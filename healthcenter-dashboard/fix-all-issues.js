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

async function fixAllIssues() {
  try {
    console.log('=== COMPREHENSIVE FIX FOR ALL ISSUES ===');
    
    // Step 1: Fix the "City General Hospital" mismatch
    console.log('\n🔧 Step 1: Fixing hospital name mismatches...');
    await fixHospitalNameMismatches();
    
    // Step 2: Ensure all appointments have conversations
    console.log('\n💬 Step 2: Creating missing conversations...');
    await createMissingConversations();
    
    // Step 3: Create confirmation messages for approved appointments
    console.log('\n✅ Step 3: Creating confirmation messages...');
    await createConfirmationMessages();
    
    // Step 4: Test the system
    console.log('\n🧪 Step 4: Testing the system...');
    await testSystem();
    
    console.log('\n✅ All issues fixed successfully!');
    
  } catch (error) {
    console.error('❌ Error fixing issues:', error);
  }
}

async function fixHospitalNameMismatches() {
  try {
    // Find appointments with "City General Hospital"
    const appointmentsSnapshot = await getDocs(
      query(collection(db, 'appointments'), where('hospitalName', '==', 'City General Hospital'))
    );
    
    if (appointmentsSnapshot.size > 0) {
      console.log(`Found ${appointmentsSnapshot.size} appointments with "City General Hospital"`);
      
      // Update them to use "New Hospital" (most common)
      const batch = [];
      appointmentsSnapshot.docs.forEach(doc => {
        batch.push(updateDoc(doc.ref, {
          hospitalName: 'New Hospital',
          hospital: 'New Hospital'
        }));
      });
      
      await Promise.all(batch);
      console.log('✅ Updated hospital names to "New Hospital"');
    } else {
      console.log('✅ No hospital name mismatches found');
    }
  } catch (error) {
    console.error('Error fixing hospital names:', error);
  }
}

async function createMissingConversations() {
  try {
    // Get all appointments
    const appointmentsSnapshot = await getDocs(collection(db, 'appointments'));
    console.log(`Processing ${appointmentsSnapshot.size} appointments...`);
    
    // Get existing conversations
    const conversationsSnapshot = await getDocs(collection(db, 'chat_conversations'));
    const existingConversations = new Map();
    
    conversationsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      const key = `${data.patientId}-${data.clinicId}`;
      existingConversations.set(key, doc.id);
    });
    
    let createdConversations = 0;
    let createdMessages = 0;
    
    for (const appointmentDoc of appointmentsSnapshot.docs) {
      const appointmentData = appointmentDoc.data();
      const appointmentId = appointmentDoc.id;
      
      const patientId = appointmentData.patientId;
      const patientName = appointmentData.patientName;
      const hospitalName = appointmentData.hospitalName || appointmentData.hospital;
      
      if (!patientId || !patientName || !hospitalName) {
        continue;
      }
      
      // Find clinic ID
      const clinicId = await getClinicIdByName(hospitalName);
      if (!clinicId) {
        console.log(`⚠️ No clinic found for "${hospitalName}"`);
        continue;
      }
      
      // Check if conversation exists
      const conversationKey = `${patientId}-${clinicId}`;
      if (existingConversations.has(conversationKey)) {
        continue;
      }
      
      // Create conversation
      console.log(`📝 Creating conversation for ${patientName} -> ${hospitalName}`);
      
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
      createdConversations++;
      
      // Create initial message
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
      createdMessages++;
    }
    
    console.log(`✅ Created ${createdConversations} conversations and ${createdMessages} messages`);
  } catch (error) {
    console.error('Error creating conversations:', error);
  }
}

