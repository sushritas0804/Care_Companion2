const express = require('express');
const router = express.Router();
const recommendationController = require('../controllers/recommendationController');
const auth = require('../middleware/auth');
const optionalAuth = require('../middleware/auth').optionalAuth;

// Get recommendations (with optional authentication)
router.post('/', optionalAuth, recommendationController.getRecommendations);

// Get recommendation by session ID
router.get('/session/:sessionId', recommendationController.getRecommendationBySession);

// Protected routes (user history)
router.get('/history', auth.protect, recommendationController.getUserRecommendations);

module.exports = router;
