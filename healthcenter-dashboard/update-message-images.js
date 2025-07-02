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

async function updateMessageImages() {
  try {
    console.log('=== UPDATING MESSAGE IMAGES ===');
    
    // Récupérer tous les messages
    const messagesSnapshot = await getDocs(collection(db, 'chat_messages'));
    
    console.log(`Found ${messagesSnapshot.size} messages`);
    
    let updatedCount = 0;
    
    for (const messageDoc of messagesSnapshot.docs) {
      const messageData = messageDoc.data();
      
      // Vérifier si le message a déjà une image d'hôpital
      if (!messageData.hospitalImage && messageData.senderType === 'clinic') {
        console.log(`Processing message ${messageDoc.id} from clinic: ${messageData.senderName}`);
        
        // Récupérer l'image de l'hôpital depuis la collection clinics
        try {
          const clinicDoc = await getDocs(
            query(
              collection(db, 'clinics'),
              where('name', '==', messageData.senderName)
            )
          );
          
          if (!clinicDoc.empty) {
            const clinicData = clinicDoc.docs[0].data();
            const hospitalImage = clinicData.profileImageUrl;
            
            if (hospitalImage) {
              // Mettre à jour le message avec l'image de l'hôpital
              await updateDoc(doc(db, 'chat_messages', messageDoc.id), {
                hospitalImage: hospitalImage
              });
              
              console.log(`✅ Updated message ${messageDoc.id} with hospital image`);
              updatedCount++;
            } else {
              console.log(`⚠️ No hospital image found for clinic: ${messageData.senderName}`);
            }
          } else {
            console.log(`⚠️ No clinic found for name: ${messageData.senderName}`);
          }
        } catch (error) {
          console.log(`❌ Error updating message ${messageDoc.id}: ${error.message}`);
        }
      }
    }
    
    console.log(`\n=== SUMMARY ===`);
    console.log(`Total messages processed: ${messagesSnapshot.size}`);
    console.log(`Messages updated with hospital image: ${updatedCount}`);
    
  } catch (error) {
    console.error('❌ Error updating message images:', error);
  }
}

// Exécuter le script
updateMessageImages(); 