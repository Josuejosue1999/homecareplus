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

async function testChatConversations() {
  try {
    console.log('=== TESTING CHAT CONVERSATIONS ===');
    
    // Récupérer toutes les conversations
    const conversationsSnapshot = await getDocs(collection(db, 'chat_conversations'));
    
    console.log(`Found ${conversationsSnapshot.size} conversations`);
    
    for (const doc of conversationsSnapshot.docs) {
      const data = doc.data();
      console.log(`\nConversation ID: ${doc.id}`);
      console.log(`Patient ID: ${data.patientId}`);
      console.log(`Clinic ID: ${data.clinicId}`);
      console.log(`Patient Name: ${data.patientName}`);
      console.log(`Clinic Name: ${data.clinicName}`);
      console.log(`Hospital Image: ${data.hospitalImage ? 'Yes' : 'No'}`);
      if (data.hospitalImage) {
        console.log(`Image URL: ${data.hospitalImage.substring(0, 50)}...`);
      }
      console.log(`Last Message: ${data.lastMessage}`);
      console.log(`Has Unread: ${data.hasUnreadMessages}`);
      console.log(`Unread Count: ${data.unreadCount}`);
      console.log(`Created At: ${data.createdAt?.toDate?.() || data.createdAt}`);
      console.log(`Updated At: ${data.updatedAt?.toDate?.() || data.updatedAt}`);
      
      // Vérifier les messages de cette conversation
      const messagesQuery = query(
        collection(db, 'chat_messages'),
        where('conversationId', '==', doc.id)
      );
      const messagesSnapshot = await getDocs(messagesQuery);
      
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
    const clinicsSnapshot = await getDocs(collection(db, 'clinics'));
    
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