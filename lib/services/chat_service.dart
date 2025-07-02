import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir toutes les conversations d'un patient
  static Stream<List<ChatConversation>> getPatientConversations() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('ChatService: No authenticated user found');
        return Stream.value([]);
      }

      print('ChatService: Getting conversations for patient: ${user.uid}');

      return _firestore
          .collection('chat_conversations')
          .where('patientId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
        print('ChatService: Received ${snapshot.docs.length} conversations');
        
        try {
          final conversations = snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              print('ChatService: Processing conversation ${doc.id}: $data');
              return ChatConversation.fromFirestore(data, doc.id);
            } catch (e) {
              print('ChatService: Error processing conversation ${doc.id}: $e');
              return null;
            }
          }).where((conversation) => conversation != null).cast<ChatConversation>().toList();
          
          // Trier manuellement par date
          conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          
          print('ChatService: Successfully processed ${conversations.length} conversations');
          return conversations;
        } catch (e) {
          print('ChatService: Error mapping conversations: $e');
          return <ChatConversation>[];
        }
      }).handleError((error) {
        print('ChatService: Error in getPatientConversations stream: $error');
        return <ChatConversation>[];
      });
    } catch (e) {
      print('ChatService: Error in getPatientConversations: $e');
      return Stream.value([]);
    }
  }

  // Obtenir toutes les conversations d'une clinique
  static Stream<List<ChatConversation>> getClinicConversations() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('ChatService: No authenticated user found');
        return Stream.value([]);
      }

      print('ChatService: Getting conversations for clinic: ${user.uid}');

      return _firestore
          .collection('chat_conversations')
          .where('clinicId', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
        print('ChatService: Received ${snapshot.docs.length} conversations');
        
        try {
          final conversations = snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              print('ChatService: Processing conversation ${doc.id}: $data');
              return ChatConversation.fromFirestore(data, doc.id);
            } catch (e) {
              print('ChatService: Error processing conversation ${doc.id}: $e');
              return null;
            }
          }).where((conversation) => conversation != null).cast<ChatConversation>().toList();
          
          // Trier manuellement par date
          conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          
          print('ChatService: Successfully processed ${conversations.length} conversations');
          return conversations;
        } catch (e) {
          print('ChatService: Error mapping conversations: $e');
          return <ChatConversation>[];
        }
      }).handleError((error) {
        print('ChatService: Error in getClinicConversations stream: $error');
        return <ChatConversation>[];
      });
    } catch (e) {
      print('ChatService: Error in getClinicConversations: $e');
      return Stream.value([]);
    }
  }

  // Obtenir les messages d'une conversation
  static Stream<List<ChatMessage>> getConversationMessages(String conversationId) {
    try {
      print('ChatService: Getting messages for conversation: $conversationId');
      
      return _firestore
          .collection('chat_messages')
          .where('conversationId', isEqualTo: conversationId)
          .snapshots()
          .map((snapshot) {
        print('ChatService: Received ${snapshot.docs.length} messages');
        
        try {
          final messages = snapshot.docs.map((doc) {
            try {
              final data = doc.data();
              print('ChatService: Processing message ${doc.id}: $data');
              return ChatMessage.fromFirestore(data, doc.id);
            } catch (e) {
              print('ChatService: Error processing message ${doc.id}: $e');
              return null;
            }
          }).where((message) => message != null).cast<ChatMessage>().toList();
          
          // Trier manuellement par timestamp
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          print('ChatService: Successfully processed ${messages.length} messages');
          return messages;
        } catch (e) {
          print('ChatService: Error mapping messages: $e');
          return <ChatMessage>[];
        }
      }).handleError((error) {
        print('ChatService: Error in getConversationMessages stream: $error');
        return <ChatMessage>[];
      });
    } catch (e) {
      print('ChatService: Error in getConversationMessages: $e');
      return Stream.value([]);
    }
  }

  // Envoyer un message
  static Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String senderName,
    required SenderType senderType,
    required String message,
    MessageType messageType = MessageType.text,
    String? appointmentId,
    String? hospitalName,
    String? department,
    DateTime? appointmentDate,
    String? appointmentTime,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('ChatService: Sending message from $senderName ($senderType)');

      // 🔧 Récupérer les images appropriées selon le type d'expéditeur
      String? senderImage;
      String? patientImage;
      String? hospitalImage;

      if (senderType == SenderType.patient) {
        patientImage = await getPatientAvatar(senderId);
        senderImage = patientImage;
        print('ChatService: Patient image: ${patientImage != null ? "Found" : "Not found"}');
      } else if (senderType == SenderType.clinic) {
        hospitalImage = await _getHospitalImageFromClinicId(senderId);
        senderImage = hospitalImage;
        print('ChatService: Hospital image: ${hospitalImage != null ? "Found" : "Not found"}');
      }

      final messageData = {
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'senderType': senderType.toString().split('.').last,
        'message': message,
        'messageType': messageType.toString().split('.').last,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'appointmentId': appointmentId,
        'hospitalName': hospitalName,
        'hospitalImage': hospitalImage, // Image de l'hôpital
        'patientImage': patientImage,   // Image du patient
        'department': department,
        'appointmentDate': appointmentDate != null ? Timestamp.fromDate(appointmentDate) : null,
        'appointmentTime': appointmentTime,
        'metadata': metadata,
      };

      final docRef = await _firestore
          .collection('chat_messages')
          .add(messageData);

      print('ChatService: Message sent with ID: ${docRef.id}');

      // Mettre à jour la conversation
      await _updateConversation(conversationId, message, senderType);

    } catch (e) {
      print('ChatService: Error sending message: $e');
      throw e;
    }
  }

  // Créer ou obtenir une conversation (ENHANCED)
  static Future<String> getOrCreateConversation({
    required String patientId,
    required String clinicId,
    required String patientName,
    required String clinicName,
    String? hospitalImage,
  }) async {
    try {
      print('ChatService: Getting or creating conversation for patient: $patientId, clinic: $clinicId');
      
      // 🔧 FIX: Récupérer l'image de l'hôpital depuis la collection clinics si pas fournie
      String? actualHospitalImage = hospitalImage;
      if (actualHospitalImage == null || actualHospitalImage.isEmpty) {
        actualHospitalImage = await _getHospitalImageFromClinicId(clinicId);
        print('ChatService: Retrieved hospital image from clinics collection: ${actualHospitalImage != null ? "Yes" : "No"}');
      }
      
      // Vérifier si la conversation existe déjà
      final existingConversation = await _firestore
          .collection('chat_conversations')
          .where('patientId', isEqualTo: patientId)
          .where('clinicId', isEqualTo: clinicId)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        final conversationId = existingConversation.docs.first.id;
        print('ChatService: Found existing conversation: $conversationId');
        
        // 🔧 FIX: Mettre à jour l'image de l'hôpital ET du patient si elles n'existent pas
        final existingData = existingConversation.docs.first.data();
        final Map<String, dynamic> updateData = {};
        
        // Toujours mettre à jour l'image de l'hôpital si elle est disponible
        if (actualHospitalImage != null && actualHospitalImage.isNotEmpty) {
          if (existingData['hospitalImage'] != actualHospitalImage) {
            updateData['hospitalImage'] = actualHospitalImage;
            print('ChatService: Will update conversation with hospital image');
          }
        }
        
        // Récupérer et ajouter l'image du patient si manquante
        if (existingData['patientImage'] == null || existingData['patientImage'].isEmpty) {
          final patientImage = await getPatientAvatar(patientId);
          if (patientImage != null && patientImage.isNotEmpty) {
            updateData['patientImage'] = patientImage;
            print('ChatService: Will update conversation with patient image');
          }
        }
        
        if (updateData.isNotEmpty) {
          updateData['updatedAt'] = FieldValue.serverTimestamp();
          await _firestore
              .collection('chat_conversations')
              .doc(conversationId)
              .update(updateData);
          print('ChatService: Updated conversation with missing images');
        }
        
        return conversationId;
      }

      print('ChatService: Creating new conversation');
      
      // 🔧 FIX: Récupérer l'image du patient pour la nouvelle conversation
      final patientImage = await getPatientAvatar(patientId);
      
      // Créer une nouvelle conversation avec les images du patient ET de l'hôpital
      final conversationData = {
        'patientId': patientId,
        'clinicId': clinicId,
        'patientName': patientName,
        'clinicName': clinicName,
        'hospitalImage': actualHospitalImage, // 🔧 Image récupérée automatiquement
        'patientImage': patientImage, // 🔧 Ajouter l'image du patient
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': 'Conversation started',
        'hasUnreadMessages': false,
        'unreadCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore
          .collection('chat_conversations')
          .add(conversationData);

      print('ChatService: ✅ New conversation created: ${docRef.id}');
      print('ChatService: ✅ With patient image: ${patientImage != null ? "Yes" : "No"}');
      print('ChatService: ✅ With hospital image: ${actualHospitalImage != null ? "Yes" : "No"}');
      return docRef.id;
    } catch (e) {
      print('ChatService: ❌ Error creating conversation: $e');
      throw e;
    }
  }

  // Mettre à jour une conversation
  static Future<void> _updateConversation(
    String conversationId,
    String lastMessage,
    SenderType senderType,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('ChatService: No authenticated user for conversation update');
        return;
      }

      print('ChatService: Updating conversation: $conversationId');

      // Déterminer si le message est non lu pour l'autre partie
      bool hasUnreadMessages = false;
      int unreadCount = 0;

      // Si c'est un patient qui envoie, la clinique a un message non lu
      // Si c'est une clinique qui envoie, le patient a un message non lu
      if (senderType == SenderType.patient) {
        hasUnreadMessages = true;
        unreadCount = 1;
      } else if (senderType == SenderType.clinic) {
        hasUnreadMessages = true;
        unreadCount = 1;
      }

      await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .update({
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': lastMessage,
        'hasUnreadMessages': hasUnreadMessages,
        'unreadCount': unreadCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('ChatService: Conversation updated successfully');
    } catch (e) {
      print('ChatService: Error updating conversation: $e');
    }
  }

  // Marquer les messages comme lus
  static Future<void> markMessagesAsRead(String conversationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('ChatService: No authenticated user for marking messages as read');
        return;
      }

      print('ChatService: Marking messages as read for conversation: $conversationId');

      // Récupérer tous les messages de la conversation
      final messagesSnapshot = await _firestore
          .collection('chat_messages')
          .where('conversationId', isEqualTo: conversationId)
          .get();

      final batch = _firestore.batch();
      int updatedCount = 0;

      // Marquer comme lus seulement les messages de l'autre partie qui ne sont pas encore lus
      for (final doc in messagesSnapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String?;
        final isRead = data['isRead'] as bool? ?? false;

        // Si le message n'est pas de l'utilisateur actuel et n'est pas encore lu
        if (senderId != currentUser.uid && !isRead) {
          batch.update(doc.reference, {'isRead': true});
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        await batch.commit();
        print('ChatService: Marked $updatedCount messages as read');
      } else {
        print('ChatService: No messages to mark as read');
      }

      // Mettre à jour la conversation pour indiquer qu'il n'y a plus de messages non lus
      await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .update({
        'hasUnreadMessages': false,
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('ChatService: Updated conversation read status');

    } catch (e) {
      print('ChatService: Error marking messages as read: $e');
    }
  }

  // Envoyer un message de confirmation de rendez-vous
  static Future<void> sendAppointmentConfirmationMessage({
    required String patientId,
    required String clinicId,
    required String patientName,
    required String clinicName,
    required String appointmentId,
    required String hospitalName,
    required String department,
    required DateTime appointmentDate,
    required String appointmentTime,
  }) async {
    try {
      print('ChatService: Sending appointment confirmation message');
      
      // Obtenir ou créer la conversation
      final conversationId = await getOrCreateConversation(
        patientId: patientId,
        clinicId: clinicId,
        patientName: patientName,
        clinicName: clinicName,
      );

      // Créer le message de confirmation
      final confirmationMessage = '''
🎉 **Appointment Confirmed!**

Your appointment has been confirmed by **$clinicName**.

**Details:**
• **Hospital:** $hospitalName
• **Department:** $department
• **Date:** ${_formatDate(appointmentDate)}
• **Time:** $appointmentTime

Please arrive 15 minutes before your scheduled time. If you need to reschedule or cancel, please contact us as soon as possible.

Thank you for choosing our services!
      ''';

      // Envoyer le message
      await sendMessage(
        conversationId: conversationId,
        senderId: clinicId,
        senderName: clinicName,
        senderType: SenderType.clinic,
        message: confirmationMessage,
        messageType: MessageType.appointmentConfirmation,
        appointmentId: appointmentId,
        hospitalName: hospitalName,
        department: department,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        metadata: {
          'action': 'appointment_confirmed',
          'appointmentId': appointmentId,
        },
      );

      print('ChatService: Appointment confirmation message sent successfully');
    } catch (e) {
      print('ChatService: Error sending appointment confirmation message: $e');
      throw e;
    }
  }

  // Envoyer un message d'annulation de rendez-vous
  static Future<void> sendAppointmentCancellationMessage({
    required String patientId,
    required String clinicId,
    required String patientName,
    required String clinicName,
    required String appointmentId,
    required String hospitalName,
    required String department,
    required DateTime appointmentDate,
    required String appointmentTime,
    String? reason,
  }) async {
    try {
      print('ChatService: Sending appointment cancellation message');
      
      // Obtenir ou créer la conversation
      final conversationId = await getOrCreateConversation(
        patientId: patientId,
        clinicId: clinicId,
        patientName: patientName,
        clinicName: clinicName,
      );

      // Créer le message d'annulation
      final cancellationMessage = '''
❌ **Appointment Cancelled**

Your appointment has been cancelled by **$clinicName**.

**Details:**
• **Hospital:** $hospitalName
• **Department:** $department
• **Date:** ${_formatDate(appointmentDate)}
• **Time:** $appointmentTime
${reason != null ? '• **Reason:** $reason' : ''}

Please contact us to reschedule your appointment at your convenience.

We apologize for any inconvenience caused.
      ''';

      // Envoyer le message
      await sendMessage(
        conversationId: conversationId,
        senderId: clinicId,
        senderName: clinicName,
        senderType: SenderType.clinic,
        message: cancellationMessage,
        messageType: MessageType.appointmentCancellation,
        appointmentId: appointmentId,
        hospitalName: hospitalName,
        department: department,
        appointmentDate: appointmentDate,
        appointmentTime: appointmentTime,
        metadata: {
          'action': 'appointment_cancelled',
          'appointmentId': appointmentId,
          'reason': reason,
        },
      );

      print('ChatService: Appointment cancellation message sent successfully');
    } catch (e) {
      print('ChatService: Error sending appointment cancellation message: $e');
      throw e;
    }
  }

  // Obtenir le nombre de conversations non lues pour un patient (ENHANCED)
  static Stream<int> getPatientUnreadConversationCount() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('ChatService: No authenticated user for unread count');
        return Stream.value(0);
      }

      print('ChatService: Getting unread conversation count for patient: ${user.uid}');

      return _firestore
          .collection('chat_conversations')
          .where('patientId', isEqualTo: user.uid)
          .where('hasUnreadMessages', isEqualTo: true)
          .snapshots()
          .asyncMap((snapshot) async {
        // Filter out conversations deleted by patient
        final activeConversations = snapshot.docs.where((doc) {
          final data = doc.data();
          final deletedByPatient = data['deletedByPatient'] ?? false;
          return !deletedByPatient;
        });
        
        final count = activeConversations.length;
        print('ChatService: ✅ Unread conversation count (active): $count');
        return count;
      }).handleError((error) {
        print('ChatService: Error in getPatientUnreadConversationCount stream: $error');
        return 0;
      });
    } catch (e) {
      print('ChatService: Error getting unread conversation count: $e');
      return Stream.value(0);
    }
  }

  // Obtenir le nombre de conversations non lues pour une clinique
  static Stream<int> getClinicUnreadConversationCount() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('ChatService: No authenticated user for unread count');
        return Stream.value(0);
      }

      print('ChatService: Getting unread conversation count for clinic: ${user.uid}');

      return _firestore
          .collection('chat_conversations')
          .where('clinicId', isEqualTo: user.uid)
          .where('hasUnreadMessages', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        final count = snapshot.docs.length;
        print('ChatService: Unread conversation count: $count');
        return count;
      }).handleError((error) {
        print('ChatService: Error in getClinicUnreadConversationCount stream: $error');
        return 0;
      });
    } catch (e) {
      print('ChatService: Error getting unread conversation count: $e');
      return Stream.value(0);
    }
  }

  // Marquer une conversation comme lue
  static Future<void> markConversationAsRead(String conversationId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('ChatService: No authenticated user for marking conversation as read');
        return;
      }

      print('ChatService: Marking conversation as read: $conversationId for user: ${currentUser.uid}');

      // Mettre à jour tous les messages non lus de cette conversation
      final batch = _firestore.batch();
      
      final messages = await _firestore
          .collection('chat_messages')
          .where('conversationId', isEqualTo: conversationId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (final messageDoc in messages.docs) {
        batch.update(messageDoc.reference, {'isRead': true});
      }
      
      // Mettre à jour la conversation
      final conversationRef = _firestore.collection('chat_conversations').doc(conversationId);
      batch.update(conversationRef, {
        'hasUnreadMessages': false,
        'unreadCount': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();
      print('ChatService: Conversation and messages marked as read successfully');

    } catch (e) {
      print('ChatService: Error marking conversation as read: $e');
    }
  }

  // Obtenir le nombre de conversations non lues pour un patient
  static Stream<int> getUnreadConversationCount(String patientId) {
    try {
      return _firestore
          .collection('chat_conversations')
          .where('patientId', isEqualTo: patientId)
          .where('hasUnreadMessages', isEqualTo: true)
          .snapshots()
          .map((snapshot) {
        print('ChatService: Unread conversation count: ${snapshot.docs.length}');
        return snapshot.docs.length;
      }).handleError((error) {
        print('ChatService: Error getting unread count: $error');
        return 0;
      });
    } catch (e) {
      print('ChatService: Error in getUnreadConversationCount: $e');
      return Stream.value(0);
    }
  }

  // Helper pour formater la date
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Récupérer l'avatar du patient depuis la collection users
  static Future<String?> getPatientAvatar(String patientId) async {
    try {
      print('ChatService: Looking for patient avatar with ID: $patientId');
      
      // D'abord essayer avec l'ID exact
      final userDoc = await _firestore
          .collection('users')
          .doc(patientId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        
        // 🔧 FIX: Try multiple potential image field names in order of preference
        final List<String> imageFields = [
          'profileImage',
          'imageUrl', 
          'profileImageUrl',
          'avatar',
          'photoURL',
          'image',
          'picture'
        ];
        
        for (final field in imageFields) {
          final imageValue = data?[field];
          if (imageValue != null && imageValue.toString().isNotEmpty && imageValue.toString() != 'null') {
            print('ChatService: ✅ Found patient avatar using field "$field": ${imageValue.toString().length > 50 ? imageValue.toString().substring(0, 50) + "..." : imageValue.toString()}');
            return imageValue.toString();
          }
        }
        
        print('ChatService: ⚠️ Patient document exists but no valid image found in any field for patient: $patientId');
        print('ChatService: Available fields: ${data?.keys.toList()}');
      } else {
        print('ChatService: ❌ Patient document not found for ID: $patientId');
      }
      
      print('ChatService: No avatar found for patient: $patientId');
      return null;
    } catch (e) {
      print('ChatService: ❌ Error getting patient avatar: $e');
      return null;
    }
  }

  // Générer un avatar par défaut avec les initiales du patient
  static String getDefaultAvatar(String patientName) {
    if (patientName.isEmpty) return 'P';
    
    final words = patientName.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}';
    } else {
      return words[0][0].toUpperCase();
    }
  }

  // 🗑️ SUPPRIMER UNE CONVERSATION (Soft Delete)
  static Future<void> deleteConversation(String conversationId, bool isPatient) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('ChatService: No authenticated user for conversation deletion');
        return;
      }

      print('ChatService: Deleting conversation: $conversationId for ${isPatient ? 'patient' : 'clinic'}');

      // Soft delete: marquer la conversation comme supprimée pour cet utilisateur
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isPatient) {
        updateData['deletedByPatient'] = true;
        updateData['deletedByPatientAt'] = FieldValue.serverTimestamp();
      } else {
        updateData['deletedByClinic'] = true;
        updateData['deletedByClinicAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .update(updateData);

      print('ChatService: Conversation marked as deleted successfully');

      // 🔥 Vérifier si la conversation a été supprimée par les deux parties
      final conversationDoc = await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .get();

      if (conversationDoc.exists) {
        final data = conversationDoc.data()!;
        final deletedByPatient = data['deletedByPatient'] ?? false;
        final deletedByClinic = data['deletedByClinic'] ?? false;

        // Si supprimée par les deux parties, supprimer définitivement
        if (deletedByPatient && deletedByClinic) {
          print('ChatService: Both parties deleted conversation, removing permanently');
          
          // Supprimer tous les messages de la conversation
          final messagesQuery = await _firestore
              .collection('chat_messages')
              .where('conversationId', isEqualTo: conversationId)
              .get();

          final batch = _firestore.batch();
          for (final doc in messagesQuery.docs) {
            batch.delete(doc.reference);
          }

          // Supprimer la conversation
          batch.delete(_firestore.collection('chat_conversations').doc(conversationId));
          
          await batch.commit();
          print('ChatService: ✅ Conversation and messages permanently deleted');
        }
      }

    } catch (e) {
      print('ChatService: ❌ Error deleting conversation: $e');
      throw e;
    }
  }

  // 📋 RÉCUPÉRER LES CONVERSATIONS NON SUPPRIMÉES POUR PATIENT
  static Stream<List<ChatConversation>> getPatientConversationsStream() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('ChatService: No authenticated user for patient conversations');
        return Stream.value([]);
      }

      print('ChatService: Getting patient conversations stream for: ${currentUser.uid}');

      return _firestore
          .collection('chat_conversations')
          .where('patientId', isEqualTo: currentUser.uid)
          .snapshots()
          .map((snapshot) {
        final conversations = <ChatConversation>[];
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          // Exclure les conversations supprimées par le patient
          final deletedByPatient = data['deletedByPatient'] ?? false;
          
          if (!deletedByPatient) {
            conversations.add(ChatConversation.fromFirestore(data, doc.id));
          }
        }
        
        // Trier par dernière activité
        conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        print('ChatService: Found ${conversations.length} active conversations for patient');
        return conversations;
      }).handleError((error) {
        print('ChatService: Error in patient conversations stream: $error');
        return <ChatConversation>[];
      });
    } catch (e) {
      print('ChatService: Error getting patient conversations stream: $e');
      return Stream.value([]);
    }
  }

  // 📋 RÉCUPÉRER LES CONVERSATIONS NON SUPPRIMÉES POUR CLINIQUE
  static Stream<List<ChatConversation>> getClinicConversationsStream() {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('ChatService: No authenticated user for clinic conversations');
        return Stream.value([]);
      }

      print('ChatService: Getting clinic conversations stream for: ${currentUser.uid}');

      return _firestore
          .collection('chat_conversations')
          .where('clinicId', isEqualTo: currentUser.uid)
          .snapshots()
          .map((snapshot) {
        final conversations = <ChatConversation>[];
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          // Exclure les conversations supprimées par la clinique
          final deletedByClinic = data['deletedByClinic'] ?? false;
          
          if (!deletedByClinic) {
            conversations.add(ChatConversation.fromFirestore(data, doc.id));
          }
        }
        
        // Trier par dernière activité
        conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        
        print('ChatService: Found ${conversations.length} active conversations for clinic');
        return conversations;
      }).handleError((error) {
        print('ChatService: Error in clinic conversations stream: $error');
        return <ChatConversation>[];
      });
    } catch (e) {
      print('ChatService: Error getting clinic conversations stream: $e');
      return Stream.value([]);
    }
  }

  // 🔧 Helper function pour récupérer l'image de l'hôpital depuis l'ID clinique
  static Future<String?> _getHospitalImageFromClinicId(String clinicId) async {
    try {
      print('ChatService: Looking for hospital image with clinic ID: $clinicId');
      
      final clinicDoc = await _firestore
          .collection('clinics')
          .doc(clinicId)
          .get();
      
      if (clinicDoc.exists) {
        final data = clinicDoc.data();
        
        // 🔧 FIX: Try multiple potential image field names for hospitals
        final List<String> imageFields = [
          'imageUrl',
          'profileImageUrl', 
          'image',
          'profileImage',
          'hospitalImage',
          'logo',
          'avatar',
          'picture'
        ];
        
        for (final field in imageFields) {
          final imageValue = data?[field];
          if (imageValue != null && imageValue.toString().isNotEmpty && imageValue.toString() != 'null') {
            print('ChatService: ✅ Found hospital image using field "$field": ${imageValue.toString().length > 50 ? imageValue.toString().substring(0, 50) + "..." : imageValue.toString()}');
            return imageValue.toString();
          }
        }
        
        print('ChatService: ⚠️ Hospital document exists but no valid image found in any field for clinic: $clinicId');
        print('ChatService: Available fields: ${data?.keys.toList()}');
      } else {
        print('ChatService: ❌ Hospital document not found for clinic ID: $clinicId');
      }
      
      return null;
    } catch (e) {
      print('ChatService: ❌ Error getting hospital image: $e');
      return null;
    }
  }

  // 🔧 FIX: Fonction utilitaire pour obtenir avatar patient par conversation
  static Future<String?> getPatientAvatarFromConversation(String conversationId) async {
    try {
      final conversationDoc = await _firestore
          .collection('chat_conversations')
          .doc(conversationId)
          .get();
      
      if (conversationDoc.exists) {
        final data = conversationDoc.data();
        final patientId = data?['patientId'];
        if (patientId != null) {
          return await getPatientAvatar(patientId);
        }
      }
      return null;
    } catch (e) {
      print('ChatService: Error getting patient avatar from conversation: $e');
      return null;
    }
  }
} 