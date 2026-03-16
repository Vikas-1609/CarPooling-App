import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/constants.dart';
import 'package:car_pooling_app_frontend/screens/rides/ride_search_screen.dart';
import 'package:car_pooling_app_frontend/screens/bookings/my_bookings_screen.dart';
import 'package:car_pooling_app_frontend/screens/driver/driver_dashboard_screen.dart';
import 'package:car_pooling_app_frontend/screens/driver/post_ride_screen.dart';
import 'package:car_pooling_app_frontend/screens/profile/profile_screen.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title is under construction.')),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: kAccentColor)),
      );
    }

    final isDriver = user.role == 'driver';

    final List<Widget> screens = isDriver
        ? [
            const DriverDashboardScreen(),
            const PostRideScreen(),
            const ProfileScreen(),
          ]
        : [
            const RideSearchScreen(),
            const MyBookingsScreen(),
            const ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isDriver
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'Post Ride',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_online_outlined),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: navItems,
        selectedItemColor: kAccentColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: kBackgroundColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
