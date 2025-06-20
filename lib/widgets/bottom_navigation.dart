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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF159BBD),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, -3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white.withOpacity(0.7),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                activeIcon: Icon(Icons.dashboard_rounded, color: Colors.white),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.video_call_outlined),
                activeIcon: Icon(Icons.video_call_rounded, color: Colors.white),
                label: 'Videos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.event_note_rounded),
                activeIcon: Icon(Icons.event_note_rounded, color: Colors.white),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                activeIcon: Icon(Icons.chat_bubble_rounded, color: Colors.white),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                activeIcon: Icon(Icons.account_circle_rounded, color: Colors.white),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 