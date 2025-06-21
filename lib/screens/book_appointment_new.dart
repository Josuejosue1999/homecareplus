import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'login.dart';
import 'package:homecare_app/screens/profile_page.dart';
import 'package:homecare_app/screens/chat_page.dart';
import 'package:homecare_app/screens/appointments_page.dart';

class BookAppointmentPage extends StatefulWidget {
  final String hospitalName;
  final String hospitalImage;
  final String hospitalLocation;
  final List<String> hospitalFacilities;
  final String hospitalAbout;

  const BookAppointmentPage({
    Key? key,
    required this.hospitalName,
    required this.hospitalImage,
    required this.hospitalLocation,
    required this.hospitalFacilities,
    required this.hospitalAbout,
  }) : super(key: key);

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedDepartment = 'General Medicine';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  int _selectedIndex = 0;
  String userName = 'User';
  String greeting = '';

  final List<String> departments = [
    'General Medicine',
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'Gynecology',
    'Dermatology',
    'Orthopedics',
    'ENT',
  ];

  @override
  void initState() {
    super.initState();
    _updateGreeting();
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pop(context);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AppointmentsPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.hospitalName,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF159BBD),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF159BBD).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Color(0xFF159BBD),
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '4.8',
                                          style: TextStyle(
                                            color: Color(0xFF159BBD),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: _buildHospitalImage(),
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
                              const Text(
                                'Book Your Appointment',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF159BBD),
                                ),
                              ),
                              const SizedBox(height: 15),
                              // Date Selection
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Color(0xFF159BBD),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Select Date',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF159BBD),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF159BBD),
                                        size: 16,
                                      ),
                                      onPressed: () async {
                                        final DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: selectedDate,
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null && picked != selectedDate) {
                                          setState(() {
                                            selectedDate = picked;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              // Time Selection
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      color: Color(0xFF159BBD),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Select Time',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF159BBD),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF159BBD),
                                        size: 16,
                                      ),
                                      onPressed: () async {
                                        final TimeOfDay? picked = await showTimePicker(
                                          context: context,
                                          initialTime: selectedTime,
                                        );
                                        if (picked != null && picked != selectedTime) {
                                          setState(() {
                                            selectedTime = picked;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),
                              // Department Selection
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.medical_services,
                                      color: Color(0xFF159BBD),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Department',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF159BBD),
                                      ),
                                    ),
                                    const Spacer(),
                                    DropdownButton<String>(
                                      value: selectedDepartment,
                                      icon: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF159BBD),
                                        size: 16,
                                      ),
                                      underline: Container(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            selectedDepartment = newValue;
                                          });
                                        }
                                      },
                                      items: departments.map<DropdownMenuItem<String>>((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: const TextStyle(
                                              color: Color(0xFF159BBD),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Personal Information
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF159BBD),
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  prefixIcon: const Icon(Icons.person, color: Color(0xFF159BBD)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF159BBD)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF159BBD)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF159BBD)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email, color: Color(0xFF159BBD)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF159BBD)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _reasonController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Reason for Visit',
                                  prefixIcon: const Icon(Icons.note, color: Color(0xFF159BBD)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF159BBD)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement booking logic
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF159BBD),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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