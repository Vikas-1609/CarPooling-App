const mongoose = require('mongoose');

const BookingSchema = new mongoose.Schema({
    passenger: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    ride: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Ride',
        required: true,
    },
    seatsBooked: {
        type: Number,
        required: true,
        min: 1,
    },
    totalPrice: {
        type: Number,
        required: true,
        min: 0,
    },
    status: {
        type: String,
        enum: ['pending', 'accepted', 'rejected', 'cancelled_by_passenger', 'cancelled_by_driver', 'completed'],
        default: 'pending',
    },
    paymentIntentId: {
        type: String,
    },
    pickupAddress: { type: String, required: true },
    dropoffAddress: { type: String, required: true },
    pickupLocation: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point',
        },
        coordinates: {
            type: [Number],
            required: true,
        }
    },
    dropoffLocation: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point',
        },
        coordinates: {
            type: [Number],
            required: true,
        }
    },
    status: {
        type: String,
        enum: [
            'pending',
            'payment_authorized',
            'accepted',
            'rejected',
            'cancelled_by_passenger',
            'cancelled_by_driver',
            'completed',
            'failed'
        ],
        default: 'pending',
    },

}, {
    timestamps: true
});

const Booking = mongoose.model('Booking', BookingSchema);
module.exports = Booking;