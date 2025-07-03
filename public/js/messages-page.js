// Messages Page Module
const messagesPage = {
    currentFilter: 'all',
    allConversations: [],
    currentUser: null,
    currentConversation: null,
    refreshInterval: null,
    patientAvatars: new Map(), // Cache for patient avatars
    hospitalAvatar: null, // Cache for hospital avatar

    init() {
        this.bindEvents();
        this.loadHospitalAvatar();
        this.loadConversations();
        this.startRealTimeUpdates();
    },

    bindEvents() {
        // Filter buttons
        document.querySelectorAll('[data-filter]').forEach(button => {
            button.addEventListener('click', (e) => {
                this.setActiveFilter(e.target.dataset.filter);
            });
        });
    },

    setActiveFilter(filter) {
        this.currentFilter = filter;
        
        // Update button states
        document.querySelectorAll('[data-filter]').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-filter="${filter}"]`).classList.add('active');
        
        // Filter and display conversations
        this.filterAndDisplayConversations();
    },

    async loadHospitalAvatar() {
        try {
            const response = await fetch('/api/settings/hospital-image');
            if (response.ok) {
                const data = await response.json();
                if (data.success && data.imageUrl) {
                    this.hospitalAvatar = data.imageUrl;
                    console.log('✅ Hospital avatar loaded');
                }
            }
        } catch (error) {
            console.error('❌ Error loading hospital avatar:', error);
        }
    },

    async loadPatientAvatars() {
        const promises = this.allConversations.map(async (conversation) => {
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
    },

    async loadConversations() {
        this.showLoadingState();
        
        try {
            const response = await fetch('/api/chat/conversations');
            const data = await response.json();
            
            if (data.success) {
                this.allConversations = data.conversations;
                
                await this.loadPatientAvatars();
                
                this.filterAndDisplayConversations();
                this.updateStatistics();
            } else {
                console.error('Failed to load conversations:', data.message);
                this.showErrorState('Failed to load conversations');
            }
        } catch (error) {
            console.error('Error loading conversations:', error);
            this.showErrorState('Error loading conversations');
        }
    },

    filterAndDisplayConversations() {
        let filteredConversations = this.allConversations;
        
        switch (this.currentFilter) {
            case 'unread':
                filteredConversations = this.allConversations.filter(conv => conv.hasUnreadMessages);
                break;
            case 'urgent':
                // Filter conversations with appointment requests
                filteredConversations = this.allConversations.filter(conv => 
                    conv.lastMessage && conv.lastMessage.includes('New Appointment Request')
                );
                break;
            case 'all':
            default:
                filteredConversations = this.allConversations;
                break;
        }
        
        this.displayConversations(filteredConversations);
    },

    displayConversations(conversations) {
        const container = document.getElementById('messagesList');
        
        if (conversations.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-comments fa-3x text-muted mb-3"></i>
                    <h5>No conversations found</h5>
                    <p class="text-muted">No conversations match your current filter.</p>
                </div>
            `;
            return;
        }
        
        const conversationsHTML = conversations.map(conversation => this.createConversationCard(conversation)).join('');
        container.innerHTML = `
            <div class="conversations-grid">
                ${conversationsHTML}
            </div>
        `;
        
        // Add event listeners to conversation cards
        this.addConversationEventListeners();
    },

    createConversationCard(conversation) {
        const unreadClass = conversation.hasUnreadMessages ? 'unread' : '';
        const urgentClass = conversation.lastMessage && conversation.lastMessage.includes('New Appointment Request') ? 'urgent' : '';
        
        // Get patient avatar from cache
        const patientInfo = this.patientAvatars.get(conversation.patientId);
        const patientAvatar = patientInfo?.avatar;
        const patientName = patientInfo?.name || conversation.patientName;
        
        return `
            <div class="conversation-card ${unreadClass} ${urgentClass}" data-conversation-id="${conversation.id}">
                <div class="conversation-header">
                    <div class="conversation-info">
                        <div class="conversation-participant">
                            <div class="participant-avatar">
                                ${this.renderPatientAvatar(patientAvatar, patientName)}
                            </div>
                            <div class="participant-details">
                                <strong>${patientName}</strong>
                                <span class="conversation-time">${this.formatTime(conversation.lastMessageTime)}</span>
                            </div>
                        </div>
                        <div class="conversation-meta">
                            ${conversation.hasUnreadMessages ? `<span class="badge bg-warning">${conversation.unreadCount}</span>` : ''}
                            ${urgentClass ? '<span class="badge bg-danger">Urgent</span>' : ''}
                        </div>
                    </div>
                    <div class="conversation-actions">
                        <button class="btn btn-sm btn-outline-primary" onclick="messagesPage.openConversation('${conversation.id}')">
                            <i class="fas fa-comments"></i> Chat
                        </button>
                        ${urgentClass ? `
                            <button class="btn btn-sm btn-success" onclick="messagesPage.approveAppointment('${conversation.id}')">
                                <i class="fas fa-check"></i> Approve
                            </button>
                            <button class="btn btn-sm btn-danger" onclick="messagesPage.rejectAppointment('${conversation.id}')">
                                <i class="fas fa-times"></i> Reject
                            </button>
                        ` : ''}
                    </div>
                </div>
                <div class="conversation-content">
                    <p class="conversation-preview">${this.truncateText(conversation.lastMessage, 100)}</p>
                </div>
            </div>
        `;
    },

    renderPatientAvatar(avatarUrl, patientName) {
        if (avatarUrl && avatarUrl.trim() !== '') {
            if (avatarUrl.startsWith('data:image') || avatarUrl.startsWith('http')) {
                // Valid image URL
                return `<img src="${avatarUrl}" alt="${patientName}" class="patient-avatar" onerror="this.parentNode.innerHTML=this.parentNode.dataset.fallback">`;
            }
        }
        
        // Fallback to initials
        const initials = this.getPatientInitials(patientName);
        return `
            <div class="patient-avatar-initials" data-fallback="${initials}">
                ${initials}
            </div>
        `;
    },

    formatTime(timestamp) {
        const now = new Date();
        const diff = now - new Date(timestamp);
        const hours = Math.floor(diff / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        
        if (hours > 24) {
            const days = Math.floor(hours / 24);
            return `${days} day${days > 1 ? 's' : ''} ago`;
        } else if (hours > 0) {
            return `${hours}h ago`;
        } else if (minutes > 0) {
            return `${minutes}m ago`;
        } else {
            return 'Just now';
        }
    },

    truncateText(text, maxLength) {
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength) + '...';
    },

    addConversationEventListeners() {
        document.querySelectorAll('.conversation-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (!e.target.closest('.conversation-actions')) {
                    const conversationId = card.dataset.conversationId;
                    this.openConversation(conversationId);
                }
            });
        });
    },

    async openConversation(conversationId) {
        try {
            const response = await fetch(`/api/chat/conversations/${conversationId}/messages`);
            const data = await response.json();
            
            if (data.success) {
                this.currentConversation = data.conversation;
                this.showConversationModal(data.messages, data.conversation);
            } else {
                console.error('Failed to load messages:', data.message);
                alert('Failed to load messages');
            }
        } catch (error) {
            console.error('Error loading messages:', error);
            alert('Error loading messages');
        }
    },

    showConversationModal(messages, conversation) {
        // Use the static modal from HTML
        const modal = document.getElementById('chatModal');
        if (!modal) {
            console.error('Chat modal not found in DOM');
            return;
        }

        // Update modal title with patient info
        const patientNameSpan = modal.querySelector('#chatPatientName');
        if (patientNameSpan) {
            patientNameSpan.textContent = `Chat with ${conversation.patientName}`;
        }

        // Update messages content
        const chatMessages = modal.querySelector('#chatMessages');
        if (chatMessages) {
            if (messages.length === 0) {
                chatMessages.innerHTML = `
                    <div class="empty-chat">
                        <i class="fas fa-comments text-muted"></i>
                        <p class="text-muted mt-2">No messages yet. Start the conversation!</p>
                    </div>
                `;
            } else {
                chatMessages.innerHTML = messages.map(message => this.createMessageBubble(message)).join('');
                
                // Auto-scroll to bottom
                setTimeout(() => {
                    chatMessages.scrollTop = chatMessages.scrollHeight;
                }, 100);
            }
        }

        // Setup event listeners for send button and input
        const sendBtn = modal.querySelector('#sendMessageBtn');
        const messageInput = modal.querySelector('#chatMessageInput');
        
        if (sendBtn && !sendBtn.hasAttribute('data-listener-added')) {
            sendBtn.addEventListener('click', () => this.sendMessage(conversation.id));
            sendBtn.setAttribute('data-listener-added', 'true');
        }
        
        if (messageInput && !messageInput.hasAttribute('data-listener-added')) {
            messageInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    this.sendMessage(conversation.id);
                }
            });
            messageInput.setAttribute('data-listener-added', 'true');
        }

        // Show the modal
        const modalInstance = new bootstrap.Modal(modal);
        modalInstance.show();
        
        // Handle modal close
        modal.addEventListener('hidden.bs.modal', () => {
            this.currentConversation = null;
            // Clear input
            if (messageInput) {
                messageInput.value = '';
            }
        }, { once: true });
    },

    createMessageBubble(message) {
        const isFromClinic = message.senderType === 'clinic';
        const messageTime = new Date(message.timestamp).toLocaleString();
        const alignment = isFromClinic ? 'justify-content-end' : 'justify-content-start';
        const bubbleClass = isFromClinic ? 'clinic-message' : 'patient-message';
        
        // Get avatar
        let avatar = '';
        if (isFromClinic) {
            // Hospital avatar - use the actual hospital image from message or cached avatar
            if (message.hospitalImage) {
                avatar = `<img src="${message.hospitalImage}" class="message-avatar-img" alt="Hospital">`;
            } else if (this.hospitalAvatar) {
                avatar = `<img src="${this.hospitalAvatar}" class="message-avatar-img" alt="Hospital">`;
            } else {
                avatar = `<div class="message-avatar-placeholder hospital"><i class="fas fa-hospital"></i></div>`;
            }
        } else {
            // Patient avatar - try multiple ways to get the patient avatar
            let patientAvatar = null;
            
            // First, try to get from message directly
            if (message.patientImage) {
                patientAvatar = message.patientImage;
            } else if (this.currentConversation && this.patientAvatars.has(this.currentConversation.patientId)) {
                // Then try to get from cached avatars using conversation patientId
                const patientInfo = this.patientAvatars.get(this.currentConversation.patientId);
                patientAvatar = patientInfo?.avatar;
            }
            
            if (patientAvatar) {
                avatar = `<img src="${patientAvatar}" class="message-avatar-img" alt="Patient">`;
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
    },

    getPatientInitials(name) {
        if (!name) return 'P';
        const names = name.split(' ');
        if (names.length >= 2) {
            return (names[0][0] + names[1][0]).toUpperCase();
        }
        return name[0].toUpperCase();
    },

    formatMessageText(text) {
        // Convert markdown-style formatting to HTML
        return text
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>')
            .replace(/\n/g, '<br>');
    },

    async sendMessage(conversationId) {
        const messageInput = document.getElementById('chatMessageInput');
        const message = messageInput.value.trim();
        
        if (!message) return;
        
        try {
            // Disable input while sending
            messageInput.disabled = true;
            document.getElementById('sendMessageBtn').disabled = true;

            const response = await fetch(`/api/chat/conversations/${conversationId}/messages`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ message })
            });
            
            const data = await response.json();
            
            if (data.success) {
                messageInput.value = '';
                // Refresh the conversation
                this.openConversation(conversationId);
            } else {
                alert('Failed to send message');
            }
        } catch (error) {
            console.error('Error sending message:', error);
            alert('Error sending message');
        } finally {
            // Re-enable input
            messageInput.disabled = false;
            document.getElementById('sendMessageBtn').disabled = false;
            messageInput.focus();
        }
    },

    async approveAppointment(conversationId) {
        try {
            // Find the appointment ID from the conversation
            const conversation = this.allConversations.find(c => c.id === conversationId);
            if (!conversation) return;
            
            // For now, we'll need to get the appointment ID from the conversation
            // This is a simplified version - in a real implementation, you'd need to
            // store the appointment ID in the conversation metadata
            
            const response = await fetch(`/api/chat/appointments/${conversationId}/approve`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                }
            });
            
            const data = await response.json();
            
            if (data.success) {
                alert('Appointment approved successfully');
                this.loadConversations(); // Refresh the list
            } else {
                alert('Failed to approve appointment');
            }
        } catch (error) {
            console.error('Error approving appointment:', error);
            alert('Error approving appointment');
        }
    },

    async rejectAppointment(conversationId) {
        const reason = prompt('Please provide a reason for rejection:');
        if (!reason) return;
        
        try {
            const response = await fetch(`/api/chat/appointments/${conversationId}/reject`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ reason })
            });
            
            const data = await response.json();
            
            if (data.success) {
                alert('Appointment rejected successfully');
                this.loadConversations(); // Refresh the list
            } else {
                alert('Failed to reject appointment');
            }
        } catch (error) {
            console.error('Error rejecting appointment:', error);
            alert('Error rejecting appointment');
        }
    },

    updateStatistics() {
        const totalConversations = this.allConversations.length;
        const unreadConversations = this.allConversations.filter(conv => conv.hasUnreadMessages).length;
        const urgentConversations = this.allConversations.filter(conv => 
            conv.lastMessage && conv.lastMessage.includes('New Appointment Request')
        ).length;
        
        document.getElementById('totalMessages').textContent = totalConversations;
        document.getElementById('unreadMessages').textContent = unreadConversations;
        document.getElementById('pendingReplies').textContent = urgentConversations;
    },

    showLoadingState() {
        const container = document.getElementById('messagesList');
        container.innerHTML = `
            <div class="loading-state">
                <div class="spinner-container">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">Loading...</span>
                    </div>
                </div>
                <p class="loading-text">Loading conversations...</p>
            </div>
        `;
    },

    showErrorState(message) {
        const container = document.getElementById('messagesList');
        container.innerHTML = `
            <div class="error-state">
                <i class="fas fa-exclamation-triangle fa-3x text-danger mb-3"></i>
                <h5>Error</h5>
                <p class="text-muted">${message}</p>
                <button class="btn btn-primary" onclick="messagesPage.loadConversations()">
                    <i class="fas fa-refresh me-2"></i>Retry
                </button>
            </div>
        `;
    },

    startRealTimeUpdates() {
        // Refresh conversations every 30 seconds
        this.refreshInterval = setInterval(() => {
            this.loadConversations();
        }, 30000);
    },

    stopRealTimeUpdates() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
        }
    },

    refresh() {
        this.loadConversations();
    },

    composeNewMessage() {
        // This would open a modal to compose a new message
        alert('New message feature coming soon!');
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    messagesPage.init();
}); 