const fetch = require('node-fetch');

async function testSendMessage() {
    console.log("=== TEST SEND MESSAGE TO LOCAL SERVER ===");
    
    try {
        // Test de connexion au serveur
        console.log("1. Testing server connection...");
        const healthCheck = await fetch('http://localhost:3000/');
        console.log(`Server responds: ${healthCheck.status} ${healthCheck.statusText}`);
        
        // Test d'envoi de message (doit échouer car pas d'authentification)
        console.log("\n2. Testing send message without auth...");
        const response = await fetch('http://localhost:3000/api/chat/conversations/test123/messages', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                message: 'Test message from script'
            })
        });
        
        const result = await response.json();
        console.log(`Response status: ${response.status}`);
        console.log(`Response body:`, result);
        
        if (response.status === 401) {
            console.log("✅ Expected 401 - Authentication required");
        } else {
            console.log("❌ Unexpected response");
        }
        
    } catch (error) {
        console.error("❌ Error:", error.message);
    }
}

testSendMessage().then(() => process.exit(0));
