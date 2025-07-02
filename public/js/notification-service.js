/**
 * Notification Service
 * Handles real-time notifications for the health center dashboard
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
        this.init();
    }

    init() {
        console.log('🔔 Initializing Notification Service...');
        this.loadSoundSettings();
        this.startRealTimeChecks();
        this.setupSoundControl();
        this.updateNotificationBadge();
    }

    loadSoundSettings() {
        const soundEnabled = localStorage.getItem('soundEnabled');
        this.soundEnabled = soundEnabled !== 'false'; // Default to true
        this.updateSoundControlUI();
    }

    startRealTimeChecks() {
        // Check for new appointments every 10 seconds
        this.checkInterval = setInterval(() => {
            this.checkForNewAppointments();
            this.checkForNewChatMessages();
        }, 10000);

        // Initial check
        this.checkForNewAppointments();
        this.checkForNewChatMessages();
    }

    async checkForNewAppointments() {
        try {
            const response = await fetch('/api/appointments/clinic-appointments');
            const data = await response.json();

            if (data.success && data.appointments) {
                this.processNewAppointments(data.appointments);
            }
        } catch (error) {
            console.error('❌ Error checking for new appointments:', error);
        }
    }

    async checkForNewChatMessages() {
        try {
            const response = await fetch('/api/chat/conversations');
            const data = await response.json();

            if (data.success && data.conversations) {
                this.processNewChatMessages(data.conversations);
            }
        } catch (error) {
            console.error('❌ Error checking for new chat messages:', error);
        }
    }

    processNewAppointments(appointments) {
        const now = new Date();
        const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000);
        let newNotifications = 0;

        appointments.forEach(appointment => {
            const appointmentDate = new Date(appointment.date);
            
            // Check if this is a new appointment (created in the last 5 minutes)
            if (appointmentDate > fiveMinutesAgo && !this.processedAppointments.has(appointment.id)) {
                console.log('🎯 New appointment detected:', appointment);
                this.processedAppointments.add(appointment.id);
                
                // Show notification
                this.showAppointmentNotification(appointment);
                newNotifications++;
            }
        });

        // Only update notification count if there were new notifications
        if (newNotifications > 0) {
            this.notificationCount += newNotifications;
            this.updateNotificationBadge();
            console.log(`📊 Added ${newNotifications} new appointment notifications`);
        }
    }

    processNewChatMessages(conversations) {
        const now = new Date();
        const fiveMinutesAgo = new Date(now.getTime() - 5 * 60 * 1000);
        let newUnreadCount = 0;
        let newChatNotifications = 0;

        conversations.forEach(conversation => {
            const lastMessageTime = new Date(conversation.lastMessageTime);
            
            // Check if there are unread messages
            if (conversation.hasUnreadMessages) {
                newUnreadCount += conversation.unreadCount || 1;
            }
            
            // Check if this is a new message (in the last 5 minutes) and not already processed
            const notificationKey = `chat-${conversation.id}`;
            if (lastMessageTime > fiveMinutesAgo && conversation.hasUnreadMessages && !this.processedAppointments.has(notificationKey)) {
                console.log('💬 New chat message detected:', conversation);
                this.processedAppointments.add(notificationKey);
                this.showChatNotification(conversation);
                newChatNotifications++;
            }
        });

        // Update chat notification count if it changed
        if (newUnreadCount !== this.unreadChatCount) {
            this.unreadChatCount = newUnreadCount;
            this.updateChatNotificationBadge();
        }

        if (newChatNotifications > 0) {
            console.log(`📊 Added ${newChatNotifications} new chat notifications`);
        }
    }

    showAppointmentNotification(appointment) {
        console.log('🔔 Showing appointment notification');
        
        // Play sound if enabled
        if (this.soundEnabled) {
            this.playNotificationSound();
        }

        // Show browser notification if supported
        if ('Notification' in window && Notification.permission === 'granted') {
            const notification = new Notification('New Appointment Request', {
                body: `${appointment.patientName} has requested an appointment for ${appointment.service}`,
                icon: '/assets/hospital.PNG',
                tag: `appointment-${appointment.id}`,
                requireInteraction: true
            });

            notification.onclick = () => {
                window.focus();
                notification.close();
                // Navigate to appointments page
                this.navigateToAppointments();
            };
        }

        // Show in-app notification
        this.showInAppNotification('New Appointment Request', 
            `${appointment.patientName} has requested an appointment for ${appointment.service}`, 
            'appointment');
    }

    showChatNotification(conversation) {
        console.log('💬 Showing chat notification');
        
        // Play sound if enabled
        if (this.soundEnabled) {
            this.playNotificationSound();
        }

        // Show browser notification if supported
        if ('Notification' in window && Notification.permission === 'granted') {
            const notification = new Notification('New Chat Message', {
                body: `New message from ${conversation.patientName}: ${conversation.lastMessage.substring(0, 50)}...`,
                icon: '/assets/hospital.PNG',
                tag: `chat-${conversation.id}`,
                requireInteraction: true
            });

            notification.onclick = () => {
                window.focus();
                notification.close();
                // Navigate to messages page
                this.navigateToMessages();
            };
        }

        // Show in-app notification
        this.showInAppNotification('New Chat Message', 
            `New message from ${conversation.patientName}`, 
            'chat');
    }

    showInAppNotification(title, message, type) {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `toast-notification ${type}-notification`;
        notification.innerHTML = `
            <div class="toast-header">
                <strong class="me-auto">${title}</strong>
                <button type="button" class="btn-close" onclick="this.parentElement.parentElement.remove()"></button>
            </div>
            <div class="toast-body">
                ${message}
            </div>
        `;

        // Add to notification container
        const container = document.getElementById('notificationContainer') || this.createNotificationContainer();
        container.appendChild(notification);

        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (notification.parentElement) {
                notification.remove();
            }
        }, 5000);
    }

    createNotificationContainer() {
        const container = document.createElement('div');
        container.id = 'notificationContainer';
        container.className = 'notification-container';
        container.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 9999;
            max-width: 350px;
        `;
        document.body.appendChild(container);
        return container;
    }

    playNotificationSound() {
        try {
            const audio = new Audio('/assets/notification.mp3');
            audio.volume = 0.5;
            audio.play().catch(error => {
                console.log('🔇 Could not play notification sound:', error);
            });
        } catch (error) {
            console.log('🔇 Error playing notification sound:', error);
        }
    }

    updateNotificationBadge() {
        const badge = document.querySelector('.notification-badge');
        if (badge) {
            if (this.notificationCount > 0) {
                badge.textContent = this.notificationCount;
                badge.style.display = 'block';
            } else {
                badge.style.display = 'none';
            }
        }
    }

    updateChatNotificationBadge() {
        const badge = document.querySelector('.chat-notification-badge');
        if (badge) {
            if (this.unreadChatCount > 0) {
                badge.textContent = this.unreadChatCount;
                badge.style.display = 'block';
            } else {
                badge.style.display = 'none';
            }
        }
    }

    setupSoundControl() {
        const soundControl = document.getElementById('soundControl');
        if (soundControl) {
            soundControl.addEventListener('click', () => {
                this.soundEnabled = !this.soundEnabled;
                localStorage.setItem('soundEnabled', this.soundEnabled);
                this.updateSoundControlUI();
                
                // Show feedback
                const icon = soundControl.querySelector('i');
                if (this.soundEnabled) {
                    icon.className = 'fas fa-volume-up';
                    this.showToast('Sound notifications enabled', 'success');
                } else {
                    icon.className = 'fas fa-volume-mute';
                    this.showToast('Sound notifications disabled', 'info');
                }
            });
        }
    }

    updateSoundControlUI() {
        const soundControl = document.getElementById('soundControl');
        if (soundControl) {
            const icon = soundControl.querySelector('i');
            if (this.soundEnabled) {
                soundControl.classList.remove('muted');
                icon.className = 'fas fa-volume-up';
            } else {
                soundControl.classList.add('muted');
                icon.className = 'fas fa-volume-mute';
            }
        }
    }

    showToast(message, type = 'info') {
        // Use SweetAlert2 if available, otherwise use simple alert
        if (typeof Swal !== 'undefined') {
            Swal.fire({
                text: message,
                icon: type,
                toast: true,
                position: 'top-end',
                showConfirmButton: false,
                timer: 3000,
                timerProgressBar: true
            });
        } else {
            console.log(`${type.toUpperCase()}: ${message}`);
        }
    }

    navigateToAppointments() {
        // Navigate to appointments page
        const appointmentsLink = document.querySelector('a[href="#appointments"]');
        if (appointmentsLink) {
            appointmentsLink.click();
        }
    }

    navigateToMessages() {
        // Navigate to messages page
        const messagesLink = document.querySelector('a[href="#messages"]');
        if (messagesLink) {
            messagesLink.click();
        }
    }

    requestNotificationPermission() {
        if ('Notification' in window && Notification.permission === 'default') {
            Notification.requestPermission().then(permission => {
                if (permission === 'granted') {
                    console.log('✅ Notification permission granted');
                    this.showToast('Notifications enabled!', 'success');
                } else {
                    console.log('❌ Notification permission denied');
                    this.showToast('Notifications disabled', 'warning');
                }
            });
        }
    }

    stop() {
        if (this.checkInterval) {
            clearInterval(this.checkInterval);
            this.checkInterval = null;
        }
        console.log('🔇 Notification Service stopped');
    }

    // Public method to manually check for new notifications
    refresh() {
        this.checkForNewAppointments();
        this.checkForNewChatMessages();
    }

    // Public method to get current notification count
    getNotificationCount() {
        return this.notificationCount;
    }

    // Public method to get current chat notification count
    getChatNotificationCount() {
        return this.unreadChatCount;
    }
}

// Initialize notification service when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.notificationService = new NotificationService();
    
    // Request notification permission on first load
    setTimeout(() => {
        window.notificationService.requestNotificationPermission();
    }, 2000);
});

// Add CSS for notification toasts
const notificationStyles = `
<style>
.toast-notification {
    background: white;
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    margin-bottom: 10px;
    overflow: hidden;
    animation: slideInRight 0.3s ease-out;
}

.toast-notification.appointment-notification {
    border-left: 4px solid #007bff;
}

.toast-notification.chat-notification {
    border-left: 4px solid #28a745;
}

.toast-header {
    background: #f8f9fa;
    padding: 0.5rem 1rem;
    border-bottom: 1px solid #e0e0e0;
    display: flex;
    align-items: center;
    justify-content: space-between;
}

.toast-body {
    padding: 1rem;
    color: #333;
}

@keyframes slideInRight {
    from {
        transform: translateX(100%);
        opacity: 0;
    }
    to {
        transform: translateX(0);
        opacity: 1;
    }
}

.notification-badge, .chat-notification-badge {
    position: absolute;
    top: -5px;
    right: -5px;
    background: #dc3545;
    color: white;
    border-radius: 50%;
    width: 20px;
    height: 20px;
    display: none;
    align-items: center;
    justify-content: center;
    font-size: 12px;
    font-weight: bold;
}
</style>
`;

document.head.insertAdjacentHTML('beforeend', notificationStyles); 