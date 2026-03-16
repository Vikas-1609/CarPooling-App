const express = require('express');
const { verifyPayment } = require('../controllers/paymentController');

const router = express.Router();

router.route('/verify')
    .post(verifyPayment)
    .get(verifyPayment);

module.exports = router;