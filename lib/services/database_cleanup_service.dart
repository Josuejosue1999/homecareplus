import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'appointment_service.dart';

class DatabaseCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Nettoyer et corriger la base de données
  static Future<void> cleanupDatabase() async {
    try {
      print('=== STARTING DATABASE CLEANUP ===');
      
      // 1. Créer des documents de cliniques pour tous les utilisateurs
      await _createMissingClinicDocuments();
      
      // 2. Corriger les noms de cliniques dans les rendez-vous
      await _fixAppointmentClinicNames();
      
      // 3. Ajouter des champs manquants aux rendez-vous
      await _addMissingFieldsToAppointments();
      
      // 4. Nettoyer les documents vides ou corrompus
      await _cleanupCorruptedDocuments();
      
      print('=== DATABASE CLEANUP COMPLETED ===');
    } catch (e) {
      print('Error during database cleanup: $e');
      throw e;
    }
  }

  // Créer des documents de cliniques manquants
  static Future<void> _createMissingClinicDocuments() async {
    try {
      print('Creating missing clinic documents...');
      
      // Récupérer tous les utilisateurs qui ont des comptes de clinique
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userType = userData['userType'] ?? '';
        
        if (userType == 'clinic' || userType == 'hospital') {
          final userId = userDoc.id;
          final clinicDoc = await _firestore.collection('clinics').doc(userId).get();
          
          if (!clinicDoc.exists) {
            // Créer un document de clinique
            final clinicData = {
              'name': userData['displayName'] ?? userData['name'] ?? 'New Clinic',
              'address': userData['address'] ?? 'Address not set',
              'phone': userData['phone'] ?? 'Phone not set',
              'email': userData['email'] ?? 'email@example.com',
              'specialties': userData['specialties'] ?? ['General Medicine'],
              'description': userData['description'] ?? 'Clinic description not set',
              'imageUrl': userData['imageUrl'] ?? 'https://via.placeholder.com/150',
              'userId': userId,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };
            
            await _firestore.collection('clinics').doc(userId).set(clinicData);
            print('Created clinic document for user: $userId');
          }
        }
      }
    } catch (e) {
      print('Error creating missing clinic documents: $e');
    }
  }

  // Corriger les noms de cliniques dans les rendez-vous
  static Future<void> _fixAppointmentClinicNames() async {
    try {
      print('Fixing appointment clinic names...');
      
      // Récupérer tous les noms de cliniques
      final clinicsSnapshot = await _firestore.collection('clinics').get();
      final clinicNames = clinicsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
        };
      }).where((clinic) => clinic['name'].isNotEmpty).toList();
      
      print('Found ${clinicNames.length} clinics: $clinicNames');
      
      // Récupérer tous les rendez-vous
      final appointmentsSnapshot = await _firestore.collection('appointments').get();
      
      for (final appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data();
        final currentHospitalName = appointmentData['hospitalName'] ?? '';
        
        // Chercher une correspondance
        for (final clinic in clinicNames) {
          final clinicName = clinic['name'] as String;
          
          if (_namesMatch(currentHospitalName, clinicName)) {
            // Mettre à jour le rendez-vous
            await appointmentDoc.reference.update({
              'hospitalName': clinicName,
              'clinicId': clinic['id'],
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('Updated appointment ${appointmentDoc.id} from "$currentHospitalName" to "$clinicName"');
            break;
          }
        }
      }
    } catch (e) {
      print('Error fixing appointment clinic names: $e');
    }
  }

  // Vérifier si deux noms correspondent
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

  // Ajouter des champs manquants aux rendez-vous
  static Future<void> _addMissingFieldsToAppointments() async {
    try {
      print('Adding missing fields to appointments...');
      
      final appointmentsSnapshot = await _firestore.collection('appointments').get();
      
      for (final appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data();
        final updates = <String, dynamic>{};
        
        // Ajouter des champs manquants
        if (!appointmentData.containsKey('status')) {
          updates['status'] = 'pending';
        }
        
        if (!appointmentData.containsKey('createdAt')) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        }
        
        if (!appointmentData.containsKey('updatedAt')) {
          updates['updatedAt'] = FieldValue.serverTimestamp();
        }
        
        if (!appointmentData.containsKey('patientId')) {
          updates['patientId'] = appointmentData['userId'] ?? '';
        }
        
        if (updates.isNotEmpty) {
          await appointmentDoc.reference.update(updates);
          print('Updated appointment ${appointmentDoc.id} with missing fields: $updates');
        }
      }
    } catch (e) {
      print('Error adding missing fields to appointments: $e');
    }
  }

  // Nettoyer les documents corrompus
  static Future<void> _cleanupCorruptedDocuments() async {
    try {
      print('Cleaning up corrupted documents...');
      
      // Nettoyer les rendez-vous sans nom d'hôpital
      final appointmentsWithoutHospital = await _firestore
          .collection('appointments')
          .where('hospitalName', isEqualTo: '')
          .get();
      
      for (final doc in appointmentsWithoutHospital.docs) {
        await doc.reference.delete();
        print('Deleted appointment without hospital name: ${doc.id}');
      }
      
      // Nettoyer les rendez-vous sans patient
      final appointmentsWithoutPatient = await _firestore
          .collection('appointments')
          .where('patientName', isEqualTo: '')
          .get();
      
      for (final doc in appointmentsWithoutPatient.docs) {
        await doc.reference.delete();
        print('Deleted appointment without patient name: ${doc.id}');
      }
      
    } catch (e) {
      print('Error cleaning up corrupted documents: $e');
    }
  }

  // Afficher un rapport de la base de données
  static Future<void> showDatabaseReport() async {
    try {
      print('=== DATABASE REPORT ===');
      
      // Compter les cliniques
      final clinicsSnapshot = await _firestore.collection('clinics').get();
      print('Total clinics: ${clinicsSnapshot.docs.length}');
      
      // Compter les rendez-vous
      final appointmentsSnapshot = await _firestore.collection('appointments').get();
      print('Total appointments: ${appointmentsSnapshot.docs.length}');
      
      // Compter les utilisateurs
      final usersSnapshot = await _firestore.collection('users').get();
      print('Total users: ${usersSnapshot.docs.length}');
      
      // Afficher les noms de cliniques
      final clinicNames = clinicsSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['name'] ?? 'Unknown';
      }).toList();
      print('Clinic names: $clinicNames');
      
      // Afficher les noms d'hôpitaux dans les rendez-vous
      final hospitalNames = appointmentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return data['hospitalName'] ?? 'Unknown';
      }).toSet().toList();
      print('Hospital names in appointments: $hospitalNames');
      
      print('=== END REPORT ===');
    } catch (e) {
      print('Error showing database report: $e');
    }
  }

  // Corriger les noms des patients dans tous les rendez-vous
  static Future<void> fixPatientNames() async {
    try {
      print('=== DATABASE CLEANUP: FIXING PATIENT NAMES ===');
      
      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .get();
      
      print('Found ${appointmentsSnapshot.docs.length} appointments to check');
      
      int fixedCount = 0;
      
      for (final appointmentDoc in appointmentsSnapshot.docs) {
        final appointmentData = appointmentDoc.data();
        final patientId = appointmentData['patientId'] ?? '';
        final currentPatientName = appointmentData['patientName'] ?? '';
        
        // Vérifier si le nom du patient doit être corrigé
        if (patientId.isNotEmpty && (currentPatientName.isEmpty || 
            currentPatientName == 'Unknown' || 
            currentPatientName == 'Patient Name Not Available' ||
            currentPatientName == 'Unknown Patient')) {
          
          try {
            // Récupérer les informations du patient depuis la collection users
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(patientId)
                .get();
            
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
                
                print('✓ Fixed patient name: "$currentPatientName" -> "$realPatientName" (ID: $patientId)');
                fixedCount++;
              } else {
                print('✗ No valid patient name found for ID: $patientId');
              }
            } else {
              print('✗ User document not found for patient ID: $patientId');
            }
          } catch (e) {
            print('Error fixing patient name for ID $patientId: $e');
          }
        } else {
          print('✓ Patient name already correct: "$currentPatientName"');
        }
      }
      
      print('=== PATIENT NAMES FIX COMPLETED: $fixedCount names fixed ===');
    } catch (e) {
      print('Error fixing patient names: $e');
      throw e;
    }
  }

  // Nettoyer complètement la base de données (tous les problèmes)
  static Future<void> fullDatabaseCleanup() async {
    try {
      print('=== STARTING FULL DATABASE CLEANUP ===');
      
      // 1. Corriger les noms des patients
      await fixPatientNames();
      
      // 2. Nettoyer les documents de cliniques
      await cleanupDatabase();
      
      // 3. Forcer la mise à jour des noms de cliniques
      await AppointmentService.forceUpdateClinicNames();
      
      print('=== FULL DATABASE CLEANUP COMPLETED ===');
    } catch (e) {
      print('Error during full database cleanup: $e');
      throw e;
    }
  }
} 