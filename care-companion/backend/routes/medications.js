const express = require('express');
const router = express.Router();
const medicationController = require('../controllers/medicationController');
const auth = require('../middleware/auth');

// Public routes
router.get('/', medicationController.getAllMedications);
router.get('/search', medicationController.searchMedications);
router.get('/categories', medicationController.getCategories);
router.get('/categories/:category', medicationController.getMedicationsByCategory);
router.get('/popular', medicationController.getPopularMedications);
router.get('/:id', medicationController.getMedicationById);

// Protected routes (for future admin features)
// router.post('/', auth.protect, auth.restrictTo('admin'), medicationController.createMedication);
// router.put('/:id', auth.protect, auth.restrictTo('admin'), medicationController.updateMedication);
// router.delete('/:id', auth.protect, auth.restrictTo('admin'), medicationController.deleteMedication);

module.exports = router;
