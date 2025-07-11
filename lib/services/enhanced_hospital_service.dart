import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital.dart';
import 'google_places_service.dart';
import 'location_service.dart';
import 'dart:async';

class EnhancedHospitalService {
  static const int _maxRadius = 50000; // 50km radius
  
  // Stream controllers for real-time updates
  static StreamController<List<Hospital>>? _hospitalStreamController;
  static StreamSubscription? _firebaseSubscription;
  static List<Hospital>? _cachedGooglePlacesHospitals;
  static UserLocation? _cachedUserLocation;
  
  /// Get all place IDs from Firebase hospitals
  static Future<Set<String>> _getFirebasePlaceIds() async {
    try {
      print('🔍 Fetching place IDs from Firebase...');
      
      final snapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('placeId', isNull: false)
          .get();
      
      final placeIds = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final placeId = data['placeId'] as String?;
        if (placeId != null && placeId.isNotEmpty) {
          placeIds.add(placeId);
        }
      }
      
      print('✅ Found ${placeIds.length} place IDs in Firebase');
      return placeIds;
    } catch (e) {
      print('❌ Error fetching Firebase place IDs: $e');
      return <String>{};
    }
  }
  
  /// Force reinitialization of the service (used when navigating from different screens)
  static void forceReinitialization() {
    print('🔄 === FORCE REINITIALIZATION STARTED ===');
    print('🔄 Force reinitializing EnhancedHospitalService...');
    
    // Cancel existing subscription
    if (_firebaseSubscription != null) {
      _firebaseSubscription!.cancel();
      _firebaseSubscription = null;
      print('🔄 Cancelled existing Firebase subscription');
    }
    
    // Close existing stream controller
    if (_hospitalStreamController != null && !_hospitalStreamController!.isClosed) {
      _hospitalStreamController!.close();
      _hospitalStreamController = null;
      print('🔄 Closed existing stream controller');
    }
    
    // Clear cached data
    _cachedGooglePlacesHospitals = null;
    _cachedUserLocation = null;
    print('🔄 Cleared cached data');
    
    print('🔄 === FORCE REINITIALIZATION COMPLETED ===');
  }
  
  /// Get nearby hospitals with real-time Firebase verification status updates
  static Stream<List<Hospital>> getNearbyHospitals() async* {
    try {
      print('🏥 === GET NEARBY HOSPITALS CALLED ===');
      print('🏥 Starting real-time hospital stream...');
      print('🏥 Current time: ${DateTime.now()}');
      print('🏥 Stream controller null: ${_hospitalStreamController == null}');
      print('🏥 Stream controller closed: ${_hospitalStreamController?.isClosed ?? true}');
      
      // Initialize stream controller if not already done or if disposed
      if (_hospitalStreamController == null || _hospitalStreamController!.isClosed) {
        print('🔄 Reinitializing hospital stream controller...');
        _hospitalStreamController = StreamController<List<Hospital>>.broadcast();
        await _setupRealTimeUpdates();
      } else {
        print('🔄 Using existing stream controller');
      }
      
      print('🏥 About to yield from stream controller');
      // Yield from the stream controller
      yield* _hospitalStreamController!.stream;
      
    } catch (e) {
      print('❌ Error in hospital stream: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: $e');
      yield [];
    }
  }
  
  /// Setup real-time updates combining Google Places and Firebase data
  static Future<void> _setupRealTimeUpdates() async {
    try {
      print('🔧 === SETUP REAL-TIME UPDATES STARTED ===');
      print('🔧 Setting up real-time updates...');
      
      // Get user's current location
      print('📍 Getting user location...');
      _cachedUserLocation = await LocationService.getCurrentLocation();
      if (_cachedUserLocation == null) {
        print('❌ Could not get user location');
        _hospitalStreamController?.add([]);
        return;
      }
      
      print('✓ User location: ${_cachedUserLocation!.latitude}, ${_cachedUserLocation!.longitude}');
      
      // Fetch hospitals from Google Places API (cache them)
      print('🏥 Fetching hospitals from Google Places...');
      _cachedGooglePlacesHospitals = await GooglePlacesService.getNearbyHospitals(
        latitude: _cachedUserLocation!.latitude,
        longitude: _cachedUserLocation!.longitude,
        radius: _maxRadius,
      );
      
      print('✓ Found ${_cachedGooglePlacesHospitals!.length} hospitals from Google Places');
      
      // Listen to Firebase changes for real-time verification status updates
      print('🔥 Setting up Firebase listener...');
      _firebaseSubscription = FirebaseFirestore.instance
          .collection('clinics')
          .where('placeId', isNull: false)
          .snapshots()
          .listen((snapshot) async {
        try {
          print('🔄 Firebase verification status updated, refreshing hospitals...');
          print('🔄 Firebase documents count: ${snapshot.docs.length}');
          
          // Process the updated Firebase data
          final firebaseHospitals = <String, Map<String, dynamic>>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final placeId = data['placeId'] as String?;
            if (placeId != null && placeId.isNotEmpty) {
              firebaseHospitals[placeId] = {
                'verified': data['verified'] ?? false,
                'isVerified': data['isVerified'] ?? false,
                'approved': data['approved'] ?? false,
                'profileImageUrl': data['profileImageUrl'],
                'certificateUrl': data['certificateUrl'],
                'about': data['about'],
                'facilities': data['facilities'],
                'id': doc.id,
              };
            }
          }
          
          print('🔄 Processing ${firebaseHospitals.length} Firebase hospitals...');
          
          // Update Google Places hospitals with Firebase verification status
          final updatedHospitals = await _processHospitalsWithRealtimeStatus(
            _cachedGooglePlacesHospitals!,
            _cachedUserLocation!,
            firebaseHospitals,
          );
          
          print('✓ Updated ${updatedHospitals.length} hospitals with real-time status');
          print('🔧 === ADDING HOSPITALS TO STREAM ===');
          _hospitalStreamController?.add(updatedHospitals);
          
        } catch (e) {
          print('❌ Error processing Firebase update: $e');
        }
      });
      
      print('🔧 === SETUP REAL-TIME UPDATES COMPLETED ===');
    } catch (e) {
      print('❌ Error setting up real-time updates: $e');
      print('❌ Error type: ${e.runtimeType}');
      _hospitalStreamController?.add([]);
    }
  }
  
  /// Process hospitals with real-time Firebase verification status
  static Future<List<Hospital>> _processHospitalsWithRealtimeStatus(
    List<Hospital> hospitals,
    UserLocation userLocation,
    Map<String, Map<String, dynamic>> firebaseHospitals,
  ) async {
    final List<Hospital> updatedHospitals = [];
    
    for (var hospital in hospitals) {
      if (hospital.latitude != null && hospital.longitude != null) {
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          hospital.latitude!,
          hospital.longitude!,
        );
        
        // Check Firebase verification status
        final firebaseData = hospital.placeId != null ? firebaseHospitals[hospital.placeId] : null;
        final isVerified = firebaseData?['verified'] == true || firebaseData?['isVerified'] == true || firebaseData?['approved'] == true;
        final existsInFirebase = firebaseData != null;
        
        // Log the verification status for debugging
        if (firebaseData != null) {
          print('🏥 Hospital ${hospital.name}:');
          print('  - Place ID: ${hospital.placeId}');
          print('  - Verified: ${firebaseData['verified']}');
          print('  - IsVerified: ${firebaseData['isVerified']}');
          print('  - Approved: ${firebaseData['approved']}');
          print('  - Final Status: ${isVerified ? "VERIFIED" : "PENDING"}');
        }
        
        // Create updated hospital with real-time status
        final updatedHospital = Hospital(
          id: firebaseData?['id'] ?? hospital.id,
          name: hospital.name,
          email: hospital.email,
          about: firebaseData?['about'] ?? hospital.about,
          location: hospital.location,
          facilities: firebaseData?['facilities'] != null 
              ? List<String>.from(firebaseData!['facilities'])
              : hospital.facilities,
          profileImageUrl: firebaseData?['profileImageUrl'] ?? hospital.profileImageUrl,
          certificateUrl: firebaseData?['certificateUrl'] ?? hospital.certificateUrl,
          isVerified: isVerified, // Real-time verification status
          createdAt: hospital.createdAt,
          availableSchedule: hospital.availableSchedule,
          latitude: hospital.latitude,
          longitude: hospital.longitude,
          verified: isVerified, // Real-time verification status
          isFromGooglePlaces: true,
          rating: hospital.rating,
          userRatingsTotal: hospital.userRatingsTotal,
          priceLevel: hospital.priceLevel,
          openingHours: hospital.openingHours,
          placeId: hospital.placeId,
          distance: distance,
          // Add a flag to indicate if this hospital exists in Firebase
          existsInFirebase: existsInFirebase,
        );
        
        updatedHospitals.add(updatedHospital);
      }
    }
    
    // Sort by distance (closest first)
    updatedHospitals.sort((a, b) {
      final distanceA = a.distance ?? double.infinity;
      final distanceB = b.distance ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });
    
    return updatedHospitals;
  }
  
  /// Process hospitals with pending status and calculate distances
  static Future<List<Hospital>> _processHospitalsWithPendingStatus(
    List<Hospital> hospitals, 
    UserLocation userLocation,
    Set<String> firebasePlaceIds
  ) async {
    // Process each hospital
    for (var hospital in hospitals) {
      if (hospital.latitude != null && hospital.longitude != null) {
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          hospital.latitude!,
          hospital.longitude!,
        );
        
        // Check if this hospital is pending (exists in Firebase)
        final isPending = hospital.placeId != null && firebasePlaceIds.contains(hospital.placeId);
        
        // Create a new hospital with distance and pending status
        final hospitalWithStatus = Hospital(
          id: hospital.id,
          name: hospital.name,
          email: hospital.email,
          about: hospital.about,
          location: hospital.location,
          facilities: hospital.facilities,
          profileImageUrl: hospital.profileImageUrl,
          certificateUrl: hospital.certificateUrl,
          isVerified: isPending, // Mark as verified if pending (exists in Firebase)
          createdAt: hospital.createdAt,
          availableSchedule: hospital.availableSchedule,
          latitude: hospital.latitude,
          longitude: hospital.longitude,
          verified: isPending, // Mark as verified if pending
          isFromGooglePlaces: true,
          rating: hospital.rating,
          userRatingsTotal: hospital.userRatingsTotal,
          priceLevel: hospital.priceLevel,
          openingHours: hospital.openingHours,
          placeId: hospital.placeId,
          distance: distance, // Set calculated distance
        );
        
        // Replace the hospital in the list
        final index = hospitals.indexOf(hospital);
        hospitals[index] = hospitalWithStatus;
      }
    }
    
    // Sort by distance (closest first)
    hospitals.sort((a, b) {
      final distanceA = a.distance ?? double.infinity;
      final distanceB = b.distance ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });
    
    return hospitals;
  }
  
  /// Get hospital details including reviews
  static Future<Map<String, dynamic>?> getHospitalDetails(String placeId) async {
    try {
      print('🏥 Fetching hospital details for placeId: $placeId');
      
      final details = await GooglePlacesService.getPlaceDetails(placeId);
      if (details == null) {
        print('❌ Could not fetch hospital details');
        return null;
      }
      
      print('✓ Hospital details fetched successfully');
      return details;
      
    } catch (e) {
      print('❌ Error fetching hospital details: $e');
      return null;
    }
  }
  
  /// Get reviews for a specific hospital
  static Future<List<Map<String, dynamic>>> getHospitalReviews(String placeId) async {
    try {
      print('⭐ Fetching reviews for placeId: $placeId');
      
      final reviews = await GooglePlacesService.getPlaceReviews(placeId);
      print('✓ Found ${reviews.length} reviews');
      
      return reviews;
      
    } catch (e) {
      print('❌ Error fetching reviews: $e');
      return [];
    }
  }
  
  /// Get enhanced facilities from Google Places
  static List<Map<String, String>> getEnhancedFacilities(Map<String, dynamic> placeDetails) {
    final List<Map<String, String>> facilities = [];
    
    // Extract facilities from Google Places data
    if (placeDetails['types'] != null) {
      final types = List<String>.from(placeDetails['types']);
      
      for (String type in types) {
        String facilityName = _getFacilityName(type);
        String iconName = _getFacilityIcon(type);
        
        if (facilityName.isNotEmpty) {
          facilities.add({
            'name': facilityName,
            'icon': iconName,
          });
        }
      }
    }
    
    // Add default healthcare facilities if none found
    if (facilities.isEmpty) {
      facilities.addAll([
        {'name': 'General Care', 'icon': 'medical_services'},
        {'name': 'Consultation', 'icon': 'person'},
        {'name': 'Emergency', 'icon': 'emergency'},
      ]);
    }
    
    return facilities;
  }
  
  /// Map Google Places types to readable facility names
  static String _getFacilityName(String type) {
    switch (type) {
      case 'hospital':
        return 'Hospital Services';
      case 'doctor':
        return 'General Practice';
      case 'pharmacy':
        return 'Pharmacy';
      case 'emergency':
        return 'Emergency Services';
      case 'dentist':
        return 'Dental Care';
      case 'veterinary_care':
        return 'Veterinary Care';
      case 'physiotherapist':
        return 'Physiotherapy';
      case 'health':
        return 'Health Services';
      default:
        return '';
    }
  }
  
  /// Map Google Places types to appropriate icons
  static String _getFacilityIcon(String type) {
    switch (type) {
      case 'hospital':
        return 'local_hospital';
      case 'doctor':
        return 'medical_services';
      case 'pharmacy':
        return 'local_pharmacy';
      case 'emergency':
        return 'emergency';
      case 'dentist':
        return 'medical_services';
      case 'veterinary_care':
        return 'pets';
      case 'physiotherapist':
        return 'healing';
      case 'health':
        return 'health_and_safety';
      default:
        return 'medical_services';
    }
  }
  
  /// Dispose resources
  static void dispose() {
    print('🧹 Disposing Enhanced Hospital Service resources...');
    _hospitalStreamController?.close();
    _hospitalStreamController = null;
    _firebaseSubscription?.cancel();
    _firebaseSubscription = null;
    _cachedGooglePlacesHospitals = null;
    _cachedUserLocation = null;
  }
} 