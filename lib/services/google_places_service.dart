import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hospital.dart';
import '../services/location_service.dart';
import 'dart:math' as math;

class GooglePlacesService {
  static const String _apiKey = 'AIzaSyA1g-UDJcfQS_33U3Sysxe9g4zlAOnpS3g';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Fetch nearby hospitals using Google Places API
  static Future<List<Hospital>> getNearbyHospitals({
    double? latitude,
    double? longitude,
    int radius = 10000, // 10km radius
  }) async {
    try {
      print('🏥 Starting Google Places API request for nearby hospitals...');
      
      // Get current location if not provided
      double lat = latitude ?? 0.0;
      double lng = longitude ?? 0.0;
      
      if (latitude == null || longitude == null) {
        final userLocation = await LocationService.getCurrentLocation();
        if (userLocation != null) {
          lat = userLocation.latitude;
          lng = userLocation.longitude;
        } else {
          throw Exception('Unable to get current location');
        }
      }

      final url = '$_baseUrl/nearbysearch/json?'
          'location=$lat,$lng&'
          'radius=$radius&'
          'type=hospital&'
          'key=$_apiKey';

      print('🌍 Places API URL: $url');
      print('📍 Searching near: $lat, $lng');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Places API response status: ${data['status']}');
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          print('🏥 Found ${results.length} hospitals from Google Places');
          
          List<Hospital> hospitals = [];
          
          for (var result in results) {
            try {
              final hospital = _convertPlaceToHospital(result);
              hospitals.add(hospital);
              print('✅ Converted hospital: ${hospital.name}');
            } catch (e) {
              print('❌ Error converting place to hospital: $e');
            }
          }
          
          print('🎉 Successfully converted ${hospitals.length} hospitals');
          return hospitals;
        } else {
          print('❌ Places API error: ${data['status']} - ${data['error_message']}');
          throw Exception('Google Places API error: ${data['status']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching nearby hospitals: $e');
      throw e;
    }
  }

  // Convert Google Places result to Hospital model
  static Hospital _convertPlaceToHospital(Map<String, dynamic> place) {
    final geometry = place['geometry'] as Map<String, dynamic>;
    final location = geometry['location'] as Map<String, dynamic>;
    
    // Get photo reference for the first photo if available
    String? photoReference;
    if (place['photos'] != null && (place['photos'] as List).isNotEmpty) {
      photoReference = place['photos'][0]['photo_reference'];
    }
    
    // Build photo URL if photo reference exists
    String? photoUrl;
    if (photoReference != null) {
      photoUrl = '$_baseUrl/photo?'
          'maxwidth=400&'
          'photo_reference=$photoReference&'
          'key=$_apiKey';
    }
    
    return Hospital(
      id: place['place_id'] ?? '',
      name: place['name'] ?? 'Unknown Hospital',
      email: '', // Google Places hospitals don't have email
      location: place['vicinity'] ?? place['formatted_address'] ?? 'Address not available',
      profileImageUrl: photoUrl,
      latitude: location['lat']?.toDouble() ?? 0.0,
      longitude: location['lng']?.toDouble() ?? 0.0,
      facilities: _extractFacilities(place),
      about: 'Healthcare facility - ${place['name']}',
      availableSchedule: _getDefaultSchedule(),
      isVerified: false, // Google Places hospitals are not verified for booking
      createdAt: DateTime.now(),
      verified: false, // Google Places hospitals are not verified for booking
      isFromGooglePlaces: true, // Flag to identify Google Places hospitals
      rating: place['rating']?.toDouble() ?? 4.0,
      userRatingsTotal: place['user_ratings_total'] ?? 0,
      priceLevel: place['price_level'],
      openingHours: _extractOpeningHours(place),
      placeId: place['place_id'],
    );
  }

  // Extract facilities from Google Places types
  static List<String> _extractFacilities(Map<String, dynamic> place) {
    final types = place['types'] as List<dynamic>? ?? [];
    List<String> facilities = [];
    
    // Map Google Places types to our facilities
    final typeMapping = {
      'hospital': 'General Hospital',
      'health': 'Health Services',
      'doctor': 'Medical Consultation',
      'pharmacy': 'Pharmacy',
      'dentist': 'Dental Care',
      'physiotherapist': 'Physiotherapy',
      'veterinary_care': 'Veterinary Care',
      'emergency_room': 'Emergency Services',
    };
    
    for (String type in types) {
      if (typeMapping.containsKey(type)) {
        facilities.add(typeMapping[type]!);
      }
    }
    
    // Add default facilities if none found
    if (facilities.isEmpty) {
      facilities.addAll(['General Care', 'Consultation', 'Emergency Services']);
    }
    
    return facilities;
  }

