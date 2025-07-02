// Messages Page Module
const messagesPage = {
    currentFilter: 'all',
    allConversations: [],
    currentUser: null,
    currentConversation: null,
    refreshInterval: null,

    init() {
        this.bindEvents();
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

    async loadConversations() {
        this.showLoadingState();
        
        try {
            const response = await fetch('/api/chat/conversations');
            const data = await response.json();
            
            if (data.success) {
                this.allConversations = data.conversations;
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
        
        return `
            <div class="conversation-card ${unreadClass} ${urgentClass}" data-conversation-id="${conversation.id}">
                <div class="conversation-header">
                    <div class="conversation-info">
                        <div class="conversation-participant">
                            <div class="participant-avatar">
                                <i class="fas fa-user-circle fa-2x text-primary"></i>
                            </div>
                            <div class="participant-details">
                                <strong>${conversation.patientName}</strong>
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
        const modal = document.createElement('div');
        modal.className = 'modal fade';
        modal.id = 'conversationModal';
        modal.innerHTML = `
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-comments text-primary me-2"></i>
                            Chat with ${conversation.patientName}
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="chat-messages" id="chatMessages" style="height: 400px; overflow-y: auto;">
                            ${messages.map(message => this.createMessageBubble(message)).join('')}
                        </div>
                        <div class="chat-input mt-3">
                            <div class="input-group">
                                <textarea class="form-control" id="messageInput" placeholder="Type your message..." rows="2"></textarea>
                                <button class="btn btn-primary" onclick="messagesPage.sendMessage('${conversation.id}')">
                                    <i class="fas fa-paper-plane"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        
        const modalInstance = new bootstrap.Modal(modal);
        modalInstance.show();
        
        // Scroll to bottom of messages
        const chatMessages = modal.querySelector('#chatMessages');
        chatMessages.scrollTop = chatMessages.scrollHeight;
        
        // Handle modal close
        modal.addEventListener('hidden.bs.modal', () => {
            document.body.removeChild(modal);
            this.currentConversation = null;
        });
    },

    createMessageBubble(message) {
        const isClinic = message.senderType === 'clinic';
        const messageClass = isClinic ? 'message-outgoing' : 'message-incoming';
        const senderName = isClinic ? 'You' : message.senderName;
        
        return `
            <div class="message-bubble ${messageClass} mb-2">
                <div class="message-header">
                    <small class="text-muted">${senderName} • ${this.formatTime(message.timestamp)}</small>
                </div>
                <div class="message-content">
                    ${this.formatMessageContent(message)}
                </div>
            </div>
        `;
    },

    formatMessageContent(message) {
        if (message.messageType === 'system' || message.messageType === 'appointmentConfirmation' || message.messageType === 'appointmentCancellation') {
            return `<div class="system-message">${message.message.replace(/\n/g, '<br>')}</div>`;
        }
        return message.message.replace(/\n/g, '<br>');
    },

    async sendMessage(conversationId) {
        const messageInput = document.getElementById('messageInput');
        const message = messageInput.value.trim();
        
        if (!message) return;
        
        try {
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