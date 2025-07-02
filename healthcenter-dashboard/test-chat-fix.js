const { initializeApp } = require("firebase/app");
const { getFirestore, collection, getDocs, query, where } = require("firebase/firestore");

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

async function testChatSystem() {
  try {
    console.log('=== TESTING CHAT SYSTEM ===');
    
    // Test 1: Check conversations
    console.log('\n📋 Test 1: Checking conversations...');
    const conversationsSnapshot = await getDocs(collection(db, 'chat_conversations'));
    console.log(`Found ${conversationsSnapshot.size} conversations`);
    
    if (conversationsSnapshot.size > 0) {
      console.log('\nSample conversations:');
      conversationsSnapshot.docs.slice(0, 3).forEach((doc, index) => {
        const data = doc.data();
        console.log(`${index + 1}. ${data.patientName} -> ${data.clinicName} (${data.lastMessage})`);
      });
    }
    
    // Test 2: Check messages
    console.log('\n💬 Test 2: Checking messages...');
    const messagesSnapshot = await getDocs(collection(db, 'chat_messages'));
    console.log(`Found ${messagesSnapshot.size} messages`);
    
    if (messagesSnapshot.size > 0) {
      console.log('\nSample messages:');
      messagesSnapshot.docs.slice(0, 3).forEach((doc, index) => {
        const data = doc.data();
        console.log(`${index + 1}. ${data.senderName} (${data.senderType}): ${data.message.substring(0, 50)}...`);
      });
    }
    
    // Test 3: Check appointments
    console.log('\n📅 Test 3: Checking appointments...');
    const appointmentsSnapshot = await getDocs(collection(db, 'appointments'));
    console.log(`Found ${appointmentsSnapshot.size} appointments`);
    
    // Test 4: Check clinics
    console.log('\n🏥 Test 4: Checking clinics...');
    const clinicsSnapshot = await getDocs(collection(db, 'clinics'));
    console.log(`Found ${clinicsSnapshot.size} clinics`);
    
    if (clinicsSnapshot.size > 0) {
      console.log('\nAvailable clinics:');
      clinicsSnapshot.docs.forEach((doc, index) => {
        const data = doc.data();
        console.log(`${index + 1}. ${data.name || data.clinicName} (ID: ${doc.id})`);
      });
    }
    
    // Test 5: Check for conversations with messages
    console.log('\n🔍 Test 5: Checking conversations with messages...');
    const conversationsWithMessages = [];
    
    for (const convDoc of conversationsSnapshot.docs) {
      const convData = convDoc.data();
      const messagesQuery = query(
        collection(db, 'chat_messages'),
        where('conversationId', '==', convDoc.id)
      );
      const messages = await getDocs(messagesQuery);
      
      conversationsWithMessages.push({
        conversationId: convDoc.id,
        patientName: convData.patientName,
        clinicName: convData.clinicName,
        messageCount: messages.size,
        lastMessage: convData.lastMessage
      });
    }
    
    console.log(`Conversations with messages: ${conversationsWithMessages.length}`);
    conversationsWithMessages.slice(0, 5).forEach((conv, index) => {
      console.log(`${index + 1}. ${conv.patientName} -> ${conv.clinicName} (${conv.messageCount} messages) - "${conv.lastMessage}"`);
    });
    
    // Test 6: Check for confirmation messages
    console.log('\n✅ Test 6: Checking confirmation messages...');
    const confirmationMessagesQuery = query(
      collection(db, 'chat_messages'),
      where('messageType', '==', 'appointmentConfirmation')
    );
    const confirmationMessages = await getDocs(confirmationMessagesQuery);
    console.log(`Found ${confirmationMessages.size} confirmation messages`);
    
    if (confirmationMessages.size > 0) {
      console.log('\nSample confirmation messages:');
      confirmationMessages.docs.slice(0, 2).forEach((doc, index) => {
        const data = doc.data();
        console.log(`${index + 1}. From ${data.senderName} to conversation ${data.conversationId}`);
        console.log(`   Message: ${data.message.substring(0, 100)}...`);
      });
    }
    
    console.log('\n✅ Chat system test completed!');
    
  } catch (error) {
    console.error('❌ Error testing chat system:', error);
  }
}

// Run the test
testChatSystem(); 