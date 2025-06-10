import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ChatPage(),
  ));
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

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
              'Chats',
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

            // Exemple de liste de conversations
            Expanded(
              child: ListView(
                children: [
                  _chatTile('Dr. Jeanne', 'How are you feeling today?', 'assets/profil.png'),
                  _chatTile('Dr. Paul', 'Please confirm your appointment.', 'assets/doctolo.png'),
                  _chatTile('Dr. Grace', 'Thank you for your feedback.', 'assets/doctor2.png'),
                ],
              ),
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
          currentIndex: 3, // ✅ Index pour "Chat"
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

  Widget _chatTile(String name, String message, String imagePath) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: AssetImage(imagePath),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(message),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // Action à faire quand on clique sur un chat
      },
    );
  }
}
