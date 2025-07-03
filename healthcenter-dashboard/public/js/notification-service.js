/**
 * Professional Notification Service
 * Handles real-time notifications for the health center dashboard with enhanced chat support
 */
class NotificationService {
    constructor() {
        this.notificationCount = 0;
        this.soundEnabled = true;
        this.lastAppointmentId = null;
        this.checkInterval = null;
        this.processedAppointments = new Set();
        this.lastChatCheck = new Date();
        this.unreadChatCount = 0;
        this.processedSounds = new Set(); // Track played sounds to prevent repeats
        this.init();
    }

    init() {
        console.log('🔔 Professional Notification Service starting...');
        this.createNotificationContainer();
        this.requestNotificationPermission();
        this.startPolling();
    }

    createNotificationContainer() {
        if (!document.getElementById('notificationContainer')) {
            const container = document.createElement('div');
            container.id = 'notificationContainer';
            container.className = 'notification-toast-container';
            document.body.appendChild(container);
        }
        this.notificationContainer = document.getElementById('notificationContainer');
    }

    async requestNotificationPermission() {
        if ('Notification' in window && Notification.permission === 'default') {
            try {
                const permission = await Notification.requestPermission();
                console.log('Notification permission:', permission);
            } catch (error) {
                console.log('Error requesting notification permission:', error);
            }
        }
    }

    startPolling() {
        console.log('🔄 Starting appointment and chat polling...');
        
        // Check immediately
        this.checkForNewAppointments();
        this.checkForNewChatMessages();
        
        // Then check every 15 seconds for better real-time experience
        this.pollingInterval = setInterval(() => {
            this.checkForNewAppointments();
            this.checkForNewChatMessages();
        }, 15000);
    }

    async checkForNewAppointments() {
        try {
            console.log('📅 Checking for new appointments...');
            const response = await fetch('/api/appointments');
            if (response.ok) {
                const data = await response.json();
                if (data.success && data.appointments) {
                    console.log(`📅 Found ${data.appointments.length} appointments`);
                    this.processAppointments(data.appointments);
                }
            }
        } catch (error) {
            console.error('Error checking for new appointments:', error);
        }
    }

    async checkForNewChatMessages() {
        try {
            console.log('💬 Checking for new chat messages...');
            const response = await fetch('/api/chat/conversations');
            if (response.ok) {
                const data = await response.json();
                if (data.success && data.conversations) {
                    console.log(`💬 Found ${data.conversations.length} conversations`);
                    this.processChatMessages(data.conversations);
                    this.updateChatBadge(data.conversations);
                }
            }
        } catch (error) {
            console.error('Error checking for new chat messages:', error);
        }
    }

    processAppointments(appointments) {
        if (!appointments || appointments.length === 0) return;

        console.log('📅 Processing appointments for notifications...');
        const now = new Date();
        const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000);

