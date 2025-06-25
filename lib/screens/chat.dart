import 'package:flutter/material.dart';
import '../widgets/professional_bottom_nav.dart';

class Chat extends StatelessWidget {
  const Chat({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF159BBD),
        title: const Text('Chat Support'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMessage(
                  'Dr. Sarah Johnson',
                  'Hello! How can I help you today?',
                  '10:00 AM',
                  true,
                  'assets/doctor1.png',
                ),
                _buildMessage(
                  'You',
                  'I have a question about my medication.',
                  '10:01 AM',
                  false,
                  'assets/profil.png',
                ),
                _buildMessage(
                  'Dr. Sarah Johnson',
                  'Of course! What would you like to know?',
                  '10:02 AM',
                  true,
                  'assets/doctor1.png',
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF159BBD),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      // TODO: Implement send message functionality
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ProfessionalBottomNav(
        currentIndex: 2,
        onTap: (index) {
          // Navigation logic
        },
        items: [
          BottomNavItem(
            icon: ProfessionalIcons.home,
            activeIcon: ProfessionalIcons.homeActive,
            label: 'Home',
          ),
          BottomNavItem(
            icon: ProfessionalIcons.appointments,
            activeIcon: ProfessionalIcons.appointmentsActive,
            label: 'Appointments',
          ),
          BottomNavItem(
            icon: ProfessionalIcons.messages,
            activeIcon: ProfessionalIcons.messagesActive,
            label: 'Chat',
          ),
          BottomNavItem(
            icon: ProfessionalIcons.profile,
            activeIcon: ProfessionalIcons.profileActive,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(
    String sender,
    String message,
    String time,
    bool isDoctor,
    String imagePath,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isDoctor ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDoctor) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(imagePath),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDoctor
                    ? const Color(0xFF159BBD).withOpacity(0.1)
                    : const Color(0xFF159BBD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDoctor)
                    Text(
                      sender,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  if (isDoctor) const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: isDoctor ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDoctor ? Colors.grey[600] : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isDoctor) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage(imagePath),
            ),
          ],
        ],
      ),
    );
  }
} 