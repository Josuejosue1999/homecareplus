const { db, collection, query, where, getDocs, doc, getDoc, addDoc, updateDoc, serverTimestamp, orderBy, limit, writeBatch } = require('./config/firebase.js');

// Version simplifiée du système de chat qui ne nécessite pas d'indexes complexes
class SimpleChatSystem {
  
  // Récupérer les conversations pour une clinique (sans orderBy pour éviter l'index)
  async getHospitalConversations(clinicId) {
    try {
      console.log(`Getting conversations for clinic: ${clinicId}`);
      
      // Requête simple sans orderBy pour éviter l'index
      const conversationsQuery = query(
        collection(db, 'chat_conversations'),
        where('clinicId', '==', clinicId)
      );
      
      const snapshot = await getDocs(conversationsQuery);
      const conversations = [];
      
      snapshot.forEach(doc => {
        const data = doc.data();
        conversations.push({
          id: doc.id,
          ...data,
          lastMessageTime: data.lastMessageTime?.toDate?.() || new Date(),
          createdAt: data.createdAt?.toDate?.() || new Date(),
          hasUnreadMessages: (data.unreadCount || 0) > 0,
          unreadCount: data.unreadCount || 0
        });
      });
      
      // Tri côté client par lastMessageTime
      conversations.sort((a, b) => b.lastMessageTime - a.lastMessageTime);
      
      console.log(`Found ${conversations.length} conversations for hospital`);
      return conversations;
      
    } catch (error) {
      console.error('Error fetching conversations:', error);
      return [];
    }
  }
  
  // Récupérer les messages d'une conversation (avec une requête simple)
  async getConversationMessages(conversationId) {
    try {
      console.log(`Getting messages for conversation: ${conversationId}`);
      
      // Requête simple sans orderBy
      const messagesQuery = query(
        collection(db, 'chat_messages'),
        where('conversationId', '==', conversationId)
      );
      
      const snapshot = await getDocs(messagesQuery);
      const messages = [];
      
      snapshot.forEach(doc => {
        const data = doc.data();
        messages.push({
          id: doc.id,
          ...data,
          timestamp: data.timestamp?.toDate?.() || new Date()
        });
      });
      
      // Tri côté client par timestamp
      messages.sort((a, b) => a.timestamp - b.timestamp);
      
      console.log(`Found ${messages.length} messages for conversation`);
      return messages;
      
    } catch (error) {
      console.error('Error fetching messages:', error);
      return [];
    }
  }
  
