import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/hospital.dart';

class HospitalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all hospitals from Firebase
  static Stream<List<Hospital>> getHospitals() {
      return _firestore
          .collection('clinics')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
      return snapshot.docs.map((doc) {
            final data = doc.data();
            print('Processing hospital: ${data['name']}');
            return Hospital.fromFirestore(data, doc.id);
          }).toList();
    });
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
      print('Error getting hospital by ID: $e');
      return null;
    }
  }

  // Search hospitals by name
  static Stream<List<Hospital>> searchHospitals(String query) {
    if (query.isEmpty) {
      return getHospitals();
    }
    
    return _firestore
        .collection('clinics')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + '\uf8ff')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Search result - Processing hospital: ${data['name']}');
        return Hospital.fromFirestore(data, doc.id);
      }).toList();
    });
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

  // Sauvegarder les coordonnées d'un hôpital
  static Future<bool> updateHospitalCoordinates(
    String hospitalId,
    double latitude,
    double longitude,
  ) async {
    try {
      print('=== UPDATING HOSPITAL COORDINATES ===');
      print('Hospital ID: $hospitalId');
      print('Latitude: $latitude');
      print('Longitude: $longitude');

      await _firestore.collection('clinics').doc(hospitalId).update({
        'latitude': latitude,
        'longitude': longitude,
        'coordinatesUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✓ Hospital coordinates updated successfully');
      return true;
    } catch (e) {
      print('Error updating hospital coordinates: $e');
      return false;
    }
  }

  // Obtenir les hôpitaux avec des coordonnées
  static Stream<List<Hospital>> getHospitalsWithCoordinates() {
    return _firestore
        .collection('clinics')
        .where('latitude', isNull: false)
        .where('longitude', isNull: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        print('Processing hospital with coordinates: ${data['name']}');
        return Hospital.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  // Obtenir les hôpitaux par proximité (triés par distance)
  static Future<List<Hospital>> getHospitalsByProximity(
    double userLatitude,
    double userLongitude,
  ) async {
    try {
      print('=== GETTING HOSPITALS BY PROXIMITY ===');
      print('User location: $userLatitude, $userLongitude');

      final snapshot = await _firestore
          .collection('clinics')
          .where('latitude', isNull: false)
          .where('longitude', isNull: false)
          .get();

      final hospitals = snapshot.docs.map((doc) {
        final data = doc.data();
        return Hospital.fromFirestore(data, doc.id);
      }).toList();

      // Calculer les distances et trier
      final hospitalsWithDistance = hospitals.map((hospital) {
        final distance = _calculateDistance(
          userLatitude,
          userLongitude,
          hospital.latitude!,
          hospital.longitude!,
        );
        return {
          'hospital': hospital,
          'distance': distance,
        };
      }).toList();

      // Trier par distance
      hospitalsWithDistance.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      print('✓ Found ${hospitalsWithDistance.length} hospitals with coordinates');
      return hospitalsWithDistance.map((item) => item['hospital'] as Hospital).toList();
    } catch (e) {
      print('Error getting hospitals by proximity: $e');
      return [];
    }
  }

  // Calculer la distance entre deux points (formule de Haversine)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Rayon de la Terre en mètres

    final double lat1Rad = lat1 * (pi / 180);
    final double lat2Rad = lat2 * (pi / 180);
    final double deltaLat = (lat2 - lat1) * (pi / 180);
    final double deltaLon = (lon2 - lon1) * (pi / 180);

    final double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Mettre à jour les informations d'un hôpital
  static Future<bool> updateHospital(String hospitalId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('clinics').doc(hospitalId).update(data);
      return true;
    } catch (e) {
      print('Error updating hospital: $e');
      return false;
    }
  }

  // Supprimer un hôpital
  static Future<bool> deleteHospital(String hospitalId) async {
    try {
      await _firestore.collection('clinics').doc(hospitalId).delete();
      return true;
    } catch (e) {
      print('Error deleting hospital: $e');
      return false;
    }
  }

  // Obtenir les statistiques des hôpitaux
  static Future<Map<String, dynamic>> getHospitalStats() async {
    try {
      final snapshot = await _firestore.collection('clinics').get();
      final totalHospitals = snapshot.docs.length;
      
      final verifiedHospitals = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['certificateUrl'] != null && data['certificateUrl'].isNotEmpty;
      }).length;

      final hospitalsWithCoordinates = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['latitude'] != null && data['longitude'] != null;
      }).length;

      return {
        'total': totalHospitals,
        'verified': verifiedHospitals,
        'withCoordinates': hospitalsWithCoordinates,
      };
    } catch (e) {
      print('Error getting hospital stats: $e');
      return {
        'total': 0,
        'verified': 0,
        'withCoordinates': 0,
      };
    }
  }
} 