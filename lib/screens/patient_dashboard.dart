import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital.dart';
import '../services/hospital_service.dart';
import 'facilities.dart';
import 'choose.dart';
import 'hospital_details.dart';
import 'dart:io';
import 'dart:convert';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(
            children: [
              // Header with Back Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF159BBD),
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF159BBD)),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ChoosePage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Patient Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
              child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                  controller: _searchController,
                        decoration: InputDecoration(
                    hintText: 'Search for hospitals...',
                          border: InputBorder.none,
                          icon: const Icon(Icons.search, color: Color(0xFF159BBD)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.filter_list, color: Color(0xFF159BBD)),
                            onPressed: () {},
                          ),
                        ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
            ),

            // Hospitals List
            Expanded(
              child: StreamBuilder<List<Hospital>>(
                stream: searchQuery.isEmpty 
                    ? HospitalService.getHospitals()
                    : HospitalService.searchHospitals(searchQuery),
                builder: (context, snapshot) {
                  print('StreamBuilder state: ${snapshot.connectionState}');
                  print('StreamBuilder hasError: ${snapshot.hasError}');
                  print('StreamBuilder error: ${snapshot.error}');
                  print('StreamBuilder hasData: ${snapshot.hasData}');
                  print('StreamBuilder data length: ${snapshot.data?.length}');
                  
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    print('StreamBuilder error details: ${snapshot.error}');
                    // Try to fetch data once as a fallback
                    return FutureBuilder<List<Hospital>>(
                      future: _fetchHospitalsOnce(),
                      builder: (context, futureSnapshot) {
                        if (futureSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                            ),
                          );
                        }
                        
                        if (futureSnapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                          Text(
                                  'Error loading hospitals',
                            style: TextStyle(
                              fontSize: 18,
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
                    ),
                    const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      // Force rebuild
                                    });
                                  },
                                  child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                          );
                        }
                        
                        final hospitals = futureSnapshot.data ?? [];
                        return _buildHospitalsList(hospitals);
                      },
                    );
                  }

                  final hospitals = snapshot.data ?? [];
                  print('Final hospitals list length: ${hospitals.length}');
                  return _buildHospitalsList(hospitals);
                },
                                              ),
                                            ),
                                          ],
                                        ),
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    // Debug log to see what data we're getting
    print('Building hospital card for: ${hospital.name}');
    print('Profile image URL: ${hospital.profileImageUrl}');
    print('Has profile image: ${hospital.profileImageUrl != null && hospital.profileImageUrl!.isNotEmpty}');
    
    return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HospitalDetailsPage(
                                                    hospitalName: hospital.name,
                                                    hospitalImage: hospital.profileImageUrl ?? 'assets/hospital.PNG',
                                                    address: hospital.location ?? 'Address not available',
                                                    facilities: hospital.facilities.isNotEmpty 
                                                        ? hospital.facilities 
                                                        : ['General Care', 'Consultation'],
                                                    rating: 4.5,
                                                    reviewCount: 50,
                                                    aboutText: hospital.about ?? 'This healthcare facility is committed to providing exceptional medical care and services.',
                                                    hospitalSchedule: hospital.availableSchedule,
                                                    reviews: [
                                                      {
                                                        'name': 'John Doe',
                                                        'rating': '4.5',
                                                        'comment': 'Great service and professional staff.',
                                                      },
                                                      {
                                                        'name': 'Jane Smith',
                                                        'rating': '4.3',
                                                        'comment': 'Clean facilities and caring doctors.',
                                                      },
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
      child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
          borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
            // Hospital Image
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: Colors.grey[100],
              ),
              child: _buildHospitalImage(hospital),
            ),

            // Hospital Info
            Padding(
              padding: const EdgeInsets.all(12),
                                    child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                  Text(
                    hospital.name,
                    style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF159BBD),
                                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                  Text(
                    hospital.location ?? 'Location not available',
                                          style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                                        ),
                  const SizedBox(height: 8),
                                        Row(
                                          children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 4),
                                            const Text(
                        '4.5',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                      const SizedBox(width: 4),
                      Text(
                        '(50)',
                                          style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                  const SizedBox(height: 8),
                                        Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                                            child: const Text(
                      'View Details',
                                              style: TextStyle(
                                                color: Colors.white,
                        fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
    );
  }

  Widget _buildHospitalImage(Hospital hospital) {
    // Check if we have a valid profile image URL or local file path
    if (hospital.profileImageUrl != null && hospital.profileImageUrl!.isNotEmpty) {
      
      print('Loading image for ${hospital.name}: ${hospital.profileImageUrl!.substring(0, 50)}...');
      
      // Check if it's a base64 image (starts with data:image)
      if (hospital.profileImageUrl!.startsWith('data:image')) {
        // Base64 image from Firestore
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.memory(
            base64Decode(hospital.profileImageUrl!.split(',')[1]),
                                        fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading base64 image for ${hospital.name}: $error');
              return _buildPlaceholderImage();
            },
          ),
        );
      }
      // Check if it's a network URL
      else if (hospital.profileImageUrl!.startsWith('http')) {
        // Network image
        return ClipRRect(
                                      borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.network(
            hospital.profileImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading network image for ${hospital.name}: $error');
              return _buildPlaceholderImage();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                print('Network image loaded successfully for ${hospital.name}');
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
      } else {
        // Local file path
        return ClipRRect(
                                      borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.file(
            File(hospital.profileImageUrl!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading local image for ${hospital.name}: $error');
              return _buildPlaceholderImage();
            },
          ),
        );
      }
    } else {
      print('No valid image URL for ${hospital.name}, showing placeholder');
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
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
              padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                color: const Color(0xFF159BBD).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_hospital,
                size: 32,
                color: Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Healthcare',
                                              style: TextStyle(
                                                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF159BBD).withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
    );
  }

  Future<List<Hospital>> _fetchHospitalsOnce() async {
    try {
      print('Attempting to fetch hospitals once as fallback...');
      final snapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .orderBy('createdAt', descending: true)
          .get();
      
      print('Fallback fetch: Got ${snapshot.docs.length} hospitals');
      final hospitals = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Fallback processing hospital: ${data['name']}');
        return Hospital.fromFirestore(data, doc.id);
      }).toList();
      
      print('Fallback: Successfully processed ${hospitals.length} hospitals');
      return hospitals;
    } catch (e) {
      print('Fallback fetch error: $e');
      throw e;
    }
  }

  Widget _buildHospitalsList(List<Hospital> hospitals) {
    if (hospitals.isEmpty) {
      return Center(
                              child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
                                children: [
            Icon(
              searchQuery.isEmpty ? Icons.local_hospital_outlined : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty 
                  ? 'No hospitals available'
                  : 'No hospitals found for "$searchQuery"',
                                          style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty 
                  ? 'Hospitals will appear here once they register'
                  : 'Try a different search term',
                                          style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: (hospitals.length / 2).ceil(),
      itemBuilder: (context, index) {
        final startIndex = index * 2;
        final endIndex = (startIndex + 2).clamp(0, hospitals.length);
        final rowHospitals = hospitals.sublist(startIndex, endIndex);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: rowHospitals.map((hospital) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: rowHospitals.indexOf(hospital) == 0 && rowHospitals.length > 1 
                        ? 8.0 
                        : 0.0,
                  ),
                  child: _buildHospitalCard(hospital),
                ),
              );
            }).toList(),
                                                ),
                                              );
                                            },
    );
  }
} 