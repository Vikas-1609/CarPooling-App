const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
    res.json({ message: 'User routes working!' });
});

const userRoutes = require('./user');
const rideRoutes = require('./ride');
const bookingRoutes = require('./booking');
const reviewRoutes = require('./review');

router.use('/users', userRoutes);
router.use('/rides', rideRoutes);
router.use('/bookings', bookingRoutes);
router.use('/reviews', reviewRoutes);

module.exports = router;
