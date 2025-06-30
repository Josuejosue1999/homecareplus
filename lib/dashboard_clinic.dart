import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onlineconsult.dart';
import 'calendar_page.dart';
import 'chat_page.dart';
import 'clinic_profile_page.dart';
import '../services/appointment_service.dart';
import '../models/appointment.dart';
import 'appointment_detail_page.dart';
import 'screens/appointment_detail_page.dart';
import 'services/appointment_service.dart';
import 'services/hospital_service.dart';
import 'services/database_cleanup_service.dart';
import 'widgets/professional_bottom_nav.dart';

class ClinicDashboardPage extends StatefulWidget {
  const ClinicDashboardPage({Key? key}) : super(key: key);

  @override
  State<ClinicDashboardPage> createState() => _ClinicDashboardPageState();
}

class _ClinicDashboardPageState extends State<ClinicDashboardPage> {
  String clinicName = 'Clinic';
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  Future<void> _loadClinicData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Loading clinic data for user: ${user.uid}');
        print('User display name: ${user.displayName}');
        
        // Nettoyer et corriger la base de données
        await DatabaseCleanupService.cleanupDatabase();
        
        // Créer un document de clinique par défaut si il n'existe pas
        await HospitalService.createDefaultClinicIfNotExists();
        
        // Récupérer le nom de la clinique depuis Firebase
        final clinicNameFromFirebase = await AppointmentService.getClinicName(user.uid);
        
        if (clinicNameFromFirebase.isNotEmpty) {
          setState(() {
            clinicName = clinicNameFromFirebase;
            isLoading = false;
          });
          print('Using clinic name from Firebase: "$clinicName"');
        } else {
          setState(() {
            clinicName = user.displayName ?? 'Clinic';
            isLoading = false;
          });
          print('Using display name: "$clinicName"');
        }
        
      } else {
        print('No user found');
        setState(() {
          clinicName = 'Clinic';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading clinic data: $e');
      setState(() {
        clinicName = 'Clinic';
        isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF159BBD),
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
                        const Text(
                          'Clinic Dashboard',
                              style: TextStyle(
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
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.person, color: Color(0xFF159BBD)),
                        onPressed: () {
                          // Navigation vers le profil
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Today',
                                '0',
                                Icons.today,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'This Week',
                                '0',
                                Icons.calendar_view_week,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),

              const SizedBox(height: 20),

                        // Upcoming Appointments Section
                        Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                              'Upcoming Appointments',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF159BBD),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Clinic: $clinicName',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () async {
                                    print('Refresh triggered');
                                    await _loadClinicData();
                                    setState(() {});
                                  },
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Color(0xFF159BBD),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Appointments List
                        StreamBuilder<List<Appointment>>(
                          stream: AppointmentService.getAllAppointments(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF159BBD),
                                ),
                              );
                            }
                            
                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              );
                            }
                            
                            final allAppointments = snapshot.data ?? [];
                            print('Total appointments found: ${allAppointments.length}');
                            
                            // Filtrer les rendez-vous pour cette clinique
                            final clinicAppointments = allAppointments.where((appointment) {
                              final hospitalName = appointment.hospitalName.toLowerCase().trim();
                              final clinicNameLower = clinicName.toLowerCase().trim();
                              
                              print('Comparing: "$hospitalName" with "$clinicNameLower"');
                              
                              // Correspondance exacte
                              if (hospitalName == clinicNameLower) {
                                print('Exact match found for appointment: ${appointment.patientName}');
                                return true;
                              }
                              
                              // Correspondance partielle
                              if (hospitalName.contains(clinicNameLower) || clinicNameLower.contains(hospitalName)) {
                                print('Partial match found for appointment: ${appointment.patientName}');
                                return true;
                              }
                              
                              return false;
                            }).toList();
                            
                            print('Filtered appointments for clinic "$clinicName": ${clinicAppointments.length}');
                            
                            // Filtrer les rendez-vous à venir (prochains 7 jours)
                            final now = DateTime.now();
                            final nextWeek = now.add(const Duration(days: 7));
                            
                            final upcomingAppointments = clinicAppointments.where((appointment) {
                              final appointmentDate = appointment.appointmentDate;
                              final isUpcoming = appointmentDate.isAfter(now) && appointmentDate.isBefore(nextWeek);
                              final isPendingOrConfirmed = appointment.status == 'pending' || appointment.status == 'confirmed';
                              
                              return isUpcoming && isPendingOrConfirmed;
                            }).toList();
                            
                            print('Upcoming appointments for clinic "$clinicName": ${upcomingAppointments.length}');
                            
                            if (upcomingAppointments.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No upcoming appointments',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Appointments for the next 7 days will appear here',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Debug Info:',
                      style: TextStyle(
                                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                      ),
                    ),
                                    Text(
                                      'Total appointments in Firebase: ${allAppointments.length}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                    Text(
                                      'Appointments for this clinic: ${clinicAppointments.length}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                    Text(
                                      'Clinic name: "$clinicName"',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        print('Force update triggered');
                                        await AppointmentService.forceUpdateClinicNames();
                                        setState(() {});
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                      child: const Text(
                                        'Fix Clinic Names',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Column(
                              children: upcomingAppointments.map((appointment) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: appointment.status == 'confirmed' 
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.orange.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                                        MaterialPageRoute(
                                          builder: (context) => AppointmentDetailPage(appointment: appointment),
                                        ),
                        );
                      },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                appointment.patientName,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                          color: Color(0xFF159BBD),
                        ),
                      ),
                    ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: appointment.status == 'confirmed' 
                                                    ? Colors.green.withOpacity(0.1)
                                                    : Colors.orange.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: appointment.status == 'confirmed' 
                                                      ? Colors.green
                                                      : Colors.orange,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                appointment.status.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: appointment.status == 'confirmed' 
                                                      ? Colors.green
                                                      : Colors.orange,
                  ),
                ),
              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 8),
                    Text(
                                              '${appointment.appointmentTime.hour.toString().padLeft(2, '0')}:${appointment.appointmentTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                                        const SizedBox(height: 8),
                                        Row(
                  children: [
                                            Icon(
                                              Icons.medical_services,
                                              size: 16,
                                              color: Colors.grey[600],
                    ),
                                            const SizedBox(width: 8),
                                            Text(
                                              appointment.department,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                    ),
                  ],
                ),
                                        if (appointment.symptoms.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.note,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  appointment.symptoms,
                      style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                                        ],
              const SizedBox(height: 12),
                                        Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                                            Text(
                                              'Tap to view details',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                                fontStyle: FontStyle.italic,
                    ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: Colors.grey[400],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      },
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
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
                Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                    fontWeight: FontWeight.bold,
                  color: color,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 