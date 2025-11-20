const User = require('../models/User');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const generateOTP = require('../utils/otpGenerator');
const nodemailer = require('nodemailer');

require('dotenv').config();

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
