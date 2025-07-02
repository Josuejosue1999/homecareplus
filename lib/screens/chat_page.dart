import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:homecare_app/screens/main_dashboard.dart';
import 'package:homecare_app/screens/profile_page.dart';
import 'package:homecare_app/screens/appointments_page.dart';
import 'package:homecare_app/screens/pro_hospitals_page.dart';
import 'package:homecare_app/widgets/professional_bottom_nav.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'chat_conversation_page.dart';
import 'dart:convert';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  int _selectedIndex = 3; // Changed to 3 for chat
  String userName = 'User';
  String greeting = '';

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _loadUserName();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            userName = data['name'] ?? data['fullName'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainDashboard()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppointmentsPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProHospitalsPage()),
        );
        break;
      case 3:
        // Already on chat page
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  Future<void> _markConversationAsRead(String conversationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await ChatService.markConversationAsRead(conversationId);
    } catch (e) {
      print('Error marking conversation as read: $e');
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.person, color: Color(0xFF159BBD)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                          );
                        },
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
                  child: StreamBuilder<List<ChatConversation>>(
                    stream: ChatService.getPatientConversations(),
                    builder: (context, snapshot) {
                      print('ChatPage: StreamBuilder state: ${snapshot.connectionState}');
                      print('ChatPage: StreamBuilder hasError: ${snapshot.hasError}');
                      print('ChatPage: StreamBuilder error: ${snapshot.error}');
                      print('ChatPage: StreamBuilder hasData: ${snapshot.hasData}');
                      print('ChatPage: StreamBuilder data length: ${snapshot.data?.length ?? 0}');
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        print('ChatPage: Error in StreamBuilder: ${snapshot.error}');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading conversations',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please check your connection and try again',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    // Force rebuild
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF159BBD),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final conversations = snapshot.data ?? [];
                      print('ChatPage: Final conversations list length: ${conversations.length}');

                      if (conversations.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No conversations yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start booking appointments to chat with clinics!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = conversations[index];
                          print('ChatPage: Building chat item for conversation: ${conversation.id}');
                          print('ChatPage: Conversation details:');
                          print('  - Clinic Name: ${conversation.clinicName}');
                          print('  - Hospital Image: ${conversation.hospitalImage}');
                          print('  - Last Message: ${conversation.lastMessage}');
                          print('  - Has Unread: ${conversation.hasUnreadMessages}');
                          print('  - Unread Count: ${conversation.unreadCount}');
                          return _buildChatItem(conversation);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ProfessionalBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF159BBD),
        selectedColor: Colors.white,
        unselectedColor: Colors.white.withOpacity(0.7),
        items: const [
          BottomNavItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard_rounded, color: Colors.white),
            label: 'Home',
          ),
          BottomNavItem(
            icon: Icon(Icons.event_note_rounded),
            activeIcon: Icon(Icons.event_note_rounded, color: Colors.white),
            label: 'Appointments',
          ),
          BottomNavItem(
            icon: Icon(Icons.add_circle, size: 38, color: Colors.white),
            activeIcon: Icon(Icons.add_circle, size: 38, color: Colors.white),
            label: 'Book',
          ),
          BottomNavItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded, color: Colors.white),
            label: 'Messages',
          ),
          BottomNavItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle_rounded, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatConversation conversation) {
    final isUnread = conversation.hasUnreadMessages;
    final timeAgo = _getTimeAgo(conversation.lastMessageTime);

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
      child: InkWell(
        onTap: () async {
          // Marquer la conversation comme lue avant d'ouvrir
          if (isUnread) {
            await _markConversationAsRead(conversation.id);
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatConversationPage(
                conversationId: conversation.id,
                otherPartyName: conversation.clinicName,
                isClinic: false,
              ),
            ),
          );
        },
        child: Row(
          children: [
            // Avatar avec image de l'hôpital
            _buildHospitalAvatar(conversation.clinicName, conversation.hospitalImage),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conversation.clinicName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            color: isUnread ? const Color(0xFF159BBD) : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread ? const Color(0xFF159BBD) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    conversation.lastMessage,
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
      ),
    );
  }

  Widget _buildHospitalAvatar(String hospitalName, String? hospitalImage) {
    print('Loading image for hospital: $hospitalName, image: $hospitalImage');
    
    // Si on a une vraie image de l'hôpital depuis Firebase, l'utiliser
    if (hospitalImage != null && hospitalImage.isNotEmpty) {
      print('Using Firebase image for $hospitalName: $hospitalImage');
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF159BBD).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: _buildHospitalImageWidget(hospitalImage),
        ),
      );
    }

    // Fallback vers le mapping statique si pas d'image Firebase
    final hospitalImages = {
      'king Hospital': 'assets/hospital.PNG',
      'King Hospital': 'assets/hospital.PNG',
      'New Hospital': 'assets/hospital2.PNG',
      'newclinic': 'assets/hospital.PNG',
      'Test Clinic 1750941734839': 'assets/hospital.PNG',
    };

    final imagePath = hospitalImages[hospitalName] ?? 'assets/hospital.PNG';
    print('Using fallback image for $hospitalName: $imagePath');

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF159BBD).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading asset image: $error');
            return _buildPlaceholderAvatar();
          },
        ),
      ),
    );
  }

  Widget _buildHospitalImageWidget(String imageUrl) {
    print('Building image widget for: $imageUrl');
    
    // Check if it's a base64 image (starts with data:image)
    if (imageUrl.startsWith('data:image')) {
      try {
        print('Loading base64 image');
        return Image.memory(
          base64Decode(imageUrl.split(',')[1]),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error decoding base64 image: $error');
            return _buildPlaceholderAvatar();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildPlaceholderAvatar();
      }
    }
    
    // Check if it's a network URL
    if (imageUrl.startsWith('http')) {
      print('Loading network image: $imageUrl');
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network image: $error');
          return _buildPlaceholderAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
            ),
          );
        },
      );
    }
    
    // Check if it's an asset
    if (imageUrl.startsWith('assets/')) {
      print('Loading asset image: $imageUrl');
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading asset image: $error');
          return _buildPlaceholderAvatar();
        },
      );
    }
    
    // Default fallback
    print('Using placeholder avatar for: $imageUrl');
    return _buildPlaceholderAvatar();
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF159BBD).withOpacity(0.1),
        borderRadius: BorderRadius.circular(23),
      ),
      child: const Icon(
        Icons.local_hospital,
        color: Color(0xFF159BBD),
        size: 24,
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
