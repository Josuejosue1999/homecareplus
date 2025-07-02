import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'dart:convert';

class ChatConversationPage extends StatefulWidget {
  final String conversationId;
  final String otherPartyName;
  final bool isClinic;

  const ChatConversationPage({
    Key? key,
    required this.conversationId,
    required this.otherPartyName,
    required this.isClinic,
  }) : super(key: key);

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _hospitalImage;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _loadHospitalImage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitalImage() async {
    try {
      // Récupérer l'image de l'hôpital depuis la conversation
      final conversationDoc = await FirebaseFirestore.instance
          .collection('chat_conversations')
          .doc(widget.conversationId)
          .get();
      
      if (conversationDoc.exists) {
        final conversationData = conversationDoc.data();
        setState(() {
          _hospitalImage = conversationData?['hospitalImage'];
        });
      }
    } catch (e) {
      print('Error loading hospital image: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    await ChatService.markMessagesAsRead(widget.conversationId);
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Obtenir les informations de l'utilisateur
      String senderName = 'Unknown';
      if (widget.isClinic) {
        // Si c'est une clinique, obtenir le nom de la clinique
        final clinicDoc = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(currentUser.uid)
            .get();
        senderName = clinicDoc.data()?['name'] ?? clinicDoc.data()?['clinicName'] ?? 'Clinic';
      } else {
        // Si c'est un patient, obtenir le nom du patient
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        senderName = userDoc.data()?['name'] ?? userDoc.data()?['fullName'] ?? 'Patient';
      }

      await ChatService.sendMessage(
        conversationId: widget.conversationId,
        senderId: currentUser.uid,
        senderName: senderName,
        senderType: widget.isClinic ? SenderType.clinic : SenderType.patient,
        message: _messageController.text.trim(),
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 🗑️ SUPPRIMER UNE CONVERSATION
  Future<void> _showDeleteConversationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Conversation?'),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this conversation with ${widget.otherPartyName}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _deleteConversation();
    }
  }

  Future<void> _deleteConversation() async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
          ),
        ),
      );

      // Supprimer la conversation
      await ChatService.deleteConversation(widget.conversationId, !widget.isClinic);

      // Fermer l'indicateur de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Retourner à la page précédente
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Conversation deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      // Fermer l'indicateur de chargement
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting conversation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF159BBD),
        title: Row(
          children: [
            _buildHospitalAvatar(widget.otherPartyName, _hospitalImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherPartyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  StreamBuilder<int>(
                    stream: ChatService.getPatientUnreadConversationCount(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data! > 0) {
                        return const Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String choice) {
              if (choice == 'delete') {
                _showDeleteConversationDialog();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete Conversation', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: ChatService.getConversationMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderType == (widget.isClinic ? SenderType.clinic : SenderType.patient);
                    
                    return _buildMessageBubble(message, isCurrentUser);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    final isSpecialMessage = message.messageType != MessageType.text;
    
    // Déterminer la logique d'alignement moderne style WhatsApp
    // Patient = gauche, Hôpital = droite (inversé de isCurrentUser pour avoir un comportement WhatsApp)
    final isFromPatient = message.senderType == SenderType.patient;
    final shouldAlignLeft = isFromPatient; // Messages patient à gauche
    final shouldAlignRight = !isFromPatient; // Messages hôpital à droite
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: shouldAlignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar à gauche pour les messages patient
          if (shouldAlignLeft) ...[
            _buildModernAvatar(message.senderName, message.senderType, hospitalImage: message.hospitalImage),
            const SizedBox(width: 8),
          ],
          
          // Container pour la bulle de message
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: shouldAlignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                children: [
                  // Nom de l'expéditeur
                  if (shouldAlignLeft)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 4),
                      child: Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  
                  // Bulle de message moderne
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: shouldAlignLeft
                          ? (isSpecialMessage ? Colors.blue[50] : Colors.grey[100])
                          : const Color(0xFF159BBD),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: shouldAlignLeft ? const Radius.circular(4) : const Radius.circular(20),
                        bottomRight: shouldAlignRight ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                      border: isSpecialMessage && shouldAlignLeft
                          ? Border.all(color: Colors.blue.withOpacity(0.3))
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSpecialMessage)
                          _buildSpecialMessageContent(message),
                        
                        Text(
                          message.message,
                          style: TextStyle(
                            color: shouldAlignLeft ? Colors.black87 : Colors.white,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // Timestamp et statut de lecture
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              DateFormat('HH:mm').format(message.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: shouldAlignLeft 
                                    ? Colors.grey[500] 
                                    : Colors.white.withOpacity(0.7),
                              ),
                            ),
                            if (shouldAlignRight) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isRead ? Icons.done_all : Icons.done,
                                size: 14,
                                color: message.isRead 
                                    ? Colors.blue[200] 
                                    : Colors.white.withOpacity(0.7),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Avatar à droite pour les messages hôpital
          if (shouldAlignRight) ...[
            const SizedBox(width: 8),
            _buildModernAvatar(message.senderName, message.senderType, hospitalImage: message.hospitalImage),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageAvatar(String senderName, SenderType senderType, {String? hospitalImage}) {
    if (senderType == SenderType.clinic) {
      // Si on a une vraie image de l'hôpital depuis le message, l'utiliser
      if (hospitalImage != null && hospitalImage.isNotEmpty) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF159BBD).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildHospitalImageWidget(hospitalImage),
          ),
        );
      }

      // Fallback vers le mapping statique si pas d'image Firebase
      final hospitalImages = {
        'king Hospital': 'assets/hospital.PNG',
        'King Hospital': 'assets/hospital.PNG',
        'New Hospital': 'assets/hospital2.PNG',
        'newclinic': 'assets/hospital.PNG',
      };

      final imagePath = hospitalImages[senderName] ?? 'assets/hospital.PNG';

      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF159BBD).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderMessageAvatar();
            },
          ),
        ),
      );
    } else {
      // Avatar pour les patients avec vraie image de profil ou initiales
      return FutureBuilder<String?>(
        future: ChatService.getPatientAvatar(FirebaseAuth.instance.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            // Utiliser la vraie image de profil du patient
            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF159BBD).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: snapshot.data!.startsWith('data:image') 
                  ? Image.memory(
                      base64Decode(snapshot.data!.split(',')[1]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPatientInitialsAvatar(senderName);
                      },
                    )
                  : snapshot.data!.startsWith('http')
                    ? Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPatientInitialsAvatar(senderName);
                        },
                      )
                    : _buildPatientInitialsAvatar(senderName),
              ),
            );
          } else {
            // Utiliser les initiales du patient comme fallback
            return _buildPatientInitialsAvatar(senderName);
          }
        },
      );
    }
  }

  Widget _buildHospitalImageWidget(String imageUrl) {
    // Check if it's a base64 image (starts with data:image)
    if (imageUrl.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(imageUrl.split(',')[1]),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderMessageAvatar();
          },
        );
      } catch (e) {
        print('Error decoding base64 image: $e');
        return _buildPlaceholderMessageAvatar();
      }
    }
    
    // Check if it's a network URL
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderMessageAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
            ),
          );
        },
      );
    }
    
    // Check if it's an asset
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderMessageAvatar();
        },
      );
    }
    
    // Default fallback
    return _buildPlaceholderMessageAvatar();
  }

  Widget _buildPlaceholderMessageAvatar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF159BBD).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Icon(
        Icons.local_hospital,
        color: Color(0xFF159BBD),
        size: 16,
      ),
    );
  }

  Widget _buildSpecialMessageContent(ChatMessage message) {
    switch (message.messageType) {
      case MessageType.appointmentConfirmation:
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Appointment Confirmed',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      case MessageType.appointmentCancellation:
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Appointment Cancelled',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF159BBD)),
                          ),
                        ),
                      )
                    : null,
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF159BBD),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalAvatar(String otherPartyName, String? hospitalImage) {
    // Si on a une vraie image de l'hôpital depuis Firebase, l'utiliser
    if (hospitalImage != null && hospitalImage.isNotEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: _buildHospitalImageWidget(hospitalImage),
        ),
      );
    }

    // Fallback vers le mapping statique si pas d'image Firebase
    final hospitalImages = {
      'king Hospital': 'assets/hospital.PNG',
      'King Hospital': 'assets/hospital.PNG',
      'New Hospital': 'assets/hospital2.PNG',
      'newclinic': 'assets/hospital.PNG',
    };

    final imagePath = hospitalImages[otherPartyName] ?? 'assets/hospital.PNG';

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderAvatar();
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.local_hospital,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildPatientInitialsAvatar(String patientName) {
    final initials = ChatService.getDefaultAvatar(patientName);
    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF159BBD),
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Avatar moderne pour les messages style WhatsApp
  Widget _buildModernAvatar(String senderName, SenderType senderType, {String? hospitalImage}) {
    if (senderType == SenderType.clinic) {
      // Avatar de l'hôpital avec image ou placeholder
      return FutureBuilder<String?>(
        future: Future.value(hospitalImage),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF159BBD).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _buildHospitalImageWidget(snapshot.data!),
              ),
            );
          } else {
            // Placeholder professionnel pour l'hôpital
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF159BBD).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF159BBD).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.local_hospital,
                color: Color(0xFF159BBD),
                size: 20,
              ),
            );
          }
        },
      );
    } else {
      // Avatar du patient avec image ou initiales
      return FutureBuilder<String?>(
        future: _getPatientAvatarBySenderId(senderName),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: snapshot.data!.startsWith('data:image') 
                  ? Image.memory(
                      base64Decode(snapshot.data!.split(',')[1]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPatientInitialsAvatar(senderName);
                      },
                    )
                  : snapshot.data!.startsWith('http')
                    ? Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPatientInitialsAvatar(senderName);
                        },
                      )
                    : _buildPatientInitialsAvatar(senderName),
              ),
            );
          } else {
            // Avatar avec initiales du patient
            final initials = ChatService.getDefaultAvatar(senderName);
            return CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }
        },
      );
    }
  }

  // Récupérer l'avatar du patient via plusieurs méthodes
  Future<String?> _getPatientAvatarBySenderId(String senderName) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        return await ChatService.getPatientAvatar(currentUser.uid);
      }
      return null;
    } catch (e) {
      print('Error getting patient avatar: $e');
      return null;
    }
  }
} 