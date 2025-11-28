const express = require('express');
const http = require('http');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./config/db');
const setupSwagger = require('./config/swagger');

// Routes
const authRoutes = require('./src/routes/authRoutes');
const profileRoutes = require('./src/routes/profileRoutes');
const userRoutes = require('./src/routes/userRoutes');
const messageRoutes = require('./src/routes/messageRoutes');

// Socket
const setupSocket = require('./src/socket/socket');

dotenv.config(); // Load environment variables

const app = express();
const server = http.createServer(app); // For Socket.IO

// Middleware
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
    // eslint-disable-next-line no-console
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
});

// Swagger setup (must be before routes)
setupSwagger(app);

// Test route
app.get('/health', (req, res) => {
    res.status(200).json({ message: 'Backend is running!' });
});

// Routes
app.use('/api', authRoutes);
app.use('/api', profileRoutes);
app.use('/api', userRoutes);
app.use('/api', messageRoutes);

// Connect to database
connectDB();

// Socket.IO setup
setupSocket(server);

// Start server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

// Global error handling
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ message: 'Something went wrong!' });
});
