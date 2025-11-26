const express = require('express');
const router = express.Router();
const roomController = require('../controllers/roomController');
const { protect } = require('../middleware/authMiddleware');

// Middleware to ensure the user is a master
const isMaster = (req, res, next) => {
  if (req.user && req.user.role === 'master') {
    next();
  } else {
    res.status(403).json({ message: 'Not authorized as a master' });
  }
};

// @route   GET api/rooms/master
// @desc    Get all rooms for the logged-in master
// @access  Private (Master)
router.get('/master', protect, isMaster, roomController.getRoomsForMaster);

// @route   GET api/rooms/place/:master_id
// @desc    Get all rooms for a specific place (for users)
// @access  Public
router.get('/place/:master_id', roomController.getRoomsForPlace);


// @route   POST api/rooms
// @desc    Create a new room
// @access  Private (Master)
router.post('/', protect, isMaster, roomController.createRoom);

// @route   PUT api/rooms/:id
// @desc    Update a room
// @access  Private (Master)
router.put('/:id', protect, isMaster, roomController.updateRoom);

// @route   DELETE api/rooms/:id
// @desc    Delete a room
// @access  Private (Master)
router.delete('/:id', protect, isMaster, roomController.deleteRoom);


module.exports = router;
