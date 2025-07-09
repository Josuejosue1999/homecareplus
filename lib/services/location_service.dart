import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

class LocationService {
  static const String _locationKey = 'user_location';
  static const String _lastUpdateKey = 'location_last_update';
  static const String _googleMapsApiKey = 'AIzaSyA1g-UDJcfQS_33U3Sysxe9g4zlAOnpS3g';
  
  // Enhanced location detection with professional error handling
  static Future<UserLocation?> getCurrentLocation() async {
    try {
      print('🎯 === ENHANCED LOCATION DETECTION WITH GOOGLE MAPS API ===');
      
      // Check and request permissions
      final permissionStatus = await _checkAndRequestPermissions();
      if (!permissionStatus) {
        print('⚠️ Location permission denied');
        return await _getCachedLocation();
      }
      
      // Get high-precision location
      final position = await _getPositionWithRetry();
      if (position == null) {
        print('❌ Failed to get position');
        return await _getCachedLocation();
      }
      
      print('✅ Location obtained successfully');
      print('📍 Coordinates: ${position.latitude}, ${position.longitude}');
      print('🎯 Accuracy: ${position.accuracy.toStringAsFixed(1)}m');
      
      // Get address using Google Maps API
      final addressData = await _getAddressFromGoogleMaps(position.latitude, position.longitude);
      
      final userLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: addressData['formatted_address'] ?? 'Current Location',
        sector: addressData['sector'] ?? 'Unknown Sector',
        streetNumber: addressData['street_number'] ?? '',
        city: addressData['city'] ?? '',
        country: addressData['country'] ?? 'Rwanda',
        timestamp: DateTime.now(),
      );
      
      // Save to cache
      await _saveLocationToCache(userLocation);
      
      print('✅ Location detection completed successfully');
      print('📍 Address: ${userLocation.address}');
      print('🏘️ Sector: ${userLocation.sector}');
      
      return userLocation;
      
    } catch (e) {
      print('❌ Error in location detection: $e');
      return await _getCachedLocation();
    }
  }
  
  // Professional permission checking
  static Future<bool> _checkAndRequestPermissions() async {
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ Location service is disabled');
        return false;
      }
      
      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        print('🔄 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        return false;
      }
      
      print('✅ Location permission granted');
      return true;
      
    } catch (e) {
      print('❌ Error checking permissions: $e');
      return false;
    }
  }
  
  // Enhanced position detection with retry mechanism
  static Future<Position?> _getPositionWithRetry() async {
    int maxRetries = 3;
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        print('🔄 Position detection attempt $attempt/$maxRetries');
        
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: attempt == 1 ? LocationAccuracy.best : LocationAccuracy.high,
          timeLimit: Duration(seconds: 15 + (attempt * 5)),
          forceAndroidLocationManager: false,
        );
        
        print('✅ Position obtained on attempt $attempt');
        return position;
        
      } catch (e) {
        print('❌ Position attempt $attempt failed: $e');
        
        if (attempt < maxRetries) {
          print('🔄 Retrying in ${attempt * 2} seconds...');
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    
    print('❌ All position attempts failed');
    return null;
  }
  
  // Enhanced Google Maps API integration
  static Future<Map<String, String>> _getAddressFromGoogleMaps(double lat, double lng) async {
    try {
      print('🗺️ Getting address from Google Maps API...');
      
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_googleMapsApiKey&language=en';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final components = result['address_components'];
          
          String formattedAddress = result['formatted_address'] ?? '';
          String sector = '';
          String streetNumber = '';
          String city = '';
          String country = 'Rwanda';
          
          // Parse address components with enhanced logic
          for (var component in components) {
            final types = List<String>.from(component['types']);
            
            if (types.contains('street_number')) {
              streetNumber = component['long_name'];
            } else if (types.contains('sublocality_level_1') || types.contains('sublocality')) {
              sector = component['long_name'];
            } else if (types.contains('locality')) {
              city = component['long_name'];
            } else if (types.contains('administrative_area_level_1') && sector.isEmpty) {
              sector = component['long_name'];
            } else if (types.contains('administrative_area_level_2') && sector.isEmpty) {
              sector = component['long_name'];
            } else if (types.contains('country')) {
              country = component['long_name'];
            }
          }
          
          // Enhanced fallback logic
          if (sector.isEmpty) {
            // Try to extract from formatted address
            final parts = formattedAddress.split(',');
            if (parts.length > 1) {
              sector = parts[1].trim();
            } else if (city.isNotEmpty) {
              sector = city;
            } else {
              sector = 'Detected Area';
            }
          }
          
          print('✅ Address parsed successfully');
          print('📍 Formatted: $formattedAddress');
          print('🏘️ Sector: $sector');
          print('🏙️ City: $city');
          print('🌍 Country: $country');
          
          return {
            'formatted_address': formattedAddress,
            'sector': sector,
            'street_number': streetNumber,
            'city': city,
            'country': country,
          };
        } else {
          print('⚠️ Google Maps API returned: ${data['status']}');
          if (data['error_message'] != null) {
            print('❌ Error: ${data['error_message']}');
          }
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Error calling Google Maps API: $e');
    }
    
    // Return fallback data
    return {
      'formatted_address': 'Current Location',
      'sector': 'Unknown Sector',
      'street_number': '',
      'city': '',
      'country': 'Rwanda',
    };
  }
  
  // Professional distance calculation with Google Maps
  static Future<Map<String, dynamic>?> getDistanceFromGoogleMaps(
    double originLat, 
    double originLng, 
    double destLat, 
    double destLng
  ) async {
    try {
      print('🗺️ Calculating distance with Google Maps API...');
      
      final url = 'https://maps.googleapis.com/maps/api/distancematrix/json?'
          'origins=$originLat,$originLng&'
          'destinations=$destLat,$destLng&'
          'mode=driving&'
          'units=metric&'
          'avoid=tolls&'
          'key=$_googleMapsApiKey';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && 
            data['rows'].isNotEmpty && 
            data['rows'][0]['elements'].isNotEmpty) {
          
          final element = data['rows'][0]['elements'][0];
          
          if (element['status'] == 'OK') {
            print('✅ Distance calculated successfully');
            print('📏 Distance: ${element['distance']['text']}');
            print('⏱️ Duration: ${element['duration']['text']}');
            
            return {
              'distance': element['distance']['text'],
              'duration': element['duration']['text'],
              'distance_value': element['distance']['value'], // in meters
              'duration_value': element['duration']['value'], // in seconds
            };
          } else {
            print('⚠️ Distance calculation failed: ${element['status']}');
          }
        } else {
          print('⚠️ Distance Matrix API returned: ${data['status']}');
        }
      } else {
        print('❌ Distance Matrix HTTP Error: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Error calculating distance: $e');
    }
    
    return null;
  }
  
  // Force location detection after user action
  static Future<UserLocation?> forceLocationDetection() async {
    try {
      print('🎯 === FORCING LOCATION DETECTION ===');
      
      // Clear cache to force fresh detection
      await _clearLocationCache();
      
      // Wait for GPS to stabilize
      await Future.delayed(Duration(seconds: 2));
      
      // Get current location with enhanced accuracy
      return await getCurrentLocation();
      
    } catch (e) {
      print('❌ Error in forced location detection: $e');
      return await _getCachedLocation();
    }
  }
  
  // Professional distance calculation with fallback
  static Future<String> getDistanceFromUserWithGoogleMaps(double hospitalLat, double hospitalLon) async {
    try {
      final userLocation = await getCurrentLocation();
      if (userLocation == null) {
        return 'Distance unavailable';
      }
      
      // Try Google Maps Distance Matrix API first
      final googleDistance = await getDistanceFromGoogleMaps(
        userLocation.latitude,
        userLocation.longitude,
        hospitalLat,
        hospitalLon,
      );
      
      if (googleDistance != null) {
        return '${googleDistance['distance']} (${googleDistance['duration']})';
      }
      
      // Fallback to direct distance calculation
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        hospitalLat,
        hospitalLon,
      );
      
      return formatDistance(distance);
      
    } catch (e) {
      print('❌ Error calculating distance: $e');
      return 'Distance unavailable';
    }
  }
  
  // Standard distance calculation
  static Future<String> getDistanceFromUser(double hospitalLat, double hospitalLon) async {
    try {
      final userLocation = await getCurrentLocation();
      if (userLocation == null) {
        return 'Distance unavailable';
      }
      
      final distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        hospitalLat,
        hospitalLon,
      );
      
      return formatDistance(distance);
      
    } catch (e) {
      print('❌ Error calculating distance: $e');
      return 'Distance unavailable';
    }
  }
  
  // Utility functions
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      if (distanceInKm < 10) {
        return '${distanceInKm.toStringAsFixed(1)}km';
      } else {
        return '${distanceInKm.round()}km';
      }
    }
  }
  
  // Location availability checks
  static Future<bool> isLocationAvailable() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      return (permission == LocationPermission.whileInUse || 
              permission == LocationPermission.always) && serviceEnabled;
    } catch (e) {
      print('❌ Error checking location availability: $e');
      return false;
    }
  }
  
  static Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return false;
    }
  }
  
  static Future<bool> checkAndRequestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('❌ Error checking and requesting permission: $e');
      return false;
    }
  }
  
  // Cache management
  static Future<UserLocation?> getCachedLocation() async {
    return await _getCachedLocation();
  }
  
  static Future<void> _saveLocationToCache(UserLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = jsonEncode(location.toJson());
      await prefs.setString(_locationKey, locationJson);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      print('✅ Location saved to cache');
    } catch (e) {
      print('❌ Error saving location to cache: $e');
    }
  }
  
  static Future<UserLocation?> _getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString(_locationKey);
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      
      if (locationJson != null && lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final now = DateTime.now();
        
        // Check if cache is not too old (6 hours)
        if (now.difference(lastUpdate).inHours < 6) {
          final locationData = jsonDecode(locationJson) as Map<String, dynamic>;
          final location = UserLocation.fromJson(locationData);
          print('✅ Location loaded from cache');
          return location;
        } else {
          print('⚠️ Cached location is too old, clearing cache');
          await _clearLocationCache();
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error loading location from cache: $e');
      return null;
    }
  }
  
  static Future<void> _clearLocationCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_locationKey);
      await prefs.remove(_lastUpdateKey);
      print('✅ Location cache cleared');
    } catch (e) {
      print('❌ Error clearing location cache: $e');
    }
  }
}

// Enhanced UserLocation class with better data validation
class UserLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String sector;
  final String streetNumber;
  final String city;
  final String country;
  final DateTime timestamp;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.sector,
    required this.streetNumber,
    required this.city,
    required this.country,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'sector': sector,
      'streetNumber': streetNumber,
      'city': city,
      'country': country,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      address: json['address'] ?? 'Unknown Location',
      sector: json['sector'] ?? 'Unknown Sector',
      streetNumber: json['streetNumber'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? 'Rwanda',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Check if location is valid
  bool get isValid {
    return latitude != 0.0 && longitude != 0.0 && 
           latitude >= -90 && latitude <= 90 &&
           longitude >= -180 && longitude <= 180;
  }

  // Get formatted display string
  String get displayString {
    if (address.isNotEmpty && sector.isNotEmpty) {
      return '$address, $sector';
    } else if (address.isNotEmpty) {
      return address;
    } else if (sector.isNotEmpty) {
      return sector;
    } else {
      return 'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
    }
  }

  @override
  String toString() {
    return 'UserLocation(lat: $latitude, lng: $longitude, address: $address, sector: $sector)';
  }
} 