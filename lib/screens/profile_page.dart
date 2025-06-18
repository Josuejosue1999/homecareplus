import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homecare_app/screens/choose.dart';
import 'package:homecare_app/screens/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userAddress = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          setState(() {
            userName = userData.data()?['name'] ?? '';
            userEmail = userData.data()?['email'] ?? '';
            userPhone = userData.data()?['phone'] ?? '';
            userAddress = userData.data()?['address'] ?? '';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
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
                      'Profile',
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
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // User Info
                              _buildInfoCard(
                                title: 'Personal Information',
                                items: [
                                  _buildInfoItem(Icons.person, userName),
                                  _buildInfoItem(Icons.email, userEmail),
                                  _buildInfoItem(Icons.phone, userPhone),
                                  _buildInfoItem(Icons.location_on, userAddress),
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
