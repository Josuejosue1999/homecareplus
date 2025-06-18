import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';

class Calendar extends StatelessWidget {
  const Calendar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF159BBD),
        title: const Text('Appointments'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Appointments',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 20),
            _buildAppointmentCard(
              'Dr. Sarah Johnson',
              'General Check-up',
              'March 15, 2024',
              '10:00 AM',
              'assets/doctor1.png',
            ),
            _buildAppointmentCard(
              'Dr. Michael Chen',
              'Follow-up Consultation',
              'March 18, 2024',
              '2:30 PM',
              'assets/doctor2.png',
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement new appointment booking
                },
                icon: const Icon(Icons.add),
                label: const Text('Book New Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF159BBD),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 2,
        context: context,
      ),
    );
  }

  Widget _buildAppointmentCard(
    String doctorName,
    String appointmentType,
    String date,
    String time,
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
                    doctorName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointmentType,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF159BBD),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF159BBD),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF159BBD),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF159BBD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // TODO: Implement reschedule functionality
              },
              icon: const Icon(
                Icons.edit,
                color: Color(0xFF159BBD),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 