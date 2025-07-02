const { initializeApp } = require("firebase/app");
const { getFirestore, collection, getDocs, query, where, addDoc, serverTimestamp, doc, getDoc, updateDoc } = require("firebase/firestore");

// Configuration Firebase
const firebaseConfig = {
  apiKey: "AIzaSyDYaKiltvi2oUAUO_mi4YNtqCpbJ3RbJI8",
  authDomain: "homecare-9f4d0.firebaseapp.com",
  projectId: "homecare-9f4d0",
  storageBucket: "homecare-9f4d0.firebasestorage.app",
  messagingSenderId: "54787084616",
  appId: "1:54787084616:android:7892366bf2029a3908a37d"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function fixChatSystem() {
  try {
    console.log('=== FIXING CHAT SYSTEM ===');
    
    // Step 1: Get all appointments
    console.log('\n📋 Step 1: Getting all appointments...');
    const appointmentsSnapshot = await getDocs(collection(db, 'appointments'));
    console.log(`Found ${appointmentsSnapshot.size} appointments`);
    
    // Step 2: Get all existing conversations
    console.log('\n💬 Step 2: Getting existing conversations...');
    const conversationsSnapshot = await getDocs(collection(db, 'chat_conversations'));
    console.log(`Found ${conversationsSnapshot.size} existing conversations`);
    
    // Create a map of existing conversations
    const existingConversations = new Map();
    conversationsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const key = `${data.patientId}-${data.clinicId}`;
      existingConversations.set(key, {
        id: doc.id,
        data: data
      });
    });
    
    // Step 3: Process each appointment
    console.log('\n🔧 Step 3: Processing appointments...');
    let createdConversations = 0;
    let createdMessages = 0;
    let skippedAppointments = 0;
    
    for (const appointmentDoc of appointmentsSnapshot.docs) {
      const appointmentData = appointmentDoc.data();
      const appointmentId = appointmentDoc.id;
      
      const patientId = appointmentData.patientId;
      const patientName = appointmentData.patientName;
      const hospitalName = appointmentData.hospital || appointmentData.hospitalName;
      
      if (!patientId || !patientName || !hospitalName) {
        console.log(`⚠️ Skipping appointment ${appointmentId}: missing required data`);
        skippedAppointments++;
        continue;
      }
      
      // Find clinic ID by hospital name
      const clinicId = await getClinicIdByName(hospitalName);
      if (!clinicId) {
        console.log(`⚠️ Skipping appointment ${appointmentId}: no clinic found for "${hospitalName}"`);
        skippedAppointments++;
        continue;
      }
      
      // Check if conversation already exists
      const conversationKey = `${patientId}-${clinicId}`;
      if (existingConversations.has(conversationKey)) {
        console.log(`✅ Conversation already exists for appointment ${appointmentId}`);
        continue;
      }
      
      // Create new conversation
      console.log(`📝 Creating conversation for appointment ${appointmentId}: ${patientName} -> ${hospitalName}`);
      
      try {
        const conversationData = {
          patientId: patientId,
          clinicId: clinicId,
          patientName: patientName,
          clinicName: hospitalName,
          lastMessageTime: serverTimestamp(),
          lastMessage: 'Appointment request created',
          hasUnreadMessages: true,
          unreadCount: 1,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        };
        
        const conversationRef = await addDoc(collection(db, 'chat_conversations'), conversationData);
        console.log(`✅ Created conversation: ${conversationRef.id}`);
        createdConversations++;
        
        // Create initial appointment request message
        const requestMessage = `📋 **New Appointment Request**

**Patient:** ${patientName}
**Department:** ${appointmentData.department || 'General'}
**Date:** ${appointmentData.appointmentDate?.toDate?.()?.toLocaleDateString() || 'Not specified'}
**Time:** ${appointmentData.appointmentTime || 'Not specified'}
**Duration:** ${appointmentData.meetingDuration || 30} minutes
**Reason:** ${appointmentData.reasonOfBooking || 'Not specified'}

Please approve or reject this appointment request.`;

        const messageData = {
          conversationId: conversationRef.id,
          senderId: patientId,
          senderName: patientName,
          senderType: 'patient',
          message: requestMessage,
          messageType: 'appointmentRequest',
          timestamp: serverTimestamp(),
          isRead: false,
          appointmentId: appointmentId,
          hospitalName: hospitalName,
          department: appointmentData.department,
          appointmentDate: appointmentData.appointmentDate,
          appointmentTime: appointmentData.appointmentTime,
          metadata: {
            action: 'appointment_request',
            appointmentId: appointmentId,
            status: 'pending',
          },
        };
        
        await addDoc(collection(db, 'chat_messages'), messageData);
        console.log(`✅ Created initial message for conversation ${conversationRef.id}`);
        createdMessages++;
        
        // If appointment is confirmed, create confirmation message
        if (appointmentData.status === 'confirmed') {
          console.log(`✅ Appointment ${appointmentId} is confirmed, creating confirmation message`);
          
          const confirmationMessage = `✅ **Appointment Confirmed**

Your appointment has been confirmed by **${hospitalName}**.

**Details:**
• **Hospital:** ${hospitalName}
• **Department:** ${appointmentData.department || 'General'}
• **Date:** ${appointmentData.appointmentDate?.toDate?.()?.toLocaleDateString() || 'Not specified'}
• **Time:** ${appointmentData.appointmentTime || 'Not specified'}

Please arrive 15 minutes before your scheduled time. If you need to reschedule or cancel, please contact us at least 24 hours in advance.

We look forward to seeing you!`;

          const confirmationMessageData = {
            conversationId: conversationRef.id,
            senderId: clinicId,
            senderName: hospitalName,
            senderType: 'clinic',
            message: confirmationMessage,
            messageType: 'appointmentConfirmation',
            timestamp: serverTimestamp(),
            isRead: false,
            appointmentId: appointmentId,
            hospitalName: hospitalName,
            department: appointmentData.department,
            appointmentDate: appointmentData.appointmentDate,
            appointmentTime: appointmentData.appointmentTime,
            metadata: {
              action: 'appointment_confirmed',
              appointmentId: appointmentId,
            },
          };
          
          await addDoc(collection(db, 'chat_messages'), confirmationMessageData);
          console.log(`✅ Created confirmation message for conversation ${conversationRef.id}`);
          createdMessages++;
          
          // Update conversation with confirmation message
          await updateDoc(doc(db, 'chat_conversations', conversationRef.id), {
            lastMessageTime: serverTimestamp(),
            lastMessage: 'Appointment confirmed',
            hasUnreadMessages: true,
            unreadCount: 1,
            updatedAt: serverTimestamp(),
          });
        }
        
      } catch (error) {
        console.error(`❌ Error creating conversation for appointment ${appointmentId}:`, error);
      }
    }
    
    console.log('\n📊 SUMMARY:');
    console.log(`Total appointments processed: ${appointmentsSnapshot.size}`);
    console.log(`Conversations created: ${createdConversations}`);
    console.log(`Messages created: ${createdMessages}`);
    console.log(`Appointments skipped: ${skippedAppointments}`);
    console.log(`Existing conversations: ${conversationsSnapshot.size}`);
    
    console.log('\n✅ Chat system fix completed!');
    
  } catch (error) {
    console.error('❌ Error fixing chat system:', error);
  }
}

async function getClinicIdByName(hospitalName) {
  try {
    const clinicsSnapshot = await getDocs(collection(db, 'clinics'));
    
    for (const doc of clinicsSnapshot.docs) {
      const clinicData = doc.data();
      const clinicName = clinicData.name || clinicData.clinicName;
      
      if (clinicName === hospitalName) {
        return doc.id;
      }
    }
    
    return null;
  } catch (error) {
    console.error('Error finding clinic by name:', error);
    return null;
  }
}

// Run the fix
fixChatSystem(); 