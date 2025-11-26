const express = require('express');
const router = express.Router();
const reviewController = require('../controllers/reviewController');
const { protect } = require('../middleware/authMiddleware');

// @route   POST api/reviews
// @desc    Create a new review
// @access  Private
router.post('/', protect, reviewController.createReview);

// @route   GET api/reviews/:master_id
// @desc    Get all reviews for a master
// @access  Public
router.get('/:master_id', reviewController.getReviewsForMaster);

module.exports = router;
