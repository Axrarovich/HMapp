const pool = require('../config/db');

// Helper to validate and format phone number
const validateAndFormatPhone = (phone) => {
  // If phone is explicitly null or undefined, return null
  if (!phone) return null;
  
  // Remove all non-digits
  const digits = phone.toString().replace(/\D/g, '');

  // Must have 12 digits and start with 998
  if (digits.length !== 12 || !digits.startsWith('998')) {
    throw new Error('Phone number must be +998 followed by exactly 9 digits.');
  }

  // Format: +998 XX XXX XX XX
  return `+${digits.substring(0, 3)} ${digits.substring(3, 5)} ${digits.substring(5, 8)} ${digits.substring(8, 10)} ${digits.substring(10, 12)}`;
};

// Create a new order
const createOrder = async (req, res) => {
  let { master_id, room_id, description, booking_date, phone_1, phone_2 } = req.body;
  const user_id = req.user.id;

  // Validate and format phone numbers
  try {
      if (!phone_1) {
          return res.status(400).json({ message: 'Phone number 1 is required.' });
      }
      phone_1 = validateAndFormatPhone(phone_1);
      
      if (phone_2) {
          phone_2 = validateAndFormatPhone(phone_2);
      } else {
          phone_2 = null;
      }
  } catch (e) {
      return res.status(400).json({ message: e.message });
  }

  // Check if the room is available
  const [rooms] = await pool.query('SELECT is_available FROM rooms WHERE id = ?', [room_id]);
  if (rooms.length === 0 || !rooms[0].is_available) {
      return res.status(400).json({ message: 'This room is not available for booking.' });
  }

  try {
    // Create order
    const [result] = await pool.query(
      'INSERT INTO orders (user_id, master_id, room_id, description, status, booking_date, phone_1, phone_2) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [user_id, master_id, room_id, description, 'pending', booking_date, phone_1, phone_2] // Status is pending until master accepts
    );

    // Note: We do NOT mark the room as unavailable immediately anymore.
    // It remains available until the master accepts the order.
    // await pool.query('UPDATE rooms SET is_available = false WHERE id = ?', [room_id]);

    const newOrder = { id: result.insertId, user_id, master_id, room_id, description, status: 'pending', booking_date, phone_1, phone_2 };
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
        SELECT o.*, 
               m_u.first_name as master_first_name, m_u.last_name as master_last_name, 
               u.first_name as user_first_name, u.last_name as user_last_name,
               r.room_number,
               (SELECT COUNT(*) FROM reviews WHERE reviews.order_id = o.id) > 0 as is_reviewed
        FROM orders o
        JOIN masters m ON o.master_id = m.id
        JOIN users m_u ON m.user_id = m_u.id
        JOIN users u ON o.user_id = u.id
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

    // Logic for updating room availability based on order status
    
    // We update room availability regardless of the previous status to ensure consistency.
    // If status is accepted or in_progress, room becomes occupied (0)
    if (['accepted', 'in_progress'].includes(status) && order.room_id) {
         await pool.query('UPDATE rooms SET is_available = 0 WHERE id = ?', [order.room_id]);
    } 
    // If order is completed, cancelled, rejected or reverted to pending, room becomes available (1)
    else if (['completed', 'cancelled', 'pending', 'rejected'].includes(status) && order.room_id) {
         await pool.query('UPDATE rooms SET is_available = 1 WHERE id = ?', [order.room_id]);
    }

    res.json({ ...order, status });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Delete order
const deleteOrder = async (req, res) => {
  const order_id = req.params.id;

  try {
    const [orders] = await pool.query('SELECT * FROM orders WHERE id = ?', [order_id]);
    if (orders.length === 0) {
      return res.status(404).json({ message: 'Order not found' });
    }
    const order = orders[0];

    // Authorization checks
    // Allow user to delete their own order
    if (order.user_id !== req.user.id) {
        return res.status(403).json({ message: 'Not authorized to delete this order' });
    }

    // Only allow deleting pending orders
    if (order.status !== 'pending') {
        return res.status(400).json({ message: 'Only pending orders can be deleted' });
    }

    await pool.query('DELETE FROM orders WHERE id = ?', [order_id]);

    res.json({ message: 'Order deleted successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { createOrder, getOrders, updateOrderStatus, deleteOrder };
