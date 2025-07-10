import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'all_reviews.dart';
import 'book_appointment.dart';
import 'login.dart';
import '../services/enhanced_hospital_service.dart';

class HospitalDetailsPage extends StatefulWidget {
  final String hospitalName;
  final String hospitalImage;
  final String address;
  final List<String> facilities;
  final double rating;
  final int reviewCount;
  final List<Map<String, String>> reviews;
  final String aboutText;
  final Map<String, Map<String, String>> hospitalSchedule;
  final bool supportsBooking;
  final bool isFromGooglePlaces;
  final String? placeId;

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
    required this.supportsBooking,
    required this.isFromGooglePlaces,
    this.placeId,
  });

  @override
  State<HospitalDetailsPage> createState() => _HospitalDetailsPageState();
}

class _HospitalDetailsPageState extends State<HospitalDetailsPage> {
  List<Map<String, String>> _enhancedFacilities = [];
  List<Map<String, dynamic>> _googlePlacesReviews = [];
  Map<String, dynamic>? _hospitalDetails;
  bool _isLoadingReviews = false;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.isFromGooglePlaces && widget.placeId != null) {
      _loadHospitalDetails();
      _loadGooglePlacesReviews();
    }
  }

  Future<void> _loadHospitalDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      final details = await EnhancedHospitalService.getHospitalDetails(widget.placeId!);
      if (details != null) {
        setState(() {
          _hospitalDetails = details;
          _enhancedFacilities = EnhancedHospitalService.getEnhancedFacilities(details);
        });
      }
    } catch (e) {
      print('Error loading hospital details: $e');
    } finally {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  Future<void> _loadGooglePlacesReviews() async {
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final reviews = await EnhancedHospitalService.getHospitalReviews(widget.placeId!);
      setState(() {
        _googlePlacesReviews = reviews;
      });
    } catch (e) {
      print('Error loading reviews: $e');
    } finally {
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF159BBD),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHospitalImage(),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Hospital Name - Fixed positioning
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 80, // Leave space for rating on the right
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hospitalName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black26,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.white.withOpacity(0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.address,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: const [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Rating Badge - Fixed positioning
                  Positioned(
                    bottom: 30,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Section
                  _buildAboutSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Available Services Section
                  _buildAvailableServicesSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Reviews Section
                  _buildReviewsSection(),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalImage() {
    if (widget.hospitalImage.startsWith('data:image')) {
      // Handle base64 images
      try {
        final bytes = base64Decode(widget.hospitalImage.split(',')[1]);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackImage();
          },
        );
      } catch (e) {
        return _buildFallbackImage();
      }
    } else if (widget.hospitalImage.startsWith('http')) {
      // Handle network images
      return Image.network(
        widget.hospitalImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    } else {
      // Handle asset images
      return Image.asset(
        widget.hospitalImage,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    }
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF159BBD).withOpacity(0.8),
            const Color(0xFF0D7A94).withOpacity(0.8),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.local_hospital,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF159BBD),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.aboutText,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableServicesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Services',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF159BBD),
          ),
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingDetails)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
            ),
          )
        else
          _buildServicesGrid(),
      ],
    );
  }

  Widget _buildServicesGrid() {
    final services = _enhancedFacilities.isNotEmpty ? _enhancedFacilities : _getDefaultServices();
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: services.map((service) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF159BBD).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF159BBD).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconFromString(service['icon']),
                color: const Color(0xFF159BBD),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                service['name']!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF159BBD),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, String>> _getDefaultServices() {
    return widget.facilities.map((facility) => {
      'name': facility,
      'icon': 'medical_services',
    }).toList();
  }

  IconData _getIconFromString(String? iconName) {
    switch (iconName) {
      case 'local_hospital':
        return Icons.local_hospital;
      case 'medical_services':
        return Icons.medical_services;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'emergency':
        return Icons.emergency;
      case 'pets':
        return Icons.pets;
      case 'healing':
        return Icons.healing;
      case 'health_and_safety':
        return Icons.health_and_safety;
      case 'person':
        return Icons.person;
      default:
        return Icons.medical_services;
    }
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Patient Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF159BBD),
              ),
            ),
            if (_googlePlacesReviews.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllReviewsPage(
                        hospitalName: widget.hospitalName,
                        reviews: _googlePlacesReviews,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View All (${_googlePlacesReviews.length})',
                  style: TextStyle(
                    color: const Color(0xFF159BBD),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingReviews)
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
            ),
          )
        else if (_googlePlacesReviews.isEmpty)
          _buildNoReviewsState()
        else
          _buildReviewsList(),
      ],
    );
  }

  Widget _buildNoReviewsState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_border,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No reviews available yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to share your experience',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return Column(
      children: [
        // Overall rating summary
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.amber.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                widget.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'from ${widget.reviewCount} Google reviews',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        
        // Review items (show first 3)
        ...(_googlePlacesReviews.take(3).map((review) => _buildReviewItem(review)).toList()),
      ],
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF159BBD).withOpacity(0.1),
                child: review['profile_photo_url'] != null
                    ? ClipOval(
                        child: Image.network(
                          review['profile_photo_url'],
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 16,
                              color: const Color(0xFF159BBD),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 16,
                        color: const Color(0xFF159BBD),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['author_name'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (review['rating'] ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          review['relative_time_description'] ?? 'Recent',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review['text'] != null && review['text'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review['text'],
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action button
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.supportsBooking
                ? const LinearGradient(
                    colors: [Color(0xFF159BBD), Color(0xFF0D7A94)],
                  )
                : null,
            color: widget.supportsBooking ? null : Colors.grey[400],
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.supportsBooking
                ? [
                    BoxShadow(
                      color: const Color(0xFF159BBD).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.supportsBooking
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookAppointmentPage(
                            hospitalName: widget.hospitalName,
                            hospitalImage: widget.hospitalImage,
                            hospitalLocation: widget.address,
                            hospitalFacilities: widget.facilities,
                            hospitalAbout: widget.aboutText,
                            hospitalSchedule: widget.hospitalSchedule,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Center(
                child: Text(
                  widget.supportsBooking ? 'Book Appointment' : 'View Details Only',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Info message for Google Places hospitals
        if (widget.isFromGooglePlaces)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This hospital is from Google Places. Contact them directly to book appointments.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
} 