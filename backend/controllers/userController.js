const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

// Generate JWT
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, {
    expiresIn: '30d',
  });
};

// Register a new user
const registerUser = async (req, res) => {
  // For masters, first_name is the place_name. last_name is optional.
  const { first_name, last_name, login, password, role } = req.body;

  console.log(req);

  if (!first_name || !login || !password || !role) {
      return res.status(400).json({ message: 'Please provide all required fields' });
  }

  try {
    // Check if user exists
    const [userExists] = await pool.query('SELECT * FROM users WHERE login = ?', [login]);
    if (userExists.length > 0) {
      return res.status(400).json({ message: 'User with this login already exists' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Create user
    const [result] = await pool.query(
      'INSERT INTO users (first_name, last_name, login, password, role) VALUES (?, ?, ?, ?, ?)',
      [first_name, last_name || null, login, hashedPassword, role] // Use null if last_name is not provided
    );
    
    const newUser = { id: result.insertId, first_name, last_name, login, role };

    // If the role is master, also create a corresponding entry in the masters table
    if (role === 'master') {
        await pool.query(
            'INSERT INTO masters (user_id, category_id, phone_number_1, place_name) VALUES (?, ?, ?, ?)',
            // Using default values. Master can edit them later.
            [newUser.id, 1, 'not-set', first_name] // Assuming category_id 1 exists
        );
    }

    res.status(201).json({
      ...newUser,
      token: generateToken(newUser.id),
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

    // Check password
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

module.exports = { registerUser, loginUser, getUserProfile };
