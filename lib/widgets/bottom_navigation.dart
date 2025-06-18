import 'package:flutter/material.dart';
import '../screens/dashboard.dart';
import '../screens/onlineconsult.dart';
import '../screens/calendar_page.dart';
import '../screens/chat_page.dart';
import '../screens/profile_page.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final BuildContext context;

  const BottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.context,
  }) : super(key: key);

  void _onItemTapped(int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const DashboardPage();
        break;
      case 1:
        page = const OnlineConsultPage();
        break;
      case 2:
        page = const CalendarPage();
        break;
      case 3:
        page = const ChatPage();
        break;
      case 4:
        page = const ProfilePage();
        break;
      default:
        page = const DashboardPage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF159BBD),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: _onItemTapped,
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
    );
  }
} 