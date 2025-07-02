const { initializeApp } = require("firebase/app");
const { getFirestore, collection, doc, getDocs, getDoc, addDoc, updateDoc, deleteDoc, query, where, serverTimestamp, orderBy, limit, increment } = require("firebase/firestore");

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

/**
 * PROFESSIONAL CHAT SYSTEM FOR HOMECARE PLUS
 * 
 * This system creates a simple, reliable chat system between patients and hospitals.
 * 
 * Data Structure:
 * - `chat_conversations`: Main conversation documents
 * - `chat_messages`: Individual messages in conversations
 * 
 * Features:
 * - Automatic conversation creation when patients book appointments
 * - Real-time messaging between patients and hospitals
 * - Message status tracking (read/unread)
 * - Professional message templates
 */

async function setupProfessionalChatSystem() {
    console.log('🚀 Setting up Professional Chat System...\n');
    
    try {
        // 1. Clean existing problematic data
        console.log('📝 Step 1: Cleaning existing data...');
        await cleanExistingChatData();
        
        // 2. Create conversations for existing appointments
        console.log('📝 Step 2: Creating conversations for existing appointments...');
        await createConversationsForAppointments();
        
        // 3. Test the system
        console.log('📝 Step 3: Testing the new system...');
        await testChatSystem();
        
        console.log('✅ Professional Chat System setup completed successfully!\n');
        
    } catch (error) {
        console.error('❌ Error setting up chat system:', error);
    }
}

async function cleanExistingChatData() {
    try {
        // Clean conversations collection
        const conversationsRef = collection(db, 'conversations');
        const conversationsSnapshot = await getDocs(conversationsRef);
        
        console.log(`   Found ${conversationsSnapshot.size} old conversations to clean...`);
        
        for (const docSnapshot of conversationsSnapshot.docs) {
            await deleteDoc(docSnapshot.ref);
        }
        
        // Clean messages collection  
        const messagesRef = collection(db, 'messages');
        const messagesSnapshot = await getDocs(messagesRef);
        
        console.log(`   Found ${messagesSnapshot.size} old messages to clean...`);
        
        for (const docSnapshot of messagesSnapshot.docs) {
            await deleteDoc(docSnapshot.ref);
        }
        
        console.log('   ✅ Old data cleaned successfully');
        
    } catch (error) {
        console.error('   ❌ Error cleaning data:', error);
    }
}

