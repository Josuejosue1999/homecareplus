import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _readNotificationsKey = 'read_notifications';

  // Écouter les changements de statut des rendez-vous pour un patient
  static Stream<List<AppointmentNotification>> getPatientNotifications() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value([]);
      }

      return _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: user.uid)
          .snapshots()
          .asyncMap((snapshot) async {
        final List<AppointmentNotification> notifications = [];
        final readNotifications = await _getReadNotifications();
        
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            final status = data['status'] ?? 'pending';
            final updatedAt = data['updatedAt'] as Timestamp?;
            final createdAt = data['createdAt'] as Timestamp?;
            final hospitalName = data['hospitalName'] ?? 'Unknown Hospital';
            final department = data['department'] ?? 'General';
            final appointmentDate = data['appointmentDate'] as Timestamp?;
            final appointmentTime = data['appointmentTime'] ?? '';

            // Notification de création de rendez-vous
            if (createdAt != null) {
              final notificationId = 'created_${doc.id}';
              notifications.add(
                AppointmentNotification(
                  id: notificationId,
                  patientId: user.uid,
                  title: 'Appointment Booked Successfully! 📅',
                  message: 'Your appointment has been booked at $hospitalName ($department). Waiting for clinic confirmation.',
                  type: NotificationType.newAppointment,
                  appointmentId: doc.id,
                  hospitalName: hospitalName,
                  department: department,
                  appointmentDate: appointmentDate?.toDate(),
                  appointmentTime: appointmentTime,
                  createdAt: createdAt.toDate(),
                  isRead: readNotifications.contains(notificationId),
                  clinicId: null,
                ),
              );
            }

            // Notification de confirmation de rendez-vous
            if (status == 'confirmed' && updatedAt != null) {
              final notificationId = 'confirmed_${doc.id}';
              notifications.add(
                AppointmentNotification(
                  id: notificationId,
                  patientId: user.uid,
                  title: 'Appointment Confirmed! 🎉',
                  message: 'Your appointment at $hospitalName ($department) has been confirmed by the clinic.',
                  type: NotificationType.appointmentConfirmed,
                  appointmentId: doc.id,
                  hospitalName: hospitalName,
                  department: department,
                  appointmentDate: appointmentDate?.toDate(),
                  appointmentTime: appointmentTime,
                  createdAt: updatedAt.toDate(),
                  isRead: readNotifications.contains(notificationId),
                  clinicId: null,
                ),
              );
            }

            // Notification d'annulation de rendez-vous
            if (status == 'cancelled' && updatedAt != null) {
              final notificationId = 'cancelled_${doc.id}';
              notifications.add(
                AppointmentNotification(
                  id: notificationId,
                  patientId: user.uid,
                  title: 'Appointment Cancelled',
                  message: 'Your appointment at $hospitalName ($department) has been cancelled by the clinic.',
                  type: NotificationType.appointmentDeclined,
                  appointmentId: doc.id,
                  hospitalName: hospitalName,
                  department: department,
                  appointmentDate: appointmentDate?.toDate(),
                  appointmentTime: appointmentTime,
                  createdAt: updatedAt.toDate(),
                  isRead: readNotifications.contains(notificationId),
                  clinicId: null,
                ),
              );
            }
          } catch (e) {
            print('Error processing notification for appointment ${doc.id}: $e');
          }
        }

        // Trier par date (plus récent en premier)
        notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        return notifications;
      });
    } catch (e) {
      print('Error getting patient notifications: $e');
      return Stream.value([]);
    }
  }

  // Obtenir le nombre de notifications non lues
  static Stream<int> getUnreadNotificationCount() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value(0);
      }

      return getPatientNotifications().map((notifications) {
        return notifications.where((notification) => !notification.isRead).length;
      });
    } catch (e) {
      print('Error getting unread notification count: $e');
      return Stream.value(0);
    }
  }

  // Marquer une notification comme lue
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList(_readNotificationsKey) ?? [];
      
      if (!readNotifications.contains(notificationId)) {
        readNotifications.add(notificationId);
        await prefs.setStringList(_readNotificationsKey, readNotifications);
        print('Marked notification as read: $notificationId');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Marquer toutes les notifications comme lues
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final notifications = await getPatientNotifications().first;
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList(_readNotificationsKey) ?? [];
      
      for (final notification in notifications) {
        if (!readNotifications.contains(notification.id)) {
          readNotifications.add(notification.id);
        }
      }
      
      await prefs.setStringList(_readNotificationsKey, readNotifications);
      print('Marked all notifications as read');
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Obtenir la liste des notifications lues
  static Future<List<String>> _getReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_readNotificationsKey) ?? [];
    } catch (e) {
      print('Error getting read notifications: $e');
      return [];
    }
  }

  // Créer une notification personnalisée
  static Future<void> createCustomNotification({
    required String patientId,
    required String title,
    required String message,
    required NotificationType type,
    String? appointmentId,
    String? hospitalName,
    String? department,
    DateTime? appointmentDate,
    String? appointmentTime,
  }) async {
    try {
      final notificationData = {
        'patientId': patientId,
        'title': title,
        'message': message,
        'type': type.toString(),
        'appointmentId': appointmentId,
        'hospitalName': hospitalName,
        'department': department,
        'appointmentDate': appointmentDate != null ? Timestamp.fromDate(appointmentDate) : null,
        'appointmentTime': appointmentTime,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('notifications')
          .add(notificationData);
      
      print('Custom notification created successfully');
    } catch (e) {
      print('Error creating custom notification: $e');
      throw e;
    }
  }

  // Créer une notification pour une clinique
  static Future<void> createClinicNotification({
    required String clinicId,
    required String title,
    required String message,
    required String appointmentId,
    required String hospitalName,
    required String department,
    required DateTime appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      print('=== CREATING CLINIC NOTIFICATION ===');
      print('Clinic ID: $clinicId');
      print('Title: $title');
      print('Message: $message');
      
      final notificationData = {
        'clinicId': clinicId,
        'title': title,
        'message': message,
        'type': 'new_appointment',
        'appointmentId': appointmentId,
        'hospitalName': hospitalName,
        'department': department,
        'appointmentDate': Timestamp.fromDate(appointmentDate),
        'appointmentTime': appointmentTime,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      await FirebaseFirestore.instance
          .collection('clinic_notifications')
          .add(notificationData);
      
      print('✓ Clinic notification created successfully');
    } catch (e) {
      print('Error creating clinic notification: $e');
      throw e;
    }
  }

  // Supprimer les anciennes notifications (plus de 30 jours)
  static Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final oldNotifications = await FirebaseFirestore.instance
          .collection('notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      for (final doc in oldNotifications.docs) {
        await doc.reference.delete();
      }

      print('Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      print('Error cleaning up old notifications: $e');
    }
  }

  // === CLINIC NOTIFICATIONS ===
  static Stream<List<AppointmentNotification>> getClinicNotifications(String clinicId) {
    try {
      print('=== GETTING CLINIC NOTIFICATIONS ===');
      print('Clinic ID: $clinicId');
      
      // Essayer d'abord la requête complexe
      return FirebaseFirestore.instance
          .collection('clinic_notifications')
          .where('clinicId', isEqualTo: clinicId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => AppointmentNotification.fromFirestore(doc.data(), doc.id)).toList());
    } catch (e) {
      print('Error in getClinicNotifications: $e');
      return Stream.value([]);
    }
  }

  // Méthode simple pour récupérer les notifications de la clinique
  static Future<List<AppointmentNotification>> getClinicNotificationsSimple(String clinicId) async {
    try {
      print('=== GETTING CLINIC NOTIFICATIONS SIMPLE ===');
      print('Clinic ID: $clinicId');
      
      // Récupérer toutes les notifications et filtrer côté client
      final snapshot = await FirebaseFirestore.instance
          .collection('clinic_notifications')
          .get();
      
      final allNotifications = snapshot.docs.map((doc) => AppointmentNotification.fromFirestore(doc.data(), doc.id)).toList();
      final filteredNotifications = allNotifications.where((notification) => 
          notification.clinicId == clinicId
      ).toList();
      
      // Trier par date (plus récent en premier)
      filteredNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      print('Simple method: Found ${filteredNotifications.length} notifications for clinic "$clinicId"');
      return filteredNotifications;
    } catch (e) {
      print('Error in getClinicNotificationsSimple: $e');
      return [];
    }
  }

  static Stream<int> getUnreadClinicNotificationCount(String clinicId) {
    try {
      print('=== GETTING UNREAD CLINIC NOTIFICATION COUNT ===');
      print('Clinic ID: $clinicId');
      
      // Essayer d'abord la requête complexe
      return FirebaseFirestore.instance
          .collection('clinic_notifications')
          .where('clinicId', isEqualTo: clinicId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) {
            final count = snapshot.docs.length;
            print('Complex query: Found $count unread notifications for clinic "$clinicId"');
            return count;
          })
          .handleError((error) {
            print('Complex query failed, using fallback method: $error');
            // Fallback: récupérer toutes les notifications et filtrer côté client
            return _getUnreadClinicNotificationCountFallback(clinicId);
          });
    } catch (e) {
      print('Error in getUnreadClinicNotificationCount: $e');
      return _getUnreadClinicNotificationCountFallback(clinicId);
    }
  }

  // Méthode de fallback pour le comptage des notifications non lues
  static Stream<int> _getUnreadClinicNotificationCountFallback(String clinicId) {
    return FirebaseFirestore.instance
        .collection('clinic_notifications')
        .snapshots()
        .map((snapshot) {
          int count = 0;
          
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              if (data['clinicId'] == clinicId && data['isRead'] == false) {
                count++;
              }
            } catch (e) {
              print('Error processing notification ${doc.id}: $e');
            }
          }
          
          print('Fallback: Found $count unread notifications for clinic "$clinicId"');
          return count;
        })
        .handleError((error) {
          print('Fallback method also failed: $error');
          // Retourner 0 en cas d'erreur
          return 0;
        });
  }

  // Marquer une notification de clinique comme lue
  static Future<void> markClinicNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('clinic_notifications')
          .doc(notificationId)
          .update({'isRead': true});
      print('✓ Marked clinic notification as read: $notificationId');
    } catch (e) {
      print('Error marking clinic notification as read: $e');
    }
  }

  // Marquer toutes les notifications de clinique comme lues
  static Future<void> markAllClinicNotificationsAsRead(String clinicId) async {
    try {
      print('=== MARKING ALL CLINIC NOTIFICATIONS AS READ ===');
      print('Clinic ID: $clinicId');
      
      final notifications = await getClinicNotifications(clinicId).first;
      final prefs = await SharedPreferences.getInstance();
      final readNotifications = prefs.getStringList('${_readNotificationsKey}_clinic_$clinicId') ?? [];
      
      for (final notification in notifications) {
        if (!readNotifications.contains(notification.id)) {
          readNotifications.add(notification.id);
        }
      }
      
      await prefs.setStringList('${_readNotificationsKey}_clinic_$clinicId', readNotifications);
      print('✓ Marked all clinic notifications as read');
    } catch (e) {
      print('Error marking all clinic notifications as read: $e');
    }
  }

  // Supprimer une notification de clinique
  static Future<void> deleteClinicNotification(String notificationId) async {
    try {
      print('=== DELETING CLINIC NOTIFICATION ===');
      print('Notification ID: $notificationId');
      
      await FirebaseFirestore.instance
          .collection('clinic_notifications')
          .doc(notificationId)
          .delete();
      
      print('✓ Clinic notification deleted successfully');
    } catch (e) {
      print('Error deleting clinic notification: $e');
      throw e;
    }
  }

  // Supprimer une notification de patient
  static Future<void> deleteNotification(String notificationId) async {
    try {
      print('=== DELETING PATIENT NOTIFICATION ===');
      print('Notification ID: $notificationId');
      
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      print('✓ Patient notification deleted successfully');
    } catch (e) {
      print('Error deleting patient notification: $e');
      throw e;
    }
  }
}

