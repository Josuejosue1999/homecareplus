const { initializeApp } = require("firebase/app");
const { getFirestore, collection, doc, getDocs, addDoc, query, where } = require("firebase/firestore");

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

async function createKingHospitalConversations() {
    console.log('👑 Creating conversations for King Hospital...\n');
    
    try {
        // Get ALL appointments and filter manually
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        console.log(`📋 Total appointments to check: ${appointmentsSnapshot.size}`);
        
        let kingHospitalCount = 0;
        const kingAppointments = [];
        
        // Find king Hospital appointments
        for (const docSnapshot of appointmentsSnapshot.docs) {
            const appointment = { id: docSnapshot.id, ...docSnapshot.data() };
            
            console.log(`Checking appointment ${appointment.id}: hospital = "${appointment.hospital}"`);
            
            if (appointment.hospital === 'king Hospital') {
                kingHospitalCount++;
                kingAppointments.push(appointment);
                console.log(`✅ Found King Hospital appointment: ${appointment.id} for ${appointment.patientName}`);
            }
        }
        
        console.log(`\n👑 Found ${kingHospitalCount} King Hospital appointments`);
        
        if (kingHospitalCount === 0) {
            console.log('❌ No King Hospital appointments found!');
            return;
        }
        
        // Create conversations for each appointment
        let createdConversations = 0;
        
        for (const appointment of kingAppointments) {
            console.log(`\n📝 Creating conversation for appointment ${appointment.id}...`);
            console.log(`   Patient: ${appointment.patientName}`);
            console.log(`   Service: ${appointment.service || 'General Consultation'}`);
            console.log(`   Status: ${appointment.status}`);
            
            // Check if conversation already exists
            const existingConversationsRef = collection(db, 'chat_conversations');
            const existingQuery = query(existingConversationsRef, where('appointmentId', '==', appointment.id));
            const existingSnapshot = await getDocs(existingQuery);
            
            if (existingSnapshot.size > 0) {
                console.log(`   ⚠️  Conversation already exists, skipping...`);
                continue;
            }
            
            // Get appointment date
            let appointmentDateText = 'À définir';
            if (appointment.appointmentDate) {
                try {
                    if (appointment.appointmentDate.seconds) {
                        appointmentDateText = new Date(appointment.appointmentDate.seconds * 1000).toLocaleDateString('fr-FR');
                    } else {
                        appointmentDateText = new Date(appointment.appointmentDate).toLocaleDateString('fr-FR');
                    }
                } catch (e) {
                    console.log(`   ⚠️  Could not parse date: ${e.message}`);
                }
            }
            
            // Create conversation
            const conversationData = {
                appointmentId: appointment.id,
                patientName: appointment.patientName || 'Patient',
                patientEmail: appointment.patientEmail || '',
                patientPhone: appointment.patientPhone || '',
                hospitalName: 'king Hospital',
                service: appointment.service || 'General Consultation',
                status: 'active',
                lastMessage: 'Nouvelle demande de rendez-vous',
                lastMessageTime: new Date(),
                unreadCount: 1,
                hasUnreadMessages: true,
                createdAt: new Date(),
                updatedAt: new Date()
            };
            
            const conversationRef = await addDoc(collection(db, 'chat_conversations'), conversationData);
            console.log(`   💬 Created conversation: ${conversationRef.id}`);
            
            // Create initial message
            const messageData = {
                conversationId: conversationRef.id,
                appointmentId: appointment.id,
                senderType: 'patient',
                senderName: appointment.patientName || 'Patient',
                message: `Bonjour, je souhaite prendre un rendez-vous pour ${appointment.service || 'une consultation'}. 
                
📅 Date souhaitée: ${appointmentDateText}
⏰ Heure: ${appointment.appointmentTime || 'À définir'}
📝 Motif: ${appointment.notes || appointment.reasonOfBooking || 'Consultation générale'}
📋 Statut actuel: ${appointment.status || 'En attente'}

Merci de confirmer la disponibilité.`,
                messageType: 'appointment_request',
                timestamp: appointment.createdAt?.toDate() || new Date(),
                isRead: false,
                metadata: {
                    appointmentDate: appointment.appointmentDate,
                    appointmentTime: appointment.appointmentTime,
                    service: appointment.service,
                    status: appointment.status
                }
            };
            
            await addDoc(collection(db, 'chat_messages'), messageData);
            console.log(`   📨 Created initial message`);
            
            createdConversations++;
        }
        
        console.log(`\n✅ Successfully created ${createdConversations} conversations for King Hospital!`);
        
        // Test the conversations
        console.log('\n🧪 Testing the new conversations...');
        const testConversationsRef = collection(db, 'chat_conversations');
        const testQuery = query(testConversationsRef, where('hospitalName', '==', 'king Hospital'));
        const testSnapshot = await getDocs(testQuery);
        
        console.log(`Found ${testSnapshot.size} conversations for king Hospital in database`);
        
        testSnapshot.forEach((docSnapshot, index) => {
            const conv = docSnapshot.data();
            console.log(`   ${index + 1}. ${conv.patientName} - ${conv.service} (${conv.status})`);
        });
        
    } catch (error) {
        console.error('❌ Error creating conversations:', error);
    }
}

createKingHospitalConversations(); 