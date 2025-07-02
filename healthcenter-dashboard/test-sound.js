// Test script to verify sound notifications work
console.log('🧪 Testing notification sound system...');

// Create a test notification service
const testNotificationService = {
    soundEnabled: true,
    
    playNotificationSound() {
        console.log('🔊 Testing notification sound...');
        
        // Try multiple sound methods
        this.tryAudioElement();
        this.tryWebAudioAPI();
        this.trySystemBeep();
    },
    
    tryAudioElement() {
        try {
            const audio = new Audio();
            audio.src = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIG2m98OScTgwOUarm7blmGgU7k9n1unEiBC13yO/eizEIHWq+8+OWT';
            audio.volume = 0.5;
            audio.play().then(() => {
                console.log('✅ Audio element test successful');
            }).catch(error => {
                console.log('❌ Audio element test failed:', error);
            });
        } catch (error) {
            console.log('❌ Audio element test error:', error);
        }
    },
    
    tryWebAudioAPI() {
        try {
            const audioContext = new (window.AudioContext || window.webkitAudioContext)();
            const oscillator = audioContext.createOscillator();
            const gainNode = audioContext.createGain();
            
            oscillator.connect(gainNode);
            gainNode.connect(audioContext.destination);
            
            oscillator.frequency.setValueAtTime(800, audioContext.currentTime);
            oscillator.frequency.setValueAtTime(600, audioContext.currentTime + 0.1);
            oscillator.frequency.setValueAtTime(800, audioContext.currentTime + 0.2);
            
            gainNode.gain.setValueAtTime(0.3, audioContext.currentTime);
            gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.3);
            
            oscillator.start(audioContext.currentTime);
            oscillator.stop(audioContext.currentTime + 0.3);
            
            console.log('✅ Web Audio API test successful');
        } catch (error) {
            console.log('❌ Web Audio API test failed:', error);
        }
    },
    
    trySystemBeep() {
        try {
            // Try to play a system beep
            console.log('🔊 Testing system beep...');
            // This is a simple beep sound
            const audio = new Audio();
            audio.src = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIG2m98OScTgwOUarm7blmGgU7k9n1unEiBC13yO/eizEIHWq+8+OWT';
            audio.volume = 0.5;
            audio.play().then(() => {
                console.log('✅ System beep test successful');
            }).catch(error => {
                console.log('❌ System beep test failed:', error);
            });
        } catch (error) {
            console.log('❌ System beep test error:', error);
        }
    }
};

// Test the sound system
console.log('🎵 Starting sound tests...');
testNotificationService.playNotificationSound();

// Export for use in browser console
window.testNotificationService = testNotificationService;
console.log('🧪 Test service available as window.testNotificationService'); 