const { simpleChatSystem } = require('./fix-chat-no-index.js');

async function testSimpleChat() {
  console.log('🔧 Testing simplified chat system (no indexes required)...\n');
  
  const clinicId = '2EIIpfgRKndh04NBa4kDTflw9Zy1'; // king Hospital
  const patientName = 'Test Patient Simple ' + Date.now();
  const appointmentId = 'simple_test_' + Date.now();
  
  try {
    // 1. Create a new conversation using simplified system
    console.log('📱 Step 1: Creating conversation with simplified system...');
    
    const conversation = await simpleChatSystem.createConversation(
      clinicId,
      'king Hospital',
      'test_patient_' + Date.now(),
      patientName,
      appointmentId,
      'Family Planning'
    );
    
    console.log(`✅ Conversation created: ${conversation.id}`);
    
    // 2. Test getting conversations for hospital (simplified query)
    console.log('\n🖥️  Step 2: Testing simplified hospital conversations query...');
    
    const conversations = await simpleChatSystem.getHospitalConversations(clinicId);
    console.log(`✅ Found ${conversations.length} conversations for king Hospital`);
    
    // Show latest conversations
    console.log('\n📋 Latest conversations:');
    conversations.slice(0, 5).forEach((conv, index) => {
      console.log(`  ${index + 1}. ${conv.patientName}: ${conv.lastMessage}`);
      console.log(`     📅 ${conv.lastMessageTime.toLocaleString()}`);
      console.log(`     💬 ${conv.unreadCount} unread messages\n`);
    });
    
    // 3. Test getting messages for the conversation
    console.log('💬 Step 3: Testing simplified message retrieval...');
    
    const messages = await simpleChatSystem.getConversationMessages(conversation.id);
    console.log(`✅ Found ${messages.length} messages in conversation`);
    
    messages.forEach((msg, index) => {
      console.log(`  ${index + 1}. [${msg.senderType}] ${msg.senderName}: ${msg.content.substring(0, 50)}...`);
    });
    
    // 4. Test sending a hospital response
    console.log('\n🏥 Step 4: Testing hospital response...');
    
    const response = await simpleChatSystem.sendMessage(
      conversation.id,
      'hospital_staff',
      'Dr. Smith - king Hospital',
      'hospital',
      'Bonjour! Nous avons bien reçu votre demande de rendez-vous. Nous vous confirmerons les créneaux disponibles sous peu.',
      'text'
    );
    
    console.log(`✅ Hospital response sent: ${response.id}`);
    
    // 5. Mark conversation as read
    console.log('\n👀 Step 5: Testing mark as read...');
    
    const markReadResult = await simpleChatSystem.markConversationAsRead(conversation.id);
    console.log(`✅ Conversation marked as read: ${markReadResult}`);
    
    // 6. Final check - get updated conversations
    console.log('\n🔄 Step 6: Final check - getting updated conversations...');
    
    const updatedConversations = await simpleChatSystem.getHospitalConversations(clinicId);
    console.log(`✅ Found ${updatedConversations.length} total conversations`);
    
    const ourConversation = updatedConversations.find(c => c.id === conversation.id);
    if (ourConversation) {
      console.log(`📧 Our test conversation:`);
      console.log(`  Patient: ${ourConversation.patientName}`);
      console.log(`  Last message: ${ourConversation.lastMessage}`);
      console.log(`  Unread count: ${ourConversation.unreadCount}`);
    }
    
    console.log('\n🎉 Simplified chat system test completed successfully!');
    console.log('\n✅ The system works without Firebase indexes');
    console.log('💡 The dashboard should now display conversations properly');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

if (require.main === module) {
  testSimpleChat().catch(console.error);
}

module.exports = { testSimpleChat }; 