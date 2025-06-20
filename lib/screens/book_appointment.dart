import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:homecare_app/screens/main_dashboard.dart';
import 'package:homecare_app/screens/profile_page.dart';
import 'package:homecare_app/screens/chat_page.dart';
import 'package:homecare_app/screens/appointments_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class BookAppointmentPage extends StatefulWidget {
  final String hospitalName;
  final String hospitalImage;
  final String hospitalLocation;
  final List<String> hospitalFacilities;
  final String hospitalAbout;
  final Map<String, Map<String, String>> hospitalSchedule;

  const BookAppointmentPage({
    Key? key,
    required this.hospitalName,
    required this.hospitalImage,
    required this.hospitalLocation,
    required this.hospitalFacilities,
    required this.hospitalAbout,
    required this.hospitalSchedule,
  }) : super(key: key);

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  int _selectedIndex = 0;
  String? selectedDepartment;
  DateTime? selectedDate;
  String? selectedTime;
  String? selectedSpecialty;
  String patientName = '';
  String patientPhone = '';
  String patientEmail = '';
  String symptoms = '';
  String notes = '';

  // Controllers pour les champs de texte
  late TextEditingController _symptomsController;

  // Variables pour la gestion des horaires
  List<String> availableDays = [];
  List<String> availableTimeSlots = [];
  Map<String, List<String>> dayTimeSlots = {};

  @override
  void initState() {
    super.initState();
    _symptomsController = TextEditingController(text: symptoms);
    _initializeAvailableSlots();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  void _initializeAvailableSlots() {
    // Extraire les jours disponibles
    availableDays = widget.hospitalSchedule.keys.toList();
    
    // Générer les créneaux horaires pour chaque jour
    for (String day in availableDays) {
      final schedule = widget.hospitalSchedule[day];
      if (schedule != null) {
        final startTime = schedule['startTime'] ?? '';
        final endTime = schedule['endTime'] ?? '';
        
        if (startTime.isNotEmpty && endTime.isNotEmpty) {
          dayTimeSlots[day] = _generateTimeSlots(startTime, endTime);
        }
      }
    }
  }

  List<String> _generateTimeSlots(String startTime, String endTime) {
    List<String> slots = [];
    
    try {
      // Parser les heures de début et fin
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      
      if (start != null && end != null) {
        DateTime current = start;
        while (current.isBefore(end)) {
          slots.add(_formatTime(current));
          current = current.add(const Duration(minutes: 30)); // Créneaux de 30 minutes
        }
      }
    } catch (e) {
      print('Error generating time slots: $e');
    }
    
    return slots;
  }

  DateTime? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(2024, 1, 1, hour, minute);
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeForDisplay(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '${displayHour}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      print('Error formatting time: $e');
    }
    return time;
  }

  List<String> _getAvailableDates() {
    List<String> dates = [];
    final now = DateTime.now();
    
    for (int i = 0; i < 30; i++) { // Prochains 30 jours
      final date = now.add(Duration(days: i));
      final dayName = DateFormat('EEEE').format(date);
      
      if (availableDays.contains(dayName)) {
        dates.add(DateFormat('yyyy-MM-dd').format(date));
      }
    }
    
    return dates;
  }

  void _onItemTapped(int index) {
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
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  Future<void> _bookAppointment() async {
    // Validation des champs
    if (selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (symptoms.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your symptoms'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Afficher un indicateur de progression
    showDialog(
      context: context,
        barrierDismissible: false,
      builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                ),
                SizedBox(width: 20),
                Text('Booking your appointment...'),
              ],
            ),
        );
      },
    );

      // Récupérer les informations de l'utilisateur connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Créer l'objet Appointment
      final appointment = Appointment(
        id: '', // Sera généré par Firestore
        patientId: user.uid,
        patientName: user.displayName ?? 'Unknown',
        patientEmail: user.email ?? '',
        patientPhone: '', // Peut être ajouté plus tard
        hospitalName: widget.hospitalName,
        hospitalImage: widget.hospitalImage,
        hospitalLocation: widget.hospitalLocation,
        department: selectedDepartment!,
        appointmentDate: selectedDate!,
        appointmentTime: selectedTime!,
        symptoms: symptoms.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Sauvegarder dans Firebase
      await AppointmentService.createAppointment(appointment);

      // Fermer le dialogue de progression
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher un message de succès
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Rediriger vers la page des rendez-vous au lieu de la page d'accueil
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const AppointmentsPage(),
          ),
        );
      }

    } catch (e) {
      // Fermer le dialogue de progression
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Afficher un message d'erreur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
              // Header Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'User',
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
              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre de la page aligné à gauche avec flèche retour
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(0xFF159BBD)),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            const Text(
                              'Book Your Appointment',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF159BBD),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Hospital Info Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: _buildHospitalImage(),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  widget.hospitalName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF159BBD),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Hospital Information Section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Location
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Color(0xFF159BBD),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.hospitalLocation,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Available Hours
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: Color(0xFF159BBD),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Available Hours: 24/7',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Available Services
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.medical_services,
                                          color: Color(0xFF159BBD),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Available Services:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: 4,
                                                runSpacing: 4,
                                                children: widget.hospitalFacilities.map((facility) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF159BBD).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      facility,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF159BBD),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Department Selection
                              Text(
                                'Select Department',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonFormField<String>(
                                    value: selectedDepartment,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    prefixIcon: Icon(Icons.medical_services, color: Color(0xFF159BBD)),
                                  ),
                                  hint: const Text('Choose a department'),
                                  items: widget.hospitalFacilities.isEmpty 
                                      ? ['General Care'].map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList()
                                      : widget.hospitalFacilities.map((String facility) {
                                      return DropdownMenuItem<String>(
                                            value: facility,
                                            child: Text(facility),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                        setState(() {
                                          selectedDepartment = newValue;
                                        });
                                    },
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Date and Time Selection
                              Text(
                                'Select Date & Time',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              // Date Selection
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, color: Color(0xFF159BBD)),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Available Dates',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (availableDays.isEmpty)
                                      Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange[200]!),
                                  ),
                                  child: Row(
                                          children: [
                                            Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'No schedule available. Please contact the hospital for availability.',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 100,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _getAvailableDates().length,
                                          itemBuilder: (context, index) {
                                            final dateStr = _getAvailableDates()[index];
                                            final date = DateTime.parse(dateStr);
                                            final dayName = DateFormat('EEEE').format(date);
                                            final isSelected = selectedDate?.year == date.year &&
                                                             selectedDate?.month == date.month &&
                                                             selectedDate?.day == date.day;
                                            
                                            return GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedDate = date;
                                                  selectedTime = null; // Reset time when date changes
                                                });
                                              },
                                              child: Container(
                                                width: 80,
                                                margin: const EdgeInsets.only(right: 8),
                                                decoration: BoxDecoration(
                                                  color: isSelected ? const Color(0xFF159BBD) : Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected ? const Color(0xFF159BBD) : Colors.grey[300]!,
                                                  ),
                                                  boxShadow: isSelected ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF159BBD).withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ] : null,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                                      DateFormat('MMM').format(date),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: isSelected ? Colors.white : Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      date.day.toString(),
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSelected ? Colors.white : Colors.grey[800],
                                                      ),
                                                    ),
                                                    Text(
                                                      dayName.substring(0, 3),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isSelected ? Colors.white70 : Colors.grey[500],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Time Selection
                              if (selectedDate != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, color: Color(0xFF159BBD)),
                                          const SizedBox(width: 8),
                                      Text(
                                            'Available Times',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Builder(
                                        builder: (context) {
                                          final dayName = DateFormat('EEEE').format(selectedDate!);
                                          final timeSlots = dayTimeSlots[dayName] ?? [];
                                          
                                          if (timeSlots.isEmpty) {
                                            return Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.orange[50],
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.orange[200]!),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'No time slots available for this day.',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.orange[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          
                                          return Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: timeSlots.map((time) {
                                              final isSelected = selectedTime == time;
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    selectedTime = time;
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? const Color(0xFF159BBD) : Colors.white,
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: isSelected ? const Color(0xFF159BBD) : Colors.grey[300]!,
                                                    ),
                                                    boxShadow: isSelected ? [
                                                      BoxShadow(
                                                        color: const Color(0xFF159BBD).withOpacity(0.3),
                                                        blurRadius: 4,
                                                        offset: const Offset(0, 1),
                                                      ),
                                                    ] : null,
                                                  ),
                                                  child: Text(
                                                    _formatTimeForDisplay(time),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: isSelected ? Colors.white : Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Reason for Booking
                              Text(
                                'Symptoms',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _symptomsController,
                                onChanged: (value) {
                                  setState(() {
                                    symptoms = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter your symptoms',
                                  prefixIcon: const Icon(Icons.medical_services_outlined, color: Color(0xFF159BBD)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Color(0xFF159BBD)),
                                  ),
                                ),
                                maxLines: 3,
                              ),
                              const SizedBox(height: 24),
                              // Book Appointment Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _bookAppointment,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF159BBD),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Confirm Booking',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF159BBD),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHospitalImage() {
    if (widget.hospitalImage.isNotEmpty) {
      // Check if it's a base64 image (starts with data:image)
      if (widget.hospitalImage.startsWith('data:image')) {
        // Base64 image from Firestore
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.memory(
            base64Decode(widget.hospitalImage.split(',')[1]),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      }
      // Check if it's a network URL
      else if (widget.hospitalImage.startsWith('http')) {
        // Network image
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(
            widget.hospitalImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
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
          ),
        );
      } else if (widget.hospitalImage.startsWith('assets/')) {
        // Asset image
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            widget.hospitalImage,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      } else {
        // Local file path
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.file(
            File(widget.hospitalImage),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      }
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF159BBD).withOpacity(0.1),
            const Color(0xFF0D5C73).withOpacity(0.05),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF159BBD).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital,
                size: 48,
                color: Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Healthcare Facility',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF159BBD).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Professional Medical Care',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF159BBD).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 