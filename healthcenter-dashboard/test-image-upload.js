/**
 * Test script pour vérifier la route de sauvegarde d'image de profil
 */

const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

async function testImageUpload() {
    try {
        console.log('🧪 Testing profile image upload route...');
        
        // Image de test (1x1 pixel PNG en base64)
        const testImageData = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
        
        console.log('Image data length:', testImageData.length);
        
        // Test de la route (sans authentification pour l'instant)
        const response = await fetch('http://localhost:3001/api/settings/profile-image', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ 
                profileImageUrl: testImageData 
            })
        });
        
        console.log('Response status:', response.status);
        console.log('Response ok:', response.ok);
        
        if (!response.ok) {
            const errorText = await response.text();
            console.log('Error response:', errorText);
        } else {
            const result = await response.json();
            console.log('Success response:', result);
        }
        
    } catch (error) {
        console.error('❌ Error testing image upload:', error);
    }
}

// Exécuter le test
testImageUpload(); 