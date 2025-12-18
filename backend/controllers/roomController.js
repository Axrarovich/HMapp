const pool = require('../config/db');

// Helper function to get master_id from user_id
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
    const { room_number, description, price, capacity, is_available } = req.body;
    
    const masterId = await getMasterId(req.user.id);

    // First, verify the room exists and belongs to the master
    const [rooms] = await pool.query('SELECT * FROM rooms WHERE id = ? AND master_id = ?', [id, masterId]);
    if (rooms.length === 0) {
      return res.status(404).json({ message: 'Room not found or not authorized.' });
    }
    const existingRoom = rooms[0];

    // Determine the image URL. Default to the existing one.
    let imageUrl = existingRoom.image_url;
    if (req.file) {
      // If a new file is uploaded, use its path.
      imageUrl = `/${req.file.path.replace(/\\/g, '/')}`;
    }
    // Note: To remove an image, the client would need to send a specific signal,
    // which is not implemented here. This logic just updates or keeps the image.

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
    const [result] = await pool.query('DELETE FROM rooms WHERE id = ? AND master_id = ?', [id, masterId]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Room not found or not authorized.' });
    }

    res.json({ message: 'Room deleted successfully' });
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