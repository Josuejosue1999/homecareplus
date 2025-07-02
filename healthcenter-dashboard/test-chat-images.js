const admin = require('firebase-admin');
const serviceAccount = require('./config/firebase.js');

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://homecare-9f4d0-default-rtdb.firebaseio.com"
  });
}

const db = admin.firestore();

async function testChatConversations() {
  try {
    console.log('=== TESTING CHAT CONVERSATIONS ===');
    
    // Récupérer toutes les conversations
    const conversationsSnapshot = await db.collection('chat_conversations').get();
    
    console.log(`Found ${conversationsSnapshot.size} conversations`);
    
    for (const doc of conversationsSnapshot.docs) {
      const data = doc.data();
      console.log(`\nConversation ID: ${doc.id}`);
      console.log(`Patient ID: ${data.patientId}`);
      console.log(`Clinic ID: ${data.clinicId}`);
      console.log(`Patient Name: ${data.patientName}`);
      console.log(`Clinic Name: ${data.clinicName}`);
      console.log(`Hospital Image: ${data.hospitalImage ? 'Yes' : 'No'}`);
      console.log(`Last Message: ${data.lastMessage}`);
      console.log(`Has Unread: ${data.hasUnreadMessages}`);
      console.log(`Unread Count: ${data.unreadCount}`);
      console.log(`Created At: ${data.createdAt?.toDate()}`);
      console.log(`Updated At: ${data.updatedAt?.toDate()}`);
      
      // Vérifier les messages de cette conversation
      const messagesSnapshot = await db.collection('chat_messages')
        .where('conversationId', '==', doc.id)
        .get();
      
      console.log(`Messages in conversation: ${messagesSnapshot.size}`);
      
      for (const msgDoc of messagesSnapshot.docs) {
        const msgData = msgDoc.data();
        console.log(`  - Message: ${msgData.message?.substring(0, 50)}...`);
        console.log(`    Hospital Image: ${msgData.hospitalImage ? 'Yes' : 'No'}`);
        console.log(`    Sender: ${msgData.senderName}`);
      }
    }
    
    // Vérifier les cliniques et leurs images
    console.log('\n=== TESTING CLINICS ===');
    const clinicsSnapshot = await db.collection('clinics').get();
    
    console.log(`Found ${clinicsSnapshot.size} clinics`);
    
    for (const doc of clinicsSnapshot.docs) {
      const data = doc.data();
      console.log(`\nClinic ID: ${doc.id}`);
      console.log(`Name: ${data.name || data.clinicName}`);
      console.log(`Profile Image: ${data.profileImageUrl ? 'Yes' : 'No'}`);
      if (data.profileImageUrl) {
        console.log(`Image URL: ${data.profileImageUrl.substring(0, 50)}...`);
      }
    }
    
  } catch (error) {
    console.error('Error testing chat conversations:', error);
  }
}

// Exécuter le test
testChatConversations().then(() => {
  console.log('\n=== TEST COMPLETED ===');
  process.exit(0);
}).catch((error) => {
  console.error('Test failed:', error);
  process.exit(1);
}); 