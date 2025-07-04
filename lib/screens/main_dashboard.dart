import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:homecare_app/screens/profile_page.dart';
import 'package:homecare_app/screens/chat_page.dart';
import 'package:homecare_app/screens/appointments_page.dart';
import 'package:homecare_app/screens/hospital_details.dart';
import 'package:homecare_app/screens/book_appointment.dart';
import 'package:homecare_app/screens/pro_hospitals_page.dart';
import 'package:homecare_app/screens/notification_page.dart';
import 'package:homecare_app/widgets/professional_bottom_nav.dart';
import 'package:homecare_app/widgets/notification_badge.dart';
import 'package:homecare_app/widgets/chat_notification_badge.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../services/notification_service.dart';

class MainDashboard extends StatefulWidget {
  final String? selectedHospitalName;
  final String? selectedHospitalImage;
  final String? selectedHospitalLocation;
  final List<String>? selectedHospitalFacilities;
  final String? selectedHospitalAbout;
  final Map<String, Map<String, String>>? selectedHospitalSchedule;
  
  const MainDashboard({
    Key? key,
    this.selectedHospitalName,
    this.selectedHospitalImage,
    this.selectedHospitalLocation,
    this.selectedHospitalFacilities,
    this.selectedHospitalAbout,
    this.selectedHospitalSchedule,
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
      if (index == 0 && widget.selectedHospitalName != null) {
        showHospitalBooking = true;
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
        // Navigation vers la page des hôpitaux
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProHospitalsPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 4:
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
                    onPressed: widget.selectedHospitalName != null ? null : () {
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
                    ),
                    child: _buildHospitalImage(),
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
                          subtitle: widget.selectedHospitalLocation ?? 'Location not available',
                          color: Colors.red,
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
                          children: (widget.selectedHospitalFacilities ?? ['General Care', 'Consultation']).map((facility) {
                            return _buildServiceChip(facility);
                          }).toList(),
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
                                        hospitalLocation: widget.selectedHospitalLocation ?? '',
                                        hospitalFacilities: widget.selectedHospitalFacilities ?? [],
                                        hospitalAbout: widget.selectedHospitalAbout ?? '',
                                        hospitalSchedule: widget.selectedHospitalSchedule ?? {},
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
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    NotificationBadge(
                      onPressed: () async {
                        await Navigator.push(
                            context,
                          MaterialPageRoute(builder: (context) => const NotificationPage()),
                          );
                        setState(() {}); // Rafraîchir le badge après retour
                        },
                      size: 50,
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
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF159BBD).withOpacity(0.06),
                                      const Color(0xFF0D5C73).withOpacity(0.04),
                                      Colors.white.withOpacity(0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF159BBD).withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.white,
                                      blurRadius: 10,
                                      offset: const Offset(0, -4),
                                      spreadRadius: 1,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFF159BBD).withOpacity(0.12),
                                    width: 1.2,
                                  ),
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
                                            Icons.flash_on_rounded,
                                            color: Color(0xFF159BBD),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Quick Actions',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF159BBD),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          child: _buildActionCard(
                                            lottieAsset: 'assets/cal.json',
                                            title: 'Appointments',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const AppointmentsPage()),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildActionCard(
                                            lottieAsset: 'assets/book.json',
                                            title: 'Book',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const ProHospitalsPage()),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ChatNotificationBadge(
                                            child: _buildActionCard(
                                              lottieAsset: 'assets/sms.json',
                                              title: 'Messages',
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => const ChatPage()),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Section Upcoming Appointments
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      const Color(0xFF159BBD).withOpacity(0.02),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF159BBD).withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.white,
                                      blurRadius: 10,
                                      offset: const Offset(0, -4),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: const Color(0xFF159BBD).withOpacity(0.06),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                                Icons.schedule_rounded,
                                                color: Color(0xFF159BBD),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Upcoming Appointments',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF159BBD),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const AppointmentsPage()),
                                              );
                                            },
                                            child: const Text(
                                              'See All',
                                              style: TextStyle(
                                                color: Color(0xFF159BBD),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    StreamBuilder<QuerySnapshot>(
                                      key: ValueKey('appointments_${FirebaseAuth.instance.currentUser?.uid ?? ""}'),
                                      stream: FirebaseFirestore.instance
                                          .collection('appointments')
                                          .where('patientId', isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '')
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(20),
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                                              ),
                                            ),
                                          );
                                        }
                                        
                                        if (snapshot.hasError) {
                                          print('Error in appointments stream: ${snapshot.error}');
                                          return Container(
                                            padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red[300],
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Error loading appointments',
                                                  style: TextStyle(
                                                    color: Colors.red[300],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Please try again later',
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                          );
                                        }

                                        final appointments = snapshot.data?.docs ?? [];
                                        print('Found ${appointments.length} appointments');

                                        if (appointments.isEmpty) {
                                          return Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                                Icon(
                                                  Icons.calendar_today_outlined,
                                                  color: Colors.grey[400],
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'No upcoming appointments',
                                          style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Book an appointment to see it here!',
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                          );
                                        }
                                        
                                        // Filtrer et trier les rendez-vous
                                        final now = DateTime.now();
                                        print('=== FILTERING APPOINTMENTS ===');
                                        print('Current time: $now');
                                        print('Total appointments: ${appointments.length}');
                                        
                                        final upcomingAppointments = appointments.where((doc) {
                                          final data = doc.data() as Map<String, dynamic>;
                                          final appointmentDate = data['appointmentDate'] is Timestamp 
                                              ? (data['appointmentDate'] as Timestamp).toDate()
                                              : DateTime.now();
                                          final status = data['status'] ?? 'pending';
                                          final patientId = data['patientId'] ?? '';
                                          final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                                          
                                          // Filtrer par date ET statut ET patient
                                          final isUpcoming = appointmentDate.isAfter(now);
                                          final isValidStatus = status == 'pending' || status == 'confirmed';
                                          final isCurrentPatient = patientId == currentUserId;
                                          
                                          print('Appointment: ${doc.id}');
                                          print('  - Date: $appointmentDate (isUpcoming: $isUpcoming)');
                                          print('  - Status: $status (isValidStatus: $isValidStatus)');
                                          print('  - Patient ID: $patientId vs Current: $currentUserId (isCurrentPatient: $isCurrentPatient)');
                                          print('  - Include: ${isUpcoming && isValidStatus && isCurrentPatient}');
                                          
                                          return isUpcoming && isValidStatus && isCurrentPatient;
                                        }).toList();
                                        
                                        print('Filtered appointments: ${upcomingAppointments.length}');
                                        
                                        upcomingAppointments.sort((a, b) {
                                          final aDate = (a.data() as Map<String, dynamic>)['appointmentDate'] is Timestamp 
                                              ? ((a.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp).toDate()
                                              : DateTime.now();
                                          final bDate = (b.data() as Map<String, dynamic>)['appointmentDate'] is Timestamp 
                                              ? ((b.data() as Map<String, dynamic>)['appointmentDate'] as Timestamp).toDate()
                                              : DateTime.now();
                                          return aDate.compareTo(bDate);
                                        });
                                        
                                        final displayAppointments = upcomingAppointments.take(2).toList();
                                        print('Display appointments: ${displayAppointments.length}');
                                        
                                        // Ensure we show at least 2 appointments if available
                                        final minDisplayCount = 2;
                                        final actualDisplayCount = displayAppointments.length;
                                        
                                        if (actualDisplayCount < minDisplayCount && upcomingAppointments.length >= minDisplayCount) {
                                          // If we have more appointments but filtered less than minimum, show more
                                          final additionalAppointments = upcomingAppointments.take(minDisplayCount).toList();
                                          print('Showing minimum ${minDisplayCount} appointments: ${additionalAppointments.length}');
                                          
                                          return Column(
                                            children: additionalAppointments.map((doc) {
                                              final data = doc.data() as Map<String, dynamic>;
                                              final appointmentDate = data['appointmentDate'] is Timestamp 
                                                  ? (data['appointmentDate'] as Timestamp).toDate()
                                                  : DateTime.now();
                                              final status = data['status'] ?? 'pending';
                                              
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 16),
                                                padding: const EdgeInsets.all(18),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Colors.white,
                                                      const Color(0xFF159BBD).withOpacity(0.01),
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF159BBD).withOpacity(0.06),
                                                      blurRadius: 15,
                                                      offset: const Offset(0, 6),
                                                      spreadRadius: 1,
                                                    ),
                                                    BoxShadow(
                                                      color: Colors.white,
                                                      blurRadius: 8,
                                                      offset: const Offset(0, -2),
                                                      spreadRadius: 0,
                                                    ),
                                                  ],
                                                  border: Border.all(
                                                    color: const Color(0xFF159BBD).withOpacity(0.04),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    // Image de l'hôpital
                                                    Container(
                                                      width: 56,
                                                      height: 56,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(16),
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          colors: [
                                                            const Color(0xFF159BBD).withOpacity(0.08),
                                                            const Color(0xFF159BBD).withOpacity(0.04),
                                                          ],
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(0xFF159BBD).withOpacity(0.1),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 3),
                                                            spreadRadius: 1,
                                                          ),
                                                        ],
                                                        border: Border.all(
                                                          color: const Color(0xFF159BBD).withOpacity(0.06),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: FutureBuilder<Widget>(
                                                        future: _buildHospitalImageForAppointmentWithFallback(data['hospitalImage'], data['hospitalName']),
                                                        builder: (context, snapshot) {
                                                          if (snapshot.hasData) {
                                                            return snapshot.data!;
                                                          }
                                                          return _buildPlaceholderImageForAppointment();
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    
                                                    // Informations du rendez-vous
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            data['hospitalName'] ?? 'Unknown Hospital',
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFF159BBD),
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            data['department'] ?? 'General',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[600],
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.calendar_today,
                                                                size: 14,
                                                                color: Colors.grey[600],
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  DateFormat('MMM dd').format(appointmentDate),
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    color: Colors.grey[600],
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Icon(
                                                                Icons.access_time,
                                                                size: 14,
                                                                color: Colors.grey[600],
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  data['appointmentTime'] ?? 'TBD',
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    color: Colors.grey[600],
                                                                  ),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    
                                                    // Statut du rendez-vous
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          begin: Alignment.topCenter,
                                                          end: Alignment.bottomCenter,
                                                          colors: status == 'confirmed' 
                                                              ? [
                                                                  const Color(0xFF4CAF50),
                                                                  const Color(0xFF388E3C),
                                                                ]
                                                              : [
                                                                  const Color(0xFFFF9800),
                                                                  const Color(0xFFF57C00),
                                                                ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: (status == 'confirmed' 
                                                                ? const Color(0xFF4CAF50)
                                                                : const Color(0xFFFF9800)).withOpacity(0.3),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 3),
                                                            spreadRadius: 1,
                                                          ),
                                                          BoxShadow(
                                                            color: Colors.white.withOpacity(0.8),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, -1),
                                                            spreadRadius: 0,
                                                          ),
                                                        ],
                                                        border: Border.all(
                                                          color: Colors.white.withOpacity(0.2),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        status == 'confirmed' ? 'CONFIRMED' : 'PENDING',
                                                        style: const TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.white,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        } else {
                                          // Use the original display logic
                                        return Column(
                                          children: displayAppointments.map((doc) {
                                            final data = doc.data() as Map<String, dynamic>;
                                            final appointmentDate = data['appointmentDate'] is Timestamp 
                                                ? (data['appointmentDate'] as Timestamp).toDate()
                                                : DateTime.now();
                                            final status = data['status'] ?? 'pending';
                                            
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 16),
                                              padding: const EdgeInsets.all(18),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white,
                                                    const Color(0xFF159BBD).withOpacity(0.01),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF159BBD).withOpacity(0.06),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 6),
                                                    spreadRadius: 1,
                                                  ),
                                                  BoxShadow(
                                                    color: Colors.white,
                                                    blurRadius: 8,
                                                    offset: const Offset(0, -2),
                                                    spreadRadius: 0,
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: const Color(0xFF159BBD).withOpacity(0.04),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // Image de l'hôpital
                                                  Container(
                                                    width: 56,
                                                    height: 56,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(16),
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                        colors: [
                                                          const Color(0xFF159BBD).withOpacity(0.08),
                                                          const Color(0xFF159BBD).withOpacity(0.04),
                                                        ],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(0xFF159BBD).withOpacity(0.1),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 3),
                                                          spreadRadius: 1,
                                                        ),
                                                      ],
                                                      border: Border.all(
                                                        color: const Color(0xFF159BBD).withOpacity(0.06),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: FutureBuilder<Widget>(
                                                      future: _buildHospitalImageForAppointmentWithFallback(data['hospitalImage'], data['hospitalName']),
                                                      builder: (context, snapshot) {
                                                        if (snapshot.hasData) {
                                                          return snapshot.data!;
                                                        }
                                                        return _buildPlaceholderImageForAppointment();
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  
                                                  // Informations du rendez-vous
                                                  Expanded(
                                                      child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                        Text(
                                                          data['hospitalName'] ?? 'Unknown Hospital',
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF159BBD),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 2),
                                                            Text(
                                                          data['department'] ?? 'General',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Row(
                                                          children: [
                                                            Icon(
                                                              Icons.calendar_today,
                                                              size: 14,
                                                              color: Colors.grey[600],
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Expanded(
                                                              child: Text(
                                                                DateFormat('MMM dd').format(appointmentDate),
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors.grey[600],
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Icon(
                                                              Icons.access_time,
                                                              size: 14,
                                                              color: Colors.grey[600],
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Expanded(
                                                              child: Text(
                                                                data['appointmentTime'] ?? 'TBD',
                                                                style: TextStyle(
                                                                  fontSize: 11,
                                                                  color: Colors.grey[600],
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  
                                                  // Statut du rendez-vous
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment.topCenter,
                                                        end: Alignment.bottomCenter,
                                                        colors: status == 'confirmed' 
                                                            ? [
                                                                const Color(0xFF4CAF50),
                                                                const Color(0xFF388E3C),
                                                              ]
                                                            : [
                                                                const Color(0xFFFF9800),
                                                                const Color(0xFFF57C00),
                                                              ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: (status == 'confirmed' 
                                                              ? const Color(0xFF4CAF50)
                                                              : const Color(0xFFFF9800)).withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 3),
                                                          spreadRadius: 1,
                                                        ),
                                                        BoxShadow(
                                                          color: Colors.white.withOpacity(0.8),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, -1),
                                                          spreadRadius: 0,
                                                        ),
                                                      ],
                                                      border: Border.all(
                                                        color: Colors.white.withOpacity(0.2),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                        status == 'confirmed' ? 'CONFIRMED' : 'PENDING',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // All Hospitals Section
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
                                          'All Hospitals',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const ProHospitalsPage(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                              decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF159BBD), Color(0xFF0D5C73)],
                                              ),
                                              borderRadius: BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                  color: const Color(0xFF159BBD).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                            child: const Text(
                                              'View All',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                    const SizedBox(height: 15),
                                    SizedBox(
                                      height: 180,
                                      child: StreamBuilder<QuerySnapshot>(
                                        stream: FirebaseFirestore.instance
                                            .collection('clinics')
                                            .limit(4)
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                                              ),
                                            );
                                          }

                                          if (snapshot.hasError) {
                                            return Center(
                                              child: Text(
                                                'Error loading hospitals: ${snapshot.error}',
                                                style: const TextStyle(color: Colors.red),
                                              ),
                                            );
                                          }

                                          final hospitals = snapshot.data?.docs ?? [];

                                          if (hospitals.isEmpty) {
                                            return const Center(
                                              child: Text(
                                                'No hospitals available',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            );
                                          }

                                          return PageView.builder(
                                            itemCount: (hospitals.length / 2).ceil(),
                                            itemBuilder: (context, pageIndex) {
                                              final startIndex = pageIndex * 2;
                                              final endIndex = (startIndex + 2).clamp(0, hospitals.length);
                                              final pageHospitals = hospitals.sublist(startIndex, endIndex);

                                              return Row(
                                                children: [
                                                  for (int i = 0; i < 2; i++)
                                                    Expanded(
                                                      child: i < pageHospitals.length
                                                          ? Padding(
                                                              padding: EdgeInsets.only(
                                                                left: i == 0 ? 0 : 8,
                                                                right: i == 1 ? 0 : 8,
                                                              ),
                                                              child: _buildHospitalCard(
                                                                hospital: pageHospitals[i],
                                                                isFirst: i == 0,
                                                              ),
                                                            )
                                                          : const SizedBox(),
                                                    ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
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

  Widget _buildActionCard({
    IconData? icon,
    String? lottieAsset,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFF159BBD).withOpacity(0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF159BBD).withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white,
              blurRadius: 10,
              offset: const Offset(0, -3),
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: const Color(0xFF159BBD).withOpacity(0.08),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottieAsset != null)
              SizedBox(
                width: 42,
                height: 42,
                child: Lottie.asset(
                  lottieAsset,
                  fit: BoxFit.contain,
                ),
              )
            else if (icon != null)
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF159BBD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: const Color(0xFF159BBD),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF159BBD),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHospitalCard({
    required QueryDocumentSnapshot hospital,
    required bool isFirst,
  }) {
    final data = hospital.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Unknown Hospital';
    final location = data['location'] ?? data['address'] ?? 'Location not available';
    final facilities = List<String>.from(data['facilities'] ?? []);
    final profileImageUrl = data['profileImageUrl'] ?? '';

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
      children: [
          // Image section
        Container(
            width: 60,
            height: 140,
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            color: const Color(0xFF159BBD).withOpacity(0.1),
            ),
            child: profileImageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                    child: profileImageUrl.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(profileImageUrl.split(',')[1]),
                            fit: BoxFit.cover,
                            width: 60,
                            height: 140,
                          )
                        : Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 140,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          ),
                  )
                : _buildPlaceholderImage(),
          ),
          // Info section
        Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                    name,
                style: const TextStyle(
                      fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF159BBD),
                ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
              ),
                  const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                        size: 10,
                    color: Colors.grey[600],
                  ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                    style: TextStyle(
                            fontSize: 9,
                      color: Colors.grey[600],
                    ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (facilities.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 10,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            facilities.take(2).join(', '),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  Row(
                    children: [
                  Icon(
                    Icons.star,
                        size: 10,
                        color: Colors.amber,
                  ),
                      const SizedBox(width: 2),
                  Text(
                        '4.5',
                    style: TextStyle(
                          fontSize: 9,
                      color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
              ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
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

  Widget _buildHospitalImage() {
    return Stack(
      children: [
        // Image de l'hôpital
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: _buildImageWidget(),
        ),
        // Overlay gradient
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
      ],
    );
  }

  Widget _buildImageWidget() {
    if (widget.selectedHospitalImage != null && widget.selectedHospitalImage!.isNotEmpty) {
      // Check if it's a base64 image (starts with data:image)
      if (widget.selectedHospitalImage!.startsWith('data:image')) {
        // Base64 image from Firestore
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Image.memory(
            base64Decode(widget.selectedHospitalImage!.split(',')[1]),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      }
      // Check if it's a network URL
      else if (widget.selectedHospitalImage!.startsWith('http')) {
        // Network image
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Image.network(
            widget.selectedHospitalImage!,
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
          ),
        );
      } else if (widget.selectedHospitalImage!.startsWith('assets/')) {
        // Asset image
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Image.asset(
            widget.selectedHospitalImage!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      } else {
        // Local file path
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Image.file(
            File(widget.selectedHospitalImage!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      }
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildHospitalImageForAppointment(String? hospitalImage) {
    if (hospitalImage != null && hospitalImage.isNotEmpty) {
      // Check if it's a base64 image (starts with data:image)
      if (hospitalImage.startsWith('data:image')) {
        // Base64 image from Firestore
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(hospitalImage.split(',')[1]),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImageForAppointment();
            },
          ),
        );
      }
      // Check if it's a network URL
      else if (hospitalImage.startsWith('http')) {
        // Network image
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            hospitalImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImageForAppointment();
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
          ),
        );
      } else if (hospitalImage.startsWith('assets/')) {
        // Asset image
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            hospitalImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImageForAppointment();
            },
          ),
        );
      } else {
        // Local file path
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(hospitalImage),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImageForAppointment();
            },
          ),
        );
      }
    } else {
      return _buildPlaceholderImageForAppointment();
    }
  }

  Widget _buildPlaceholderImageForAppointment() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF159BBD).withOpacity(0.1),
            const Color(0xFF0D5C73).withOpacity(0.05),
          ],
        ),
      ),
      child: const Icon(
        Icons.local_hospital,
        color: Color(0xFF159BBD),
        size: 24,
      ),
    );
  }

  // 🔧 FIX: Build hospital image with fallback fetching for appointments
  Future<Widget> _buildHospitalImageForAppointmentWithFallback(String? hospitalImage, String? hospitalName) async {
    // If we already have a hospital image, use it
    if (hospitalImage != null && hospitalImage.trim().isNotEmpty) {
      return _buildHospitalImageForAppointment(hospitalImage);
    }
    
    // If no image but we have hospital name, try to fetch image dynamically
    if (hospitalName != null && hospitalName.trim().isNotEmpty) {
      try {
        final fetchedImage = await AppointmentService.getHospitalImageByName(hospitalName.trim());
        if (fetchedImage != null && fetchedImage.trim().isNotEmpty) {
          return _buildHospitalImageForAppointment(fetchedImage);
        }
      } catch (e) {
        print('Error fetching hospital image for $hospitalName: $e');
      }
    }
    
    // Fallback to placeholder
    return _buildPlaceholderImageForAppointment();
  }
} 