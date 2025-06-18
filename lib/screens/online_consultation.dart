import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

class OnlineConsultation extends StatelessWidget {
  const OnlineConsultation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF159BBD),
        title: const Text('Online Consultation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Doctors',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 20),
            _buildDoctorCard(
              'Dr. Sarah Johnson',
              'General Practitioner',
              'Available Now',
              'assets/doctor1.png',
            ),
            _buildDoctorCard(
              'Dr. Michael Chen',
              'Pediatrician',
              'Available in 30 mins',
              'assets/doctor2.png',
            ),
            _buildDoctorCard(
              'Dr. Emily Brown',
              'Dermatologist',
              'Available in 1 hour',
              'assets/doctor3.png',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 1,
        context: context,
      ),
    );
  }

  Widget _buildDoctorCard(
    String name,
    String specialization,
    String availability,
    String imagePath,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(imagePath),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    specialization,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    availability,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement video call functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF159BBD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Consult'),
            ),
          ],
        ),
      ),
    );
  }
} 