        appointments.forEach(appointment => {
            const appointmentDate = new Date(appointment.date || appointment.createdAt);
            
            if (appointmentDate > fiveMinutesAgo && !this.processedAppointments.has(appointment.id)) {
                console.log('📅 NEW APPOINTMENT DETECTED!');
                console.log('📋 Appointment details:', appointment);
                
                this.processedAppointments.add(appointment.id);
                this.showAppointmentNotification(appointment);
                this.notificationCount++;
                this.updateNotificationBadge();
            }
        });
    }

    processChatMessages(conversations) {
        if (!conversations || conversations.length === 0) {
            this.unreadChatCount = 0;
            this.updateChatBadge([]);
            return;
        }

        console.log('💬 Processing conversations for notifications...');
        const now = new Date();
        const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000);

        conversations.forEach(conversation => {
            // Check if there are unread messages
            if (conversation.hasUnreadMessages && conversation.unreadCount > 0) {
                const conversationId = conversation.id;
                const lastMessageTime = new Date(conversation.lastMessageTime);
                
                // Check if this is a recent message we haven't notified about
                const lastMessageKey = `chat_${conversationId}_${conversation.lastMessageTime}`;
                
                if (lastMessageTime > fiveMinutesAgo && !this.processedAppointments.has(lastMessageKey)) {
                    console.log('💬 NEW CHAT MESSAGE DETECTED!');
                    console.log('📋 Conversation details:', conversation);
                    
                    // Mark as processed
                    this.processedAppointments.add(lastMessageKey);
                    
                    // Show chat notification
                    this.showChatNotification(conversation);
                }
            }
        });
    }

    showAppointmentNotification(appointment) {
        console.log('📅 Showing appointment notification for:', appointment);
        
        // Play notification sound only once
        const soundKey = `appointment_${appointment.id}`;
        this.playNotificationSoundOnce(soundKey);
        
        // Animate notification bell
        this.animateNotificationBell();
        
        // Update notification count (no toast for cleaner UI)
        this.updateNotificationCount();
    }

    showChatNotification(conversation) {
        console.log('💬 Showing chat notification for:', conversation);
        
        // Play notification sound only once
        const soundKey = `chat_${conversation.id}_${conversation.lastMessageTime}`;
        this.playNotificationSoundOnce(soundKey);
        
        // Animate notification bell
        this.animateNotificationBell();
        
        // Update notification count (no toast for cleaner UI)
        this.updateNotificationCount();
        
        // Update chat badge if chat interface exists
        this.updateChatIcon();
    }

    showAppointmentToastNotification(appointment) {
        if (!this.notificationContainer) return;
        
        const toast = document.createElement('div');
        toast.className = 'notification-toast appointment show';
        
        const timeAgo = this.getTimeAgo(new Date(appointment.date || appointment.createdAt));
        
        toast.innerHTML = `
            <div class="notification-header">
                <i class="fas fa-calendar-plus"></i>
                <span>New Appointment</span>
                <button class="close-toast" onclick="this.parentElement.parentElement.remove()">×</button>
            </div>
            <div class="notification-body">
                <strong>${appointment.patientName || 'New Patient'}</strong>
                <p>${appointment.department || 'General Consultation'}</p>
                <small>${timeAgo}</small>
            </div>
            <div class="notification-actions">
                <button class="btn-view-appointment" onclick="window.location.href='#appointments'">
                    View Details
                </button>
            </div>
        `;
        
        this.notificationContainer.appendChild(toast);
        
        // Auto remove after 8 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.remove();
            }
        }, 8000);
    }

    showChatToastNotification(conversation) {
        if (!this.notificationContainer) return;
        
        const toast = document.createElement('div');
        toast.className = 'notification-toast chat show';
        
        const timeAgo = this.getTimeAgo(new Date(conversation.lastMessageTime));
        
        toast.innerHTML = `
            <div class="notification-header">
                <i class="fas fa-comments"></i>
                <span>New Message</span>
                <button class="close-toast" onclick="this.parentElement.parentElement.remove()">×</button>
            </div>
            <div class="notification-body">
                <strong>${conversation.patientName}</strong>
                <p>${conversation.lastMessage}</p>
                <small>${timeAgo}</small>
            </div>
            <div class="notification-actions">
                <button class="btn-view-chat" onclick="notificationService.navigateToMessages()">
                    View Chat
                </button>
            </div>
        `;
        
        this.notificationContainer.appendChild(toast);
        
        // Auto remove after 8 seconds
        setTimeout(() => {
            if (toast.parentNode) {
                toast.remove();
            }
        }, 8000);
    }

    updateChatBadge(conversations) {
        // Count total unread messages
        let totalUnread = 0;
        if (conversations && conversations.length > 0) {
            conversations.forEach(conv => {
                if (conv.hasUnreadMessages) {
                    totalUnread += conv.unreadCount || 1;
                }
            });
        }

        this.unreadChatCount = totalUnread;
        
        // Update chat badge in sidebar
        const chatBadge = document.getElementById('chatBadge');
        if (chatBadge) {
            if (totalUnread > 0) {
                chatBadge.style.display = 'block';
                chatBadge.textContent = totalUnread;
                chatBadge.className = 'badge bg-warning ms-auto';
            } else {
                chatBadge.style.display = 'none';
            }
        }
    }

    updateChatIcon() {
        const chatIcon = document.getElementById('chatIcon');
        if (chatIcon) {
            chatIcon.classList.add('has-notification');
            
            // Remove animation after 3 seconds
            setTimeout(() => {
                chatIcon.classList.remove('has-notification');
            }, 3000);
        }
    }

    navigateToMessages() {
        // Navigate to messages page
        console.log('🔗 Navigating to messages...');
        
        // If we have a messages page object, use it
        if (typeof messagesPage !== 'undefined') {
            // Update sidebar active state
            document.querySelectorAll('.sidebar .nav-item').forEach(item => {
                item.classList.remove('active');
            });
            
            // Find and activate messages nav item
            const messagesLink = document.querySelector('a[href="#messages"]');
            if (messagesLink) {
                messagesLink.closest('.nav-item').classList.add('active');
            }
            
            // Show messages section
            this.showSection('messages');
        } else {
            // Fallback: try to trigger click on messages link
            const messagesLink = document.querySelector('a[href="#messages"]');
            if (messagesLink) {
                messagesLink.click();
            }
        }
    }

    showSection(sectionName) {
        // Hide all sections
        const sections = document.querySelectorAll('[id$="Section"]');
        sections.forEach(section => {
            section.style.display = 'none';
        });
        
        // Show target section
        const targetSection = document.getElementById(`${sectionName}Section`);
        if (targetSection) {
            targetSection.style.display = 'block';
        }
        
        // Update header title
        const headerTitle = document.querySelector('.header-title h1');
        if (headerTitle) {
            const icon = sectionName === 'messages' ? 'comments' : 'tachometer-alt';
            const title = sectionName.charAt(0).toUpperCase() + sectionName.slice(1);
            headerTitle.innerHTML = `<i class="fas fa-${icon} me-2"></i>${title}`;
        }
    }

    playNotificationSound() {
        if (!this.soundEnabled) return;
        
        try {
            const audio = document.getElementById('notificationSound');
            if (audio) {
                audio.currentTime = 0;
                audio.play().catch(e => console.log('Could not play notification sound:', e));
            }
        } catch (error) {
            console.log('Error playing notification sound:', error);
        }
    }

    animateNotificationBell() {
        const bell = document.getElementById('notificationBell');
        if (bell) {
            bell.classList.add('ringing');
            setTimeout(() => {
                bell.classList.remove('ringing');
            }, 1000);
        }
    }

    updateNotificationBadge() {
        const badge = document.querySelector('.notifications .badge');
        if (badge) {
            if (this.notificationCount > 0) {
                badge.textContent = this.notificationCount;
                badge.style.display = 'inline-flex';
                badge.className = 'badge bg-danger';
            } else {
                badge.style.display = 'none';
            }
        }
        
        // Also update appointment badge in sidebar
        const appointmentBadge = document.getElementById('appointmentBadge');
        if (appointmentBadge) {
            if (this.notificationCount > 0) {
                appointmentBadge.textContent = this.notificationCount;
                appointmentBadge.style.display = 'inline-flex';
                appointmentBadge.className = 'badge bg-danger ms-auto';
            } else {
                appointmentBadge.style.display = 'none';
            }
        }
    }

    updateNotificationCount() {
        // This method can be called to refresh the notification count
        this.updateNotificationBadge();
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

    // Public method to manually check for new notifications
    refresh() {
        this.checkForNewAppointments();
        this.checkForNewChatMessages();
    }

    // Public method to clear all notifications
    clearNotifications() {
        this.notificationCount = 0;
        this.unreadChatCount = 0;
        this.updateNotificationBadge();
        this.updateChatBadge([]);
        
        if (this.notificationContainer) {
            this.notificationContainer.innerHTML = '';
        }
    }

    // Public method to get current chat notification count
    getChatNotificationCount() {
        return this.unreadChatCount;
    }

    // Public method to toggle sound
    toggleSound() {
        this.soundEnabled = !this.soundEnabled;
        console.log('🔊 Notification sound:', this.soundEnabled ? 'enabled' : 'disabled');
        return this.soundEnabled;
    }

    // Clean up when needed
    destroy() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
        }
    }

    playNotificationSoundOnce(soundKey) {
        if (this.processedSounds.has(soundKey)) return;
        
        this.processedSounds.add(soundKey);
        this.playNotificationSound();
    }
}

// Initialize notification service when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.notificationService = new NotificationService();
});

// Test notification function
function testNotification() {
    if (window.notificationService) {
        // Test with a mock appointment
        const mockAppointment = {
            id: 'test_' + Date.now(),
            patientName: 'Test Patient',
            department: 'General Consultation',
            date: new Date()
        };
        
        window.notificationService.showAppointmentNotification(mockAppointment);
        console.log('🧪 Test notification triggered');
    }
} 