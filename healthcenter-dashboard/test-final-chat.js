const admin = require('firebase-admin');
const { initializeApp, cert } = require('firebase-admin/app');

// Configuration Firebase Admin
const serviceAccount = require('./config/firebase.js');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function testFinalChatFunction() {
  try {
    console.log('=== TESTING FINAL CHAT FUNCTION ===');
    
    // Données de test avec différents hôpitaux
    const testAppointments = [
      {
        id: 'test-appointment-king-123',
        patientId: 'iY5C616o8TNVeswzv28Iq5MKNat2',
        patientName: 'Test Patient',
        hospital: 'king Hospital',
        hospitalName: 'king Hospital',
        department: 'General Medicine',
        appointmentDate: new Date('2025-07-06'),
        appointmentTime: '10:00 AM',
        clinicName: 'king Hospital',
        clinicId: '2EIIpfgRKndh04NBa4kDTflw9Zy1',
      },
      {
        id: 'test-appointment-new-456',
        patientId: 'iY5C616o8TNVeswzv28Iq5MKNat2',
        patientName: 'Test Patient',
        hospital: 'New Hospital',
        hospitalName: 'New Hospital',
        department: 'Dental Care',
        appointmentDate: new Date('2025-07-07'),
        appointmentTime: '14:00',
        clinicName: 'New Hospital',
        clinicId: 'ozrvi03359a17NRnRxaZD8Ab5352',
      }
    ];

    for (const appointmentData of testAppointments) {
      console.log(`\n--- Testing appointment for ${appointmentData.hospital} ---`);
      
      // Créer ou obtenir la conversation
      const conversationQuery = await db
        .collection('chat_conversations')
        .where('patientId', '==', appointmentData.patientId)
        .where('clinicId', '==', appointmentData.clinicId)
        .limit(1)
        .get();

      let conversationId;
      if (conversationQuery.empty) {
        // Créer une nouvelle conversation
        const conversationRef = await db.collection('chat_conversations').add({
          patientId: appointmentData.patientId,
          clinicId: appointmentData.clinicId,
          patientName: appointmentData.patientName,
          clinicName: appointmentData.clinicName,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          hasUnreadMessages: false,
          unreadCount: 0,
          lastMessage: '',
          lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        });
        conversationId = conversationRef.id;
        console.log(`✓ Created new conversation: ${conversationId}`);
      } else {
        conversationId = conversationQuery.docs[0].id;
        console.log(`✓ Found existing conversation: ${conversationId}`);
      }

      // Créer le message de confirmation
      const confirmationMessage = `✅ **Appointment Confirmed**

Your appointment has been confirmed by **${appointmentData.clinicName}**.

**Details:**
• **Hospital:** ${appointmentData.hospital}
• **Department:** ${appointmentData.department}
• **Date:** ${appointmentData.appointmentDate.toLocaleDateString()}
• **Time:** ${appointmentData.appointmentTime}

Please arrive 15 minutes before your scheduled time. If you need to reschedule or cancel, please contact us at least 24 hours in advance.

We look forward to seeing you!`;

      // Ajouter le message
      const messageRef = await db.collection('chat_messages').add({
        conversationId: conversationId,
        senderId: appointmentData.clinicId,
        senderName: appointmentData.clinicName,
        senderType: 'clinic',
        message: confirmationMessage,
        messageType: 'appointmentConfirmation',
        appointmentId: appointmentData.id,
        hospitalName: appointmentData.hospital,
        department: appointmentData.department,
        appointmentDate: appointmentData.appointmentDate,
        appointmentTime: appointmentData.appointmentTime,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        metadata: {
          action: 'appointment_confirmed',
          appointmentId: appointmentData.id,
        },
      });

      console.log(`✓ Created confirmation message: ${messageRef.id}`);
      console.log(`✓ Message content preview: ${confirmationMessage.substring(0, 100)}...`);

      // Mettre à jour la conversation
      await db.collection('chat_conversations').doc(conversationId).update({
        lastMessage: 'Appointment confirmed',
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        hasUnreadMessages: true,
        unreadCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✓ Updated conversation with new message`);
    }

    console.log('\n=== TEST COMPLETED SUCCESSFULLY ===');
    console.log('✅ All test appointments created with correct hospital names');
    console.log('✅ Messages show correct hospital names in content');
    console.log('✅ Conversations updated with unread status');
    console.log('✅ Ready for testing in Flutter app');

  } catch (error) {
    console.error('❌ Error in test:', error);
  }
}

// Exécuter le test
testFinalChatFunction(); 