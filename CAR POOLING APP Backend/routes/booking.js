const express = require('express');
const {
    createBooking,
    acceptBooking,
    cancelBooking,
    getMyBookings,
    completeBooking,
    confirmBooking
} = require('../controllers/bookingController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.route('/')
    .post(protect, createBooking);

router.post("/create-order", protect, createBooking);

router.post("/confirm", protect, confirmBooking);

router.route('/mybookings')
    .get(protect, getMyBookings);

router.route('/:bookingId/accept')
    .put(protect, acceptBooking);

router.route('/:bookingId/complete')
    .put(protect, completeBooking);

router.route('/:bookingId/cancel')
    .put(protect, cancelBooking);

module.exports = router;