  // Envoyer un message
  async sendMessage(conversationId, senderId, senderName, senderType, content, messageType = 'text') {
    try {
      console.log(`Sending message from ${senderName} (${senderType})`);
      
      // FIXÉ: Récupérer l'information du sender depuis Firestore
      let actualSenderName = senderName;
      let senderImage = null;
      
      if (senderType === 'clinic' || senderType === 'hospital') {
        try {
          const clinicDoc = await getDoc(doc(db, 'clinics', senderId));
          if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            actualSenderName = clinicData.name || clinicData.clinicName || senderName;
            senderImage = clinicData.imageUrl || clinicData.image || clinicData.profileImage;
            console.log(`✅ Clinic name: ${actualSenderName}, has image: ${senderImage ? 'Yes' : 'No'}`);
          }
        } catch (error) {
          console.log('⚠️ Could not fetch clinic info:', error.message);
        }
      }
      
      const messageData = {
        conversationId,
        senderId,
        senderName: actualSenderName, // Utiliser le vrai nom
        senderType: senderType === 'hospital' ? 'clinic' : senderType, // Normaliser le type
        message: content, // FIXÉ: Utiliser 'message' au lieu de 'content' pour la compatibilité
        messageType,
        timestamp: serverTimestamp(),
        isRead: false, // FIXÉ: Utiliser 'isRead' au lieu de 'read'
        hospitalImage: (senderType === 'clinic' || senderType === 'hospital') ? senderImage : null,
      };
      
      // Ajouter le message
      const messageRef = await addDoc(collection(db, 'chat_messages'), messageData);
      
      // Mettre à jour la conversation
      const conversationRef = doc(db, 'chat_conversations', conversationId);
      await updateDoc(conversationRef, {
        lastMessage: content,
        lastMessageTime: serverTimestamp(),
        hasUnreadMessages: true,
        unreadCount: senderType === 'patient' ? 1 : 0,
        updatedAt: serverTimestamp(),
      });
      
      console.log(`✅ Message sent with ID: ${messageRef.id}`);
      return { id: messageRef.id, ...messageData };
      
    } catch (error) {
      console.error('❌ Error sending message:', error);
      throw error;
    }
  }
  
  // Marquer une conversation comme lue
  async markConversationAsRead(conversationId) {
    try {
      const conversationRef = doc(db, 'chat_conversations', conversationId);
      await updateDoc(conversationRef, {
        unreadCount: 0
      });
      
      console.log(`Conversation ${conversationId} marked as read`);
      return true;
      
    } catch (error) {
      console.error('Error marking conversation as read:', error);
      return false;
    }
  }

  // 🗑️ SUPPRIMER UNE CONVERSATION (Soft Delete)
  async deleteConversation(conversationId, isClinic = true) {
    try {
      console.log(`🗑️ Deleting conversation ${conversationId} for ${isClinic ? 'clinic' : 'patient'}`);
      
      // Soft delete: marquer la conversation comme supprimée pour cet utilisateur
      const updateData = {
        updatedAt: serverTimestamp(),
      };

      if (isClinic) {
        updateData.deletedByClinic = true;
        updateData.deletedByClinicAt = serverTimestamp();
      } else {
        updateData.deletedByPatient = true;
        updateData.deletedByPatientAt = serverTimestamp();
      }

      const conversationRef = doc(db, 'chat_conversations', conversationId);
      await updateDoc(conversationRef, updateData);

      console.log('✅ Conversation marked as deleted successfully');

      // 🔥 Vérifier si la conversation a été supprimée par les deux parties
      const conversationDoc = await getDoc(conversationRef);

      if (conversationDoc.exists()) {
        const data = conversationDoc.data();
        const deletedByPatient = data.deletedByPatient || false;
        const deletedByClinic = data.deletedByClinic || false;

        // Si supprimée par les deux parties, supprimer définitivement
        if (deletedByPatient && deletedByClinic) {
          console.log('🔥 Both parties deleted conversation, removing permanently');
          
          // Supprimer tous les messages de la conversation
          const messagesQuery = query(
            collection(db, 'chat_messages'),
            where('conversationId', '==', conversationId)
          );
          const messagesSnapshot = await getDocs(messagesQuery);

          const batch = writeBatch(db);
          messagesSnapshot.docs.forEach(messageDoc => {
            batch.delete(messageDoc.ref);
          });

          // Supprimer la conversation
          batch.delete(conversationRef);
          
          await batch.commit();
          console.log('✅ Conversation and messages permanently deleted');
        }
      }

      return { success: true };

    } catch (error) {
      console.error('❌ Error deleting conversation:', error);
      throw error;
    }
  }

  // 📋 RÉCUPÉRER LES CONVERSATIONS NON SUPPRIMÉES POUR CLINIQUE
  async getHospitalConversationsFiltered(clinicId) {
    try {
      console.log(`📋 Getting filtered conversations for clinic: ${clinicId}`);
      
      // Requête simple sans orderBy pour éviter l'index
      const conversationsQuery = query(
        collection(db, 'chat_conversations'),
        where('clinicId', '==', clinicId)
      );
      
      const snapshot = await getDocs(conversationsQuery);
      const conversations = [];
      
      snapshot.forEach(doc => {
        const data = doc.data();
        
        // Exclure les conversations supprimées par la clinique
        const deletedByClinic = data.deletedByClinic || false;
        
        if (!deletedByClinic) {
          conversations.push({
            id: doc.id,
            ...data,
            lastMessageTime: data.lastMessageTime?.toDate?.() || new Date(),
            createdAt: data.createdAt?.toDate?.() || new Date(),
            hasUnreadMessages: (data.unreadCount || 0) > 0,
            unreadCount: data.unreadCount || 0
          });
        }
      });
      
      // Tri côté client par lastMessageTime
      conversations.sort((a, b) => b.lastMessageTime - a.lastMessageTime);
      
      console.log(`✅ Found ${conversations.length} active conversations for hospital`);
      return conversations;
      
    } catch (error) {
      console.error('❌ Error fetching filtered conversations:', error);
      return [];
    }
  }
  
  // Créer une nouvelle conversation (utilisé par l'app mobile)
  async createConversation(clinicId, clinicName, patientId, patientName, appointmentId, appointmentType) {
    try {
      console.log(`Creating conversation for patient ${patientName} with clinic ${clinicName}`);
      
      const conversationData = {
        clinicId,
        clinicName,
        patientId,
        patientName,
        appointmentId,
        appointmentType,
        status: 'pending',
        createdAt: serverTimestamp(),
        lastMessageTime: serverTimestamp(),
        lastMessage: 'Nouvelle demande de rendez-vous',
        unreadCount: 1,
        isActive: true
      };
      
      const conversationRef = await addDoc(collection(db, 'chat_conversations'), conversationData);
      
      // Ajouter le message initial
      const initialMessage = {
        conversationId: conversationRef.id,
        senderId: patientId,
        senderName: patientName,
        senderType: 'patient',
        content: `Bonjour, je souhaite prendre un rendez-vous.\n\nType: ${appointmentType}\nPatient: ${patientName}\nStatut: En attente de confirmation`,
        messageType: 'appointment_request',
        timestamp: serverTimestamp(),
        read: false,
        appointmentDetails: {
          appointmentId,
          type: appointmentType,
          status: 'pending'
        }
      };
      
      await addDoc(collection(db, 'chat_messages'), initialMessage);
      
      console.log(`Conversation created with ID: ${conversationRef.id}`);
      return { id: conversationRef.id, ...conversationData };
      
    } catch (error) {
      console.error('Error creating conversation:', error);
      throw error;
    }
  }
}

