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
        this.init();
    }

    init() {
        console.log('🔔 Initializing notification service...');
        
        // Load sound preference from localStorage
        this.soundEnabled = localStorage.getItem('notificationSoundEnabled') !== 'false';
        console.log('🔊 Sound enabled:', this.soundEnabled);
        
        // Initialize notification elements
        this.notificationBell = document.getElementById('notificationBell');
        this.notificationCount = document.getElementById('notificationCount');
        this.notificationContainer = document.getElementById('notificationContainer');
        this.soundControl = document.getElementById('soundControl');
        
        // Set up sound control
        this.setupSoundControl();
        
        // Start checking for new appointments
        this.startPolling();
        
        // Enable audio on first user interaction
        this.enableAudioOnInteraction();
    }

    setupSoundControl() {
        if (!this.soundControl) return;
        
        // Update sound control icon
        this.updateSoundControlIcon();
        
        // Add click event
        this.soundControl.addEventListener('click', () => {
            this.toggleSound();
        });
    }

    updateSoundControlIcon() {
        if (!this.soundControl) return;
        
        const icon = this.soundControl.querySelector('i');
        if (icon) {
            icon.className = this.soundEnabled ? 'fas fa-volume-up' : 'fas fa-volume-mute';
        }
    }

    toggleSound() {
        this.soundEnabled = !this.soundEnabled;
        localStorage.setItem('notificationSoundEnabled', this.soundEnabled.toString());
        this.updateSoundControlIcon();
        
        console.log('🔊 Sound toggled:', this.soundEnabled ? 'ON' : 'OFF');
        
        // Show feedback
        this.showToastNotification({
            patientName: 'Sound ' + (this.soundEnabled ? 'Enabled' : 'Disabled'),
            appointmentDate: { seconds: Math.floor(Date.now() / 1000) }
        });
    }

    setupNotificationBell() {
        if (!this.notificationBell) return;
        
        // Add click event to show notifications
        this.notificationBell.addEventListener('click', () => {
            this.showNotificationHistory();
        });
    }

    startPolling() {
        console.log('🔄 Starting appointment and chat polling...');
        
        // Check immediately
        this.checkForNewAppointments();
        this.checkForNewChatMessages();
        
        // Then check every 10 seconds
        this.pollingInterval = setInterval(() => {
            this.checkForNewAppointments();
            this.checkForNewChatMessages();
        }, 10000);
    }

    async checkForNewAppointments() {
        try {
            console.log('🔍 Checking for new appointments...');
            const response = await fetch('/api/appointments/clinic-appointments');
            if (response.ok) {
                const data = await response.json();
                if (data.success && data.appointments) {
                    console.log(`📋 Found ${data.appointments.length} appointments`);
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
            const response = await fetch('/api/chat/clinic-conversations');
            if (response.ok) {
                const data = await response.json();
                if (data.success && data.conversations) {
                    console.log(`💬 Found ${data.conversations.length} conversations`);
                    this.processChatMessages(data.conversations);
                }
            }
        } catch (error) {
            console.error('Error checking for new chat messages:', error);
        }
    }

    processAppointments(appointments) {
        if (!appointments || appointments.length === 0) return;

        console.log('🔍 Processing appointments for notifications...');
        
        // Find the most recent appointment
        const latestAppointment = appointments.reduce((latest, current) => {
            const latestDate = latest.appointmentDate || latest.date;
            const currentDate = current.appointmentDate || current.date;
            
            if (!latestDate) return current;
            if (!currentDate) return latest;
            
            return new Date(currentDate.seconds * 1000) > new Date(latestDate.seconds * 1000) ? current : latest;
        });

        console.log('🔍 Latest appointment ID:', latestAppointment.id);
        console.log('🔍 Latest appointment date:', latestAppointment.appointmentDate || latestAppointment.date);
        
        // Check if this is a new appointment (within last 10 minutes)
        const appointmentTime = latestAppointment.appointmentDate || latestAppointment.date;
        if (!appointmentTime) {
            console.log('❌ No appointment date found');
            return;
        }

        const appointmentDate = new Date(appointmentTime.seconds * 1000);
        const now = new Date();
        const timeDiff = now.getTime() - appointmentDate.getTime();
        const minutesDiff = timeDiff / (1000 * 60);

        console.log('⏰ Appointment time:', appointmentDate);
        console.log('⏰ Current time:', now);
        console.log('⏰ Time difference (minutes):', minutesDiff);

        // Check if appointment is recent (within 10 minutes) and not already processed
        if (minutesDiff <= 10 && minutesDiff >= 0) {
            const appointmentId = latestAppointment.id;
            
            // Check if we've already processed this appointment
            if (!this.processedAppointments.has(appointmentId)) {
                console.log('🎉 NEW APPOINTMENT DETECTED!');
                console.log('📋 Appointment details:', latestAppointment);
                
                // Mark as processed
                this.processedAppointments.add(appointmentId);
                
                // Show notification
                this.showAppointmentNotification(latestAppointment);
            } else {
                console.log('✅ Appointment already processed:', appointmentId);
            }
        } else {
            console.log('⏰ Appointment is not recent enough or in the future');
        }
    }

    processChatMessages(conversations) {
        if (!conversations || conversations.length === 0) return;

        console.log('💬 Processing conversations for notifications...');

        conversations.forEach(conversation => {
            // Check if there are unread messages
            if (conversation.hasUnreadMessages && conversation.unreadCount > 0) {
                const conversationId = conversation.id;
                
                // Check if we've already processed this conversation's latest message
                const lastMessageKey = `chat_${conversationId}_${conversation.lastMessageTime}`;
                
                if (!this.processedAppointments.has(lastMessageKey)) {
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
        console.log('🔔 Showing appointment notification for:', appointment);
        
        // Play notification sound
        this.playNotificationSound();
        
        // Animate notification bell
        this.animateNotificationBell();
        
        // Show toast notification
        this.showToastNotification(appointment);
        
        // Update notification count
        this.updateNotificationCount();
        
        // Refresh appointments list if on appointments page
        if (window.dashboardAppointments) {
            window.dashboardAppointments.refresh();
        }
    }

    showChatNotification(conversation) {
        console.log('💬 Showing chat notification for:', conversation);
        
        // Play notification sound
        this.playNotificationSound();
        
        // Animate notification bell
        this.animateNotificationBell();
        
        // Show toast notification for chat
        this.showChatToastNotification(conversation);
        
        // Update notification count
        this.updateNotificationCount();
        
        // Update chat badge if chat interface exists
        this.updateChatBadge();
    }

    playNotificationSound() {
        if (!this.soundEnabled) {
            console.log('🔇 Sound is disabled, skipping notification sound');
            return;
        }
        
        try {
            console.log('🔊 Attempting to play notification sound...');
            
            // Try to play the appointment sound first
            const appointmentSound = document.getElementById('appointmentSound');
            if (appointmentSound) {
                console.log('🎵 Playing appointment sound...');
                appointmentSound.currentTime = 0;
                appointmentSound.volume = 0.8;
                
                // Ensure audio context is resumed (required by modern browsers)
                if (appointmentSound.audioContext && appointmentSound.audioContext.state === 'suspended') {
                    appointmentSound.audioContext.resume();
                }
                
                const playPromise = appointmentSound.play();
                if (playPromise !== undefined) {
                    playPromise
                        .then(() => {
                            console.log('✅ Appointment sound played successfully');
                        })
                        .catch(error => {
                            console.error('❌ Error playing appointment sound:', error);
                            this.tryWebAudioAPI();
                        });
                }
            } else {
                console.log('⚠️ Appointment sound element not found, trying Web Audio API...');
                this.tryWebAudioAPI();
            }
        } catch (error) {
            console.error('❌ Error in playNotificationSound:', error);
            this.tryWebAudioAPI();
        }
    }

    tryWebAudioAPI() {
        try {
            console.log('🎵 Trying Web Audio API...');
            
            // Create audio context
            const audioContext = new (window.AudioContext || window.webkitAudioContext)();
            
            // Create oscillator for beep sound
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();
            
            oscillator.connect(gainNode);
            gainNode.connect(audioContext.destination);
            
            // Configure sound
            oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
            oscillator.type = 'sine';
            
            gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
            gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
            
            // Play 3 beeps
            for (let i = 0; i < 3; i++) {
                setTimeout(() => {
                    oscillator.start(audioContext.currentTime);
                    oscillator.stop(audioContext.currentTime + 0.3);
                }, i * 400);
            }
            
            console.log('✅ Web Audio API beep played successfully');
        } catch (error) {
            console.error('❌ Error with Web Audio API:', error);
            this.trySystemBeep();
        }
    }

    trySystemBeep() {
        try {
            console.log('🔊 Playing system beep...');
            // Create a simple beep using the system
            const audio = new Audio();
            audio.src = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIG2m98OScTgwOUarm7blmGgU7k9n1unEiBC13yO/eizEIHWq+8+OWT';
            audio.volume = 0.5;
            audio.play().then(() => {
                console.log('✅ System beep played successfully');
            }).catch(error => {
                console.error('❌ System beep failed:', error);
            });
        } catch (error) {
            console.error('❌ All sound methods failed:', error);
        }
    }

    animateNotificationBell() {
        const notificationBell = document.getElementById('notificationBell');
        if (notificationBell) {
            notificationBell.classList.add('ringing');
            setTimeout(() => {
                notificationBell.classList.remove('ringing');
            }, 500);
        }
    }

    showToastNotification(appointment) {
        const container = document.getElementById('notificationContainer');
        if (!container) return;

        const toast = document.createElement('div');
        toast.className = 'notification-toast appointment';
        
        const patientName = appointment.patientName || 'Unknown Patient';
        const hospitalName = appointment.hospitalName || 'Your Clinic';
        const department = appointment.department || 'General';
        const appointmentTime = appointment.appointmentTime || 'TBD';
        
        toast.innerHTML = `
            <div class="notification-toast-header">
                <div class="notification-toast-title">
                    <i class="fas fa-calendar-plus"></i>
                    New Appointment
                </div>
                <button class="notification-toast-close" onclick="this.parentElement.parentElement.remove()">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="notification-toast-message">
                <strong>${patientName}</strong> has booked an appointment for <strong>${department}</strong> at <strong>${appointmentTime}</strong>
            </div>
            <div class="notification-toast-time">
                ${new Date().toLocaleTimeString()}
            </div>
        `;

        container.appendChild(toast);
        
        // Show animation
        setTimeout(() => {
            toast.classList.add('show');
        }, 100);

        // Auto remove after 8 seconds
        setTimeout(() => {
            if (toast.parentElement) {
                toast.classList.remove('show');
                setTimeout(() => {
                    if (toast.parentElement) {
                        toast.remove();
                    }
                }, 300);
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
                <button class="btn-view-chat" onclick="window.open('/chat/${conversation.id}', '_blank')">
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

    updateNotificationCount() {
        this.notificationCount++;
        const badge = document.getElementById('notificationCount');
        if (badge) {
            badge.textContent = this.notificationCount;
            badge.style.display = this.notificationCount > 0 ? 'block' : 'none';
        }
    }

    updateChatBadge() {
        const chatBadge = document.getElementById('chatBadge');
        const chatIcon = document.getElementById('chatIcon');
        
        if (chatBadge && chatIcon) {
            // You can add logic here to count total unread chat messages
            // For now, just indicate there are new messages
            chatBadge.style.display = 'block';
            chatIcon.classList.add('has-notification');
        }
    }

    showNotificationHistory() {
        // This could show a dropdown with recent notifications
        console.log('📋 Showing notification history...');
    }

    // Method to manually trigger notification (for testing)
    testNotification() {
        const testAppointment = {
            id: 'test-' + Date.now(),
            patientName: 'Test Patient',
            hospitalName: 'Test Hospital',
            department: 'General Medicine',
            appointmentTime: '10:00 AM'
        };
        
        this.showAppointmentNotification(testAppointment);
    }

    // Cleanup method
    destroy() {
        if (this.checkInterval) {
            clearInterval(this.checkInterval);
        }
    }

    enableAudioOnInteraction() {
        const enableAudio = () => {
            console.log('🎵 Enabling audio on user interaction...');
            
            // Resume any suspended audio contexts
            if (window.AudioContext || window.webkitAudioContext) {
                const audioContext = new (window.AudioContext || window.webkitAudioContext)();
                if (audioContext.state === 'suspended') {
                    audioContext.resume();
                }
            }
            
            // Remove event listeners after first interaction
            document.removeEventListener('click', enableAudio);
            document.removeEventListener('keydown', enableAudio);
            document.removeEventListener('touchstart', enableAudio);
        };
        
        // Add event listeners for user interaction
        document.addEventListener('click', enableAudio, { once: true });
        document.addEventListener('keydown', enableAudio, { once: true });
        document.addEventListener('touchstart', enableAudio, { once: true });
    }
}

// Initialize notification service when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.notificationService = new NotificationService();
});

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = NotificationService;
} 