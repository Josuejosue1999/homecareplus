import 'package:flutter/material.dart';
import 'facilities_dentalclinics.dart';
import 'dashboard.dart';
import 'calendar_page.dart';
import 'chat_page.dart';
import 'onlineconsult.dart';
import 'profile_page.dart';
import 'general.dart';
import 'physiotherapy.dart';
import 'diagnostic.dart';
import 'mentalhealth.dart';
import 'eye.dart';
import 'pediatrics.dart';
import 'gynecology.dart';
import 'ent.dart';
import 'communityhealth.dart';

class FacilitiesPage extends StatelessWidget {
  const FacilitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF159BBD),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const DashboardPage()),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Facilities',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF159BBD),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Container(
                width: 169,
                height: 4,
                color: const Color(0xFF159BBD),
              ),
              const SizedBox(height: 30),
              _buildRow(context, [
                {'title': 'Dental clinics', 'page': const FacilitiesDentalClinicsPage()},
                {'title': 'Community\nHealth Centers', 'page': const FacilitiesCommunityHealthPage()},
                {'title': 'Mental Health\nClinics', 'page': const FacilitiesMentalHealthPage()},
              ]),
              const SizedBox(height: 20),
              _buildRow(context, [
                {'title': 'General\nHospitals', 'page': const FacilitiesGeneralHospitalsPage()},
                {'title': 'Physiotherapy\nCenters', 'page': const FacilitiesPhysiotherapyPage()},
                {'title': 'Diagnostic\nLaboratories', 'page': const FacilitiesDiagnosticPage()},
              ]),
              const SizedBox(height: 20),
              _buildRow(context, [
                {'title': 'Eye Clinics', 'page': const FacilitiesEyeClinicsPage()},
                {'title': 'Pediatrics Clinics', 'page': const FacilitiesPediatricsPage()},
                {'title': 'Gynecology &\nFertility Centers', 'page': const FacilitiesGynecologyPage()},
              ]),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FacilitiesENTPage()),
                    );
                  },
                  child: Container(
                    width: 94,
                    height: 81,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x26159BBD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'ENT (Ear, Nose, Throat) Clinics',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF159BBD),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          currentIndex: 0,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
                break;
              case 1:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnlineConsultPage()));
                break;
              case 2:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CalendarPage()));
                break;
              case 3:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatPage()));
                break;
              case 4:
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/home.png')),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/video.png')),
              label: 'Videos',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/calendar.png')),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/chat.png')),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: ImageIcon(AssetImage('assets/profil.png')),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<Map<String, dynamic>> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.map((item) => _facilityBox(context, item['title'], item['page'])).toList(),
      ),
    );
  }

  Widget _facilityBox(BuildContext context, String title, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
      child: Container(
        width: 94,
        height: 81,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0x26159BBD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
