import 'package:flutter/material.dart';
import 'package:homecare_plus/services/enhanced_hospital_service.dart';
import 'package:homecare_plus/models/hospital.dart';
import 'package:homecare_plus/screens/hospital_details.dart';
import 'package:homecare_plus/screens/booking_hub_page.dart';

class HealthcareProvidersPage extends StatefulWidget {
  const HealthcareProvidersPage({Key? key}) : super(key: key);

  @override
  State<HealthcareProvidersPage> createState() => _HealthcareProvidersPageState();
}

class _HealthcareProvidersPageState extends State<HealthcareProvidersPage> 
    with TickerProviderStateMixin {
  List<Hospital> allHospitals = [];
  List<Hospital> filteredHospitals = [];
  List<Hospital> verifiedHospitals = [];
  List<Hospital> googleHospitals = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'all'; // 'all', 'verified', 'google'

  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadHospitals();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitals() async {
    try {
      final hospitalStream = EnhancedHospitalService.getNearbyHospitals();
      
      await for (final hospitals in hospitalStream) {
        if (mounted) {
          setState(() {
            allHospitals = hospitals;
            
            // Séparer les hôpitaux vérifiés et Google
            verifiedHospitals = hospitals
                .where((hospital) => hospital.existsInFirebase && hospital.verified)
                .toList();
            
            googleHospitals = hospitals
                .where((hospital) => hospital.isFromGooglePlaces)
                .toList();
            
            _applyFilters();
            isLoading = false;
          });
        }
        break;
      }
    } catch (e) {
      print('Error loading hospitals: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Hospital> baseList;
    
    switch (selectedFilter) {
      case 'verified':
        baseList = verifiedHospitals;
        break;
      case 'google':
        baseList = googleHospitals;
        break;
      default:
        baseList = allHospitals;
    }
    
    if (searchQuery.isEmpty) {
      filteredHospitals = baseList;
    } else {
      filteredHospitals = baseList
          .where((hospital) => 
              hospital.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (hospital.location?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
              hospital.facilities.any((facility) => 
                  facility.toLowerCase().contains(searchQuery.toLowerCase())))
          .toList();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      _applyFilters();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      selectedFilter = filter;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Healthcare Providers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF159BBD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadHospitals,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header avec statistiques
            Container(
              color: const Color(0xFF159BBD),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques
                    Row(
                      children: [
                        _buildStatCard('Total', allHospitals.length, Icons.local_hospital_rounded),
                        const SizedBox(width: 12),
                        _buildStatCard('Verified', verifiedHospitals.length, Icons.verified_rounded),
                        const SizedBox(width: 12),
                        _buildStatCard('Google', googleHospitals.length, Icons.map_rounded),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Barre de recherche
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    
                    // Filtres
                    _buildFilterChips(),
                  ],
                ),
              ),
            ),
            
            // Liste des hôpitaux
            Expanded(
              child: isLoading
                  ? _buildLoadingView()
                  : filteredHospitals.isEmpty
                      ? _buildEmptyView()
                      : _buildHospitalsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF159BBD), size: 20),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search hospitals, locations, or services...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[400],
            size: 24,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Colors.grey,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _buildFilterChip('All', 'all', allHospitals.length),
        const SizedBox(width: 8),
        _buildFilterChip('Verified', 'verified', verifiedHospitals.length),
        const SizedBox(width: 8),
        _buildFilterChip('Google', 'google', googleHospitals.length),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = selectedFilter == value;
    return GestureDetector(
      onTap: () => _onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF159BBD) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF159BBD) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading healthcare providers...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No healthcare providers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredHospitals.length,
      itemBuilder: (context, index) {
        final hospital = filteredHospitals[index];
        return _buildHospitalCard(hospital);
      },
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HospitalDetailsPage(
                  hospitalName: hospital.name,
                  hospitalImage: hospital.profileImageUrl ?? 'assets/hospital.PNG',
                  address: hospital.location ?? 'Address not available',
                  facilities: hospital.facilities,
                  rating: hospital.displayRating,
                  reviewCount: hospital.displayRatingCount,
                  reviews: [],
                  aboutText: hospital.about ?? 'Healthcare facility information not available.',
                  hospitalSchedule: hospital.availableSchedule,
                  supportsBooking: hospital.supportsBooking,
                  isFromGooglePlaces: hospital.isFromGooglePlaces,
                  placeId: hospital.placeId,
                  isVerified: hospital.verified || hospital.isVerified,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image de profil
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: hospital.profileImageUrl != null && hospital.profileImageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(hospital.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: hospital.profileImageUrl == null || hospital.profileImageUrl!.isEmpty
                        ? const Color(0xFF159BBD).withOpacity(0.1)
                        : null,
                  ),
                  child: hospital.profileImageUrl == null || hospital.profileImageUrl!.isEmpty
                      ? const Icon(
                          Icons.local_hospital_rounded,
                          color: Color(0xFF159BBD),
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom et badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hospital.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          ),
                          if (hospital.verified || hospital.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 12,
                                    color: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'VERIFIED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (hospital.isFromGooglePlaces)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.map_rounded,
                                    size: 12,
                                    color: Color(0xFFEA580C),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'GOOGLE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Localisation
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hospital.location ?? 'Location not available',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Note et services
                      Row(
                        children: [
                          if (hospital.displayRating > 0) ...[
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${hospital.displayRating.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (hospital.distance != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_walk_rounded,
                                  size: 16,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${hospital.distance!.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      
                      if (hospital.facilities.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          hospital.facilities.take(3).join(' • '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Flèche
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 