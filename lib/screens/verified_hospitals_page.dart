import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital.dart';
import '../services/enhanced_hospital_service.dart';
import '../services/location_service.dart';
import '../widgets/distance_badge.dart';
import '../widgets/professional_bottom_nav.dart';
import 'hospital_details.dart';
import 'main_dashboard.dart';
import 'appointments_page.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'dart:convert';

class VerifiedHospitalsPage extends StatefulWidget {
  const VerifiedHospitalsPage({super.key});

  @override
  State<VerifiedHospitalsPage> createState() => _VerifiedHospitalsPageState();
}

class _VerifiedHospitalsPageState extends State<VerifiedHospitalsPage> {
  UserLocation? _userLocation;
  bool _isLocationLoading = false;
  int _selectedIndex = 2; // Book tab is selected
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('🚀 === VERIFIED HOSPITALS PAGE INIT ===');
    _initializeLocation();
    _initializeHospitalService();
    print('🚀 === VERIFIED HOSPITALS PAGE INIT COMPLETE ===');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Force la réinitialisation du service hospital
  void _initializeHospitalService() {
    print('🏥 === INITIALIZING HOSPITAL SERVICE ===');
    print('🏥 Reinitializing hospital service for verified hospitals page at ${DateTime.now()}');
    
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

  void _initializeLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      final location = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLocation = location;
          _isLocationLoading = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainDashboard()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppointmentsPage()),
        );
        break;
      case 2:
        // Already on verified hospitals page
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Professional Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: const Color(0xFF159BBD),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF159BBD),
                      Color(0xFF0D7A94),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verified Healthcare Centers',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Premium medical facilities certified and trusted by our healthcare network for your peace of mind',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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

          // Verified Hospitals List
          SliverToBoxAdapter(
            child: StreamBuilder<List<Hospital>>(
              stream: EnhancedHospitalService.getNearbyHospitals(),
              builder: (context, snapshot) {
                print('🔄 === VERIFIED HOSPITALS STREAMBUILDER DEBUG ===');
                print('🔄 StreamBuilder state: ${snapshot.connectionState}');
                print('❌ StreamBuilder hasError: ${snapshot.hasError}');
                print('📝 StreamBuilder error: ${snapshot.error}');
                print('✅ StreamBuilder hasData: ${snapshot.hasData}');
                print('📊 StreamBuilder data length: ${snapshot.data?.length}');
                print('⏰ Timestamp: ${DateTime.now()}');
                print('🔄 === VERIFIED HOSPITALS STREAMBUILDER DEBUG END ===');
                
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
                      return _buildVerifiedHospitalsList(hospitals);
                    },
                  );
                }

                final hospitals = snapshot.data ?? [];
                print('🎉 === VERIFIED HOSPITALS FINAL DATA ===');
                print('🎉 Final hospitals list length: ${hospitals.length}');
                print('🌍 Google Places hospitals: ${hospitals.where((h) => h.isFromGooglePlaces).length}');
                print('🏥 Firebase hospitals: ${hospitals.where((h) => !h.isFromGooglePlaces).length}');
                print('✅ Verified hospitals: ${hospitals.where((h) => h.isVerified || h.verified).length}');
                print('❌ Non-verified hospitals: ${hospitals.where((h) => !(h.isVerified || h.verified)).length}');
                if (hospitals.isNotEmpty) {
                  print('🏥 First hospital: ${hospitals.first.name}');
                  print('🏥 First hospital location: ${hospitals.first.location}');
                  print('🏥 First hospital verified: ${hospitals.first.isVerified || hospitals.first.verified}');
                }
                print('🎉 === VERIFIED HOSPITALS FINAL DATA END ===');
                return _buildVerifiedHospitalsList(hospitals);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: ProfessionalBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF159BBD),
        selectedColor: Colors.white,
        unselectedColor: Colors.white.withOpacity(0.7),
        items: const [
          BottomNavItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard_rounded, color: Colors.white),
            label: 'Home',
          ),
          BottomNavItem(
            icon: Icon(Icons.event_note_rounded),
            activeIcon: Icon(Icons.event_note_rounded, color: Colors.white),
            label: 'Appointments',
          ),
          BottomNavItem(
            icon: Icon(Icons.add_circle, size: 38, color: Colors.white),
            activeIcon: Icon(Icons.add_circle, size: 38, color: Colors.white),
            label: 'Book',
          ),
          BottomNavItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded, color: Colors.white),
            label: 'Messages',
          ),
          BottomNavItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle_rounded, color: Colors.white),
            label: 'Profile',
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
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFF159BBD).withOpacity(0.1),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search verified hospitals...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey[500],
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
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
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Hospitals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedHospitalsList(List<Hospital> hospitals) {
    // Filter only verified hospitals
    final verifiedHospitals = hospitals.where((hospital) => 
      hospital.isVerified || hospital.verified
    ).toList();

    // Apply search filter
    final filteredHospitals = _searchQuery.isEmpty 
        ? verifiedHospitals 
        : verifiedHospitals.where((hospital) => 
            hospital.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (hospital.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            hospital.facilities.any((facility) => 
                facility.toLowerCase().contains(_searchQuery.toLowerCase()))
          ).toList();

    print('🔍 === VERIFIED HOSPITALS FILTERING ===');
    print('🔍 Total hospitals received: ${hospitals.length}');
    print('🔍 Verified hospitals: ${verifiedHospitals.length}');
    print('🔍 After search filter: ${filteredHospitals.length}');

    if (filteredHospitals.isEmpty) {
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
                _searchQuery.isEmpty ? Icons.verified_user_outlined : Icons.search_off_rounded,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty 
                  ? 'No Verified Healthcare Centers' 
                  : 'No Results Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty 
                  ? 'Please check back later for verified healthcare centers in your area.'
                  : 'Try searching with different keywords.',
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
                  '${filteredHospitals.length} Verified Healthcare Centers',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Hospitals List
          Column(
            children: filteredHospitals.map((hospital) => _buildHospitalCard(hospital)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
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
              reviews: [],
              aboutText: hospital.about ?? 'This healthcare facility is committed to providing exceptional medical care and services.',
              hospitalSchedule: hospital.availableSchedule,
              supportsBooking: true, // All verified hospitals support booking
              isFromGooglePlaces: hospital.isFromGooglePlaces,
              placeId: hospital.placeId,
              isVerified: true, // All hospitals here are verified
              isUnverified: false,
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
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hospital Image with Overlay
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Hospital Image
                    _buildHospitalImage(hospital),

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

                    // Verified Badge
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
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
                  ],
                ),
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
                            Text(
                              hospital.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      // Rating
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
                              color: Colors.amber,
                              size: 14,
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
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hospital.location ?? 'Location not available',
                          style: TextStyle(
                            fontSize: 14,
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
                    const SizedBox(height: 16),
                  ],

                  // Book Appointment Button
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
                                rating: hospital.displayRating,
                                reviewCount: hospital.displayRatingCount,
                                reviews: [],
                                aboutText: hospital.about ?? 'This healthcare facility is committed to providing exceptional medical care and services.',
                                hospitalSchedule: hospital.availableSchedule,
                                supportsBooking: true,
                                isFromGooglePlaces: hospital.isFromGooglePlaces,
                                placeId: hospital.placeId,
                                isVerified: true,
                                isUnverified: false,
                              ),
                            ),
                          );
                        },
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'View Details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalImage(Hospital hospital) {
    if (hospital.profileImageUrl != null && hospital.profileImageUrl!.isNotEmpty) {
      if (hospital.profileImageUrl!.startsWith('data:image')) {
        return Image.memory(
          base64Decode(hospital.profileImageUrl!.split(',')[1]),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } else {
        return Image.network(
          hospital.profileImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              print('Network image loaded successfully for ${hospital.name}');
              return child;
            }
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading image for ${hospital.name}: $error');
            return _buildPlaceholderImage();
          },
        );
      }
    } else {
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
} 