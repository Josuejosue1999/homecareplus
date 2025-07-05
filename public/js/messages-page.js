/**
 * Professional Messages Page Management
 * Handles chat conversations, message display, and real-time messaging with Socket.IO
 */
class MessagesPage {
    constructor() {
        this.conversations = [];
        this.currentConversation = null;
        this.patientAvatars = new Map(); // Cache for patient avatars
        this.hospitalAvatar = null; // Cache for hospital avatar
        this.currentUser = null;
        this.socket = null;
        this.init();
    }

    init() {
        this.initSocket();
        this.bindEvents();
        this.setupVisibilityHandler();
        this.loadHospitalAvatar();
        this.loadConversations();
    }

    setupVisibilityHandler() {
        // Mark conversations as read when returning to messages page
        document.addEventListener('visibilitychange', () => {
            if (!document.hidden && window.location.pathname.includes('dashboard') && 
                document.querySelector('.messages-container')) {
                console.log('👁️ Messages page became visible - marking conversations as read');
                setTimeout(() => {
                    this.markAllVisibleConversationsAsRead();
                }, 1000); // Small delay to ensure page is fully loaded
            }
        });

        // Also mark as read when navigating to messages page
        window.addEventListener('popstate', () => {
            if (window.location.pathname.includes('dashboard') && 
                document.querySelector('.messages-container')) {
                console.log('🔄 Navigated to messages page - marking conversations as read');
                setTimeout(() => {
                    this.markAllVisibleConversationsAsRead();
                }, 500);
            }
        });

        // Mark as read when the messages page loads initially
        setTimeout(() => {
            if (document.querySelector('.messages-container')) {
                console.log('🏁 Messages page loaded - marking conversations as read');
                this.markAllVisibleConversationsAsRead();
            }
        }, 2000);
    }

    initSocket() {
        console.log('🔌 Initializing Socket.IO connection...');
        this.socket = io();
        
        this.socket.on('connect', () => {
            console.log('✅ Socket.IO connected successfully!');
            console.log('🆔 Socket ID:', this.socket.id);
            console.log('🔗 Socket connected:', this.socket.connected);
            console.log('🌐 Socket transport:', this.socket.io.engine.transport.name);
            
            // Join hospital room for real-time updates
            if (this.currentUser && this.currentUser.uid) {
                console.log('🏥 Joining hospital room:', this.currentUser.uid);
                this.socket.emit('join-hospital', this.currentUser.uid);
            }
        });

        this.socket.on('new-message', (data) => {
            console.log('📨 New message received via Socket.IO:', data);
            this.handleNewMessage(data);
        });

        this.socket.on('conversation-updated', (data) => {
            console.log('🔄 Conversation updated via Socket.IO:', data);
            this.handleConversationUpdate(data);
        });

        this.socket.on('conversation-deleted', (data) => {
            console.log('🗑️ Conversation deleted via Socket.IO:', data);
            this.handleConversationDeleted(data);
        });

        this.socket.on('disconnect', (reason) => {
            console.log('🔌 Socket disconnected:', reason);
            console.log('🔗 Socket connected:', this.socket.connected);
        });
        
        this.socket.on('connect_error', (error) => {
            console.error('❌ Socket connection error:', error);
        });
        
        this.socket.on('error', (error) => {
            console.error('❌ Socket error:', error);
        });
        
        // Log all socket events for debugging
        this.socket.onAny((event, ...args) => {
            console.log(`🔊 Socket event "${event}":`, args);
        });
    }

