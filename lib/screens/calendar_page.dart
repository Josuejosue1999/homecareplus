import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: CalendarPage(),
  ));
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

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
              'My Calendar',
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
            const SizedBox(height: 20),

            // Message de contenu
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'You have no scheduled appointments yet.\nPlease check back later or book a new appointment.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),

            const SizedBox(height: 30),

            // Icône illustrative
            const Icon(Icons.calendar_month, size: 100, color: Color(0xFF159BBD)),
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
          currentIndex: 2, // ✅ Index du bouton "Calendar"
          onTap: (index) {
            // TODO: Navigation selon l'index
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
