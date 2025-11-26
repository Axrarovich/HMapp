const pool = require('../config/db');

// Create a new order
const createOrder = async (req, res) => {
  const { master_id, room_id, description } = req.body;
  const user_id = req.user.id;

  // Check if the room is available
  const [rooms] = await pool.query('SELECT is_available FROM rooms WHERE id = ?', [room_id]);
  if (rooms.length === 0 || !rooms[0].is_available) {
      return res.status(400).json({ message: 'This room is not available for booking.' });
  }

  try {
    // Create order
    const [result] = await pool.query(
      'INSERT INTO orders (user_id, master_id, room_id, description, status) VALUES (?, ?, ?, ?, ?)',
      [user_id, master_id, room_id, description, 'pending'] // Status is pending until master accepts
    );

    // Mark the room as unavailable
    await pool.query('UPDATE rooms SET is_available = false WHERE id = ?', [room_id]);

    const newOrder = { id: result.insertId, user_id, master_id, room_id, description, status: 'pending' };
    res.status(201).json(newOrder);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all orders for a user or master
const getOrders = async (req, res) => {
  try {
    let orders;
    if (req.user.role === 'master') {
      const [masterProfile] = await pool.query('SELECT id FROM masters WHERE user_id = ?', [req.user.id]);
      if(masterProfile.length === 0) {
        return res.status(404).json({message: "Master profile not found"})
      }
      const masterId = masterProfile[0].id;
      [orders] = await pool.query(`
        SELECT o.*, u.first_name as user_first_name, u.last_name as user_last_name, r.room_number
        FROM orders o
        JOIN users u ON o.user_id = u.id
        LEFT JOIN rooms r ON o.room_id = r.id
        WHERE o.master_id = ?
        ORDER BY o.created_at DESC
      `, [masterId]);
    } else { // 'user' role
      [orders] = await pool.query(`
        SELECT o.*, u.first_name as master_first_name, u.last_name as master_last_name, r.room_number
        FROM orders o
        JOIN masters m ON o.master_id = m.id
        JOIN users u ON m.user_id = u.id
        LEFT JOIN rooms r ON o.room_id = r.id
        WHERE o.user_id = ?
        ORDER BY o.created_at DESC
      `, [req.user.id]);
    }
    res.json(orders);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Update order status
const updateOrderStatus = async (req, res) => {
  const { status } = req.body;
  const order_id = req.params.id;

  try {
    const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [order_id]);
    if (orders.length === 0) {
      return res.status(404).json({ message: 'Order not found' });
    }
    const order = orders[0];

    // Authorization checks
    if (req.user.role === 'master') {
        const [masterProfile] = await pool.query('SELECT id FROM masters WHERE user_id = ?', [req.user.id]);
        if (masterProfile.length === 0 || order.master_id !== masterProfile[0].id) {
            return res.status(403).json({ message: 'Not authorized to update this order' });
        }
    } else if (order.user_id !== req.user.id) {
        return res.status(403).json({ message: 'Not authorized to update this order' });
    }

    await pool.query('UPDATE orders SET status = ? WHERE id = ?', [status, order_id]);

    // If order is cancelled by master or user, make the room available again
    if ((status === 'cancelled' || status === 'completed') && order.room_id) {
        await pool.query('UPDATE rooms SET is_available = true WHERE id = ?', [order.room_id]);
    }

    res.json({ ...order, status });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { createOrder, getOrders, updateOrderStatus };