enum NotificationType {
  appointmentConfirmed,
  appointmentDeclined,
  newAppointment,
  appointmentReminder,
  custom,
}

class AppointmentNotification {
  final String id;
  final String patientId;
  final String title;
  final String message;
  final NotificationType type;
  final String? appointmentId;
  final String? hospitalName;
  final String? department;
  final DateTime? appointmentDate;
  final String? appointmentTime;
  final DateTime createdAt;
  final bool isRead;
  final String? clinicId;

  AppointmentNotification({
    required this.id,
    required this.patientId,
    required this.title,
    required this.message,
    required this.type,
    this.appointmentId,
    this.hospitalName,
    this.department,
    this.appointmentDate,
    this.appointmentTime,
    required this.createdAt,
    required this.isRead,
    this.clinicId,
  });

  // Méthode pour créer une notification depuis Firestore
  factory AppointmentNotification.fromFirestore(Map<String, dynamic> data, String id) {
    return AppointmentNotification(
      id: id,
      patientId: data['patientId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: _parseNotificationType(data['type'] ?? ''),
      appointmentId: data['appointmentId'],
      hospitalName: data['hospitalName'],
      department: data['department'],
      appointmentDate: data['appointmentDate']?.toDate(),
      appointmentTime: data['appointmentTime'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      clinicId: data['clinicId'],
    );
  }

  // Méthode helper pour parser le type de notification
  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'new_appointment':
        return NotificationType.newAppointment;
      case 'appointment_confirmed':
        return NotificationType.appointmentConfirmed;
      case 'appointment_declined':
        return NotificationType.appointmentDeclined;
      case 'appointment_cancelled':
        return NotificationType.appointmentDeclined;
      default:
        return NotificationType.newAppointment;
    }
  }

  // Getter pour le body (compatibilité)
  String get body => message;

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'appointmentId': appointmentId,
      'hospitalName': hospitalName,
      'department': department,
      'appointmentDate': appointmentDate != null ? Timestamp.fromDate(appointmentDate!) : null,
      'appointmentTime': appointmentTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'clinicId': clinicId,
    };
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy at HH:mm').format(createdAt);
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Color get typeColor {
    switch (type) {
      case NotificationType.appointmentConfirmed:
        return Colors.green;
      case NotificationType.appointmentDeclined:
        return Colors.red;
      case NotificationType.newAppointment:
        return Colors.blue;
      case NotificationType.appointmentReminder:
        return Colors.orange;
      case NotificationType.custom:
        return Colors.purple;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case NotificationType.appointmentConfirmed:
        return Icons.check_circle;
      case NotificationType.appointmentDeclined:
        return Icons.cancel;
      case NotificationType.newAppointment:
        return Icons.schedule;
      case NotificationType.appointmentReminder:
        return Icons.notification_important;
      case NotificationType.custom:
        return Icons.info;
    }
  }
} 