  // Extract opening hours from Google Places
  static Map<String, Map<String, String>> _extractOpeningHours(Map<String, dynamic> place) {
    // Default schedule
    Map<String, Map<String, String>> schedule = _getDefaultSchedule();
    
    if (place['opening_hours'] != null) {
      final openingHours = place['opening_hours'] as Map<String, dynamic>;
      if (openingHours['weekday_text'] != null) {
        final weekdayText = openingHours['weekday_text'] as List<dynamic>;
        
        final dayMapping = {
          'Monday': 'Monday',
          'Tuesday': 'Tuesday',
          'Wednesday': 'Wednesday',
          'Thursday': 'Thursday',
          'Friday': 'Friday',
          'Saturday': 'Saturday',
          'Sunday': 'Sunday',
        };
        
        for (String dayText in weekdayText) {
          for (String day in dayMapping.keys) {
            if (dayText.toLowerCase().contains(day.toLowerCase())) {
              // Extract time from text like "Monday: 8:00 AM – 6:00 PM"
              final timePart = dayText.split(': ').length > 1 ? dayText.split(': ')[1] : '';
              if (timePart.isNotEmpty && !timePart.toLowerCase().contains('closed')) {
                final times = timePart.split(' – ');
                if (times.length == 2) {
                  schedule[dayMapping[day]!] = {
                    'startTime': _convertTo24Hour(times[0].trim()),
                    'endTime': _convertTo24Hour(times[1].trim()),
                  };
                }
              }
              break;
            }
          }
        }
      }
    }
    
    return schedule;
  }

  // Convert 12-hour format to 24-hour format
  static String _convertTo24Hour(String time12) {
    try {
      final parts = time12.split(' ');
      if (parts.length != 2) return time12;
      
      final timePart = parts[0];
      final ampm = parts[1].toLowerCase();
      
      final timeParts = timePart.split(':');
      if (timeParts.length != 2) return time12;
      
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      
      if (ampm == 'pm' && hour != 12) {
        hour += 12;
      } else if (ampm == 'am' && hour == 12) {
        hour = 0;
      }
      
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time12;
    }
  }

  // Get default schedule
  static Map<String, Map<String, String>> _getDefaultSchedule() {
    return {
      'Monday': {'startTime': '08:00', 'endTime': '17:00'},
      'Tuesday': {'startTime': '08:00', 'endTime': '17:00'},
      'Wednesday': {'startTime': '08:00', 'endTime': '17:00'},
      'Thursday': {'startTime': '08:00', 'endTime': '17:00'},
      'Friday': {'startTime': '08:00', 'endTime': '17:00'},
      'Saturday': {'startTime': '09:00', 'endTime': '15:00'},
      'Sunday': {'startTime': '', 'endTime': ''},
    };
  }

  // Get place details for more information
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final url = '$_baseUrl/details/json?'
          'place_id=$placeId&'
          'fields=name,rating,formatted_phone_number,formatted_address,opening_hours,website,photos,reviews,user_ratings_total&'
          'key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }

  // Fetch Google Places reviews for a specific place
  static Future<List<Map<String, dynamic>>> getPlaceReviews(String placeId) async {
    try {
      final placeDetails = await getPlaceDetails(placeId);
      if (placeDetails != null && placeDetails['reviews'] != null) {
        return List<Map<String, dynamic>>.from(placeDetails['reviews']);
      }
      return [];
    } catch (e) {
      print('Error getting place reviews: $e');
      return [];
    }
  }

  // Get enhanced facilities with icons mapping
  static List<Map<String, dynamic>> getEnhancedFacilities(Map<String, dynamic> place) {
    final types = place['types'] as List<dynamic>? ?? [];
    List<Map<String, dynamic>> facilities = [];
    
    // Enhanced facility mapping with icons
    final facilityMapping = {
      'hospital': {'name': 'General Hospital', 'icon': 'local_hospital'},
      'health': {'name': 'Health Services', 'icon': 'health_and_safety'},
      'doctor': {'name': 'Medical Consultation', 'icon': 'medical_services'},
      'pharmacy': {'name': 'Pharmacy', 'icon': 'local_pharmacy'},
      'dentist': {'name': 'Dental Care', 'icon': 'dentistry'},
      'physiotherapist': {'name': 'Physiotherapy', 'icon': 'accessibility'},
      'veterinary_care': {'name': 'Veterinary Care', 'icon': 'pets'},
      'emergency_room': {'name': 'Emergency Services', 'icon': 'emergency'},
    };
    
    for (String type in types) {
      if (facilityMapping.containsKey(type)) {
        facilities.add(facilityMapping[type]!);
      }
    }
    
    // Add common hospital facilities if none found
    if (facilities.isEmpty) {
      facilities.addAll([
        {'name': 'General Care', 'icon': 'local_hospital'},
        {'name': 'Consultation', 'icon': 'medical_services'},
        {'name': 'Emergency Services', 'icon': 'emergency'},
      ]);
    }
    
    return facilities;
  }

  // Calculate distance between two coordinates
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);
    
    final double a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
} 