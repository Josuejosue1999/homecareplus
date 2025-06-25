import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';
import '../services/notification_service.dart';
import 'clinic_appointments_page.dart';
import 'chat.dart';
import 'clinic_profile_page.dart';
import 'clinic_notification_page.dart';
import 'login2.dart';
import 'appointment_detail_page.dart';
import '../widgets/professional_bottom_nav.dart';
import '../widgets/notification_badge.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../models/appointment.dart';

class ClinicDashboardPage extends StatefulWidget {
  const ClinicDashboardPage({Key? key}) : super(key: key);

  @override
  State<ClinicDashboardPage> createState() => _ClinicDashboardPageState();
}

class _ClinicDashboardPageState extends State<ClinicDashboardPage> {
  String clinicName = '';
  String greeting = '';
  List<Appointment> upcomingAppointments = [];
  bool isLoadingAppointments = true;
  bool isLoadingClinic = true;
  String? appointmentError;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndLoadData();
  }

  Future<void> _checkAuthenticationAndLoadData() async {
    try {
      setState(() {
        isLoadingClinic = true;
        isLoadingAppointments = true;
        appointmentError = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No authenticated user found, redirecting to login');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login2Page()),
          );
        }
        return;
      }

      print('Authenticated user: ${user.uid}');
      
      // Charger les données de la clinique en premier
      await _fetchClinicName();
      
      // Mettre à jour le greeting
    _updateGreeting();
      
      // Charger les rendez-vous seulement après avoir récupéré le nom de la clinique
      if (clinicName.isNotEmpty) {
        await _loadAppointments();
      }
      
      setState(() {
        isLoadingClinic = false;
      });
    } catch (e) {
      print('Error in authentication check: $e');
      if (mounted) {
        setState(() {
          appointmentError = 'Authentication error: $e';
          isLoadingClinic = false;
          isLoadingAppointments = false;
        });
      }
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

  Future<void> _loadAppointments() async {
    try {
      setState(() {
        isLoadingAppointments = true;
        appointmentError = null;
      });

      print('Loading appointments for clinic: $clinicName');
      
      // Utiliser la méthode sécurisée pour récupérer les rendez-vous à venir
      final upcomingStream = AppointmentService.getClinicUpcomingAppointments(clinicName);
      
      upcomingStream.listen((appointments) {
        print('Received ${appointments.length} upcoming appointments for clinic "$clinicName"');
        
        setState(() {
          upcomingAppointments = appointments;
          isLoadingAppointments = false;
        });
      }, onError: (error) {
        print('Error loading appointments: $error');
        setState(() {
          appointmentError = error.toString();
          isLoadingAppointments = false;
        });
      });
      
    } catch (e) {
      print('Error in _loadAppointments: $e');
      setState(() {
        appointmentError = e.toString();
        isLoadingAppointments = false;
      });
    }
  }

  Future<void> _fetchClinicName() async {
    try {
    final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return;
      }

      print('Fetching clinic data for user: ${user.uid}');
      
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(user.uid)
          .get();

      if (clinicDoc.exists) {
        final clinicData = clinicDoc.data()!;
        final name = clinicData['name'] ?? '';
        
        print('Clinic name from Firebase: "$name"');
        
        if (mounted) {
        setState(() {
            clinicName = name;
          });
        }
      } else {
        print('No clinic document found for user: ${user.uid}');
        // Créer un document de clinique par défaut si il n'existe pas
        await _createDefaultClinicDocument(user.uid);
      }
    } catch (e) {
      print('Error fetching clinic name: $e');
      if (mounted) {
        setState(() {
          appointmentError = 'Error loading clinic data: $e';
        });
      }
    }
  }

  Future<void> _createDefaultClinicDocument(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(userId)
          .set({
        'name': 'New Clinic',
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'phone': '',
        'address': '',
        'about': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        setState(() {
          clinicName = 'New Clinic';
        });
      }
    } catch (e) {
      print('Error creating default clinic document: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home - déjà sur le dashboard
        break;
      case 1: // Appointments
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClinicAppointmentsPage(clinicName: clinicName),
          ),
        );
        break;
      case 2: // Chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Chat')),
              body: const Center(child: Text('Chat coming soon!')),
            ),
          ),
        );
        break;
      case 3: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ClinicProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un écran de chargement si les données de la clinique ne sont pas encore chargées
    if (isLoadingClinic) {
      return Scaffold(
        backgroundColor: const Color(0xFF159BBD),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Loading health center dashboard...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we load your health center data',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Afficher une erreur si il y en a une
    if (appointmentError != null && clinicName.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF159BBD),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 24),
              Text(
                'Error Loading Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  appointmentError!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  _checkAuthenticationAndLoadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF159BBD),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
                          clinicName,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        await Navigator.push(
                            context,
                          MaterialPageRoute(
                            builder: (context) => ClinicNotificationPage(clinicId: user.uid),
                          ),
                          );
                        setState(() {});
                        },
                      child: Stack(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          StreamBuilder<int>(
                            stream: NotificationService.getUnreadClinicNotificationCount(FirebaseAuth.instance.currentUser?.uid ?? ''),
                            builder: (context, snapshot) {
                              final count = snapshot.data ?? 0;
                              if (count == 0) {
                                return const SizedBox.shrink();
                              }
                              return Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    count > 99 ? '99+' : count.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
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
                  child: SingleChildScrollView(
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
                                  MaterialPageRoute(
                                    builder: (context) => ClinicAppointmentsPage(clinicName: clinicName),
                                  ),
                                );
                              },
                              textSize: 10,
                            ),
                            _buildActionCard(
                              icon: Icons.message,
                              title: 'Messages',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      appBar: AppBar(title: const Text('Chat')),
                                      body: const Center(child: Text('Chat coming soon!')),
                                    ),
                                  ),
                                );
                              },
                              textSize: 12,
                            ),
                            _buildActionCard(
                              icon: Icons.people,
                              title: 'Patients',
                              onTap: () {
                                // TODO: Navigate to patients list
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Patients list coming soon!'),
                                    backgroundColor: Color(0xFF159BBD),
                                  ),
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

                        // Upcoming Appointments
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
                                        MaterialPageRoute(
                                          builder: (context) => ClinicAppointmentsPage(clinicName: clinicName),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'See All',
                                      style: TextStyle(
                                        color: Color(0xFF159BBD),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              if (isLoadingAppointments) ...[
                              Container(
                                  padding: const EdgeInsets.all(40),
                                  child: const Center(
                                child: Column(
                                  children: [
                                        CircularProgressIndicator(
                                          color: Color(0xFF159BBD),
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Loading appointments...',
                                          style: TextStyle(
                                            color: Color(0xFF159BBD),
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Please wait while we fetch your upcoming appointments',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                              ] else if (clinicName.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(40),
                                  child: const Center(
        child: Column(
          children: [
                                        CircularProgressIndicator(
                                          color: Color(0xFF159BBD),
                                        ),
                                        SizedBox(height: 16),
            Text(
                                          'Loading health center information...',
              style: TextStyle(
                                            fontSize: 18,
                fontWeight: FontWeight.w600,
                                            color: const Color(0xFF666666),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Please wait while we verify your health center details',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: const Color(0xFF999999),
                                          ),
            ),
          ],
        ),
      ),
                                ),
                              ] else if (appointmentError != null) ...[
        Container(
                                  padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
                                    color: Colors.red[50],
          borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          children: [
            Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Colors.red[400],
                                      ),
                                      const SizedBox(height: 12),
              Text(
                                        'Error Loading Appointments',
                                        style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                                          color: Colors.red[700],
                ),
            ),
            const SizedBox(height: 8),
            Text(
                                        'Please try again later',
              style: TextStyle(
                  fontSize: 14,
                                          color: Colors.red[600],
              ),
            ),
          ],
        ),
      ),
                              ] else ...[
                                upcomingAppointments.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
            colors: [
                                              Colors.grey[50]!,
                                              Colors.grey[100]!,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.grey[200]!,
                                            width: 1,
                                          ),
                                        ),
          child: Column(
      children: [
        Container(
                                              padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF159BBD).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(50),
                                              ),
                                              child: Icon(
                                                Icons.calendar_today_outlined,
                                                size: 48,
                                                color: const Color(0xFF159BBD),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
              Text(
                                              'No Upcoming Appointments',
                                              style: TextStyle(
                                                fontSize: 18,
                  fontWeight: FontWeight.bold,
                                                color: Colors.grey[800],
                ),
              ),
                                            const SizedBox(height: 8),
              Text(
                                              'You don\'t have any appointments scheduled for the next 7 days.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 20),
                                    Container(
                                              padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                                color: const Color(0xFF159BBD).withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                                  color: const Color(0xFF159BBD).withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
            children: [
                                                  Icon(
                                                    Icons.info_outline,
                                            color: const Color(0xFF159BBD),
                                            size: 20,
                                          ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'New appointments will appear here once patients book with your health center.',
                                                      style: const TextStyle(
                      color: Color(0xFF159BBD),
                                                        fontWeight: FontWeight.w500,
                                                        fontSize: 14,
                                                      ),
                                                      textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                                          ],
                                        ),
                                      )
                                    : Column(
            children: [
                                          // Afficher les 3 premiers rendez-vous
                                          ...upcomingAppointments.take(3).map((appointment) {
                                            return Column(
                  children: [
                                                InkWell(
                                                  onTap: () async {
                                                    final result = await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => AppointmentDetailPage(appointment: appointment),
                                                      ),
                                                    );
                                                    if (result == true) {
                                                      // Rafraîchir la liste des rendez-vous après confirmation/annulation
                                                      await _loadAppointments();
                                                      setState(() {}); // Rafraîchir l'interface
                                                    }
                                                  },
                                                  child: _buildProfessionalAppointmentCard(appointment),
                                                ),
                                                if (upcomingAppointments.indexOf(appointment) < upcomingAppointments.length - 1 && 
                                                    upcomingAppointments.indexOf(appointment) < 2)
                                                  const SizedBox(height: 12),
                                              ],
                                            );
                                          }).toList(),
                                          
                                          // Indicateur s'il y a plus de 3 rendez-vous
                                          if (upcomingAppointments.length > 3) ...[
                                            const SizedBox(height: 16),
                                    Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                                color: const Color(0xFF159BBD).withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                                  color: const Color(0xFF159BBD).withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.more_horiz,
                                            color: const Color(0xFF159BBD),
                                            size: 20,
                                          ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${upcomingAppointments.length - 3} more appointment${upcomingAppointments.length - 3 > 1 ? 's' : ''}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF159BBD),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                                          ],
                                          
                                          // Si moins de 3 rendez-vous, afficher un message d'encouragement
                                          if (upcomingAppointments.length < 3 && upcomingAppointments.isNotEmpty) ...[
                                            const SizedBox(height: 16),
                              Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                                  color: Colors.green.withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                                    Icons.check_circle_outline,
                                                    color: Colors.green[600],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                                  Text(
                                                    '${upcomingAppointments.length} appointment${upcomingAppointments.length > 1 ? 's' : ''} scheduled',
                                          style: TextStyle(
                                                      color: Colors.green[600],
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                            ),
                                          ],
                                        ],
                                      ),
                              ],
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
            label: 'Chat',
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    double textSize = 12,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 100,
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFF159BBD).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF159BBD).withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
                              ),
                            ],
                          ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                            children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF159BBD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
                          child: Text(
                title,
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF159BBD),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalAppointmentCard(Appointment appointment) {
    // Gérer les valeurs manquantes ou vides de manière professionnelle
    String patientName = appointment.patientName;
    
    // Si le nom du patient est vide ou "Unknown", essayer de le récupérer
    if (patientName.isEmpty || 
        patientName == 'Unknown' || 
        patientName == 'Patient Name Not Available' ||
        patientName == 'Unknown Patient') {
      patientName = 'Patient Name Not Available';
      
      // Afficher un log de débogage
      print('⚠️ Appointment ${appointment.id} has invalid patient name: "${appointment.patientName}"');
      print('   Patient ID: ${appointment.patientId}');
      print('   Hospital: ${appointment.hospitalName}');
    } else {
      print('✓ Appointment ${appointment.id} has valid patient name: "$patientName"');
    }
    
    final department = appointment.department.isNotEmpty 
        ? appointment.department 
        : 'General Consultation';
    
    final time = appointment.appointmentTime.isNotEmpty 
        ? appointment.appointmentTime 
        : 'Time TBD';
    
    final status = appointment.status.isNotEmpty 
        ? appointment.status 
        : 'pending';
    
    // Formater la date de manière plus lisible
    final dateFormatted = DateFormat('MMM dd, yyyy').format(appointment.appointmentDate);
    final timeFormatted = time != 'Time TBD' ? time : 'Time TBD';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            _getStatusColor(status).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
            child: Row(
              children: [
          // Icône avec couleur selon le statut
          Container(
            padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getStatusColor(status).withOpacity(0.1),
                  _getStatusColor(status).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(status),
              color: _getStatusColor(status),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Informations du rendez-vous
          Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                    Expanded(
                      child: Text(
                        patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(status).withOpacity(0.1),
                            _getStatusColor(status).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                          letterSpacing: 0.5,
                        ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
              Row(
                children: [
                    Icon(
                      Icons.medical_services,
                      size: 14,
                      color: const Color(0xFF159BBD),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        department,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
          ],
        ),
                const SizedBox(height: 8),
                  Row(
                    children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                      Text(
                      dateFormatted,
                        style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeFormatted,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
            ),
          ],
        ),
      ),
          
          // Flèche pour indiquer que c'est cliquable
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.calendar_today;
    }
  }
} 