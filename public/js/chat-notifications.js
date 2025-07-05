// Chat Notifications System
class ChatNotifications {
    constructor() {
        this.unreadCount = 0;
        this.conversations = [];
        this.init();
    }

    init() {
        this.setupNotificationBadge();
        this.setupPeriodicRefresh();
        this.loadUnreadCount();
    }

    setupNotificationBadge() {
        // Find or create notification badge
        let badge = document.querySelector('.chat-notification-badge');
        if (!badge) {
            // Create badge if it doesn't exist
            const chatButton = document.querySelector('[href*="messages"], [data-page="messages"], .nav-link[href*="chat"]');
            if (chatButton) {
                badge = document.createElement('span');
                badge.className = 'chat-notification-badge badge bg-danger position-absolute';
                badge.style.cssText = `
                    top: -5px;
                    right: -5px;
                    min-width: 18px;
                    height: 18px;
                    border-radius: 9px;
                    font-size: 10px;
                    line-height: 18px;
                    text-align: center;
                    display: none;
                `;
                chatButton.style.position = 'relative';
                chatButton.appendChild(badge);
            }
        }
        this.badge = badge;
    }

    async loadUnreadCount() {
        try {
            const response = await fetch('/api/chat/conversations');
            if (response.ok) {
                const data = await response.json();
                if (data.success) {
                    this.conversations = data.conversations;
                    this.updateUnreadCount();
                }
            }
        } catch (error) {
            console.error('Error loading unread count:', error);
        }
    }

    updateUnreadCount() {
        // Count total unread messages from patients
        let totalUnread = 0;
        this.conversations.forEach(conversation => {
            if (conversation.hasUnreadMessages && conversation.unreadCount > 0) {
                // Only count if last message was from patient
                if (!conversation.lastSenderType || conversation.lastSenderType === 'patient') {
                    totalUnread += conversation.unreadCount;
                }
            }
        });

        this.unreadCount = totalUnread;
        this.updateBadgeDisplay();
    }

    updateBadgeDisplay() {
        if (!this.badge) return;

        if (this.unreadCount > 0) {
            this.badge.textContent = this.unreadCount > 99 ? '99+' : this.unreadCount;
            this.badge.style.display = 'block';
            this.badge.classList.add('animate__animated', 'animate__pulse');
            
            // Remove animation after it completes
            setTimeout(() => {
                this.badge.classList.remove('animate__animated', 'animate__pulse');
            }, 1000);
        } else {
            this.badge.style.display = 'none';
        }
    }

    // Call this when a conversation is read
    markConversationAsRead(conversationId) {
        const conversation = this.conversations.find(c => c.id === conversationId);
        if (conversation) {
            conversation.hasUnreadMessages = false;
            conversation.unreadCount = 0;
            this.updateUnreadCount();
        }
    }

    // Call this when a new message is received
    handleNewMessage(conversationId, senderType) {
        const conversation = this.conversations.find(c => c.id === conversationId);
        if (conversation && senderType === 'patient') {
            conversation.hasUnreadMessages = true;
            conversation.unreadCount = (conversation.unreadCount || 0) + 1;
            conversation.lastSenderType = 'patient';
            this.updateUnreadCount();
            
            // Show browser notification if permission granted
            this.showBrowserNotification(conversation);
        }
    }

    // Call this when clinic sends a message
    handleClinicMessage(conversationId) {
        const conversation = this.conversations.find(c => c.id === conversationId);
        if (conversation) {
            conversation.lastSenderType = 'clinic';
            // Don't update unread count for clinic messages
        }
    }

    async showBrowserNotification(conversation) {
        if ('Notification' in window && Notification.permission === 'granted') {
            const notification = new Notification(`New message from ${conversation.patientName}`, {
                body: conversation.lastMessage || 'New message received',
                icon: '/assets/logo.png',
                badge: '/assets/logo.png',
                tag: `chat-${conversation.id}`,
                requireInteraction: false,
                silent: false
            });

            notification.onclick = () => {
                window.focus();
                // Navigate to messages page
                if (window.location.pathname !== '/messages') {
                    window.location.href = '/messages';
                }
                notification.close();
            };

            // Auto close after 5 seconds
            setTimeout(() => notification.close(), 5000);
        }
    }

    // Request notification permission
    async requestNotificationPermission() {
        if ('Notification' in window && Notification.permission === 'default') {
            const permission = await Notification.requestPermission();
            return permission === 'granted';
        }
        return Notification.permission === 'granted';
    }

    setupPeriodicRefresh() {
        // Refresh unread count every 30 seconds
        setInterval(() => {
            this.loadUnreadCount();
        }, 30000);
    }

    // Increment unread count (for real-time updates)
    incrementUnreadCount(amount = 1) {
        this.unreadCount += amount;
        this.updateBadgeDisplay();
    }

    // Decrement unread count
    decrementUnreadCount(amount = 1) {
        this.unreadCount = Math.max(0, this.unreadCount - amount);
        this.updateBadgeDisplay();
    }

    // Reset unread count
    resetUnreadCount() {
        this.unreadCount = 0;
        this.updateBadgeDisplay();
    }
}

// Initialize chat notifications when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.chatNotifications = new ChatNotifications();
    
    // Request notification permission on first load
    window.chatNotifications.requestNotificationPermission();
});

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ChatNotifications;
} 