const User = require('../models/User');
const jwt = require('jsonwebtoken');
const validator = require('validator');

// Generate JWT token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
};

// Register new user
exports.register = async (req, res, next) => {
  try {
    const { fullName, email, password, dateOfBirth, medicalHistory } = req.body;

    // Validate input
    if (!fullName || !email || !password || !dateOfBirth) {
      return res.status(400).json({
        status: 'error',
        message: 'Please provide all required fields'
      });
    }

    if (!validator.isEmail(email)) {
      return res.status(400).json({
        status: 'error',
        message: 'Please provide a valid email address'
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        status: 'error',
        message: 'Password must be at least 8 characters long'
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(409).json({
        status: 'error',
        message: 'User with this email already exists'
      });
    }

    // Calculate age from date of birth
    const dob = new Date(dateOfBirth);
    const today = new Date();
    let age = today.getFullYear() - dob.getFullYear();
    const monthDiff = today.getMonth() - dob.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < dob.getDate())) {
      age--;
    }

    if (age < 13) {
      return res.status(400).json({
        status: 'error',
        message: 'You must be at least 13 years old to register'
      });
    }

    // Create new user
    const user = await User.create({
      fullName,
      email: email.toLowerCase(),
      password,
      dateOfBirth: dob,
      medicalHistory: medicalHistory || []
    });

    // Remove password from response
    user.password = undefined;

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      status: 'success',
      message: 'User registered successfully',
      token,
      data: {
        user
      }
    });
  } catch (error) {
    next(error);
  }
};

// Login user
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        status: 'error',
        message: 'Please provide email and password'
      });
    }

    // Find user and include password for comparison
    const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
    
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({
        status: 'error',
        message: 'Invalid email or password'
      });
    }

    // Remove password from response
    user.password = undefined;

    // Generate token
    const token = generateToken(user._id);

    res.status(200).json({
      status: 'success',
      message: 'Logged in successfully',
      token,
      data: {
        user
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get current user profile
exports.getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    res.status(200).json({
      status: 'success',
      data: {
        user
      }
    });
  } catch (error) {
    next(error);
  }
};

// Update user profile
exports.updateProfile = async (req, res, next) => {
  try {
    const { fullName, medicalHistory, allergies } = req.body;
    
    const updateData = {};
    if (fullName) updateData.fullName = fullName;
    if (medicalHistory) updateData.medicalHistory = medicalHistory;
    if (allergies) updateData.allergies = allergies;

    const user = await User.findByIdAndUpdate(
      req.user.id,
      updateData,
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({
        status: 'error',
        message: 'User not found'
      });
    }

    res.status(200).json({
      status: 'success',
      message: 'Profile updated successfully',
      data: {
        user
      }
    });
  } catch (error) {
    next(error);
  }
};

// Logout (client-side token removal)
exports.logout = (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Logged out successfully'
  });
};

// Forgot password (simplified version)
exports.forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        status: 'error',
        message: 'Please provide your email address'
      });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    
    if (!user) {
      // Don't reveal that user doesn't exist for security
      return res.status(200).json({
        status: 'success',
        message: 'If an account exists with this email, password reset instructions have been sent'
      });
    }

    // In a real application, you would:
    // 1. Generate a reset token
    // 2. Send email with reset link
    // 3. Store hashed reset token in database with expiry
    
    res.status(200).json({
      status: 'success',
      message: 'Password reset instructions have been sent to your email'
    });
  } catch (error) {
    next(error);
  }
};
