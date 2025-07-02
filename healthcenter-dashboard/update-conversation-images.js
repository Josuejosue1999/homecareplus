const { initializeApp } = require("firebase/app");
const { getFirestore, collection, getDocs, query, where, updateDoc, doc } = require("firebase/firestore");

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

async function updateConversationImages() {
  try {
    console.log('=== UPDATING CONVERSATION IMAGES ===');
    
    // Récupérer toutes les conversations
    const conversationsSnapshot = await getDocs(collection(db, 'chat_conversations'));
    
    console.log(`Found ${conversationsSnapshot.size} conversations to update`);
    
    // Récupérer toutes les cliniques pour créer un mapping
    const clinicsSnapshot = await getDocs(collection(db, 'clinics'));
    const clinicImages = {};
    
    for (const clinicDoc of clinicsSnapshot.docs) {
      const clinicData = clinicDoc.data();
      const clinicName = clinicData.name || clinicData.clinicName;
      if (clinicName && clinicData.profileImageUrl) {
        clinicImages[clinicName] = clinicData.profileImageUrl;
        console.log(`Mapped clinic "${clinicName}" to image`);
      }
    }
    
    let updatedCount = 0;
    
    for (const conversationDoc of conversationsSnapshot.docs) {
      const conversationData = conversationDoc.data();
      const clinicName = conversationData.clinicName;
      
      console.log(`\nProcessing conversation: ${conversationDoc.id}`);
      console.log(`Clinic name: ${clinicName}`);
      console.log(`Current hospital image: ${conversationData.hospitalImage ? 'Yes' : 'No'}`);
      
      // Si la conversation n'a pas d'image et qu'on a une image pour cette clinique
      if (!conversationData.hospitalImage && clinicImages[clinicName]) {
        console.log(`Updating conversation with image for ${clinicName}`);
        
        try {
          await updateDoc(doc(db, 'chat_conversations', conversationDoc.id), {
            hospitalImage: clinicImages[clinicName],
          });
          updatedCount++;
          console.log(`✅ Updated conversation ${conversationDoc.id}`);
        } catch (error) {
          console.error(`❌ Error updating conversation ${conversationDoc.id}:`, error);
        }
      } else if (conversationData.hospitalImage) {
        console.log(`Conversation already has image`);
      } else {
        console.log(`No image found for clinic: ${clinicName}`);
      }
    }
    
    console.log(`\n=== UPDATE COMPLETED ===`);
    console.log(`Updated ${updatedCount} conversations out of ${conversationsSnapshot.size}`);
    
  } catch (error) {
    console.error('Error updating conversation images:', error);
  }
}

// Exécuter la mise à jour
updateConversationImages().then(() => {
  console.log('\n=== SCRIPT COMPLETED ===');
  process.exit(0);
}).catch((error) => {
  console.error('Script failed:', error);
  process.exit(1);
}); 