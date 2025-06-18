import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ChatPage(),
  ));
}

class ChatPage extends StatelessWidget {
  const ChatPage({Key? key}) : super(key: key);

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
                      'Messages',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Chat List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildChatItem(
                        name: 'Dr. Sarah Johnson',
                        lastMessage: 'Your test results are ready',
                        time: '10:30 AM',
                        isUnread: true,
                      ),
                      _buildChatItem(
                        name: 'Dr. Michael Chen',
                        lastMessage: 'Don\'t forget your appointment tomorrow',
                        time: 'Yesterday',
                        isUnread: false,
                      ),
                      _buildChatItem(
                        name: 'Lab Assistant',
                        lastMessage: 'Your blood test is scheduled for 2 PM',
                        time: '2 days ago',
                        isUnread: false,
                      ),
                      _buildChatItem(
                        name: 'Nurse Emma',
                        lastMessage: 'Please bring your medical history',
                        time: '3 days ago',
                        isUnread: false,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement new message functionality
        },
        backgroundColor: const Color(0xFF159BBD),
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildChatItem({
    required String name,
    required String lastMessage,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: const Color(0xFF159BBD).withOpacity(0.1),
            child: const Icon(
              Icons.person,
              color: Color(0xFF159BBD),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        color: isUnread ? const Color(0xFF159BBD) : Colors.black87,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: isUnread ? const Color(0xFF159BBD) : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  lastMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUnread ? Colors.black87 : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isUnread)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF159BBD),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
