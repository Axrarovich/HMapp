const pool = require('../config/db');
const fs = require('fs');
const path = require('path');

// Helper function to get master_id from user_id
async function getMasterId(userId) {
  const [masters] = await pool.query('SELECT id FROM masters WHERE user_id = ?', [userId]);
  if (masters.length === 0) {
    throw new Error('Master profile not found for this user');
  }
  return masters[0].id;
}

// Helper to delete file from filesystem
const deleteFile = (filePath) => {
  if (!filePath) return;
  // filePath comes as '/uploads/...' from db.
  // We need to resolve it relative to the root or where uploads are.
  // Assuming 'uploads' is in the root of backend project.
  
  // imageUrl starts with /, so we remove it to get relative path
  const relativePath = filePath.startsWith('/') ? filePath.substring(1) : filePath;
  const fullPath = path.join(__dirname, '..', relativePath);
  
  fs.unlink(fullPath, (err) => {
    if (err) {
        // Ignore error if file doesn't exist, otherwise log it
        if (err.code !== 'ENOENT') {
            console.error('Failed to delete file:', fullPath, err);
        }
    }
  });
};

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

// @desc    Get all rooms for a specific place (public)
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
  // image_url is derived from the file uploaded via multer middleware in the route
  const imageUrl = req.file ? `/${req.file.path.replace(/\\/g, '/')}` : null;

  try {
    const masterId = await getMasterId(req.user.id);
    const [result] = await pool.query(
      'INSERT INTO rooms (master_id, room_number, description, price, capacity, image_url) VALUES (?, ?, ?, ?, ?, ?)',
      [masterId, room_number, description, price, capacity, imageUrl]
    );
    res.status(201).json({ id: result.insertId, master_id: masterId, ...req.body, image_url: imageUrl });
  } catch (error) {
    res.status(500).json({ message: `Failed to create room: ${error.message}` });
  }
};

// @desc    Update an existing room
const updateRoom = async (req, res) => {
  try {
    const { id } = req.params;
    const { room_number, description, price, capacity, is_available, delete_image } = req.body;
    
    const masterId = await getMasterId(req.user.id);

    // First, verify the room exists and belongs to the master
    const [rooms] = await pool.query('SELECT * FROM rooms WHERE id = ? AND master_id = ?', [id, masterId]);
    if (rooms.length === 0) {
      return res.status(404).json({ message: 'Room not found or not authorized.' });
    }
    const existingRoom = rooms[0];

    // Determine the image URL. Default to the existing one.
    let imageUrl = existingRoom.image_url;

    // Handle explicit deletion
    if (delete_image === 'true') {
      if (existingRoom.image_url) {
        deleteFile(existingRoom.image_url);
      }
      imageUrl = null;
    }

    // Handle new file upload
    if (req.file) {
      // If we haven't already deleted the old image (because delete_image wasn't true),
      // and there was an old image, delete it now because we are replacing it.
      if (existingRoom.image_url && delete_image !== 'true') {
        deleteFile(existingRoom.image_url);
      }
      imageUrl = `/${req.file.path.replace(/\\/g, '/')}`;
    }

    const sql = `UPDATE rooms SET 
                  room_number = ?, 
                  description = ?, 
                  price = ?, 
                  capacity = ?, 
                  is_available = ?, 
                  image_url = ? 
                WHERE id = ? AND master_id = ?`;

    const params = [
      room_number !== undefined ? room_number : existingRoom.room_number,
      description !== undefined ? description : existingRoom.description,
      price !== undefined ? price : existingRoom.price,
      capacity !== undefined ? capacity : existingRoom.capacity,
      is_available !== undefined ? is_available : existingRoom.is_available,
      imageUrl,
      id,
      masterId
    ];

    await pool.query(sql, params);
    res.json({ message: 'Room updated successfully' });
  } catch (error) {
    res.status(500).json({ message: `Failed to update room: ${error.message}` });
  }
};

// @desc    Delete a room
const deleteRoom = async (req, res) => {
  const { id } = req.params;
  try {
    const masterId = await getMasterId(req.user.id);
    
    // Check if room exists and get image url before deleting
    const [rooms] = await pool.query('SELECT image_url FROM rooms WHERE id = ? AND master_id = ?', [id, masterId]);
    if (rooms.length === 0) {
      return res.status(404).json({ message: 'Room not found or not authorized.' });
    }
    const roomToDelete = rooms[0];

    const [result] = await pool.query('DELETE FROM rooms WHERE id = ? AND master_id = ?', [id, masterId]);
    
    if (result.affectedRows > 0) {
      // Delete image file if exists
      if (roomToDelete.image_url) {
        deleteFile(roomToDelete.image_url);
      }
      res.json({ message: 'Room deleted successfully' });
    } else {
      // Should not be reached given previous check, but good for safety
      res.status(404).json({ message: 'Room not found or not authorized.' });
    }

  } catch (error) {
    // Check for foreign key constraint error
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(400).json({ message: 'Cannot delete room. It is currently booked in an active order.' });
    }
    res.status(500).json({ message: error.message });
  }
};

module.exports = { 
  getRoomsForMaster, 
  getRoomsForPlace, 
  createRoom, 
  updateRoom, 
  deleteRoom 
};