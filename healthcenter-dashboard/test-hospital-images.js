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

async function testHospitalImages() {
  try {
    console.log('=== TESTING HOSPITAL IMAGES IN CHAT ===');
    
    // 1. Vérifier les images des cliniques existantes
    console.log('\n1. Checking existing clinic images...');
    const clinicsSnapshot = await db.collection('clinics').get();
    
    clinicsSnapshot.forEach(doc => {
      const clinicData = doc.data();
      console.log(`🏥 ${clinicData.name}: ${clinicData.profileImageUrl ? 'Has image' : 'No image'}`);
    });

    // 2. Vérifier les conversations existantes
    console.log('\n2. Checking existing conversations...');
    const conversationsSnapshot = await db.collection('chat_conversations').get();
    
    conversationsSnapshot.forEach(doc => {
      const conversationData = doc.data();
      console.log(`💬 Conversation ${doc.id}: ${conversationData.clinicName} - ${conversationData.hospitalImage ? 'Has image' : 'No image'}`);
    });

    // 3. Vérifier les messages existants
    console.log('\n3. Checking existing messages...');
    const messagesSnapshot = await db.collection('chat_messages').get();
    
    messagesSnapshot.forEach(doc => {
      const messageData = doc.data();
      if (messageData.senderType === 'clinic') {
        console.log(`📨 Message ${doc.id}: ${messageData.senderName} - ${messageData.hospitalImage ? 'Has image' : 'No image'}`);
      }
    });

    // 4. Créer un test avec une image d'hôpital
    console.log('\n4. Creating test with hospital image...');
    
    // Récupérer une clinique avec une image
    const clinicWithImage = clinicsSnapshot.docs.find(doc => {
      const data = doc.data();
      return data.profileImageUrl && data.profileImageUrl.length > 0;
    });

    if (clinicWithImage) {
      const clinicData = clinicWithImage.data();
      console.log(`✅ Found clinic with image: ${clinicData.name}`);
      
      // Créer un message de test avec l'image
      const testMessageData = {
        conversationId: 'test-conversation',
        senderId: clinicWithImage.id,
        senderName: clinicData.name,
        senderType: 'clinic',
        message: 'Test message with hospital image',
        messageType: 'text',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
        hospitalName: clinicData.name,
        hospitalImage: clinicData.profileImageUrl,
        metadata: {
          action: 'test',
        },
      };

      await db.collection('chat_messages').add(testMessageData);
      console.log('✅ Test message created with hospital image');
    } else {
      console.log('⚠️ No clinic with image found');
    }

    console.log('\n=== TEST COMPLETED ===');

  } catch (error) {
    console.error('❌ Error testing hospital images:', error);
  }
}

testHospitalImages(); 