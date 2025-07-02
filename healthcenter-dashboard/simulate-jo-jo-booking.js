const { simpleChatSystem } = require('./fix-chat-no-index.js');

async function simulateJoJoBooking() {
  console.log('📱 Simulating Jo Jo Jo Boss booking...\n');
  
  const clinicId = '2EIIpfgRKndh04NBa4kDTflw9Zy1'; // king Hospital
  const patientName = 'Jo Jo Jo Boss';
  const patientId = 'patient_jo_jo_boss_' + Date.now();
  const appointmentId = 'appointment_jo_' + Date.now();
  
  try {
    console.log('🆔 Patient Details:');
    console.log(`   Name: ${patientName}`);
    console.log(`   ID: ${patientId}`);
    console.log(`   Clinic: king Hospital`);
    console.log(`   Appointment ID: ${appointmentId}\n`);
    
    // 1. Create conversation for Jo Jo Jo Boss
    console.log('📱 Step 1: Creating appointment booking for Jo Jo Jo Boss...');
    
    const conversation = await simpleChatSystem.createConversation(
      clinicId,
      'king Hospital',
      patientId,
      patientName,
      appointmentId,
      'Family Planning'
    );
    
    console.log(`✅ Conversation created for ${patientName}: ${conversation.id}`);
    
    // 2. Add a more detailed appointment request message
    console.log('\n💬 Step 2: Adding detailed appointment request message...');
    
    const detailedMessage = `📅 **New Appointment Request**

Hello king Hospital,

I would like to request an appointment with the following details:

**Patient Information:**
• **Name:** ${patientName}
• **Email:** jojojoboss@email.com
• **Phone:** 25088779999

**Appointment Details:**
• **Hospital:** king Hospital
• **Department:** Family Planning
• **Requested Date:** ${new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toLocaleDateString()}
• **Requested Time:** 14:30
• **Reason:** Consultation de planification familiale

**Status:** ⏳ Pending Approval

Please approve or reject this appointment request. Thank you!
    `;
    
    const messageResponse = await simpleChatSystem.sendMessage(
      conversation.id,
      patientId,
      patientName,
      'patient',
      detailedMessage,
      'appointment_request'
    );
    
    console.log(`✅ Detailed appointment message sent: ${messageResponse.id}`);
    
    // 3. Check all conversations for king Hospital
    console.log('\n🖥️  Step 3: Checking all conversations for king Hospital...');
    
    const allConversations = await simpleChatSystem.getHospitalConversations(clinicId);
    console.log(`✅ Found ${allConversations.length} total conversations for king Hospital`);
    
    // 4. Show the dashboard view
    console.log('\n📋 Dashboard Messages View:');
    console.log('=========================================');
    
    allConversations.slice(0, 8).forEach((conv, index) => {
      const timeAgo = Math.floor((new Date() - conv.lastMessageTime) / 60000);
      const timeText = timeAgo < 1 ? 'Now' : `${timeAgo}m ago`;
      
      console.log(`${conv.patientName}`);
      console.log(`${conv.patientName}`);
      console.log(`${timeText}`);
      console.log(`${conv.unreadCount}`);
      console.log(`${conv.lastMessage}`);
      console.log('');
    });
    
    console.log('=========================================');
    
    // 5. Find Jo Jo Jo Boss specifically
    const joConversation = allConversations.find(c => 
      c.patientName.toLowerCase().includes('jo jo') || 
      c.patientName.toLowerCase().includes('jojojoboss')
    );
    
    if (joConversation) {
      console.log('\n🎯 Found Jo Jo Jo Boss conversation:');
      console.log(`   ID: ${joConversation.id}`);
      console.log(`   Patient: ${joConversation.patientName}`);
      console.log(`   Last message: ${joConversation.lastMessage.substring(0, 100)}...`);
      console.log(`   Unread count: ${joConversation.unreadCount}`);
      console.log(`   Time: ${joConversation.lastMessageTime.toLocaleString()}`);
    }
    
    console.log('\n🎉 Jo Jo Jo Boss booking simulation completed!');
    console.log('\n📱➡️🖥️  The hospital dashboard should now show:');
    console.log(`   • New conversation from ${patientName}`);
    console.log('   • "Nouvelle demande de rendez-vous" message');
    console.log('   • Unread notification badge');
    console.log('   • Ability to open and respond to the conversation');
    
    console.log('\n🔔 This simulates exactly what happens when:');
    console.log('   1. Jo Jo Jo Boss books appointment from mobile app');
    console.log('   2. Automatic conversation + message creation');
    console.log('   3. Real-time notification appears in hospital dashboard');
    
  } catch (error) {
    console.error('❌ Simulation failed:', error);
  }
}

if (require.main === module) {
  simulateJoJoBooking().catch(console.error);
}

module.exports = { simulateJoJoBooking }; 