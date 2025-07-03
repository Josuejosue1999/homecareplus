/**
 * Professional Messages Page Management
 * Handles chat conversations, message display, and real-time messaging with enhanced UI
 */
class MessagesPage {
    constructor() {
        this.conversations = [];
        this.currentConversation = null;
        this.updateInterval = null;
        this.patientAvatars = new Map(); // Cache for patient avatars
        this.hospitalAvatar = null; // Cache for hospital avatar
        this.init();
    }

    init() {
        this.bindEvents();
        this.loadHospitalAvatar();
        this.loadConversations();
        this.startRealTimeUpdates();
    }

    bindEvents() {
        // Refresh button
        const refreshBtn = document.getElementById('refreshMessages');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => this.loadConversations());
        }

        // Filter buttons
        const filterBtns = document.querySelectorAll('.filter-btn');
        filterBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                const filter = e.target.dataset.filter;
                this.filterConversations(filter);
            });
        });

        // Search functionality
        const searchInput = document.getElementById('conversationSearch');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.searchConversations(e.target.value);
            });
        }
    }

    // 🔧 FIX: Load hospital avatar for chat display
    async loadHospitalAvatar() {
        try {
            const response = await fetch('/api/settings/hospital-image');
            if (response.ok) {
                const data = await response.json();
                if (data.success && data.imageUrl) {
                    this.hospitalAvatar = data.imageUrl;
                    console.log('✅ Hospital avatar loaded for professional chat');
                }
            }
        } catch (error) {
            console.error('❌ Error loading hospital avatar:', error);
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

    // 🔧 FIX: Load patient avatars for professional chat display
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
                                name: data.name || conversation.patientName,
                                email: data.email,
                                phone: data.phone
                            });
                            console.log(`✅ Loaded avatar for patient: ${data.name}`);
                        } else {
                            // Store placeholder info even if no avatar found
                            this.patientAvatars.set(conversation.patientId, {
                                avatar: null,
                                name: conversation.patientName,
                                email: conversation.patientEmail,
                                phone: conversation.patientPhone
                            });
                            console.log(`📷 No avatar found for patient ${conversation.patientId}, using placeholder`);
                        }
                    }
                } catch (error) {
                    console.log(`Could not load avatar for patient ${conversation.patientId}`);
                    // Store minimal info to prevent re-fetching
                    this.patientAvatars.set(conversation.patientId, {
                        avatar: null,
                        name: conversation.patientName
                    });
                }
            }
        });
        
        await Promise.all(promises);
        console.log(`✅ Loaded ${this.patientAvatars.size} patient avatars`);
    }

    renderConversationsList() {
        const messagesList = document.getElementById('messagesList');
        if (!messagesList) return;

        if (this.conversations.length === 0) {
            messagesList.innerHTML = `
                <div class="empty-conversations">
                    <div class="empty-icon">
                        <i class="fas fa-comments"></i>
                    </div>
                    <h3>No conversations yet</h3>
                    <p>Conversations will appear here when patients book appointments and send messages</p>
                </div>
            `;
            return;
        }

        // 🔧 FIX: Professional conversation list with proper avatars
        const conversationsHtml = this.conversations.map(conversation => {
            const timeAgo = this.getTimeAgo(new Date(conversation.lastMessageTime));
            const unreadBadge = conversation.hasUnreadMessages ? 
                `<span class="unread-badge">${conversation.unreadCount}</span>` : '';
            
            // Get patient info from cache
            const patientInfo = this.patientAvatars.get(conversation.patientId);
            const patientName = patientInfo?.name || conversation.patientName;
            
            return `
                <div class="conversation-item ${conversation.hasUnreadMessages ? 'unread' : ''}" 
                     data-conversation-id="${conversation.id}"
                     onclick="messagesPage.openConversation('${conversation.id}')">
                    
                    <div class="patient-avatar-container">
                        ${this.renderPatientAvatar(patientInfo?.avatar, patientName)}
                        ${conversation.hasUnreadMessages ? '<div class="online-indicator"></div>' : ''}
                    </div>
                    
                    <div class="conversation-content">
                        <div class="conversation-header">
                            <h3 class="patient-name">${patientName}</h3>
                            <span class="conversation-time">${timeAgo}</span>
                        </div>
                        
                        <p class="last-message">${conversation.lastMessage}</p>
                        
                        <div class="conversation-meta">
                            <span class="patient-id">ID: ${conversation.patientId.substring(0, 8)}...</span>
                            ${unreadBadge}
                        </div>
                    </div>
                </div>
            `;
        }).join('');

        messagesList.innerHTML = conversationsHtml;
    }

    // 🔧 FIX: Professional patient avatar rendering with fallback
    renderPatientAvatar(avatarUrl, patientName) {
        if (avatarUrl && avatarUrl.trim() !== '' && avatarUrl !== 'null') {
            return `<img src="${avatarUrl}" alt="${patientName}" class="patient-avatar-img" 
                         onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                    <div class="patient-avatar-initials" style="display: none;">
                        ${this.getPatientInitials(patientName)}
                    </div>`;
        }
        
        // Fallback to initials
        return `<div class="patient-avatar-initials">
                    ${this.getPatientInitials(patientName)}
                </div>`;
    }

    getPatientInitials(name) {
        if (!name) return 'P';
        const words = name.trim().split(' ');
        if (words.length >= 2) {
            return (words[0][0] + words[1][0]).toUpperCase();
        }
        return name.substring(0, 2).toUpperCase();
    }

    getTimeAgo(date) {
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        if (diffMins < 1) return 'Just now';
        if (diffMins < 60) return `${diffMins}m ago`;
        if (diffHours < 24) return `${diffHours}h ago`;
        if (diffDays < 7) return `${diffDays}d ago`;
        return date.toLocaleDateString();
    }

    async openConversation(conversationId) {
        try {
            console.log('Opening conversation:', conversationId);
            
            // Find conversation
            const conversation = this.conversations.find(c => c.id === conversationId);
            if (!conversation) {
                console.error('Conversation not found:', conversationId);
                return;
            }
            
            this.currentConversation = conversation;
            
            // Load messages
            const response = await fetch(`/api/chat/messages/${conversationId}`);
            if (response.ok) {
                const data = await response.json();
                if (data.success) {
                    conversation.messages = data.messages || [];
                    this.showChatModal(conversation);
                    
                    // Mark as read
                    await this.markConversationAsRead(conversationId);
                }
            }
        } catch (error) {
            console.error('Error opening conversation:', error);
        }
    }

    showChatModal(conversation) {
        // Create modal if it doesn't exist
        let modal = document.getElementById('chatModal');
        if (!modal) {
            modal = this.createChatModal();
            document.body.appendChild(modal);
        }

        // Update modal content
        this.updateChatModalContent(modal, conversation);
        
        // Show modal
        const bootstrapModal = new bootstrap.Modal(modal);
        bootstrapModal.show();
        
        // Focus on input
        setTimeout(() => {
            const input = modal.querySelector('#chatInput');
            if (input) input.focus();
        }, 300);
    }

    createChatModal() {
        const modal = document.createElement('div');
        modal.className = 'modal fade chat-modal';
        modal.id = 'chatModal';
        modal.tabIndex = -1;
        
        modal.innerHTML = `
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title" id="chatPatientName">
                            <div class="chat-patient-initials">P</div>
                            Chat with Patient
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>
                    <div class="modal-body">
                        <div class="chat-messages-container" id="chatMessages">
                            <!-- Messages will be rendered here -->
                        </div>
                        <div class="chat-input-container">
                            <form class="chat-input-form" onsubmit="messagesPage.sendMessage(event)">
                                <div class="chat-input-wrapper">
                                    <textarea class="chat-input" id="chatInput" 
                                             placeholder="Type your message..." 
                                             rows="1"></textarea>
                                </div>
                                <button type="submit" class="chat-send-btn">
                                    <i class="fas fa-paper-plane"></i>
                                    Send
                                </button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        return modal;
    }

    updateChatModalContent(modal, conversation) {
        // Update modal title with patient info
        const patientInfo = this.patientAvatars.get(conversation.patientId);
        const patientName = patientInfo?.name || conversation.patientName;
        
        const titleElement = modal.querySelector('#chatPatientName');
        if (patientInfo?.avatar) {
            titleElement.innerHTML = `
                <img src="${patientInfo.avatar}" class="chat-patient-avatar" alt="${patientName}">
                Chat with ${patientName}
            `;
        } else {
            titleElement.innerHTML = `
                <div class="chat-patient-initials">${this.getPatientInitials(patientName)}</div>
                Chat with ${patientName}
            `;
        }
        
        // Render messages
        this.renderChatMessages(modal, conversation.messages || []);
    }

    // 🔧 FIX: Professional chat message rendering with proper avatars
    renderChatMessages(modal, messages) {
        const chatMessages = modal.querySelector('#chatMessages');
        if (!chatMessages) return;

        if (messages.length === 0) {
            chatMessages.innerHTML = `
                <div class="empty-chat">
                    <div class="empty-icon">
                        <i class="fas fa-comments"></i>
                    </div>
                    <p>No messages yet. Start the conversation!</p>
                </div>
            `;
            return;
        }

        const messagesHtml = messages.map(message => {
            const isFromClinic = message.senderType === 'clinic';
            const messageTime = new Date(message.timestamp).toLocaleString();
            const wrapperClass = isFromClinic ? 'hospital' : 'patient';
            
            // Get appropriate avatar with enhanced patient avatar loading
            let avatarHtml = '';
            if (isFromClinic) {
                // Hospital avatar - positioned on the right
                if (this.hospitalAvatar) {
                    avatarHtml = `<img src="${this.hospitalAvatar}" class="message-avatar-img" alt="Hospital">`;
                } else {
                    avatarHtml = `<div class="message-avatar-placeholder hospital">
                                    <i class="fas fa-hospital"></i>
                                  </div>`;
                }
            } else {
                // Patient avatar - enhanced loading from Firebase profile
                const patientInfo = this.patientAvatars.get(this.currentConversation?.patientId);
                console.log('🔍 Patient avatar info for conversation:', this.currentConversation?.patientId, patientInfo);
                
                // Try multiple sources for patient avatar
                let patientAvatarUrl = null;
                if (patientInfo?.avatar) {
                    patientAvatarUrl = patientInfo.avatar;
                } else if (message.patientAvatar) {
                    patientAvatarUrl = message.patientAvatar;
                } else if (this.currentConversation?.patientAvatar) {
                    patientAvatarUrl = this.currentConversation.patientAvatar;
                }
                
                if (patientAvatarUrl) {
                    avatarHtml = `<img src="${patientAvatarUrl}" class="message-avatar-img" alt="Patient" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                 <div class="message-avatar-placeholder patient" style="display: none;">${this.getPatientInitials(message.senderName || this.currentConversation?.patientName)}</div>`;
                } else {
                    const initials = this.getPatientInitials(message.senderName || this.currentConversation?.patientName || 'Patient');
                    avatarHtml = `<div class="message-avatar-placeholder patient">${initials}</div>`;
                }
            }
            
            return `
                <div class="message-wrapper ${wrapperClass}">
                    <div class="message-avatar">
                        ${avatarHtml}
                    </div>
                    <div class="message-bubble ${wrapperClass}">
                        <div class="message-content">${this.formatMessage(message.message)}</div>
                        <small class="message-time">${messageTime}</small>
                    </div>
                </div>
            `;
        }).join('');

        chatMessages.innerHTML = messagesHtml;
        
        // Scroll to bottom
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }

    formatMessage(message) {
        // Handle appointment confirmation messages with better formatting
        if (message.includes('**') || message.includes('✅')) {
            return message
                .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                .replace(/•/g, '&bull;')
                .replace(/\n/g, '<br>');
        }
        
        // Handle regular messages
        return message.replace(/\n/g, '<br>');
    }

    async sendMessage(event) {
        event.preventDefault();
        
        const input = document.getElementById('chatInput');
        const message = input.value.trim();
        
        if (!message || !this.currentConversation) return;
        
        try {
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
            
            if (response.ok) {
                const data = await response.json();
                if (data.success) {
                    // Clear input
                    input.value = '';
                    
                    // Reload conversation to show new message
                    await this.openConversation(this.currentConversation.id);
                    
                    // Reload conversations list
                    this.loadConversations();
                }
            }
        } catch (error) {
            console.error('Error sending message:', error);
        }
    }

    async markConversationAsRead(conversationId) {
        try {
            const response = await fetch('/api/chat/mark-read', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    conversationId: conversationId
                })
            });
            
            if (response.ok) {
                // Update local conversation
                const conversation = this.conversations.find(c => c.id === conversationId);
                if (conversation) {
                    conversation.hasUnreadMessages = false;
                    conversation.unreadCount = 0;
                }
                
                // Re-render conversations
                this.renderConversationsList();
                this.updateStatistics();
            }
        } catch (error) {
            console.error('Error marking conversation as read:', error);
        }
    }

    async deleteConversation(conversationId) {
        if (!confirm('Are you sure you want to delete this conversation?')) return;
        
        try {
            const response = await fetch(`/api/chat/conversations/${conversationId}`, {
                method: 'DELETE'
            });
            
            if (response.ok) {
                this.loadConversations();
            }
        } catch (error) {
            console.error('Error deleting conversation:', error);
        }
    }

    filterConversations(filter) {
        // Update active filter button
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-filter="${filter}"]`).classList.add('active');
        
        // Filter conversations
        let filteredConversations = [...this.conversations];
        
        switch (filter) {
            case 'unread':
                filteredConversations = this.conversations.filter(c => c.hasUnreadMessages);
                break;
            case 'recent':
                const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
                filteredConversations = this.conversations.filter(c => 
                    new Date(c.lastMessageTime) > oneDayAgo
                );
                break;
            case 'all':
            default:
                // Show all conversations
                break;
        }
        
        // Temporarily update conversations and re-render
        const originalConversations = this.conversations;
        this.conversations = filteredConversations;
        this.renderConversationsList();
        this.conversations = originalConversations;
    }

    searchConversations(query) {
        if (!query.trim()) {
            this.renderConversationsList();
            return;
        }
        
        const filteredConversations = this.conversations.filter(conversation => {
            const patientInfo = this.patientAvatars.get(conversation.patientId);
            const patientName = patientInfo?.name || conversation.patientName;
            
            return patientName.toLowerCase().includes(query.toLowerCase()) ||
                   conversation.lastMessage.toLowerCase().includes(query.toLowerCase()) ||
                   conversation.patientId.includes(query);
        });
        
        // Temporarily update conversations and re-render
        const originalConversations = this.conversations;
        this.conversations = filteredConversations;
        this.renderConversationsList();
        this.conversations = originalConversations;
    }

    updateStatistics() {
        const totalConversations = this.conversations.length;
        const unreadConversations = this.conversations.filter(conv => conv.hasUnreadMessages).length;
        const recentConversations = this.conversations.filter(conv => {
            const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
            return new Date(conv.lastMessageTime) > oneDayAgo;
        }).length;
        
        // Update statistics display
        const totalElement = document.getElementById('totalMessages');
        const unreadElement = document.getElementById('unreadMessages');
        const recentElement = document.getElementById('recentMessages');
        
        if (totalElement) totalElement.textContent = totalConversations;
        if (unreadElement) unreadElement.textContent = unreadConversations;
        if (recentElement) recentElement.textContent = recentConversations;
    }

    startRealTimeUpdates() {
        // Update conversations every 30 seconds
        this.updateInterval = setInterval(() => {
            this.loadConversations();
        }, 30000);
    }

    stopRealTimeUpdates() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = null;
        }
    }
}

// Initialize messages page
const messagesPage = new MessagesPage(); 