const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { sendVerificationEmail } = require('../services/mailService');

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

const generateVerificationToken = (id) => {
    return jwt.sign({ id, type: 'email_verification' }, process.env.JWT_SECRET, {
        expiresIn: '1h',
    });
};

exports.registerUser = async (req, res) => {
    const { fullName, email, password, phoneNumber, role } = req.body;

    if (!fullName || !email || !password || !phoneNumber) {
        return res.status(400).json({ message: 'Please enter all fields' });
    }

    const userExists = await User.findOne({ email });

    if (userExists) {
        if (userExists.isVerified === false) {
             return res.status(400).json({ message: 'User already exists, but email is unverified. Check your inbox.' });
        }
        return res.status(400).json({ message: 'User already exists and is verified. Please log in.' });
    }

    let user;
    try {
        user = await User.create({
            fullName,
            email,
            password,
            phoneNumber,
            role: role || 'passenger',
        });

        if (user) {
            const verificationToken = generateVerificationToken(user._id);
            
            user.verificationToken = verificationToken;
            user.tokenExpires = Date.now() + 3600000;
            await user.save();

            await sendVerificationEmail(user.email, verificationToken);
            
            res.status(202).json({
                message: 'Registration successful! Please check your email to verify your account.',
                emailSentTo: user.email
            });
        } else {
            res.status(400).json({ message: 'Invalid user data' });
        }
    } catch (error) {
        if (user && user._id) {
            await User.deleteOne({ _id: user._id });
        }
        
        res.status(500).json({ 
            message: 'Server error during registration. Please try again.',
            error: error.message 
        });
    }
};

exports.verifyEmail = async (req, res) => {
    const { token } = req.params;

    try {
        const user = await User.findOne({ 
            verificationToken: token, 
            tokenExpires: { $gt: Date.now() }
        });

        if (!user) {
            return res.status(400).send('Verification link is invalid or has expired.');
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        if (decoded.id.toString() !== user._id.toString()) {
             return res.status(400).send('Verification failed: Token mismatch.');
        }

        user.isVerified = true;
        user.verificationToken = undefined;
        user.tokenExpires = undefined;
        await user.save();

        res.send('<h1>✅ Email Verified Successfully!</h1><p>You can now log in to the application.</p>');

    } catch (error) {
        res.status(500).send('An error occurred during verification.');
    }
};

exports.loginUser = async (req, res) => {
    const { email, password } = req.body;
    const user = await User.findOne({ email }).select('+password'); 

    if (user && (await user.matchPassword(password))) {
        
        if (user.isVerified === false) {
             return res.status(401).json({ 
                 message: 'Account not verified. Please check your email for the verification link.' 
             });
        }
        
        res.json({
            _id: user._id,
            fullName: user.fullName,
            email: user.email,
            role: user.role,
            isVerified: user.isVerified,
            token: generateToken(user._id),
        });
    } else {
        res.status(401).json({ message: 'Invalid email or password' });
    }
};

exports.getMe = async (req, res) => {
    res.json(req.user);
};