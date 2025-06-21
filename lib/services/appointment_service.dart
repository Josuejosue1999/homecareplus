import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/appointment.dart';

class AppointmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Créer un nouveau rendez-vous
  static Future<String> createAppointment(Appointment appointment) async {
    try {
      final docRef = await _firestore
          .collection('appointments')
          .add(appointment.toFirestore());
      
      print('Appointment created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      throw e;
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

  // Récupérer les rendez-vous à venir (prochains 7 jours)
  static Stream<List<Appointment>> getUpcomingAppointments() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));

      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .where('appointmentDate', isGreaterThanOrEqualTo: now)
          .where('appointmentDate', isLessThanOrEqualTo: nextWeek)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('appointmentDate', descending: false)
          .orderBy('appointmentTime', descending: false)
          .snapshots()
          .map((snapshot) {
        print('Fetched ${snapshot.docs.length} upcoming appointments from Firebase');
        return snapshot.docs.map((doc) {
          return Appointment.fromFirestore(doc.data(), doc.id);
        }).toList();
      });
    } catch (e) {
      print('Error fetching upcoming appointments: $e');
      throw e;
    }
  }

  // Mettre à jour le statut d'un rendez-vous
  static Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Appointment status updated successfully');
    } catch (e) {
      print('Error updating appointment status: $e');
      throw e;
    }
  }

  // Supprimer un rendez-vous
  static Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .delete();
      
      print('Appointment deleted successfully');
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
} 