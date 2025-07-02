const { initializeApp } = require("firebase/app");
const { getFirestore, collection, addDoc } = require("firebase/firestore");

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

async function createTestConversations() {
    console.log('🧪 Creating test conversations for King Hospital...\n');
    
    try {
        // Test conversations data
        const testConversations = [
            {
                patientName: 'Tobi Tobi',
                patientEmail: 'tobi@example.com',
                patientPhone: '+250123456789',
                service: 'Family Planning',
                appointmentDate: '03/07/2025',
                appointmentTime: '10:00',
                status: 'confirmed',
                notes: 'Consultation pour planification familiale'
            },
            {
                patientName: 'Jo Jo Jo Boss',
                patientEmail: 'jo@example.com',
                patientPhone: '+250987654321',
                service: 'Family Planning',
                appointmentDate: '04/07/2025',
                appointmentTime: '14:30',
                status: 'pending',
                notes: 'Première consultation'
            },
            {
                patientName: 'Marie Uwimana',
                patientEmail: 'marie@example.com',
                patientPhone: '+250555123456',
                service: 'Gynecology',
                appointmentDate: '05/07/2025',
                appointmentTime: '09:00',
                status: 'pending',
                notes: 'Contrôle de routine'
            }
        ];
        
        let createdCount = 0;
        
        for (const testData of testConversations) {
            console.log(`📝 Creating conversation for ${testData.patientName}...`);
            
            // Create conversation
            const conversationData = {
                appointmentId: `test-${Date.now()}-${createdCount}`,
                patientName: testData.patientName,
                patientEmail: testData.patientEmail,
                patientPhone: testData.patientPhone,
                hospitalName: 'king Hospital',
                service: testData.service,
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
                appointmentId: conversationData.appointmentId,
                senderType: 'patient',
                senderName: testData.patientName,
                message: `Bonjour, je souhaite prendre un rendez-vous pour ${testData.service}. 
                
📅 Date souhaitée: ${testData.appointmentDate}
⏰ Heure: ${testData.appointmentTime}
📝 Motif: ${testData.notes}
📋 Statut: ${testData.status}

Merci de confirmer la disponibilité.`,
                messageType: 'appointment_request',
                timestamp: new Date(),
                isRead: false,
                metadata: {
                    appointmentDate: testData.appointmentDate,
                    appointmentTime: testData.appointmentTime,
                    service: testData.service,
                    status: testData.status
                }
            };
            
            await addDoc(collection(db, 'chat_messages'), messageData);
            console.log(`   📨 Created initial message`);
            
            createdCount++;
        }
        
        console.log(`\n✅ Successfully created ${createdCount} test conversations for King Hospital!`);
        
    } catch (error) {
        console.error('❌ Error creating test conversations:', error);
    }
}

createTestConversations(); 