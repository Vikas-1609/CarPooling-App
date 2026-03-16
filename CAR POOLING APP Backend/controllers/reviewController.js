const mongoose = require('mongoose');
const Review = require('../models/Review');
const Booking = require('../models/Booking');
const User = require('../models/User');

const updateAverageRating = async (userId) => {
    try {
        let revieweeId;
        if (mongoose.isValidObjectId(userId)) {
            revieweeId = (typeof userId === 'string') ? new mongoose.Types.ObjectId(userId) : userId;
        } else {
            throw new Error('Invalid userId provided to updateAverageRating');
        }

        const stats = await Review.aggregate([
            { $match: { reviewee: revieweeId } },
            {
                $group: {
                    _id: '$reviewee',
                    averageRating: { $avg: '$rating' },
                    numReviews: { $sum: 1 }
                }
            },
            {
                $project: {
                    _id: 1,
                    numReviews: 1,
                    averageRating: { $round: ['$averageRating', 1] }
                }
            }
        ]).catch(async (err) => {
            if (err && /unknown operator '\$round'|Unrecognized pipeline stage name '\$round'/.test(err.message)) {
                const fallbackStats = await Review.aggregate([
                    { $match: { reviewee: revieweeId } },
                    {
                        $group: {
                            _id: '$reviewee',
                            averageRating: { $avg: '$rating' },
                            numReviews: { $sum: 1 }
                        }
                    }
                ]);
                return fallbackStats;
            }
            throw err;
        });

        let averageRating = 0;
        let numReviews = 0;

        if (Array.isArray(stats) && stats.length > 0) {
            numReviews = stats[0].numReviews || 0;
            if (typeof stats[0].averageRating === 'number') {
                averageRating = Number(stats[0].averageRating);
            } else {
                const rawAvg = stats[0].averageRating || 0;
                averageRating = typeof rawAvg === 'number' ? parseFloat(rawAvg.toFixed(1)) : 0;
            }
        }

        await User.findByIdAndUpdate(
            revieweeId,
            {
                $set: {
                    averageRating: averageRating,
                    numReviews: numReviews
                }
            },
            { runValidators: true, new: true }
        );

        return { averageRating, numReviews };
    } catch (err) {
        throw err;
    }
};

exports.submitReview = async (req, res) => {
    const reviewerId = req.user._id;
    const { bookingId, revieweeId, rating, comment } = req.body;

    if (!bookingId || !revieweeId || !rating) {
        return res.status(400).json({ message: 'Missing required fields: bookingId, revieweeId, and rating.' });
    }

    try {
        const booking = await Booking.findById(bookingId).populate('ride');

        if (!booking || booking.status !== 'completed') {
            return res.status(400).json({ message: 'Review can only be submitted for completed bookings.' });
        }

        const isPassenger = booking.passenger.toString() === reviewerId.toString();
        const isDriver = booking.ride.driver.toString() === reviewerId.toString();

        if (!isPassenger && !isDriver) {
            return res.status(403).json({ message: 'You were not a participant in this booking.' });
        }

        if (revieweeId.toString() !== booking.passenger.toString() && revieweeId.toString() !== booking.ride.driver.toString()) {
            return res.status(400).json({ message: 'The person you are reviewing must be the other participant in the booking.' });
        }

        if (reviewerId.toString() === revieweeId.toString()) {
            return res.status(400).json({ message: 'You cannot review yourself.' });
        }

        const existingReview = await Review.findOne({ reviewer: reviewerId, reviewee: revieweeId, booking: bookingId });
        if (existingReview) {
            return res.status(400).json({ message: 'You have already submitted a review for this trip.' });
        }

        const review = await Review.create({
            reviewer: reviewerId,
            reviewee: revieweeId,
            ride: booking.ride._id,
            booking: bookingId,
            rating,
            comment,
        });

        await updateAverageRating(revieweeId);

        res.status(201).json({
            success: true,
            data: review,
            message: 'Review submitted successfully. User rating updated.'
        });

    } catch (error) {
        if (error.code === 11000) {
            return res.status(400).json({ message: 'You have already submitted a review for this specific trip.' });
        }
        res.status(500).json({
            message: 'Failed to submit review due to server error.',
            error: error.message
        });
    }
};

exports.getReviewsForUser = async (req, res) => {
    const { userId } = req.params;

    try {
        const reviews = await Review.find({ reviewee: userId })
            .populate('reviewer', 'fullName averageRating')
            .sort({ createdAt: -1 });

        res.status(200).json({
            success: true,
            count: reviews.length,
            data: reviews
        });
    } catch (error) {
        res.status(500).json({ message: 'Failed to fetch reviews.' });
    }
};