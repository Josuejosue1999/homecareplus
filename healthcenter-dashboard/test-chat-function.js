const { db, doc, getDoc, collection, query, where, orderBy, getDocs, updateDoc, addDoc, serverTimestamp } = require("./config/firebase");

// Test data
const testAppointmentData = {
  id: 'test-appointment-123',
  patientId: 'iY5C616o8TNVeswzv28Iq5MKNat2', // Patient ID from logs
  patientName: 'Test Patient',
  hospital: 'king Hospital',
  hospitalName: 'king Hospital',
  department: 'General Medicine',
  appointmentDate: new Date('2025-07-06'),
  appointmentTime: '10:00 AM'
};

const testClinicName = 'king Hospital';
const testClinicId = '2EIIpfgRKndh04NBa4kDTflw9Zy1'; // Clinic ID from logs

async function testCreateAppointmentConfirmationMessage() {
  try {
    console.log('=== TESTING CHAT FUNCTION ===');
    console.log('Patient ID:', testAppointmentData.patientId);
    console.log('Clinic ID:', testClinicId);
    console.log('Clinic Name:', testClinicName);
    
    const patientId = testAppointmentData.patientId;
    const patientName = testAppointmentData.patientName;
    const hospitalName = testAppointmentData.hospital || testAppointmentData.hospitalName;
    const department = testAppointmentData.department;
    const appointmentDate = testAppointmentData.appointmentDate;
    const appointmentTime = testAppointmentData.appointmentTime;
    const appointmentId = testAppointmentData.id || testAppointmentData.appointmentId || null;

    console.log('Looking for existing conversation...');
    
    // Créer ou obtenir la conversation
    const conversationQuery = await getDocs(
      query(
        collection(db, 'chat_conversations'),
        where('patientId', '==', patientId),
        where('clinicId', '==', testClinicId)
      )
    );

    let conversationId;
    if (conversationQuery.empty) {
      console.log('No existing conversation found, creating new one...');
      // Créer une nouvelle conversation
      const conversationData = {
        patientId: patientId,
        clinicId: testClinicId,
        patientName: patientName,
        clinicName: testClinicName,
        lastMessageTime: serverTimestamp(),
        lastMessage: 'Appointment confirmed',
        hasUnreadMessages: true,
        unreadCount: 1,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };

      const conversationRef = await addDoc(collection(db, 'chat_conversations'), conversationData);
      
      conversationId = conversationRef.id;
      console.log('✓ New conversation created:', conversationId);
    } else {
      conversationId = conversationQuery.docs[0].id;
      console.log('✓ Existing conversation found:', conversationId);
    }

    // Créer le message de confirmation
    const confirmationMessage = `✅ **Appointment Confirmed**\n\nYour appointment has been confirmed by **${testClinicName}**.\n\n**Details:**\n• **Hospital:** ${hospitalName}\n• **Department:** ${department}\n• **Date:** ${appointmentDate.toLocaleDateString()}\n• **Time:** ${appointmentTime}\n\nPlease arrive 15 minutes before your scheduled time. If you need to reschedule or cancel, please contact us at least 24 hours in advance.\n\nWe look forward to seeing you!`;

    console.log('Creating confirmation message...');

    // Ajouter le message à la conversation
    const messageData = {
      conversationId: conversationId,
      senderId: testClinicId,
      senderName: testClinicName,
      senderType: 'clinic',
      message: confirmationMessage,
      messageType: 'appointmentConfirmation',
      timestamp: serverTimestamp(),
      isRead: false,
      appointmentId: appointmentId,
      hospitalName: hospitalName,
      department: department,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      metadata: {
        action: 'appointment_confirmed',
        appointmentId: appointmentId,
      },
    };

    await addDoc(collection(db, 'chat_messages'), messageData);
    console.log('✓ Message created successfully');

    // Mettre à jour la conversation
    await updateDoc(doc(db, 'chat_conversations', conversationId), {
      lastMessageTime: serverTimestamp(),
      lastMessage: 'Appointment confirmed',
      hasUnreadMessages: true,
      unreadCount: 1,
      updatedAt: serverTimestamp(),
    });
    console.log('✓ Conversation updated successfully');

    console.log('=== TEST COMPLETED SUCCESSFULLY ===');
    console.log('Conversation ID:', conversationId);
    console.log('Patient should now see the message in their chat!');
    
    return conversationId;

  } catch (error) {
    console.error('Error in test:', error);
    throw error;
  }
}

// Run the test
testCreateAppointmentConfirmationMessage()
  .then(() => {
    console.log('Test completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Test failed:', error);
    process.exit(1);
  }); 