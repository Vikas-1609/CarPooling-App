const Ride = require('../models/Ride');

exports.postRide = async (req, res) => {
    const driverId = req.user._id;

    if (req.user.role !== 'driver') {
        return res.status(403).json({ message: 'Only registered drivers can post rides.' });
    }

    const {
        origin, destination, originAddress, destinationAddress,
        departureTime, availableSeats, pricePerSeat, carDescription, stopovers
    } = req.body;

    if (!origin || !destination || !originAddress || !destinationAddress || !departureTime || !availableSeats || !pricePerSeat) {
        return res.status(400).json({ message: 'Please provide all required ride details (locations, time, seats, price).' });
    }

    if (origin.type !== 'Point' || destination.type !== 'Point') {
        return res.status(400).json({ message: 'Origin and Destination must be GeoJSON Point objects.' });
    }

    try {
        const newRide = await Ride.create({
            driver: driverId,
            origin,
            destination,
            originAddress,
            destinationAddress,
            departureTime: new Date(departureTime),
            availableSeats,
            pricePerSeat,
            carDescription,
            stopovers: stopovers || [],
        });

        res.status(201).json({
            success: true,
            data: newRide,
            message: 'Ride posted successfully and is now available for booking.'
        });

    } catch (error) {
        res.status(500).json({
            message: 'Failed to post ride due to server error.',
            error: error.message
        });
    }
};

exports.getMyRides = async (req, res) => {
    try {
        const rides = await Ride.find({ driver: req.user._id }).sort({ departureTime: 1 });
        res.status(200).json({
            success: true,
            count: rides.length,
            data: rides
        });
    } catch (error) {
        res.status(500).json({ message: 'Could not fetch driver\'s rides.' });
    }
};

exports.searchRides = async (req, res) => {
    const {
        originLat, originLng,
        destLat, destLng,
        departureDate
    } = req.query;

    if (!originLat || !originLng || !destLat || !destLng || !departureDate) {
        return res.status(400).json({ message: 'Missing required search parameters (coordinates and date).' });
    }

    const searchOrigin = [parseFloat(originLng), parseFloat(originLat)];
    const searchDestination = [parseFloat(destLng), parseFloat(destLat)];

    const startOfDay = new Date(departureDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(departureDate);
    endOfDay.setHours(23, 59, 59, 999);

    const maxDistanceMeters = 5000;

    const query = {
        origin: {
            $nearSphere: {
                $geometry: {
                    type: "Point",
                    coordinates: searchOrigin
                },
                $maxDistance: maxDistanceMeters
            }
        },
        departureTime: {
            $gte: startOfDay,
            $lte: endOfDay
        },
        availableSeats: { $gt: 0 },
        status: 'scheduled'
    };

    try {
        let rides = await Ride.find(query)
            .select('-__v')
            .populate('driver', 'fullName rating role');

        const destToleranceKm = 10;
        const destToleranceMeters = destToleranceKm * 1000;

        const finalRides = rides.filter(ride => {
            const rideDestLng = ride.destination.coordinates[0];
            const rideDestLat = ride.destination.coordinates[1];
            
            const distance = getDistance(
                searchDestination[1], searchDestination[0],
                rideDestLat, rideDestLng
            );
            return distance <= destToleranceMeters;
        });

        res.status(200).json({
            success: true,
            count: finalRides.length,
            data: finalRides
        });

    } catch (error) {
        res.status(500).json({
            message: 'Failed to search rides due to server error.',
            error: error.message
        });
    }
};

const getDistance = (lat1, lon1, lat2, lon2) => {
    const R = 6371e3;
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
        Math.cos(φ1) * Math.cos(φ2) *
        Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    const distance = R * c;
    return distance;
};