
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import 'package:intl/intl.dart';

class DriverPendingBookingsScreen extends StatefulWidget {
  final String rideId;

  const DriverPendingBookingsScreen({super.key, required this.rideId});

  @override
  State<DriverPendingBookingsScreen> createState() =>
      _DriverPendingBookingsScreenState();
}

class _DriverPendingBookingsScreenState
    extends State<DriverPendingBookingsScreen> {
  final BookingService _bookingService = BookingService();
  late Future<List<BookingModel>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  void _fetchBookings() {
    setState(() {
      _bookingsFuture = _bookingService.getMyBookings().then((allBookings) {
        return allBookings
            .where((booking) => booking.ride?.id == widget.rideId)
            .toList();
      });
    });
  }

  Future<void> _handleAction(String action, String bookingId) async {
    try {
      if (action == 'accept') {
        await _bookingService.acceptBooking(bookingId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Booking Accepted')));
        }
      } else if (action == 'complete') {
        await _bookingService.completeBooking(bookingId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Booking Completed')));
        }
      } else if (action == 'cancel') {
        await _bookingService.cancelBooking(bookingId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Booking Cancelled')));
        }
      }
      _fetchBookings(); // Refresh list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Widget _buildBookingCard(BookingModel booking) {
    return Card(
      color: kInputFieldColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.passenger?.fullName ?? 'Passenger',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: booking.status == 'pending'
                        ? Colors.orange.withOpacity(0.2)
                        : (booking.status == 'accepted'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: TextStyle(
                      color: booking.status == 'pending'
                          ? Colors.orange
                          : (booking.status == 'accepted'
                                ? Colors.green
                                : Colors.grey),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: kAccentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.pickupAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 9.0, top: 4, bottom: 4),
              child: SizedBox(
                height: 20,
                child: VerticalDivider(color: Colors.grey, thickness: 1),
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking.dropoffAddress,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${booking.seatsBooked} Seat(s)',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(booking.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (booking.status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleAction('cancel', booking.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAction('accept', booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (booking.status == 'accepted')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleAction('cancel', booking.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel Request'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAction('complete', booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryTextColor,
                      ),
                      child: const Text(
                        'Mark Complete',
                        style: TextStyle(color: kBackgroundColor),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Ride Requests',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryTextColor),
      ),
      body: FutureBuilder<List<BookingModel>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kAccentColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No requests found for this ride.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final bookings = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _fetchBookings(),
            color: kAccentColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                return _buildBookingCard(bookings[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
