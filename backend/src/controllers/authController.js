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
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
  connectionTimeout: 10000,
  greetingTimeout: 10000,
  socketTimeout: 10000,
});

// Helper function to send OTP email
const sendOTPEmail = async (username, email, otp) => {
  try {
    // eslint-disable-next-line no-console
    console.log(`[EMAIL] Sending OTP to ${email}`);
    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Your OTP Code',
      text: `Hello ${username},\n\nYour OTP code is: ${otp}\nIt will expire in 5 minutes.\n\nThank you!`,
    };
    await transporter.sendMail(mailOptions);
    // eslint-disable-next-line no-console
    console.log(`[EMAIL] OTP email sent successfully to ${email}`);
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[EMAIL] Email sending failed:', error.message);
    throw new Error(`Failed to send OTP email: ${error.message}`);
  }
};

// Signup
exports.signup = async (req, res) => {
  const { username, email, password } = req.body;
  // eslint-disable-next-line no-console
  console.log(`[SIGNUP] Attempt: username=${username}, email=${email}`);
  
  try {
    if (!username || !email || !password) {
      // eslint-disable-next-line no-console
      console.log('[SIGNUP] Missing fields');
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      if (!existingUser.otpVerified) {
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

    const hashedPassword = await bcrypt.hash(password, 10);
    const otp = generateOTP();
    const otpExpiration = new Date(Date.now() + parseInt(process.env.OTP_EXPIRATION));
    const user = new User({
      username,
      email,
      password: hashedPassword,
      otp,
      otpExpiration,
      otpVerified: false,
    });
    await user.save();
    // eslint-disable-next-line no-console
    console.log(`[SIGNUP] User created: ${email}`);
    await sendOTPEmail(username, email, otp);
    res.status(201).json({ message: 'User created, OTP sent to email' });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[SIGNUP] Error:', err.message);
    res.status(500).json({ message: 'Server error', error: err.message });
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
    user.otp = null;
    user.otpExpiration = null;
    user.otpVerified = true;
    await user.save();
    res.status(200).json({ message: 'OTP verified successfully' });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[VERIFY_OTP] Error:', err.message);
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
    res.status(200).json({ token, userId: user._id, username: user.username, email: user.email });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[SIGNIN] Error:', err.message);
    res.status(500).json({ message: 'Server error' });
  }
};
