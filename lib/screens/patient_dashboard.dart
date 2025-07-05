import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
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

class _PatientDashboardPageState extends State<PatientDashboardPage> with TickerProviderStateMixin {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  UserLocation? _userLocation;
  bool _isLocationLoading = false;
  bool _showLocationPermissionDialog = false;

  // Animation controllers for moving bubbles
  late AnimationController _bubble1Controller;
  late AnimationController _bubble2Controller;
  late AnimationController _bubble3Controller;
  late AnimationController _bubble4Controller;
  
  // Animations for bubble positions
  late Animation<Offset> _bubble1Animation;
  late Animation<Offset> _bubble2Animation;
  late Animation<Offset> _bubble3Animation;
  late Animation<Offset> _bubble4Animation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bubble1Controller.dispose();
    _bubble2Controller.dispose();
    _bubble3Controller.dispose();
    _bubble4Controller.dispose();
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

  void _initializeAnimations() {
    // Initialize bubble animation controllers with different durations for variety
    _bubble1Controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _bubble2Controller = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    
    _bubble3Controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _bubble4Controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    // Create different movement patterns for each bubble
    _bubble1Animation = Tween<Offset>(
      begin: const Offset(-0.2, 0.3),
      end: const Offset(1.2, 0.1),
    ).animate(CurvedAnimation(
      parent: _bubble1Controller,
      curve: Curves.easeInOut,
    ));
    
    _bubble2Animation = Tween<Offset>(
      begin: const Offset(1.1, 0.8),
      end: const Offset(-0.1, 0.2),
    ).animate(CurvedAnimation(
      parent: _bubble2Controller,
      curve: Curves.easeInOut,
    ));
    
    _bubble3Animation = Tween<Offset>(
      begin: const Offset(0.2, -0.1),
      end: const Offset(0.8, 0.9),
    ).animate(CurvedAnimation(
      parent: _bubble3Controller,
      curve: Curves.easeInOut,
    ));
    
    _bubble4Animation = Tween<Offset>(
      begin: const Offset(0.9, 0.1),
      end: const Offset(0.1, 0.7),
    ).animate(CurvedAnimation(
      parent: _bubble4Controller,
      curve: Curves.easeInOut,
    ));

    // Start animations and repeat them
    _bubble1Controller.repeat(reverse: true);
    _bubble2Controller.repeat(reverse: true);
    _bubble3Controller.repeat(reverse: true);
    _bubble4Controller.repeat(reverse: true);
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
                    // Animated Moving Bubbles for Dynamic Feel
                    AnimatedBuilder(
                      animation: _bubble1Controller,
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * _bubble1Animation.value.dx,
                          top: 240 * _bubble1Animation.value.dy,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.03),
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 20,
                                  offset: const Offset(-5, -5),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 0,
                                  blurRadius: 15,
                                  offset: const Offset(5, 5),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    AnimatedBuilder(
                      animation: _bubble2Controller,
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * _bubble2Animation.value.dx,
                          top: 240 * _bubble2Animation.value.dy,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.12),
                                  Colors.white.withOpacity(0.06),
                                  Colors.white.withOpacity(0.02),
                                ],
                                stops: const [0.0, 0.7, 1.0],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 18,
                                  offset: const Offset(-3, -3),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  spreadRadius: 0,
                                  blurRadius: 12,
                                  offset: const Offset(3, 3),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    AnimatedBuilder(
                      animation: _bubble3Controller,
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * _bubble3Animation.value.dx,
                          top: 240 * _bubble3Animation.value.dy,
                          child: Container(
                            width: 60,
                            height: 60,
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.05),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: const Offset(-2, -2),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    AnimatedBuilder(
                      animation: _bubble4Controller,
                      builder: (context, child) {
                        return Positioned(
                          left: MediaQuery.of(context).size.width * _bubble4Animation.value.dx,
                          top: 240 * _bubble4Animation.value.dy,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.05),
                                  Colors.transparent,
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      },
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
                            // Title and Icon Section (moved higher)
                            Row(
                              children: [
                                // Medical Icon
                                Container(
                                  width: 56, // Increased to match larger title
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.25),
                                        Colors.white.withOpacity(0.15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 0,
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.1),
                                        spreadRadius: 0,
                                        blurRadius: 6,
                                        offset: const Offset(0, -2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_hospital_rounded,
                                    color: Colors.white,
                                    size: 28, // Increased to match larger title
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Title (increased size)
                                const Text(
                                  'Find Healthcare',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28, // Increased from 24 to 28
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    height: 1.1,
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
                                    Icons.verified_rounded,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Discover trusted healthcare providers in your area',
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
                  ? HospitalService.getHospitals()
                  : HospitalService.searchHospitals(searchQuery),
              builder: (context, snapshot) {
                print('StreamBuilder state: ${snapshot.connectionState}');
                print('StreamBuilder hasError: ${snapshot.hasError}');
                print('StreamBuilder error: ${snapshot.error}');
                print('StreamBuilder hasData: ${snapshot.hasData}');
                print('StreamBuilder data length: ${snapshot.data?.length}');
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingState();
                }

                if (snapshot.hasError) {
                  print('StreamBuilder error details: ${snapshot.error}');
                  // Try to fetch data once as a fallback
                  return FutureBuilder<List<Hospital>>(
                    future: _fetchHospitalsOnce(),
                    builder: (context, futureSnapshot) {
                      if (futureSnapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState();
                      }
                      
                      if (futureSnapshot.hasError) {
                        return _buildErrorState();
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
          Text(
            'Please wait while we load available hospitals...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
                  // Verification Badge
                  if (hospital.isVerified)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
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
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            const Text(
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
                        showIcon: true,
                        fontSize: 11,
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
                            const Text(
                              '4.5',
                              style: TextStyle(
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
                      children: hospital.facilities.take(3).map((facility) {
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
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Action Button
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF159BBD), Color(0xFF0D7A94)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF159BBD).withOpacity(0.3),
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
                        child: const Center(
                          child: Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
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