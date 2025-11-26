const pool = require('../config/db');

// Get all masters
const getMasters = async (req, res) => {
  try {
    const [masters] = await pool.query(
      'SELECT u.first_name, u.last_name, m.* FROM masters m JOIN users u ON m.user_id = u.id'
    );
    res.json(masters);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get master by ID
const getMasterById = async (req, res) => {
  try {
    const [masters] = await pool.query(
      'SELECT u.first_name, u.last_name, m.* FROM masters m JOIN users u ON m.user_id = u.id WHERE m.id = ?',
      [req.params.id]
    );
    if (masters.length === 0) {
      return res.status(404).json({ message: 'Master not found' });
    }
    res.json(masters[0]);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get current master's profile
const getMasterProfile = async (req, res) => {
  // Only masters can get their own profile
  if (req.user.role !== 'master') {
    return res.status(403).json({ message: 'User is not a master' });
  }

  try {
    const [masters] = await pool.query('SELECT * FROM masters WHERE user_id = ?', [req.user.id]);
    if (masters.length === 0) {
      return res.status(404).json({ message: 'Master profile not found for this user' });
    }
    res.json(masters[0]);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};


// Update master profile
const updateMasterProfile = async (req, res) => {
  // Only masters can update their own profile
  if (req.user.role !== 'master') {
    return res.status(403).json({ message: 'User is not a master' });
  }

  const { phone_number_1, phone_number_2, place_name, latitude, longitude, description, image_url, is_available } = req.body;

  try {
    const [masters] = await pool.query('SELECT * FROM masters WHERE user_id = ?', [req.user.id]);
    if (masters.length === 0) {
        return res.status(404).json({ message: 'Master profile not found for this user' });
    }
    const masterId = masters[0].id;


    await pool.query(
      'UPDATE masters SET phone_number_1 = ?, phone_number_2 = ?, place_name = ?, latitude = ?, longitude = ?, description = ?, image_url = ?, is_available = ? WHERE id = ?',
      [phone_number_1, phone_number_2, place_name, latitude, longitude, description, image_url, is_available, masterId]
    );

    const [updatedMasters] = await pool.query('SELECT * FROM masters WHERE id = ?', [masterId]);
    res.json(updatedMasters[0]);

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getMasters, getMasterById, getMasterProfile, updateMasterProfile };