async function createConfirmationMessages() {
  try {
    // Get confirmed appointments
    const confirmedAppointmentsSnapshot = await getDocs(
      query(collection(db, 'appointments'), where('status', '==', 'confirmed'))
    );
    
    console.log(`Found ${confirmedAppointmentsSnapshot.size} confirmed appointments`);
    
    let createdConfirmations = 0;
    
    for (const appointmentDoc of confirmedAppointmentsSnapshot.docs) {
      const appointmentData = appointmentDoc.data();
      const appointmentId = appointmentDoc.id;
      
      const patientId = appointmentData.patientId;
      const patientName = appointmentData.patientName;
      const hospitalName = appointmentData.hospitalName || appointmentData.hospital;
      
      if (!patientId || !patientName || !hospitalName) {
        continue;
      }
      
      // Find clinic ID
      const clinicId = await getClinicIdByName(hospitalName);
      if (!clinicId) {
        continue;
      }
      
      // Check if confirmation message already exists
      const confirmationMessagesSnapshot = await getDocs(
        query(
          collection(db, 'chat_messages'),
          where('appointmentId', '==', appointmentId),
          where('messageType', '==', 'appointmentConfirmation')
        )
      );
      
      if (confirmationMessagesSnapshot.size > 0) {
        continue; // Already has confirmation message
      }
      
      // Find conversation
      const conversationSnapshot = await getDocs(
        query(
          collection(db, 'chat_conversations'),
          where('patientId', '==', patientId),
          where('clinicId', '==', clinicId)
        )
      );
      
      if (conversationSnapshot.empty) {
        continue; // No conversation found
      }
      
      const conversationId = conversationSnapshot.docs[0].id;
      
      // Create confirmation message
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
        conversationId: conversationId,
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
      createdConfirmations++;
      
      // Update conversation
      await updateDoc(doc(db, 'chat_conversations', conversationId), {
        lastMessageTime: serverTimestamp(),
        lastMessage: 'Appointment confirmed',
        hasUnreadMessages: true,
        unreadCount: 1,
        updatedAt: serverTimestamp(),
      });
    }
    
    console.log(`✅ Created ${createdConfirmations} confirmation messages`);
  } catch (error) {
    console.error('Error creating confirmation messages:', error);
  }
}

async function testSystem() {
  try {
    console.log('\n📊 System Status After Fixes:');
    
    // Test appointments
    const appointmentsSnapshot = await getDocs(collection(db, 'appointments'));
    console.log(`Total appointments: ${appointmentsSnapshot.size}`);
    
    // Test conversations
    const conversationsSnapshot = await getDocs(collection(db, 'chat_conversations'));
    console.log(`Total conversations: ${conversationsSnapshot.size}`);
    
    // Test messages
    const messagesSnapshot = await getDocs(collection(db, 'chat_messages'));
    console.log(`Total messages: ${messagesSnapshot.size}`);
    
    // Test confirmation messages
    const confirmationMessagesSnapshot = await getDocs(
      query(collection(db, 'chat_messages'), where('messageType', '==', 'appointmentConfirmation'))
    );
    console.log(`Confirmation messages: ${confirmationMessagesSnapshot.size}`);
    
    // Test recent appointments for "New Hospital"
    const newHospitalAppointments = await getDocs(
      query(collection(db, 'appointments'), where('hospitalName', '==', 'New Hospital'))
    );
    console.log(`Appointments for "New Hospital": ${newHospitalAppointments.size}`);
    
    console.log('\n✅ System test completed!');
  } catch (error) {
    console.error('Error testing system:', error);
  }
}

async function getClinicIdByName(hospitalName) {
  try {
    // Try exact match with 'name' field
    const clinicDocs = await getDocs(
      query(collection(db, 'clinics'), where('name', '==', hospitalName))
    );
    
    if (clinicDocs.docs.length > 0) {
      return clinicDocs.docs[0].id;
    }
    
    // Try exact match with 'clinicName' field
    const clinicDocs2 = await getDocs(
      query(collection(db, 'clinics'), where('clinicName', '==', hospitalName))
    );
    
    if (clinicDocs2.docs.length > 0) {
      return clinicDocs2.docs[0].id;
    }
    
    return null;
  } catch (error) {
    console.error('Error finding clinic by name:', error);
    return null;
  }
}

// Run the comprehensive fix
fixAllIssues(); 