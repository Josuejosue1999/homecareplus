import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homecare_app/screens/login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

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
  String? profileImageUrl;
  bool isLoading = true;
  File? _profileImageFile;

  // Controllers pour les champs éditables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  // État d'édition pour chaque champ
  Map<String, bool> _editing = {
    'name': false,
    'email': false,
    'phone': false,
    'address': false,
    'about': false,
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

  @override
  void initState() {
    super.initState();
    _loadClinicData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadClinicData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final clinicData = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(user.uid)
            .get();

        if (clinicData.exists) {
          final data = clinicData.data() ?? {};
          setState(() {
            clinicName = data['name'] ?? '';
            clinicEmail = data['email'] ?? '';
            clinicPhone = data['phone'] ?? '';
            clinicAddress = data['address'] ?? '';
            clinicAbout = data['about'] ?? '';
            profileImageUrl = data['profileImageUrl'];
            isLoading = false;
          });

          // Initialiser les controllers
          _nameController.text = clinicName;
          _emailController.text = clinicEmail;
          _phoneController.text = clinicPhone;
          _addressController.text = clinicAddress;
          _aboutController.text = clinicAbout;
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
      
      await _loadSavedProfileImage();
      
    } catch (e) {
      print('Error loading clinic data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadSavedProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileImagePath = prefs.getString('clinic_profile_image_path');

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        final profileFile = File(profileImagePath);
        if (await profileFile.exists()) {
          setState(() {
            profileImageUrl = profileImagePath;
            _profileImageFile = null;
          });
          await _syncImageToFirestore(profileImagePath);
        } else {
          await prefs.remove('clinic_profile_image_path');
        }
      }
    } catch (e) {
      print('Error loading saved profile image: $e');
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

        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'clinic_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${appDir.path}/$fileName';
        
        await imageFile.copy(savedPath);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('clinic_profile_image_path', savedPath);

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

    await _saveField('address', fullAddress);
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error signing out: $e');
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
                        _addressController.text = clinicAddress;
                        _selectedSector = '';
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