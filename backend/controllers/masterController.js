const pool = require('../config/db');
const bcrypt = require('bcryptjs');

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
      'SELECT u.first_name, u.last_name, u.login, m.image_url, m.* FROM masters m JOIN users u ON m.user_id = u.id WHERE m.id = ?',
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
  if (req.user.role !== 'master') {
    return res.status(403).json({ message: 'User is not a master' });
  }

  try {
    const [masters] = await pool.query(
      'SELECT u.login, u.first_name, m.image_url, m.* FROM masters m JOIN users u ON m.user_id = u.id WHERE u.id = ?',
      [req.user.id]
    );
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
  if (req.user.role !== 'master') {
    return res.status(403).json({ message: 'User is not a master' });
  }

  const { phone_number_1, phone_number_2, place_name, description, is_available, login, image_url } = req.body;

  try {
    const [masters] = await pool.query('SELECT * FROM masters WHERE user_id = ?', [req.user.id]);
    if (masters.length === 0) {
        return res.status(404).json({ message: 'Master profile not found for this user' });
    }
    const masterId = masters[0].id;

    await pool.query(
      'UPDATE masters SET phone_number_1 = ?, phone_number_2 = ?, place_name = ?, description = ?, is_available = ?, image_url = ? WHERE id = ?',
      [phone_number_1, phone_number_2, place_name, description, is_available, image_url, masterId]
    );

    await pool.query('UPDATE users SET login = ? WHERE id = ?', [login, req.user.id]);

    const [updatedMasters] = await pool.query(
      'SELECT u.login, u.first_name, m.image_url, m.* FROM masters m JOIN users u ON m.user_id = u.id WHERE m.id = ?',
      [masterId]
    );
    res.json(updatedMasters[0]);

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update master password
const updateMasterPassword = async (req, res) => {
  if (req.user.role !== 'master') {
    return res.status(403).json({ message: 'User is not a master' });
  }

  const { oldPassword, newPassword } = req.body;

  if (!oldPassword || !newPassword) {
    return res.status(400).json({ message: 'Please provide old and new passwords' });
  }

  try {
    const [users] = await pool.query('SELECT password FROM users WHERE id = ?', [req.user.id]);
    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(oldPassword, user.password);

    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid old password' });
    }

    if (oldPassword === newPassword) {
      return res.status(400).json({ message: 'New password cannot be the same as the old password' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await pool.query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, req.user.id]);

    res.json({ message: 'Password updated successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete master account
const deleteMasterAccount = async (req, res) => {
    if (req.user.role !== 'master') {
        return res.status(403).json({ message: 'User is not a master' });
    }
    const { password } = req.body;

    if (!password) {
        return res.status(400).json({ message: 'Password is required' });
    }

    const userId = req.user.id;
    const connection = await pool.getConnection();

    try {
        const [users] = await connection.query('SELECT password FROM users WHERE id = ?', [userId]);
        if (users.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }

        const user = users[0];
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid password' });
        }

        await connection.beginTransaction();
        await connection.query('DELETE FROM masters WHERE user_id = ?', [userId]);
        await connection.query('DELETE FROM users WHERE id = ?', [userId]);
        await connection.commit();
        res.json({ message: 'Account deleted successfully' });
    } catch (error) {
        await connection.rollback();
        res.status(500).json({ message: error.message });
    }
};

module.exports = { getMasters, getMasterById, getMasterProfile, updateMasterProfile, updateMasterPassword, deleteMasterAccount };
