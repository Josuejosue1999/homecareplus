/**
 * 🧪 CHAT SYSTEM FIXES VALIDATION SCRIPT
 * 
 * Simple validation script to test all implemented fixes
 */

const { db, getDocs, getDoc, doc, collection, query, where } = require('./config/firebase');

async function validateChatFixes() {
  console.log('🧪 === VALIDATING CHAT SYSTEM FIXES ===\n');

  try {
    // 1. Validate Conversations Exist
    console.log('1️⃣ === CHECKING CONVERSATIONS ===');
    const conversationsSnapshot = await getDocs(collection(db, 'chat_conversations'));
    console.log(`✅ Found ${conversationsSnapshot.docs.length} conversations in database`);
    
    if (conversationsSnapshot.docs.length > 0) {
      const sampleConversation = conversationsSnapshot.docs[0].data();
      console.log(`   📋 Sample conversation: Patient ${sampleConversation.patientId} <-> Clinic ${sampleConversation.clinicId}`);
      
      // 2. Check Patient Data
      console.log('\n2️⃣ === CHECKING PATIENT DATA ===');
      try {
        const patientDoc = await getDoc(doc(db, 'users', sampleConversation.patientId));
        if (patientDoc.exists()) {
          const patientData = patientDoc.data();
          console.log(`✅ Patient document exists: ${patientData.name || 'Unknown'}`);
          
          // Check for image fields
          const imageFields = ['profileImage', 'imageUrl', 'profileImageUrl', 'avatar', 'photoURL', 'image', 'picture'];
          let foundImage = false;
          
          for (const field of imageFields) {
            if (patientData[field] && patientData[field].toString().trim() !== '') {
              console.log(`   🖼️ Patient image found in field: ${field}`);
              foundImage = true;
              break;
            }
          }
          
          if (!foundImage) {
            console.log('   ⚠️ No patient image found - will use fallback initials');
          }
        } else {
          console.log(`❌ Patient document not found: ${sampleConversation.patientId}`);
        }
      } catch (error) {
        console.log(`❌ Error checking patient: ${error.message}`);
      }
      
      // 3. Check Hospital Data
      console.log('\n3️⃣ === CHECKING HOSPITAL DATA ===');
      try {
        const clinicDoc = await getDoc(doc(db, 'clinics', sampleConversation.clinicId));
        if (clinicDoc.exists()) {
          const clinicData = clinicDoc.data();
          console.log(`✅ Hospital document exists: ${clinicData.name || clinicData.clinicName || 'Unknown'}`);
          
          // Check for image fields
          const imageFields = ['imageUrl', 'profileImageUrl', 'image', 'profileImage', 'hospitalImage', 'logo', 'avatar', 'picture'];
          let foundImage = false;
          
          for (const field of imageFields) {
            if (clinicData[field] && clinicData[field].toString().trim() !== '') {
              console.log(`   🖼️ Hospital image found in field: ${field}`);
              foundImage = true;
              break;
            }
          }
          
          if (!foundImage) {
            console.log('   ⚠️ No hospital image found - will use default');
          }
        } else {
          console.log(`❌ Hospital document not found: ${sampleConversation.clinicId}`);
        }
      } catch (error) {
        console.log(`❌ Error checking hospital: ${error.message}`);
      }
    }
    
    // 4. Check Messages
    console.log('\n4️⃣ === CHECKING MESSAGES ===');
    const messagesSnapshot = await getDocs(collection(db, 'chat_messages'));
    console.log(`✅ Found ${messagesSnapshot.docs.length} messages in database`);
    
    let hospitalMessages = 0;
    let patientMessages = 0;
    
    messagesSnapshot.docs.forEach(doc => {
      const messageData = doc.data();
      if (messageData.senderType === 'clinic') {
        hospitalMessages++;
      } else if (messageData.senderType === 'patient') {
        patientMessages++;
      }
    });
    
    console.log(`   🏥 Hospital messages: ${hospitalMessages}`);
    console.log(`   👤 Patient messages: ${patientMessages}`);
    
    // 5. Check Appointments
    console.log('\n5️⃣ === CHECKING APPOINTMENTS ===');
    const appointmentsSnapshot = await getDocs(collection(db, 'appointments'));
    console.log(`✅ Found ${appointmentsSnapshot.docs.length} appointments in database`);
    
    const pendingAppointments = appointmentsSnapshot.docs.filter(doc => 
      doc.data().status === 'pending'
    ).length;
    
    const confirmedAppointments = appointmentsSnapshot.docs.filter(doc => 
      doc.data().status === 'confirmed'
    ).length;
    
    console.log(`   ⏳ Pending appointments: ${pendingAppointments}`);
    console.log(`   ✅ Confirmed appointments: ${confirmedAppointments}`);
    
    console.log('\n🎉 === VALIDATION COMPLETE ===');
    console.log('Your chat system is ready to test! 🚀');
    console.log('\n📝 === NEXT STEPS ===');
    console.log('1. Start hospital dashboard: npm start');
    console.log('2. Test patient profile images in chat');
    console.log('3. Test hospital replies');
    console.log('4. Test appointment approval auto-confirmation');
    console.log('5. Verify real-time sync between patient app and dashboard');
    
  } catch (error) {
    console.error('❌ Validation failed:', error);
  }
}

// Run validation
validateChatFixes().then(() => {
  console.log('\n🏁 Validation script completed');
}).catch(error => {
  console.error('🚨 Validation script failed:', error);
}); 