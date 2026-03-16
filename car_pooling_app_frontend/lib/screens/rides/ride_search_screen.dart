
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../core/constants.dart';
import '../../models/ride_model.dart';
import '../../services/ride_service.dart';
import '../../services/location_service.dart';
import '../../widgets/ride_card.dart';
import 'location_search_delegate.dart';
import 'ride_details_screen.dart'; // Import RideDetailsScreen

class RideSearchScreen extends StatefulWidget {
  const RideSearchScreen({super.key});

  @override
  State<RideSearchScreen> createState() => _RideSearchScreenState();
}

class _RideSearchScreenState extends State<RideSearchScreen> {
  final RideService _rideService = RideService();
  final MapController _mapController = MapController();

  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  double? _originLat;
  double? _originLng;
  double? _destLat;
  double? _destLng;
  DateTime? _selectedDate;

  final LatLng _defaultCenter = const LatLng(28.6139, 77.2090);

  List<RideModel> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _updateDateTextField();
  }

  void _updateDateTextField() {
    if (_selectedDate != null) {
      _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate!);
    }
  }
  
  String _getFormattedDateForApi() {
    if (_selectedDate == null) return '';
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(_selectedDate!.toUtc());
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_hasSearched) {
      setState(() {
        _hasSearched = false;
      });
      FocusScope.of(context).unfocus();
    }
  }
  void _searchRides() async {
    FocusScope.of(context).unfocus();

    if (_originLat == null || _originLng == null || _destLat == null || _destLng == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Origin and Destination on the map first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      final formattedDate = _getFormattedDateForApi();
final results = await _rideService.searchRides(
        originLat: _originLat!,
        originLng: _originLng!,
        destLat: _destLat!,
        destLng: _destLng!,
        departureDate: formattedDate,
      );

      setState(() {
        _searchResults = results;
      });

      if (results.isNotEmpty) {
         _fitMapToBounds();
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Search Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fitMapToBounds() {
    if (_originLat != null && _originLng != null && _destLat != null && _destLng != null) {
      final bounds = LatLngBounds.fromPoints([
        LatLng(_originLat!, _originLng!),
        LatLng(_destLat!, _destLng!),
      ]);
      _mapController.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ));
    }
  }

  @override
  void dispose() {
    _originController.dispose();
    _destController.dispose();
    _dateController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.carpooling',
              ),
              MarkerLayer(
                markers: [
                  if (_originLat != null && _originLng != null)
                    Marker(
                      point: LatLng(_originLat!, _originLng!),
                      child: const _AnimatedMapMarker(icon: Icons.location_on, color: Colors.blue),
                    ),
                  if (_destLat != null && _destLng != null)
                    Marker(
                      point: LatLng(_destLat!, _destLng!),
                      child: const _AnimatedMapMarker(icon: Icons.location_on, color: Colors.red),
                    ),
                ],
              ),
            ],
          ),

          Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: _buildFloatingSearchCard(),
            ),

          if (_hasSearched)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                return false; 
              },
              child: DraggableScrollableSheet(
                initialChildSize: 0.4,
                minChildSize: 0.1,
                maxChildSize: 0.8,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 0),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available Rides',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryTextColor,
                                ),
                              ),
                              Row(
                                children: [
                                  if (!_isLoading)
                                    Text(
                                      '${_searchResults.length} found',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(width: 10),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _hasSearched = false;
                                      });
                                    },
                                    child: const Icon(Icons.close, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        Expanded(
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : _searchResults.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.directions_car_filled_outlined, size: 60, color: Colors.grey.shade400),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No rides found.',
                                            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: scrollController,
                                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                      itemCount: _searchResults.length,
                                      itemBuilder: (context, index) {
                                        final ride = _searchResults[index];
                                        return RideCard(
                                          ride: ride,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => RideDetailsScreen(ride: ride),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingSearchCard() {
    return Card(
      elevation: 8,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _originController,
              readOnly: true,
              style: const TextStyle(color: Colors.black),
              onTap: () async {
                final result = await showSearch<LocationResult?>(
                  context: context,
                  delegate: LocationSearchDelegate(),
                );
                if (result != null) {
                  setState(() {
                    _originLat = result.location.latitude;
                    _originLng = result.location.longitude;
                    _originController.text = result.displayName.split(',').first;
                    _hasSearched = false;
                  });
                  _mapController.move(result.location, 14.0);
                }
              },
              decoration: InputDecoration(
                hintText: 'Tap to search Origin...',
                hintStyle: TextStyle(color: Colors.grey.shade700),
                prefixIcon: const Icon(Icons.circle_outlined, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 10),
            
            TextField(
              controller: _destController,
              readOnly: true,
              style: const TextStyle(color: Colors.black),
              onTap: () async {
                final result = await showSearch<LocationResult?>(
                  context: context,
                  delegate: LocationSearchDelegate(),
                );
                if (result != null) {
                  setState(() {
                    _destLat = result.location.latitude;
                    _destLng = result.location.longitude;
                    _destController.text = result.displayName.split(',').first;
                    _hasSearched = false;
                  });
                  if (_originLat != null && _originLng != null) {
                    _fitMapToBounds();
                  } else {
                    _mapController.move(result.location, 14.0);
                  }
                }
              },
              decoration: InputDecoration(
                hintText: 'Tap to search Destination...',
                hintStyle: TextStyle(color: Colors.grey.shade700),
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 10),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _dateController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Date',
                      hintStyle: TextStyle(color: Colors.grey.shade700),
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: kBackgroundColor,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                          _updateDateTextField();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _searchRides,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Search', style: TextStyle(color: kBackgroundColor)),
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
}

class _AnimatedMapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _AnimatedMapMarker({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          alignment: Alignment.bottomCenter,
          scale: value,
          child: child,
        );
      },
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Icon(icon, color: color, size: 40, shadows: const [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))]),
      ),
    );
  }
}

