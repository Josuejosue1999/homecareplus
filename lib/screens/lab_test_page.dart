import 'package:flutter/material.dart';

class LabTestPage extends StatefulWidget {
  const LabTestPage({Key? key}) : super(key: key);

  @override
  State<LabTestPage> createState() => _LabTestPageState();
}

class _LabTestPageState extends State<LabTestPage> {
  final List<String> _testCategories = [
    'Blood Tests',
    'Urine Tests',
    'X-Ray',
    'MRI',
    'CT Scan',
    'Ultrasound',
  ];

  final List<Map<String, dynamic>> _hospitals = [
    {
      'name': 'Central Medical Center',
      'address': '123 Main Street, City',
      'rating': 4.8,
      'distance': '2.5 km',
      'image': 'assets/images/hospital1.jpg',
    },
    {
      'name': 'City General Hospital',
      'address': '456 Health Avenue, City',
      'rating': 4.6,
      'distance': '3.8 km',
      'image': 'assets/images/hospital2.jpg',
    },
    {
      'name': 'Metro Health Institute',
      'address': '789 Care Road, City',
      'rating': 4.7,
      'distance': '4.2 km',
      'image': 'assets/images/hospital3.jpg',
    },
  ];

  String? _selectedCategory;
  String? _selectedHospital;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Book Lab Test',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
                        // Test Categories
                        const Text(
                          'Select Test Category',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF159BBD),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
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
                          child: Column(
                            children: _testCategories.map((category) {
                              return RadioListTile<String>(
                                title: Text(category),
                                value: category,
                                groupValue: _selectedCategory,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                                activeColor: const Color(0xFF159BBD),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Hospital Selection
                        const Text(
                          'Select Hospital',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF159BBD),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
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
                          child: Column(
                            children: _hospitals.map((hospital) {
                              return RadioListTile<String>(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hospital['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hospital['distance'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          hospital['rating'].toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                value: hospital['name'],
                                groupValue: _selectedHospital,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedHospital = value;
                                  });
                                },
                                activeColor: const Color(0xFF159BBD),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Date Selection
                        const Text(
                          'Select Date',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF159BBD),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
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
                          child: ListTile(
                            leading: const Icon(Icons.calendar_today, color: Color(0xFF159BBD)),
                            title: Text(
                              _selectedDate == null
                                  ? 'Select a date'
                                  : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            ),
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Time Selection
                        const Text(
                          'Select Time',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF159BBD),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
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
                          child: ListTile(
                            leading: const Icon(Icons.access_time, color: Color(0xFF159BBD)),
                            title: Text(
                              _selectedTime == null
                                  ? 'Select a time'
                                  : _selectedTime!.format(context),
                            ),
                            onTap: () async {
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedTime = picked;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Additional Notes
                        const Text(
                          'Additional Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF159BBD),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(
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
                          child: TextField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Enter any additional notes or requirements...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Book Button
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_selectedCategory == null ||
                                  _selectedHospital == null ||
                                  _selectedDate == null ||
                                  _selectedTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please fill in all required fields'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              // TODO: Implement booking logic
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test booked successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF159BBD),
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Book Test',
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 