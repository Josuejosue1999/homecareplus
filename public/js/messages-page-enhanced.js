// Enhanced Messages Page Module with Professional Features
const messagesPageEnhanced = {
    currentFilter: 'all',
    allConversations: [],
    currentUser: null,
    currentConversation: null,
    refreshInterval: null,
    patientAvatars: new Map(),
    hospitalAvatar: null,
    typingTimeout: null,
    searchQuery: '',
    sortBy: 'time', // 'time', 'name', 'unread'
    
    init() {
        this.bindEvents();
        this.loadHospitalAvatar();
        this.loadConversations();
        this.startRealTimeUpdates();
        this.initKeyboardShortcuts();
        this.initSearchFunctionality();
    },

    bindEvents() {
        // Filter buttons
        document.querySelectorAll('[data-filter]').forEach(button => {
            button.addEventListener('click', (e) => {
                this.setActiveFilter(e.target.dataset.filter);
            });
        });

        // Message input events for better UX
        const messageInput = document.getElementById('chatMessageInput');
        if (messageInput) {
            messageInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    this.sendMessage(this.currentConversation?.id);
                }
            });

            messageInput.addEventListener('input', () => {
                this.handleTypingIndicator();
            });
        }
    },

    initKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Ctrl/Cmd + / for search
            if ((e.ctrlKey || e.metaKey) && e.key === '/') {
                e.preventDefault();
                this.focusSearch();
            }
            
            // Escape to close modal
            if (e.key === 'Escape') {
                const modal = document.getElementById('chatModal');
                if (modal && modal.classList.contains('show')) {
                    const bootstrapModal = bootstrap.Modal.getInstance(modal);
                    bootstrapModal?.hide();
                }
            }
        });
    },

    initSearchFunctionality() {
        const searchContainer = document.querySelector('.messages-header .header-actions');
        if (searchContainer && !document.getElementById('messageSearch')) {
            const searchHTML = `
                <div class="search-container me-3">
                    <div class="input-group">
                        <span class="input-group-text">
                            <i class="fas fa-search"></i>
                        </span>
                        <input type="text" 
                               class="form-control" 
                               id="messageSearch" 
                               placeholder="Search conversations..."
                               maxlength="100">
                    </div>
                </div>
            `;
            searchContainer.insertAdjacentHTML('afterbegin', searchHTML);
            
            const searchInput = document.getElementById('messageSearch');
            searchInput.addEventListener('input', (e) => {
                this.searchQuery = e.target.value.toLowerCase().trim();
                this.filterAndDisplayConversations();
            });
        }
    },

    focusSearch() {
        const searchInput = document.getElementById('messageSearch');
        if (searchInput) {
            searchInput.focus();
        }
    },

    setActiveFilter(filter) {
        this.currentFilter = filter;
        
        // Update button states with enhanced animation
        document.querySelectorAll('[data-filter]').forEach(btn => {
            btn.classList.remove('active');
        });
        
        const activeBtn = document.querySelector(`[data-filter="${filter}"]`);
        if (activeBtn) {
            activeBtn.classList.add('active');
            
            // Add a subtle pulse effect
            activeBtn.style.animation = 'pulse 0.3s ease-out';
            setTimeout(() => {
                activeBtn.style.animation = '';
            }, 300);
        }
        
        this.filterAndDisplayConversations();
    },

    async loadHospitalAvatar() {
        try {
            const response = await fetch('/api/settings/hospital-image');
            if (response.ok) {
                const data = await response.json();
                if (data.success && data.imageUrl) {
                    this.hospitalAvatar = data.imageUrl;
                    console.log('✅ Hospital avatar loaded for enhanced chat');
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
                this.showSuccessToast('Conversations loaded successfully');
            } else {
                console.error('Failed to load conversations:', data.message);
                this.showErrorState('Failed to load conversations');
                this.showErrorToast('Failed to load conversations');
            }
        } catch (error) {
            console.error('Error loading conversations:', error);
            this.showErrorState('Error loading conversations');
            this.showErrorToast('Error loading conversations');
        }
    },

    filterAndDisplayConversations() {
        let filteredConversations = this.allConversations;
        
        // Apply filter
        switch (this.currentFilter) {
            case 'unread':
                filteredConversations = filteredConversations.filter(conv => conv.hasUnreadMessages);
                break;
            case 'urgent':
                filteredConversations = filteredConversations.filter(conv => 
                    conv.lastMessage && conv.lastMessage.includes('New Appointment Request')
                );
                break;
            case 'sent':
                // Implement sent messages filter logic
                break;
            case 'all':
            default:
                break;
        }
        
        // Apply search
        if (this.searchQuery) {
            filteredConversations = filteredConversations.filter(conv => {
                const patientInfo = this.patientAvatars.get(conv.patientId);
                const patientName = (patientInfo?.name || conv.patientName || '').toLowerCase();
                const lastMessage = (conv.lastMessage || '').toLowerCase();
                
                return patientName.includes(this.searchQuery) || 
                       lastMessage.includes(this.searchQuery);
            });
        }
        
        // Apply sorting
        this.sortConversations(filteredConversations);
        
        this.displayConversations(filteredConversations);
    },

    sortConversations(conversations) {
        conversations.sort((a, b) => {
            switch (this.sortBy) {
                case 'name':
                    const nameA = (this.patientAvatars.get(a.patientId)?.name || a.patientName || '').toLowerCase();
                    const nameB = (this.patientAvatars.get(b.patientId)?.name || b.patientName || '').toLowerCase();
                    return nameA.localeCompare(nameB);
                
                case 'unread':
                    if (a.hasUnreadMessages && !b.hasUnreadMessages) return -1;
                    if (!a.hasUnreadMessages && b.hasUnreadMessages) return 1;
                    return new Date(b.lastMessageTime) - new Date(a.lastMessageTime);
                
                case 'time':
                default:
                    return new Date(b.lastMessageTime) - new Date(a.lastMessageTime);
            }
        });
    },

    displayConversations(conversations) {
        const container = document.getElementById('messagesList');
        
        if (conversations.length === 0) {
            const emptyMessage = this.searchQuery ? 
                `No conversations found for "${this.searchQuery}"` : 
                'No conversations match your current filter.';
                
            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-comments fa-3x text-muted mb-3"></i>
                    <h5>No conversations found</h5>
                    <p class="text-muted">${emptyMessage}</p>
                    ${this.searchQuery ? `
                        <button class="btn btn-outline-primary mt-3" onclick="messagesPageEnhanced.clearSearch()">
                            <i class="fas fa-times me-2"></i>Clear Search
                        </button>
                    ` : ''}
                </div>
            `;
            return;
        }
        
        const conversationsHTML = conversations.map((conversation, index) => {
            return this.createConversationCard(conversation, index);
        }).join('');
        
        container.innerHTML = `
            <div class="conversations-grid">
                ${conversationsHTML}
            </div>
        `;
        
        this.addConversationEventListeners();
        this.animateConversationCards();
    },

    createConversationCard(conversation, index) {
        const unreadClass = conversation.hasUnreadMessages ? 'unread' : '';
        const urgentClass = conversation.lastMessage && conversation.lastMessage.includes('New Appointment Request') ? 'urgent' : '';
        
        const patientInfo = this.patientAvatars.get(conversation.patientId);
        const patientAvatar = patientInfo?.avatar;
        const patientName = patientInfo?.name || conversation.patientName;
        const timeAgo = this.getTimeAgo(conversation.lastMessageTime);
        const isOnline = this.isPatientOnline(conversation.patientId); // Placeholder for online status
        
        return `
            <div class="conversation-card ${unreadClass} ${urgentClass}" 
                 data-conversation-id="${conversation.id}"
                 style="animation-delay: ${index * 0.1}s">
                <div class="conversation-header">
                    <div class="conversation-info">
                        <div class="conversation-participant">
                            <div class="participant-avatar">
                                ${this.renderPatientAvatar(patientAvatar, patientName)}
                                ${isOnline ? '<div class="online-indicator"></div>' : ''}
                            </div>
                            <div class="participant-details">
                                <strong>${patientName}</strong>
                                <span class="conversation-time" title="${new Date(conversation.lastMessageTime).toLocaleString()}">
                                    ${timeAgo}
                                </span>
                            </div>
                        </div>
                        <div class="conversation-meta">
                            ${conversation.hasUnreadMessages ? `
                                <span class="badge bg-warning">
                                    ${conversation.unreadCount || 1}
                                </span>
                            ` : ''}
                            ${urgentClass ? '<span class="badge bg-danger">Urgent</span>' : ''}
                        </div>
                    </div>
                    <div class="conversation-actions">
                        <button class="btn btn-sm btn-outline-primary" 
                                onclick="messagesPageEnhanced.openConversation('${conversation.id}')"
                                title="Open chat">
                            <i class="fas fa-comments"></i> Chat
                        </button>
                        ${urgentClass ? `
                            <button class="btn btn-sm btn-success" 
                                    onclick="messagesPageEnhanced.approveAppointment('${conversation.id}')"
                                    title="Approve appointment">
                                <i class="fas fa-check"></i> Approve
                            </button>
                            <button class="btn btn-sm btn-danger" 
                                    onclick="messagesPageEnhanced.rejectAppointment('${conversation.id}')"
                                    title="Reject appointment">
                                <i class="fas fa-times"></i> Reject
                            </button>
                        ` : ''}
                    </div>
                </div>
                <div class="conversation-content">
                    <p class="conversation-preview">${this.truncateText(conversation.lastMessage, 120)}</p>
                </div>
            </div>
        `;
    },

    renderPatientAvatar(avatarUrl, patientName) {
        if (avatarUrl && avatarUrl.trim() !== '') {
            if (avatarUrl.startsWith('data:image') || avatarUrl.startsWith('http')) {
                return `<img src="${avatarUrl}" class="patient-avatar" alt="${patientName}" 
                            onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                        <div class="patient-avatar-initials" style="display: none;">
                            ${this.getInitials(patientName)}
                        </div>`;
            }
        }
        return `<div class="patient-avatar-initials">${this.getInitials(patientName)}</div>`;
    },

    getTimeAgo(timestamp) {
        const now = new Date();
        const time = new Date(timestamp);
        const diffMs = now - time;
        const diffHours = Math.floor(diffMs / (1000 * 60 * 60));
        const diffDays = Math.floor(diffHours / 24);
        
        if (diffMs < 60000) return 'Just now';
        if (diffMs < 3600000) return `${Math.floor(diffMs / 60000)}m ago`;
        if (diffHours < 24) return `${diffHours}h ago`;
        if (diffDays < 7) return `${diffDays}d ago`;
        
        return time.toLocaleDateString();
    },

    isPatientOnline(patientId) {
        // Placeholder for online status check
        // In a real implementation, this would check against a websocket or server endpoint
        return Math.random() > 0.7; // Mock online status
    },

    getInitials(name) {
        if (!name) return '?';
        return name.split(' ')
                  .map(n => n[0])
                  .join('')
                  .toUpperCase()
                  .substring(0, 2);
    },

    animateConversationCards() {
        const cards = document.querySelectorAll('.conversation-card');
        cards.forEach((card, index) => {
            card.style.opacity = '0';
            card.style.transform = 'translateY(20px)';
            
            setTimeout(() => {
                card.style.transition = 'all 0.3s ease-out';
                card.style.opacity = '1';
                card.style.transform = 'translateY(0)';
            }, index * 100);
        });
    },

    clearSearch() {
        const searchInput = document.getElementById('messageSearch');
        if (searchInput) {
            searchInput.value = '';
            this.searchQuery = '';
            this.filterAndDisplayConversations();
            searchInput.focus();
        }
    },

    handleTypingIndicator() {
        // Clear existing timeout
        if (this.typingTimeout) {
            clearTimeout(this.typingTimeout);
        }
        
        // Show typing indicator (implementation depends on backend support)
        this.showTypingIndicator();
        
        // Hide typing indicator after 2 seconds of inactivity
        this.typingTimeout = setTimeout(() => {
            this.hideTypingIndicator();
        }, 2000);
    },

    showTypingIndicator() {
        // Implementation for showing typing indicator
        // This would typically send a websocket message to other users
    },

    hideTypingIndicator() {
        // Implementation for hiding typing indicator
    },

    // Toast notification methods
    showSuccessToast(message) {
        this.showToast(message, 'success');
    },

    showErrorToast(message) {
        this.showToast(message, 'error');
    },

    showToast(message, type = 'info') {
        const toastContainer = document.getElementById('notificationContainer') || document.body;
        const toastId = 'toast-' + Date.now();
        
        const toastHTML = `
            <div id="${toastId}" class="toast toast-${type} align-items-center border-0" role="alert">
                <div class="d-flex">
                    <div class="toast-body">
                        <i class="fas fa-${type === 'success' ? 'check' : type === 'error' ? 'exclamation-triangle' : 'info'} me-2"></i>
                        ${message}
                    </div>
                    <button type="button" class="btn-close me-2 m-auto" data-bs-dismiss="toast"></button>
                </div>
            </div>
        `;
        
        toastContainer.insertAdjacentHTML('beforeend', toastHTML);
        
        const toastElement = document.getElementById(toastId);
        const toast = new bootstrap.Toast(toastElement, {
            autohide: true,
            delay: type === 'error' ? 5000 : 3000
        });
        
        toast.show();
        
        // Remove from DOM after hiding
        toastElement.addEventListener('hidden.bs.toast', () => {
            toastElement.remove();
        });
    },

    // Enhanced conversation methods
    async openConversation(conversationId) {
        try {
            this.showLoadingInModal();
            
            const response = await fetch(`/api/chat/conversations/${conversationId}/messages`);
            const data = await response.json();
            
            if (data.success) {
                this.currentConversation = data.conversation;
                this.showConversationModal(data.messages, data.conversation);
                this.markConversationAsRead(conversationId);
            } else {
                console.error('Failed to load messages:', data.message);
                this.showErrorToast('Failed to load messages');
            }
        } catch (error) {
            console.error('Error loading messages:', error);
            this.showErrorToast('Error loading messages');
        }
    },

    showLoadingInModal() {
        const modal = document.getElementById('chatModal');
        if (modal) {
            const bootstrapModal = new bootstrap.Modal(modal);
            bootstrapModal.show();
            
            const chatMessages = modal.querySelector('#chatMessages');
            if (chatMessages) {
                chatMessages.innerHTML = `
                    <div class="loading-state">
                        <div class="spinner-container">
                            <div class="spinner-border text-primary" role="status">
                                <span class="visually-hidden">Loading...</span>
                            </div>
                        </div>
                        <p class="loading-text">Loading conversation...</p>
                    </div>
                `;
            }
        }
    },

    markConversationAsRead(conversationId) {
        // Update the conversation as read in the list
        const conversation = this.allConversations.find(c => c.id === conversationId);
        if (conversation && conversation.hasUnreadMessages) {
            conversation.hasUnreadMessages = false;
            conversation.unreadCount = 0;
            
            // Update the conversation card
            const card = document.querySelector(`[data-conversation-id="${conversationId}"]`);
            if (card) {
                card.classList.remove('unread');
                const badge = card.querySelector('.badge.bg-warning');
                if (badge) {
                    badge.remove();
                }
            }
            
            // Update statistics
            this.updateStatistics();
        }
    },

    // Override parent methods to use enhanced functionality
    refresh() {
        this.loadConversations();
    },

    // Additional utility methods
    truncateText(text, maxLength) {
        if (!text) return '';
        if (text.length <= maxLength) return text;
        return text.substring(0, maxLength) + '...';
    },

    // Extend the original methods
    ...messagesPage
};

// Initialize enhanced messages page if it's available
if (typeof messagesPage !== 'undefined') {
    // Override the original with enhanced version
    Object.assign(messagesPage, messagesPageEnhanced);
} 