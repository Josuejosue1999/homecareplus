import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homecare_app/screens/login2.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../services/appointment_service.dart';
import '../services/location_service.dart';
import '../services/hospital_service.dart';
import '../models/appointment.dart';

class ClinicProfilePage extends StatefulWidget {
  const ClinicProfilePage({Key? key}) : super(key: key);

  @override
  State<ClinicProfilePage> createState() => _ClinicProfilePageState();
}

class _ClinicProfilePageState extends State<ClinicProfilePage> {
  String clinicName = '';
  String clinicEmail = '';
  String clinicPhone = '';
  String clinicAddress = '';
  String clinicAbout = '';
  List<String> clinicFacilities = [];
  int meetingDuration = 30; // Default appointment duration in minutes
  String? profileImageUrl;
  bool isLoading = true;
  File? _profileImageFile;
  String? _currentUserId; // Pour suivre l'utilisateur actuel

  // Coordonnées géographiques
  double? _latitude;
  double? _longitude;
  bool _isLocationLoading = false;
  String _locationStatus = 'Not set';

  // Controllers pour les champs éditables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  // État d'édition pour chaque champ
  Map<String, bool> _editing = {
    'name': false,
    'email': false,
    'phone': false,
    'address': false,
    'about': false,
    'facilities': false,
    'duration': false,
    'schedule': false,
    'location': false,
  };

  // Constantes pour les quartiers de Kigali
  final List<String> kigaliSectors = [
    'KK (Kacyiru)',
    'KG (Gasabo)',
    'KN (Nyarugenge)',
    'KM (Muhima)',
    'KP (Kicukiro)',
    'KR (Remera)',
    'KY (Nyamirambo)',
    'KC (Kiyovu)',
    'KI (Kimihurura)',
    'KG (Gisozi)',
    'KJ (Gikondo)',
  ];

  String _selectedSector = '';

  // Liste des facilities disponibles
  final List<String> availableFacilities = [
    'General Medicine',
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'Gynecology',
    'Dermatology',
    'Orthopedics',
    'ENT',
    'Dental Care',
    'Laboratory Services',
    'Radiology',
    'Emergency Care',
    'Surgery',
    'Physical Therapy',
    'Mental Health',
    'Nutrition Services',
    'Vaccination',
    'Family Planning',
  ];

  @override
  void initState() {
    super.initState();
    _loadClinicData();
    // Tester automatiquement l'adresse de Test hospital
    _testTestHospitalAddress();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadClinicData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Vérifier si l'utilisateur a changé
        if (_currentUserId != null && _currentUserId != user.uid) {
          // L'utilisateur a changé, nettoyer les données locales
          await _clearLocalProfileData();
        }
        
        final clinicData = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .get();

        if (clinicData.exists) {
          final data = clinicData.data() ?? {};
          final address = data['address'] ?? '';
          
          print('=== LOADING CLINIC DATA ===');
          print('Raw address from Firebase: "$address"');
          
          // Extraire le secteur de l'adresse si elle contient une virgule
          String streetAddress = address;
          String sector = '';
          
          if (address.contains(',')) {
            final parts = address.split(',');
            if (parts.length >= 2) {
              streetAddress = parts[0].trim();
              sector = parts[1].trim();
            }
          }
          
          print('Extracted street address: "$streetAddress"');
          print('Extracted sector: "$sector"');
          
          setState(() {
            clinicName = data['name'] ?? '';
            clinicEmail = data['email'] ?? '';
            clinicPhone = data['phone'] ?? '';
            clinicAddress = address;
            clinicAbout = data['about'] ?? '';
            clinicFacilities = List<String>.from(data['facilities'] ?? []);
            meetingDuration = data['meetingDuration'] ?? 30; // Default 30 minutes
            profileImageUrl = data['profileImageUrl'];
            
            // Charger les coordonnées géographiques
            _latitude = data['latitude']?.toDouble();
            _longitude = data['longitude']?.toDouble();
            _locationStatus = _latitude != null && _longitude != null 
                ? 'Set (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                : 'Not set';
            
            isLoading = false;

            // Initialiser les contrôleurs avec les données chargées
          _nameController.text = clinicName;
          _emailController.text = clinicEmail;
          _phoneController.text = clinicPhone;
            _addressController.text = streetAddress;
          _aboutController.text = clinicAbout;
            _durationController.text = meetingDuration.toString();
            _selectedSector = sector;
          });
          
          print('✓ Clinic data loaded successfully');
          print('Final clinicAddress: "$clinicAddress"');
          print('Final _addressController.text: "${_addressController.text}"');
          print('Final _selectedSector: "$_selectedSector"');
          print('Coordinates: $_latitude, $_longitude');
        } else {
          print('❌ No clinic data found for user: ${user.uid}');
          setState(() {
            isLoading = false;
          });
        }
      }
      
