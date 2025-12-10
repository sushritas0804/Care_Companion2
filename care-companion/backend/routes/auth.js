const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const auth = require('../middleware/auth');

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/forgot-password', authController.forgotPassword);
router.get('/logout', authController.logout);

// Protected routes
router.get('/profile', auth.protect, authController.getProfile);
router.put('/profile', auth.protect, authController.updateProfile);

module.exports = router;
