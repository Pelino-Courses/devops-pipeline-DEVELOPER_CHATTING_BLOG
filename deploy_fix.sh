cd /opt/devops-app

# Fix swagger.js
cat > backend/config/swagger.js << 'EOF'
const swaggerJsdoc = require("swagger-jsdoc");
const swaggerUi = require("swagger-ui-express");

const options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "My API Documentation",
      version: "1.0.0",
      description: "API documentation using Swagger for my Node.js project",
    },
    servers: [
      {
        url: "http://51.103.157.72:5000",
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: "JWT",
        },
      },
    },
  },
  apis: ["./src/routes/*.js"], // Swagger docs read from route files
};

const swaggerSpec = swaggerJsdoc(options);

function setupSwagger(app) {
  app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));
}

module.exports = setupSwagger;
EOF

# Fix authController.js
cat > backend/src/controllers/authController.js << 'EOF'
const User = require("../models/User");
const bcrypt = require("bcrypt");
const jwt = require("jsonwebtoken");
const generateOTP = require("../utils/otpGenerator");
const nodemailer = require("nodemailer");
require("dotenv").config(); 

// Configure Nodemailer transporter for Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER, // your Gmail
    pass: process.env.EMAIL_PASS, // Gmail App Password
  },
});

// Helper function to send OTP email
const sendOTPEmail = async (username, email, otp) => {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Your OTP Code',
    text: `Hello ${username},\n\nYour OTP code is: ${otp}\nIt will expire in 5 minutes.\n\nThank you!`,
  };
  await transporter.sendMail(mailOptions);
};

// Signup
exports.signup = async (req, res) => {
  const { username, email, password } = req.body;
  try {
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      if (!existingUser.otpVerified) {
        // User exists but not verified → resend OTP
        const otp = generateOTP();
        existingUser.otp = otp;
        existingUser.otpExpiration = new Date(Date.now() + parseInt(process.env.OTP_EXPIRATION));
        await existingUser.save();
        await sendOTPEmail(existingUser.username, email, otp);
        return res.status(200).json({ message: 'OTP resent to email' });
      } else {
        return res.status(400).json({ message: 'Email already exists' });
      }
    }
    // New user signup
    const hashedPassword = await bcrypt.hash(password, 10);
    const otp = generateOTP();
    const otpExpiration = new Date(Date.now() + parseInt(process.env.OTP_EXPIRATION));
    const user = new User({
      username,
      email,
      password: hashedPassword,
      otp,
      otpExpiration,
      otpVerified: false, // mark as not verified initially
    });
    await user.save();
    await sendOTPEmail(username, email, otp);
    res.status(201).json({ message: 'User created, OTP sent to email' });
  } catch (err) {
    console.error('Signup Error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// Verify OTP
exports.verifyOTP = async (req, res) => {
  const { email, otp } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (user.otp !== otp || user.otpExpiration < new Date()) {
      return res.status(400).json({ message: 'Invalid or expired OTP' });
    }
    // Clear OTP and mark user as verified
    user.otp = null;
    user.otpExpiration = null;
    user.otpVerified = true;
    await user.save();
    res.status(200).json({ message: 'OTP verified successfully' });
  } catch (err) {
    console.error('Verify OTP Error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// Signin
exports.signin = async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: 'User not found' });
    if (!user.otpVerified) {
      return res.status(400).json({ message: 'Email not verified. Please verify OTP first.' });
    }
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ message: 'Invalid credentials' });
    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
      expiresIn: '1h',
    });
    res.status(200).json({ token });
  } catch (err) {
    console.error('Signin Error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};
EOF

# Fix User.js
cat > backend/src/models/User.js << 'EOF'
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  otp: { type: String },
  otpExpiration: { type: Date },
  otpVerified: { type: Boolean, default: false }, // new field
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
EOF

# Fix authMiddleware.js
cat > backend/src/middleware/authMiddleware.js << 'EOF'
const jwt = require("jsonwebtoken");
require("dotenv").config();
const User = require("../models/User"); 

// optional: fetch full user if needed
const authMiddleware = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header('Authorization')?.replace('Bearer ', '');
    if (!token) return res.status(401).json({ message: 'No token, authorization denied' });
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // Optional: fetch user from DB if needed
    // const user = await User.findById(decoded.userId).select('-password');
    // if (!user) return res.status(401).json({ message: 'User not found' });
    // req.user = user;
    // Attach user info from token
    req.user = { id: decoded.userId }; // use req.user.id in controllers
    next();
  } catch (err) {
    console.error(err);
    res.status(401).json({ message: 'Invalid or expired token' });
  }
};

