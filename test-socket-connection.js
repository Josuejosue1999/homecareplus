const io = require('socket.io-client');

console.log('🔌 Testing Socket.IO connection...');

const socket = io('http://localhost:3000');

socket.on('connect', () => {
    console.log('✅ Socket.IO connected successfully!');
    console.log('🆔 Socket ID:', socket.id);
    
    // Test joining a hospital room
    socket.emit('join-hospital', 'test-hospital-123');
    console.log('🏥 Joined hospital room');
    
    // Disconnect after test
    setTimeout(() => {
        socket.disconnect();
        console.log('👋 Socket disconnected');
        process.exit(0);
    }, 2000);
});

socket.on('connect_error', (error) => {
    console.error('❌ Socket.IO connection failed:', error.message);
    process.exit(1);
});

socket.on('disconnect', (reason) => {
    console.log('🔌 Socket disconnected:', reason);
});

// Timeout after 10 seconds
setTimeout(() => {
    console.error('❌ Connection timeout');
    process.exit(1);
}, 10000); 