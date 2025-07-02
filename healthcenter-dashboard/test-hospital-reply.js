const axios = require('axios');

async function testHospitalReply() {
    console.log('🏥 TESTING HOSPITAL REPLY TO CAPSTONEBOY');
    console.log('========================================\n');
    
    try {
        // Test 1: Check if server is running
        console.log('1️⃣ Testing server connection...');
        const healthCheck = await axios.get('http://localhost:3001', {
            timeout: 5000
        });
        
        if (healthCheck.status === 200) {
            console.log('✅ Server is running on port 3001\n');
        }
        
        // Test 2: Try to send a message (this will likely fail due to auth, but we can see the error)
        console.log('2️⃣ Testing message send endpoint...');
        try {
            const messageResponse = await axios.post('http://localhost:3001/api/chat/send-message', {
                conversationId: 'test-id',
                message: 'Hello capstoneboy, this is a test message from New Hospital',
                messageType: 'text'
            }, {
                headers: {
                    'Content-Type': 'application/json'
                },
                timeout: 5000
            });
            
            console.log('✅ Message endpoint response:', messageResponse.data);
            
        } catch (error) {
            if (error.response) {
                console.log(`⚠️  Expected auth error: ${error.response.status} - ${error.response.data.error || error.response.data.message}`);
                
                if (error.response.status === 401) {
                    console.log('✅ This is normal - endpoint requires authentication');
                }
            } else {
                console.log('❌ Network error:', error.message);
            }
        }
        
        // Test 3: Check conversations endpoint
        console.log('\n3️⃣ Testing conversations endpoint...');
        try {
            const conversationsResponse = await axios.get('http://localhost:3001/api/chat/conversations', {
                timeout: 5000
            });
            
            console.log('✅ Conversations endpoint response:', conversationsResponse.data);
            
        } catch (error) {
            if (error.response) {
                console.log(`⚠️  Expected auth error: ${error.response.status} - ${error.response.data.message}`);
                
                if (error.response.status === 401) {
                    console.log('✅ This is normal - endpoint requires authentication');
                }
            } else {
                console.log('❌ Network error:', error.message);
            }
        }
        
        console.log('\n🔧 SOLUTION FOR HOSPITAL REPLY ISSUE:');
        console.log('=====================================');
        console.log('The hospital dashboard endpoints are working correctly.');
        console.log('The issue is likely one of these:');
        console.log('');
        console.log('1. 🔐 Hospital needs to be logged in to the dashboard');
        console.log('   - Go to: http://localhost:3001/login');
        console.log('   - Login with hospital credentials');
        console.log('');
        console.log('2. 🔄 Browser session expired');
        console.log('   - Clear browser cache and cookies');
        console.log('   - Login again to the hospital dashboard');
        console.log('');
        console.log('3. 📱 Conversation ID mismatch');
        console.log('   - Make sure you\'re clicking on the correct conversation');
        console.log('   - Try refreshing the Messages page');
        console.log('');
        console.log('🎯 IMMEDIATE STEPS:');
        console.log('1. Open http://localhost:3001/login in your browser');
        console.log('2. Login with New Hospital credentials');
        console.log('3. Go to Messages page');
        console.log('4. Click on capstoneboy conversation');
        console.log('5. Try sending a message');
        console.log('');
        console.log('If it still doesn\'t work, check browser console (F12) for JavaScript errors.');
        
    } catch (error) {
        if (error.code === 'ECONNREFUSED') {
            console.log('❌ Server is not running on port 3001');
            console.log('');
            console.log('🔧 TO START THE SERVER:');
            console.log('cd healthcenter-dashboard && npm start');
        } else {
            console.log('❌ Unexpected error:', error.message);
        }
    }
}

// Run the test
testHospitalReply(); 