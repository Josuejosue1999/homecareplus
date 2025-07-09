import 'package:flutter/material.dart';
import 'package:homecare_app/widgets/professional_bottom_nav.dart';
import 'package:homecare_app/screens/main_dashboard.dart';
import 'package:homecare_app/screens/appointments_page.dart';
import 'package:homecare_app/screens/chat_page.dart';
import 'package:homecare_app/screens/profile_page.dart';
import 'package:homecare_app/screens/hospital_details.dart';
import 'package:homecare_app/screens/hospital_about_page.dart';
import 'package:homecare_app/services/hospital_service.dart';
import 'package:homecare_app/models/hospital.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

class ProHospitalsPage extends StatefulWidget {
  const ProHospitalsPage({Key? key}) : super(key: key);

  @override
  State<ProHospitalsPage> createState() => _ProHospitalsPageState();
}

class _ProHospitalsPageState extends State<ProHospitalsPage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String userName = 'User';
  String greeting = '';
  String _searchQuery = '';
  String _selectedFilter = 'All';
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _cardAnimation;
  
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
  
  // Location variables
  Position? _userPosition;
  String _userLocation = 'Detecting location...';
  bool _locationLoading = true;

  final List<String> _filterOptions = ['All', 'Open Now', 'Emergency', 'Specialist'];

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _getCurrentLocation();
    
    // Initialize animations
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
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
    
    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Initialize bubble animations with different paths
    _bubble1Animation = Tween<Offset>(
      begin: const Offset(-0.2, 1.2),
      end: const Offset(1.2, -0.2),
    ).animate(CurvedAnimation(
      parent: _bubble1Controller,
      curve: Curves.linear,
    ));
    
    _bubble2Animation = Tween<Offset>(
      begin: const Offset(1.2, 1.1),
      end: const Offset(-0.2, -0.1),
    ).animate(CurvedAnimation(
      parent: _bubble2Controller,
      curve: Curves.linear,
    ));
    
    _bubble3Animation = Tween<Offset>(
      begin: const Offset(0.5, 1.3),
      end: const Offset(0.5, -0.3),
    ).animate(CurvedAnimation(
      parent: _bubble3Controller,
      curve: Curves.linear,
    ));
    
    _bubble4Animation = Tween<Offset>(
      begin: const Offset(-0.1, 1.1),
      end: const Offset(1.1, -0.1),
    ).animate(CurvedAnimation(
      parent: _bubble4Controller,
      curve: Curves.linear,
    ));
    
    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardAnimationController.forward();
    });
    
    // Start bubble animations with repeat
    _bubble1Controller.repeat();
    _bubble2Controller.repeat();
    _bubble3Controller.repeat();
    _bubble4Controller.repeat();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _bubble1Controller.dispose();
    _bubble2Controller.dispose();
    _bubble3Controller.dispose();
    _bubble4Controller.dispose();
    super.dispose();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
  }

  void _onItemTapped(int index) {
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
        // Already on this page
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

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
        setState(() {
          _userLocation = 'Location services disabled';
          _locationLoading = false;
        });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
          setState(() {
            _userLocation = 'Location permission denied';
            _locationLoading = false;
          });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
        setState(() {
          _userLocation = 'Location permission permanently denied';
          _locationLoading = false;
        });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String locationText = '';
          
          if (place.locality != null && place.locality!.isNotEmpty) {
            locationText = place.locality!;
          }
          if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            if (locationText.isNotEmpty) {
              locationText += ', ${place.administrativeArea!}';
            } else {
              locationText = place.administrativeArea!;
            }
          }
          if (locationText.isEmpty) {
            locationText = 'Current Location';
          }

          if (mounted) {
          setState(() {
            _userPosition = position;
            _userLocation = locationText;
            _locationLoading = false;
          });
          }
        } else {
          if (mounted) {
          setState(() {
            _userPosition = position;
            _userLocation = 'Current Location';
            _locationLoading = false;
          });
          }
        }
      } catch (geocodingError) {
        if (mounted) {
        setState(() {
          _userPosition = position;
          _userLocation = 'Current Location';
          _locationLoading = false;
        });
        }
      }
    } catch (e) {
      if (mounted) {
      setState(() {
        _userLocation = 'Unable to get location';
        _locationLoading = false;
      });
      }
    }
  }

  double _calculateDistance(double? hospitalLat, double? hospitalLng) {
    if (_userPosition == null || hospitalLat == null || hospitalLng == null) {
      return 0.0;
    }

    return Geolocator.distanceBetween(
      _userPosition!.latitude,
      _userPosition!.longitude,
      hospitalLat,
      hospitalLng,
    ) / 1000; // Convert to kilometers
  }

  String _formatDistance(double distance) {
    if (distance == 0.0) return 'Distance N/A';
    if (distance < 1.0) {
      return '${(distance * 1000).round()}m away';
    } else {
      return '${distance.toStringAsFixed(1)}km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header Section
              AnimatedBuilder(
                animation: _headerAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -30 * (1 - _headerAnimation.value)),
                    child: Opacity(
                      opacity: _headerAnimation.value,
                      child: _buildEnhancedHeader(),
                    ),
                  );
                },
              ),
              
              // Main Content Area
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Search and Filter Section
                      AnimatedBuilder(
                        animation: _headerAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - _headerAnimation.value)),
                            child: Opacity(
                              opacity: _headerAnimation.value,
                              child: _buildSearchAndFilterSection(),
                            ),
                          );
                        },
                      ),
                      
                      // Hospital List
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _cardAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - _cardAnimation.value)),
                              child: Opacity(
                                opacity: _cardAnimation.value,
                                child: _buildHospitalsList(),
                              ),
                            );
                          },
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

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Stack(
        children: [
          // Animated Bubbles Background
          // Bubble 1
          AnimatedBuilder(
            animation: _bubble1Animation,
            builder: (context, child) {
              return Positioned(
                left: _bubble1Animation.value.dx * MediaQuery.of(context).size.width,
                top: _bubble1Animation.value.dy * 120,
                child: Container(
                  width: 60,
                  height: 60,
                      decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Bubble 2
          AnimatedBuilder(
            animation: _bubble2Animation,
            builder: (context, child) {
              return Positioned(
                left: _bubble2Animation.value.dx * MediaQuery.of(context).size.width,
                top: _bubble2Animation.value.dy * 120,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.03),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Bubble 3
          AnimatedBuilder(
            animation: _bubble3Animation,
            builder: (context, child) {
              return Positioned(
                left: _bubble3Animation.value.dx * MediaQuery.of(context).size.width,
                top: _bubble3Animation.value.dy * 120,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.02),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Bubble 4
          AnimatedBuilder(
            animation: _bubble4Animation,
            builder: (context, child) {
              return Positioned(
                left: _bubble4Animation.value.dx * MediaQuery.of(context).size.width,
                top: _bubble4Animation.value.dy * 120,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.13),
                        Colors.white.withOpacity(0.04),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Main Header Content
          Column(
            children: [
              // Top Navigation Row
              Row(
                children: [
                  // Back Button with Glass Morphism
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(context),
                child: Container(
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Title Section
                  Expanded(
                          child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                          greeting,
                                style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Find Healthcare',
                                style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                  
                  // Action Buttons
                  Row(
                    children: [
                      // Refresh Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              _getCurrentLocation();
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // User Location Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                            children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _locationLoading 
                            ? Icons.location_searching_rounded 
                            : Icons.location_on_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              Text(
                            'Your Location',
                                style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                              Text(
                            _userLocation,
                            style: const TextStyle(
                                  fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (_locationLoading)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ],
                              ),
                            ],
                          ),
                        );
                      }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF159BBD).withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search hospitals, specialties...',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
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
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : Container(
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF159BBD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF159BBD),
                          size: 20,
                        ),
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Filter Chips
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                final isOpenNow = filter == 'Open Now';
                
                return Container(
                  margin: EdgeInsets.only(
                    right: index < _filterOptions.length - 1 ? 12 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: isSelected 
                            ? (isOpenNow 
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF4CAF50),
                                      const Color(0xFF45A049),
                                      const Color(0xFF388E3C),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF159BBD),
                                      const Color(0xFF0E86A8),
                                      const Color(0xFF0A6B82),
                                    ],
                                  ))
                            : LinearGradient(
                                colors: [Colors.white, Colors.white],
                              ),
                        boxShadow: [
                          // Main shadow for depth
                          BoxShadow(
                            color: isSelected 
                                ? (isOpenNow 
                                    ? const Color(0xFF4CAF50).withOpacity(0.4)
                                    : const Color(0xFF159BBD).withOpacity(0.4))
                                : Colors.black.withOpacity(0.1),
                            blurRadius: isSelected ? 15 : 8,
                            offset: const Offset(0, 6),
                            spreadRadius: isSelected ? 1 : 0,
                          ),
                          // Inner highlight for 3D effect
                          if (isSelected) BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                            spreadRadius: 0,
                          ),
                          // Ambient shadow
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            spreadRadius: -5,
                          ),
                        ],
                        border: isSelected 
                            ? null 
                            : Border.all(
                                color: const Color(0xFF159BBD).withOpacity(0.3),
                                width: 1.5,
                              ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isOpenNow) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : const Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected 
                                          ? Colors.white.withOpacity(0.5)
                                          : const Color(0xFF4CAF50).withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              filter,
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.white 
                                    : (isOpenNow 
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF159BBD)),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.3,
                                shadows: isSelected ? [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ] : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clinics').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState();
        }

        final hospitals = snapshot.data?.docs ?? [];
        
        if (hospitals.isEmpty) {
          return _buildEmptyState();
        }

        // Filter hospitals based on search query
        final filteredHospitals = hospitals.where((doc) {
          final hospitalData = doc.data() as Map<String, dynamic>;
          final name = hospitalData['name']?.toString().toLowerCase() ?? '';
          final location = hospitalData['location']?.toString().toLowerCase() ?? '';
          
          if (_searchQuery.isEmpty) return true;
          
          return name.contains(_searchQuery.toLowerCase()) ||
                 location.contains(_searchQuery.toLowerCase());
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          itemCount: filteredHospitals.length,
          itemBuilder: (context, index) {
            final hospitalData = filteredHospitals[index].data() as Map<String, dynamic>;
            final hospital = Hospital.fromFirestore(hospitalData, filteredHospitals[index].id);
            
            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildPremiumHospitalCard(hospital, index),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPremiumHospitalCard(Hospital hospital, int index) {
    // Calculate distance
    double distance = _calculateDistance(hospital.latitude, hospital.longitude);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF159BBD).withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HospitalAboutPage(
                  hospitalName: hospital.name,
                  hospitalImage: hospital.profileImageUrl ?? '',
                  hospitalLocation: hospital.location ?? 'Address not available',
                  hospitalAbout: hospital.about ?? 'No description available.',
                  hospitalFacilities: hospital.facilities,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Enhanced Hospital Image
                Hero(
                  tag: 'hospital_${hospital.name}_$index',
                  child: Container(
                    width: 90,
                    height: 90,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF159BBD).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildEnhancedHospitalImage(hospital.profileImageUrl),
                    ),
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Hospital Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hospital Name with Premium Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                        hospital.name,
                        style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF159BBD),
                                  const Color(0xFF0E86A8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Location with Enhanced Icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF159BBD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Color(0xFF159BBD),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hospital.location ?? 'Address not available',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Distance Display
                      if (_userPosition != null)
                      Row(
                        children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.directions_rounded,
                                size: 14,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDistance(distance),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      
                      const SizedBox(height: 12),
                      
                      // Rating and Status Row
                      Row(
                        children: [
                          // Rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Open Now',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                            ),
                      ),
                    ],
                  ),
                ),
                
                          const Spacer(),
                          
                          // Action Button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF159BBD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                                color: const Color(0xFF159BBD).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HospitalAboutPage(
                                hospitalName: hospital.name,
                                hospitalImage: hospital.profileImageUrl ?? '',
                                hospitalLocation: hospital.location ?? 'Address not available',
                                hospitalAbout: hospital.about ?? 'No description available.',
                                hospitalFacilities: hospital.facilities,
                              ),
                            ),
                          );
                        },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF159BBD),
                                    size: 16,
                        ),
                      ),
                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHospitalImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPremiumDefaultImage();
    }
    
    // Handle base64 images
    if (imageUrl.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(imageUrl.split(',')[1]),
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPremiumDefaultImage();
          },
        );
      } catch (e) {
        return _buildPremiumDefaultImage();
      }
    }
    
    // Handle network URLs
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPremiumDefaultImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
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
    }
    
    // Handle asset images
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPremiumDefaultImage();
        },
      );
    }
    
    return _buildPremiumDefaultImage();
  }

  Widget _buildPremiumDefaultImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF159BBD),
            const Color(0xFF0E86A8),
            const Color(0xFF0A6B82),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -5,
            left: -5,
            child: Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
                Icons.local_hospital_rounded,
        color: Colors.white,
        size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Connection Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your internet connection\nand try again',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                // Trigger rebuild
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Try Again',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF159BBD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF159BBD).withOpacity(0.1),
                  const Color(0xFF0E86A8).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.local_hospital_outlined,
              size: 64,
              color: Color(0xFF159BBD),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Healthcare Centers',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Healthcare centers will appear here\nonce they register with our platform',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
} 