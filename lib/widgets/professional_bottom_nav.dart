import 'package:flutter/material.dart';

class ProfessionalBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<BottomNavItem> items;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  const ProfessionalBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor = const Color(0xFF159BBD),
    this.selectedColor = Colors.white,
    this.unselectedColor = Colors.white70,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
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
            selectedItemColor: selectedColor,
            unselectedItemColor: unselectedColor,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: unselectedColor,
            ),
            type: BottomNavigationBarType.fixed,
            currentIndex: currentIndex,
            onTap: onTap,
            items: items.map((item) => BottomNavigationBarItem(
              icon: item.icon,
              activeIcon: item.activeIcon ?? item.icon,
              label: item.label,
            )).toList(),
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final Widget icon;
  final Widget? activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

// Icônes professionnelles prédéfinies
class ProfessionalIcons {
  static const home = Icon(Icons.dashboard_rounded);
  static const homeActive = Icon(Icons.dashboard_rounded, color: Colors.white);
  
  static const appointments = Icon(Icons.event_note_rounded);
  static const appointmentsActive = Icon(Icons.event_note_rounded, color: Colors.white);
  
  static const messages = Icon(Icons.chat_bubble_outline_rounded);
  static const messagesActive = Icon(Icons.chat_bubble_rounded, color: Colors.white);
  
  static const profile = Icon(Icons.account_circle_outlined);
  static const profileActive = Icon(Icons.account_circle_rounded, color: Colors.white);
  
  static const video = Icon(Icons.video_call_outlined);
  static const videoActive = Icon(Icons.video_call_rounded, color: Colors.white);
  
  static const calendar = Icon(Icons.calendar_today_rounded);
  static const calendarActive = Icon(Icons.calendar_today_rounded, color: Colors.white);
  
  static const medical = Icon(Icons.medical_services_outlined);
  static const medicalActive = Icon(Icons.medical_services_rounded, color: Colors.white);
  
  static const lab = Icon(Icons.science_outlined);
  static const labActive = Icon(Icons.science_rounded, color: Colors.white);
} 