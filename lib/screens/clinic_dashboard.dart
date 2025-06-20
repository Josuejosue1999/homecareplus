import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:homecare_app/screens/login.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homecare_app/widgets/professional_bottom_nav.dart';

class ClinicDashboardPage extends StatefulWidget {
  const ClinicDashboardPage({Key? key}) : super(key: key);

  @override
  State<ClinicDashboardPage> createState() => _ClinicDashboardPageState();
}

class _ClinicDashboardPageState extends State<ClinicDashboardPage> {
  int _selectedIndex = 0;
  String clinicName = 'Clinic';
  String greeting = '';

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _fetchClinicName();
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

  Future<void> _fetchClinicName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('clinics').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          clinicName = doc.data()?['name'] ?? 'Clinic';
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home page
        break;
      case 1:
        // Navigate to appointments page
        break;
      case 2:
        // Navigate to chat page
        break;
      case 3:
        // Navigate to profile page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ClinicProfilePage()),
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
                          clinicName,
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
                            MaterialPageRoute(builder: (context) => const ClinicProfilePage()),
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
                        // Quick Actions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF159BBD).withOpacity(0.05),
                                const Color(0xFF0D5C73).withOpacity(0.03),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF159BBD).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF159BBD),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionCard(
                              icon: Icons.calendar_today,
                              title: 'Appointments',
                              onTap: () {
                                // Navigate to appointments page
                              },
                                    textSize: 9,
                            ),
                            _buildActionCard(
                              icon: Icons.message,
                              title: 'Messages',
                              onTap: () {
                                // Navigate to chat page
                              },
                                    textSize: 12,
                            ),
                          ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Upcoming Appointments
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF159BBD).withOpacity(0.1),
                                const Color(0xFF0D5C73).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
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
                                  const Text(
                                    'Upcoming Appointments',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF159BBD),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // TODO: Navigate to all appointments
                                    },
                                    child: const Text(
                                      'See All',
                                      style: TextStyle(
                                        color: Color(0xFF159BBD),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
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
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    _buildAppointmentItem(
                                      patientName: 'John Doe',
                                      specialty: 'Cardiology',
                                      date: DateTime.now().add(const Duration(days: 2)),
                                      time: '10:00 AM',
                                    ),
                                    const Divider(height: 20),
                                    _buildAppointmentItem(
                                      patientName: 'Jane Smith',
                                      specialty: 'Neurology',
                                      date: DateTime.now().add(const Duration(days: 5)),
                                      time: '2:30 PM',
                                    ),
                                  ],
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
      bottomNavigationBar: ProfessionalBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF159BBD),
        selectedColor: Colors.white,
        unselectedColor: Colors.white.withOpacity(0.7),
        items: const [
          BottomNavItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard_rounded, color: Colors.white),
            label: 'Home',
          ),
          BottomNavItem(
            icon: Icon(Icons.event_note_rounded),
            activeIcon: Icon(Icons.event_note_rounded, color: Colors.white),
            label: 'Appointments',
          ),
          BottomNavItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded, color: Colors.white),
            label: 'Chat',
          ),
          BottomNavItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle_rounded, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    double textSize = 12,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 110,
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: const Color(0xFF159BBD),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF159BBD),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem({
    required String patientName,
    required String specialty,
    required DateTime date,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF159BBD).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.calendar_today,
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
                patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF159BBD),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$specialty - ${DateFormat('MMM dd, yyyy').format(date)} at $time',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ClinicProfilePage extends StatefulWidget {
  const ClinicProfilePage({Key? key}) : super(key: key);

  @override
  State<ClinicProfilePage> createState() => _ClinicProfilePageState();
}

class _ClinicProfilePageState extends State<ClinicProfilePage> {
  String clinicName = '';
  String clinicEmail = '';
  String clinicAbout = '';
  String clinicLocation = '';
  List<String> clinicFacilities = [];
  Map<String, Map<String, String>> availableSchedule = {};
  String? profileImageUrl;
  String? certificateUrl;
  bool isLoading = true;
  bool isVerified = false;
  File? _profileImageFile;
  File? _certificateFile;

