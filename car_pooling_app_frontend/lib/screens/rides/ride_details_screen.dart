import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/ride_model.dart';
import '../../services/booking_service.dart';
import '../../services/cashfree_service.dart';
import '../../core/constants.dart';
import '../reviews/driver_reviews_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final RideModel ride;

  const RideDetailsScreen({super.key, required this.ride});

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final BookingService _bookingService = BookingService();
  bool _isBooking = false;
  int _seatsToBook = 1;
  final CashfreeService _cashfreeService = CashfreeService();

  Map<String, dynamic>? _bookingData;

  @override
  void initState() {
    super.initState();
    _cashfreeService.init(
      onSuccess: (orderId) async {
        if (!mounted) return;
        setState(() {
          _isBooking = false;
        });
        if (_bookingData != null) {
          try {
            final message = await _bookingService.confirmBooking(
              orderId,
              _bookingData!,
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message), backgroundColor: Colors.green),
            );
            Navigator.of(context).pop();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment verified but failed to finalize: ${e.toString().replaceAll('Exception: ', '')}',
                ),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment Successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      },
      onError: (error, orderId) async {
        if (!mounted) return;
        setState(() {
          _isBooking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Failed or Cancelled: ${error.getMessage()}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dt);
  }

  void _bookRide() async {
    setState(() {
      _isBooking = true;
    });

    bool paymentStarted = false;
    try {
      final result = await _bookingService.createBooking(
        rideId: widget.ride.id,
        seatsBooked: _seatsToBook,


        pickupAddress: widget.ride.originAddress,
        dropoffAddress: widget.ride.destinationAddress,
        pickupLng: widget.ride.origin.coordinates[0],
        pickupLat: widget.ride.origin.coordinates[1],
        dropoffLng: widget.ride.destination.coordinates[0],
        dropoffLat: widget.ride.destination.coordinates[1],
      );

      if (!mounted) return;

      final message = result['message'] ?? 'Booking successful!';
      final paymentSessionId = result['paymentSessionId'];
      final orderId = result['cfOrderId'];

      _bookingData = result['bookingData'];

      if (paymentSessionId != null && orderId != null) {
        paymentStarted = true;

        await _cashfreeService.startPayment(
          sessionId: paymentSessionId,
          orderId: orderId,
        );
      } else {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted && !paymentStarted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: kBackgroundColor,
        elevation: 0,
        foregroundColor: kPrimaryTextColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Driver',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: kPrimaryTextColor.withOpacity(0.1),
                  child: Text(
                    widget.ride.driver.fullName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: kPrimaryTextColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ride.driver.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: kPrimaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.ride.driver.phone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DriverReviewsScreen(
                              driverId: widget.ride.driver.id,
                              driverName: widget.ride.driver.fullName,
                              averageRating: widget.ride.driver.averageRating,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.ride.driver.averageRating.toStringAsFixed(1)} Rating',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),


            const Text(
              'Route',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.circle_outlined,
                      size: 20,
                      color: Colors.blue,
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey.shade600,
                    ),
                    const Icon(Icons.location_on, size: 20, color: Colors.red),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ride.originAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 35),
                      Text(
                        widget.ride.destinationAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Departure',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(widget.ride.departureTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryTextColor,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Price per seat',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${widget.ride.pricePerSeat.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Seats: ${widget.ride.availableSeats}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryTextColor,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: kPrimaryTextColor,
                      ),
                      onPressed: () {
                        if (_seatsToBook > 1) {
                          setState(() => _seatsToBook--);
                        }
                      },
                    ),
                    Text(
                      '$_seatsToBook',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryTextColor,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: kPrimaryTextColor,
                      ),
                      onPressed: () {
                        if (_seatsToBook < widget.ride.availableSeats) {
                          setState(() => _seatsToBook++);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: (_isBooking || widget.ride.availableSeats == 0)
                  ? null
                  : _bookRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryTextColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isBooking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: kBackgroundColor,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      'Book Ride • ₹${(widget.ride.pricePerSeat * _seatsToBook).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kBackgroundColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
