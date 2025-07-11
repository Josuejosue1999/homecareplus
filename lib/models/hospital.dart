class Hospital {
  final String id;
  final String name;
  final String email;
  final String? about;
  final String? location;
  final List<String> facilities;
  final String? profileImageUrl;
  final String? certificateUrl;
  final bool isVerified;
  final DateTime createdAt;
  final Map<String, Map<String, String>> availableSchedule;
  final double? latitude;
  final double? longitude;
  
  // New fields for Google Places integration
  final bool verified; // For Firebase hospitals that support booking
  final bool isFromGooglePlaces; // Flag to identify Google Places hospitals
  final double? rating; // Google Places rating
  final int? userRatingsTotal; // Number of ratings
  final int? priceLevel; // Price level from Google Places
  final Map<String, Map<String, String>>? openingHours; // Google Places opening hours
  final String? placeId; // Google Places ID
  final bool existsInFirebase; // Flag to identify if this Google Places hospital exists in Firebase
  
  // Distance field for sorting (calculated dynamically)
  double? distance;

  Hospital({
    required this.id,
    required this.name,
    required this.email,
    this.about,
    this.location,
    required this.facilities,
    this.profileImageUrl,
    this.certificateUrl,
    required this.isVerified,
    required this.createdAt,
    required this.availableSchedule,
    this.latitude,
    this.longitude,
    this.verified = false,
    this.isFromGooglePlaces = false,
    this.rating,
    this.userRatingsTotal,
    this.priceLevel,
    this.openingHours,
    this.placeId,
    this.existsInFirebase = false,
    this.distance,
  });

  factory Hospital.fromFirestore(Map<String, dynamic> data, String id) {
    // Récupérer l'adresse depuis 'address' en priorité, puis 'location' comme fallback
    String? address = data['address'];
    if (address == null || address.isEmpty) {
      address = data['location'];
    }
    
    return Hospital(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      about: data['about'],
      location: address,
      facilities: List<String>.from(data['facilities'] ?? []),
      profileImageUrl: data['profileImageUrl'],
      certificateUrl: data['certificateUrl'],
      isVerified: data['certificateUrl'] != null && data['certificateUrl'].isNotEmpty,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      availableSchedule: _parseSchedule(data['availableSchedule']),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      verified: data['verified'] ?? true, // Firebase hospitals are verified by default
      isFromGooglePlaces: false, // Firebase hospitals are not from Google Places
      rating: data['rating']?.toDouble(),
      userRatingsTotal: data['userRatingsTotal'],
      priceLevel: data['priceLevel'],
      openingHours: data['openingHours'] != null ? _parseSchedule(data['openingHours']) : null,
      placeId: data['placeId'],
      existsInFirebase: true, // Firebase hospitals exist in Firebase by definition
      distance: data['distance']?.toDouble(),
    );
  }

  static Map<String, Map<String, String>> _parseSchedule(dynamic scheduleData) {
    if (scheduleData == null) return {};
    
    Map<String, Map<String, String>> schedule = {};
    if (scheduleData is Map) {
      scheduleData.forEach((key, value) {
        if (value is Map) {
          schedule[key.toString()] = Map<String, String>.from(value);
        }
      });
    }
    return schedule;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'about': about,
      'address': location,
      'location': location,
      'facilities': facilities,
      'profileImageUrl': profileImageUrl,
      'certificateUrl': certificateUrl,
      'createdAt': createdAt,
      'availableSchedule': availableSchedule,
      'latitude': latitude,
      'longitude': longitude,
      'verified': verified,
      'isFromGooglePlaces': isFromGooglePlaces,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'priceLevel': priceLevel,
      'openingHours': openingHours,
      'placeId': placeId,
      'existsInFirebase': existsInFirebase,
      'distance': distance,
    };
  }

  // Méthode pour vérifier si l'hôpital a une image
  bool get hasProfileImage {
    return profileImageUrl != null && profileImageUrl!.isNotEmpty;
  }

  // Méthode pour vérifier si l'image est en base64
  bool get hasBase64Image {
    return hasProfileImage && profileImageUrl!.startsWith('data:image');
  }

  // Méthode pour vérifier si l'image est une URL réseau
  bool get hasNetworkImage {
    return hasProfileImage && profileImageUrl!.startsWith('http');
  }

  // Méthode pour vérifier si l'image est un fichier local
  bool get hasLocalImage {
    return hasProfileImage && !profileImageUrl!.startsWith('data:image') && !profileImageUrl!.startsWith('http');
  }

  // Méthode pour vérifier si l'hôpital a des coordonnées géographiques
  bool get hasCoordinates {
    return latitude != null && longitude != null;
  }

  // Check if hospital supports booking and chat (Firebase verified hospitals)
  bool get supportsBooking {
    return verified && !isFromGooglePlaces;
  }

  // Get the display rating (Google Places rating or default)
  double get displayRating {
    return rating ?? 4.5;
  }

  // Get the display rating count
  int get displayRatingCount {
    return userRatingsTotal ?? 50;
  }
} 