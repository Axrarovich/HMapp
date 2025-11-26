const express = require('express');
const router = express.Router();
const masterController = require('../controllers/masterController');
const { protect } = require('../middleware/authMiddleware');

// @route   GET api/masters
// @desc    Get all masters
// @access  Public
router.get('/', masterController.getMasters);

// @route   GET api/masters/profile
// @desc    Get current master's profile
// @access  Private (only for masters)
router.get('./profile', protect, masterController.getMasterProfile);

// @route   GET api/masters/:id
// @desc    Get master by ID
// @access  Public
router.get('/:id', masterController.getMasterById);

// @route   PUT api/masters/profile
// @desc    Update master profile
// @access  Private (only for masters)
router.put('/profile', protect, masterController.updateMasterProfile);

module.exports = router;
