const admin = require('firebase-admin');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase (reuse existing initialization if available)
let db;
try {
  db = getFirestore();
  console.log('Using existing Firebase Admin instance');
} catch (error) {
  // If not initialized, initialize it
  const serviceAccount = require('./config/firebase.js');
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  
  db = getFirestore();
  console.log('Initialized new Firebase Admin instance');
}

async function fixCapstoneBoysConversation() {
    console.log('🔧 FIXING CAPSTONEBOY CONVERSATION IMAGES');
    console.log('==========================================\n');
    
    try {
        // Find conversations that might be for capstoneboy
        const conversationsSnapshot = await db.collection('chat_conversations').get();
        console.log(`Checking ${conversationsSnapshot.docs.length} conversations for capstoneboy...\n`);
        
        let fixed = false;
        
        for (const doc of conversationsSnapshot.docs) {
            const data = doc.data();
            const conversationId = doc.id;
            const patientName = data.patientName || '';
            const clinicName = data.clinicName || '';
            
            // Look for capstoneboy or New Hospital conversations
            if (patientName.toLowerCase().includes('capstone') || 
                patientName.toLowerCase().includes('boy') ||
                clinicName.toLowerCase().includes('new hospital')) {
                
                console.log(`📋 Found potential capstoneboy conversation: ${conversationId}`);
                console.log(`   Patient: ${patientName}`);
                console.log(`   Clinic: ${clinicName}`);
                console.log(`   Current Hospital Image: ${data.hospitalImage ? 'Yes' : 'No'}`);
                console.log(`   Current Patient Image: ${data.patientImage ? 'Yes' : 'No'}`);
                
                const updateData = {};
                
                // Fix hospital image
                if (!data.hospitalImage || data.hospitalImage.trim() === '') {
                    try {
                        const clinicsSnapshot = await db.collection('clinics').get();
                        for (const clinicDoc of clinicsSnapshot.docs) {
                            const clinicData = clinicDoc.data();
                            const clinicNameInDoc = clinicData.name || clinicData.clinicName || '';
                            
                            if (clinicNameInDoc.toLowerCase().includes('new hospital')) {
                                const hospitalImage = clinicData.imageUrl || clinicData.image || clinicData.profileImage || clinicData.profileImageUrl;
                                if (hospitalImage) {
                                    updateData.hospitalImage = hospitalImage;
                                    console.log('   ✅ Found hospital image in clinics collection');
                                    break;
                                }
                            }
                        }
                    } catch (error) {
                        console.log('   ❌ Error fetching hospital image:', error.message);
                    }
                }
                
                // Fix patient image
                if (!data.patientImage || data.patientImage.trim() === '') {
                    try {
                        const usersSnapshot = await db.collection('users').get();
                        for (const userDoc of usersSnapshot.docs) {
                            const userData = userDoc.data();
                            const userName = userData.name || userData.fullName || '';
                            
                            if (userName.toLowerCase().includes('capstone') || userName.toLowerCase().includes('boy')) {
                                const patientImage = userData.profileImage || userData.imageUrl || userData.avatar || userData.photoURL;
                                if (patientImage) {
                                    updateData.patientImage = patientImage;
                                    console.log('   ✅ Found patient image in users collection');
                                    break;
                                }
                            }
                        }
                    } catch (error) {
                        console.log('   ❌ Error fetching patient image:', error.message);
                    }
                }
                
                // Update conversation if needed
                if (Object.keys(updateData).length > 0) {
                    updateData.updatedAt = admin.firestore.FieldValue.serverTimestamp();
                    
                    try {
                        await db.collection('chat_conversations').doc(conversationId).update(updateData);
                        console.log('   🎉 Updated conversation with missing images');
                        fixed = true;
                    } catch (error) {
                        console.log('   ❌ Error updating conversation:', error.message);
                    }
                } else {
                    console.log('   ✅ No updates needed');
                }
                
                console.log(''); // Add spacing
            }
        }
        
        if (fixed) {
            console.log('✅ CAPSTONEBOY CONVERSATION FIXED!');
            console.log('The conversation now has proper hospital and patient images.');
        } else {
            console.log('⚠️  No capstoneboy conversations found or all were already fixed.');
        }
        
        console.log('\n🔄 NEXT STEPS:');
        console.log('1. Restart your Flutter app to reload the conversation data');
        console.log('2. Check that hospital images now appear on patient home page');
        console.log('3. Check that hospital images appear in patient chat');
        console.log('4. Test hospital reply from dashboard');
        
    } catch (error) {
        console.error('❌ Error in fix script:', error);
    }
}

// Run the fix
fixCapstoneBoysConversation().then(() => {
    console.log('\n🏁 Script completed');
}).catch((error) => {
    console.error('❌ Script failed:', error);
}); 