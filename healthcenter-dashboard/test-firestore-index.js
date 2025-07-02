const { db, collection, query, where, orderBy, getDocs } = require('./config/firebase.js');

async function testFirestoreIndexes() {
  console.log('🔧 Testing Firestore queries for required indexes...');
  
  try {
    // Test chat_conversations query that fails
    console.log('Testing chat_conversations query...');
    
    const conversationsQuery = query(
      collection(db, 'chat_conversations'),
      where('clinicId', '==', '2EIIpfgRKndh04NBa4kDTflw9Zy1'),
      orderBy('lastMessageTime', 'desc')
    );
    
    const snapshot = await getDocs(conversationsQuery);
    console.log(`✅ chat_conversations query works! Found ${snapshot.size} conversations`);
    
    snapshot.forEach(doc => {
      const data = doc.data();
      console.log(`  - ${data.patientName}: ${data.lastMessage || 'No message'}`);
    });
    
  } catch (error) {
    if (error.code === 'failed-precondition') {
      console.log('❌ Index required for chat_conversations');
      console.log('Error message:', error.message);
      
      // Extract URL from error message
      const urlMatch = error.message.match(/(https:\/\/console\.firebase\.google\.com[^\s]*)/);
      if (urlMatch) {
        console.log('\n📝 Create the index using this URL:');
        console.log(urlMatch[1]);
      }
      
      console.log('\n🔗 Or create it manually in Firebase Console:');
      console.log('Collection: chat_conversations');
      console.log('Fields:');
      console.log('  - clinicId (Ascending)');
      console.log('  - lastMessageTime (Descending)');
      console.log('  - __name__ (Ascending)');
    } else {
      console.error('❌ Error testing chat_conversations:', error.message);
    }
  }
  
  try {
    // Test chat_messages query
    console.log('\nTesting chat_messages query...');
    
    const messagesQuery = query(
      collection(db, 'chat_messages'),
      where('conversationId', '==', 'test'),
      orderBy('timestamp', 'desc')
    );
    
    const snapshot = await getDocs(messagesQuery);
    console.log(`✅ chat_messages query works! Found ${snapshot.size} messages`);
    
  } catch (error) {
    if (error.code === 'failed-precondition') {
      console.log('❌ Index required for chat_messages');
      console.log('Error message:', error.message);
      
      const urlMatch = error.message.match(/(https:\/\/console\.firebase\.google\.com[^\s]*)/);
      if (urlMatch) {
        console.log('\n📝 Create the index using this URL:');
        console.log(urlMatch[1]);
      }
    } else {
      console.error('❌ Error testing chat_messages:', error.message);
    }
  }
  
  console.log('\n🚀 Index test complete!');
}

if (require.main === module) {
  testFirestoreIndexes().catch(console.error);
}

module.exports = { testFirestoreIndexes }; 