/**
 * Test script pour vérifier la fonctionnalité d'image de profil
 */

const { initializeApp } = require('firebase/app');
const { getFirestore, doc, getDoc, updateDoc } = require('firebase/firestore');

// Configuration Firebase (utiliser la même que dans app.js)
const firebaseConfig = {
  apiKey: "AIzaSyBqXqXqXqXqXqXqXqXqXqXqXqXqXqXqXqX",
  authDomain: "homecareplus-12345.firebaseapp.com",
  projectId: "homecareplus-12345",
  storageBucket: "homecareplus-12345.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdefghijklmnop"
};

// Initialiser Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function testProfileImage() {
  try {
    console.log('🧪 Testing profile image functionality...');
    
    // Test 1: Vérifier si une clinique existe avec une image de profil
    const testClinicId = 'test-clinic-id'; // Remplacer par un vrai ID de clinique
    const clinicDocRef = doc(db, 'clinics', testClinicId);
    const clinicDoc = await getDoc(clinicDocRef);
    
    if (clinicDoc.exists()) {
      const clinicData = clinicDoc.data();
      console.log('✅ Clinic found:', clinicData.clinicName);
      console.log('📸 Profile image URL:', clinicData.profileImageUrl || 'No image');
      
      // Test 2: Mettre à jour l'image de profil avec une image de test
      const testImageUrl = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
      
      await updateDoc(clinicDocRef, {
        profileImageUrl: testImageUrl,
        updatedAt: new Date()
      });
      
      console.log('✅ Profile image updated successfully');
      
      // Test 3: Vérifier que l'image a été sauvegardée
      const updatedDoc = await getDoc(clinicDocRef);
      const updatedData = updatedDoc.data();
      console.log('✅ Updated profile image URL:', updatedData.profileImageUrl);
      
    } else {
      console.log('❌ Test clinic not found. Please create a test clinic first.');
    }
    
  } catch (error) {
    console.error('❌ Error testing profile image:', error);
  }
}

// Exécuter le test
testProfileImage(); 