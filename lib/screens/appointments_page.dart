import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Fetch appointments from Firebase
    final List<Map<String, dynamic>> appointments = [
      {
        'doctorName': 'Dr. Sarah Johnson',
        'specialty': 'Cardiology',
        'date': DateTime.now().add(const Duration(days: 2)),
        'time': '10:00 AM',
        'status': 'Upcoming',
      },
      {
        'doctorName': 'Dr. Michael Chen',
        'specialty': 'Neurology',
        'date': DateTime.now().add(const Duration(days: 5)),
        'time': '2:30 PM',
        'status': 'Upcoming',
      },
      {
        'doctorName': 'Dr. Emily Brown',
        'specialty': 'Dermatology',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'time': '11:00 AM',
        'status': 'Completed',
      },
    ];

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
                      'My Appointments',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Appointments List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      final bool isUpcoming = appointment['status'] == 'Upcoming';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
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
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: isUpcoming
                                    ? const Color(0xFF159BBD).withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  topRight: Radius.circular(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    appointment['status'],
                                    style: TextStyle(
                                      color: isUpcoming
                                          ? const Color(0xFF159BBD)
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(appointment['date']),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF159BBD).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF159BBD),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appointment['doctorName'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${appointment['specialty']} - ${appointment['time']}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isUpcoming)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        // TODO: Implement cancel appointment
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Appointment cancelled'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to book appointment page
        },
        backgroundColor: const Color(0xFF159BBD),
        child: const Icon(Icons.add),
      ),
    );
  }
} 