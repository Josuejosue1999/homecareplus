const admin = require('firebase-admin');

// Initialize Firebase Admin if not already done
if (admin.apps.length === 0) {
  const serviceAccount = require('./config/firebase.js');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://homecare-9f4d0-default-rtdb.firebaseio.com"
  });
}

const db = admin.firestore();

async function setupIndexes() {
  console.log('🔧 Setting up Firestore indexes...');
  
  try {
    // Test the query that requires the index
    console.log('Testing chat_conversations query...');
    
    const testQuery = db.collection('chat_conversations')
      .where('clinicId', '==', 'test')
      .orderBy('lastMessageTime', 'desc')
      .limit(1);
    
    await testQuery.get();
    console.log('✅ chat_conversations index already exists or query works');
    
  } catch (error) {
    if (error.code === 'failed-precondition') {
      console.log('❌ Index required for chat_conversations');
      console.log('📝 Please create the index using this URL:');
      console.log(error.message.match(/https:\/\/[^\s]+/)[0]);
      console.log('\n🔗 Or create it manually in Firebase Console:');
      console.log('Collection: chat_conversations');
      console.log('Fields:');
      console.log('  - clinicId (Ascending)');
      console.log('  - lastMessageTime (Descending)');
      console.log('  - __name__ (Ascending)');
      console.log('\n⏳ After creating the index, wait a few minutes for it to build...');
    } else {
      console.error('Error testing index:', error);
    }
  }
  
  // Test other potential queries
  try {
    console.log('Testing chat_messages query...');
    const testQuery2 = db.collection('chat_messages')
      .where('conversationId', '==', 'test')
      .orderBy('timestamp', 'desc')
      .limit(1);
    
    await testQuery2.get();
    console.log('✅ chat_messages query works');
    
  } catch (error) {
    if (error.code === 'failed-precondition') {
      console.log('❌ Index required for chat_messages');
      console.log('📝 Please create the index using this URL:');
      console.log(error.message.match(/https:\/\/[^\s]+/)[0]);
    }
  }
  
  console.log('\n🚀 Index setup check complete!');
}

if (require.main === module) {
  setupIndexes().then(() => {
    process.exit(0);
  }).catch((error) => {
    console.error('❌ Error setting up indexes:', error);
    process.exit(1);
  });
}

module.exports = { setupIndexes }; 