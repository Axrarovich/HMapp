const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');
const multer = require('multer');

// Configure multer for file storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, 'uploads/'); // Make sure this 'uploads' directory exists
  },
  filename: function (req, file, cb) {
    cb(null, Date.now() + '-' + file.originalname);
  }
});

const upload = multer({ storage: storage });

// @route   POST api/users/register
// @desc    Register a new user (now with image upload)
// @access  Public
router.post('/register', upload.single('image'), userController.registerUser);

// @route   POST api/users/login
// @desc    Authenticate user & get token
// @access  Public
router.post('/login', userController.loginUser);

// @route   GET api/users/check-login/:login
// @desc    Check if a login is already taken
// @access  Public
router.get('/check-login/:login', userController.checkLogin);

// @route   GET api/users/profile
// @desc    Get user profile
// @access  Private
router.get('/profile', protect, userController.getUserProfile);

// @route   PUT api/users/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', protect, userController.updateUserProfile);

// @route   DELETE api/users/profile
// @desc    Delete user profile
// @access  Private
router.delete('/profile', protect, userController.deleteUserProfile);


module.exports = router;
