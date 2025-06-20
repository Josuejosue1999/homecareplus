import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:homecare_app/screens/profile_page.dart';
import 'package:homecare_app/screens/lab_test_page.dart';
import 'package:homecare_app/screens/chat_page.dart';
import 'package:homecare_app/screens/appointments_page.dart';
import 'package:homecare_app/screens/hospital_details.dart';
import 'package:homecare_app/screens/book_appointment.dart';
import 'package:homecare_app/widgets/professional_bottom_nav.dart';

class MainDashboard extends StatefulWidget {
  final String? selectedHospitalName;
  final String? selectedHospitalImage;
  
  const MainDashboard({
    Key? key,
    this.selectedHospitalName,
    this.selectedHospitalImage,
  }) : super(key: key);

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  String userName = 'User';
  String greeting = '';
  bool showHospitalBooking = false;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    if (widget.selectedHospitalName != null) {
      showHospitalBooking = true;
    }
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
      if (index == 0) {
        showHospitalBooking = false;
      }
    });

    switch (index) {
      case 0:
        // Already on home page
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AppointmentsPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  Widget _buildHospitalBookingContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Your Booking',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF159BBD),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review and confirm your appointment',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF159BBD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF159BBD)),
                    onPressed: () {
                      setState(() {
                        showHospitalBooking = false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Card principale avec informations détaillées
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Image de l'hôpital avec overlay
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      image: DecorationImage(
                        image: AssetImage(widget.selectedHospitalImage ?? 'assets/hospital.PNG'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Premium Healthcare',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF159BBD),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Informations détaillées
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom de l'hôpital et note
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.selectedHospitalName ?? 'Selected Hospital',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF159BBD),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  '4.8',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF159BBD),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Informations de contact et localisation
                        _buildInfoRow(
                          icon: Icons.location_on,
                          title: 'Location',
                          subtitle: '200 First St SW, Rochester, MN',
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.phone,
                          title: 'Contact',
                          subtitle: '+1 (555) 123-4567',
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.access_time,
                          title: 'Hours',
                          subtitle: '24/7 Emergency Care',
                          color: Colors.orange,
                        ),
                        const SizedBox(height: 16),
                        
                        // Services disponibles
                        const Text(
                          'Available Services',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF159BBD),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildServiceChip('Emergency Care'),
                            _buildServiceChip('Surgery'),
                            _buildServiceChip('ICU'),
                            _buildServiceChip('Laboratory'),
                            _buildServiceChip('Radiology'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Boutons d'action
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showHospitalBooking = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                  foregroundColor: Colors.grey[700],
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookAppointmentPage(
                                        hospitalName: widget.selectedHospitalName ?? '',
                                        hospitalImage: widget.selectedHospitalImage ?? '',
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF159BBD),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Continue Booking',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF159BBD),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceChip(String service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF159BBD).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF159BBD).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        service,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF159BBD),
        ),
      ),
    );
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
              // Header Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.person, color: Color(0xFF159BBD)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: showHospitalBooking
                      ? _buildHospitalBookingContent()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quick Actions
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF159BBD).withOpacity(0.05),
                                      const Color(0xFF0D5C73).withOpacity(0.03),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF159BBD).withOpacity(0.1),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Quick Actions',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF159BBD),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildActionCard(
                                          icon: Icons.calendar_today,
                                          title: 'Appointments',
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const AppointmentsPage()),
                                            );
                                          },
                                          textSize: 9,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildActionCard(
                                          icon: Icons.medical_services,
                                          title: 'Lab Tests',
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const LabTestPage()),
                                            );
                                          },
                                          textSize: 12,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildActionCard(
                                          icon: Icons.message,
                                          title: 'Messages',
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const ChatPage()),
                                            );
                                          },
                                          textSize: 12,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Nearby Hospitals Section
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF159BBD).withOpacity(0.1),
                                      const Color(0xFF0D5C73).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Nearby Hospitals',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // TODO: Navigate to all hospitals
                                          },
                                          child: const Text(
                                            'View All',
                                            style: TextStyle(
                                              color: Color(0xFF159BBD),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          _buildHospitalItem(
                                            hospitalName: 'Central Medical Center',
                                            distance: '2.5 km',
                                            rating: '4.8',
                                          ),
                                          const Divider(height: 20),
                                          _buildHospitalItem(
                                            hospitalName: 'City General Hospital',
                                            distance: '3.8 km',
                                            rating: '4.6',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Nouvelle section Upcoming Appointments PRO (robuste)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Upcoming Appointments',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => const AppointmentsPage()),
                                            );
                                          },
                                          child: const Text('See All'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('appointments')
                                          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                                          .limit(10)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        if (snapshot.hasError) {
                                          return Text('Error: \\${snapshot.error}');
                                        }
                                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                          return const Text('No appointments found.\nBook an appointment to see it here!', textAlign: TextAlign.center);
                                        }
                                        final appointments = snapshot.data!.docs;
                                        final sorted = List.from(appointments);
                                        sorted.sort((a, b) {
                                          final ad = (a['date'] is Timestamp) ? (a['date'] as Timestamp).toDate() : DateTime.now();
                                          final bd = (b['date'] is Timestamp) ? (b['date'] as Timestamp).toDate() : DateTime.now();
                                          return bd.compareTo(ad);
                                        });
                                        final mostRecent = sorted.take(2).toList();
                                        if (mostRecent.isEmpty) {
                                          return const Text('No upcoming appointments.');
                                        }
                                        return Column(
                                          children: mostRecent.map((doc) {
                                            final data = doc.data() as Map<String, dynamic>;
                                            String dateStr = '';
                                            try {
                                              if (data['date'] is Timestamp) {
                                                dateStr = DateFormat('MMM dd, yyyy').format((data['date'] as Timestamp).toDate());
                                              } else if (data['date'] is String) {
                                                dateStr = data['date'];
                                              }
                                            } catch (_) {}
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 16),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF7FAFC),
                                                borderRadius: BorderRadius.circular(15),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.04),
                                                    blurRadius: 6,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: Image.asset(
                                                      data['hospitalImage'] ?? 'assets/hospital.PNG',
                                                      width: 56,
                                                      height: 56,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          data['hospitalName'] ?? '',
                                                          style: const TextStyle(
                                                            fontSize: 17,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF159BBD),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.local_hospital, size: 16, color: Color(0xFF159BBD)),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              data['department'] ?? '',
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color: Color(0xFF159BBD),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.calendar_today, size: 15, color: Colors.grey),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              dateStr,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 12),
                                                            Icon(Icons.access_time, size: 15, color: Colors.grey),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              data['time'] ?? '',
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                color: Colors.black87,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    double textSize = 12,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: const Color(0xFF159BBD),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF159BBD),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalItem({
    required String hospitalName,
    required String distance,
    required String rating,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF159BBD).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.local_hospital,
            color: Color(0xFF159BBD),
            size: 20,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hospitalName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF159BBD),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    distance,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
} 