const simpleChatSystem = new SimpleChatSystem();

// API Functions pour le serveur
async function getHospitalConversations(req, res) {
  try {
    const user = req.user;
    if (!user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    
    const conversations = await simpleChatSystem.getHospitalConversations(user.uid);
    res.json({ 
      success: true, 
      conversations: conversations || [],
      count: conversations ? conversations.length : 0
    });
    
  } catch (error) {
    console.error('Error in getHospitalConversations:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function getConversationMessages(req, res) {
  try {
    const { conversationId } = req.params;
    const messages = await simpleChatSystem.getConversationMessages(conversationId);
    res.json({ 
      success: true, 
      messages: messages || [],
      count: messages ? messages.length : 0
    });
    
  } catch (error) {
    console.error('Error in getConversationMessages:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function sendMessage(req, res) {
  try {
    const { conversationId, message: content, messageType = 'text' } = req.body;
    const user = req.user;
    
    console.log('🏥 Hospital sending message:', { conversationId, content, messageType, userId: user?.uid });
    
    if (!user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    
    if (!conversationId || !content) {
      return res.status(400).json({ success: false, error: 'Missing conversationId or message content' });
    }
    
    // FIXÉ: Récupérer le nom de la clinique depuis Firestore
    let senderName = user.displayName || 'Hôpital';
    try {
      const clinicDoc = await getDoc(doc(db, 'clinics', user.uid));
      if (clinicDoc.exists()) {
        const clinicData = clinicDoc.data();
        senderName = clinicData.name || clinicData.clinicName || senderName;
        console.log('✅ Found clinic name:', senderName);
      }
    } catch (error) {
      console.log('⚠️ Could not fetch clinic name:', error.message);
    }
    
    const message = await simpleChatSystem.sendMessage(
      conversationId,
      user.uid,
      senderName,
      'clinic', // FIXÉ: Utiliser 'clinic' au lieu de 'hospital'
      content,
      messageType
    );
    
    res.json({ 
      success: true, 
      message: message,
      messageId: message.id
    });
    
  } catch (error) {
    console.error('❌ Error in sendMessage:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function markConversationAsRead(req, res) {
  try {
    const { conversationId } = req.params;
    const success = await simpleChatSystem.markConversationAsRead(conversationId);
    res.json({ success });
    
  } catch (error) {
    console.error('Error in markConversationAsRead:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

// API pour supprimer une conversation
async function deleteConversation(req, res) {
  try {
    const { conversationId } = req.params;
    const user = req.user;
    
    console.log('🗑️ API: Deleting conversation request:', { conversationId, userId: user?.uid });
    
    if (!user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    
    if (!conversationId) {
      return res.status(400).json({ success: false, error: 'Missing conversationId' });
    }
    
    const result = await simpleChatSystem.deleteConversation(conversationId, true); // true = isClinic
    
    res.json({ 
      success: true, 
      message: 'Conversation deleted successfully'
    });
    
  } catch (error) {
    console.error('❌ Error in deleteConversation API:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

// API pour récupérer les conversations filtrées (non supprimées)
async function getHospitalConversationsFiltered(req, res) {
  try {
    const user = req.user;
    if (!user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    
    const conversations = await simpleChatSystem.getHospitalConversationsFiltered(user.uid);
    res.json({ 
      success: true, 
      conversations: conversations || [],
      count: conversations ? conversations.length : 0
    });
    
  } catch (error) {
    console.error('Error in getHospitalConversationsFiltered:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

module.exports = {
  SimpleChatSystem,
  simpleChatSystem,
  getHospitalConversations,
  getConversationMessages,
  sendMessage,
  markConversationAsRead,
  deleteConversation,
  getHospitalConversationsFiltered
}; 