  // Expansion state for each editable field
  Map<String, bool> _expanded = {
    'name': false,
    'email': false,
    'about': false,
    'location': false,
    'facilities': false,
    'password': false,
    'schedule': false,
  };

  final List<String> weekDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

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

  // Controller pour le champ d'adresse
  final TextEditingController _addressController = TextEditingController();
  String _selectedSector = '';
  String _streetNumber = '';

  @override
  void initState() {
    super.initState();
    _loadClinicData();
    if (clinicLocation.isNotEmpty) {
      _addressController.text = clinicLocation;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
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
            clinicAbout = data['about'] ?? '';
            clinicLocation = data['location'] ?? '';
            clinicFacilities = List<String>.from(data['facilities'] ?? []);
            
            // Corriger le type casting pour availableSchedule
            if (data['availableSchedule'] != null) {
              Map<String, dynamic> scheduleData = data['availableSchedule'];
              availableSchedule = scheduleData.map((key, value) {
                if (value is Map) {
                  return MapEntry(key, Map<String, String>.from(value));
                }
                return MapEntry(key, <String, String>{});
              });
            } else {
              availableSchedule = {};
            }
            
            profileImageUrl = data['profileImageUrl'];
            certificateUrl = data['certificateUrl'];
            isVerified = (certificateUrl != null && certificateUrl!.isNotEmpty);
            isLoading = false;
          });
        }
      }
      
      // Charger les images sauvegardées localement après les données Firestore
      await _loadSavedImages();
      
    } catch (e) {
      print('Error loading clinic data: $e');
      setState(() {
        isLoading = false;
      });
      
      // Même en cas d'erreur, essayer de charger les images locales
      await _loadSavedImages();
    }
  }

  Future<void> _loadSavedImages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileImagePath = prefs.getString('profile_image_path');
      final certificateImagePath = prefs.getString('certificate_image_path');

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        final profileFile = File(profileImagePath);
        if (await profileFile.exists()) {
          setState(() {
            profileImageUrl = profileImagePath;
            _profileImageFile = null;
          });
          print('Profile image loaded from local storage: $profileImagePath');
        } else {
          // Si le fichier n'existe plus, supprimer la référence
          await prefs.remove('profile_image_path');
          print('Profile image file not found, removed from preferences');
        }
      }
      
      if (certificateImagePath != null && certificateImagePath.isNotEmpty) {
        final certificateFile = File(certificateImagePath);
        if (await certificateFile.exists()) {
          setState(() {
            certificateUrl = certificateImagePath;
            _certificateFile = null;
          });
          print('Certificate image loaded from local storage: $certificateImagePath');
        } else {
          // Si le fichier n'existe plus, supprimer la référence
          await prefs.remove('certificate_image_path');
          print('Certificate image file not found, removed from preferences');
        }
      }
    } catch (e) {
      print('Error loading saved images: $e');
    }
  }

  Future<void> _pickImage(bool isProfile) async {
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
        
        // Vérifier la taille du fichier (max 5MB)
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

        // Afficher un indicateur de progression
        if (context.mounted) {
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
              Text('Uploading image...'),
            ],
                ),
              );
            },
          );
        }

        try {
          // Essayer d'abord Firebase Storage
          await _uploadImageToFirebase(imageFile, isProfile);
          
          // Fermer le dialogue de progression
          if (context.mounted) {
            Navigator.of(context).pop();
          }
          
          if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${isProfile ? 'Profile picture' : 'Certificate'} uploaded to Firebase successfully!'),
              backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
            ),
          );
        }
        } catch (firebaseError) {
          print('Firebase upload failed: $firebaseError');

          // Fermer le dialogue de progression
        if (context.mounted) {
          Navigator.of(context).pop();
      }

          // En cas d'échec Firebase, sauvegarder localement
          await _saveImageLocally(imageFile, isProfile);
      
      if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Firebase upload failed. ${isProfile ? 'Profile picture' : 'Certificate'} saved locally.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
                action: SnackBarAction(
                  label: 'Retry Firebase',
                  textColor: Colors.white,
                  onPressed: () {
                    _uploadImageToFirebase(imageFile, isProfile);
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateField(String field, dynamic value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('clinics').doc(user.uid).update({field: value});
        
        // Mettre à jour l'état local immédiatement
        setState(() {
          switch (field) {
            case 'about':
              clinicAbout = value;
              break;
            case 'location':
              clinicLocation = value;
              break;
            case 'facilities':
              clinicFacilities = List<String>.from(value);
              break;
            case 'name':
              clinicName = value;
              break;
            case 'email':
              clinicEmail = value;
              break;
            case 'availableSchedule':
              availableSchedule = Map<String, Map<String, String>>.from(value);
              break;
          }
        });
        
        // Recharger les données depuis Firestore pour s'assurer de la cohérence
        await _loadClinicData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$field updated successfully')),
        );
      } catch (e) {
        print('Error updating $field: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update $field')),
        );
      }
    }
  }

  void _toggleExpand(String key) {
    setState(() {
      _expanded[key] = !(_expanded[key] ?? false);
    });
  }

  void _addFacility() {
    setState(() {
      clinicFacilities.add('');
    });
  }

  void _removeFacility(int index) {
    setState(() {
      clinicFacilities.removeAt(index);
    });
    _updateField('facilities', clinicFacilities);
  }

  void _updateFacility(int index, String value) {
    setState(() {
      clinicFacilities[index] = value;
    });
  }

  void _updateSchedule(String day, String startTime, String endTime) {
    setState(() {
      availableSchedule[day] = {
        'startTime': startTime,
        'endTime': endTime,
      };
    });
  }

  void _removeSchedule(String day) {
    setState(() {
      availableSchedule.remove(day);
    });
  }

  Future<void> _changePassword(String oldPassword, String newPassword) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        final cred = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(newPassword);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update password')));
      }
    }
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

  // Nouvelle méthode pour construire le sélecteur de secteur
  Future<void> _selectSectorBottomSheet() async {
    String search = '';
    String? selectedSector = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<String> filteredSectors = kigaliSectors;
        return StatefulBuilder(
          builder: (context, setModalState) {
            filteredSectors = kigaliSectors
                .where((sector) => sector.toLowerCase().contains(search.toLowerCase()))
                .toList();
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select your sector', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18,
                      color: Color(0xFF159BBD),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search sector (KK, KG, etc.)...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF159BBD)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF159BBD)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF159BBD), width: 2),
                      ),
                    ),
                    onChanged: (val) => setModalState(() => search = val),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      itemCount: filteredSectors.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF159BBD)),
                          title: Text(filteredSectors[index]),
                          subtitle: Text('Kigali, Rwanda'),
                          onTap: () {
                            Navigator.pop(context, filteredSectors[index]);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedSector != null) {
      setState(() {
        _selectedSector = selectedSector;
        // Mettre à jour le champ d'adresse avec le nouveau secteur
        String currentText = _addressController.text;
        if (currentText.contains('KK') || currentText.contains('KG') || 
            currentText.contains('KN') || currentText.contains('KM') || 
            currentText.contains('KP') || currentText.contains('KR') || 
            currentText.contains('KY') || currentText.contains('KC') || 
            currentText.contains('KI') || currentText.contains('KJ')) {
          // Remplacer l'ancien secteur par le nouveau
          _addressController.text = currentText.replaceFirstMapped(
            RegExp(r'K[A-Z]\s*\([^)]*\)'),
            (match) => selectedSector
          );
        } else {
          // Ajouter le nouveau secteur au début
          _addressController.text = '$selectedSector, ${currentText.isEmpty ? 'Kigali, Rwanda' : currentText}';
        }
        clinicLocation = _addressController.text;
      });
    }
  }

  // Méthode pour uploader l'image vers Firebase Storage
  Future<void> _uploadImageToFirebase(File imageFile, bool isProfile) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Créer un nom de fichier unique avec l'ID utilisateur
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${isProfile ? 'profile' : 'certificate'}_${user.uid}_$timestamp.$extension';
      
      // Référence Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('clinics')
          .child(user.uid)
          .child(fileName);

      print('Starting upload to: $fileName');

      // Upload avec métadonnées
      final metadata = SettableMetadata(
        contentType: 'image/$extension',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'fileType': isProfile ? 'profile' : 'certificate',
        },
      );

      final uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Attendre la completion
      final snapshot = await uploadTask;
      
      // Obtenir l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Upload successful. Download URL: $downloadUrl');

      // Mettre à jour Firestore avec l'URL
      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(user.uid)
          .update({
        isProfile ? 'profileImageUrl' : 'certificateUrl': downloadUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Mettre à jour l'état local
      if (mounted) {
        setState(() {
          if (isProfile) {
            profileImageUrl = downloadUrl;
            _profileImageFile = null;
          } else {
            certificateUrl = downloadUrl;
            _certificateFile = null;
          }
        });
      }

    } catch (e) {
      print('Upload error: $e');
      throw e;
    }
  }

  // Méthode alternative pour sauvegarder l'image localement
  Future<void> _saveImageLocally(File imageFile, bool isProfile) async {
    try {
      // Créer un nom de fichier unique
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final fileName = '${isProfile ? 'profile' : 'certificate'}_$timestamp.$extension';
      
      // Sauvegarder dans le stockage local de l'app
      final appDir = await getApplicationDocumentsDirectory();
      final savedFile = await imageFile.copy('${appDir.path}/$fileName');
      
      print('Image saved locally at: ${savedFile.path}');
      
      // Sauvegarder le chemin dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = isProfile ? 'profile_image_path' : 'certificate_image_path';
      await prefs.setString(key, savedFile.path);
      
      // Mettre à jour l'état local avec le chemin local
      if (mounted) {
        setState(() {
          if (isProfile) {
            profileImageUrl = savedFile.path;
            _profileImageFile = null;
          } else {
            certificateUrl = savedFile.path;
            _certificateFile = null;
          }
        });
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isProfile ? 'Profile picture' : 'Certificate'} saved successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error saving image locally: $e');
      
      // En cas d'erreur, essayer de sauvegarder temporairement
      try {
        if (mounted) {
          setState(() {
            if (isProfile) {
              _profileImageFile = imageFile;
              profileImageUrl = null;
            } else {
              _certificateFile = imageFile;
              certificateUrl = null;
            }
          });
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${isProfile ? 'Profile picture' : 'Certificate'} loaded temporarily'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (fallbackError) {
        print('Fallback error: $fallbackError');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
                      'Clinic Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    if (!isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                            SizedBox(width: 4),
                            Text('Unverified', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Profile Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                        ))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile Picture
                              Center(
                                child: Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF159BBD),
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.white,
                                          child: _buildProfileImage(),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () => _pickImage(true),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF159BBD),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                spreadRadius: 1,
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Editable Clinic Name
                              _buildExpandableEditableRow(
                                icon: Icons.business,
                                title: 'Clinic Name',
                                value: clinicName,
                                field: 'name',
                              ),
                              const SizedBox(height: 12),
                              // Editable Email
                              _buildExpandableEditableRow(
                                icon: Icons.email,
                                title: 'Email',
                                value: clinicEmail,
                                field: 'email',
                              ),
                              const SizedBox(height: 12),
                              // About Us Section
                              _buildExpandableEditableRow(
                                icon: Icons.info_outline,
                                title: 'About Us',
                                value: clinicAbout,
                                field: 'about',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              // Location Section
                              _buildExpandableEditableRow(
                                icon: Icons.location_on,
                                title: 'Location',
                                value: clinicLocation,
                                field: 'location',
                              ),
                              const SizedBox(height: 12),
                              // Schedule Section
                              _buildScheduleSection(),
                              const SizedBox(height: 12),
                              // Facilities Section (dynamique)
                              _buildFacilitiesSection(),
                              const SizedBox(height: 20),
                              // Certificate Upload
                              _buildUploadSection(
                                icon: Icons.verified_user,
                                title: 'Upload Certificate / Licence',
                                file: _certificateFile,
                                url: certificateUrl,
                                onTap: () => _pickImage(false),
                                textColor: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              // Change Password Section
                              _buildChangePasswordSection(),
                              const SizedBox(height: 30),
                              // Logout Button
                              Center(
                                child: ElevatedButton(
                                  onPressed: _signOut,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF159BBD),
                                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Logout',
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

  Widget _buildExpandableEditableRow({
    required IconData icon,
    required String title,
    required String value,
    required String field,
    int maxLines = 1,
  }) {
    final expanded = _expanded[field] ?? false;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF159BBD)),
            const SizedBox(width: 14),
            Expanded(
              child: expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            if (field == 'location') ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.map, color: Color(0xFF159BBD), size: 20),
                                onPressed: _selectSectorBottomSheet,
                                tooltip: 'Choose sector (KK, KG, etc.)',
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (field == 'location') ...[
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'e.g. KK 123 St, House #45, Kigali',
                              helperText: 'Select sector first, then add street number and details',
                              helperStyle: TextStyle(color: Colors.grey[600]),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              prefixIcon: const Icon(Icons.location_on, color: Color(0xFF159BBD)),
                            ),
                            onChanged: (newValue) {
                              setState(() {
                                clinicLocation = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _updateField('location', clinicLocation);
                                  _toggleExpand('location');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF159BBD),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                ),
                                child: const Text('Save', style: TextStyle(fontSize: 13, color: Colors.white)),
                              ),
                            ],
                          ),
                        ]
                        else ...[
                          TextFormField(
                            initialValue: value,
                            maxLines: maxLines,
                            decoration: InputDecoration(
                              hintText: 'Enter $title',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (newValue) {
                              setState(() {
                                switch (field) {
                                  case 'about':
                                    clinicAbout = newValue;
                                    break;
                                  case 'name':
                                    clinicName = newValue;
                                    break;
                                  case 'email':
                                    clinicEmail = newValue;
                                    break;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _updateField(field, field == 'about' ? clinicAbout :
                                             field == 'name' ? clinicName :
                                             field == 'email' ? clinicEmail : value);
                                  _toggleExpand(field);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF159BBD),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                ),
                                child: const Text('Save', style: TextStyle(fontSize: 13, color: Colors.white)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            value.isEmpty ? 'No $title' : value,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF159BBD)),
                          onPressed: () => _toggleExpand(field),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    final expanded = _expanded['schedule'] ?? false;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF159BBD)),
                const SizedBox(width: 14),
                const Text('Available Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                IconButton(
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF159BBD)),
                  onPressed: () => _toggleExpand('schedule'),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 8),
              ...weekDays.map((day) {
                final daySchedule = availableSchedule[day];
                return _buildDayScheduleRow(day, daySchedule);
              }).toList(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _updateField('availableSchedule', availableSchedule);
                      _toggleExpand('schedule');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF159BBD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
            if (!expanded)
              Padding(
                padding: const EdgeInsets.only(left: 34, top: 4),
                child: availableSchedule.isEmpty
                    ? const Text('No schedule set', style: TextStyle(fontSize: 15))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: availableSchedule.entries.map((entry) {
                          final day = entry.key;
                          final schedule = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '$day: ${schedule['startTime']} - ${schedule['endTime']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayScheduleRow(String day, Map<String, String>? daySchedule) {
    String startTime = daySchedule?['startTime'] ?? '';
    String endTime = daySchedule?['endTime'] ?? '';
    bool isActive = daySchedule != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF159BBD).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? const Color(0xFF159BBD) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isActive ? const Color(0xFF159BBD) : Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: startTime.isNotEmpty 
                            ? TimeOfDay(hour: int.parse(startTime.split(':')[0]), minute: int.parse(startTime.split(':')[1]))
                            : TimeOfDay.now(),
                      );
                      if (picked != null) {
                        startTime = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
                        _updateSchedule(day, startTime, endTime);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        startTime.isEmpty ? 'Start' : startTime,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: startTime.isEmpty ? Colors.grey : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-', style: TextStyle(fontSize: 12)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: endTime.isNotEmpty 
                            ? TimeOfDay(hour: int.parse(endTime.split(':')[0]), minute: int.parse(endTime.split(':')[1]))
                            : TimeOfDay.now(),
                      );
                      if (picked != null) {
                        endTime = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
                        _updateSchedule(day, startTime, endTime);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        endTime.isEmpty ? 'End' : endTime,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: endTime.isEmpty ? Colors.grey : Colors.black,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isActive ? Icons.remove_circle : Icons.add_circle,
              color: isActive ? Colors.red : const Color(0xFF159BBD),
              size: 20,
            ),
            onPressed: () {
              if (isActive) {
                _removeSchedule(day);
              } else {
                _updateSchedule(day, '09:00', '17:00');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    final expanded = _expanded['facilities'] ?? false;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_hospital, color: Color(0xFF159BBD)),
                const SizedBox(width: 14),
                const Text('Facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                IconButton(
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF159BBD)),
                  onPressed: () => _toggleExpand('facilities'),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 8),
              if (clinicFacilities.isEmpty)
                ElevatedButton.icon(
                  onPressed: _addFacility,
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text('Add first facility', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF159BBD),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  ),
                ),
              ...List.generate(clinicFacilities.length, (index) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: clinicFacilities[index],
                            decoration: InputDecoration(
                              hintText: 'Enter facility name',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            onChanged: (val) => _updateFacility(index, val),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeFacility(index),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _addFacility,
                          icon: const Icon(Icons.add, color: Colors.white, size: 16),
                          label: const Text('Add new', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF159BBD),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              }),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _updateField('facilities', clinicFacilities);
                      _toggleExpand('facilities');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF159BBD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
            if (!expanded)
              Padding(
                padding: const EdgeInsets.only(left: 34, top: 4),
                child: clinicFacilities.isEmpty
                    ? const Text('No Facilities', style: TextStyle(fontSize: 15))
                    : Wrap(
                        spacing: 8,
                        children: clinicFacilities.map((f) => Chip(label: Text(f))).toList(),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection({required IconData icon, required String title, File? file, String? url, required VoidCallback onTap, Color textColor = Colors.white}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF159BBD)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (file != null)
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      if (url != null && url.isNotEmpty)
                        const Icon(Icons.cloud_done, color: Colors.green, size: 20),
                      if ((file == null && (url == null || url.isEmpty)))
                        const Icon(Icons.cloud_upload, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        file != null 
                            ? 'Ready to upload'
                            : (url != null && url.isNotEmpty)
                                ? 'Uploaded successfully'
                                : 'No file selected',
                        style: TextStyle(
                          fontSize: 12,
                          color: file != null 
                              ? Colors.orange
                              : (url != null && url.isNotEmpty)
                                  ? Colors.green
                                  : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.upload_file, size: 16),
                    label: Text(
                      file != null 
                          ? 'Upload Now'
                          : (url != null && url.isNotEmpty)
                              ? 'Change File'
                              : 'Select File',
                      style: TextStyle(color: textColor),
                    ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF159BBD),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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

  Widget _buildChangePasswordSection() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    final expanded = _expanded['password'] ?? false;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: Color(0xFF159BBD)),
                const SizedBox(width: 14),
                const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                IconButton(
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, color: const Color(0xFF159BBD)),
                  onPressed: () => _toggleExpand('password'),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: oldPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Old Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: newPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: confirmPassController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (newPassController.text == confirmPassController.text && newPassController.text.length >= 6) {
                        _changePassword(oldPassController.text, newPassController.text);
                        _toggleExpand('password');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match or too short')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF159BBD),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 13, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_profileImageFile != null) {
      return Image.file(
        _profileImageFile!, 
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading local image: $error');
          return const Icon(Icons.local_hospital, size: 60, color: Color(0xFF159BBD));
        },
      );
    } else if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      // Vérifier si c'est une URL réseau ou un chemin local
      if (profileImageUrl!.startsWith('http')) {
        // Image réseau
        return Image.network(
          profileImageUrl!, 
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading network image: $error');
            // En cas d'erreur, nettoyer l'URL et afficher l'icône par défaut
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  profileImageUrl = null;
                });
              }
            });
            return const Icon(Icons.local_hospital, size: 60, color: Color(0xFF159BBD));
          },
        );
      } else {
        // Image locale
        return Image.file(
          File(profileImageUrl!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error loading local saved image: $error');
            // En cas d'erreur, nettoyer le chemin et afficher l'icône par défaut
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  profileImageUrl = null;
                });
              }
            });
            return const Icon(Icons.local_hospital, size: 60, color: Color(0xFF159BBD));
          },
        );
      }
    } else {
      return const Icon(Icons.local_hospital, size: 60, color: Color(0xFF159BBD));
    }
  }
} 