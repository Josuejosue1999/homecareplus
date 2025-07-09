import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class GoogleMapsService {
  static const String _apiKey = 'AIzaSyA1g-UDJcfQS_33U3Sysxe9g4zlAOnpS3g';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // Rechercher des centres de santé proches
  static Future<List<HealthcarePlace>> findNearbyHealthcare({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String type = 'hospital',
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/nearbysearch/json?location=$latitude,$longitude&radius=$radius&type=$type&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<HealthcarePlace> places = [];
          
          for (var place in data['results']) {
            places.add(HealthcarePlace.fromJson(place));
          }
          
          return places;
        } else {
          throw Exception('Google Places API error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to load places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error finding healthcare places: $e');
    }
  }

  // Obtenir la position actuelle de l'utilisateur
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si les services de localisation sont activés
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés.');
    }

    // Vérifier les permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Les permissions de localisation sont refusées.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Les permissions de localisation sont définitivement refusées.');
    }

    // Obtenir la position actuelle
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Calculer la distance entre deux points
  static double calculateDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  // Rechercher des centres de santé par nom
  static Future<List<HealthcarePlace>> searchHealthcareByName({
    required String query,
    required double latitude,
    required double longitude,
    int radius = 10000,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/textsearch/json?query=$query&location=$latitude,$longitude&radius=$radius&type=hospital&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final List<HealthcarePlace> places = [];
          
          for (var place in data['results']) {
            places.add(HealthcarePlace.fromJson(place));
          }
          
          return places;
        } else {
          throw Exception('Google Places API error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching healthcare places: $e');
    }
  }

  // Obtenir les détails d'un lieu
  static Future<HealthcarePlaceDetails> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/details/json?place_id=$placeId&fields=name,rating,formatted_phone_number,formatted_address,website,opening_hours,photos&key=$_apiKey'
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          return HealthcarePlaceDetails.fromJson(data['result']);
        } else {
          throw Exception('Google Places API error: ${data['status']}');
        }
      } else {
        throw Exception('Failed to load place details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting place details: $e');
    }
  }
}

class HealthcarePlace {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double? rating;
  final String? photoReference;
  final List<String> types;
  final bool isOpen;
  final String? priceLevel;

  HealthcarePlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.photoReference,
    required this.types,
    required this.isOpen,
    this.priceLevel,
  });

  factory HealthcarePlace.fromJson(Map<String, dynamic> json) {
    return HealthcarePlace(
      id: json['place_id'] ?? '',
      name: json['name'] ?? '',
      address: json['vicinity'] ?? json['formatted_address'] ?? '',
      latitude: json['geometry']['location']['lat']?.toDouble() ?? 0.0,
      longitude: json['geometry']['location']['lng']?.toDouble() ?? 0.0,
      rating: json['rating']?.toDouble(),
      photoReference: json['photos'] != null && json['photos'].isNotEmpty
          ? json['photos'][0]['photo_reference']
          : null,
      types: List<String>.from(json['types'] ?? []),
      isOpen: json['opening_hours']?['open_now'] ?? false,
      priceLevel: json['price_level']?.toString(),
    );
  }

  // Obtenir l'URL de la photo
  String? getPhotoUrl({int maxWidth = 400}) {
    if (photoReference == null) return null;
    return 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=$maxWidth&photoreference=$photoReference&key=${GoogleMapsService._apiKey}';
  }
}

class HealthcarePlaceDetails {
  final String name;
  final double? rating;
  final String? phoneNumber;
  final String? address;
  final String? website;
  final Map<String, dynamic>? openingHours;
  final List<String>? photoReferences;

  HealthcarePlaceDetails({
    required this.name,
    this.rating,
    this.phoneNumber,
    this.address,
    this.website,
    this.openingHours,
    this.photoReferences,
  });

  factory HealthcarePlaceDetails.fromJson(Map<String, dynamic> json) {
    return HealthcarePlaceDetails(
      name: json['name'] ?? '',
      rating: json['rating']?.toDouble(),
      phoneNumber: json['formatted_phone_number'],
      address: json['formatted_address'],
      website: json['website'],
      openingHours: json['opening_hours'],
      photoReferences: json['photos'] != null
          ? List<String>.from(json['photos'].map((photo) => photo['photo_reference']))
          : null,
    );
  }
} 