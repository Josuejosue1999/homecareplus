import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

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
      bottomNavigationBar: BottomNavigation(
        currentIndex: 2,
        context: context,
      ),
    );
  }
}
