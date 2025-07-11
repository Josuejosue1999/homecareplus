import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import '../models/hospital.dart';
import '../services/hospital_service.dart';
import '../services/enhanced_hospital_service.dart';
import '../services/location_service.dart';
import '../widgets/distance_badge.dart';
import 'facilities.dart';
import 'choose.dart';
import 'hospital_details.dart';
import 'find_healthcare_page.dart';
import '../main.dart';
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
    print('🚀 === PATIENT DASHBOARD INIT STATE ===');
    print('🚀 Initializing patient dashboard at ${DateTime.now()}');
    _initializeLocation();
    // Forcer la réinitialisation du service hospital pour garantir le bon fonctionnement
    _initializeHospitalService();
    print('🚀 === PATIENT DASHBOARD INIT COMPLETE ===');
  }
  
  /// Force la réinitialisation du service hospital
  void _initializeHospitalService() {
    print('🏥 === INITIALIZING HOSPITAL SERVICE ===');
    print('🏥 Reinitializing hospital service for patient dashboard at ${DateTime.now()}');
    
    // Forcer la réinitialisation du service
    try {
      EnhancedHospitalService.forceReinitialization();
      print('🏥 ✅ Hospital service force reinitialization completed');
    } catch (e) {
      print('🏥 ❌ Error during hospital service reinitialization: $e');
    }
    
    // Vérifier l'état du service
    print('🏥 Service state verification...');
    print('🏥 === HOSPITAL SERVICE INIT COMPLETE ===');
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Ne pas disposer le service car cela cause des problèmes lors de la navigation
    // EnhancedHospitalService.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      // Use the enhanced location service with Google Maps API
      final userLocation = await LocationService.getCurrentLocation();
        
      if (userLocation != null) {
            setState(() {
          _userLocation = userLocation;
          _isLocationLoading = false;
            });
      } else {
        setState(() {
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing location: $e');
        setState(() {
          _isLocationLoading = false;
        });
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
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        slivers: [
          // Ultra-Professional App Bar with Premium Design
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF159BBD),
                      const Color(0xFF0E86A8),
                      const Color(0xFF0A6B82),
                      const Color(0xFF064F5C),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF159BBD).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Static Professional Background Elements
                    Positioned(
                      right: 40,
                      top: 50,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.04),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    
                    Positioned(
                      left: 30,
                      bottom: 30,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.06),
                              Colors.white.withOpacity(0.03),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    
                    // Main Content - Refined Layout
                    Positioned(
                      top: 40, // Moved higher up
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header row with back arrow, logo and title
                            Row(
                              children: [
                                // Back Arrow
                                GestureDetector(
                                  onTap: () {
            Navigator.pushReplacement(
              context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const ProfessionalWelcomeScreen(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(-1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeInOutCubic,
                                            )),
                                            child: child,
                                          );
                                        },
                                        transitionDuration: const Duration(milliseconds: 600),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                
                                // Title - Centered between back arrow and symbol
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Find Healthcare',
          style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Symbol on the right
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.local_hospital,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Discover container (moved below title)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_hospital_rounded,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Discover healthcare providers in your area',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Location text (plain text, not in container) - Reduced size
                            if (_isLocationLoading) ...[
                              Row(
                                children: [
                                  SizedBox(
                                    width: 14, // Reduced from 16 to 14
                                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                                    ),
                                  ),
                                  const SizedBox(width: 10), // Reduced spacing
                                  Text(
                                    'Detecting location...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 12, // Reduced from 14 to 12
                                      fontWeight: FontWeight.w500,
                                    ),
                    ),
                  ],
                ),
                            ] else if (_userLocation != null) ...[
                              Row(
        children: [
                                  SizedBox(
                                    width: 14, // Reduced from 16 to 14
                                    height: 14,
                                    child: Lottie.asset(
                                      'assets/location.json',
                                      width: 14,
                                      height: 14,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback to regular icon if Lottie fails
                                        return Icon(
                                          Icons.place,
                                          size: 14,
                                          color: const Color(0xFF159BBD),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6), // Reduced spacing
                                  Expanded(
                                    child: Text(
                                      _userLocation!.address,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 12, // Reduced from 14 to 12
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                          ),
                        ],
                      ),
                              if (_userLocation!.sector.isNotEmpty) ...[
                                const SizedBox(height: 3), // Reduced spacing
                                Row(
                                  children: [
                                    const SizedBox(width: 20), // Align with icon above
                                    SizedBox(
                                      width: 12, // Reduced from 14 to 12
                                      height: 12,
                                      child: Lottie.asset(
                                        'assets/location.json',
                                        width: 12,
                                        height: 12,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Fallback to regular icon if Lottie fails
                                          return Icon(
                                            Icons.location_city,
                                            size: 12,
                                            color: Colors.grey[600],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 4), // Reduced spacing
                                    Text(
                                      _userLocation!.sector,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 10, // Reduced from 12 to 10
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ] else ...[
                              Row(
                                children: [
                                  SizedBox(
                                    width: 14, // Reduced from 16 to 14
                                    height: 14,
                                    child: Lottie.asset(
                                      'assets/location.json',
                                      width: 14,
                                      height: 14,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback to regular icon if Lottie fails
                                        return Icon(
                                          Icons.location_disabled,
                                          size: 14,
                                          color: Colors.grey[600],
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 6), // Reduced spacing
                                  Text(
                                    'Location unavailable',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12, // Reduced from 14 to 12
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Search Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: _buildSearchSection(),
              ),
            ),

            // Hospitals List
          SliverToBoxAdapter(
              child: StreamBuilder<List<Hospital>>(
                stream: searchQuery.isEmpty 
                    ? EnhancedHospitalService.getNearbyHospitals()
                    : EnhancedHospitalService.getNearbyHospitals().map((hospitals) {
                        return hospitals.where((hospital) {
                          return hospital.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                                 hospital.location!.toLowerCase().contains(searchQuery.toLowerCase()) ||
                                 hospital.facilities.any((facility) => 
                                     facility.toLowerCase().contains(searchQuery.toLowerCase()));
                        }).toList();
                      }),
                builder: (context, snapshot) {
                  print('🔄 === STREAMBUILDER DEBUG INFO ===');
                  print('🔄 StreamBuilder state: ${snapshot.connectionState}');
                  print('❌ StreamBuilder hasError: ${snapshot.hasError}');
                  print('📝 StreamBuilder error: ${snapshot.error}');
                  print('✅ StreamBuilder hasData: ${snapshot.hasData}');
                  print('📊 StreamBuilder data length: ${snapshot.data?.length}');
                  print('🔍 Search query: "$searchQuery"');
                  print('⏰ Timestamp: ${DateTime.now()}');
                  print('🔄 === STREAMBUILDER DEBUG END ===');
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    print('⏳ StreamBuilder is waiting for data...');
                    return _buildLoadingState();
                  }

                  if (snapshot.hasError) {
                    print('❌ StreamBuilder error details: ${snapshot.error}');
                    print('❌ Error type: ${snapshot.error.runtimeType}');
                    print('❌ Falling back to direct Firebase fetch...');
                    // Try to fetch data once as a fallback
                    return FutureBuilder<List<Hospital>>(
                      future: _fetchHospitalsOnce(),
                      builder: (context, futureSnapshot) {
                        if (futureSnapshot.connectionState == ConnectionState.waiting) {
                          print('⏳ FutureBuilder fallback is waiting...');
                          return _buildLoadingState();
                        }
                        
                        if (futureSnapshot.hasError) {
                          print('❌ FutureBuilder fallback also failed: ${futureSnapshot.error}');
                          return _buildErrorState();
                        }
                        
                        final hospitals = futureSnapshot.data ?? [];
                        print('📦 FutureBuilder fallback success: ${hospitals.length} hospitals');
                        return _buildHospitalsList(hospitals);
                      },
                    );
                  }

                  final hospitals = snapshot.data ?? [];
                  print('🎉 === FINAL HOSPITALS DATA ===');
                  print('🎉 Final hospitals list length: ${hospitals.length}');
                  print('🌍 Google Places hospitals: ${hospitals.where((h) => h.isFromGooglePlaces).length}');
                  print('🏥 Firebase hospitals: ${hospitals.where((h) => !h.isFromGooglePlaces).length}');
                  if (hospitals.isNotEmpty) {
                    print('🏥 First hospital: ${hospitals.first.name}');
                    print('🏥 First hospital location: ${hospitals.first.location}');
                  }
                  print('🎉 === FINAL HOSPITALS END ===');
                  return _buildHospitalsList(hospitals);
                },
                                              ),
                                            ),
                                          ],
                                        ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF159BBD).withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF159BBD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF159BBD),
                size: 20,
              ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Search Healthcare',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search hospitals, clinics, or specialties...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : Container(
                        padding: const EdgeInsets.all(8),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          onPressed: () {
                            // Filter functionality can be added here
                          },
                        ),
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
                  ),
                ),
          
          const SizedBox(height: 20),
          
          // Find Nearby Healthcare Button with Google Maps
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF159BBD), Color(0xFF0D7A94)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF159BBD).withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FindHealthcarePage(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.map_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Find Healthcare Maps', // Shortened text to avoid overflow
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF159BBD).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Finding Healthcare Centers',
            style: TextStyle(
              fontSize: 18,
                fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
              ),
            ),
          const SizedBox(height: 8),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.place_rounded,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
              Text(
                    'Nearby hospitals from Google Places',
                style: TextStyle(
                      fontSize: 12,
              color: Colors.grey[600],
            ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
              children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
                Text(
            'Please check your internet connection and try again',
                  style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Force rebuild
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF159BBD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                    ),
                  ),
            child: const Text(
              'Retry',
                    style: TextStyle(
                fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    // Debug log to see what data we're getting
    print('Building hospital card for: ${hospital.name}');
    print('Profile image URL: ${hospital.profileImageUrl}');
    print('Has profile image: ${hospital.profileImageUrl != null && hospital.profileImageUrl!.isNotEmpty}');
    
    // Check if this hospital should show "Under Review" badge
    // Only show badge if: hospital is from Google Places, has a placeId, 
    // exists in Firebase, but is not verified
    bool shouldShowUnderReviewBadge = hospital.isFromGooglePlaces && 
                                     hospital.placeId != null && 
                                     hospital.placeId!.isNotEmpty && 
                                     hospital.existsInFirebase && 
                                     !hospital.verified;
    
    // Check if this hospital should show "Verified" badge
    // Only show badge if: hospital is from Google Places, has a placeId, 
    // exists in Firebase, AND is verified
    bool shouldShowVerifiedBadge = hospital.isFromGooglePlaces && 
                                  hospital.placeId != null && 
                                  hospital.placeId!.isNotEmpty && 
                                  hospital.existsInFirebase && 
                                  hospital.verified;
    
    // Check if this hospital should show "Unverified" badge
    // Only show badge if: hospital is from Google Places, has a placeId, 
    // but does NOT exist in Firebase yet
    bool shouldShowUnverifiedBadge = hospital.isFromGooglePlaces && 
                                    hospital.placeId != null && 
                                    hospital.placeId!.isNotEmpty && 
                                    !hospital.existsInFirebase;
    
    print('Hospital ${hospital.name} - Should show Under Review: $shouldShowUnderReviewBadge');
    print('Hospital ${hospital.name} - Should show Verified: $shouldShowVerifiedBadge');
    print('Hospital ${hospital.name} - Should show Unverified: $shouldShowUnverifiedBadge');
    print('  - isFromGooglePlaces: ${hospital.isFromGooglePlaces}');
    print('  - placeId: ${hospital.placeId}');
    print('  - existsInFirebase: ${hospital.existsInFirebase}');
    print('  - verified: ${hospital.verified}');
    
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
                                                    rating: hospital.displayRating,
                                                    reviewCount: hospital.displayRatingCount,
                                                    reviews: [], // Will be fetched from Google Places if available
                                                    aboutText: hospital.about ?? 'This healthcare facility is committed to providing exceptional medical care and services.',
                                                    hospitalSchedule: hospital.availableSchedule,
                                                    supportsBooking: hospital.supportsBooking,
                                                                                                    isFromGooglePlaces: hospital.isFromGooglePlaces,
                                                placeId: hospital.placeId,
                                                isUnverified: shouldShowUnverifiedBadge,
                                              ),
                                                ),
                                              );
                                            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
          borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
              color: const Color(0xFF159BBD).withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
            // Hospital Image with Overlay
                                  Container(
              height: 160,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                color: Colors.grey[100],
              ),
              child: Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
              ),
              child: _buildHospitalImage(hospital),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),

                  // Distance Badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DistanceBadge(
                        hospitalLatitude: hospital.latitude,
                        hospitalLongitude: hospital.longitude,
                        fallbackText: 'Distance N/A',
                        useGoogleMaps: true,
                      ),
                    ),
                  ),

                  // Under Review Badge (if hospital is from Google Places but not verified in Firebase)
                  if (shouldShowUnderReviewBadge)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pending_outlined,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Under Review',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Verified Badge (if hospital is from Google Places and verified in Firebase)
                  if (shouldShowVerifiedBadge)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Unverified Badge (if hospital is from Google Places but not in Firebase)
                  if (shouldShowUnverifiedBadge)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Unverified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Hospital Info
            Padding(
              padding: const EdgeInsets.all(20),
                                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                  // Hospital Name and Rating
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hospital.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                              ],
                            ),
                            // Google Places indicator
                            if (hospital.isFromGooglePlaces) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.place_rounded,
                                    size: 12,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Google Places',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                                          children: [
                            const Icon(
                              Icons.star_rounded,
                        size: 16,
                              color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                            Text(
                              hospital.displayRating.toStringAsFixed(1),
                              style: const TextStyle(
                                                fontSize: 12,
                          fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                            children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Lottie.asset(
                          'assets/location.json',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to regular icon if Lottie fails
                            return Icon(
                              Icons.location_on,
                              size: 16,
                              color: const Color(0xFF159BBD),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hospital.location ?? 'Location not available',
                                              style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                                            ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                                        ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Facilities
                  if (hospital.facilities.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Afficher les 3 premières facilities
                        ...hospital.facilities.take(3).map((facility) {
                        return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF159BBD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF159BBD).withOpacity(0.2),
                                width: 1,
                              ),
                          ),
                          child: Text(
                            facility,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF159BBD),
                                fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                        // Ajouter "..." si il y a plus de 3 facilities
                        if (hospital.facilities.length > 3)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '...',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Action Button
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hospital.supportsBooking 
                            ? [const Color(0xFF159BBD), const Color(0xFF0D7A94)]
                            : shouldShowVerifiedBadge 
                                ? [const Color(0xFF159BBD), const Color(0xFF0D7A94)] // Bleu pour les hôpitaux vérifiés
                                : [Colors.grey[600]!, Colors.grey[700]!], // Gris pour les autres
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: hospital.supportsBooking 
                              ? const Color(0xFF159BBD).withOpacity(0.3)
                              : shouldShowVerifiedBadge 
                                  ? const Color(0xFF159BBD).withOpacity(0.3) // Ombre bleue pour les hôpitaux vérifiés
                                  : Colors.grey.withOpacity(0.2), // Ombre grise pour les autres
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
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
                                rating: hospital.displayRating,
                                reviewCount: hospital.displayRatingCount,
                                reviews: [],
                                aboutText: hospital.about ?? 'This healthcare facility is committed to providing exceptional medical care and services.',
                                hospitalSchedule: hospital.availableSchedule,
                                supportsBooking: hospital.supportsBooking || shouldShowVerifiedBadge, // Support booking si vérifié
                                isFromGooglePlaces: hospital.isFromGooglePlaces,
                                placeId: hospital.placeId,
                                isVerified: shouldShowVerifiedBadge, // Passer le statut de vérification
                                isUnverified: shouldShowUnverifiedBadge, // Passer le statut non vérifié
                              ),
                            ),
                          );
                        },
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hospital.supportsBooking) ...[
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Book Appointment',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  shouldShowVerifiedBadge 
                                      ? Icons.verified_rounded // Icône vérifiée pour les hôpitaux vérifiés
                                      : Icons.info_outline_rounded, // Icône d'info pour les autres
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
        return Image.memory(
            base64Decode(hospital.profileImageUrl!.split(',')[1]),
                                        fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading base64 image for ${hospital.name}: $error');
              return _buildPlaceholderImage();
            },
        );
      }
      // Check if it's a network URL
      else if (hospital.profileImageUrl!.startsWith('http')) {
        // Network image
        return Image.network(
            hospital.profileImageUrl!,
            fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
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
        );
      } else {
        // Local file path
        return Image.file(
            File(hospital.profileImageUrl!),
            fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading local image for ${hospital.name}: $error');
              return _buildPlaceholderImage();
            },
        );
      }
    } else {
      print('No valid image URL for ${hospital.name}, showing placeholder');
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
                                    decoration: BoxDecoration(
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
              padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                color: const Color(0xFF159BBD).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                size: 40,
                color: Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Healthcare Center',
                                              style: TextStyle(
                fontSize: 14,
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
      return Container(
        padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searchQuery.isEmpty ? Icons.local_hospital_outlined : Icons.search_off_rounded,
                size: 48,
              color: Colors.grey[400],
            ),
            ),
            const SizedBox(height: 24),
            Text(
              searchQuery.isEmpty 
                  ? 'No Healthcare Centers'
                  : 'No Results Found',
                                          style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty 
                  ? 'Healthcare centers will appear here once they register'
                  : 'Try adjusting your search terms',
                                          style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                                              ),
              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Text(
                  '${hospitals.length} Healthcare Centers',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                if (searchQuery.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF159BBD).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'for "$searchQuery"',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF159BBD),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Hospitals List
          ...hospitals.map((hospital) => _buildHospitalCard(hospital)).toList(),
          
          // Bottom Spacing
          const SizedBox(height: 40),
        ],
      ),
    );
  }
} 

