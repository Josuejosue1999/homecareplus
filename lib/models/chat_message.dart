import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  appointmentConfirmation,
  appointmentCancellation,
  appointmentReminder,
  appointmentRequest,
  system,
}

enum SenderType {
  patient,
  clinic,
  system,
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final SenderType senderType;
  final String message;
  final MessageType messageType;
  final DateTime timestamp;
  final bool isRead;
  final String? appointmentId;
  final String? hospitalName;
  final String? hospitalImage;
  final String? patientImage;
  final String? department;
  final DateTime? appointmentDate;
  final String? appointmentTime;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.message,
    required this.messageType,
    required this.timestamp,
    required this.isRead,
    this.appointmentId,
    this.hospitalName,
    this.hospitalImage,
    this.patientImage,
    this.department,
    this.appointmentDate,
    this.appointmentTime,
    this.metadata,
  });

  factory ChatMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderType: _parseSenderType(data['senderType'] ?? 'patient'),
      message: data['message'] ?? '',
      messageType: _parseMessageType(data['messageType'] ?? 'text'),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      appointmentId: data['appointmentId'],
      hospitalName: data['hospitalName'],
      hospitalImage: data['hospitalImage'],
      patientImage: data['patientImage'],
      department: data['department'],
      appointmentDate: data['appointmentDate']?.toDate(),
      appointmentTime: data['appointmentTime'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType.toString().split('.').last,
      'message': message,
      'messageType': messageType.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'appointmentId': appointmentId,
      'hospitalName': hospitalName,
      'hospitalImage': hospitalImage,
      'patientImage': patientImage,
      'department': department,
      'appointmentDate': appointmentDate != null ? Timestamp.fromDate(appointmentDate!) : null,
      'appointmentTime': appointmentTime,
      'metadata': metadata,
    };
  }

  static SenderType _parseSenderType(String type) {
    switch (type) {
      case 'clinic':
        return SenderType.clinic;
      case 'system':
        return SenderType.system;
      case 'patient':
      default:
        return SenderType.patient;
    }
  }

  static MessageType _parseMessageType(String type) {
    switch (type) {
      case 'appointmentConfirmation':
        return MessageType.appointmentConfirmation;
      case 'appointmentCancellation':
        return MessageType.appointmentCancellation;
      case 'appointmentReminder':
        return MessageType.appointmentReminder;
      case 'appointmentRequest':
        return MessageType.appointmentRequest;
      case 'system':
        return MessageType.system;
      case 'text':
      default:
        return MessageType.text;
    }
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    SenderType? senderType,
    String? message,
    MessageType? messageType,
    DateTime? timestamp,
    bool? isRead,
    String? appointmentId,
    String? hospitalName,
    String? hospitalImage,
    String? patientImage,
    String? department,
    DateTime? appointmentDate,
    String? appointmentTime,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      appointmentId: appointmentId ?? this.appointmentId,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalImage: hospitalImage ?? this.hospitalImage,
      patientImage: patientImage ?? this.patientImage,
      department: department ?? this.department,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ChatConversation {
  final String id;
  final String patientId;
  final String clinicId;
  final String patientName;
  final String clinicName;
  final String? hospitalImage;
  final DateTime lastMessageTime;
  final String lastMessage;
  final bool hasUnreadMessages;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatConversation({
    required this.id,
    required this.patientId,
    required this.clinicId,
    required this.patientName,
    required this.clinicName,
    this.hospitalImage,
    required this.lastMessageTime,
    required this.lastMessage,
    required this.hasUnreadMessages,
    required this.unreadCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatConversation.fromFirestore(Map<String, dynamic> data, String id) {
    return ChatConversation(
      id: id,
      patientId: data['patientId'] ?? '',
      clinicId: data['clinicId'] ?? '',
      patientName: data['patientName'] ?? '',
      clinicName: data['clinicName'] ?? '',
      hospitalImage: data['hospitalImage'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'] ?? '',
      hasUnreadMessages: data['hasUnreadMessages'] ?? false,
      unreadCount: data['unreadCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'clinicId': clinicId,
      'patientName': patientName,
      'clinicName': clinicName,
      'hospitalImage': hospitalImage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessage': lastMessage,
      'hasUnreadMessages': hasUnreadMessages,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
} 