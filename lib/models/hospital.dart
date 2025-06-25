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
      about: data['about'] ?? 'This healthcare facility is committed to providing exceptional medical care and services. Our state-of-the-art facility is equipped with the latest medical technology and staffed by experienced healthcare professionals.',
      location: address ?? 'Location not available',
      facilities: List<String>.from(data['facilities'] ?? []),
      profileImageUrl: data['profileImageUrl'],
      certificateUrl: data['certificateUrl'],
      isVerified: data['certificateUrl'] != null && data['certificateUrl'].isNotEmpty,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      availableSchedule: _parseSchedule(data['availableSchedule']),
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
} 