const { db, collection, addDoc, updateDoc, doc, serverTimestamp, query, where, orderBy, getDocs } = require('./config/firebase.js');

async function testRealTimeNotifications() {
  console.log('🔧 Testing real-time notifications system...\n');
  
  const clinicId = '2EIIpfgRKndh04NBa4kDTflw9Zy1'; // king Hospital
  const patientName = 'Test Patient ' + Date.now();
  const appointmentId = 'test_' + Date.now();
  
  try {
    // 1. Create a new conversation (simulating mobile app)
    console.log('📱 Step 1: Creating new conversation (simulating mobile app)...');
    
    const conversationData = {
      clinicId: clinicId,
      clinicName: 'king Hospital',
      patientId: 'test_patient_' + Date.now(),
      patientName: patientName,
      appointmentId: appointmentId,
      appointmentType: 'General Consultation',
      status: 'pending',
      createdAt: serverTimestamp(),
      lastMessageTime: serverTimestamp(),
      lastMessage: 'Nouvelle demande de rendez-vous',
      unreadCount: 1,
      isActive: true
    };
    
    const conversationRef = await addDoc(collection(db, 'chat_conversations'), conversationData);
    console.log(`✅ Conversation created with ID: ${conversationRef.id}`);
    
    // 2. Add initial message
    console.log('💬 Step 2: Adding initial message...');
    
    const messageData = {
      conversationId: conversationRef.id,
      senderId: conversationData.patientId,
      senderName: patientName,
      senderType: 'patient',
      content: `Bonjour, je souhaite prendre un rendez-vous pour une consultation générale. Détails du rendez-vous:\n\nType: General Consultation\nPatient: ${patientName}\nStatut: En attente`,
      messageType: 'appointment_request',
      timestamp: serverTimestamp(),
      read: false,
      appointmentDetails: {
        appointmentId: appointmentId,
        type: 'General Consultation',
        status: 'pending'
      }
    };
    
    await addDoc(collection(db, 'chat_messages'), messageData);
    console.log('✅ Initial message added');
    
    // 3. Test dashboard query (simulating web dashboard)
    console.log('🖥️  Step 3: Testing dashboard query (simulating web dashboard)...');
    
    try {
      const conversationsQuery = query(
        collection(db, 'chat_conversations'),
        where('clinicId', '==', clinicId),
        orderBy('lastMessageTime', 'desc')
      );
      
      const snapshot = await getDocs(conversationsQuery);
      console.log(`✅ Dashboard query successful! Found ${snapshot.size} conversations for king Hospital:`);
      
      snapshot.forEach(doc => {
        const data = doc.data();
        console.log(`  📧 ${data.patientName}: ${data.lastMessage} (${data.unreadCount} non lu)`);
      });
      
    } catch (error) {
      console.log('❌ Dashboard query failed - indexes not ready yet');
      console.log('Error:', error.message);
      console.log('Please wait for Firestore indexes to build...');
    }
    
    // 4. Test hospital response
    console.log('\n🏥 Step 4: Testing hospital response...');
    
    const responseData = {
      conversationId: conversationRef.id,
      senderId: 'hospital_staff',
      senderName: 'Dr. Smith',
      senderType: 'hospital',
      content: 'Bonjour! Nous avons bien reçu votre demande de rendez-vous. Nous vous confirmerons les créneaux disponibles sous peu.',
      messageType: 'text',
      timestamp: serverTimestamp(),
      read: false
    };
    
    await addDoc(collection(db, 'chat_messages'), responseData);
    
    // Update conversation
    await updateDoc(doc(db, 'chat_conversations', conversationRef.id), {
      lastMessage: responseData.content,
      lastMessageTime: serverTimestamp(),
      unreadCount: 0 // Hospital read it
    });
    
    console.log('✅ Hospital response sent');
    
    console.log('\n🎉 Test completed successfully!');
    console.log('\n📝 Next steps:');
    console.log('1. Check if the Firebase indexes are built');
    console.log('2. If indexes are ready, the dashboard should show the new conversation');
    console.log('3. Test from mobile app to ensure real-time sync works');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

if (require.main === module) {
  testRealTimeNotifications().catch(console.error);
}

module.exports = { testRealTimeNotifications }; 