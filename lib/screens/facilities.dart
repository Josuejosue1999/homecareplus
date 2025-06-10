import 'package:flutter/material.dart';
import 'facilities_dentalclinics.dart'; // ✅ Ajouté

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FacilitiesPage(),
  ));
}

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
              // Bouton retour
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
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Titre
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

              // Ligne 1
              _buildRow(context, [
                'Dental clinics',
                'Community\nHealth Centers',
                'Mental Health\nClinics',
              ]),

              const SizedBox(height: 20),

              // Ligne 2
              _buildRow(context, [
                'General\nHospitals',
                'Physiotherapy\nCenters',
                'Diagnostic\nLaboratories',
              ]),

              const SizedBox(height: 20),

              // Ligne 3
              _buildRow(context, [
                'Eye Clinics',
                'Pediatrics Clinics',
                'Gynecology &\nFertility Centers',
              ]),

              const SizedBox(height: 20),

              // Dernier box au centre
              Center(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Action pour ENT
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
            // TODO: handle navigation
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

  Widget _buildRow(BuildContext context, List<String> titles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: titles.map((title) => _facilityBox(context, title)).toList(),
      ),
    );
  }

  Widget _facilityBox(BuildContext context, String title) {
    return GestureDetector(
      onTap: () {
        if (title.trim().toLowerCase() == 'dental clinics') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FacilitiesDentalClinicsPage(),
            ),
          );
        }
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
