import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hospital.dart';

class HospitalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
} 