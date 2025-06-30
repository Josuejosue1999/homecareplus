// Messages Page Module
const messagesPage = {
    currentFilter: 'all',
    allMessages: [],
    currentUser: null,

    init() {
        this.bindEvents();
        this.loadMessages();
        this.updateStatistics();
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
        
        // Filter and display messages
        this.filterAndDisplayMessages();
    },

    loadMessages() {
        this.showLoadingState();
        
        // Simulate loading messages (replace with actual API call)
        setTimeout(() => {
            this.allMessages = this.getSampleMessages();
            this.filterAndDisplayMessages();
            this.updateStatistics();
        }, 1000);
    },

    getSampleMessages() {
        return [
            {
                id: 1,
                from: 'John Doe',
                to: 'Clinic',
                subject: 'Appointment Confirmation',
                message: 'Thank you for confirming my appointment for tomorrow at 2 PM. I will be there on time.',
                timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
                status: 'unread',
                priority: 'normal',
                type: 'incoming'
            },
            {
                id: 2,
                from: 'Clinic',
                to: 'Jane Smith',
                subject: 'Appointment Reminder',
                message: 'This is a reminder for your appointment scheduled for tomorrow at 10 AM. Please arrive 15 minutes early.',
                timestamp: new Date(Date.now() - 4 * 60 * 60 * 1000), // 4 hours ago
                status: 'read',
                priority: 'normal',
                type: 'outgoing'
            },
            {
                id: 3,
                from: 'Mike Johnson',
                to: 'Clinic',
                subject: 'Urgent: Need to Reschedule',
                message: 'I have an emergency and need to reschedule my appointment for next week. Please let me know available slots.',
                timestamp: new Date(Date.now() - 1 * 60 * 60 * 1000), // 1 hour ago
                status: 'unread',
                priority: 'urgent',
                type: 'incoming'
            },
            {
                id: 4,
                from: 'Clinic',
                to: 'Sarah Wilson',
                subject: 'Test Results Available',
                message: 'Your test results are now available. Please call us to schedule a follow-up consultation.',
                timestamp: new Date(Date.now() - 6 * 60 * 60 * 1000), // 6 hours ago
                status: 'read',
                priority: 'normal',
                type: 'outgoing'
            },
            {
                id: 5,
                from: 'David Brown',
                to: 'Clinic',
                subject: 'Prescription Refill Request',
                message: 'I need a refill for my prescription. Can you please process this request?',
                timestamp: new Date(Date.now() - 8 * 60 * 60 * 1000), // 8 hours ago
                status: 'unread',
                priority: 'normal',
                type: 'incoming'
            }
        ];
    },

    filterAndDisplayMessages() {
        let filteredMessages = this.allMessages;
        
        switch (this.currentFilter) {
            case 'unread':
                filteredMessages = this.allMessages.filter(msg => msg.status === 'unread');
                break;
            case 'sent':
                filteredMessages = this.allMessages.filter(msg => msg.type === 'outgoing');
                break;
            case 'urgent':
                filteredMessages = this.allMessages.filter(msg => msg.priority === 'urgent');
                break;
            case 'all':
            default:
                filteredMessages = this.allMessages;
                break;
        }
        
        this.displayMessages(filteredMessages);
    },

    displayMessages(messages) {
        const container = document.getElementById('messagesList');
        
        if (messages.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                    <h5>No messages found</h5>
                    <p class="text-muted">No messages match your current filter.</p>
                </div>
            `;
            return;
        }
        
        const messagesHTML = messages.map(message => this.createMessageCard(message)).join('');
        container.innerHTML = `
            <div class="messages-grid">
                ${messagesHTML}
            </div>
        `;
        
        // Add event listeners to message cards
        this.addMessageEventListeners();
    },

    createMessageCard(message) {
        const priorityClass = message.priority === 'urgent' ? 'urgent' : '';
        const statusClass = message.status === 'unread' ? 'unread' : '';
        const typeIcon = message.type === 'incoming' ? 'fas fa-arrow-right' : 'fas fa-arrow-left';
        const typeClass = message.type === 'incoming' ? 'incoming' : 'outgoing';
        
        return `
            <div class="message-card ${priorityClass} ${statusClass} ${typeClass}" data-message-id="${message.id}">
                <div class="message-header">
                    <div class="message-info">
                        <div class="message-sender">
                            <i class="${typeIcon} me-2"></i>
                            <strong>${message.from}</strong>
                            <span class="message-direction">${message.type === 'incoming' ? '→' : '←'}</span>
                            <strong>${message.to}</strong>
                        </div>
                        <div class="message-meta">
                            <span class="message-time">${this.formatTime(message.timestamp)}</span>
                            ${message.priority === 'urgent' ? '<span class="badge bg-danger ms-2">Urgent</span>' : ''}
                            ${message.status === 'unread' ? '<span class="badge bg-warning ms-2">Unread</span>' : ''}
                        </div>
                    </div>
                    <div class="message-actions">
                        <button class="btn btn-sm btn-outline-primary" onclick="messagesPage.viewMessage(${message.id})">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-success" onclick="messagesPage.replyToMessage(${message.id})">
                            <i class="fas fa-reply"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="messagesPage.deleteMessage(${message.id})">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </div>
                <div class="message-content">
                    <h6 class="message-subject">${message.subject}</h6>
                    <p class="message-preview">${this.truncateText(message.message, 100)}</p>
                </div>
            </div>
        `;
    },

    formatTime(timestamp) {
        const now = new Date();
        const diff = now - timestamp;
        const hours = Math.floor(diff / (1000 * 60 * 60));
        const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
        
        if (hours > 24) {
            return timestamp.toLocaleDateString();
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

    addMessageEventListeners() {
        document.querySelectorAll('.message-card').forEach(card => {
            card.addEventListener('click', (e) => {
                if (!e.target.closest('.message-actions')) {
                    const messageId = card.dataset.messageId;
                    this.viewMessage(parseInt(messageId));
                }
            });
        });
    },

    viewMessage(messageId) {
        const message = this.allMessages.find(msg => msg.id === messageId);
        if (!message) return;
        
        // Mark as read if unread
        if (message.status === 'unread') {
            message.status = 'read';
            this.updateStatistics();
        }
        
        this.showMessageModal(message);
    },

    showMessageModal(message) {
        const modalHTML = `
            <div class="modal fade" id="messageModal" tabindex="-1">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">
                                <i class="fas fa-envelope me-2"></i>
                                ${message.subject}
                            </h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <div class="message-details">
                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <strong>From:</strong> ${message.from}
                                    </div>
                                    <div class="col-md-6">
                                        <strong>To:</strong> ${message.to}
                                    </div>
                                </div>
                                <div class="row mb-3">
                                    <div class="col-md-6">
                                        <strong>Date:</strong> ${message.timestamp.toLocaleString()}
                                    </div>
                                    <div class="col-md-6">
                                        <strong>Priority:</strong> 
                                        <span class="badge bg-${message.priority === 'urgent' ? 'danger' : 'secondary'}">
                                            ${message.priority}
                                        </span>
                                    </div>
                                </div>
                                <hr>
                                <div class="message-body">
                                    <p>${message.message}</p>
                                </div>
                            </div>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                            <button type="button" class="btn btn-primary" onclick="messagesPage.replyToMessage(${message.id})">
                                <i class="fas fa-reply me-1"></i>Reply
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        // Remove existing modal if any
        const existingModal = document.getElementById('messageModal');
        if (existingModal) {
            existingModal.remove();
        }
        
        // Add modal to body
        document.body.insertAdjacentHTML('beforeend', modalHTML);
        
        // Show modal
        const modal = new bootstrap.Modal(document.getElementById('messageModal'));
        modal.show();
    },

    replyToMessage(messageId) {
        const message = this.allMessages.find(msg => msg.id === messageId);
        if (!message) return;
        
        this.showComposeModal(message);
    },

    composeNewMessage() {
        this.showComposeModal();
    },

    showComposeModal(replyTo = null) {
        const modalHTML = `
            <div class="modal fade" id="composeModal" tabindex="-1">
                <div class="modal-dialog modal-lg">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">
                                <i class="fas fa-edit me-2"></i>
                                ${replyTo ? 'Reply to Message' : 'Compose New Message'}
                            </h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <form id="composeForm">
                                <div class="mb-3">
                                    <label for="recipient" class="form-label">To:</label>
                                    <input type="text" class="form-control" id="recipient" 
                                           value="${replyTo ? replyTo.from : ''}" required>
                                </div>
                                <div class="mb-3">
                                    <label for="subject" class="form-label">Subject:</label>
                                    <input type="text" class="form-control" id="subject" 
                                           value="${replyTo ? `Re: ${replyTo.subject}` : ''}" required>
                                </div>
                                <div class="mb-3">
                                    <label for="messageBody" class="form-label">Message:</label>
                                    <textarea class="form-control" id="messageBody" rows="6" required></textarea>
                                </div>
                                <div class="mb-3">
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" id="urgentPriority">
                                        <label class="form-check-label" for="urgentPriority">
                                            Mark as urgent
                                        </label>
                                    </div>
                                </div>
                            </form>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                            <button type="button" class="btn btn-primary" onclick="messagesPage.sendMessage()">
                                <i class="fas fa-paper-plane me-1"></i>Send Message
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        // Remove existing modal if any
        const existingModal = document.getElementById('composeModal');
        if (existingModal) {
            existingModal.remove();
        }
        
        // Add modal to body
        document.body.insertAdjacentHTML('beforeend', modalHTML);
        
        // Show modal
        const modal = new bootstrap.Modal(document.getElementById('composeModal'));
        modal.show();
    },

    sendMessage() {
        const recipient = document.getElementById('recipient').value;
        const subject = document.getElementById('subject').value;
        const messageBody = document.getElementById('messageBody').value;
        const isUrgent = document.getElementById('urgentPriority').checked;
        
        if (!recipient || !subject || !messageBody) {
            Swal.fire('Error', 'Please fill in all required fields', 'error');
            return;
        }
        
        // Create new message
        const newMessage = {
            id: Date.now(),
            from: 'Clinic',
            to: recipient,
            subject: subject,
            message: messageBody,
            timestamp: new Date(),
            status: 'read',
            priority: isUrgent ? 'urgent' : 'normal',
            type: 'outgoing'
        };
        
        // Add to messages list
        this.allMessages.unshift(newMessage);
        
        // Update display
        this.filterAndDisplayMessages();
        this.updateStatistics();
        
        // Close modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('composeModal'));
        modal.hide();
        
        // Show success message
        Swal.fire('Success', 'Message sent successfully!', 'success');
    },

    deleteMessage(messageId) {
        Swal.fire({
            title: 'Delete Message',
            text: 'Are you sure you want to delete this message?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Yes, delete it!'
        }).then((result) => {
            if (result.isConfirmed) {
                this.allMessages = this.allMessages.filter(msg => msg.id !== messageId);
                this.filterAndDisplayMessages();
                this.updateStatistics();
                
                Swal.fire('Deleted!', 'Message has been deleted.', 'success');
            }
        });
    },

    updateStatistics() {
        const total = this.allMessages.length;
        const unread = this.allMessages.filter(msg => msg.status === 'unread').length;
        const sent = this.allMessages.filter(msg => msg.type === 'outgoing').length;
        const urgent = this.allMessages.filter(msg => msg.priority === 'urgent').length;
        
        document.getElementById('totalMessages').textContent = total;
        document.getElementById('unreadMessages').textContent = unread;
        document.getElementById('sentMessages').textContent = sent;
        document.getElementById('pendingReplies').textContent = urgent;
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
                <p class="loading-text">Loading messages...</p>
            </div>
        `;
    },

    refresh() {
        this.loadMessages();
    }
};

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('messages-content')) {
        messagesPage.init();
    }
}); 