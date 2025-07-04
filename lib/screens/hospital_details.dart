import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'all_reviews.dart';
import 'book_appointment.dart';
import 'login.dart';

class HospitalDetailsPage extends StatelessWidget {
  final String hospitalName;
  final String hospitalImage;
  final String address;
  final List<String> facilities;
  final double rating;
  final int reviewCount;
  final List<Map<String, String>> reviews;
  final String aboutText;
  final Map<String, Map<String, String>> hospitalSchedule;

  const HospitalDetailsPage({
    super.key,
    required this.hospitalName,
    required this.hospitalImage,
    required this.address,
    required this.facilities,
    required this.rating,
    required this.reviewCount,
    required this.reviews,
    required this.aboutText,
    required this.hospitalSchedule,
  });

  // Méthode pour déterminer si c'est un nouvel hôpital
  bool get isNewHospital {
    return address == 'Address to be updated' || 
           address == 'Location to be updated' ||
           address.isEmpty ||
           aboutText.isEmpty ||
           aboutText.contains('healthcare facility committed to providing exceptional medical care');
  }

  // Méthode pour obtenir l'adresse formatée
  String get formattedAddress {
    if (isNewHospital) {
      return '📍 Location information not available';
    }
    return address;
  }

  // Méthode pour obtenir le texte "About" amélioré
  String get enhancedAboutText {
    if (isNewHospital) {
      return 'Information about this healthcare facility will be updated soon.';
    }
    return aboutText;
  }

  // Méthode pour obtenir les installations par défaut
  List<String> get enhancedFacilities {
    if (isNewHospital) {
      return ['Information not available'];
    }
    return facilities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHospitalImage(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Badge pour nouvel hôpital
                  if (isNewHospital)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.new_releases, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFF159BBD)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Hospital Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Name and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hospitalName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF159BBD),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF159BBD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFF159BBD),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isNewHospital ? 'N/A' : rating.toString(),
                              style: const TextStyle(
                                color: Color(0xFF159BBD),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isNewHospital ? '(New)' : '($reviewCount)',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Address
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
                          formattedAddress,
                          style: TextStyle(
                            fontSize: 16,
                            color: isNewHospital ? Colors.orange[700] : Colors.grey,
                            fontStyle: isNewHospital ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isNewHospital ? Colors.orange[50] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: isNewHospital ? Border.all(color: Colors.orange[200]!) : null,
                    ),
                    child: Text(
                      enhancedAboutText,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Facilities Section
                  const Text(
                    'Available Facilities',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF159BBD),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: enhancedFacilities.map((facility) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF159BBD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          facility,
                          style: const TextStyle(
                            color: Color(0xFF159BBD),
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Patient Reviews Section - Masqué pour les nouveaux hôpitaux
                  if (!isNewHospital) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Patient Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllReviewsPage(
                                  hospitalName: hospitalName,
                                  reviews: reviews,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'View More',
                            style: TextStyle(
                              color: const Color(0xFF159BBD),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Show only first 3 reviews
                    ...reviews.take(3).map((review) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
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
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: Text(
                                  review['name']?[0].toUpperCase() ?? 'A',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      review['name'] ?? 'Anonymous',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          review['rating'] ?? '0.0',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                review['date'] ?? 'Recently',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review['comment'] ?? 'No comment provided',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    if (reviews.length > 3)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllReviewsPage(
                                  hospitalName: hospitalName,
                                  reviews: reviews,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'View All ${reviews.length} Reviews',
                            style: const TextStyle(
                              color: Color(0xFF159BBD),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ] else ...[
                    // Message pour les nouveaux hôpitaux
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This is a newly registered healthcare facility. Patient reviews will be available once they start serving the community.',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Book Appointment Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF159BBD).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today,
                                        color: Color(0xFF159BBD),
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Book Your Appointment',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Please sign in to book your appointment and access your medical records.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LoginPage(
                                                  selectedHospitalName: hospitalName,
                                                  selectedHospitalImage: hospitalImage,
                                                  selectedHospitalLocation: address,
                                                  selectedHospitalFacilities: facilities,
                                                  selectedHospitalAbout: aboutText,
                                                  selectedHospitalSchedule: hospitalSchedule,
                                                ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF159BBD),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: const Text(
                                            'Continue',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF159BBD),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalImage() {
    if (hospitalImage.isNotEmpty) {
      // Check if it's a base64 image (starts with data:image)
      if (hospitalImage.startsWith('data:image')) {
        // Base64 image from Firestore
        return Image.memory(
          base64Decode(hospitalImage.split(',')[1]),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      }
      // Check if it's a network URL
      else if (hospitalImage.startsWith('http')) {
        // Network image
        return Image.network(
          hospitalImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } else if (hospitalImage.startsWith('assets/')) {
        // Asset image
        return Image.asset(
          hospitalImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      } else {
        // Local file path
        return Image.file(
          File(hospitalImage),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      }
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
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
              child: Icon(
                isNewHospital ? Icons.medical_services : Icons.local_hospital,
                size: 48,
                color: const Color(0xFF159BBD),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hospitalName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF159BBD).withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isNewHospital ? 'New Healthcare Facility' : 'Professional Medical Care',
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