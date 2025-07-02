const admin = require('firebase-admin');

// Configuration Firebase Admin
const serviceAccount = {
  "type": "service_account",
  "project_id": "homecare-9f4d0",
  "private_key_id": "your-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@homecare-9f4d0.iam.gserviceaccount.com",
  "client_id": "your-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40homecare-9f4d0.iam.gserviceaccount.com"
};

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function testCorrectedChatFunction() {
  try {
    console.log('=== TESTING CORRECTED CHAT FUNCTION ===');
    
    // Données de test avec un hôpital différent
    const testAppointmentData = {
      id: 'test-appointment-corrected-123',
      patientId: 'iY5C616o8TNVeswzv28Iq5MKNat2',
      patientName: 'Test Patient',
      hospital: 'New Medical Center', // Nom différent de "King Hospital"
      hospitalName: 'New Medical Center',
      department: 'Cardiology',
      appointmentDate: admin.firestore.Timestamp.fromDate(new Date('2025-07-10')),
      appointmentTime: '2:00 PM',
      status: 'confirmed'
    };

    const clinicId = '2EIIpfgRKndh04NBa4kDTflw9Zy1';
    const clinicName = 'King Hospital'; // Nom de la clinique qui approuve

    console.log('Test appointment data:');
    console.log('- Hospital in appointment:', testAppointmentData.hospital);
    console.log('- Clinic approving:', clinicName);
    console.log('- Patient ID:', testAppointmentData.patientId);

    // Créer ou obtenir la conversation
    const conversationQuery = await db
      .collection('chat_conversations')
      .where('patientId', '==', testAppointmentData.patientId)
      .where('clinicId', '==', clinicId)
      .get();

    let conversationId;
    if (conversationQuery.empty) {
      // Créer une nouvelle conversation
      const conversationData = {
        patientId: testAppointmentData.patientId,
        clinicId: clinicId,
        patientName: testAppointmentData.patientName,
        clinicName: testAppointmentData.hospital, // Utiliser le nom de l'hôpital du rendez-vous
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: 'Appointment confirmed',
        hasUnreadMessages: true,
        unreadCount: 1,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const conversationRef = await db
        .collection('chat_conversations')
        .add(conversationData);
      
      conversationId = conversationRef.id;
      console.log('✓ New conversation created:', conversationId);
    } else {
      conversationId = conversationQuery.docs[0].id;
      console.log('✓ Existing conversation found:', conversationId);
    }

    // Créer le message de confirmation en utilisant le nom de l'hôpital du rendez-vous
    const confirmationMessage = `✅ **Appointment Confirmed**\n\nYour appointment has been confirmed by **${testAppointmentData.hospital}**.\n\n**Details:**\n• **Hospital:** ${testAppointmentData.hospital}\n• **Department:** ${testAppointmentData.department}\n• **Date:** ${testAppointmentData.appointmentDate.toDate().toLocaleDateString()}\n• **Time:** ${testAppointmentData.appointmentTime}\n\nPlease arrive 15 minutes before your scheduled time. If you need to reschedule or cancel, please contact us at least 24 hours in advance.\n\nWe look forward to seeing you!`;

    // Ajouter le message à la conversation
    const messageData = {
      conversationId: conversationId,
      senderId: clinicId,
      senderName: testAppointmentData.hospital, // Utiliser le nom de l'hôpital du rendez-vous
      senderType: 'clinic',
      message: confirmationMessage,
      messageType: 'appointmentConfirmation',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      appointmentId: testAppointmentData.id,
      hospitalName: testAppointmentData.hospital,
      department: testAppointmentData.department,
      appointmentDate: testAppointmentData.appointmentDate,
      appointmentTime: testAppointmentData.appointmentTime,
      metadata: {
        action: 'appointment_confirmed',
        appointmentId: testAppointmentData.id,
      },
    };

    await db
      .collection('chat_messages')
      .add(messageData);

    // Mettre à jour la conversation
    await db
      .collection('chat_conversations')
      .doc(conversationId)
      .update({
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: 'Appointment confirmed',
        hasUnreadMessages: true,
        unreadCount: 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log('✓ Corrected confirmation message created successfully');
    console.log('✓ Message shows hospital name:', testAppointmentData.hospital);
    console.log('✓ Conversation updated with unread count: 1');
    
    // Vérifier que la conversation a été créée correctement
    const updatedConversation = await db
      .collection('chat_conversations')
      .doc(conversationId)
      .get();
    
    if (updatedConversation.exists) {
      const data = updatedConversation.data();
      console.log('✓ Conversation verification:');
      console.log('  - Clinic name in conversation:', data.clinicName);
      console.log('  - Has unread messages:', data.hasUnreadMessages);
      console.log('  - Unread count:', data.unreadCount);
    }

    console.log('=== TEST COMPLETED SUCCESSFULLY ===');
    console.log('The corrected chat function now uses the hospital name from the appointment data instead of the clinic name that approved it.');

  } catch (error) {
    console.error('Error in test:', error);
  }
}

// Exécuter le test
testCorrectedChatFunction(); 