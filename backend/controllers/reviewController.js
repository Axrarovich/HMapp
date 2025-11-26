const pool = require('../config/db');

// Create a new review
const createReview = async (req, res) => {
  const { master_id, order_id, rating, comment } = req.body;
  const user_id = req.user.id;

  try {
    // Check if the user has a completed order with this master
    const [orders] = await pool.query(
      'SELECT * FROM orders WHERE id = ? AND user_id = ? AND master_id = ? AND status = \'completed\'',
      [order_id, user_id, master_id]
    );

    if (orders.length === 0) {
      return res.status(403).json({ message: 'You can only review a completed order.' });
    }

    // Check if the user has already reviewed this order
    const [existingReviews] = await pool.query('SELECT * FROM reviews WHERE order_id = ? AND user_id = ?', [order_id, user_id]);
    if (existingReviews.length > 0) {
        return res.status(400).json({ message: 'You have already reviewed this order.' });
    }


    const [result] = await pool.query(
      'INSERT INTO reviews (user_id, master_id, order_id, rating, comment) VALUES (?, ?, ?, ?, ?)',
      [user_id, master_id, order_id, rating, comment]
    );
    const newReview = { id: result.insertId, user_id, master_id, order_id, rating, comment };

    // Update master's average rating
    const [ratings] = await pool.query('SELECT AVG(rating) as avg_rating FROM reviews WHERE master_id = ?', [master_id]);
    const avg_rating = ratings[0].avg_rating || 0;
    await pool.query('UPDATE masters SET rating = ? WHERE id = ?', [avg_rating, master_id]);


    res.status(201).json(newReview);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// Get all reviews for a master
const getReviewsForMaster = async (req, res) => {
  const { master_id } = req.params;
  try {
    const [reviews] = await pool.query(
        'SELECT r.*, u.first_name, u.last_name FROM reviews r JOIN users u ON r.user_id = u.id WHERE r.master_id = ? ORDER BY r.created_at DESC', 
        [master_id]
    );
    res.json(reviews);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { createReview, getReviewsForMaster };
