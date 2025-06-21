import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_app/screens/main_dashboard.dart';
import 'package:homecare_app/screens/profile_page.dart';
import 'package:homecare_app/screens/chat_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:homecare_app/widgets/professional_bottom_nav.dart';
import 'dart:convert';
import 'dart:io';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  int _selectedIndex = 1;
  String userName = 'User';
  String greeting = '';
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
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
        // Déjà sur cette page
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 3:
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
              // Header PRO
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
                            MaterialPageRoute(builder: (context) => const MainDashboard()),
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
                          const Text(
                          'My Appointments',
                            style: TextStyle(
                              fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                          const SizedBox(height: 4),
                        Text(
                          greeting + ', ' + userName,
                          style: const TextStyle(
                              fontSize: 14,
                            color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Bouton profil
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.person, color: Colors.white, size: 24),
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
                  child: StreamBuilder<QuerySnapshot>(
                    key: ValueKey('appointments_$_refreshKey'),
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
                                    // Force rebuild
                                    setState(() {});
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
                                  'You haven\'t booked any appointments yet',
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

                      final appointments = snapshot.data!.docs;
                      
                      // Sort appointments by date (newest first)
                      appointments.sort((a, b) {
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
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final doc = appointments[index];
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
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                  // Hospital Image
                                  Container(
                                      width: 60,
                                      height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: const Color(0xFF159BBD).withOpacity(0.1),
                                    ),
                                    child: _buildHospitalImage(data['hospitalImage']),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Appointment Details
                                Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                          data['hospitalName'] ?? 'Unknown Hospital',
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
                                        _showDeleteConfirmation(context, doc.id, data['hospitalName'] ?? 'Unknown Hospital');
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
                          );
                        },
                      );
                    },
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

  Widget _buildHospitalImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(Icons.local_hospital, size: 30, color: Color(0xFF159BBD));
    }
    
    // Check if it's a base64 image (starts with data:image)
    if (imageUrl.startsWith('data:image')) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            base64Decode(imageUrl.split(',')[1]),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.local_hospital, size: 30, color: Color(0xFF159BBD));
            },
          ),
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return const Icon(Icons.local_hospital, size: 30, color: Color(0xFF159BBD));
      }
    }
    
    // Check if it's a network URL
    if (imageUrl.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.local_hospital, size: 30, color: Color(0xFF159BBD));
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
    }
    
    // Check if it's an asset
    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          imageUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.local_hospital, size: 30, color: Color(0xFF159BBD));
          },
        ),
      );
    }
    
    // Check if it's a local file path
    if (imageUrl.startsWith('/')) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(imageUrl),
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.local_hospital, size: 30, color: Color(0xFF159BBD));
            },
          ),
        );
      } catch (e) {
        print('Error loading local file: $e');
        return const Icon(Icons.local_hospital, size: 30, color: Color(0xFF159BBD));
      }
    }
    
    // Default fallback
    return const Icon(Icons.local_hospital, size: 30, color: Color(0xFF159BBD));
  }

  void _showDeleteConfirmation(BuildContext context, String appointmentId, String hospitalName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Delete Appointment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF159BBD),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to delete this appointment?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hospitalName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF159BBD),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This action cannot be undone.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleDelete(context, appointmentId, hospitalName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        );
      },
    );
  }

  void _handleDelete(BuildContext context, String appointmentId, String hospitalName) async {
    BuildContext? dialogContext;
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context;
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                ),
                SizedBox(width: 16),
                Text('Deleting appointment...'),
              ],
            ),
          );
        },
      );

      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .delete();

      // Close loading dialog immediately after successful deletion
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      // Force refresh the page
      if (context.mounted) {
        setState(() {
          _refreshKey++;
        });
      }

      // Show success message after a short delay
      if (context.mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Appointment deleted successfully'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }

      print('Appointment deleted successfully: $appointmentId');
    } catch (e) {
      print('Error deleting appointment: $e');
      
      // Close loading dialog if it's still open
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!).pop();
      }

      // Show error message after a short delay
      if (context.mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Failed to delete appointment. Please try again.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Dismiss',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        });
      }
    }
  }
} 