      // Charger l'image de profil depuis Firebase uniquement
      await _loadProfileImageFromFirestore();
      
    } catch (e) {
      print('Error loading clinic data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _clearLocalProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final profileImagePath = prefs.getString('clinic_profile_image_path_${user.uid}');

      // Supprimer l'ancienne image locale si elle existe
      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        final profileFile = File(profileImagePath);
        if (await profileFile.exists()) {
          await profileFile.delete();
        }
      }
      
      // Nettoyer les préférences pour cet utilisateur
      await prefs.remove('clinic_profile_image_path_${user.uid}');
      
      // Nettoyer aussi l'ancienne clé générique pour compatibilité
      await prefs.remove('clinic_profile_image_path');
      
      // Réinitialiser l'état local
          setState(() {
        profileImageUrl = null;
            _profileImageFile = null;
          });
    } catch (e) {
      print('Error clearing local profile data: $e');
    }
  }

  Future<void> _loadProfileImageFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final clinicData = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .get();
        
        if (clinicData.exists) {
          final data = clinicData.data() ?? {};
          final firestoreImageUrl = data['profileImageUrl'];
          
          if (firestoreImageUrl != null && firestoreImageUrl.isNotEmpty) {
            setState(() {
              profileImageUrl = firestoreImageUrl;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading profile image from Firestore: $e');
    }
  }

  Future<void> _syncImageToFirestore(String imagePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .get();
        
        final currentImageUrl = doc.data()?['profileImageUrl'];
        
        if (currentImageUrl != imagePath) {
          final imageFile = File(imagePath);
          if (await imageFile.exists()) {
            final bytes = await imageFile.readAsBytes();
            final extension = imagePath.split('.').last.toLowerCase();
            final base64Image = base64Encode(bytes);
            final imageData = 'data:image/$extension;base64,$base64Image';
            
            await FirebaseFirestore.instance
                .collection('clinics')
                .doc(user.uid)
                .update({
              'profileImageUrl': imageData,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    } catch (e) {
      print('Image sync completed');
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size must be less than 5MB. Please select a smaller image.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'clinic_profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${appDir.path}/$fileName';
        
        await imageFile.copy(savedPath);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('clinic_profile_image_path_${user.uid}', savedPath);

        setState(() {
          profileImageUrl = savedPath;
          _profileImageFile = File(savedPath);
        });

        await _syncImageToFirestore(savedPath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking profile image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating profile image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveField(String field, String value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .update({
          field: value,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        setState(() {
          _editing[field] = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Information updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving field: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving information. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAddress() async {
    final fullAddress = _selectedSector.isNotEmpty
        ? '${_addressController.text}, $_selectedSector'
        : _addressController.text;

    print('=== SAVING CLINIC ADDRESS ===');
    print('Street Address: "${_addressController.text}"');
    print('Selected Sector: "$_selectedSector"');
    print('Full Address: "$fullAddress"');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('User ID: ${user.uid}');
        
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .update({
          'address': fullAddress,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        print('✓ Address saved to Firebase successfully');

        // Vérifier immédiatement si l'adresse a été sauvegardée
        await _verifyAddressSaved(user.uid, fullAddress);

        // Mettre à jour l'état local
        setState(() {
          clinicAddress = fullAddress;
          _editing['address'] = false;
        });

        print('✓ Local state updated');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ No authenticated user found');
      }
    } catch (e) {
      print('❌ Error saving address: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving address. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyAddressSaved(String userId, String expectedAddress) async {
    try {
      print('=== VERIFYING ADDRESS SAVED ===');
      
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(userId)
          .get();

      if (clinicDoc.exists) {
        final data = clinicDoc.data()!;
        final savedAddress = data['address'] ?? '';
        
        print('Expected address: "$expectedAddress"');
        print('Saved address in Firebase: "$savedAddress"');
        
        if (savedAddress == expectedAddress) {
          print('✅ Address verification successful!');
        } else {
          print('❌ Address verification failed!');
          print('Expected: "$expectedAddress"');
          print('Found: "$savedAddress"');
        }
      } else {
        print('❌ Clinic document not found for verification');
      }
    } catch (e) {
      print('❌ Error verifying address: $e');
    }
  }

  // Méthode de test pour vérifier l'adresse de "Test hospital"
  Future<void> _testTestHospitalAddress() async {
    try {
      print('=== TESTING TEST HOSPITAL ADDRESS ===');
      
      // Rechercher l'hôpital "Test hospital" dans Firebase
      final querySnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .where('name', isEqualTo: 'Test hospital')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final testHospitalDoc = querySnapshot.docs.first;
        final data = testHospitalDoc.data();
        
        print('✅ Found Test hospital in Firebase');
        print('Document ID: ${testHospitalDoc.id}');
        print('Hospital Name: ${data['name'] ?? 'N/A'}');
        print('Hospital Address: "${data['address'] ?? 'N/A'}"');
        print('Hospital Email: ${data['email'] ?? 'N/A'}');
        print('Hospital Phone: ${data['phone'] ?? 'N/A'}');
        print('Last Updated: ${data['lastUpdated'] ?? 'N/A'}');
        
        if (data['address'] != null && data['address'].toString().isNotEmpty) {
          print('✅ Test hospital address is saved in Firebase!');
        } else {
          print('❌ Test hospital address is NOT saved in Firebase!');
        }
      } else {
        print('❌ Test hospital not found in Firebase');
        
        // Lister tous les hôpitaux pour debug
        print('=== LISTING ALL HOSPITALS ===');
        final allClinics = await FirebaseFirestore.instance
            .collection('clinics')
            .get();
            
        for (var doc in allClinics.docs) {
          final data = doc.data();
          print('Hospital: ${data['name'] ?? 'N/A'} - Address: "${data['address'] ?? 'N/A'}"');
        }
      }
    } catch (e) {
      print('❌ Error testing Test hospital address: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      // Nettoyer les données locales avant la déconnexion
      await _clearLocalProfileData();
      
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login2Page()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Future<void> _saveFacilities() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .update({
          'facilities': clinicFacilities,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        setState(() {
          _editing['facilities'] = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Facilities updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving facilities: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating facilities: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveDuration() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .update({
          'meetingDuration': meetingDuration,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        setState(() {
          _editing['duration'] = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Meeting duration updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving meeting duration: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating meeting duration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSchedule() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Pour l'instant, on sauvegarde juste la durée des rendez-vous
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .update({
          'meetingDuration': meetingDuration,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        setState(() {
          _editing['schedule'] = false;
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Working schedule updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving schedule: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour détecter automatiquement la localisation
  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isLocationLoading = true;
    });

    try {
      print('=== DETECTING CURRENT LOCATION ===');
      
      final userLocation = await LocationService.getCurrentLocation();
      
      if (userLocation != null) {
        setState(() {
          _latitude = userLocation.latitude;
          _longitude = userLocation.longitude;
          _locationStatus = 'Detected (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})';
          _isLocationLoading = false;
        });
        
        // Sauvegarder les coordonnées dans Firebase
        await _saveCoordinates();
        
        print('✓ Location detected and saved successfully');
      } else {
        setState(() {
          _locationStatus = 'Detection failed';
          _isLocationLoading = false;
        });
        print('❌ Location detection failed');
      }
    } catch (e) {
      print('Error detecting location: $e');
      setState(() {
        _locationStatus = 'Error: $e';
        _isLocationLoading = false;
      });
    }
  }

  // Méthode pour sauvegarder les coordonnées
  Future<void> _saveCoordinates() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _latitude != null && _longitude != null) {
        final success = await HospitalService.updateHospitalCoordinates(
          user.uid,
          _latitude!,
          _longitude!,
        );
        
        if (success) {
          print('✓ Coordinates saved to Firebase');
        } else {
          print('❌ Failed to save coordinates to Firebase');
        }
      }
    } catch (e) {
      print('Error saving coordinates: $e');
    }
  }

  // Méthode pour effacer les coordonnées
  Future<void> _clearCoordinates() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .update({
          'latitude': FieldValue.delete(),
          'longitude': FieldValue.delete(),
          'coordinatesUpdatedAt': FieldValue.delete(),
        });
        
        setState(() {
          _latitude = null;
          _longitude = null;
          _locationStatus = 'Not set';
        });
        
        print('✓ Coordinates cleared successfully');
      }
    } catch (e) {
      print('Error clearing coordinates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header Professionnel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF159BBD).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xFF159BBD),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Health Center Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF159BBD).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Color(0xFF159BBD),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu Principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Section Photo de Profil
                    _buildProfileHeader(),
                    const SizedBox(height: 32),

                    // Section Informations de la Clinique
                    _buildClinicInfoSection(),
                    const SizedBox(height: 24),

                    // Section Paramètres
                    _buildSettingsSection(),
                    const SizedBox(height: 32),

                    // Bouton de Déconnexion
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Photo de Profil
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF159BBD).withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? profileImageUrl!.startsWith('data:image/')
                          ? Image.memory(
                              base64Decode(profileImageUrl!.split(',')[1]),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultProfileImage();
                              },
                            )
                          : profileImageUrl!.startsWith('http')
                              ? Image.network(
                                  profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultProfileImage();
                                  },
                                )
                              : File(profileImageUrl!).existsSync()
                      ? Image.file(
                          File(profileImageUrl!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                                        return _buildDefaultProfileImage();
                          },
                        )
                                  : _buildDefaultProfileImage()
                      : _buildDefaultProfileImage(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF159BBD),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF159BBD).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Informations de la Clinique
          Text(
            clinicName.isNotEmpty ? clinicName : 'Clinic Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            clinicEmail.isNotEmpty ? clinicEmail : 'clinic@example.com',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF159BBD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: Color(0xFF159BBD),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Clinic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoField('Clinic Name', _nameController, 'name', Icons.business_outlined),
          const SizedBox(height: 16),
          _buildInfoField('Email Address', _emailController, 'email', Icons.email_outlined),
          const SizedBox(height: 16),
          _buildInfoField('Phone Number', _phoneController, 'phone', Icons.phone_outlined),
          const SizedBox(height: 16),
          _buildAddressField(),
          const SizedBox(height: 16),
          _buildAboutField(),
          const SizedBox(height: 16),
          _buildFacilitiesField(),
          const SizedBox(height: 16),
          _buildLocationField(),
          const SizedBox(height: 16),
          _buildDurationField(),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller, String field, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            if (!_editing[field]!)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _editing[field] = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF159BBD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF159BBD),
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editing[field]!)
          Column(
            children: [
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF159BBD), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editing[field] = false;
                        switch (field) {
                          case 'name':
                            controller.text = clinicName;
                            break;
                          case 'email':
                            controller.text = clinicEmail;
                            break;
                          case 'phone':
                            controller.text = clinicPhone;
                            break;
                          case 'about':
                            controller.text = clinicAbout;
                            break;
                        }
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _saveField(field, controller.text);
                      switch (field) {
                        case 'name':
                          clinicName = controller.text;
                          break;
                        case 'email':
                          clinicEmail = controller.text;
                          break;
                        case 'phone':
                          clinicPhone = controller.text;
                          break;
                        case 'about':
                          clinicAbout = controller.text;
                          break;
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF159BBD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              controller.text.isNotEmpty ? controller.text : 'Not specified',
              style: TextStyle(
                fontSize: 16,
                color: controller.text.isNotEmpty ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                fontWeight: controller.text.isNotEmpty ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 16),
            const SizedBox(width: 8),
            const Text(
              'Address',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            if (!_editing['address']!)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _editing['address'] = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF159BBD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF159BBD),
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editing['address']!)
          Column(
            children: [
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF159BBD), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSector.isNotEmpty ? _selectedSector : null,
                decoration: InputDecoration(
                  labelText: 'Sector',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF159BBD), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                items: kigaliSectors.map((String sector) {
                  return DropdownMenuItem<String>(
                    value: sector,
                    child: Text(sector),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedSector = newValue ?? '';
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editing['address'] = false;
                        // Restaurer les valeurs originales
                        if (clinicAddress.contains(',')) {
                          final parts = clinicAddress.split(',');
                          if (parts.length >= 2) {
                            _addressController.text = parts[0].trim();
                            _selectedSector = parts[1].trim();
                          } else {
                        _addressController.text = clinicAddress;
                        _selectedSector = '';
                          }
                        } else {
                          _addressController.text = clinicAddress;
                          _selectedSector = '';
                        }
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF159BBD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              clinicAddress.isNotEmpty ? clinicAddress : 'Not specified',
              style: TextStyle(
                fontSize: 16,
                color: clinicAddress.isNotEmpty ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                fontWeight: clinicAddress.isNotEmpty ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAboutField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF64748B), size: 16),
            const SizedBox(width: 8),
            const Text(
              'About Clinic',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            if (!_editing['about']!)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _editing['about'] = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF159BBD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF159BBD),
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editing['about']!)
          Column(
            children: [
              TextFormField(
                controller: _aboutController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe your clinic...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF159BBD), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editing['about'] = false;
                        _aboutController.text = clinicAbout;
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      _saveField('about', _aboutController.text);
                      clinicAbout = _aboutController.text;
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF159BBD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              clinicAbout.isNotEmpty ? clinicAbout : 'No description available',
              style: TextStyle(
                fontSize: 16,
                color: clinicAbout.isNotEmpty ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                fontWeight: clinicAbout.isNotEmpty ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFacilitiesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medical_services_outlined, color: Color(0xFF64748B), size: 16),
            const SizedBox(width: 8),
            const Text(
              'Facilities & Services',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            if (!_editing['facilities']!)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _editing['facilities'] = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF159BBD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF159BBD),
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editing['facilities']!)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select available facilities:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableFacilities.map((facility) {
                        final isSelected = clinicFacilities.contains(facility);
                        return FilterChip(
                          label: Text(facility),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (!clinicFacilities.contains(facility)) {
                                  clinicFacilities.add(facility);
                                }
                              } else {
                                clinicFacilities.remove(facility);
                              }
                            });
                          },
                          selectedColor: const Color(0xFF159BBD).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF159BBD),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF159BBD) : Colors.grey[300]!,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editing['facilities'] = false;
                        // Restaurer les facilities originales depuis Firebase
                        _loadClinicData();
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveFacilities,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF159BBD),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: clinicFacilities.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: clinicFacilities.map((facility) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF159BBD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF159BBD).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          facility,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF159BBD),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const Text(
                    'No facilities specified',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.my_location, color: Color(0xFF64748B), size: 16),
            const SizedBox(width: 8),
            const Text(
              'Location Coordinates',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            if (!_editing['location']!)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _editing['location'] = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF159BBD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF159BBD),
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editing['location']!)
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _latitude != null && _longitude != null 
                              ? Colors.green[600] 
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationStatus,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _latitude != null && _longitude != null 
                                  ? Colors.green[600] 
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLocationLoading ? null : _detectCurrentLocation,
                            icon: _isLocationLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.my_location, size: 16),
                            label: Text(_isLocationLoading ? 'Detecting...' : 'Detect Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF159BBD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_latitude != null && _longitude != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _clearCoordinates,
                              icon: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[600],
                                side: BorderSide(color: Colors.red[300]!),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Coordinates Set',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Latitude: ${_latitude!.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[700],
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'Longitude: ${_longitude!.toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green[700],
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _editing['location'] = false;
                      });
                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  _latitude != null && _longitude != null 
                      ? Icons.location_on 
                      : Icons.location_off,
                  color: _latitude != null && _longitude != null 
                      ? Colors.green[600] 
                      : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _latitude != null && _longitude != null 
                            ? 'Location Set' 
                            : 'Location Not Set',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _latitude != null && _longitude != null 
                              ? Colors.green[600] 
                              : Colors.grey[600],
                        ),
                      ),
                      if (_latitude != null && _longitude != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDurationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, color: Color(0xFF64748B), size: 16),
            const SizedBox(width: 8),
            const Text(
              'Default Meeting Duration',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const Spacer(),
            if (!_editing['duration']!)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _editing['duration'] = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF159BBD).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 14,
                    color: Color(0xFF159BBD),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_editing['duration']!)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: meetingDuration,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [15, 30, 45, 60, 90, 120].map((duration) {
                    return DropdownMenuItem(
                      value: duration,
                      child: Text('$duration minutes'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      meetingDuration = value ?? 30;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveDuration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF159BBD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Save'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _editing['duration'] = false;
                    meetingDuration = 30; // Reset to default
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Cancel'),
              ),
            ],
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              '$meetingDuration minutes',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF159BBD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF159BBD),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingItem(
            Icons.notifications_outlined,
            'Notifications',
            'Manage your notification preferences',
            () {},
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            Icons.language_outlined,
            'Language',
            'Change app language',
            () {},
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            Icons.security_outlined,
            'Privacy & Security',
            'Manage your privacy settings',
            () {},
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            Icons.help_outline,
            'Help & Support',
            'Get help and contact support',
            () {},
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            Icons.location_on_outlined,
            'Test Hospital Address',
            'Check if Test hospital address is saved in Firebase',
            _testTestHospitalAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF159BBD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF159BBD), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF94A3B8),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF159BBD), Color(0xFF0D5C73)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF159BBD).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _signOut,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultProfileImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF159BBD).withOpacity(0.1),
            const Color(0xFF0D5C73).withOpacity(0.1),
          ],
        ),
      ),
      child: const Icon(
        Icons.local_hospital,
        size: 60,
        color: Color(0xFF159BBD),
      ),
    );
  }
} 