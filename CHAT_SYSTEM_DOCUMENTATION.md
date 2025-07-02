# Système de Chat - HomeCare Plus

## Vue d'ensemble

Le système de chat permet une communication en temps réel entre les patients et les cliniques. Il inclut des notifications automatiques pour les confirmations et annulations de rendez-vous, ainsi qu'une interface de chat complète pour les conversations.

## Fonctionnalités principales

### 1. Notifications automatiques de rendez-vous
- **Confirmation de rendez-vous** : Envoi automatique d'un message de confirmation quand une clinique approuve un rendez-vous
- **Annulation de rendez-vous** : Envoi automatique d'un message d'annulation avec raison quand une clinique rejette un rendez-vous
- **Messages formatés** : Les messages incluent tous les détails du rendez-vous (hôpital, département, date, heure)

### 2. Interface de chat complète
- **Liste des conversations** : Affichage de toutes les conversations du patient avec les cliniques
- **Conversation individuelle** : Interface de chat en temps réel pour chaque conversation
- **Indicateurs de lecture** : Badges pour les messages non lus
- **Historique des messages** : Conservation de l'historique complet des conversations

### 3. Badges de notification
- **Badge sur l'icône Messages** : Affichage du nombre de conversations avec des messages non lus
- **Mise à jour en temps réel** : Les badges se mettent à jour automatiquement

## Architecture technique

### Modèles de données

#### ChatMessage
```dart
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final SenderType senderType; // patient, clinic, system
  final String message;
  final MessageType messageType; // text, appointmentConfirmation, appointmentCancellation, etc.
  final DateTime timestamp;
  final bool isRead;
  final String? appointmentId;
  final String? hospitalName;
  final String? department;
  final DateTime? appointmentDate;
  final String? appointmentTime;
  final Map<String, dynamic>? metadata;
}
```

#### ChatConversation
```dart
class ChatConversation {
  final String id;
  final String patientId;
  final String clinicId;
  final String patientName;
  final String clinicName;
  final DateTime lastMessageTime;
  final String lastMessage;
  final bool hasUnreadMessages;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

### Services

#### ChatService
- `getPatientConversations()` : Récupère toutes les conversations d'un patient
- `getConversationMessages(conversationId)` : Récupère les messages d'une conversation
- `sendMessage()` : Envoie un nouveau message
- `sendAppointmentConfirmationMessage()` : Envoie un message de confirmation automatique
- `sendAppointmentCancellationMessage()` : Envoie un message d'annulation automatique
- `markMessagesAsRead()` : Marque les messages comme lus
- `getOrCreateConversation()` : Crée ou récupère une conversation existante

### API côté serveur

#### Routes principales
- `POST /api/appointments/:appointmentId/send-confirmation-message` : Envoie un message de confirmation
- `POST /api/appointments/:appointmentId/send-cancellation-message` : Envoie un message d'annulation
- `GET /api/clinic/info` : Récupère les informations de la clinique connectée

## Utilisation

### Pour les patients

1. **Accéder au chat** : Cliquer sur l'icône "Messages" dans la navigation
2. **Voir les conversations** : La liste affiche toutes les conversations avec les cliniques
3. **Ouvrir une conversation** : Cliquer sur une conversation pour voir les messages
4. **Répondre** : Taper un message et cliquer sur envoyer
5. **Notifications** : Les messages de confirmation/annulation apparaissent automatiquement

### Pour les cliniques (Dashboard web)

1. **Approuver un rendez-vous** : 
   - Cliquer sur "View Details" d'un rendez-vous
   - Cliquer sur "Approve"
   - Un message de confirmation est automatiquement envoyé au patient

2. **Rejeter un rendez-vous** :
   - Cliquer sur "View Details" d'un rendez-vous
   - Cliquer sur "Reject"
   - Saisir une raison
   - Un message d'annulation est automatiquement envoyé au patient

## Structure des collections Firestore

### chat_conversations
```javascript
{
  patientId: "string",
  clinicId: "string", 
  patientName: "string",
  clinicName: "string",
  lastMessageTime: "timestamp",
  lastMessage: "string",
  hasUnreadMessages: "boolean",
  unreadCount: "number",
  createdAt: "timestamp",
  updatedAt: "timestamp"
}
```

### chat_messages
```javascript
{
  conversationId: "string",
  senderId: "string",
  senderName: "string",
  senderType: "string", // "patient", "clinic", "system"
  message: "string",
  messageType: "string", // "text", "appointmentConfirmation", "appointmentCancellation"
  timestamp: "timestamp",
  isRead: "boolean",
  appointmentId: "string?",
  hospitalName: "string?",
  department: "string?",
  appointmentDate: "timestamp?",
  appointmentTime: "string?",
  metadata: "object?"
}
```

## Messages automatiques

### Confirmation de rendez-vous
```
🎉 **Appointment Confirmed!**

Your appointment has been confirmed by **{clinicName}**.

**Details:**
• **Hospital:** {hospitalName}
• **Department:** {department}
• **Date:** {date}
• **Time:** {time}

Please arrive 15 minutes before your scheduled time. If you need to reschedule or cancel, please contact us as soon as possible.

Thank you for choosing our services!
```

### Annulation de rendez-vous
```
❌ **Appointment Cancelled**

Your appointment has been cancelled by **{clinicName}**.

**Details:**
• **Hospital:** {hospitalName}
• **Department:** {department}
• **Date:** {date}
• **Time:** {time}
• **Reason:** {reason}

Please contact us to reschedule your appointment at your convenience.

We apologize for any inconvenience caused.
```

## Sécurité et performance

### Sécurité
- Authentification requise pour toutes les opérations
- Vérification des permissions (patient ne peut voir que ses conversations)
- Validation des données côté serveur

### Performance
- Pagination des messages pour les longues conversations
- Mise en cache des informations de conversation
- Mise à jour en temps réel avec Firestore

## Maintenance

### Nettoyage automatique
- Les anciens messages peuvent être supprimés après une période définie
- Les conversations inactives peuvent être archivées

### Monitoring
- Logs détaillés pour le débogage
- Métriques de performance
- Alertes en cas d'erreur

## Évolutions futures

1. **Notifications push** : Intégration avec Firebase Cloud Messaging
2. **Fichiers joints** : Support pour les images et documents
3. **Messages vocaux** : Enregistrement et envoi de messages vocaux
4. **Chat de groupe** : Conversations avec plusieurs médecins
5. **Intégration IA** : Assistant virtuel pour les questions fréquentes 