const mongoose = require('mongoose');

const PointSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: ['Point'],
        required: true,
        default: 'Point'
    },
    coordinates: {
        type: [Number],
        required: true,
        validate: [(val) => val.length === 2, 'Coordinates must be an array of two numbers [lng, lat]']
    }
});

const RideSchema = new mongoose.Schema({
    driver: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    origin: {
        type: PointSchema,
        required: true,
    },
    destination: {
        type: PointSchema,
        required: true,
    },
    originAddress: { type: String, required: true },
    destinationAddress: { type: String, required: true },

    stopovers: [{
        location: PointSchema,
        address: String,
    }],

    departureTime: {
        type: Date,
        required: true,
    },
    availableSeats: {
        type: Number,
        required: true,
        min: 0,
        max: 8,
    },
    pricePerSeat: {
        type: Number,
        required: true,
        min: 0,
    },
    carDescription: {
        type: String,
    },
    status: {
        type: String,
        enum: ['scheduled', 'full', 'in-progress', 'completed', 'cancelled'],
        default: 'scheduled',
    },
}, {
    timestamps: true
});

RideSchema.index({ origin: '2dsphere' });
RideSchema.index({ destination: '2dsphere' });
RideSchema.index({ departureTime: 1 });


const Ride = mongoose.model('Ride', RideSchema);

module.exports = Ride;