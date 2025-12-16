const pool = require('../config/db');
const multer = require('multer');
const path = require('path');

// Multer config
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
  const extname = filetypes.test(path.extname(file.originalname).toLowerCase());
  const mimetype = filetypes.test(file.mimetype);

  if (extname && mimetype) {
    return cb(null, true);
  } else {
    cb(new Error('Images only!'));
  }
}

const upload = multer({ storage, fileFilter: checkFileType });
const uploadSingleImage = upload.single('image');

// Helper function to get master_id
async function getMasterId(userId) {
  const [masters] = await pool.query('SELECT id FROM masters WHERE user_id = ?', [userId]);
  if (masters.length === 0) {
    throw new Error('Master profile not found for this user');
  }
  return masters[0].id;
}

// @desc    Get all rooms for the logged-in master
const getRoomsForMaster = async (req, res) => {
  try {
    const masterId = await getMasterId(req.user.id);
    const [rooms] = await pool.query('SELECT * FROM rooms WHERE master_id = ?', [masterId]);
    res.json(rooms);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get all rooms for a specific place
const getRoomsForPlace = async (req, res) => {
  try {
    const [rooms] = await pool.query('SELECT * FROM rooms WHERE master_id = ?', [req.params.master_id]);
    res.json(rooms);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Create a new room
const createRoom = async (req, res) => {
  const { room_number, description, price, capacity } = req.body;
  const imageUrl = req.file ? `/${req.file.path.replace(/\\/g, '/')}` : null;

  try {
    const masterId = await getMasterId(req.user.id);
    const [result] = await pool.query(
      'INSERT INTO rooms (master_id, room_number, description, price, capacity, image_url) VALUES (?, ?, ?, ?, ?, ?)',
      [masterId, room_number, description, price, capacity, imageUrl]
    );
    res.status(201).json({ id: result.insertId, master_id: masterId, ...req.body, image_url: imageUrl });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a room (handles both JSON and multipart)
const updateRoom = async (req, res) => {
  const processUpdate = async () => {
    try {
      const { id } = req.params;
      const { room_number, description, price, capacity, is_available } = req.body;
      
      const masterId = await getMasterId(req.user.id);
      const [rooms] = await pool.query('SELECT * FROM rooms WHERE id = ? AND master_id = ?', [id, masterId]);

      if (rooms.length === 0) {
        return res.status(404).json({ message: 'Room not found or not authorized.' });
      }

      const existingRoom = rooms[0];

      // If a new file is uploaded, use its path. Otherwise, keep the existing URL.
      const imageUrl = req.file ? `/${req.file.path.replace(/\\/g, '/')}` : req.body.image_url || existingRoom.image_url;


      const sql = `UPDATE rooms SET 
                    room_number = ?, 
                    description = ?, 
                    price = ?, 
                    capacity = ?, 
                    is_available = ?, 
                    image_url = ? 
                  WHERE id = ?`;

      const params = [
        room_number !== undefined ? room_number : existingRoom.room_number,
        description !== undefined ? description : existingRoom.description,
        price !== undefined ? price : existingRoom.price,
        capacity !== undefined ? capacity : existingRoom.capacity,
        is_available !== undefined ? is_available : existingRoom.is_available,
        imageUrl, // Use the final image URL
        id
      ];

      await pool.query(sql, params);
      res.json({ message: 'Room updated successfully' });
    } catch (error) {
      res.status(500).json({ message: `Server error: ${error.message}` });
    }
  };

  // Multer will process the form. If there's an image, req.file will be populated.
  uploadSingleImage(req, res, (err) => {
    if (err) {
      return res.status(400).json({ message: err.message });
    }
    processUpdate();
  });
};


// @desc    Delete a room
const deleteRoom = async (req, res) => {
  const { id } = req.params;
  try {
    const masterId = await getMasterId(req.user.id);
    await pool.query('DELETE FROM rooms WHERE id = ? AND master_id = ?', [id, masterId]);
    res.json({ message: 'Room deleted successfully' });
  } catch (error) {
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(400).json({ message: 'Cannot delete this room because it is associated with existing orders.' });
    }
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getRoomsForMaster, getRoomsForPlace, createRoom, updateRoom, deleteRoom };