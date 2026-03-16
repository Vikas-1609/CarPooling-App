const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

exports.sendVerificationEmail = async (email, token) => {
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
        throw new Error("EMAIL_USER or EMAIL_PASS is missing in .env");
    }

    const verificationURL = `http://localhost:5000/api/users/verify/${token}`;

    const mailOptions = {
        from: `CarPooling Clone <${process.env.EMAIL_USER}>`,
        to: email,
        subject: 'Verify Your CarPooling Clone Account',
        html: `
            <div style="font-family: Arial, sans-serif; padding: 20px;">
                <h2>Welcome to CarPooling Clone!</h2>
                <p>Please verify your email address to complete your registration.</p>
                <a href="${verificationURL}" 
                   style="background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;">
                   Verify Email
                </a>
                <p style="margin-top: 20px; font-size: 0.9em;">This link will expire in 1 hour.</p>
            </div>
        `,
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        return info;
    } catch (error) {
        throw new Error("Failed to send verification email.");
    }
};
