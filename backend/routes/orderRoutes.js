const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { protect } = require('../middleware/authMiddleware');

// @route   POST api/orders
// @desc    Create a new order
// @access  Private
router.post('/', protect, orderController.createOrder);

// @route   GET api/orders
// @desc    Get all orders for a user or master
// @access  Private
router.get('/', protect, orderController.getOrders);

// @route   PUT api/orders/:id
// @desc    Update order status
// @access  Private
router.put('/:id', protect, orderController.updateOrderStatus);

module.exports = router;
