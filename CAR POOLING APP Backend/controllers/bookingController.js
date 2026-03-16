const Booking = require('../models/Booking');
const Ride = require('../models/Ride');
const User = require('../models/User');
const { Cashfree } = require('../config/cashfree');
const {
    createCashfreeOrderSession,
    capturePayment,
    voidPayment
} = require('../services/paymentService');

exports.createBooking = async (req, res) => {
    const passengerId = req.user._id;
    const {
        rideId,
        seatsBooked,
        pickupAddress,
        dropoffAddress,
        pickupLng,
        pickupLat,
        dropoffLng,
        dropoffLat
    } = req.body;

    try {
        const ride = await Ride.findById(rideId);

        if (!ride || ride.status !== "scheduled") {
            return res.status(404).json({ message: "Ride not available" });
        }

        if (ride.availableSeats < seatsBooked) {
            return res.status(400).json({
                message: `Only ${ride.availableSeats} seats available`
            });
        }

        const totalPrice = ride.pricePerSeat * seatsBooked;
        const passenger = await User.findById(passengerId);

        const customerDetails = {
            id: passengerId.toString(),
            fullName: passenger.fullName,
            email: passenger.email,
            phoneNumber: passenger.phoneNumber
        };

        const orderId = "CF_" + Date.now();

        const cashfreeOrder = await createCashfreeOrderSession(
            totalPrice,
            orderId,
            customerDetails
        );

        res.status(200).json({
            success: true,
            message: "Proceed to payment",
            paymentSessionId: cashfreeOrder.paymentSessionId,
            cfOrderId: cashfreeOrder.cfOrderId,
            bookingData: {
                passengerId,
                rideId,
                seatsBooked,
                pickupAddress,
                dropoffAddress,
                pickupLng,
                pickupLat,
                dropoffLng,
                dropoffLat
            }
        });
    } catch (error) {
        res.status(500).json({
            message: "Failed to create order",
            error: error.message
        });
    }
};

exports.confirmBooking = async (req, res) => {
    const { orderId, bookingData } = req.body;

    try {
        const ride = await Ride.findById(bookingData.rideId);

        if (!ride) {
            return res.status(404).json({ message: "Ride not found" });
        }

        if (ride.availableSeats < bookingData.seatsBooked) {
            return res.status(400).json({
                message: "Seats not available"
            });
        }

        const totalPrice = ride.pricePerSeat * bookingData.seatsBooked;

        const booking = await Booking.create({
            passenger: bookingData.passengerId,
            ride: bookingData.rideId,
            seatsBooked: bookingData.seatsBooked,
            totalPrice,
            pickupAddress: bookingData.pickupAddress,
            dropoffAddress: bookingData.dropoffAddress,
            pickupLocation: {
                coordinates: [
                    parseFloat(bookingData.pickupLng),
                    parseFloat(bookingData.pickupLat)
                ]
            },
            dropoffLocation: {
                coordinates: [
                    parseFloat(bookingData.dropoffLng),
                    parseFloat(bookingData.dropoffLat)
                ]
            },
            paymentIntentId: orderId,
            status: "accepted"
        });

        ride.availableSeats -= bookingData.seatsBooked;

        if (ride.availableSeats === 0) {
            ride.status = "full";
        }

        await ride.save();

        res.json({
            success: true,
            message: "Booking confirmed successfully",
            data: booking
        });
    } catch (error) {
        res.status(500).json({
            message: "Booking confirmation failed"
        });
    }
};

exports.acceptBooking = async (req, res) => {
    const { bookingId } = req.params;
    const driverId = req.user._id;

    try {
        const booking = await Booking.findById(bookingId).populate('ride');

        if (!booking) {
            return res.status(404).json({ message: 'Booking not found.' });
        }

        if (booking.ride.driver.toString() !== driverId.toString()) {
            return res.status(403).json({ message: 'You are not the driver for this ride.' });
        }

        if (booking.status !== 'pending') {
            return res.status(400).json({ message: `Booking status is ${booking.status}, cannot be accepted.` });
        }

        booking.status = 'accepted';
        await booking.save();

        const ride = booking.ride;
        ride.availableSeats -= booking.seatsBooked;

        if (ride.availableSeats === 0) {
            ride.status = "full";
        }
        await ride.save();

        res.status(200).json({
            success: true,
            data: booking,
            message: 'Booking accepted and seats reserved!'
        });
    } catch (error) {
        res.status(500).json({ message: 'Failed to accept booking.' });
    }
};

exports.cancelBooking = async (req, res) => {
    const { bookingId } = req.params;
    const userRole = req.user.role;

    try {
        const booking = await Booking.findById(bookingId).populate('ride');

        if (!booking) {
            return res.status(404).json({ message: 'Booking not found.' });
        }

        if (booking.status !== 'pending' && booking.status !== 'accepted') {
            return res.status(400).json({ message: `Booking status is ${booking.status}, cancellation is no longer possible.` });
        }

        if (booking.paymentIntentId && booking.status === 'accepted') {
            await voidPayment(booking.paymentIntentId);
        }

        booking.status = userRole === 'passenger' ? 'cancelled_by_passenger' : 'cancelled_by_driver';
        await booking.save();

        if (booking.ride.availableSeats < booking.ride.seats) {
            const ride = booking.ride;
            ride.availableSeats += booking.seatsBooked;
            await ride.save();
        }

        res.status(200).json({
            success: true,
            data: booking,
            message: `Booking successfully cancelled by ${userRole}. Payment authorization voided.`
        });
    } catch (error) {
        res.status(500).json({ message: 'Failed to cancel booking.' });
    }
};

exports.getMyBookings = async (req, res) => {
    const userId = req.user._id.toString();

    try {
        const bookings = await Booking.find({
            $or: [
                { passenger: userId },
                {}
            ]
        })
        .populate({
            path: 'ride',
            populate: {
                path: 'driver',
                select: 'fullName phoneNumber averageRating role'
            }
        })
        .populate('passenger', 'fullName phoneNumber role');

        const myBookings = bookings.filter(b => {
            const isPassenger = b.passenger && b.passenger._id.toString() === userId;
            const isDriver = b.ride?.driver && b.ride.driver._id.toString() === userId;
            return isPassenger || isDriver;
        });

        res.status(200).json({
            success: true,
            count: myBookings.length,
            data: myBookings
        });
    } catch (error) {
        res.status(500).json({
            message: 'Failed to fetch your bookings.',
            error: error.message
        });
    }
};

exports.completeBooking = async (req, res) => {
    const { bookingId } = req.params;
    const driverId = req.user._id;

    try {
        const booking = await Booking.findById(bookingId).populate('ride');

        if (!booking) {
            return res.status(404).json({ message: 'Booking not found.' });
        }

        if (booking.ride.driver.toString() !== driverId.toString()) {
            return res.status(403).json({ message: 'You are not authorized to complete this trip.' });
        }

        if (booking.status !== 'accepted' && booking.status !== 'payment_authorized') {
            return res.status(400).json({ message: `Booking status is ${booking.status}, it cannot be completed.` });
        }

        if (booking.paymentIntentId) {
            const captureResponse = await capturePayment(booking.paymentIntentId, booking.totalPrice);

            if (captureResponse && captureResponse.success !== true) {
                return res.status(500).json({ message: 'Payment capture failed. Trip status NOT updated.' });
            }
        }

        booking.status = 'completed';
        await booking.save();

        res.status(200).json({
            success: true,
            data: booking,
            message: 'Trip completed. Payment captured successfully!'
        });
    } catch (error) {
        res.status(500).json({ message: 'Failed to complete trip or capture payment.' });
    }
};