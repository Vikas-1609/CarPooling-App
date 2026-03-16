
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import 'package:intl/intl.dart';
import 'driver_pending_bookings_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final RideService _rideService = RideService();
  final BookingService _bookingService = BookingService();
  late Future<List<dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  void _fetchDashboardData() {
    setState(() {
      _dashboardDataFuture =
          Future.wait([
            _rideService.getMyRides(),
            _bookingService.getMyBookings(),
          ]).then((results) {
            final rides = results[0] as List<RideModel>;
            final bookings = results[1] as List<BookingModel>;

            Map<String, int> pendingCounts = {};
            Map<String, String> rideBadges = {};
            for (var ride in rides) {
              final rideBookings = bookings.where((b) => b.ride?.id == ride.id).toList();
              
              pendingCounts[ride.id] = rideBookings
                  .where((b) => b.status == 'pending')
                  .length;
                  
              bool hasBookings = rideBookings.isNotEmpty;
              bool allFinished = rideBookings.every((b) => b.status == 'completed' || b.status == 'cancelled');
              bool hasCompleted = rideBookings.any((b) => b.status == 'completed');
              bool hasAccepted = rideBookings.any((b) => b.status == 'accepted');
              
              String badge = '';
              if (ride.status == 'completed' || (hasBookings && allFinished && hasCompleted)) {
                 badge = 'COMPLETED';
              } else if (ride.status == 'accepted' || hasAccepted) {
                 badge = 'ACCEPTED';
              }
              
              rideBadges[ride.id] = badge;
            }
            return [rides, pendingCounts, rideBadges];
          });
    });
  }

  Widget _buildRideCard(RideModel ride, int pendingCount, String badgeText) {
    return Card(
      color: kInputFieldColor,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  DriverPendingBookingsScreen(rideId: ride.id),
            ),
          );
          if (mounted) {
            _fetchDashboardData();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(ride.departureTime),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (badgeText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeText == 'COMPLETED' ? Colors.black87 : Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kAccentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${ride.pricePerSeat}/seat',
                      style: const TextStyle(
                        color: kAccentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.my_location, color: kAccentColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.originAddress,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 9.0, top: 2, bottom: 2),
                child: SizedBox(
                  height: 15,
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
                      ride.destinationAddress,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Available Seats: ${ride.availableSeats}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingCount New Request${pendingCount > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
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
          'My Posted Rides',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dashboardDataFuture,
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
          } else if (!snapshot.hasData || (snapshot.data![0] as List).isEmpty) {
            return const Center(
              child: Text(
                'You haven\'t posted any rides yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final rides = snapshot.data![0] as List<RideModel>;
          final pendingCounts = snapshot.data![1] as Map<String, int>;
          final rideBadges = snapshot.data![2] as Map<String, String>;

          return RefreshIndicator(
            onRefresh: () async => _fetchDashboardData(),
            color: kAccentColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rides.length,
              itemBuilder: (context, index) {
                final rideId = rides[index].id;
                return _buildRideCard(
                  rides[index],
                  pendingCounts[rideId] ?? 0,
                  rideBadges[rideId] ?? '',
                );
              },
            ),
          );
        },
      ),
    );
  }
}
