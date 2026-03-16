const express = require('express');
const { postRide, getMyRides, searchRides } = require('../controllers/rideController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.route('/search')
    .get(searchRides);

router.route('/')
    .post(protect, postRide);

router.route('/myrides')
    .get(protect, getMyRides);

module.exports = router;