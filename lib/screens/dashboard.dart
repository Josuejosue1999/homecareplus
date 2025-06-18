import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'facilities.dart'; // <-- Pour la navigation vers FacilitiesPage
import 'onlineconsult.dart'; // <-- Pour la navigation vers OnlineConsultPage
import '../widgets/bottom_navigation.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DashboardPage(),
  ));
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF159BBD),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundImage: AssetImage('assets/profil.png'),
                            ),
                            const SizedBox(width: 10),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Loading...', style: TextStyle(color: Colors.white));
                                }
                                if (snapshot.hasError) {
                                  return const Text('Error loading name', style: TextStyle(color: Colors.white));
                                }
                                final data = snapshot.data?.data() as Map<String, dynamic>?;
                                final realName = data?['fullName'] ?? 'User';
                                return Text(
                                  'Good Morning, $realName',
                                  style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                                );
                              },
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {},
                          child: Image.asset(
                            'assets/notif.png',
                            width: 36,
                            height: 36,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            'Search',
                            style: TextStyle(color: Colors.grey),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Our Facilities',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const FacilitiesPage()),
                        );
                      },
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF159BBD),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  height: 70,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _facilityCircle('assets/faci1.png', 'Dental clinics'),
                      _facilityCircle('assets/faci2.png', 'General Hospital'),
                      _facilityCircle('assets/faci3.png', 'Mental Health Clinics'),
                      _facilityCircle('assets/faci4.png', 'Eye Clinics'),
                      _facilityCircle('assets/faci5.png', 'Pediatrics Clinics'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: const [
                    Text(
                      'Upcoming Schedule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0x26159BBD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/doctolo.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dr Jose',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('Dentist',
                              style: TextStyle(color: Colors.black54, fontSize: 12)),
                          const SizedBox(height: 6),
                          Container(
                            width: 292,
                            height: 35,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x47159BBD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text('Monday, 5 June',
                                        style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Image.asset('assets/calendar1.png',
                                        width: 14, height: 14),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 20,
                                  color: Colors.grey,
                                ),
                                Row(
                                  children: [
                                    const Text('09:00 - 10:00 AM',
                                        style: TextStyle(fontSize: 11)),
                                    const SizedBox(width: 4),
                                    Image.asset('assets/clock1.png',
                                        width: 14, height: 14),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Hospital',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    InkWell(
                      onTap: () {},
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF159BBD),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _hospitalBox('assets/general1.png', 'General Hospital'),
                    _hospitalBox('assets/general1.png', 'Dental Clinics'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigation(
          currentIndex: 0,
        context: context,
      ),
    );
  }

  Widget _facilityCircle(String imagePath, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  Widget _hospitalBox(String imagePath, String title) {
    return Container(
      width: 176,
      height: 177,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.asset(
              imagePath,
              width: 176,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}