/**
 * Messages Page Management
 * Handles chat conversations, message display, and real-time messaging
 */
class MessagesPage {
    constructor() {
        this.conversations = [];
        this.currentConversation = null;
        this.updateInterval = null;
        this.patientAvatars = new Map(); // Cache for patient avatars
        this.init();
    }

    init() {
        console.log('🔔 Initializing Messages Page...');
        this.setupEventListeners();
        this.loadConversations();
        this.startRealTimeUpdates();
    }

    setupEventListeners() {
        // Navigation event listeners
        document.addEventListener('click', (e) => {
            if (e.target.closest('.nav-link[data-target="messages"]')) {
                e.preventDefault();
                this.showMessagesContent();
            }
        });
    }

    showMessagesContent() {
        // Hide all dashboard sections
        document.querySelectorAll('.dashboard-section').forEach(section => {
            section.style.display = 'none';
        });
        
        // Show messages section
        const messagesSection = document.getElementById('messagesSection');
        if (messagesSection) {
            messagesSection.style.display = 'block';
            this.loadConversations(); // Refresh when showing
        }
        
        // Update sidebar active state
        document.querySelectorAll('.sidebar .nav-item').forEach(item => {
            item.classList.remove('active');
        });
        document.querySelector('.sidebar .nav-item:has(#messages-link)').classList.add('active');
        
        // Update header title
        const headerTitle = document.querySelector('.header-title h1');
        if (headerTitle) {
            headerTitle.innerHTML = '<i class="fas fa-comments me-2"></i>Messages';
        }
    }

    async loadConversations() {
        try {
            console.log('📨 Loading hospital conversations...');
            
            const response = await fetch('/api/chat/conversations');
            if (response.ok) {
                const data = await response.json();
                if (data.success) {
                    this.conversations = data.conversations || [];
                    console.log(`✅ Loaded ${this.conversations.length} conversations`);
                    
                    // Load patient avatars
                    await this.loadPatientAvatars();
                    
                    this.renderConversationsList();
                    this.updateStatistics();
                } else {
                    console.error('Failed to load conversations:', data.error);
                }
            }
        } catch (error) {
            console.error('Error loading conversations:', error);
        }
    }

    // 🔧 FIX: Load patient avatars for hospital chat
    async loadPatientAvatars() {
        const promises = this.conversations.map(async (conversation) => {
            if (!this.patientAvatars.has(conversation.patientId)) {
                try {
                    const response = await fetch(`/api/chat/patient-avatar/${conversation.patientId}`);
                    if (response.ok) {
                        const data = await response.json();
                        if (data.success) {
                            this.patientAvatars.set(conversation.patientId, {
                                avatar: data.avatar,
                                name: data.name
                            });
                        }
                    }
                } catch (error) {
                    console.log(`Could not load avatar for patient ${conversation.patientId}`);
                }
            }
        });
        
        await Promise.all(promises);
    }

