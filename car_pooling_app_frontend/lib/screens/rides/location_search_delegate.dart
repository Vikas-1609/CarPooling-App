
import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../core/constants.dart';

class LocationSearchDelegate extends SearchDelegate<LocationResult?> {
  final LocationService _locationService = LocationService();

  @override
  String get searchFieldLabel => 'Search location...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 18),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.black),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.black,
      ),
      scaffoldBackgroundColor: kBackgroundColor,
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.length < 3) {
      return Center(
        child: Text(
          'Type at least 3 characters to search',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
        ),
      );
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<LocationResult>>(
      future: _locationService.searchLocations(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryTextColor),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error fetching locations',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return Center(
            child: Text(
              'No locations found for "$query"',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return ListTile(
              leading: const Icon(Icons.location_on, color: kPrimaryTextColor),
              title: Text(
                result.displayName,
                style: const TextStyle(color: kPrimaryTextColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                close(context, result);
              },
            );
          },
        );
      },
    );
  }
}
