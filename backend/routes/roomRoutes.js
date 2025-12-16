const express = require('express');
const router = express.Router();
const roomController = require('../controllers/roomController');
const { protect } = require('../middleware/authMiddleware');
const multer = require('multer');
const path = require('path');

// Middleware to ensure the user is a master
const isMaster = (req, res, next) => {
  if (req.user && req.user.role === 'master') {
    next();
  } else {
    res.status(403).json({ message: 'Not authorized as a master' });
  }
};

const storage = multer.diskStorage({
  destination(req, file, cb) {
    cb(null, 'uploads/');
  },
  filename(req, file, cb) {
    cb(null, `${file.fieldname}-${Date.now()}${path.extname(file.originalname)}`);
  },
});

function checkFileType(file, cb) {
  const filetypes = /jpg|jpeg|png/;
  if (!file.originalname.match(new RegExp(`\.(${filetypes.source})$`, 'i'))) {
    return cb(new Error('Images only!'), false);
  }
  cb(null, true);
}

const upload = multer({ storage, fileFilter: checkFileType });

// GET routes
router.get('/master', protect, isMaster, roomController.getRoomsForMaster);
router.get('/place/:master_id', roomController.getRoomsForPlace);

// POST route
router.post('/', protect, isMaster, upload.single('image'), roomController.createRoom);

// PUT route - The controller will handle the multipart logic internally
router.put('/:id', protect, isMaster, roomController.updateRoom);

// DELETE route
router.delete('/:id', protect, isMaster, roomController.deleteRoom);

module.exports = router;
