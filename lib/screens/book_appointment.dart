import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:homecare_app/screens/main_dashboard.dart';
import 'package:homecare_app/screens/profile_page.dart';
import 'package:homecare_app/screens/chat_page.dart';
import 'package:homecare_app/screens/appointments_page.dart';
import 'package:homecare_app/screens/pro_hospitals_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../widgets/professional_bottom_nav.dart';
import 'package:lottie/lottie.dart';

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

class _BookAppointmentPageState extends State<BookAppointmentPage> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  String? selectedDepartment;
  DateTime? selectedDate;
  String? selectedTime;
  String? selectedSpecialty;
  String patientName = '';
  String patientPhone = '';
  String patientEmail = '';
  String reasonOfBooking = '';
  String notes = '';
  int meetingDuration = 30; // Default duration, will be updated from clinic settings

  // Controllers pour les champs de texte
  late TextEditingController _reasonOfBookingController;

  // Variables pour la gestion des horaires
  List<String> availableDays = [];
  List<String> availableTimeSlots = [];
  Map<String, List<String>> dayTimeSlots = {};
  // NOUVEAU: Stocker les créneaux indisponibles pour feedback visuel
  Set<String> bookedTimeSlots = {};
  bool isLoading = false;
  
  // NOUVEAU: Variable pour l'écoute en temps réel
  StreamSubscription<QuerySnapshot>? _appointmentsListener;
  String? _currentClinicId;

  // Liste des départements disponibles
  final List<String> departments = [
    'General Medicine',
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'Gynecology',
    'Dermatology',
    'Orthopedics',
    'ENT',
    'Ophthalmology',
    'Laboratory',
    'Physiotherapy',
    'Mental Health',
  ];

  @override
  void initState() {
    super.initState();
    _reasonOfBookingController = TextEditingController(text: reasonOfBooking);
    _initializeAvailableSlots();
    _loadClinicMeetingDuration();
    // NOUVEAU: Initialiser l'écoute en temps réel
    _initializeRealtimeListener();
  }

  void _initializeBubbleAnimations() {
    // Initialize animation controllers with different durations
    // _bubble1Controller = AnimationController(
    //   duration: const Duration(seconds: 8),
    //   vsync: this,
    // );
    // _bubble2Controller = AnimationController(
    //   duration: const Duration(seconds: 12),
    //   vsync: this,
    // );
    // _bubble3Controller = AnimationController(
    //   duration: const Duration(seconds: 10),
    //   vsync: this,
    // );
    // _bubble4Controller = AnimationController(
    //   duration: const Duration(seconds: 15),
    //   vsync: this,
    // );

    // Set up floating animations
    // _bubble1Animation = Tween<Offset>(
    //   begin: const Offset(0.1, 0.8),
    //   end: const Offset(0.9, 0.2),
    // ).animate(CurvedAnimation(
    //   parent: _bubble1Controller,
    //   curve: Curves.easeInOut,
    // ));

    // _bubble2Animation = Tween<Offset>(
    //   begin: const Offset(0.8, 0.9),
    //   end: const Offset(0.2, 0.1),
    // ).animate(CurvedAnimation(
    //   parent: _bubble2Controller,
    //   curve: Curves.easeInOut,
    // ));

    // _bubble3Animation = Tween<Offset>(
    //   begin: const Offset(0.3, 0.1),
    //   end: const Offset(0.7, 0.9),
    // ).animate(CurvedAnimation(
    //   parent: _bubble3Controller,
    //   curve: Curves.easeInOut,
    // ));

    // _bubble4Animation = Tween<Offset>(
    //   begin: const Offset(0.9, 0.3),
    //   end: const Offset(0.1, 0.7),
    // ).animate(CurvedAnimation(
    //   parent: _bubble4Controller,
    //   curve: Curves.easeInOut,
    // ));

    // Start animations with repeat
    // _bubble1Controller.repeat(reverse: true);
    // _bubble2Controller.repeat(reverse: true);
    // _bubble3Controller.repeat(reverse: true);
    // _bubble4Controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _reasonOfBookingController.dispose();
    // NOUVEAU: Annuler l'écoute en temps réel
    _appointmentsListener?.cancel();
    // _bubble1Controller.dispose();
    // _bubble2Controller.dispose();
    // _bubble3Controller.dispose();
    // _bubble4Controller.dispose();
    super.dispose();
  }

  void _initializeAvailableSlots() {
    print('=== INITIALIZING AVAILABLE SLOTS ===');
    print('Hospital schedule: ${widget.hospitalSchedule}');
    
    // Extraire les jours disponibles
    availableDays = widget.hospitalSchedule.keys.toList();
    print('Available days: $availableDays');
    
    // Générer les créneaux horaires pour chaque jour
    for (String day in availableDays) {
      final schedule = widget.hospitalSchedule[day];
      print('Schedule for $day: $schedule');
      
      if (schedule != null) {
        final startTime = schedule['startTime'] ?? '';
        final endTime = schedule['endTime'] ?? '';
        
        print('Start time: $startTime, End time: $endTime');
        
        if (startTime.isNotEmpty && endTime.isNotEmpty) {
          dayTimeSlots[day] = _generateTimeSlots(startTime, endTime);
          print('Generated ${dayTimeSlots[day]!.length} time slots for $day');
        } else {
          // Si pas d'horaires spécifiques, utiliser des horaires par défaut
          dayTimeSlots[day] = _generateDefaultTimeSlots();
          print('Using default time slots for $day');
        }
      } else {
        // Si pas de planning pour ce jour, utiliser des horaires par défaut
        dayTimeSlots[day] = _generateDefaultTimeSlots();
        print('Using default time slots for $day (no schedule)');
      }
    }
    
    // Si aucun jour n'est défini, utiliser des jours par défaut
    if (availableDays.isEmpty) {
      availableDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      for (String day in availableDays) {
        dayTimeSlots[day] = _generateDefaultTimeSlots();
      }
      print('Using default days and time slots');
    }
    
    print('Final available days: $availableDays');
    print('Final day time slots: $dayTimeSlots');
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
          current = current.add(Duration(minutes: meetingDuration));
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

  // Formater l'heure pour l'affichage (ex: 10:00 -> 10h00)
  String _formatTimeForDisplay(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return '${hour}h${minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      print('Error formatting time: $e');
    }
    return time;
  }

  // Formater l'heure pour l'affichage avec période (ex: 10:00 -> 10:00 AM)
  String _formatTimeWithPeriod(String time) {
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
      print('Error formatting time with period: $e');
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

  List<String> _generateDefaultTimeSlots() {
    List<String> slots = [];
    // Horaires par défaut : 8h00 à 18h00 avec des créneaux selon la durée configurée
    for (int hour = 8; hour < 18; hour++) {
      for (int minute = 0; minute < 60; minute += meetingDuration) {
        slots.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }

  Future<void> _loadClinicMeetingDuration() async {
    try {
      final duration = await AppointmentService.getClinicMeetingDuration(widget.hospitalName);
      setState(() {
        meetingDuration = duration;
      });
      print('✓ Loaded clinic meeting duration: $duration minutes');
    } catch (e) {
      print('Error loading clinic meeting duration: $e');
      // Keep default 30 minutes
    }
  }

  // Générer les créneaux horaires disponibles pour la date sélectionnée
  Future<void> _generateTimeSlotsForDate(DateTime date) async {
    try {
      setState(() {
        isLoading = true;
      });

      print('=== GENERATING TIME SLOTS FOR DATE ===');
      print('Date: ${DateFormat('yyyy-MM-dd').format(date)}');
      print('Hospital: ${widget.hospitalName}');

      // Step 1: Generate all possible time slots based on hospital schedule
      final dayName = DateFormat('EEEE').format(date);
      List<String> allPossibleSlots = [];
      
      if (dayTimeSlots.containsKey(dayName)) {
        allPossibleSlots = dayTimeSlots[dayName]!;
      } else {
        allPossibleSlots = _generateDefaultTimeSlots();
      }

      print('Generated ${allPossibleSlots.length} possible time slots');

      // Step 2: Check which slots are already booked
      Set<String> bookedSlots = {};
      
      for (final timeSlot in allPossibleSlots) {
        final isAvailable = await AppointmentService.isTimeSlotAvailable(
          widget.hospitalName,
          date,
          timeSlot,
        );
        
        if (!isAvailable) {
          bookedSlots.add(timeSlot);
        }
      }

      print('Found ${bookedSlots.length} booked time slots');

      // Step 3: Update UI state
      setState(() {
        dayTimeSlots[DateFormat('yyyy-MM-dd').format(date)] = allPossibleSlots;
        bookedTimeSlots = bookedSlots;
        isLoading = false;
      });

      print('✓ Time slots generation completed');
      print('✓ Available slots: ${allPossibleSlots.length - bookedSlots.length}');
      print('✓ Booked slots: ${bookedSlots.length}');
      
    } catch (e) {
      print('Error generating time slots: $e');
      // Fallback to default slots
      final slots = _generateDefaultTimeSlots();
      setState(() {
        dayTimeSlots[DateFormat('yyyy-MM-dd').format(date)] = slots;
        bookedTimeSlots = {};
        isLoading = false;
      });
    }
  }

  // Récupérer l'ID de la clinique par son nom
  Future<String?> _getClinicId(String clinicName) async {
    try {
      print('=== GETTING CLINIC ID ===');
      print('Looking for clinic: "$clinicName"');
      
      // Première tentative: correspondance exacte
      final clinicDocs = await FirebaseFirestore.instance
          .collection('clinics')
          .where('name', isEqualTo: clinicName)
          .get();
      
      if (clinicDocs.docs.isNotEmpty) {
        final clinicId = clinicDocs.docs.first.id;
        print('✅ Found exact match for clinic "$clinicName": $clinicId');
        return clinicId;
      }
      
      print('⚠️ No exact match found, trying partial match...');
      
      // Deuxième tentative: correspondance partielle
      final allClinicDocs = await FirebaseFirestore.instance.collection('clinics').get();
      print('📋 Total clinics in database: ${allClinicDocs.docs.length}');
      
      for (final doc in allClinicDocs.docs) {
        final data = doc.data();
        final name = data['name'] ?? '';
        print('🔍 Checking clinic: "$name" (ID: ${doc.id})');
        
        // Correspondance case-insensitive et partielle
        if (name.toLowerCase().trim() == clinicName.toLowerCase().trim()) {
          print('✅ Found case-insensitive exact match: "$name" -> ${doc.id}');
          return doc.id;
        }
        
        if (name.toLowerCase().contains(clinicName.toLowerCase()) ||
            clinicName.toLowerCase().contains(name.toLowerCase())) {
          print('✅ Found partial match: "$clinicName" matches "$name" -> ${doc.id}');
          return doc.id;
        }
      }
      
      print('❌ No clinic found for name: "$clinicName"');
      print('💡 Available clinic names:');
      for (final doc in allClinicDocs.docs) {
        final data = doc.data();
        final name = data['name'] ?? '';
        print('   - "$name" (ID: ${doc.id})');
      }
      
      return null;
    } catch (e) {
      print('❌ Error getting clinic ID: $e');
      return null;
    }
  }

  // NOUVEAU: Récupérer les créneaux déjà réservés pour une date donnée
  Future<Set<String>> _getBookedTimeSlots(DateTime date) async {
    try {
      final clinicId = await _getClinicId(widget.hospitalName);
      if (clinicId == null) {
        return {};
      }

      // Récupérer les créneaux disponibles et calculer les créneaux réservés par différence
      final availableSlots = await AppointmentService.getAvailableTimeSlots(clinicId, date);
      final allPossibleSlots = _generateDefaultTimeSlots();
      
      // Les créneaux réservés sont ceux qui ne sont pas dans les disponibles
      final bookedSlots = allPossibleSlots.where((slot) => !availableSlots.contains(slot)).toSet();
      
      return bookedSlots;
    } catch (e) {
      print('Error getting booked time slots: $e');
      return {};
    }
  }

  // NOUVEAU: Initialiser l'écoute en temps réel des appointments
  Future<void> _initializeRealtimeListener() async {
    try {
      _currentClinicId = await _getClinicId(widget.hospitalName);
      if (_currentClinicId != null) {
        _setupRealtimeAppointmentListener();
      }
    } catch (e) {
      print('Error initializing realtime listener: $e');
    }
  }

  // NOUVEAU: Configurer l'écoute en temps réel des appointments
  void _setupRealtimeAppointmentListener() {
    if (_currentClinicId == null) return;

    _appointmentsListener = FirebaseFirestore.instance
        .collection('appointments')
        .where('clinicId', isEqualTo: _currentClinicId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .snapshots()
        .listen((snapshot) {
          print('=== REALTIME UPDATE: ${snapshot.docs.length} appointments ===');
          // Rafraîchir les créneaux si une date est sélectionnée
          if (selectedDate != null) {
            _generateTimeSlotsForDate(selectedDate!);
          }
        });

    print('✓ Realtime appointment listener set up for clinic: $_currentClinicId');
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
          MaterialPageRoute(builder: (context) => const ProHospitalsPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
        break;
      case 4:
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
          backgroundColor: Colors.red),);
      return;
    }

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red),);
      return;
    }

    if (selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time'),
          backgroundColor: Colors.red),);
      return;
    }

    if (reasonOfBooking.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please describe your reason for booking'),
          backgroundColor: Colors.red),);
      return;
    }

    try {
      // NOUVEAU: Vérifier la disponibilité du créneau avant de procéder
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
                Text('Checking availability...'),
              ]),);
        },
      );

      // Récupérer l'ID de la clinique pour la validation
      final clinicId = await _getClinicId(widget.hospitalName);
      print('🏥 Clinic ID for "${widget.hospitalName}": $clinicId');
      
      // Vérifier si le créneau est encore disponible
      bool isAvailable = false;
      if (clinicId != null) {
        isAvailable = await AppointmentService.isTimeSlotAvailable(
          clinicId,
          selectedDate!, 
          selectedTime!
        );
        print('✅ Time slot availability check: $isAvailable');
      } else {
        print('⚠️ Clinic ID is null, checking by hospital name instead...');
        // Si on ne trouve pas l'ID de la clinique, vérifier par nom d'hôpital
        isAvailable = await AppointmentService.isTimeSlotAvailable(
          widget.hospitalName,
          selectedDate!,
          selectedTime!
        );
        print('✅ Time slot availability check by hospital name: $isAvailable');
      }

      // Fermer le dialogue de vérification
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (!isAvailable) {
        if (context.mounted) {
          // Rafraîchir silencieusement les créneaux disponibles pour mettre à jour l'affichage
          await _generateTimeSlotsForDate(selectedDate!);
          
          // Réinitialiser la sélection de temps puisque le créneau n'est plus disponible
          setState(() {
            selectedTime = null;
          });
        }
        return;
      }

      // Afficher un indicateur de progression pour la réservation
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
              ]),);
        },
      );

      // Récupérer les informations de l'utilisateur connecté
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Récupérer le profil utilisateur pour obtenir le vrai nom
      String patientName = 'Patient Name Not Available';
      String patientEmail = user.email ?? '';
      String patientPhone = '';
      
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          patientName = userData['name'] ?? userData['fullName'] ?? user.displayName ?? 'Patient Name Not Available';
          patientEmail = userData['email'] ?? user.email ?? '';
          patientPhone = userData['phone'] ?? userData['phoneNumber'] ?? '';
        } else {
          // Si pas de document utilisateur, essayer avec displayName
          patientName = user.displayName ?? 'Patient Name Not Available';
        }
      } catch (e) {
        print('Error fetching user profile: $e');
        patientName = user.displayName ?? 'Patient Name Not Available';
      }

      // Créer le rendez-vous avec la méthode standard
      final appointment = Appointment(
        id: '',
        patientId: user.uid,
        patientName: patientName,
        patientEmail: patientEmail,
        patientPhone: patientPhone,
        hospitalName: widget.hospitalName,
        hospitalImage: widget.hospitalImage,
        hospitalLocation: widget.hospitalLocation,
        department: selectedDepartment ?? 'General Consultation',
        appointmentDate: selectedDate!,
        appointmentTime: selectedTime!,
        reasonOfBooking: reasonOfBooking.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );
      
      final appointmentId = await AppointmentService.createAppointment(appointment);

      // Fermer le dialogue de progression
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // 🎉 NEW: Show professional success popup
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50),),
                  const SizedBox(height: 20),
                  
                  // Success Title
                  const Text(
                    'Appointment Booked Successfully!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Success Message
                  Text(
                    'Your appointment has been booked at ${widget.hospitalName}.\n\nYou will receive a confirmation once the clinic approves your request.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        // Navigate to main dashboard
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const MainDashboard(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF159BBD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),)),),
                ]),);
          },
        );
      }

    } catch (e) {
      // Fermer le dialogue de progression en cas d'erreur
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3)),);
      }
    }
  }

  // Mettre à jour la sélection de date et générer les créneaux
  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
      selectedTime = null; // Reset time selection
    });
    
    // Générer les créneaux pour la nouvelle date
    _generateTimeSlotsForDate(date);
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
            stops: const [0.0, 0.3, 0.6, 0.8]),),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section with Animated Bubbles
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    // Animated Bubbles Background
                    // Bubble 1
                    // AnimatedBuilder(
                    //   animation: _bubble1Animation,
                    //   builder: (context, child) {
                    //     return Positioned(
                    //       left: _bubble1Animation.value.dx * MediaQuery.of(context).size.width,
                    //       top: _bubble1Animation.value.dy * 80,
                    //       child: Container(
                    //         width: 60,
                    //         height: 60,
                    //         decoration: BoxDecoration(
                    //           shape: BoxShape.circle,
                    //           gradient: LinearGradient(
                    //             colors: [
                    //               Colors.white.withOpacity(0.15),
                    //               Colors.white.withOpacity(0.05),
                    //             ]),)),);
                    //   },
                    // ),
                    // Bubble 2
                    // AnimatedBuilder(
                    //   animation: _bubble2Animation,
                    //   builder: (context, child) {
                    //     return Positioned(
                    //       left: _bubble2Animation.value.dx * MediaQuery.of(context).size.width,
                    //       top: _bubble2Animation.value.dy * 80,
                    //       child: Container(
                    //         width: 40,
                    //         height: 40,
                    //         decoration: BoxDecoration(
                    //           shape: BoxShape.circle,
                    //           gradient: LinearGradient(
                    //             colors: [
                    //               Colors.white.withOpacity(0.2),
                    //               Colors.white.withOpacity(0.08),
                    //             ]),)),);
                    //   },
                    // ),
                    // Bubble 3
                    // AnimatedBuilder(
                    //   animation: _bubble3Animation,
                    //   builder: (context, child) {
                    //     return Positioned(
                    //       left: _bubble3Animation.value.dx * MediaQuery.of(context).size.width,
                    //       top: _bubble3Animation.value.dy * 80,
                    //       child: Container(
                    //         width: 80,
                    //         height: 80,
                    //         decoration: BoxDecoration(
                    //           shape: BoxShape.circle,
                    //           gradient: LinearGradient(
                    //             colors: [
                    //               Colors.white.withOpacity(0.1),
                    //               Colors.white.withOpacity(0.03),
                    //             ]),)),);
                    //   },
                    // ),
                    // Bubble 4
                    // AnimatedBuilder(
                    //   animation: _bubble4Animation,
                    //   builder: (context, child) {
                    //     return Positioned(
                    //       left: _bubble4Animation.value.dx * MediaQuery.of(context).size.width,
                    //       top: _bubble4Animation.value.dy * 80,
                    //       child: Container(
                    //         width: 35,
                    //         height: 35,
                    //         decoration: BoxDecoration(
                    //           shape: BoxShape.circle,
                    //           gradient: LinearGradient(
                    //             colors: [
                    //               Colors.white.withOpacity(0.25),
                    //               Colors.white.withOpacity(0.1),
                    //             ]),)),);
                    //   },
                    // ),
                    // Header Content
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Book Your Appointment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center),),
                        const SizedBox(width: 48), // Pour équilibrer avec la flèche
                      ],
                    ),
                  ]),),
              // Main Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),),
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
                              // Hospital Information Section
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.1)),),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Hospital Name
                              Center(
                                child: Text(
                                  widget.hospitalName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF159BBD))),),
                                    const SizedBox(height: 16),
                                    
                                    // Available Hours
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Lottie.asset(
                                            'assets/cal.json',
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.access_time,
                                                color: Color(0xFF159BBD),
                                                size: 20,
                                              );
                                            }),),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Available Hours: 24/7',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey),),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Location
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Lottie.asset(
                                            'assets/location.json',
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.location_on,
                                                color: Color(0xFF159BBD),
                                                size: 20,
                                              );
                                            }),),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            widget.hospitalLocation,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey)),),
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
                                                  color: Colors.grey),),
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
                                                        color: Color(0xFF159BBD))),);
                                                }).toList(),
                                              ),
                                            ]),),
                                      ],
                                    ),
                                  ]),),
                              const SizedBox(height: 20),
                              // Department Selection
                              Text(
                                'Select Department',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),),
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
                                    }),),
                              const SizedBox(height: 20),

                              // Date and Time Selection
                              Text(
                                'Select Date & Time',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800]),),
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
                                            color: Colors.grey[700]),),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (availableDays.isEmpty || _getAvailableDates().isEmpty)
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
                                                'Loading available dates...',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange[700])),),
                                          ]),)
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
                                                _onDateSelected(date);
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
                                                        color: isSelected ? Colors.white : Colors.grey[600]),),
                                                    Text(
                                                      date.day.toString(),
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSelected ? Colors.white : Colors.grey[800]),),
                                                    Text(
                                                      dayName.substring(0, 3),
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: isSelected ? Colors.white70 : Colors.grey[500]),),
                                                  ])),);
                                          }),),
                                  ]),),
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
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Lottie.asset(
                                              'assets/cal.json',
                                              width: 20,
                                              height: 20,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(Icons.access_time, color: Color(0xFF159BBD));
                                              }),),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Available Times',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700]),),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF159BBD).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$meetingDuration min',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF159BBD))),),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      if (isLoading)
                                        const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(20),
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF159BBD))),)
                                      else if (selectedDate != null)
                                        _buildTimeSlotsGrid()
                                      else
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[200]!),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'Please select a date to see available times',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 14),)),),
                                    ]),),
                              const SizedBox(height: 20),
                              // Reason for Booking
                              Text(
                                'Reason for Booking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700]),),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _reasonOfBookingController,
                                onChanged: (value) {
                                  setState(() {
                                    reasonOfBooking = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter your reason for booking',
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
                                    borderSide: const BorderSide(color: Color(0xFF159BBD))),),
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
                                      color: Colors.white),)),),
                            ]),),
                      ]),)),),
            ])),),
      bottomNavigationBar: ProfessionalBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavItem(
            icon: Icon(Icons.home, color: Colors.white70),
            activeIcon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          BottomNavItem(
            icon: Icon(Icons.calendar_today, color: Colors.white70),
            activeIcon: Icon(Icons.calendar_today, color: Colors.white),
            label: 'Appointments',
          ),
          BottomNavItem(
            icon: Icon(Icons.add, color: Colors.white70),
            activeIcon: Icon(Icons.add, color: Colors.white),
            label: 'Book',
          ),
          BottomNavItem(
            icon: Icon(Icons.message, color: Colors.white70),
            activeIcon: Icon(Icons.message, color: Colors.white),
            label: 'Messages',
          ),
          BottomNavItem(
            icon: Icon(Icons.person, color: Colors.white70),
            activeIcon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
        ]),);
  }

  Widget _buildTimeSlotsGrid() {
    final dayName = DateFormat('EEEE').format(selectedDate!);
    final availableSlots = dayTimeSlots[dayName] ?? [];
    
    // Générer une liste complète incluant les créneaux indisponibles
    final allPossibleSlots = _generateDefaultTimeSlots();
    final List<String> allSlots = [];
    
    // Combiner les créneaux disponibles et indisponibles pour un affichage complet
    for (final slot in allPossibleSlots) {
      allSlots.add(slot);
    }
    
    // Si aucun créneau, afficher le message par défaut
    if (allSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.schedule_outlined, color: Colors.orange[600], size: 32),
            const SizedBox(height: 8),
            Text(
              'No time slots available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.orange[700]),),
            const SizedBox(height: 4),
            Text(
              'Please select a different date or contact the clinic directly.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600]),),
          ]),);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Légende pour expliquer les différents états
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              // Légende disponible
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF159BBD))),),
              const SizedBox(width: 6),
              const Text('Available', style: TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(width: 16),
              // Légende sélectionné
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF159BBD),
                  borderRadius: BorderRadius.circular(4)),),
              const SizedBox(width: 6),
              const Text('Selected', style: TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(width: 16),
              // Légende réservé
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: CustomPaint(
                  painter: MiniHatchPatternPainter()),),
              const SizedBox(width: 6),
              const Text('Booked', style: TextStyle(fontSize: 11, color: Colors.black54)),
            ]),),
        
        // Grille des créneaux horaires
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: allSlots.map((time) {
            final isSelected = selectedTime == time;
            final isBooked = bookedTimeSlots.contains(time);
            final isAvailable = availableSlots.contains(time) && !isBooked;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isAvailable ? () {
                    setState(() {
                      selectedTime = time;
                    });
                  } : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    height: 45,
                    decoration: BoxDecoration(
                      color: _getTimeSlotColor(isBooked, isSelected, isAvailable),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getTimeSlotBorderColor(isBooked, isSelected, isAvailable),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: _getTimeSlotShadow(isBooked, isSelected, isAvailable),
                    ),
                    child: Stack(
                      children: [
                        // Effet hachuré pour les créneaux réservés
                        if (isBooked)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: CustomPaint(
                                painter: ProfessionalHatchPatternPainter())),),
                        
                        // Contenu principal
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTimeForDisplay(time),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _getTimeSlotTextColor(isBooked, isSelected, isAvailable)),),
                              if (isBooked)
                                Text(
                                  'Booked',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red[600]),),
                            ]),),
                        
                        // Icône de statut dans le coin
                        if (isBooked)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.red[500],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 8,
                                color: Colors.white)),)
                        else if (isSelected)
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green[500],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 8,
                                color: Colors.white)),),
                        
                        // Overlay pour les créneaux non disponibles
                        if (isBooked)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(11))),),
                      ]),))),);
          }).toList(),
        ),
      ],
    );
  }

  // Fonction pour déterminer la couleur de fond du créneau
  Color _getTimeSlotColor(bool isBooked, bool isSelected, bool isAvailable) {
    if (isBooked) {
      return Colors.red[50]!;
    } else if (isSelected) {
      return const Color(0xFF159BBD);
    } else if (isAvailable) {
      return Colors.white;
    } else {
      return Colors.grey[100]!;
    }
  }

  // Fonction pour déterminer la couleur de bordure du créneau
  Color _getTimeSlotBorderColor(bool isBooked, bool isSelected, bool isAvailable) {
    if (isBooked) {
      return Colors.red[300]!;
    } else if (isSelected) {
      return const Color(0xFF159BBD);
    } else if (isAvailable) {
      return const Color(0xFF159BBD).withOpacity(0.3);
    } else {
      return Colors.grey[300]!;
    }
  }

  // Fonction pour déterminer la couleur du texte du créneau
  Color _getTimeSlotTextColor(bool isBooked, bool isSelected, bool isAvailable) {
    if (isBooked) {
      return Colors.red[700]!;
    } else if (isSelected) {
      return Colors.white;
    } else if (isAvailable) {
      return const Color(0xFF159BBD);
    } else {
      return Colors.grey[500]!;
    }
  }

  // Fonction pour déterminer l'ombre du créneau
  List<BoxShadow> _getTimeSlotShadow(bool isBooked, bool isSelected, bool isAvailable) {
    if (isBooked) {
      return [
        BoxShadow(
          color: Colors.red.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    } else if (isSelected) {
      return [
        BoxShadow(
          color: const Color(0xFF159BBD).withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isAvailable) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
    } else {
      return [];
    }
  }
}

// CustomPainter pour les hachures des créneaux réservés
class ProfessionalHatchPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw diagonal lines for hatch pattern
    const spacing = 8.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// CustomPainter pour les mini hachures dans la légende
class MiniHatchPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.4)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Créer un motif de hachures diagonales
    for (double i = -size.height; i < size.width; i += 3) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 