import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital.dart';
import '../services/hospital_service.dart';
import '../services/location_service.dart';
import '../widgets/distance_badge.dart';
import 'facilities.dart';
import 'choose.dart';
import 'hospital_details.dart';
import 'dart:io';
import 'dart:convert';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  UserLocation? _userLocation;
  bool _isLocationLoading = false;
  bool _showLocationPermissionDialog = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Vérifier si la localisation est disponible
      bool locationAvailable = await LocationService.isLocationAvailable();
      
      if (!locationAvailable) {
        // Essayer d'obtenir la localisation depuis le cache
        _userLocation = await LocationService.getCachedLocation();
        
        if (_userLocation == null) {
          // Demander les permissions
          bool permissionGranted = await LocationService.requestLocationPermission();
          if (!permissionGranted) {
            setState(() {
              _showLocationPermissionDialog = true;
            });
          }
        }
      } else {
        // Obtenir la localisation actuelle
        _userLocation = await LocationService.getCurrentLocation();
      }
    } catch (e) {
      print('Error initializing location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    bool permissionGranted = await LocationService.requestLocationPermission();
    if (permissionGranted) {
      await _initializeLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ChoosePage()),
            );
          },
        ),
        title: const Text(
          'Find Hospitals',
          style: TextStyle(
                        color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
                      ),
        backgroundColor: const Color(0xFF159BBD),
        elevation: 0,
        actions: [
          // Bouton de localisation
          IconButton(
            icon: _isLocationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location, color: Colors.white),
            onPressed: _isLocationLoading ? null : _initializeLocation,
            tooltip: 'Update location',
                    ),
                  ],
                ),
      body: Column(
        children: [
          // Header avec informations de localisation
          _buildLocationHeader(),

            // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
              child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                  controller: _searchController,
                        decoration: InputDecoration(
                    hintText: 'Search for hospitals...',
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: Color(0xFF159BBD)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.filter_list, color: Color(0xFF159BBD)),
                            onPressed: () {},
                          ),
                        ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
            ),

            // Hospitals List
            Expanded(
              child: StreamBuilder<List<Hospital>>(
                stream: searchQuery.isEmpty 
                    ? HospitalService.getHospitals()
                    : HospitalService.searchHospitals(searchQuery),
                builder: (context, snapshot) {
                  print('StreamBuilder state: ${snapshot.connectionState}');
                  print('StreamBuilder hasError: ${snapshot.hasError}');
                  print('StreamBuilder error: ${snapshot.error}');
                  print('StreamBuilder hasData: ${snapshot.hasData}');
                  print('StreamBuilder data length: ${snapshot.data?.length}');
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    print('StreamBuilder error details: ${snapshot.error}');
                    // Try to fetch data once as a fallback
                    return FutureBuilder<List<Hospital>>(
                      future: _fetchHospitalsOnce(),
                      builder: (context, futureSnapshot) {
                        if (futureSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                            ),
                          );
                        }
                        
                        if (futureSnapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                          Text(
                                  'Error loading hospitals',
                            style: TextStyle(
                              fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please check your connection and try again',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      // Force rebuild
                                    });
                                  },
                                  child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                          );
                        }
                        
                        final hospitals = futureSnapshot.data ?? [];
                        return _buildHospitalsList(hospitals);
                      },
                    );
                  }

                  final hospitals = snapshot.data ?? [];
                  print('Final hospitals list length: ${hospitals.length}');
                  return _buildHospitalsList(hospitals);
                },
                                              ),
                                            ),
                                          ],
                                        ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF159BBD),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Location',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLocationLoading) ...[
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Detecting your location...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ] else if (_userLocation != null) ...[
            Text(
              _userLocation!.address,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (_userLocation!.sector.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Sector: ${_userLocation!.sector}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location not available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _requestLocationPermission,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Enable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    // Debug log to see what data we're getting
    print('Building hospital card for: ${hospital.name}');
    print('Profile image URL: ${hospital.profileImageUrl}');
    print('Has profile image: ${hospital.profileImageUrl != null && hospital.profileImageUrl!.isNotEmpty}');
    
    return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: hospital.name,
                                                    hospitalImage: hospital.profileImageUrl ?? 'assets/hospital.PNG',
                                                    address: hospital.location ?? 'Address not available',
                                                    facilities: hospital.facilities.isNotEmpty 
                                                        ? hospital.facilities 
                                                        : ['General Care', 'Consultation'],
                                                    rating: 4.5,
                                                    reviewCount: 50,
                                                    aboutText: hospital.about ?? 'This healthcare facility is committed to providing exceptional medical care and services.',
                                                    hospitalSchedule: hospital.availableSchedule,
                                                    reviews: [
                                                      {
                                                        'name': 'John Doe',
                  'rating': '5',
                  'comment': 'Excellent service and professional staff.',
                  'date': '2024-01-15',
                                                      },
                                                      {
                                                        'name': 'Jane Smith',
                  'rating': '4',
                  'comment': 'Good experience, clean facility.',
                  'date': '2024-01-10',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
          borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
            // Hospital Image
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.grey[100],
              ),
              child: _buildHospitalImage(hospital),
            ),

            // Hospital Info
            Padding(
              padding: const EdgeInsets.all(12),
                                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                  Text(
                    hospital.name,
                    style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                  
                  // Location and distance row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                    hospital.location ?? 'Location not available',
                                          style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                                        ),
                      ),
                      const SizedBox(width: 8),
                      // Distance badge
                      DistanceBadge(
                        hospitalLatitude: hospital.latitude,
                        hospitalLongitude: hospital.longitude,
                        fallbackText: 'Distance unavailable',
                        showIcon: true,
                        fontSize: 10,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                                        Row(
                                          children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '4.5',
                                              style: TextStyle(
                                                fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                                              ),
                                            ),
                      const SizedBox(width: 4),
                      Text(
                        '(50 reviews)',
                                          style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                                              ),
                                            ),
                      const Spacer(),
                      if (hospital.isVerified)
                                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                    ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 12,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Verified',
                                              style: TextStyle(
                        fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                  color: Colors.green[600],
                                            ),
                                          ),
                            ],
                                        ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  // Facilities
                  if (hospital.facilities.isNotEmpty) ...[
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: hospital.facilities.take(3).map((facility) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF159BBD).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            facility,
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF159BBD),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
    );
  }

  Widget _buildHospitalImage(Hospital hospital) {
    // Check if we have a valid profile image URL or local file path
    if (hospital.profileImageUrl != null && hospital.profileImageUrl!.isNotEmpty) {
      
      print('Loading image for ${hospital.name}: ${hospital.profileImageUrl!.substring(0, 50)}...');
      
      // Check if it's a base64 image (starts with data:image)
      if (hospital.profileImageUrl!.startsWith('data:image')) {
        // Base64 image from Firestore
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.memory(
            base64Decode(hospital.profileImageUrl!.split(',')[1]),
                                        fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading base64 image for ${hospital.name}: $error');
              return _buildPlaceholderImage();
            },
          ),
        );
      }
      // Check if it's a network URL
      else if (hospital.profileImageUrl!.startsWith('http')) {
        // Network image
        return ClipRRect(
                                      borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.network(
            hospital.profileImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading network image for ${hospital.name}: $error');
              return _buildPlaceholderImage();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                print('Network image loaded successfully for ${hospital.name}');
                return child;
              }
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                        loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                                                ),
                                              );
                                            },
          ),
        );
      } else {
        // Local file path
        return ClipRRect(
                                      borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.file(
            File(hospital.profileImageUrl!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading local image for ${hospital.name}: $error');
              return _buildPlaceholderImage();
            },
          ),
        );
      }
    } else {
      print('No valid image URL for ${hospital.name}, showing placeholder');
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF159BBD).withOpacity(0.1),
            const Color(0xFF0D5C73).withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                        Container(
              padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                color: const Color(0xFF159BBD).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital,
                size: 32,
                color: Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Healthcare',
                                              style: TextStyle(
                                                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF159BBD).withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
    );
  }

  Future<List<Hospital>> _fetchHospitalsOnce() async {
    try {
      print('Attempting to fetch hospitals once as fallback...');
      final snapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .orderBy('createdAt', descending: true)
          .get();
      
      print('Fallback fetch: Got ${snapshot.docs.length} hospitals');
      final hospitals = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Fallback processing hospital: ${data['name']}');
        return Hospital.fromFirestore(data, doc.id);
      }).toList();
      
      print('Fallback: Successfully processed ${hospitals.length} hospitals');
      return hospitals;
    } catch (e) {
      print('Fallback fetch error: $e');
      throw e;
    }
  }

  Widget _buildHospitalsList(List<Hospital> hospitals) {
    if (hospitals.isEmpty) {
      return Center(
                              child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                                children: [
            Icon(
              searchQuery.isEmpty ? Icons.local_hospital_outlined : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty 
                  ? 'No hospitals available'
                  : 'No hospitals found for "$searchQuery"',
                                          style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty 
                  ? 'Hospitals will appear here once they register'
                  : 'Try a different search term',
                                          style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: hospitals.length,
      itemBuilder: (context, index) {
        return _buildHospitalCard(hospitals[index]);
                                            },
    );
  }
} 