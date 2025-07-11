import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:homecare_app/screens/find_healthcare_page.dart';
import 'package:homecare_app/screens/patient_dashboard.dart';
import 'package:homecare_app/screens/hospital_details.dart';
import 'package:homecare_app/screens/appointments_page.dart';
import 'package:homecare_app/screens/main_dashboard.dart';
import 'package:homecare_app/screens/chat_page.dart';
import 'package:homecare_app/screens/profile_page.dart';
import 'package:homecare_app/screens/healthcare_providers_page.dart';
import 'package:homecare_app/widgets/professional_bottom_nav.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../services/enhanced_hospital_service.dart';
import '../models/hospital.dart';

class BookingHubPage extends StatefulWidget {
  const BookingHubPage({Key? key}) : super(key: key);

  @override
  State<BookingHubPage> createState() => _BookingHubPageState();
}

class _BookingHubPageState extends State<BookingHubPage> with TickerProviderStateMixin {
  int _selectedIndex = 2; // Book tab is selected
  String userName = 'Patient';

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          final data = userDoc.data()!;
          setState(() {
            userName = data['name'] ?? data['fullName'] ?? 'Patient';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
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
        // Already on booking page
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Header Section
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF159BBD),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF159BBD),
                          Color(0xFF0D7B8A),
                        ],
                      ),
                    ),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Text(
                              'Hello, $userName 👋',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Find and book healthcare appointments',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '📅 Book Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    '🏥 Quality Care',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
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
              
              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      _buildSearchBar(),
                      const SizedBox(height: 32),
                      
                      // Quick Actions
                      _buildQuickActions(),
                      
                      const SizedBox(height: 100), // Bottom padding for navigation
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
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search hospitals, doctors, or services...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[400],
            size: 24,
          ),
          suffixIcon: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FindHealthcarePage()),
              );
            },
            icon: const Icon(
              Icons.map_rounded,
              color: Color(0xFF159BBD),
              size: 24,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PatientDashboardPage()),
          );
        },
        readOnly: true,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 20),
        
        // Première rangée d'actions
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.local_hospital_rounded,
                title: 'Find Hospitals',
                subtitle: 'Browse nearby hospitals',
                color: const Color(0xFF159BBD),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PatientDashboardPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.verified_rounded,
                title: 'Healthcare Providers',
                subtitle: 'All verified providers',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HealthcareProvidersPage()),
                  );
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Deuxième rangée d'actions
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.map_rounded,
                title: 'Map View',
                subtitle: 'Explore with maps',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FindHealthcarePage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.emergency_rounded,
                title: 'Emergency',
                subtitle: 'Quick emergency help',
                color: const Color(0xFFEF4444),
                onTap: () {
                  // Emergency action - could call emergency services or show emergency contacts
                  _showEmergencyDialog();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.emergency_rounded, color: Color(0xFFEF4444)),
              SizedBox(width: 8),
              Text('Emergency Help'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('In case of emergency, please call:'),
              SizedBox(height: 12),
              Text('🚨 Emergency: 911', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('🏥 Ambulance: 912', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('🚓 Police: 910', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
} 