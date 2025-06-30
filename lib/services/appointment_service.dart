import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/notification_service.dart';

class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Créer un nouveau rendez-vous
  static Future<String> createAppointment(Appointment appointment) async {
    try {
      print('=== CREATING APPOINTMENT ===');
      print('Original hospital name: "${appointment.hospitalName}"');
      
      // Récupérer tous les noms de cliniques existants
      final clinicNames = await getAllClinicNames();
      print('Available clinic names: $clinicNames');
      
      // Chercher une correspondance exacte
      String finalHospitalName = appointment.hospitalName;
      String? clinicId = null;
      
      for (final clinicName in clinicNames) {
        if (clinicName.toLowerCase().trim() == appointment.hospitalName.toLowerCase().trim()) {
          finalHospitalName = clinicName;
          print('Exact match found: using "$clinicName"');
          break;
        }
      }
      
      // Si aucune correspondance exacte, essayer une correspondance partielle
      if (finalHospitalName == appointment.hospitalName) {
        for (final clinicName in clinicNames) {
          if (clinicName.toLowerCase().contains(appointment.hospitalName.toLowerCase()) ||
              appointment.hospitalName.toLowerCase().contains(clinicName.toLowerCase())) {
            finalHospitalName = clinicName;
            print('Partial match found: using "$clinicName"');
            break;
          }
        }
      }
      
      // Trouver l'ID de la clinique par son nom
      clinicId = await _getClinicIdByName(finalHospitalName);
      print('Found clinic ID: $clinicId for clinic: $finalHospitalName');
      
      print('Final hospital name: "$finalHospitalName"');
      
      // Créer une copie du rendez-vous avec le nom corrigé et l'ID de la clinique
      final correctedAppointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        patientName: appointment.patientName,
        patientEmail: appointment.patientEmail,
        patientPhone: appointment.patientPhone,
        hospitalName: finalHospitalName,
        hospitalImage: appointment.hospitalImage,
        hospitalLocation: appointment.hospitalLocation,
        department: appointment.department,
        appointmentDate: appointment.appointmentDate,
        appointmentTime: appointment.appointmentTime,
        reasonOfBooking: appointment.reasonOfBooking,
        status: appointment.status,
        createdAt: appointment.createdAt,
        clinicId: clinicId,
      );

      final docRef = await _firestore
          .collection('appointments')
          .add(correctedAppointment.toFirestore());
      
      print('Appointment created successfully with ID: ${docRef.id}');
      print('Appointment details: ${correctedAppointment.toFirestore()}');
      
      // Créer une notification pour la clinique
      try {
        if (clinicId != null) {
          await NotificationService.createClinicNotification(
            clinicId: clinicId,
            title: 'Nouveau rendez-vous 📅',
            message: 'Un nouveau rendez-vous a été réservé par ${appointment.patientName}',
            appointmentId: docRef.id,
            hospitalName: finalHospitalName,
            department: appointment.department,
            appointmentDate: appointment.appointmentDate,
            appointmentTime: appointment.appointmentTime,
          );
          print('✓ Clinic notification created successfully for clinic: $clinicId');
        } else {
          print('⚠ No clinic found with name: $finalHospitalName');
        }
      } catch (e) {
        print('Error creating clinic notification: $e');
      }
      
      print('=== APPOINTMENT CREATED ===');
      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      throw e;
    }
  }

  // Créer une notification pour la clinique
  static Future<void> _createClinicNotification(Appointment appointment, String appointmentId) async {
    try {
      print('=== CREATING CLINIC NOTIFICATION ===');
      print('Hospital: ${appointment.hospitalName}');
      print('Patient: ${appointment.patientName}');
      
      // Trouver l'ID de la clinique par son nom
      final clinicId = await _getClinicIdByName(appointment.hospitalName);
      
      if (clinicId != null) {
        print('Found clinic ID: $clinicId');
        
        // Créer la notification
        await NotificationService.createClinicNotification(
          clinicId: clinicId,
          title: 'New Appointment Booking',
          message: '${appointment.patientName} has booked an appointment for ${appointment.department} on ${_formatDate(appointment.appointmentDate)} at ${appointment.appointmentTime}',
          appointmentId: appointmentId,
          hospitalName: appointment.hospitalName,
          department: appointment.department,
          appointmentDate: appointment.appointmentDate,
          appointmentTime: appointment.appointmentTime,
        );
        
        print('✓ Clinic notification created for clinic: $clinicId');
      } else {
        print('⚠ No clinic found with name: ${appointment.hospitalName}');
      }
    } catch (e) {
      print('Error in _createClinicNotification: $e');
      throw e;
    }
  }

  // Trouver l'ID de la clinique par son nom
  static Future<String?> _getClinicIdByName(String clinicName) async {
    try {
      final clinicDocs = await _firestore
          .collection('clinics')
          .where('name', isEqualTo: clinicName)
          .get();
      
      if (clinicDocs.docs.isNotEmpty) {
        return clinicDocs.docs.first.id;
      }
      
      // Si pas de correspondance exacte, chercher une correspondance partielle
      final allClinicDocs = await _firestore.collection('clinics').get();
      
      for (final doc in allClinicDocs.docs) {
        final data = doc.data();
        final name = data['name'] ?? '';
        
        if (name.toLowerCase().contains(clinicName.toLowerCase()) ||
            clinicName.toLowerCase().contains(name.toLowerCase())) {
          return doc.id;
        }
      }
      
      return null;
    } catch (e) {
      print('Error getting clinic ID by name: $e');
      return null;
    }
  }

  // Formater la date pour l'affichage
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Corriger le nom de l'hôpital/clinique
  static Future<String> _correctHospitalName(String originalName) async {
    try {
      print('Correcting hospital name: "$originalName"');
      
      // Récupérer tous les noms de cliniques
      final clinicNames = await getAllClinicNames();
      print('Available clinic names: $clinicNames');
      
      // Chercher une correspondance exacte
      for (final clinicName in clinicNames) {
        if (clinicName.toLowerCase().trim() == originalName.toLowerCase().trim()) {
          print('Exact match found: "$originalName" -> "$clinicName"');
          return clinicName;
        }
      }
      
      // Chercher une correspondance partielle
      for (final clinicName in clinicNames) {
        if (clinicName.toLowerCase().contains(originalName.toLowerCase()) ||
            originalName.toLowerCase().contains(clinicName.toLowerCase())) {
          print('Partial match found: "$originalName" -> "$clinicName"');
          return clinicName;
        }
      }
      
      // Chercher une correspondance avec des mots clés
      final originalWords = originalName.toLowerCase().split(' ');
      for (final clinicName in clinicNames) {
        final clinicWords = clinicName.toLowerCase().split(' ');
        
        for (final originalWord in originalWords) {
          for (final clinicWord in clinicWords) {
            if (originalWord.length > 3 && clinicWord.length > 3 && originalWord == clinicWord) {
              print('Keyword match found: "$originalName" -> "$clinicName"');
              return clinicName;
            }
          }
        }
      }
      
      // Si aucune correspondance trouvée, essayer de créer un document de clinique
      print('No match found, attempting to create clinic document for: "$originalName"');
      await _createClinicDocumentIfNotExists(originalName);
      
      return originalName;
    } catch (e) {
      print('Error correcting hospital name: $e');
      return originalName;
    }
  }

  // Créer un document de clinique si il n'existe pas
  static Future<void> _createClinicDocumentIfNotExists(String clinicName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // Vérifier si un document de clinique existe déjà
      final clinicDoc = await _firestore
          .collection('clinics')
          .doc(user.uid)
          .get();
      
      if (!clinicDoc.exists) {
        // Créer un document de clinique
        final clinicData = {
          'name': clinicName,
          'address': 'Address not set',
          'phone': 'Phone not set',
          'email': user.email ?? 'email@example.com',
          'specialties': ['General Medicine'],
          'description': 'Clinic description not set',
          'imageUrl': 'https://via.placeholder.com/150',
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        await _firestore
            .collection('clinics')
            .doc(user.uid)
            .set(clinicData);
        
        print('Created clinic document for: "$clinicName"');
      } else {
        // Mettre à jour le nom de la clinique existante
        await _firestore
            .collection('clinics')
            .doc(user.uid)
            .update({
          'name': clinicName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('Updated clinic name to: "$clinicName"');
      }
    } catch (e) {
      print('Error creating/updating clinic document: $e');
    }
  }

  // Récupérer le nom de la clinique depuis Firebase
  static Future<String> getClinicName(String userId) async {
    try {
      final clinicDoc = await _firestore
          .collection('clinics')
          .doc(userId)
          .get();
      
      if (clinicDoc.exists) {
        final data = clinicDoc.data() ?? {};
        final clinicName = data['name'] ?? '';
        print('Clinic name from Firebase: "$clinicName"');
        return clinicName;
      } else {
        print('No clinic document found for user: $userId');
        return '';
      }
    } catch (e) {
      print('Error getting clinic name: $e');
      return '';
    }
  }

  // Récupérer tous les noms de cliniques dans Firebase
  static Future<List<String>> getAllClinicNames() async {
    try {
      final clinicsSnapshot = await _firestore
          .collection('clinics')
          .get();
      
      final clinicNames = clinicsSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['name'] ?? '';
      }).where((name) => name.isNotEmpty).cast<String>().toList();
      
      print('All clinic names in Firebase: $clinicNames');
      return clinicNames;
    } catch (e) {
      print('Error getting all clinic names: $e');
      return [];
    }
  }

  // Récupérer tous les noms d'hôpitaux dans les rendez-vous
  static Future<List<String>> getAllHospitalNames() async {
    try {
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .get();
      
      final hospitalNames = appointmentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['hospitalName'] ?? '';
      }).where((name) => name.isNotEmpty).cast<String>().toSet().toList();
      
      print('All hospital names in appointments: $hospitalNames');
      return hospitalNames;
    } catch (e) {
      print('Error getting all hospital names: $e');
      return [];
    }
  }

  // Corriger les noms de cliniques dans les rendez-vous
  static Future<void> fixClinicNames() async {
    try {
      print('Starting clinic name fix...');
      
      // Récupérer tous les noms de cliniques
      final clinicNames = await getAllClinicNames();
      final hospitalNames = await getAllHospitalNames();
      
      print('Clinic names: $clinicNames');
      print('Hospital names: $hospitalNames');
      
      // Trouver les correspondances
      for (String clinicName in clinicNames) {
        for (String hospitalName in hospitalNames) {
          if (clinicName.toLowerCase().contains(hospitalName.toLowerCase()) ||
              hospitalName.toLowerCase().contains(clinicName.toLowerCase())) {
            print('Potential match: "$clinicName" <-> "$hospitalName"');
            
            // Mettre à jour les rendez-vous
            final appointmentsSnapshot = await _firestore
                .collection('appointments')
                .where('hospitalName', isEqualTo: hospitalName)
                .get();
            
            for (var doc in appointmentsSnapshot.docs) {
              await doc.reference.update({
                'hospitalName': clinicName,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              print('Updated appointment ${doc.id} from "$hospitalName" to "$clinicName"');
            }
          }
        }
      }
      
      print('Clinic name fix completed');
    } catch (e) {
      print('Error fixing clinic names: $e');
    }
  }

  // Récupérer tous les rendez-vous d'un patient
  static Stream<List<Appointment>> getPatientAppointments() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .orderBy('appointmentDate', descending: false)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        print('Fetched ${snapshot.docs.length} appointments from Firebase');
        return snapshot.docs.map((doc) {
          return Appointment.fromFirestore(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching appointments: $e');
      throw e;
    }
  }

  // Récupérer les rendez-vous d'une clinique spécifique (version sécurisée)
  static Stream<List<Appointment>> getClinicAppointments(String clinicName) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return Stream.value([]);
      }

      print('=== GETTING CLINIC APPOINTMENTS ===');
      print('Clinic name: "$clinicName"');
      print('User ID: ${user.uid}');
      
      // Récupérer d'abord le nom exact de la clinique depuis Firebase
      return _firestore
          .collection('clinics')
          .doc(user.uid)
          .snapshots()
          .asyncMap((clinicDoc) async {
        String exactClinicName = clinicName;
        
        if (clinicDoc.exists) {
          final clinicData = clinicDoc.data()!;
          final firebaseClinicName = clinicData['name'] ?? '';
          if (firebaseClinicName.isNotEmpty) {
            exactClinicName = firebaseClinicName;
            print('Using exact clinic name from Firebase: "$exactClinicName"');
          }
        }
        
        // Récupérer les rendez-vous avec le nom exact de la clinique
        final snapshot = await _firestore
            .collection('appointments')
            .where('hospitalName', isEqualTo: exactClinicName)
            .orderBy('appointmentDate', descending: false)
            .orderBy('appointmentTime', descending: false)
            .get();
            
        print('Found ${snapshot.docs.length} appointments for clinic "$exactClinicName"');
        final appointments = snapshot.docs.map((doc) {
          final appointment = Appointment.fromFirestore(doc.data(), doc.id);
          print('Appointment: ${appointment.patientName} - ${appointment.hospitalName} - ${appointment.appointmentDate}');
          return appointment;
        }).toList();
        return appointments;
      });
    } catch (e) {
      print('Error fetching clinic appointments: $e');
      return Stream.value([]);
    }
  }

  // Récupérer les rendez-vous à venir d'une clinique (prochains 7 jours) - version simplifiée sans index
  static Stream<List<Appointment>> getClinicUpcomingAppointments(String clinicName) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return Stream.value([]);
      }

      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      print('=== GETTING CLINIC UPCOMING APPOINTMENTS ===');
      print('Clinic name: "$clinicName"');
      print('User ID: ${user.uid}');
      print('Date range: ${now.toIso8601String()} to ${nextWeek.toIso8601String()}');

      // Récupérer d'abord le nom exact de la clinique depuis Firebase
      return _firestore
          .collection('clinics')
          .doc(user.uid)
          .get()
          .asStream()
          .asyncMap((clinicDoc) async {
            String exactClinicName = clinicName;
            if (clinicDoc.exists) {
              final clinicData = clinicDoc.data()!;
              exactClinicName = clinicData['name'] ?? clinicName;
              print('Using exact clinic name from Firebase: "$exactClinicName"');
            }

            // Requête simple sans index - récupérer tous les rendez-vous
            final snapshot = await _firestore
          .collection('appointments')
                .get();
            
            final allAppointments = snapshot.docs.map((doc) {
              try {
                final data = doc.data();
                return Appointment(
                  id: doc.id,
                  patientId: data['patientId'] ?? '',
                  patientName: data['patientName'] ?? '',
                  patientEmail: data['patientEmail'] ?? '',
                  patientPhone: data['patientPhone'] ?? '',
                  hospitalName: data['hospitalName'] ?? '',
                  hospitalImage: data['hospitalImage'] ?? '',
                  hospitalLocation: data['hospitalLocation'] ?? '',
                  department: data['department'] ?? '',
                  appointmentDate: data['appointmentDate']?.toDate() ?? DateTime.now(),
                  appointmentTime: data['appointmentTime'] ?? '',
                  reasonOfBooking: data['reasonOfBooking'] ?? data['symptoms'] ?? '',
                  status: data['status'] ?? 'pending',
                  createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
                  updatedAt: data['updatedAt']?.toDate(),
                );
              } catch (e) {
                print('Error parsing appointment ${doc.id}: $e');
                return null;
              }
            }).where((appointment) => appointment != null).cast<Appointment>().toList();

            // Filtrer les rendez-vous de cette clinique à venir (prochains 7 jours) avec statut pending ou confirmed
            final upcomingAppointments = allAppointments.where((appointment) {
              final isThisClinic = appointment.hospitalName == exactClinicName;
              final isUpcoming = appointment.appointmentDate.isAfter(now) && 
                               appointment.appointmentDate.isBefore(nextWeek);
              final hasValidStatus = appointment.status == 'pending' || 
                                   appointment.status == 'confirmed';
              return isThisClinic && isUpcoming && hasValidStatus;
            }).toList();

            // Trier par date et heure
            upcomingAppointments.sort((a, b) {
              final dateComparison = a.appointmentDate.compareTo(b.appointmentDate);
              if (dateComparison != 0) return dateComparison;
              return a.appointmentTime.compareTo(b.appointmentTime);
            });

            // Limiter à 3 rendez-vous maximum
            final limitedAppointments = upcomingAppointments.take(3).toList();

            print('Found ${allAppointments.length} total appointments');
            print('Found ${upcomingAppointments.length} upcoming appointments for clinic "$exactClinicName"');
            print('Returning ${limitedAppointments.length} limited appointments');

            return limitedAppointments;
          })
          .handleError((error) {
            print('Error fetching clinic data: $error');
            return <Appointment>[];
          });
    } catch (e) {
      print('Error in getClinicUpcomingAppointments: $e');
      return Stream.value([]);
    }
  }

  // Récupérer les rendez-vous d'aujourd'hui pour une clinique
  static Stream<List<Appointment>> getClinicTodayAppointments(String clinicName) {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return Stream.value([]);
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      print('=== GETTING CLINIC TODAY APPOINTMENTS ===');
      print('Clinic name: "$clinicName"');
      print('User ID: ${user.uid}');
      print('Today: ${today.toIso8601String()}');

      // Récupérer d'abord le nom exact de la clinique depuis Firebase
      return _firestore
          .collection('clinics')
          .doc(user.uid)
          .snapshots()
          .asyncMap((clinicDoc) async {
        String exactClinicName = clinicName;
        
        if (clinicDoc.exists) {
          final clinicData = clinicDoc.data()!;
          final firebaseClinicName = clinicData['name'] ?? '';
          if (firebaseClinicName.isNotEmpty) {
            exactClinicName = firebaseClinicName;
            print('Using exact clinic name from Firebase: "$exactClinicName"');
          }
        }

        final snapshot = await _firestore
            .collection('appointments')
            .where('hospitalName', isEqualTo: exactClinicName)
            .where('appointmentDate', isGreaterThanOrEqualTo: today)
            .where('appointmentDate', isLessThan: tomorrow)
          .orderBy('appointmentDate', descending: false)
          .orderBy('appointmentTime', descending: false)
            .get();
            
        print('Found ${snapshot.docs.length} today appointments for clinic "$exactClinicName"');
        
        final appointments = snapshot.docs.map((doc) {
          return Appointment.fromFirestore(doc.data(), doc.id);
        }).toList();
        
        // Trier par heure
        appointments.sort((a, b) => a.appointmentTime.compareTo(b.appointmentTime));
        
        return appointments;
      });
    } catch (e) {
      print('Error fetching clinic today appointments: $e');
      return Stream.value([]);
    }
  }

  // Récupérer les rendez-vous à venir (prochains 7 jours) - version simplifiée sans index
  static Stream<List<Appointment>> getUpcomingAppointments() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return Stream.value([]);
      }

      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      print('=== GETTING PATIENT UPCOMING APPOINTMENTS ===');
      print('User ID: ${user.uid}');
      print('Date range: ${now.toIso8601String()} to ${nextWeek.toIso8601String()}');

      // Requête simple sans index - récupérer tous les rendez-vous du patient
      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
            final allAppointments = snapshot.docs.map((doc) {
              try {
                final data = doc.data();
                return Appointment(
                  id: doc.id,
                  patientId: data['patientId'] ?? '',
                  patientName: data['patientName'] ?? '',
                  patientEmail: data['patientEmail'] ?? '',
                  patientPhone: data['patientPhone'] ?? '',
                  hospitalName: data['hospitalName'] ?? '',
                  hospitalImage: data['hospitalImage'] ?? '',
                  hospitalLocation: data['hospitalLocation'] ?? '',
                  department: data['department'] ?? '',
                  appointmentDate: data['appointmentDate']?.toDate() ?? DateTime.now(),
                  appointmentTime: data['appointmentTime'] ?? '',
                  reasonOfBooking: data['reasonOfBooking'] ?? data['symptoms'] ?? '',
                  status: data['status'] ?? 'pending',
                  createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
                  updatedAt: data['updatedAt']?.toDate(),
                );
              } catch (e) {
                print('Error parsing appointment ${doc.id}: $e');
                return null;
              }
            }).where((appointment) => appointment != null).cast<Appointment>().toList();

            // Filtrer les rendez-vous à venir (prochains 7 jours) avec statut pending ou confirmed
            final upcomingAppointments = allAppointments.where((appointment) {
              final isUpcoming = appointment.appointmentDate.isAfter(now) && 
                               appointment.appointmentDate.isBefore(nextWeek);
              final hasValidStatus = appointment.status == 'pending' || 
                                   appointment.status == 'confirmed';
              return isUpcoming && hasValidStatus;
        }).toList();

            // Trier par date et heure
            upcomingAppointments.sort((a, b) {
              final dateComparison = a.appointmentDate.compareTo(b.appointmentDate);
              if (dateComparison != 0) return dateComparison;
              return a.appointmentTime.compareTo(b.appointmentTime);
            });

            // Limiter à 2 rendez-vous maximum
            final limitedAppointments = upcomingAppointments.take(2).toList();

            print('Found ${allAppointments.length} total appointments');
            print('Found ${upcomingAppointments.length} upcoming appointments');
            print('Returning ${limitedAppointments.length} limited appointments');

            return limitedAppointments;
          })
          .handleError((error) {
            print('Error in getUpcomingAppointments: $error');
            return <Appointment>[];
      });
    } catch (e) {
      print('Error in getUpcomingAppointments: $e');
      return Stream.value([]);
    }
  }

  // Mettre à jour le statut d'un rendez-vous
  static Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      print('=== UPDATING APPOINTMENT STATUS ===');
      print('Appointment ID: $appointmentId');
      print('New Status: $status');
      
      // Récupérer le rendez-vous actuel pour vérifier l'ancien statut
      final currentAppointment = await getAppointmentById(appointmentId);
      if (currentAppointment != null) {
        print('Current status: ${currentAppointment.status}');
        print('Patient ID: ${currentAppointment.patientId}');
        print('Patient Name: ${currentAppointment.patientName}');
        print('Hospital: ${currentAppointment.hospitalName}');
      }
      
      // Mettre à jour le statut dans Firebase
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✓ Appointment status updated successfully in Firebase');
      print('✓ Status changed from "${currentAppointment?.status}" to "$status"');
      
      // Créer des notifications selon le statut
      if (currentAppointment != null) {
        try {
          // Notification pour le patient
          if (currentAppointment.patientId.isNotEmpty) {
            String notificationTitle;
            String notificationMessage;
            NotificationType notificationType;
            
            if (status == 'confirmed') {
              notificationTitle = 'Appointment Confirmed ✅';
              notificationMessage = 'Your appointment on ${DateFormat('MMM dd, yyyy').format(currentAppointment.appointmentDate)} at ${currentAppointment.hospitalName} has been confirmed by the clinic.';
              notificationType = NotificationType.appointmentConfirmed;
            } else if (status == 'cancelled') {
              notificationTitle = 'Appointment Cancelled ❌';
              notificationMessage = 'Your appointment on ${DateFormat('MMM dd, yyyy').format(currentAppointment.appointmentDate)} at ${currentAppointment.hospitalName} has been cancelled by the clinic.';
              notificationType = NotificationType.appointmentDeclined;
            } else {
              notificationTitle = 'Appointment Status Updated';
              notificationMessage = 'Your appointment status has been updated to: $status';
              notificationType = NotificationType.appointmentConfirmed;
            }
            
            await NotificationService.createCustomNotification(
              patientId: currentAppointment.patientId,
              title: notificationTitle,
              message: notificationMessage,
              type: notificationType,
              hospitalName: currentAppointment.hospitalName,
              department: currentAppointment.department,
              appointmentDate: currentAppointment.appointmentDate,
              appointmentTime: currentAppointment.appointmentTime,
            );
            print('✓ Patient notification created');
          }
          
          // Notification pour la clinique
          final clinicId = await _getClinicIdByName(currentAppointment.hospitalName);
          if (clinicId != null) {
            String clinicNotificationTitle;
            String clinicNotificationMessage;
            
            if (status == 'confirmed') {
              clinicNotificationTitle = 'Appointment Confirmed 📅';
              clinicNotificationMessage = 'You have confirmed the appointment for ${currentAppointment.patientName} on ${DateFormat('MMM dd, yyyy').format(currentAppointment.appointmentDate)}.';
            } else if (status == 'cancelled') {
              clinicNotificationTitle = 'Appointment Cancelled 📅';
              clinicNotificationMessage = 'You have cancelled the appointment for ${currentAppointment.patientName} on ${DateFormat('MMM dd, yyyy').format(currentAppointment.appointmentDate)}.';
            } else {
              clinicNotificationTitle = 'Appointment Status Updated 📅';
              clinicNotificationMessage = 'Appointment status for ${currentAppointment.patientName} has been updated to: $status';
            }
            
            await NotificationService.createClinicNotification(
              clinicId: clinicId,
              title: clinicNotificationTitle,
              message: clinicNotificationMessage,
              appointmentId: appointmentId,
              hospitalName: currentAppointment.hospitalName,
              department: currentAppointment.department,
              appointmentDate: currentAppointment.appointmentDate,
              appointmentTime: currentAppointment.appointmentTime,
            );
            print('✓ Clinic notification created');
          }
    } catch (e) {
          print('Error creating notifications: $e');
        }
      }
      
      print('=== STATUS UPDATE COMPLETED ===');
      
      // Attendre un peu pour s'assurer que Firebase a propagé les changements
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      print('❌ Error updating appointment status: $e');
      throw e;
    }
  }

  // Supprimer un rendez-vous
  static Future<void> deleteAppointment(String appointmentId) async {
    try {
      print('=== DELETING APPOINTMENT ===');
      print('Appointment ID: $appointmentId');
      
      // Vérifier que le rendez-vous existe
      final appointmentDoc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (!appointmentDoc.exists) {
        throw Exception('Rendez-vous non trouvé');
      }
      
      final appointmentData = appointmentDoc.data()!;
      final patientName = appointmentData['patientName'] ?? 'Unknown';
      final hospitalName = appointmentData['hospitalName'] ?? 'Unknown';
      final appointmentDate = appointmentData['appointmentDate'] != null 
          ? (appointmentData['appointmentDate'] as Timestamp).toDate() 
          : DateTime.now();
      
      print('Deleting appointment for patient: $patientName');
      print('Hospital: $hospitalName');
      print('Date: $appointmentDate');
      
      // Supprimer le rendez-vous
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .delete();
      
      print('✓ Appointment deleted successfully');
      
      // Créer une notification pour informer le patient (optionnel)
      try {
        final patientId = appointmentData['patientId'] ?? '';
        if (patientId.isNotEmpty) {
          await NotificationService.createCustomNotification(
            patientId: patientId,
            title: 'Rendez-vous annulé',
            message: 'Votre rendez-vous du ${DateFormat('dd/MM/yyyy').format(appointmentDate)} à $hospitalName a été annulé par la clinique.',
            type: NotificationType.appointmentDeclined,
            hospitalName: hospitalName,
            department: appointmentData['department'] ?? '',
            appointmentDate: appointmentDate,
            appointmentTime: appointmentData['appointmentTime'] ?? '',
          );
          print('✓ Notification sent to patient');
        }
      } catch (e) {
        print('Error sending notification to patient: $e');
      }
      
    } catch (e) {
      print('Error deleting appointment: $e');
      throw e;
    }
  }

  // Récupérer un rendez-vous par ID
  static Future<Appointment?> getAppointmentById(String appointmentId) async {
    try {
      final doc = await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .get();
      
      if (doc.exists) {
        return Appointment.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching appointment by ID: $e');
      throw e;
    }
  }

  // Récupérer tous les rendez-vous (pour déboguer)
  static Stream<List<Appointment>> getAllAppointments() {
    try {
      print('Fetching ALL appointments from Firebase');
      return _firestore
          .collection('appointments')
          .snapshots()
          .map((snapshot) {
        print('Found ${snapshot.docs.length} total appointments in Firebase');
        final appointments = snapshot.docs.map((doc) {
          try {
            final appointment = Appointment.fromFirestore(doc.data(), doc.id);
            print('All appointments - Patient: ${appointment.patientName}, Hospital: "${appointment.hospitalName}", Date: ${appointment.appointmentDate}, Status: ${appointment.status}');
            return appointment;
          } catch (e) {
            print('Error parsing appointment ${doc.id}: $e');
            print('Raw data: ${doc.data()}');
            // Retourner un rendez-vous par défaut en cas d'erreur
            return Appointment(
              id: doc.id,
              patientId: doc.data()['patientId'] ?? '',
              patientName: doc.data()['patientName'] ?? 'Unknown',
              patientEmail: doc.data()['patientEmail'] ?? '',
              patientPhone: doc.data()['patientPhone'] ?? '',
              hospitalName: doc.data()['hospitalName'] ?? '',
              hospitalImage: doc.data()['hospitalImage'] ?? '',
              hospitalLocation: doc.data()['hospitalLocation'] ?? '',
              department: doc.data()['department'] ?? 'General',
              appointmentDate: (doc.data()['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              appointmentTime: doc.data()['appointmentTime'] ?? '',
              reasonOfBooking: doc.data()['reasonOfBooking'] ?? doc.data()['symptoms'] ?? '',
              status: doc.data()['status'] ?? 'pending',
              createdAt: (doc.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }
        }).toList();
        
        // Trier par date de création (plus récent en premier)
        appointments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return appointments;
      });
    } catch (e) {
      print('Error fetching all appointments: $e');
      throw e;
    }
  }

  // Forcer la mise à jour des noms de cliniques dans tous les rendez-vous
  static Future<void> forceUpdateClinicNames() async {
    try {
      print('=== FORCE UPDATING CLINIC NAMES ===');
      
      // Récupérer tous les rendez-vous
      final appointmentsSnapshot = await _firestore.collection('appointments').get();
      print('Found ${appointmentsSnapshot.docs.length} total appointments');
      
      // Récupérer tous les noms de cliniques
      final clinicNames = await getAllClinicNames();
      print('Available clinic names: $clinicNames');
      
      for (final appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data();
        final currentHospitalName = appointmentData['hospitalName'] ?? '';
        
        print('Processing appointment ${appointmentDoc.id} with hospital name: "$currentHospitalName"');
        
        // Chercher une correspondance avec les noms de cliniques
        String? bestMatch;
        for (final clinicName in clinicNames) {
          if (_namesMatch(currentHospitalName, clinicName)) {
            bestMatch = clinicName;
            print('Found match: "$currentHospitalName" -> "$clinicName"');
            break;
          }
        }
        
        // Si aucune correspondance trouvée, essayer avec le nom d'affichage de l'utilisateur
        if (bestMatch == null) {
          final user = _auth.currentUser;
          if (user != null && user.displayName != null) {
            final displayName = user.displayName!;
            if (_namesMatch(currentHospitalName, displayName)) {
              bestMatch = displayName;
              print('Found match with display name: "$currentHospitalName" -> "$displayName"');
            }
          }
        }
        
        // Mettre à jour le rendez-vous si une correspondance est trouvée
        if (bestMatch != null && bestMatch != currentHospitalName) {
          await appointmentDoc.reference.update({
            'hospitalName': bestMatch,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Updated appointment ${appointmentDoc.id} from "$currentHospitalName" to "$bestMatch"');
        } else {
          print('No match found for appointment ${appointmentDoc.id}');
        }
      }
      
      print('=== FORCE UPDATE COMPLETED ===');
    } catch (e) {
      print('Error force updating clinic names: $e');
      throw e;
    }
  }

  // Vérifier si deux noms correspondent (méthode utilitaire)
  static bool _namesMatch(String name1, String name2) {
    if (name1.isEmpty || name2.isEmpty) return false;
    
    final normalized1 = name1.toLowerCase().trim();
    final normalized2 = name2.toLowerCase().trim();
    
    // Correspondance exacte
    if (normalized1 == normalized2) return true;
    
    // Correspondance partielle
    if (normalized1.contains(normalized2) || normalized2.contains(normalized1)) return true;
    
    // Correspondance avec des mots clés communs
    final keywords1 = normalized1.split(' ');
    final keywords2 = normalized2.split(' ');
    
    for (final keyword1 in keywords1) {
      for (final keyword2 in keywords2) {
        if (keyword1.length > 3 && keyword2.length > 3 && keyword1 == keyword2) {
          return true;
        }
      }
    }
    
    return false;
  }

  // Récupérer et corriger les noms des patients dans les rendez-vous
  static Future<void> fixPatientNames() async {
    try {
      print('=== FIXING PATIENT NAMES ===');
      
      // Récupérer tous les rendez-vous
      final appointmentsSnapshot = await _firestore.collection('appointments').get();
      print('Found ${appointmentsSnapshot.docs.length} appointments to check');
      
      for (final appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data();
        final patientId = appointmentData['patientId'] ?? '';
        final currentPatientName = appointmentData['patientName'] ?? '';
        
        print('Processing appointment ${appointmentDoc.id}');
        print('Patient ID: $patientId');
        print('Current patient name: "$currentPatientName"');
        
        // Vérifier si le nom du patient est vide ou "Unknown"
        if (patientId.isNotEmpty && (currentPatientName.isEmpty || 
            currentPatientName == 'Unknown' || 
            currentPatientName == 'Patient Name Not Available')) {
          
          // Récupérer les informations du patient depuis la collection users
          try {
            final userDoc = await _firestore.collection('users').doc(patientId).get();
            
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final realPatientName = userData['name'] ?? userData['fullName'] ?? '';
              
              if (realPatientName.isNotEmpty && realPatientName != currentPatientName) {
                // Mettre à jour le nom du patient dans le rendez-vous
                await appointmentDoc.reference.update({
                  'patientName': realPatientName,
                  'patientEmail': userData['email'] ?? appointmentData['patientEmail'] ?? '',
                  'patientPhone': userData['phone'] ?? userData['phoneNumber'] ?? appointmentData['patientPhone'] ?? '',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                print('✓ Updated patient name from "$currentPatientName" to "$realPatientName"');
              } else {
                print('✗ No valid patient name found in user document');
              }
            } else {
              print('✗ User document not found for patient ID: $patientId');
            }
          } catch (e) {
            print('Error fetching user data for patient $patientId: $e');
          }
        } else {
          print('✓ Patient name already correct: "$currentPatientName"');
        }
      }
      
      print('=== PATIENT NAMES FIX COMPLETED ===');
    } catch (e) {
      print('Error fixing patient names: $e');
      throw e;
    }
  }

  // Récupérer le nom d'un patient par son ID
  static Future<String> getPatientName(String patientId) async {
    try {
      if (patientId.isEmpty) return 'Unknown Patient';
      
      final userDoc = await _firestore.collection('users').doc(patientId).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final patientName = userData['name'] ?? userData['fullName'] ?? '';
        
        if (patientName.isNotEmpty) {
          print('Found patient name for ID $patientId: "$patientName"');
          return patientName;
        }
      }
      
      print('No patient name found for ID: $patientId');
      return 'Unknown Patient';
    } catch (e) {
      print('Error getting patient name for ID $patientId: $e');
      return 'Unknown Patient';
    }
  }

  // Améliorer la création de rendez-vous avec vérification du nom du patient
  static Future<String> createAppointmentWithPatientCheck(Appointment appointment) async {
    try {
      print('=== CREATING APPOINTMENT WITH PATIENT CHECK ===');
      print('Original patient name: "${appointment.patientName}"');
      print('Patient ID: ${appointment.patientId}');
      
      // Vérifier et corriger le nom du patient si nécessaire
      String finalPatientName = appointment.patientName;
      if (appointment.patientName.isEmpty || 
          appointment.patientName == 'Unknown' || 
          appointment.patientName == 'Patient Name Not Available') {
        
        finalPatientName = await getPatientName(appointment.patientId);
        print('Corrected patient name: "$finalPatientName"');
      }
      
      // Créer une copie du rendez-vous avec le nom corrigé
      final correctedAppointment = Appointment(
        id: appointment.id,
        patientId: appointment.patientId,
        patientName: finalPatientName,
        patientEmail: appointment.patientEmail,
        patientPhone: appointment.patientPhone,
        hospitalName: appointment.hospitalName,
        hospitalImage: appointment.hospitalImage,
        hospitalLocation: appointment.hospitalLocation,
        department: appointment.department,
        appointmentDate: appointment.appointmentDate,
        appointmentTime: appointment.appointmentTime,
        reasonOfBooking: appointment.reasonOfBooking,
        status: appointment.status,
        createdAt: appointment.createdAt,
      );

      // Utiliser la méthode existante pour créer le rendez-vous
      return await createAppointment(correctedAppointment);
    } catch (e) {
      print('Error creating appointment with patient check: $e');
      throw e;
    }
  }

  // Corriger rapidement les noms des patients dans les rendez-vous (version optimisée)
  static Future<void> quickFixPatientNames() async {
    try {
      print('=== QUICK FIXING PATIENT NAMES ===');
      
      // Récupérer seulement les rendez-vous avec des noms de patients problématiques
      final appointmentsSnapshot = await _firestore
          .collection('appointments')
          .where('patientName', whereIn: ['', 'Unknown', 'Patient Name Not Available', 'Unknown Patient'])
          .get();
      
      print('Found ${appointmentsSnapshot.docs.length} appointments with problematic patient names');
      
      if (appointmentsSnapshot.docs.isEmpty) {
        print('✓ No problematic patient names found');
        return;
      }
      
      int fixedCount = 0;
      
      for (final appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data();
        final patientId = appointmentData['patientId'] ?? '';
        final currentPatientName = appointmentData['patientName'] ?? '';
        
        if (patientId.isNotEmpty) {
          try {
            // Récupérer les informations du patient depuis la collection users
            final userDoc = await _firestore.collection('users').doc(patientId).get();
            
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final realPatientName = userData['name'] ?? userData['fullName'] ?? '';
              
              if (realPatientName.isNotEmpty && realPatientName != currentPatientName) {
                // Mettre à jour le nom du patient dans le rendez-vous
                await appointmentDoc.reference.update({
                  'patientName': realPatientName,
                  'patientEmail': userData['email'] ?? appointmentData['patientEmail'] ?? '',
                  'patientPhone': userData['phone'] ?? userData['phoneNumber'] ?? appointmentData['patientPhone'] ?? '',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                print('✓ Fixed patient name: "$currentPatientName" -> "$realPatientName"');
                fixedCount++;
              }
            }
          } catch (e) {
            print('Error fixing patient name for ID $patientId: $e');
          }
        }
      }
      
      print('=== QUICK FIX COMPLETED: $fixedCount names fixed ===');
    } catch (e) {
      print('Error in quick fix patient names: $e');
    }
  }

  // Synchroniser les noms de cliniques et nettoyer les données
  static Future<void> syncClinicNames() async {
    try {
      print('=== SYNCING CLINIC NAMES ===');
      
      // Récupérer tous les documents de cliniques
      final clinicDocs = await _firestore.collection('clinics').get();
      print('Found ${clinicDocs.docs.length} clinic documents');
      
      // Créer un map des noms de cliniques par ID utilisateur
      final clinicNames = <String, String>{};
      for (final doc in clinicDocs.docs) {
        final data = doc.data();
        final name = data['name'] ?? '';
        if (name.isNotEmpty) {
          clinicNames[doc.id] = name;
          print('Clinic ${doc.id}: "$name"');
        }
      }
      
      // Récupérer tous les rendez-vous
      final appointmentDocs = await _firestore.collection('appointments').get();
      print('Found ${appointmentDocs.docs.length} appointment documents');
      
      // Mettre à jour les noms de cliniques dans les rendez-vous
      int updatedCount = 0;
      for (final doc in appointmentDocs.docs) {
        final data = doc.data();
        final userId = data['userId'] ?? '';
        final currentHospitalName = data['hospitalName'] ?? '';
        final expectedHospitalName = clinicNames[userId];
        
        if (expectedHospitalName != null && 
            expectedHospitalName.isNotEmpty && 
            currentHospitalName != expectedHospitalName) {
          
          print('Updating appointment ${doc.id}: "$currentHospitalName" -> "$expectedHospitalName"');
          
          await _firestore
              .collection('appointments')
              .doc(doc.id)
              .update({'hospitalName': expectedHospitalName});
          
          updatedCount++;
        }
      }
      
      print('Updated $updatedCount appointment documents');
      
    } catch (e) {
      print('Error syncing clinic names: $e');
    }
  }

  // Vérifier le type d'utilisateur (patient ou clinique)
  static Future<String?> getUserType(String userId) async {
    try {
      print('=== CHECKING USER TYPE ===');
      print('User ID: $userId');
      
      // Vérifier d'abord si l'utilisateur est une clinique
      final clinicDoc = await _firestore
          .collection('clinics')
          .doc(userId)
          .get();
      
      if (clinicDoc.exists) {
        print('✓ User is a CLINIC');
        return 'clinic';
      }
      
      // Vérifier si l'utilisateur est un patient dans la collection 'patients'
      final patientDoc = await _firestore
          .collection('patients')
          .doc(userId)
          .get();
      
      if (patientDoc.exists) {
        print('✓ User is a PATIENT (from patients collection)');
        return 'patient';
      }
      
      // Vérifier si l'utilisateur est un patient dans la collection 'users'
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final role = userData['role'] ?? '';
        
        if (role == 'patient') {
          print('✓ User is a PATIENT (from users collection)');
          return 'patient';
        } else if (role == 'clinic') {
          print('✓ User is a CLINIC (from users collection)');
          return 'clinic';
        }
      }
      
      // Si aucune collection n'existe, vérifier les rendez-vous pour déterminer le type
      final appointmentsQuery = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (appointmentsQuery.docs.isNotEmpty) {
        print('✓ User is a PATIENT (found in appointments)');
        return 'patient';
      }
      
      // Vérifier si l'utilisateur a des rendez-vous en tant que clinique
      final clinicAppointmentsQuery = await _firestore
          .collection('appointments')
          .where('hospitalName', isNotEqualTo: '')
          .get();
      
      // Chercher dans les résultats si l'utilisateur correspond à une clinique
      for (final doc in clinicAppointmentsQuery.docs) {
        final data = doc.data();
        final hospitalName = data['hospitalName'] ?? '';
        
        // Vérifier si l'utilisateur correspond à cette clinique
        final clinicQuery = await _firestore
            .collection('clinics')
            .where('name', isEqualTo: hospitalName)
            .get();
        
        if (clinicQuery.docs.isNotEmpty) {
          final clinicId = clinicQuery.docs.first.id;
          if (clinicId == userId) {
            print('✓ User is a CLINIC (found in appointments)');
            return 'clinic';
          }
        }
      }
      
      print('⚠ User type UNKNOWN');
      return null;
    } catch (e) {
      print('Error checking user type: $e');
      return null;
    }
  }

  // Récupérer la durée des rendez-vous configurée par une clinique
  static Future<int> getClinicMeetingDuration(String clinicName) async {
    try {
      print('=== GETTING CLINIC MEETING DURATION ===');
      print('Clinic name: "$clinicName"');
      
      // Récupérer tous les noms de cliniques existants
      final clinicNames = await getAllClinicNames();
      print('Available clinic names: $clinicNames');
      
      // Chercher une correspondance exacte
      String finalClinicName = clinicName;
      for (final name in clinicNames) {
        if (name.toLowerCase().trim() == clinicName.toLowerCase().trim()) {
          finalClinicName = name;
          print('Exact match found: using "$name"');
          break;
        }
      }
      
      // Si aucune correspondance exacte, essayer une correspondance partielle
      if (finalClinicName == clinicName) {
        for (final name in clinicNames) {
          if (name.toLowerCase().contains(clinicName.toLowerCase()) ||
              clinicName.toLowerCase().contains(name.toLowerCase())) {
            finalClinicName = name;
            print('Partial match found: using "$name"');
            break;
          }
        }
      }
      
      print('Final clinic name: "$finalClinicName"');
      
      // Récupérer la durée configurée par la clinique
      final clinicDocs = await _firestore
          .collection('clinics')
          .where('name', isEqualTo: finalClinicName)
          .get();
      
      if (clinicDocs.docs.isNotEmpty) {
        final data = clinicDocs.docs.first.data();
        final duration = data['meetingDuration'] ?? 30; // Default 30 minutes
        print('✓ Found clinic meeting duration: $duration minutes');
        return duration;
      }
      
      // Si pas de correspondance exacte, chercher une correspondance partielle
      final allClinicDocs = await _firestore.collection('clinics').get();
      
      for (final doc in allClinicDocs.docs) {
        final data = doc.data();
        final name = data['name'] ?? '';
        
        if (name.toLowerCase().contains(clinicName.toLowerCase()) ||
            clinicName.toLowerCase().contains(name.toLowerCase())) {
          final duration = data['meetingDuration'] ?? 30; // Default 30 minutes
          print('✓ Found clinic meeting duration (partial match): $duration minutes');
          return duration;
        }
      }
      
      print('⚠ No clinic found, using default duration: 30 minutes');
      return 30; // Default duration
    } catch (e) {
      print('Error getting clinic meeting duration: $e');
      return 30; // Default duration on error
    }
  }

  // Récupérer l'horaire d'une clinique
  static Future<ClinicSchedule?> getClinicSchedule(String clinicId) async {
    try {
      print('=== GETTING CLINIC SCHEDULE ===');
      print('Clinic ID: $clinicId');
      
      final scheduleDocs = await _firestore
          .collection('clinic_schedules')
          .where('clinicId', isEqualTo: clinicId)
          .get();
      
      if (scheduleDocs.docs.isNotEmpty) {
        final doc = scheduleDocs.docs.first;
        final schedule = ClinicSchedule.fromFirestore(doc.data(), doc.id);
        print('✓ Found clinic schedule for clinic: $clinicId');
        return schedule;
      }
      
      print('⚠ No schedule found for clinic: $clinicId');
      return null;
    } catch (e) {
      print('Error getting clinic schedule: $e');
      return null;
    }
  }

  // Créer ou mettre à jour l'horaire d'une clinique
  static Future<void> saveClinicSchedule(ClinicSchedule schedule) async {
    try {
      print('=== SAVING CLINIC SCHEDULE ===');
      print('Clinic ID: ${schedule.clinicId}');
      
      // Vérifier si un horaire existe déjà
      final existingDocs = await _firestore
          .collection('clinic_schedules')
          .where('clinicId', isEqualTo: schedule.clinicId)
          .get();
      
      if (existingDocs.docs.isNotEmpty) {
        // Mettre à jour l'horaire existant
        await _firestore
            .collection('clinic_schedules')
            .doc(existingDocs.docs.first.id)
            .update(schedule.toFirestore());
        print('✓ Updated existing clinic schedule');
      } else {
        // Créer un nouvel horaire
        await _firestore
            .collection('clinic_schedules')
            .add(schedule.toFirestore());
        print('✓ Created new clinic schedule');
      }
    } catch (e) {
      print('Error saving clinic schedule: $e');
      throw e;
    }
  }

  // Générer les créneaux horaires disponibles pour une date donnée
  static Future<List<String>> getAvailableTimeSlots(String clinicId, DateTime date) async {
    try {
      print('=== GETTING AVAILABLE TIME SLOTS ===');
      print('Clinic ID: $clinicId');
      print('Date: ${date.toIso8601String()}');
      
      // Récupérer l'horaire de la clinique
      final schedule = await getClinicSchedule(clinicId);
      if (schedule == null) {
        print('⚠ No schedule found, using default slots');
        return _generateDefaultTimeSlots();
      }
      
      // Obtenir le jour de la semaine
      final dayName = _getDayName(date.weekday);
      final daySchedule = schedule.weeklySchedule[dayName];
      
      if (daySchedule == null || !daySchedule.isWorkingDay) {
        print('⚠ Not a working day: $dayName');
        return [];
      }
      
      // Générer les créneaux pour ce jour
      final slots = daySchedule.generateTimeSlots(schedule.defaultSlotDuration);
      print('✓ Generated ${slots.length} time slots for $dayName');
      
      // Filtrer les créneaux déjà réservés
      final bookedSlots = await _getBookedTimeSlots(clinicId, date);
      final availableSlots = slots.where((slot) => !bookedSlots.contains(slot)).toList();
      
      print('✓ Found ${availableSlots.length} available slots out of ${slots.length} total slots');
      return availableSlots;
    } catch (e) {
      print('Error getting available time slots: $e');
      return _generateDefaultTimeSlots();
    }
  }

  // Obtenir les créneaux déjà réservés pour une date
  static Future<List<String>> _getBookedTimeSlots(String clinicId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final appointments = await _firestore
          .collection('appointments')
          .where('clinicId', isEqualTo: clinicId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
      
      final List<String> bookedSlots = [];
      for (final doc in appointments.docs) {
        final data = doc.data();
        final time = data['appointmentTime'] ?? '';
        if (time.isNotEmpty) {
          bookedSlots.add(time);
        }
      }
      
      return bookedSlots;
    } catch (e) {
      print('Error getting booked time slots: $e');
      return [];
    }
  }

  // Générer des créneaux par défaut (8h00-18h00, 30 minutes)
  static List<String> _generateDefaultTimeSlots() {
    List<String> slots = [];
    for (int hour = 8; hour < 18; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        slots.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }

  // Obtenir le nom du jour en anglais
  static String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  // Formater l'heure pour l'affichage (ex: 10:00 -> 10h00)
  static String formatTimeForDisplay(String time) {
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
  static String formatTimeWithPeriod(String time) {
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
} 