    bindEvents() {
        // Filter buttons
        document.querySelectorAll('[data-filter]').forEach(button => {
            button.addEventListener('click', (e) => {
                this.setActiveFilter(e.target.dataset.filter);
            });
        });

        // Search functionality
        const searchInput = document.getElementById('searchConversations');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.filterConversations(e.target.value);
            });
        }
    }

    setActiveFilter(filter) {
        this.currentFilter = filter;
        
        // Update button states
        document.querySelectorAll('[data-filter]').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-filter="${filter}"]`).classList.add('active');
        
        // Filter and display conversations
        this.filterAndDisplayConversations();
    }

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
    }

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

    async loadConversations() {
        this.showLoadingState();
        
        try {
            const response = await fetch('/api/chat/conversations');
            const data = await response.json();
            
            if (data.success) {
                this.conversations = data.conversations;
                
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
    }

    filterConversations(searchTerm) {
        const filteredConversations = this.conversations.filter(conv => 
            conv.patientName.toLowerCase().includes(searchTerm.toLowerCase()) ||
            conv.lastMessage.toLowerCase().includes(searchTerm.toLowerCase())
        );
        this.displayConversations(filteredConversations);
    }

    filterAndDisplayConversations() {
        let filteredConversations = this.conversations;
        
        switch (this.currentFilter) {
            case 'unread':
                filteredConversations = this.conversations.filter(conv => conv.hasUnreadMessages);
                break;
            case 'urgent':
                filteredConversations = this.conversations.filter(conv => 
                    conv.lastMessage && conv.lastMessage.includes('New Appointment Request')
                );
                break;
            case 'all':
            default:
                filteredConversations = this.conversations;
                break;
        }
        
        this.displayConversations(filteredConversations);
    }

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
    }

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
                        <button class="btn btn-sm btn-outline-danger" onclick="messagesPage.deleteConversation('${conversation.id}')" title="Delete Conversation">
                            <i class="fas fa-trash"></i>
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
                    <p class="conversation-preview">${this.truncateText(conversation.lastMessage, 80)}</p>
                </div>
            </div>
        `;
    }

    renderPatientAvatar(avatarUrl, patientName) {
        if (avatarUrl && avatarUrl.trim() !== '') {
            if (avatarUrl.startsWith('data:image') || avatarUrl.startsWith('http')) {
                return `<img src="${avatarUrl}" class="patient-avatar" alt="${patientName}">`;
            }
        }
        
        // Fallback to initials
        return `
            <div class="patient-avatar-initials">
                ${this.getPatientInitials(patientName)}
            </div>
        `;
    }

    getPatientInitials(name) {
        if (!name) return '?';
        const words = name.trim().split(' ');
        if (words.length >= 2) {
            return (words[0][0] + words[1][0]).toUpperCase();
        }
        return name[0].toUpperCase();
    }

    truncateText(text, maxLength) {
        if (!text) return '';
        return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
    }

    formatTime(timestamp) {
        if (!timestamp) return '';
        
        const date = timestamp instanceof Date ? timestamp : new Date(timestamp);
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

    addConversationEventListeners() {
        // Click to open conversation
        document.querySelectorAll('.conversation-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (!e.target.closest('.conversation-actions')) {
                    const conversationId = card.dataset.conversationId;
                    this.openConversation(conversationId);
                }
            });
        });
    }

    async openConversation(conversationId) {
        try {
            const response = await fetch(`/api/chat/conversations/${conversationId}/messages`);
            const data = await response.json();
            
            if (data.success) {
                this.currentConversation = data.conversation;
                this.showConversationModal(data.messages, data.conversation);
                
                // Mark conversation as read
                await this.markConversationAsRead(conversationId);
                
                // Join conversation room for real-time updates
                this.socket.emit('join-conversation', conversationId);
            } else {
                this.showToast('Error loading conversation', 'error');
            }
        } catch (error) {
            console.error('Error opening conversation:', error);
            this.showToast('Error loading conversation', 'error');
        }
    }

    async markConversationAsRead(conversationId) {
        try {
            console.log(`📖 Marking conversation ${conversationId} as read`);
            
            await fetch(`/api/chat/conversations/${conversationId}/mark-read`, {
                method: 'POST'
            });
            
            // Update local conversation state
            const conversation = this.conversations.find(c => c.id === conversationId);
            if (conversation) {
                conversation.hasUnreadMessages = false;
                conversation.unreadCount = 0;
                this.updateStatistics();
                this.filterAndDisplayConversations();
                console.log(`✅ Conversation ${conversationId} marked as read locally`);
                
                // Update global notification system
                if (window.chatNotifications) {
                    window.chatNotifications.markConversationAsRead(conversationId);
                }
            }
        } catch (error) {
            console.error('Error marking conversation as read:', error);
        }
    }

    async markAllVisibleConversationsAsRead() {
        try {
            console.log('📖 Marking all visible conversations as read...');
            
            const unreadConversations = this.conversations.filter(c => c.hasUnreadMessages);
            
            if (unreadConversations.length === 0) {
                console.log('✅ No unread conversations to mark');
                return;
            }
            
            console.log(`📖 Found ${unreadConversations.length} unread conversations to mark as read`);
            
            const promises = unreadConversations.map(conversation => 
                this.markConversationAsRead(conversation.id)
            );
            
            await Promise.all(promises);
            console.log(`✅ Marked ${unreadConversations.length} conversations as read`);
            
        } catch (error) {
            console.error('Error marking conversations as read:', error);
            }
        }

    async deleteConversation(conversationId) {
        const result = await Swal.fire({
            title: 'Delete Conversation?',
            text: 'This will permanently delete the conversation and all messages. This action cannot be undone.',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#dc3545',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Yes, Delete',
            cancelButtonText: 'Cancel'
        });
        
        if (result.isConfirmed) {
            try {
                const response = await fetch(`/api/chat/conversations/${conversationId}`, {
                    method: 'DELETE'
                });
                
                const data = await response.json();
                
                if (data.success) {
                    // Remove from local array
                    this.conversations = this.conversations.filter(c => c.id !== conversationId);
                    this.filterAndDisplayConversations();
                    this.updateStatistics();
                    
                    this.showToast('Conversation deleted successfully', 'success');
                    
                    // Close modal if this conversation is currently open
                    if (this.currentConversation && this.currentConversation.id === conversationId) {
                        const modal = bootstrap.Modal.getInstance(document.getElementById('chatModal'));
                        if (modal) {
                            modal.hide();
                        }
                    }
                } else {
                    this.showToast('Failed to delete conversation', 'error');
                }
            } catch (error) {
                console.error('Error deleting conversation:', error);
                this.showToast('Error deleting conversation', 'error');
                }
        }
    }

    showConversationModal(messages, conversation) {
        const modal = document.getElementById('chatModal');
        const modalTitle = document.getElementById('chatModalLabel');
        const chatMessages = document.getElementById('chatMessages');
        
        // Update modal title
        modalTitle.innerHTML = `
            <i class="fas fa-comments me-2"></i>
            <span id="chatPatientName">${conversation.patientName}</span>
        `;
        
        // Render messages
        this.renderChatMessages(chatMessages, messages);
        
        // Show modal
        const bsModal = new bootstrap.Modal(modal);
        bsModal.show();
        
        // Bind send message event
        this.bindSendMessageEvent(conversation.id);
        
        // Scroll to bottom
        setTimeout(() => {
            chatMessages.scrollTop = chatMessages.scrollHeight;
        }, 100);
    }

    renderChatMessages(container, messages) {
        if (!messages || messages.length === 0) {
            container.innerHTML = `
                <div class="empty-chat">
                    <i class="fas fa-comments fa-3x text-muted mb-3"></i>
                    <p>No messages yet. Start the conversation!</p>
                </div>
            `;
            return;
        }

        const messagesHtml = messages.map(message => {
            const isFromClinic = message.senderType === 'clinic' || message.senderType === 'hospital';
            const messageClass = isFromClinic ? 'clinic-message' : 'patient-message';
            const justifyClass = isFromClinic ? 'justify-content-end' : 'justify-content-start';
        
            // Avatar HTML
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
                
                let patientAvatarUrl = null;
                if (patientInfo?.avatar) {
                    patientAvatarUrl = patientInfo.avatar;
                } else if (message.patientAvatar) {
                    patientAvatarUrl = message.patientAvatar;
                } else if (message.senderProfileImage) {
                    patientAvatarUrl = message.senderProfileImage;
                } else if (this.currentConversation?.patientAvatar) {
                    patientAvatarUrl = this.currentConversation.patientAvatar;
                }

                console.log('🖼️ Patient avatar URL:', patientAvatarUrl);
                
                if (patientAvatarUrl && (patientAvatarUrl.startsWith('data:image') || patientAvatarUrl.startsWith('http'))) {
                    avatarHtml = `<img src="${patientAvatarUrl}" class="message-avatar-img" alt="Patient" 
                                  onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                                  <div class="message-avatar-placeholder patient" style="display: none;">
                                      ${this.getPatientInitials(message.senderName || this.currentConversation?.patientName || 'Patient')}
                                  </div>`;
            } else {
                    const initials = this.getPatientInitials(message.senderName || this.currentConversation?.patientName || 'Patient');
                    avatarHtml = `<div class="message-avatar-placeholder patient">${initials}</div>`;
            }
        }
        
        return `
                <div class="chat-message-wrapper ${messageClass} ${justifyClass}">
                    <div class="message-avatar">
                        ${avatarHtml}
                    </div>
                    <div class="chat-message">
                    <div class="message-bubble">
                        <div class="message-header">
                                <span class="message-sender">${message.senderName}</span>
                                <span class="message-time">${this.formatMessageTime(message.timestamp)}</span>
                            </div>
                            <div class="message-text">${this.formatMessageText(message.message)}</div>
                            ${message.metadata ? this.renderMessageMetadata(message.metadata) : ''}
                        </div>
                    </div>
            </div>
        `;
        }).join('');

        container.innerHTML = messagesHtml;
    }

    formatMessageTime(timestamp) {
        if (!timestamp) return '';
        const date = timestamp instanceof Date ? timestamp : new Date(timestamp);
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }

    formatMessageText(text) {
        if (!text) return '';
        // Convert line breaks to HTML
        return text.replace(/\n/g, '<br>');
    }

    renderMessageMetadata(metadata) {
        if (!metadata) return '';
        
        // Handle appointment request metadata
        if (metadata.action === 'appointment_request') {
            const status = metadata.status || 'pending';
            const statusClass = status === 'pending' ? 'warning' : status === 'approved' ? 'success' : 'danger';
            
            return `
                <div class="message-metadata appointment-request">
                    <div class="metadata-content">
                        <i class="fas fa-calendar-plus text-primary me-2"></i>
                        <span class="metadata-text">Appointment Request</span>
                        <span class="badge bg-${statusClass} ms-2">${status.charAt(0).toUpperCase() + status.slice(1)}</span>
                    </div>
                </div>
            `;
        }
        
        // Handle other metadata types if needed
        return '';
    }

    bindSendMessageEvent(conversationId) {
        const sendBtn = document.getElementById('sendMessageBtn');
        const messageInput = document.getElementById('chatMessageInput');
        
        // Remove existing listeners
        sendBtn.replaceWith(sendBtn.cloneNode(true));
        messageInput.replaceWith(messageInput.cloneNode(true));
        
        // Get new references
        const newSendBtn = document.getElementById('sendMessageBtn');
        const newMessageInput = document.getElementById('chatMessageInput');
        
        const sendMessage = () => this.sendMessage(conversationId);
        
        newSendBtn.addEventListener('click', sendMessage);
        newMessageInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });
    }

    async sendMessage(conversationId) {
        const messageInput = document.getElementById('chatMessageInput');
        const message = messageInput.value.trim();
        
        if (!message) return;
        
        try {
            console.log('🔄 Sending message to conversation:', conversationId);
            console.log('📝 Message content:', message);

            const response = await fetch(`/api/chat/conversations/${conversationId}/messages`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    message,
                    messageType: 'text'
                })
            });
            
            const data = await response.json();
            console.log('📥 Server response:', data);
            
            if (data.success) {
                messageInput.value = '';
                
                // Emit via Socket.IO for real-time updates
                this.socket.emit('send-message', {
                    conversationId,
                    message,
                    senderId: this.currentUser?.uid,
                    senderName: this.currentUser?.displayName || 'Hospital',
                    senderType: 'clinic'
                });
                
                // Update global notification system
                if (window.chatNotifications) {
                    window.chatNotifications.handleClinicMessage(conversationId);
                }
                
                // Reload messages to show the new message
                this.reloadCurrentConversation();
                
                this.showToast('Message sent successfully', 'success');
            } else {
                console.error('❌ Failed to send message:', data.message);
                this.showToast(`Failed to send message: ${data.message}`, 'error');
            }
        } catch (error) {
            console.error('❌ Error sending message:', error);
            this.showToast('Error sending message', 'error');
        }
    }

    async reloadCurrentConversation() {
        if (!this.currentConversation) return;
        
        try {
            const response = await fetch(`/api/chat/conversations/${this.currentConversation.id}/messages`);
            const data = await response.json();
            
            if (data.success) {
                const chatMessages = document.getElementById('chatMessages');
                this.renderChatMessages(chatMessages, data.messages);
                
                // Scroll to bottom
                setTimeout(() => {
                    chatMessages.scrollTop = chatMessages.scrollHeight;
                }, 100);
            }
        } catch (error) {
            console.error('Error reloading conversation:', error);
        }
    }

    // Socket event handlers
    handleNewMessage(data) {
        // If the message is for the currently open conversation, update it
        if (this.currentConversation && this.currentConversation.id === data.conversationId) {
            this.reloadCurrentConversation();
        }
        
        // Update global notification system
        if (window.chatNotifications && data.senderType === 'patient') {
            window.chatNotifications.handleNewMessage(data.conversationId, data.senderType);
        }
        
        // Update the conversations list
        this.loadConversations();
    }

    handleConversationUpdate(data) {
        // Reload conversations to reflect updates
        this.loadConversations();
    }

    handleConversationDeleted(data) {
        // Remove from local array
        this.conversations = this.conversations.filter(c => c.id !== data.conversationId);
        this.filterAndDisplayConversations();
        this.updateStatistics();
        
        // Close modal if this conversation is currently open
        if (this.currentConversation && this.currentConversation.id === data.conversationId) {
            const modal = bootstrap.Modal.getInstance(document.getElementById('chatModal'));
            if (modal) {
                modal.hide();
            }
        }
    }

    async approveAppointment(conversationId) {
        // Implementation for appointment approval
        this.showToast('Appointment approval feature coming soon', 'info');
    }

    async rejectAppointment(conversationId) {
        // Implementation for appointment rejection
        this.showToast('Appointment rejection feature coming soon', 'info');
        }

    updateStatistics() {
        const totalConversations = this.conversations.length;
        const unreadConversations = this.conversations.filter(c => c.hasUnreadMessages).length;
        const urgentConversations = this.conversations.filter(c => 
            c.lastMessage && c.lastMessage.includes('New Appointment Request')
        ).length;
        
        // Update stat cards if they exist
        const totalStat = document.querySelector('[data-stat="total"]');
        const unreadStat = document.querySelector('[data-stat="unread"]');
        const urgentStat = document.querySelector('[data-stat="urgent"]');
        
        if (totalStat) totalStat.textContent = totalConversations;
        if (unreadStat) unreadStat.textContent = unreadConversations;
        if (urgentStat) urgentStat.textContent = urgentConversations;
    }

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
    }

    showErrorState(message) {
        const container = document.getElementById('messagesList');
        container.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-exclamation-triangle fa-3x text-danger mb-3"></i>
                <h5>Error</h5>
                <p class="text-muted">${message}</p>
                <button class="btn btn-primary" onclick="messagesPage.loadConversations()">
                    <i class="fas fa-refresh"></i> Retry
                </button>
            </div>
        `;
    }

    showToast(message, type = 'info') {
        // Simple toast notification
        const toast = document.createElement('div');
        toast.className = `alert alert-${type === 'error' ? 'danger' : type} alert-dismissible fade show position-fixed`;
        toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
        toast.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        document.body.appendChild(toast);
        
        // Auto remove after 3 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
        }
        }, 3000);
    }

    refresh() {
        this.loadConversations();
    }
}

// Initialize the messages page
const messagesPage = new MessagesPage(); 