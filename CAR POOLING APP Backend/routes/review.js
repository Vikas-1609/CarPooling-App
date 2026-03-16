const express = require('express');
const {
    submitReview,
    getReviewsForUser
} = require('../controllers/reviewController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.route('/')
    .post(protect, submitReview);

router.route('/:userId')
    .get(getReviewsForUser);

module.exports = router;