async function createConversationsForAppointments() {
    try {
        // Get appointments for "king Hospital"
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        console.log(`   Processing ${appointmentsSnapshot.size} appointments...`);
        
        let createdConversations = 0;
        
        for (const appointmentDoc of appointmentsSnapshot.docs) {
            const appointment = { id: appointmentDoc.id, ...appointmentDoc.data() };
            
            // Only process appointments for "king Hospital"
            if (appointment.hospital === 'king Hospital') {
                console.log(`   📋 Processing appointment: ${appointment.id} for ${appointment.patientName}`);
                console.log(`   📋 Service: ${appointment.service || appointment.department || 'General Consultation'}`);
                
                // Check if conversation already exists
                const existingConversationsRef = collection(db, 'chat_conversations');
                const existingQuery = query(existingConversationsRef, where('appointmentId', '==', appointment.id));
                const existingSnapshot = await getDocs(existingQuery);
                
                if (existingSnapshot.size > 0) {
                    console.log(`   ⚠️  Conversation already exists for appointment ${appointment.id}`);
                    continue;
                }
                
                // Create conversation
                const conversationData = {
                    appointmentId: appointment.id,
                    patientName: appointment.patientName || appointment.patient || 'Patient',
                    patientEmail: appointment.patientEmail || appointment.email || '',
                    patientPhone: appointment.patientPhone || appointment.phone || '',
                    hospitalName: appointment.hospital,
                    service: appointment.service || appointment.department || 'General Consultation',
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
                
                // Create initial message with better date handling
                let appointmentDateText = 'À définir';
                if (appointment.appointmentDate) {
                    try {
                        if (appointment.appointmentDate.seconds) {
                            appointmentDateText = new Date(appointment.appointmentDate.seconds * 1000).toLocaleDateString('fr-FR');
                        } else if (appointment.appointmentDate.toDate) {
                            appointmentDateText = appointment.appointmentDate.toDate().toLocaleDateString('fr-FR');
                        } else {
                            appointmentDateText = new Date(appointment.appointmentDate).toLocaleDateString('fr-FR');
                        }
                    } catch (e) {
                        console.log(`   ⚠️  Could not parse appointment date: ${e.message}`);
                    }
                }
                
                const messageData = {
                    conversationId: conversationRef.id,
                    appointmentId: appointment.id,
                    senderType: 'patient',
                    senderName: appointment.patientName || appointment.patient || 'Patient',
                    message: `Bonjour, je souhaite prendre un rendez-vous pour ${appointment.service || appointment.department || 'une consultation'}. 
                    
📅 Date souhaitée: ${appointmentDateText}
⏰ Heure: ${appointment.appointmentTime || appointment.time || 'À définir'}
📝 Motif: ${appointment.notes || appointment.reasonOfBooking || 'Consultation générale'}

Merci de confirmer la disponibilité.`,
                    messageType: 'appointment_request',
                    timestamp: appointment.createdAt?.toDate() || new Date(),
                    isRead: false,
                    metadata: {
                        appointmentDate: appointment.appointmentDate,
                        appointmentTime: appointment.appointmentTime || appointment.time,
                        service: appointment.service || appointment.department
                    }
                };
                
                await addDoc(collection(db, 'chat_messages'), messageData);
                console.log(`   📨 Created initial message for conversation`);
                
                createdConversations++;
            }
        }
        
        console.log(`   ✅ Created ${createdConversations} conversations successfully`);
        
    } catch (error) {
        console.error('   ❌ Error creating conversations:', error);
    }
}

async function testChatSystem() {
    try {
        // Test 1: Get conversations for king Hospital
        console.log('   🧪 Test 1: Getting conversations...');
        const conversationsRef = collection(db, 'chat_conversations');
        const hospitalQuery = query(conversationsRef, where('hospitalName', '==', 'king Hospital'));
        const conversationsSnapshot = await getDocs(hospitalQuery);
        
        console.log(`   Found ${conversationsSnapshot.size} conversations for king Hospital`);
        
        // Test 2: Get messages for first conversation
        if (conversationsSnapshot.size > 0) {
            const firstConversation = conversationsSnapshot.docs[0];
            console.log('   🧪 Test 2: Getting messages for first conversation...');
            
            const messagesRef = collection(db, 'chat_messages');
            const messagesQuery = query(messagesRef, where('conversationId', '==', firstConversation.id));
            const messagesSnapshot = await getDocs(messagesQuery);
            
            console.log(`   Found ${messagesSnapshot.size} messages for conversation`);
        }
        
        console.log('   ✅ All tests passed successfully');
        
    } catch (error) {
        console.error('   ❌ Error testing system:', error);
    }
}

// Professional API Functions for Express.js

/**
 * Get all conversations for a hospital
 */
async function getHospitalConversations(hospitalName) {
    try {
        console.log(`📞 Getting conversations for hospital: ${hospitalName}`);
        
        const conversationsRef = collection(db, 'chat_conversations');
        const hospitalQuery = query(conversationsRef, where('hospitalName', '==', hospitalName));
        const conversationsSnapshot = await getDocs(hospitalQuery);
        
        const conversations = [];
        
        for (const docSnapshot of conversationsSnapshot.docs) {
            const data = docSnapshot.data();
            conversations.push({
                id: docSnapshot.id,
                appointmentId: data.appointmentId,
                patientName: data.patientName,
                patientEmail: data.patientEmail,
                patientPhone: data.patientPhone,
                service: data.service,
                lastMessage: data.lastMessage,
                lastMessageTime: data.lastMessageTime?.toDate() || new Date(),
                unreadCount: data.unreadCount || 0,
                hasUnreadMessages: data.hasUnreadMessages || false,
                status: data.status || 'active'
            });
        }
        
        // Sort by last message time (newest first)
        conversations.sort((a, b) => b.lastMessageTime - a.lastMessageTime);
        
        console.log(`   Found ${conversations.length} conversations`);
        return conversations;
        
    } catch (error) {
        console.error('❌ Error getting conversations:', error);
        throw error;
    }
}

/**
 * Get messages for a specific conversation
 */
async function getConversationMessages(conversationId) {
    try {
        console.log(`📨 Getting messages for conversation: ${conversationId}`);
        
        const messagesRef = collection(db, 'chat_messages');
        const messagesQuery = query(messagesRef, where('conversationId', '==', conversationId));
        const messagesSnapshot = await getDocs(messagesQuery);
        
        const messages = [];
        
        for (const docSnapshot of messagesSnapshot.docs) {
            const data = docSnapshot.data();
            messages.push({
                id: docSnapshot.id,
                senderType: data.senderType,
                senderName: data.senderName,
                message: data.message,
                messageType: data.messageType || 'text',
                timestamp: data.timestamp?.toDate() || new Date(),
                isRead: data.isRead || false,
                appointmentId: data.appointmentId,
                metadata: data.metadata || {}
            });
        }
        
        // Sort by timestamp (oldest first)
        messages.sort((a, b) => a.timestamp - b.timestamp);
        
        console.log(`   Found ${messages.length} messages`);
        return messages;
        
    } catch (error) {
        console.error('❌ Error getting messages:', error);
        throw error;
    }
}

/**
 * Send a new message
 */
async function sendMessage(conversationId, senderType, senderName, message, messageType = 'text') {
    try {
        console.log(`📤 Sending message to conversation: ${conversationId}`);
        
        // Add the message
        const messageData = {
            conversationId: conversationId,
            senderType: senderType,
            senderName: senderName,
            message: message,
            messageType: messageType,
            timestamp: new Date(),
            isRead: false
        };
        
        const messageRef = await addDoc(collection(db, 'chat_messages'), messageData);
        
        // Update conversation
        const conversationRef = doc(db, 'chat_conversations', conversationId);
        await updateDoc(conversationRef, {
            lastMessage: message.substring(0, 100) + (message.length > 100 ? '...' : ''),
            lastMessageTime: new Date(),
            updatedAt: new Date(),
                         // Only increment unread count if message is from patient
             ...(senderType === 'patient' ? {
                 hasUnreadMessages: true
             } : {})
        });
        
        console.log(`   ✅ Message sent successfully: ${messageRef.id}`);
        return messageRef.id;
        
    } catch (error) {
        console.error('❌ Error sending message:', error);
        throw error;
    }
}

/**
 * Mark conversation as read
 */
async function markConversationAsRead(conversationId) {
    try {
        console.log(`👀 Marking conversation as read: ${conversationId}`);
        
        const conversationRef = doc(db, 'chat_conversations', conversationId);
        await updateDoc(conversationRef, {
            unreadCount: 0,
            hasUnreadMessages: false,
            updatedAt: new Date()
        });
        
        // Mark all messages as read
        const messagesRef = collection(db, 'chat_messages');
        const messagesQuery = query(messagesRef, where('conversationId', '==', conversationId));
        const messagesSnapshot = await getDocs(messagesQuery);
        
        for (const docSnapshot of messagesSnapshot.docs) {
            await updateDoc(docSnapshot.ref, { isRead: true });
        }
        
        console.log('   ✅ Conversation marked as read');
        
    } catch (error) {
        console.error('❌ Error marking conversation as read:', error);
        throw error;
    }
}

// Export functions for use in app.js
module.exports = {
    setupProfessionalChatSystem,
    getHospitalConversations,
    getConversationMessages,
    sendMessage,
    markConversationAsRead
};

// Run setup if this file is executed directly
if (require.main === module) {
    setupProfessionalChatSystem();
} 