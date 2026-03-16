const express = require('express');
const { 
    registerUser, 
    loginUser, 
    getMe,
    verifyEmail 
} = require('../controllers/userController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/signup', registerUser);
router.post('/login', loginUser);
router.get('/verify/:token', verifyEmail);

router.get('/me', protect, getMe);

module.exports = router;