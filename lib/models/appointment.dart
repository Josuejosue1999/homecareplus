import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final String patientEmail;
  final String patientPhone;
  final String hospitalName;
  final String hospitalImage;
  final String hospitalLocation;
  final String department;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String symptoms;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientEmail,
    required this.patientPhone,
    required this.hospitalName,
    required this.hospitalImage,
    required this.hospitalLocation,
    required this.department,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.symptoms,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Appointment.fromFirestore(Map<String, dynamic> data, String id) {
    return Appointment(
      id: id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      patientEmail: data['patientEmail'] ?? '',
      patientPhone: data['patientPhone'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      hospitalImage: data['hospitalImage'] ?? '',
      hospitalLocation: data['hospitalLocation'] ?? '',
      department: data['department'] ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      appointmentTime: data['appointmentTime'] ?? '',
      symptoms: data['symptoms'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp?)?.toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'patientEmail': patientEmail,
      'patientPhone': patientPhone,
      'hospitalName': hospitalName,
      'hospitalImage': hospitalImage,
      'hospitalLocation': hospitalLocation,
      'department': department,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'appointmentTime': appointmentTime,
      'symptoms': symptoms,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? patientEmail,
    String? patientPhone,
    String? hospitalName,
    String? hospitalImage,
    String? hospitalLocation,
    String? department,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? symptoms,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientEmail: patientEmail ?? this.patientEmail,
      patientPhone: patientPhone ?? this.patientPhone,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalImage: hospitalImage ?? this.hospitalImage,
      hospitalLocation: hospitalLocation ?? this.hospitalLocation,
      department: department ?? this.department,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      symptoms: symptoms ?? this.symptoms,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
