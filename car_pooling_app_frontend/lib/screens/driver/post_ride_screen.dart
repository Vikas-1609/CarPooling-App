
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/ride_service.dart';
import 'package:intl/intl.dart';
import '../main_navigation_screen.dart';
import '../rides/location_search_delegate.dart';
import '../../services/location_service.dart';

class PostRideScreen extends StatefulWidget {
  const PostRideScreen({super.key});

  @override
  State<PostRideScreen> createState() => _PostRideScreenState();
}

class _PostRideScreenState extends State<PostRideScreen> {
  final _formKey = GlobalKey<FormState>();
  final RideService _rideService = RideService();
  bool _isLoading = false;

  final TextEditingController _originAddressController =
      TextEditingController();
  final TextEditingController _originLatController = TextEditingController();
  final TextEditingController _originLngController = TextEditingController();

  final TextEditingController _destAddressController = TextEditingController();
  final TextEditingController _destLatController = TextEditingController();
  final TextEditingController _destLngController = TextEditingController();

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();
  final TextEditingController _carDescriptionController =
      TextEditingController();

  DateTime? _selectedDate;

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: kAccentColor,
              onPrimary: Colors.white,
              surface: kInputFieldColor,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: kAccentColor,
                onPrimary: Colors.white,
                surface: kInputFieldColor,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _submitRide() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a departure time')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final message = await _rideService.postRide(
          originAddress: _originAddressController.text.trim(),
          destinationAddress: _destAddressController.text.trim(),
          originLat: double.tryParse(_originLatController.text) ?? 0.0,
          originLng: double.tryParse(_originLngController.text) ?? 0.0,
          destLat: double.tryParse(_destLatController.text) ?? 0.0,
          destLng: double.tryParse(_destLngController.text) ?? 0.0,
          departureTime: _selectedDate!.toIso8601String(),
          availableSeats: int.parse(_seatsController.text),
          pricePerSeat: double.parse(_priceController.text),
          carDescription: _carDescriptionController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: kInputFieldColor,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Post a Ride',
          style: TextStyle(color: kPrimaryTextColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Route Details',
                style: TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _originAddressController,
                readOnly: true,
                style: const TextStyle(color: Colors.black),
                onTap: () async {
                  final result = await showSearch<LocationResult?>(
                    context: context,
                    delegate: LocationSearchDelegate(),
                  );
                  if (result != null) {
                    setState(() {
                      _originLatController.text = result.location.latitude
                          .toString();
                      _originLngController.text = result.location.longitude
                          .toString();
                      _originAddressController.text = result.displayName;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Origin Address',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Tap to search Origin...',
                  hintStyle: TextStyle(color: Colors.grey.shade700),
                  prefixIcon: const Icon(
                    Icons.circle_outlined,
                    color: Colors.blue,
                  ),
                  filled: true,
                  fillColor: kInputFieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _destAddressController,
                readOnly: true,
                style: const TextStyle(color: Colors.black),
                onTap: () async {
                  final result = await showSearch<LocationResult?>(
                    context: context,
                    delegate: LocationSearchDelegate(),
                  );
                  if (result != null) {
                    setState(() {
                      _destLatController.text = result.location.latitude
                          .toString();
                      _destLngController.text = result.location.longitude
                          .toString();
                      _destAddressController.text = result.displayName;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Destination Address',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: 'Tap to search Destination...',
                  hintStyle: TextStyle(color: Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                  filled: true,
                  fillColor: kInputFieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Ride Details',
                style: TextStyle(
                  color: kPrimaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              InkWell(
                onTap: _pickDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kInputFieldColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select Departure Time'
                            : DateFormat(
                                'MMM dd, yyyy - HH:mm',
                              ).format(_selectedDate!),
                        style: TextStyle(
                          color: _selectedDate == null
                              ? Colors.grey
                              : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _seatsController,
                      'Available Seats',
                      'e.g., 3',
                      type: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      _priceController,
                      'Price per Seat (₹)',
                      'e.g., 150',
                      type: TextInputType.number,
                    ),
                  ),
                ],
              ),

              _buildTextField(
                _carDescriptionController,
                'Car Model & Color',
                'e.g., Silver Honda City (HR26 DQ 1234)',
              ),

              const SizedBox(height: 30),
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: kBackgroundColor)
                      : const Text(
                          'Post Ride',
                          style: TextStyle(
                            color: kBackgroundColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
