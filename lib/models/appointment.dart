import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicSchedule {
  final String id;
  final String clinicId;
  final Map<String, DaySchedule> weeklySchedule;
  final int defaultSlotDuration; // in minutes
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClinicSchedule({
    required this.id,
    required this.clinicId,
    required this.weeklySchedule,
    this.defaultSlotDuration = 30,
    required this.createdAt,
    this.updatedAt,
  });

  factory ClinicSchedule.fromFirestore(Map<String, dynamic> data, String id) {
    Map<String, DaySchedule> schedule = {};
    
    // Parse weekly schedule
    if (data['weeklySchedule'] != null) {
      final scheduleData = data['weeklySchedule'] as Map<String, dynamic>;
      scheduleData.forEach((day, dayData) {
        schedule[day] = DaySchedule.fromFirestore(dayData);
      });
    }

    return ClinicSchedule(
      id: id,
      clinicId: data['clinicId'] ?? '',
      weeklySchedule: schedule,
      defaultSlotDuration: data['defaultSlotDuration'] ?? 30,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp?)?.toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> scheduleData = {};
    weeklySchedule.forEach((day, schedule) {
      scheduleData[day] = schedule.toFirestore();
    });

    return {
      'clinicId': clinicId,
      'weeklySchedule': scheduleData,
      'defaultSlotDuration': defaultSlotDuration,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

class DaySchedule {
  final bool isWorkingDay;
  final String? startTime;
  final String? endTime;
  final List<String> breakTimes; // Format: ["12:00-13:00", "15:00-15:30"]
  final int? customSlotDuration; // Override default duration for this day

  DaySchedule({
    this.isWorkingDay = false,
    this.startTime,
    this.endTime,
    this.breakTimes = const [],
    this.customSlotDuration,
  });

  factory DaySchedule.fromFirestore(Map<String, dynamic> data) {
    return DaySchedule(
      isWorkingDay: data['isWorkingDay'] ?? false,
      startTime: data['startTime'],
      endTime: data['endTime'],
      breakTimes: List<String>.from(data['breakTimes'] ?? []),
      customSlotDuration: data['customSlotDuration'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'isWorkingDay': isWorkingDay,
      'startTime': startTime,
      'endTime': endTime,
      'breakTimes': breakTimes,
      'customSlotDuration': customSlotDuration,
    };
  }

  // Generate time slots for this day
  List<String> generateTimeSlots(int defaultDuration) {
    if (!isWorkingDay || startTime == null || endTime == null) {
      return [];
    }

    final duration = customSlotDuration ?? defaultDuration;
    List<String> slots = [];
    
    try {
      final start = _parseTime(startTime!);
      final end = _parseTime(endTime!);
      
      if (start != null && end != null) {
        DateTime current = start;
        while (current.isBefore(end)) {
          // Check if current time is not in break times
          if (!_isInBreakTime(current)) {
            slots.add(_formatTime(current));
          }
          current = current.add(Duration(minutes: duration));
        }
      }
    } catch (e) {
      print('Error generating time slots: $e');
    }
    
    return slots;
  }

  bool _isInBreakTime(DateTime time) {
    for (String breakTime in breakTimes) {
      if (breakTime.contains('-')) {
        final parts = breakTime.split('-');
        if (parts.length == 2) {
          final breakStart = _parseTime(parts[0].trim());
          final breakEnd = _parseTime(parts[1].trim());
          
          if (breakStart != null && breakEnd != null) {
            if (time.isAfter(breakStart) && time.isBefore(breakEnd)) {
              return true;
            }
          }
        }
      }
    }
    return false;
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
}

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
  final String reasonOfBooking;
  final int meetingDuration; // Duration in minutes
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? clinicId;

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
    required this.reasonOfBooking,
    this.meetingDuration = 30, // Default 30 minutes
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.clinicId,
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
      reasonOfBooking: data['reasonOfBooking'] ?? data['symptoms'] ?? '',
      meetingDuration: data['meetingDuration'] ?? 30, // Default 30 minutes
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp?)?.toDate() 
          : null,
      clinicId: data['clinicId'],
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
      'reasonOfBooking': reasonOfBooking,
      'meetingDuration': meetingDuration,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'clinicId': clinicId,
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
    String? reasonOfBooking,
    int? meetingDuration,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clinicId,
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
      reasonOfBooking: reasonOfBooking ?? this.reasonOfBooking,
      meetingDuration: meetingDuration ?? this.meetingDuration,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clinicId: clinicId ?? this.clinicId,
    );
  }
}
