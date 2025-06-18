import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:homecare_app/screens/login.dart';

class ClinicDashboardPage extends StatefulWidget {
  const ClinicDashboardPage({Key? key}) : super(key: key);

  @override
  State<ClinicDashboardPage> createState() => _ClinicDashboardPageState();
}

class _ClinicDashboardPageState extends State<ClinicDashboardPage> {
  int _selectedIndex = 0;
  String clinicName = 'Clinic';
  String greeting = '';

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _fetchClinicName();
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

  Future<void> _fetchClinicName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('clinics').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          clinicName = doc.data()?['name'] ?? 'Clinic';
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home page
        break;
      case 1:
        // Navigate to appointments page
        break;
      case 2:
        // Navigate to chat page
        break;
      case 3:
        // Navigate to profile page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ClinicProfilePage()),
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
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.person, color: Color(0xFF159BBD)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ClinicProfilePage()),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Actions
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
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildActionCard(
                              icon: Icons.calendar_today,
                              title: 'Appointments',
                              onTap: () {
                                // Navigate to appointments page
                              },
                            ),
                            _buildActionCard(
                              icon: Icons.message,
                              title: 'Messages',
                              onTap: () {
                                // Navigate to chat page
                              },
                            ),
                          ],
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
                                      // TODO: Navigate to all appointments
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
                                    _buildAppointmentItem(
                                      patientName: 'John Doe',
                                      specialty: 'Cardiology',
                                      date: DateTime.now().add(const Duration(days: 2)),
                                      time: '10:00 AM',
                                    ),
                                    const Divider(height: 20),
                                    _buildAppointmentItem(
                                      patientName: 'Jane Smith',
                                      specialty: 'Neurology',
                                      date: DateTime.now().add(const Duration(days: 5)),
                                      time: '2:30 PM',
                                    ),
                                  ],
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF159BBD),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.7),
          backgroundColor: const Color(0xFF159BBD),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(15),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 30,
              color: const Color(0xFF159BBD),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF159BBD),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem({
    required String patientName,
    required String specialty,
    required DateTime date,
    required String time,
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
            Icons.calendar_today,
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
                patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF159BBD),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$specialty - ${DateFormat('MMM dd, yyyy').format(date)} at $time',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ClinicProfilePage extends StatefulWidget {
  const ClinicProfilePage({Key? key}) : super(key: key);

  @override
  State<ClinicProfilePage> createState() => _ClinicProfilePageState();
}

class _ClinicProfilePageState extends State<ClinicProfilePage> {
  String clinicName = '';
  String clinicEmail = '';
  String clinicPhone = '';
  String clinicAddress = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  Future<void> _loadClinicData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final clinicData = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .get();

        if (clinicData.exists) {
          setState(() {
            clinicName = clinicData.data()?['name'] ?? '';
            clinicEmail = clinicData.data()?['email'] ?? '';
            clinicPhone = clinicData.data()?['phone'] ?? '';
            clinicAddress = clinicData.data()?['address'] ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading clinic data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error signing out: $e');
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Clinic Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Profile Picture
                              const CircleAvatar(
                                radius: 50,
                                backgroundColor: Color(0xFF159BBD),
                                child: Icon(
                                  Icons.local_hospital,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Clinic Info
                              _buildInfoCard(
                                title: 'Clinic Information',
                                items: [
                                  _buildInfoItem(Icons.business, clinicName),
                                  _buildInfoItem(Icons.email, clinicEmail),
                                  _buildInfoItem(Icons.phone, clinicPhone),
                                  _buildInfoItem(Icons.location_on, clinicAddress),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Settings
                              _buildInfoCard(
                                title: 'Settings',
                                items: [
                                  _buildInfoItem(Icons.notifications, 'Notifications'),
                                  _buildInfoItem(Icons.language, 'Language'),
                                  _buildInfoItem(Icons.security, 'Privacy & Security'),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Logout Button
                              ElevatedButton(
                                onPressed: _signOut,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF159BBD),
                                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> items}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF159BBD),
            ),
          ),
          const SizedBox(height: 15),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF159BBD), size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 