    renderConversationsList() {
        const messagesList = document.getElementById('messagesList');
        if (!messagesList) return;

        if (this.conversations.length === 0) {
            messagesList.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-comments"></i>
                    <h6>No conversations yet</h6>
                    <p>Conversations will appear here when patients book appointments</p>
                </div>
            `;
            return;
        }

        // 🔧 FIX: Show patient avatars, not hospital images
        const conversationsHtml = this.conversations.map(conversation => {
            const timeAgo = this.getTimeAgo(new Date(conversation.lastMessageTime));
            const unreadBadge = conversation.hasUnreadMessages ? 
                `<span class="badge bg-primary">${conversation.unreadCount}</span>` : '';
            
            // Get patient avatar from cache
            const patientInfo = this.patientAvatars.get(conversation.patientId);
            const patientAvatar = patientInfo?.avatar;
            const patientName = patientInfo?.name || conversation.patientName;
            
            return `
                <div class="message-item ${conversation.hasUnreadMessages ? 'unread' : ''}" 
                     data-conversation-id="${conversation.id}">
                    <div class="message-avatar">
                        ${this.renderPatientAvatar(patientAvatar, patientName)}
                    </div>
                    <div class="message-content">
                        <div class="message-header">
                            <h6 class="message-sender">${patientName}</h6>
                            <span class="message-time">${timeAgo}</span>
                            ${unreadBadge}
                        </div>
                        <p class="message-preview">${conversation.lastMessage}</p>
                        <div class="conversation-meta">
                            <small class="text-muted">
                                <i class="fas fa-user"></i> Patient ID: ${conversation.patientId.substring(0, 8)}...
                            </small>
                        </div>
                    </div>
                    <div class="message-actions">
                        <button class="btn btn-sm btn-outline-primary" onclick="messagesPage.openConversation('${conversation.id}')" title="View conversation">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger ms-1" onclick="messagesPage.deleteConversation('${conversation.id}')" title="Delete conversation">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
            `;
        }).join('');

        messagesList.innerHTML = conversationsHtml;
    }

    // 🔧 FIX: Render patient avatar with fallback to initials
    renderPatientAvatar(avatarUrl, patientName) {
        if (avatarUrl && avatarUrl.trim() !== '') {
            if (avatarUrl.startsWith('data:image')) {
                // Base64 image
                return `<img src="${avatarUrl}" alt="${patientName}" class="patient-avatar" onerror="this.parentNode.innerHTML=this.parentNode.dataset.fallback">`;
            } else if (avatarUrl.startsWith('http')) {
                // Network image
                return `<img src="${avatarUrl}" alt="${patientName}" class="patient-avatar" onerror="this.parentNode.innerHTML=this.parentNode.dataset.fallback">`;
            }
        }
        
        // Fallback to initials
        const initials = this.getPatientInitials(patientName);
        return `
            <div class="patient-avatar-initials" data-fallback="${this.getPatientInitials(patientName)}">
                ${initials}
            </div>
        `;
    }

    getPatientInitials(name) {
        if (!name || name.trim() === '') return 'P';
        
        const words = name.trim().split(' ');
        if (words.length >= 2) {
            return `${words[0][0].toUpperCase()}${words[1][0].toUpperCase()}`;
        } else {
            return words[0][0].toUpperCase();
        }
    }

    updateStatistics() {
        const totalMessages = this.conversations.length;
        const unreadMessages = this.conversations.filter(c => c.hasUnreadMessages).length;
        const totalUnreadCount = this.conversations.reduce((sum, c) => sum + (c.unreadCount || 0), 0);

        document.getElementById('totalMessages').textContent = totalMessages;
        document.getElementById('unreadMessages').textContent = totalUnreadCount;
        document.getElementById('sentMessages').textContent = totalMessages; // Approximation
        document.getElementById('pendingReplies').textContent = unreadMessages;
    }

    async openConversation(conversationId) {
        try {
            console.log('💬 Opening conversation:', conversationId);
            
            // Find the conversation
            const conversation = this.conversations.find(c => c.id === conversationId);
            if (!conversation) {
                console.error('Conversation not found');
                return;
            }

            this.currentConversation = conversation;
            
            // Load messages for this conversation
            await this.loadConversationMessages(conversationId);
            
            // Mark as read
            if (conversation.hasUnreadMessages) {
                await this.markConversationAsRead(conversationId);
            }
            
            // Show chat modal
            this.showChatModal(conversation);
            
        } catch (error) {
            console.error('Error opening conversation:', error);
        }
    }

    async loadConversationMessages(conversationId) {
        try {
            const response = await fetch(`/api/chat/conversation/${conversationId}/messages`);
            if (response.ok) {
                const data = await response.json();
                if (data.success) {
                    this.currentConversation.messages = data.messages || [];
                }
            }
        } catch (error) {
            console.error('Error loading conversation messages:', error);
        }
    }

    async markConversationAsRead(conversationId) {
        try {
            const response = await fetch(`/api/chat/mark-as-read/${conversationId}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                }
            });
            
            if (response.ok) {
                // Update local conversation state
                const conversation = this.conversations.find(c => c.id === conversationId);
                if (conversation) {
                    conversation.hasUnreadMessages = false;
                    conversation.unreadCount = 0;
                }
                
                // Refresh the conversations list
                this.renderConversationsList();
                this.updateStatistics();
            }
        } catch (error) {
            console.error('Error marking conversation as read:', error);
        }
    }

    showChatModal(conversation) {
        // Create or update chat modal
        let chatModal = document.getElementById('chatModal');
        if (!chatModal) {
            chatModal = this.createChatModal();
        }

        // Update modal content
        this.updateChatModalContent(chatModal, conversation);
        
        // Show modal
        const modal = new bootstrap.Modal(chatModal);
        modal.show();
    }

    createChatModal() {
        const modalHtml = `
            <div class="modal fade" id="chatModal" tabindex="-1" aria-labelledby="chatModalLabel" aria-hidden="true">
                <div class="modal-dialog modal-lg modal-dialog-scrollable">
                    <div class="modal-content">
                        <div class="modal-header bg-primary text-white">
                            <h5 class="modal-title" id="chatModalLabel">
                                <i class="fas fa-comments me-2"></i>
                                <span id="chatPatientName">Chat</span>
                            </h5>
                            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
                        </div>
                        <div class="modal-body p-0">
                            <div class="chat-container">
                                <div class="chat-messages" id="chatMessages">
                                    <!-- Messages will be loaded here -->
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <div class="chat-input-container w-100">
                                <div class="input-group">
                                    <input type="text" class="form-control" id="chatMessageInput" 
                                           placeholder="Type your message..." maxlength="500">
                                    <button class="btn btn-primary" type="button" id="sendMessageBtn">
                                        <i class="fas fa-paper-plane"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;

        document.body.insertAdjacentHTML('beforeend', modalHtml);
        
        const modal = document.getElementById('chatModal');
        
        // Setup event listeners
        const sendBtn = modal.querySelector('#sendMessageBtn');
        const messageInput = modal.querySelector('#chatMessageInput');
        
        sendBtn.addEventListener('click', () => this.sendMessage());
        messageInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.sendMessage();
            }
        });

        return modal;
    }

    updateChatModalContent(modal, conversation) {
        // Update modal title with patient info
        const patientInfo = this.patientAvatars.get(conversation.patientId);
        const patientName = patientInfo?.name || conversation.patientName;
        modal.querySelector('#chatPatientName').textContent = `Chat with ${patientName}`;
        
        // Render messages
        this.renderChatMessages(modal, conversation.messages || []);
    }

    // 🔧 FIX: Professional chat message styling with avatars
    renderChatMessages(modal, messages) {
        const chatMessages = modal.querySelector('#chatMessages');
        if (!chatMessages) return;

        if (messages.length === 0) {
            chatMessages.innerHTML = `
                <div class="empty-chat">
                    <i class="fas fa-comments text-muted"></i>
                    <p class="text-muted mt-2">No messages yet. Start the conversation!</p>
                </div>
            `;
            return;
        }

        const messagesHtml = messages.map(message => {
            const isFromClinic = message.senderType === 'clinic';
            const messageTime = new Date(message.timestamp).toLocaleString();
            const alignment = isFromClinic ? 'justify-content-end' : 'justify-content-start';
            const bubbleClass = isFromClinic ? 'clinic-message' : 'patient-message';
            
            // Get avatar
            let avatar = '';
            if (isFromClinic) {
                // Hospital avatar
                avatar = message.hospitalImage 
                    ? `<img src="${message.hospitalImage}" class="message-avatar-img" alt="Hospital">`
                    : `<div class="message-avatar-placeholder hospital"><i class="fas fa-hospital"></i></div>`;
            } else {
                // Patient avatar
                const patientInfo = this.patientAvatars.get(this.currentConversation?.patientId);
                if (patientInfo?.avatar) {
                    avatar = `<img src="${patientInfo.avatar}" class="message-avatar-img" alt="Patient">`;
                } else {
                    const initials = this.getPatientInitials(message.senderName);
                    avatar = `<div class="message-avatar-placeholder patient">${initials}</div>`;
                }
            }
            
            return `
                <div class="chat-message-wrapper d-flex ${alignment} mb-3">
                    ${!isFromClinic ? `<div class="message-avatar me-2">${avatar}</div>` : ''}
                    <div class="chat-message ${bubbleClass} ${isFromClinic ? 'ms-auto' : ''}">
                        <div class="message-bubble">
                            <div class="message-header">
                                <small class="message-sender text-muted">${message.senderName}</small>
                                <small class="message-time text-muted ms-2">${messageTime}</small>
                            </div>
                            <div class="message-text">${this.formatMessageText(message.content || message.message || '')}</div>
                            ${message.appointmentId ? `
                                <div class="message-meta mt-2">
                                    <small class="text-muted">
                                        <i class="fas fa-calendar-check"></i>
                                        Appointment: ${message.appointmentId}
                                    </small>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                    ${isFromClinic ? `<div class="message-avatar ms-2">${avatar}</div>` : ''}
                </div>
            `;
        }).join('');

        chatMessages.innerHTML = messagesHtml;
        
        // Auto-scroll to bottom
        setTimeout(() => {
            chatMessages.scrollTop = chatMessages.scrollHeight;
        }, 100);
    }

    formatMessageText(text) {
        // Convert markdown-style formatting to HTML
        return text
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>')
            .replace(/\n/g, '<br>');
    }

    async sendMessage() {
        if (!this.currentConversation) return;

        const messageInput = document.getElementById('chatMessageInput');
        const message = messageInput.value.trim();
        
        if (!message) return;

        try {
            // Disable input while sending
            messageInput.disabled = true;
            document.getElementById('sendMessageBtn').disabled = true;

            const response = await fetch('/api/chat/send-message', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    conversationId: this.currentConversation.id,
                    message: message,
                    messageType: 'text'
                })
            });

            const result = await response.json();

            if (result.success) {
                // Clear input
                messageInput.value = '';
                
                // Reload messages
                await this.loadConversationMessages(this.currentConversation.id);
                this.renderChatMessages(
                    document.getElementById('chatModal'), 
                    this.currentConversation.messages
                );
                
                // Refresh conversations list
                this.loadConversations();
                
                console.log('✅ Message sent successfully');
            } else {
                throw new Error(result.error || 'Failed to send message');
            }
        } catch (error) {
            console.error('❌ Error sending message:', error);
            alert('Failed to send message. Please try again.');
        } finally {
            // Re-enable input
            messageInput.disabled = false;
            document.getElementById('sendMessageBtn').disabled = false;
            messageInput.focus();
        }
    }

    // 🗑️ SUPPRIMER UNE CONVERSATION
    async deleteConversation(conversationId) {
        const conversation = this.conversations.find(c => c.id === conversationId);
        if (!conversation) return;
        
        // Confirmation avec SweetAlert
        const result = await Swal.fire({
            title: 'Delete Conversation?',
            text: `Are you sure you want to delete the conversation with ${conversation.patientName}? This action cannot be undone.`,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#dc3545',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Yes, delete it!',
            cancelButtonText: 'Cancel'
        });

        if (result.isConfirmed) {
            try {
                console.log('🗑️ Deleting conversation:', conversationId);
                
                const response = await fetch(`/api/chat/conversation/${conversationId}`, {
                    method: 'DELETE',
                    headers: {
                        'Content-Type': 'application/json'
                    }
                });

                if (response.ok) {
                    // Supprimer de la liste locale
                    this.conversations = this.conversations.filter(c => c.id !== conversationId);
                    
                    // Mettre à jour l'affichage
                    this.renderConversationsList();
                    this.updateStatistics();
                    
                    // Notification de succès
                    Swal.fire({
                        title: 'Deleted!',
                        text: 'The conversation has been deleted.',
                        icon: 'success',
                        timer: 2000,
                        showConfirmButton: false
                    });
                    
                    console.log('✅ Conversation deleted successfully');
                } else {
                    throw new Error('Failed to delete conversation');
                }
            } catch (error) {
                console.error('❌ Error deleting conversation:', error);
                Swal.fire({
                    title: 'Error!',
                    text: 'Failed to delete the conversation. Please try again.',
                    icon: 'error',
                    confirmButtonText: 'OK'
                });
            }
        }
    }

    // 🔁 Real-time updates every 10 seconds
    startRealTimeUpdates() {
        this.updateInterval = setInterval(() => {
            this.loadConversations();
        }, 10000); // Update every 10 seconds
    }

    composeNewMessage() {
        // For now, show an info message
        Swal.fire({
            title: 'New Message',
            text: 'New messages are automatically created when patients book appointments. You can respond to existing conversations.',
            icon: 'info',
            confirmButtonText: 'OK'
        });
    }

    getTimeAgo(date) {
        const now = new Date();
        const diffInSeconds = Math.floor((now - date) / 1000);
        
        if (diffInSeconds < 60) return 'Just now';
        if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
        if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
        if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`;
        
        return date.toLocaleDateString();
    }

    destroy() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
        }
    }
}

// Initialize messages page when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.messagesPage = new MessagesPage();
});

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = MessagesPage;
} 