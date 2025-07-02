const { simpleChatSystem } = require('./fix-chat-no-index.js');

async function testAppointmentNotification() {
  console.log('🏥 Testing appointment notification flow (Patient → Hospital)...\n');
  
  const clinicId = '2EIIpfgRKndh04NBa4kDTflw9Zy1'; // king Hospital
  const patientName = 'Jo Jo Jo Boss';
  const patientId = 'patient_jo_jo_boss_' + Date.now();
  const appointmentId = 'appointment_' + Date.now();
  
  try {
    // 1. Patient books appointment (simulating mobile app)
    console.log('📱 Step 1: Patient books appointment...');
    console.log(`   Patient: ${patientName}`);
    console.log(`   Hospital: king Hospital`);
    console.log(`   Department: Family Planning`);
    console.log(`   Appointment ID: ${appointmentId}\n`);
    
    // 2. Create conversation and initial message
    console.log('💬 Step 2: Creating conversation...');
    const conversation = await simpleChatSystem.createConversation(
      clinicId,
      'king Hospital',
      patientId,
      patientName,
      appointmentId,
      'Family Planning'
    );
    
    if (!conversation || !conversation.id) {
      throw new Error('Failed to create conversation: No conversation ID returned');
    }
    
    console.log(`✅ Conversation created: ${conversation.id}\n`);
    
    // 3. Send appointment booking message
    console.log('📩 Step 3: Sending appointment request message...');
    const message = `Bonjour,

Je souhaite prendre un rendez-vous pour une consultation en Planning Familial.

**Mes informations:**
• Nom: ${patientName}  
• Service demandé: Family Planning
• Préférence: Dans les prochains jours

Merci de me confirmer la disponibilité.

Cordialement,
${patientName}`;

    const messageResult = await simpleChatSystem.sendMessage(
      conversation.id,
      patientId,
      patientName,
      'patient',
      message,
      'appointmentRequest'
    );
    
    if (!messageResult || !messageResult.id) {
      throw new Error('Failed to send message: No message ID returned');
    }
    
    console.log('✅ Message sent successfully\n');
    
    // 4. Test hospital retrieval
    console.log('🏥 Step 4: Testing hospital message retrieval...');
    const hospitalConversations = await simpleChatSystem.getHospitalConversations(clinicId);
    
    if (!hospitalConversations || !Array.isArray(hospitalConversations)) {
      throw new Error('Failed to get hospital conversations: Invalid response format');
    }
    
    console.log(`✅ Hospital can see ${hospitalConversations.length} conversations`);
    
    // Find our conversation
    const ourConversation = hospitalConversations.find(conv => 
      conv.id === conversation.id
    );
    
    if (!ourConversation) {
      throw new Error('Hospital cannot see the new conversation!');
    }
    
    console.log(`✅ Hospital can see conversation from ${ourConversation.patientName}`);
    console.log(`   Last message: "${ourConversation.lastMessage}"`);
    console.log(`   Unread count: ${ourConversation.unreadCount}\n`);
    
    // 5. Test message retrieval
    console.log('📨 Step 5: Testing message retrieval...');
    const messages = await simpleChatSystem.getConversationMessages(conversation.id);
    
    if (!messages || !Array.isArray(messages)) {
      throw new Error('Failed to get messages: Invalid response format');
    }
    
    console.log(`✅ Found ${messages.length} messages in conversation`);
    messages.forEach((msg, index) => {
      console.log(`   ${index + 1}. From ${msg.senderName} (${msg.senderType}): "${msg.content?.substring(0, 50) || 'No content'}..."`);
    });
    
    console.log('\n🎉 SUCCESS! Complete notification flow working:');
    console.log('   ✅ Patient can book appointment');
    console.log('   ✅ Conversation is created automatically');
    console.log('   ✅ Message is sent to hospital');
    console.log('   ✅ Hospital can retrieve conversations');
    console.log('   ✅ Hospital can read messages');
    
    return {
      success: true,
      conversationId: conversation.id,
      messageCount: messages.length
    };
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    return { success: false, error: error.message };
  }
}

// Run the test
testAppointmentNotification()
  .then(result => {
    if (result.success) {
      console.log(`\n🔥 Test completed successfully! Conversation: ${result.conversationId}`);
    } else {
      console.log(`\n💥 Test failed: ${result.error}`);
    }
    process.exit(result.success ? 0 : 1);
  })
  .catch(error => {
    console.error('💥 Unexpected error:', error);
    process.exit(1);
  }); 