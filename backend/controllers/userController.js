const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

// Generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '30d',
  });
};

// Check if a login is already taken
const checkLogin = async (req, res) => {
  try {
    const [users] = await pool.query('SELECT * FROM users WHERE login = ?', [req.params.login]);
    res.json({ exists: users.length > 0 });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Register a new user
const registerUser = async (req, res) => {
  const { first_name, last_name, login, password, role, phone_number_1, phone_number_2, address, description } = req.body;
  const imageUrl = req.file ? req.file.path : null; // Get the path of the uploaded image

  if (!login || !password || !role) {
    return res.status(400).json({ message: 'Please provide login, password, and role' });
  }

  try {
    const [userExists] = await pool.query('SELECT * FROM users WHERE login = ?', [login]);
    if (userExists.length > 0) {
      return res.status(400).json({ message: 'User with this login already exists' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    let newUser;
    let token;

    if (role === 'user') {
      if (!first_name) {
        return res.status(400).json({ message: 'First name is required for a user role' });
      }
      const [result] = await pool.query(
        'INSERT INTO users (first_name, last_name, login, password, role) VALUES (?, ?, ?, ?, ?)',
        [first_name, last_name || null, login, hashedPassword, role]
      );
      newUser = { id: result.insertId, first_name, last_name, login, role };
      token = generateToken(result.insertId);

    } else if (role === 'master') {
      if (!first_name || !phone_number_1 || !address) {
        return res.status(400).json({ message: 'Place name, phone number 1, and location are required for a master role' });
      }

      const locationParts = address.split(',').map(part => part.trim());
      const latitude = parseFloat(locationParts[0]);
      const longitude = parseFloat(locationParts[1]);

      if (isNaN(latitude) || isNaN(longitude)) {
        return res.status(400).json({ message: 'Invalid location format. Expected \'latitude, longitude\'' });
      }

      const [userResult] = await pool.query(
        'INSERT INTO users (login, password, role, first_name) VALUES (?, ?, ?, ?)',
        [login, hashedPassword, role, first_name]
      );
      const newUserId = userResult.insertId;

      await pool.query(
        'INSERT INTO masters (user_id, place_name, phone_number_1, phone_number_2, latitude, longitude, description, category_id, image_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [newUserId, first_name, phone_number_1, phone_number_2 || null, latitude, longitude, description || null, 1, imageUrl]
      );
      
      newUser = { id: newUserId, first_name: first_name, login, role };
      token = generateToken(newUserId);

    } else {
      return res.status(400).json({ message: 'Invalid role specified' });
    }

    res.status(201).json({
      ...newUser,
      token,
    });

  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Authenticate user & get token
const loginUser = async (req, res) => {
  const { login, password } = req.body;

  try {
    const [users] = await pool.query('SELECT * FROM users WHERE login = ?', [login]);
    if (users.length === 0) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    const user = users[0];

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    res.json({
      id: user.id,
      first_name: user.first_name,
      last_name: user.last_name,
      login: user.login,
      role: user.role,
      token: generateToken(user.id),
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get user profile
const getUserProfile = async (req, res) => {
  try {
    const [users] = await pool.query('SELECT id, first_name, last_name, login, role FROM users WHERE id = ?', [req.user.id]);
    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(users[0]);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Update user profile
// @route   PUT /api/users/profile
// @access  Private
const updateUserProfile = async (req, res) => {
  try {
    const [users] = await pool.query('SELECT * FROM users WHERE id = ?', [req.user.id]);

    if (users.length === 0) {
      return res.status(404).json({ message: 'User not found' });
    }

    const user = users[0];

    const { first_name, last_name, login, password } = req.body;

    const updatedFields = {
      first_name: first_name || user.first_name,
      last_name: last_name === '' ? null : last_name || user.last_name,
      login: login || user.login,
    };

    if (password) {
      const salt = await bcrypt.genSalt(10);
      updatedFields.password = await bcrypt.hash(password, salt);
    }

    if (login && login !== user.login) {
      const [existingUser] = await pool.query('SELECT * FROM users WHERE login = ?', [login]);
      if (existingUser.length > 0) {
        return res.status(400).json({ message: 'User with this login already exists' });
      }
    }

    await pool.query('UPDATE users SET ? WHERE id = ?', [updatedFields, req.user.id]);

    const [updatedUsers] = await pool.query('SELECT id, first_name, last_name, login, role FROM users WHERE id = ?', [req.user.id]);

    res.json({
      ...updatedUsers[0],
      token: generateToken(req.user.id),
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { registerUser, loginUser, getUserProfile, updateUserProfile, checkLogin };
