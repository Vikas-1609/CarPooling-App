const Booking = require('../models/Booking');
const { verifyPaymentStatus } = require('../services/paymentService');

exports.verifyPayment = async (req, res) => {
    const cfOrderId = req.body.cfOrderId || req.query.cfOrderId;

    if (!cfOrderId) {
        return res.status(400).json({ message: 'Missing Cashfree Order ID for verification.' });
    }

    try {
        const booking = await Booking.findOne({ paymentIntentId: cfOrderId });

        if (!booking) {
            return res.status(404).json({ message: 'Booking not found for this Order ID.' });
        }

        const officialStatus = await verifyPaymentStatus(cfOrderId);

        let newStatus = booking.status;
        let message = `Payment status: ${officialStatus}. Booking status remains ${booking.status}.`;

        if (officialStatus === 'SUCCESS' && booking.status === 'pending') {
            newStatus = 'payment_authorized';
            message = 'Payment successfully authorized. Waiting for driver acceptance.';
        } else if (officialStatus === 'FAILED' && booking.status === 'pending') {
            newStatus = 'failed';
            message = 'Payment failed. Booking terminated.';

            await Booking.deleteOne({ _id: booking._id });
            return res.status(200).json({ success: false, message: 'Payment failed. Booking deleted.' });
        }

        if (newStatus !== booking.status) {
            booking.status = newStatus;
            await booking.save();
        }

        res.status(200).json({
            success: true,
            bookingId: booking._id,
            newStatus: newStatus,
            message: message
        });

    } catch (error) {
        res.status(500).json({ message: 'Internal server error during payment verification.' });
    }
};