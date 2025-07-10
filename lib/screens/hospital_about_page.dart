import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'reviews.dart';
import 'book_appointment.dart';
import 'pro_hospitals_page.dart';

class HospitalAboutPage extends StatefulWidget {
  final String hospitalName;
  final String hospitalImage;
  final String hospitalLocation;
  final String hospitalAbout;
  final List<String> hospitalFacilities;

  const HospitalAboutPage({
    super.key,
    required this.hospitalName,
    required this.hospitalImage,
    required this.hospitalLocation,
    required this.hospitalAbout,
    required this.hospitalFacilities,
  });

  @override
  State<HospitalAboutPage> createState() => _HospitalAboutPageState();
}

class _HospitalAboutPageState extends State<HospitalAboutPage> with TickerProviderStateMixin {
  String userName = 'User';
  String greeting = '';

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
    _updateGreeting();
    _initializeBubbleAnimations();
  }

  @override
  void dispose() {
    _bubble1Controller.dispose();
    _bubble2Controller.dispose();
    _bubble3Controller.dispose();
    _bubble4Controller.dispose();
    super.dispose();
  }

  void _initializeBubbleAnimations() {
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

    // Create bubble movement animations
    _bubble1Animation = Tween<Offset>(
      begin: const Offset(-0.1, 0.8),
      end: const Offset(1.1, -0.2),
    ).animate(CurvedAnimation(
      parent: _bubble1Controller,
      curve: Curves.linear,
    ));

    _bubble2Animation = Tween<Offset>(
      begin: const Offset(1.1, 0.9),
      end: const Offset(-0.1, -0.1),
    ).animate(CurvedAnimation(
      parent: _bubble2Controller,
      curve: Curves.linear,
    ));

    _bubble3Animation = Tween<Offset>(
      begin: const Offset(0.5, 1.2),
      end: const Offset(0.3, -0.3),
    ).animate(CurvedAnimation(
      parent: _bubble3Controller,
      curve: Curves.easeInOut,
    ));

    _bubble4Animation = Tween<Offset>(
      begin: const Offset(-0.2, 1.0),
      end: const Offset(1.2, 0.1),
    ).animate(CurvedAnimation(
      parent: _bubble4Controller,
      curve: Curves.easeInOut,
    ));

    // Start bubble animations
    _bubble1Controller.repeat();
    _bubble2Controller.repeat();
    _bubble3Controller.repeat();
    _bubble4Controller.repeat();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF159BBD),
              const Color(0xFF0D5C73),
              const Color(0xFF0D5C73).withOpacity(0.8),
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.6, 0.8],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section with Animated Bubbles
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    // Animated Bubbles Background
                    // Bubble 1
                    AnimatedBuilder(
                      animation: _bubble1Animation,
                      builder: (context, child) {
                        return Positioned(
                          left: _bubble1Animation.value.dx * MediaQuery.of(context).size.width,
                          top: _bubble1Animation.value.dy * 80,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.05),
                                ],
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
                          top: _bubble2Animation.value.dy * 80,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.08),
                                ],
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
                          top: _bubble3Animation.value.dy * 80,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.1),
                                  Colors.white.withOpacity(0.03),
                                ],
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
                          top: _bubble4Animation.value.dy * 80,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Header Content
                    Row(
                      children: [
                        // Bouton de retour
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Titre
                        Expanded(
                          child: Text(
                            'About',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        // Bouton profil
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.person, color: Color(0xFF159BBD)),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Main Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top image container with rounded bottom corners
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                          child: _buildHospitalImage(),
                        ),
                      ),
                      
                      // Content container below the image
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 24),
                              
                              // Section About
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF159BBD),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.hospitalAbout,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Adresse
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF159BBD).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF159BBD).withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: const Color(0xFF159BBD),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.hospitalLocation,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Available Time
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF159BBD).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF159BBD).withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: const Color(0xFF159BBD),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Available Time',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF159BBD),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Monday - Friday: 8:00 AM - 6:00 PM\nSaturday: 9:00 AM - 4:00 PM\nSunday: Closed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Facilities Section
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Facilities',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF159BBD),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.hospitalFacilities.map((facility) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF159BBD).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      facility,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF159BBD),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              
                              // Booking Button
                              Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF159BBD), Color(0xFF0D7A94)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF159BBD).withOpacity(0.3),
                                      spreadRadius: 0,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookAppointmentPage(
                                          hospitalName: widget.hospitalName,
                                          hospitalImage: widget.hospitalImage,
                                          hospitalLocation: widget.hospitalLocation,
                                          hospitalFacilities: widget.hospitalFacilities,
                                          hospitalAbout: widget.hospitalAbout,
                                          hospitalSchedule: const {},
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Book Appointment',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Reviews Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Reviews',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF159BBD),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const ReviewsPage()),
                                      );
                                    },
                                    child: const Text(
                                      'See all',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF159BBD),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Carousel des reviews
                              SizedBox(
                                height: 120,
                                child: PageView.builder(
                                  itemCount: 4,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0x26159BBD),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            ClipOval(
                                              child: Image.asset(
                                                'assets/pp1.png',
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Jeannette Jeanne',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  SizedBox(height: 2),
                                                  Text(
                                                    '1 day ago',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'Many thanks to this hospital, they are professional',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalImage() {
    if (widget.hospitalImage.isNotEmpty) {
      // Check if it's a base64 image
      if (widget.hospitalImage.startsWith('data:image')) {
        try {
          return Image.memory(
            base64Decode(widget.hospitalImage.split(',')[1]),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          );
        } catch (e) {
          return _buildPlaceholderImage();
        }
      }
      
      // Check if it's a network URL
      if (widget.hospitalImage.startsWith('http')) {
        return Image.network(
          widget.hospitalImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
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
      }
      
      // Check if it's an asset
      if (widget.hospitalImage.startsWith('assets/')) {
        return Image.asset(
          widget.hospitalImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      }
      
      // Check if it's a local file path
      if (widget.hospitalImage.startsWith('/')) {
        try {
          return Image.file(
            File(widget.hospitalImage),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          );
        } catch (e) {
          return _buildPlaceholderImage();
        }
      }
    }
    
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF159BBD).withOpacity(0.8),
            const Color(0xFF0D5C73).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.local_hospital,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }
} 