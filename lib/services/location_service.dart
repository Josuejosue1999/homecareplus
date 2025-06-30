import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class LocationService {
  static const String _locationKey = 'user_location';
  static const String _lastUpdateKey = 'location_last_update';
  
  // Structure pour stocker les informations de localisation
  static Future<UserLocation?> getCurrentLocation() async {
    try {
      print('=== GETTING CURRENT LOCATION ===');
      
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠ Location permission denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('⚠ Location permission permanently denied');
        return null;
      }
      
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠ Location service is disabled');
        return null;
      }
      
      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      
      print('✓ Current position: ${position.latitude}, ${position.longitude}');
      
      // Obtenir les informations d'adresse
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        
        // Construire l'adresse complète
        String address = _buildAddress(placemark);
        String sector = _extractSector(placemark);
        String streetNumber = _extractStreetNumber(placemark);
        
        final userLocation = UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
          sector: sector,
          streetNumber: streetNumber,
          city: placemark.locality ?? '',
          country: placemark.country ?? '',
          timestamp: DateTime.now(),
        );
        
        // Sauvegarder en cache
        await _saveLocationToCache(userLocation);
        
        print('✓ Location obtained successfully');
        print('  Address: $address');
        print('  Sector: $sector');
        print('  Street Number: $streetNumber');
        
        return userLocation;
      }
      
      // Si pas d'adresse, retourner juste les coordonnées
      final userLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Location detected',
        sector: 'Unknown',
        streetNumber: '',
        city: '',
        country: '',
        timestamp: DateTime.now(),
      );
      
      await _saveLocationToCache(userLocation);
      return userLocation;
      
    } catch (e) {
      print('Error getting current location: $e');
      return await _getCachedLocation();
    }
  }
  
  // Forcer la détection de la localisation (après activation)
  static Future<UserLocation?> forceLocationDetection() async {
    try {
      print('=== FORCING LOCATION DETECTION ===');
      
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠ Location permission denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('⚠ Location permission permanently denied');
        return null;
      }
      
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠ Location service is disabled');
        return null;
      }
      
      // Attendre un peu pour que le GPS se stabilise
      await Future.delayed(const Duration(seconds: 2));
      
      // Obtenir la position actuelle avec une précision élevée
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      
      print('✓ Forced position detection: ${position.latitude}, ${position.longitude}');
      
      // Obtenir les informations d'adresse
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        
        // Construire l'adresse complète
        String address = _buildAddress(placemark);
        String sector = _extractSector(placemark);
        String streetNumber = _extractStreetNumber(placemark);
        
        final userLocation = UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
          sector: sector,
          streetNumber: streetNumber,
          city: placemark.locality ?? '',
          country: placemark.country ?? '',
          timestamp: DateTime.now(),
        );
        
        // Sauvegarder en cache
        await _saveLocationToCache(userLocation);
        
        print('✓ Forced location detection successful');
        print('  Address: $address');
        print('  Sector: $sector');
        print('  Street Number: $streetNumber');
        
        return userLocation;
      }
      
      // Si pas d'adresse, retourner juste les coordonnées
      final userLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Location detected',
        sector: 'Unknown',
        streetNumber: '',
        city: '',
        country: '',
        timestamp: DateTime.now(),
      );
      
      await _saveLocationToCache(userLocation);
      return userLocation;
      
    } catch (e) {
      print('Error in forced location detection: $e');
      return await _getCachedLocation();
    }
  }
  
  // Obtenir la localisation depuis le cache
  static Future<UserLocation?> getCachedLocation() async {
    return await _getCachedLocation();
  }
  
  // Calculer la distance entre deux points
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  
  // Formater la distance pour l'affichage
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
  
  // Calculer la distance depuis la localisation de l'utilisateur
  static Future<String> getDistanceFromUser(double hospitalLat, double hospitalLon) async {
    try {
      final userLocation = await getCurrentLocation();
      if (userLocation == null) {
        return 'Distance unavailable';
      }
      
      final distance = calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        hospitalLat,
        hospitalLon,
      );
      
      return formatDistance(distance);
    } catch (e) {
      print('Error calculating distance: $e');
      return 'Distance unavailable';
    }
  }
  
  // Construire l'adresse complète
  static String _buildAddress(Placemark placemark) {
    List<String> addressParts = [];
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      addressParts.add(placemark.subLocality!);
    }
    
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      addressParts.add(placemark.administrativeArea!);
    }
    
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      addressParts.add(placemark.country!);
    }
    
    return addressParts.join(', ');
  }
  
  // Extraire le secteur
  static String _extractSector(Placemark placemark) {
    // Priorité: subLocality > locality > administrativeArea
    if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
      return placemark.subLocality!;
    }
    
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      return placemark.locality!;
    }
    
    if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
      return placemark.administrativeArea!;
    }
    
    return 'Unknown Sector';
  }
  
  // Extraire le numéro de rue
  static String _extractStreetNumber(Placemark placemark) {
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      // Essayer d'extraire le numéro de la rue
      final streetParts = placemark.street!.split(' ');
      if (streetParts.isNotEmpty) {
        final firstPart = streetParts.first;
        if (RegExp(r'^\d+').hasMatch(firstPart)) {
          return firstPart;
        }
      }
    }
    
    return '';
  }
  
  // Sauvegarder la localisation en cache
  static Future<void> _saveLocationToCache(UserLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = jsonEncode(location.toJson());
      await prefs.setString(_locationKey, locationJson);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      print('✓ Location saved to cache');
    } catch (e) {
      print('Error saving location to cache: $e');
    }
  }
  
  // Récupérer la localisation depuis le cache
  static Future<UserLocation?> _getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationJson = prefs.getString(_locationKey);
      final lastUpdateStr = prefs.getString(_lastUpdateKey);
      
      if (locationJson != null && lastUpdateStr != null) {
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final now = DateTime.now();
        
        // Vérifier si le cache n'est pas trop ancien (24 heures)
        if (now.difference(lastUpdate).inHours < 24) {
          final locationData = jsonDecode(locationJson) as Map<String, dynamic>;
          final location = UserLocation.fromJson(locationData);
          print('✓ Location loaded from cache');
          return location;
        }
      }
      
      return null;
    } catch (e) {
      print('Error loading location from cache: $e');
      return null;
    }
  }
  
  // Vérifier si la localisation est disponible
  static Future<bool> isLocationAvailable() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      return (permission == LocationPermission.whileInUse || 
              permission == LocationPermission.always) && serviceEnabled;
    } catch (e) {
      print('Error checking location availability: $e');
      return false;
    }
  }
  
  // Demander les permissions de localisation
  static Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }
  
  // Vérifier et demander les permissions si nécessaire
  static Future<bool> checkAndRequestPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      print('Error checking and requesting permission: $e');
      return false;
    }
  }
}

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
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      sector: json['sector'] ?? '',
      streetNumber: json['streetNumber'] ?? '',
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  String toString() {
    return 'UserLocation(latitude: $latitude, longitude: $longitude, address: $address, sector: $sector)';
  }
} 