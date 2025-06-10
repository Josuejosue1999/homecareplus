import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProfilePage(),
  ));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
              'My Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 169,
              height: 4,
              color: const Color(0xFF159BBD),
            ),

            const SizedBox(height: 30),

            // Photo + Nom + Email
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profil.png'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Josue Doe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'josue@email.com',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // Options
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF159BBD)),
              title: const Text('Edit Profile'),
              onTap: () {
                // Action de modification
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Color(0xFF159BBD)),
              title: const Text('Change Password'),
              onTap: () {
                // Action mot de passe
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout'),
              onTap: () {
                // Action logout
              },
            ),
          ],
        ),
      ),

      // ✅ Barre de navigation bas
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF159BBD),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          currentIndex: 4, // ✅ Index pour "Profile"
          onTap: (index) {
            // TODO: Navigation entre pages
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
}