module.exports = authMiddleware;
EOF

# Fix socket.js
cat > backend/src/socket/socket.js << 'EOF'
const socketIo = require('socket.io');
const Message = require('../models/Message');

const setupSocket = (server) => {
  const io = socketIo(server, {
    cors: { origin: '*' }
  });

  io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    socket.on('join', (userId) => {
      socket.join(userId); // join a room with userId
    });

    socket.on('sendMessage', async ({ senderId, receiverId, content }) => {
      try {
        const message = await Message.create({ sender: senderId, receiver: receiverId, content });
        // Emit to both users
        io.to(receiverId).emit('receiveMessage', message);
        io.to(senderId).emit('receiveMessage', message);
      } catch (err) {
        console.error('Error sending message:', err);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    socket.on('disconnect', () => {
      console.log('User disconnected:', socket.id);
    });
  });
};

module.exports = setupSocket;
EOF

# Fix chatController.js
cat > backend/src/controllers/chatController.js << 'EOF'
const Message = require("../models/Message");

// Get all messages between logged-in user and another user
const getMessages = async (req, res) => {
  try {
    const userId = req.user.id; // from auth middleware
    const otherUserId = req.params.userId;
    const messages = await Message.find({
      $or: [
        { sender: userId, receiver: otherUserId },
        { sender: otherUserId, receiver: userId },
      ],
    }).sort({ createdAt: 1 });
    res.status(200).json(messages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = { getMessages };
EOF

# Fix messageRoutes.js
cat > backend/src/routes/messageRoutes.js << 'EOF'
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const Message = require('../models/Message');

/**
 * @swagger
 * /api/messages:
 *   post:
 *     summary: Send a message to another user
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               receiverId:
 *                 type: string
 *               content:
 *                 type: string
 *     responses:
 *       200:
 *         description: Message sent
 *       401:
 *         description: Unauthorized
 */
router.post('/messages', authMiddleware, async (req, res) => {
  try {
    const { receiverId, content } = req.body;
    const message = await Message.create({
      sender: req.user.id,
      receiver: receiverId,
      content, // frontend should encrypt before sending
    });
    res.status(200).json(message);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

/**
 * @swagger
 * /api/messages/{userId}:
 *   get:
 *     summary: Get messages between current user and another user
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - name: userId
 *         in: path
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: List of messages
 *       401:
 *         description: Unauthorized
 */
router.get('/messages/:userId', authMiddleware, async (req, res) => {
  try {
    const { userId } = req.params;
    const messages = await Message.find({
      $or: [
        { sender: req.user.id, receiver: userId },
        { sender: userId, receiver: req.user.id }
      ]
    }).sort({ createdAt: 1 }); // oldest first
    res.status(200).json(messages);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
EOF

# Fix userRoutes.js
cat > backend/src/routes/userRoutes.js << 'EOF'
const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const User = require('../models/User');

/**
 * @swagger
 * /api/users:
 *   get:
 *     summary: Get all verified users except current user
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of users
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   username:
 *                     type: string
 *                   email:
 *                     type: string
 *                   _id:
 *                     type: string
 *       401:
 *         description: Unauthorized
 */
router.get('/users', authMiddleware, async (req, res) => {
  try {
    const users = await User.find({
       otpVerified: true,
       _id: { $ne: req.user.id } // Exclude current user
    }).select('username email _id');
    res.status(200).json(users);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
EOF

# Fix permissions (since this script might run as root)
chown -R azureuser:azureuser /opt/devops-app/backend

# Rebuild backend
sudo docker-compose stop backend
sudo docker rm backend
sudo docker-compose build --no-cache backend
sudo docker-compose up -d backend
