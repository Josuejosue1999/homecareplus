import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/hospital.dart';

class HospitalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all hospitals from Firebase
  static Stream<List<Hospital>> getHospitals() {
    try {
      print('Starting to fetch hospitals from Firebase...');
      return _firestore
          .collection('clinics')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            print('Error in getHospitals stream: $error');
            throw error;
          })
          .map((snapshot) {
        print('Fetched ${snapshot.docs.length} hospitals from Firebase');
        try {
          final hospitals = snapshot.docs.map((doc) {
            final data = doc.data();
            print('Processing hospital: ${data['name']}');
            print('Hospital: ${data['name']} - Profile Image: ${data['profileImageUrl']?.substring(0, 50) ?? 'null'}...');
            print('Hospital: ${data['name']} - About: ${data['about']?.substring(0, 50) ?? 'null'}...');
            return Hospital.fromFirestore(data, doc.id);
          }).toList();
          print('Successfully processed ${hospitals.length} hospitals');
          return hospitals;
        } catch (e) {
          print('Error processing hospitals data: $e');
          throw e;
        }
      });
    } catch (e) {
      print('Error setting up getHospitals stream: $e');
      throw e;
    }
  }

  // Fetch a single hospital by ID
  static Future<Hospital?> getHospitalById(String id) async {
    try {
      final doc = await _firestore.collection('clinics').doc(id).get();
      if (doc.exists) {
        return Hospital.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching hospital: $e');
      return null;
    }
  }

  // Search hospitals by name
  static Stream<List<Hospital>> searchHospitals(String query) {
    if (query.isEmpty) {
      return getHospitals();
    }
    
    try {
      print('Searching hospitals with query: $query');
      return _firestore
          .collection('clinics')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: query + '\uf8ff')
          .snapshots()
          .handleError((error) {
            print('Error in searchHospitals stream: $error');
            throw error;
          })
          .map((snapshot) {
        print('Found ${snapshot.docs.length} hospitals matching query: $query');
        return snapshot.docs.map((doc) {
          return Hospital.fromFirestore(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error setting up searchHospitals stream: $e');
      throw e;
    }
  }

  // Créer ou mettre à jour un document de clinique
  static Future<void> createOrUpdateClinic({
    required String name,
    required String address,
    required String phone,
    required String email,
    required List<String> specialties,
    required String description,
    required String imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final clinicData = {
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'specialties': specialties,
        'description': description,
        'imageUrl': imageUrl,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('clinics')
          .doc(user.uid)
          .set(clinicData, SetOptions(merge: true));

      print('Clinic document created/updated successfully');
      print('Clinic name: "$name"');
      print('User ID: ${user.uid}');
    } catch (e) {
      print('Error creating/updating clinic: $e');
      throw e;
    }
  }

  // Récupérer les informations d'une clinique
  static Future<Map<String, dynamic>?> getClinicInfo(String userId) async {
    try {
      final doc = await _firestore
          .collection('clinics')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        print('Clinic info retrieved: $data');
        return data;
      } else {
        print('No clinic document found for user: $userId');
        return null;
      }
    } catch (e) {
      print('Error getting clinic info: $e');
      throw e;
    }
  }

  // Mettre à jour le nom d'une clinique
  static Future<void> updateClinicName(String userId, String newName) async {
    try {
      await _firestore
          .collection('clinics')
          .doc(userId)
          .update({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Clinic name updated to: "$newName"');
    } catch (e) {
      print('Error updating clinic name: $e');
      throw e;
    }
  }

  // Récupérer toutes les cliniques
  static Stream<List<Map<String, dynamic>>> getAllClinics() {
    try {
      return _firestore
          .collection('clinics')
          .snapshots()
          .map((snapshot) {
        final clinics = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        
        print('Retrieved ${clinics.length} clinics from Firebase');
        return clinics;
      });
    } catch (e) {
      print('Error getting all clinics: $e');
      throw e;
    }
  }

  // Supprimer une clinique
  static Future<void> deleteClinic(String userId) async {
    try {
      await _firestore
          .collection('clinics')
          .doc(userId)
          .delete();

      print('Clinic deleted successfully');
    } catch (e) {
      print('Error deleting clinic: $e');
      throw e;
    }
  }

  // Vérifier si une clinique existe
  static Future<bool> clinicExists(String userId) async {
    try {
      final doc = await _firestore
          .collection('clinics')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking if clinic exists: $e');
      return false;
    }
  }

  // Créer un document de clinique par défaut si il n'existe pas
  static Future<void> createDefaultClinicIfNotExists() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final exists = await clinicExists(user.uid);
      if (!exists) {
        final defaultName = user.displayName ?? 'New Clinic';
        
        await createOrUpdateClinic(
          name: defaultName,
          address: 'Address not set',
          phone: 'Phone not set',
          email: user.email ?? 'email@example.com',
          specialties: ['General Medicine'],
          description: 'Clinic description not set',
          imageUrl: 'https://via.placeholder.com/150',
        );

        print('Default clinic created with name: "$defaultName"');
      } else {
        print('Clinic already exists for user: ${user.uid}');
      }
    } catch (e) {
      print('Error creating default clinic: $e');
      throw e;
    }
  }

  // Synchroniser les noms de cliniques avec les rendez-vous
  static Future<void> syncClinicNamesWithAppointments() async {
    try {
      print('Starting clinic name synchronization...');
      
      // Récupérer toutes les cliniques
      final clinicsSnapshot = await _firestore.collection('clinics').get();
      final clinics = clinicsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
        };
      }).toList();

      print('Found ${clinics.length} clinics: $clinics');

      // Pour chaque clinique, mettre à jour les rendez-vous correspondants
      for (final clinic in clinics) {
        final clinicId = clinic['id'] as String;
        final clinicName = clinic['name'] as String;
        
        if (clinicName.isNotEmpty) {
          // Chercher les rendez-vous qui pourraient correspondre à cette clinique
          final appointmentsSnapshot = await _firestore
              .collection('appointments')
              .where('hospitalName', isEqualTo: clinicName)
              .get();

          print('Found ${appointmentsSnapshot.docs.length} appointments for clinic "$clinicName"');

          // Mettre à jour les rendez-vous pour s'assurer qu'ils ont le bon nom
          for (final doc in appointmentsSnapshot.docs) {
            await doc.reference.update({
              'hospitalName': clinicName,
              'clinicId': clinicId,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            print('Updated appointment ${doc.id} with clinic name "$clinicName"');
          }
        }
      }

      print('Clinic name synchronization completed');
    } catch (e) {
      print('Error synchronizing clinic names: $e');
      throw e;
    }
  }
} 