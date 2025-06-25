import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import 'appointment_detail_page.dart';
import 'clinic_dashboard.dart';

class ClinicAppointmentsPage extends StatefulWidget {
  final String clinicName;

  const ClinicAppointmentsPage({
    Key? key,
    required this.clinicName,
  }) : super(key: key);

  @override
  State<ClinicAppointmentsPage> createState() => _ClinicAppointmentsPageState();
}

class _ClinicAppointmentsPageState extends State<ClinicAppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshKey = 0;
  String greeting = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _updateGreeting();
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
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
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
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ClinicDashboardPage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Titre et sous-titre
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hospital Appointments',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF159BBD),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$greeting, ${widget.clinicName}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Bouton refresh
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white, size: 24),
                        onPressed: () {
                          setState(() {
                            _refreshKey++;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: const Color(0xFF159BBD),
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Today'),
                    Tab(text: 'Upcoming'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Appointments List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAppointmentsList('all'),
                      _buildAppointmentsList('today'),
                      _buildAppointmentsList('upcoming'),
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

  Widget _buildAppointmentsList(String filterType) {
    return StreamBuilder<QuerySnapshot>(
      key: ValueKey('appointments_${widget.clinicName}_$filterType$_refreshKey'),
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('hospitalName', isEqualTo: widget.clinicName)
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
          print('Error loading appointments: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _refreshKey++;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF159BBD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    filterType == 'all' 
                        ? 'No appointments in this hospital yet'
                        : 'No ${filterType} appointments found',
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

        final allAppointments = snapshot.data!.docs;
        final filteredAppointments = _filterAppointments(allAppointments, filterType);
        
        if (filteredAppointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${filterType} appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No ${filterType} appointments found for this hospital',
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

        // Sort appointments by date (newest first)
        filteredAppointments.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          
          DateTime? aDate;
          DateTime? bDate;
          
          try {
            if (aData['appointmentDate'] is Timestamp) {
              aDate = (aData['appointmentDate'] as Timestamp).toDate();
            }
          } catch (e) {
            print('Error parsing date A: $e');
          }
          
          try {
            if (bData['appointmentDate'] is Timestamp) {
              bDate = (bData['appointmentDate'] as Timestamp).toDate();
            }
          } catch (e) {
            print('Error parsing date B: $e');
          }
          
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          
          return bDate.compareTo(aDate);
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            final doc = filteredAppointments[index];
            final data = doc.data() as Map<String, dynamic>;
            
            // Parse appointment date
            DateTime? appointmentDate;
            try {
              if (data['appointmentDate'] is Timestamp) {
                appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
              } else if (data['appointmentDate'] is String) {
                appointmentDate = DateTime.parse(data['appointmentDate']);
              }
            } catch (e) {
              print('Error parsing date: $e');
              appointmentDate = DateTime.now();
            }
            
            final isUpcoming = appointmentDate?.isAfter(DateTime.now().subtract(const Duration(days: 1))) ?? false;
            final status = data['status'] ?? 'pending';
            
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isUpcoming ? const Color(0xFF159BBD).withOpacity(0.18) : Colors.grey.withOpacity(0.13),
                  width: 1.2,
                ),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentDetailPage(
                        appointment: Appointment(
                          id: doc.id,
                          patientId: data['patientId'] ?? '',
                          patientName: data['patientName'] ?? 'Unknown Patient',
                          patientEmail: data['patientEmail'] ?? '',
                          patientPhone: data['patientPhone'] ?? '',
                          hospitalName: data['hospitalName'] ?? '',
                          hospitalImage: data['hospitalImage'] ?? '',
                          hospitalLocation: data['hospitalLocation'] ?? '',
                          department: data['department'] ?? 'General',
                          appointmentDate: appointmentDate ?? DateTime.now(),
                          appointmentTime: data['appointmentTime'] ?? '',
                          status: data['status'] ?? 'pending',
                          reasonOfBooking: data['reasonOfBooking'] ?? data['symptoms'] ?? '',
                          createdAt: data['createdAt'] != null 
                              ? (data['createdAt'] as Timestamp).toDate() 
                              : DateTime.now(),
                          updatedAt: data['updatedAt'] != null 
                              ? (data['updatedAt'] as Timestamp).toDate() 
                              : null,
                        ),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Patient Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFF159BBD).withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: Color(0xFF159BBD),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Appointment Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['patientName'] ?? 'Unknown Patient',
                              style: const TextStyle(
                                fontSize: 16,
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
                                fontSize: 13,
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
                                    DateFormat('EEE, MMM dd, yyyy').format(appointmentDate ?? DateTime.now()),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
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
                                      fontSize: 12,
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
                      
                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'confirmed' 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: status == 'confirmed' 
                                ? Colors.green.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          status == 'confirmed' ? 'CONF' : 'PENDING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: status == 'confirmed' 
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Delete Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            _showDeleteConfirmation(context, doc.id, data['patientName'] ?? 'Unknown Patient');
                          },
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _filterAppointments(List<QueryDocumentSnapshot> appointments, String filterType) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    return appointments.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      DateTime? appointmentDate;
      
      try {
        if (data['appointmentDate'] is Timestamp) {
          appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
        } else if (data['appointmentDate'] is String) {
          appointmentDate = DateTime.parse(data['appointmentDate']);
        }
      } catch (e) {
        print('Error parsing date: $e');
        return false;
      }

      if (appointmentDate == null) return false;

      // Normaliser la date du rendez-vous pour comparer seulement la date (sans l'heure)
      final appointmentDateOnly = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);

      switch (filterType) {
        case 'today':
          // Vérifier si la date du rendez-vous est aujourd'hui
          return appointmentDateOnly.isAtSameMomentAs(today);
        case 'upcoming':
          // Rendez-vous futurs (à partir d'aujourd'hui)
          return appointmentDateOnly.isAfter(today.subtract(const Duration(days: 1)));
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  void _showDeleteConfirmation(BuildContext context, String appointmentId, String patientName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Appointment'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the appointment for $patientName? This action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAppointment(appointmentId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    try {
      await AppointmentService.deleteAppointment(appointmentId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 