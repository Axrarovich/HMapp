const pool = require('../config/db');

// Get master_id from user_id
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

// @desc    Get all rooms for a specific place (for users)
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
  const { room_number, description, price, image_url } = req.body;
  try {
    const masterId = await getMasterId(req.user.id);
    const [result] = await pool.query(
      'INSERT INTO rooms (master_id, room_number, description, price, image_url) VALUES (?, ?, ?, ?, ?)',
      [masterId, room_number, description, price, image_url]
    );
    res.status(201).json({ id: result.insertId, master_id: masterId, ...req.body });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update a room
const updateRoom = async (req, res) => {
  const { id } = req.params;
  const { room_number, description, price, image_url, is_available } = req.body;
  try {
    const masterId = await getMasterId(req.user.id);
    // Verify the room belongs to the master
    const [rooms] = await pool.query('SELECT * FROM rooms WHERE id = ? AND master_id = ?', [id, masterId]);
    if (rooms.length === 0) {
      return res.status(404).json({ message: 'Room not found or you are not authorized to edit it.' });
    }

    await pool.query(
      'UPDATE rooms SET room_number = ?, description = ?, price = ?, image_url = ?, is_available = ? WHERE id = ?',
      [room_number, description, price, image_url, is_available, id]
    );
    res.json({ message: 'Room updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Delete a room
const deleteRoom = async (req, res) => {
  const { id } = req.params;
  try {
    const masterId = await getMasterId(req.user.id);
    // Verify the room belongs to the master
    const [rooms] = await pool.query('SELECT * FROM rooms WHERE id = ? AND master_id = ?', [id, masterId]);
    if (rooms.length === 0) {
      return res.status(404).json({ message: 'Room not found or you are not authorized to delete it.' });
    }

    await pool.query('DELETE FROM rooms WHERE id = ?', [id]);
    res.json({ message: 'Room deleted successfully' });
  } catch (error) {
    // Handle foreign key constraint error if an order is associated with the room
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
        return res.status(400).json({ message: 'Cannot delete this room because it is associated with existing orders.' });
    }
    res.status(500).json({ message: error.message });
  }
};


module.exports = { getRoomsForMaster, getRoomsForPlace, createRoom, updateRoom, deleteRoom };
