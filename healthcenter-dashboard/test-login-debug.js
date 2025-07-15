const { auth, db, signInWithEmailAndPassword, createUserWithEmailAndPassword, setDoc, doc, getDoc } = require("./config/firebase");

async function testLoginDebug() {
  try {
    console.log('🔍 === DIAGNOSTIC DE CONNEXION HOSPITAL DASHBOARD ===\n');
    
    // Test 1: Créer un compte test pour les cliniques
    console.log('📝 Test 1: Création d\'un compte test...');
    const testEmail = 'test-clinic@example.com';
    const testPassword = 'test123456';
    
    try {
      // Essayer de créer un nouveau compte
      const userCredential = await createUserWithEmailAndPassword(auth, testEmail, testPassword);
      const user = userCredential.user;
      
      console.log('✅ Compte créé avec UID:', user.uid);
      
      // Créer les données de la clinique dans Firestore
      const clinicData = {
        clinicName: 'Test Clinic',
        name: 'Test Clinic',
        email: testEmail,
        about: 'Clinique de test pour diagnostic',
        address: 'Test Address',
        phone: '123-456-7890',
        facilities: ['General Medicine'],
        isVerified: false,
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date(),
        availableSchedule: {
          'Monday': {'start': '08:00', 'end': '17:00'},
          'Tuesday': {'start': '08:00', 'end': '17:00'},
          'Wednesday': {'start': '08:00', 'end': '17:00'},
          'Thursday': {'start': '08:00', 'end': '17:00'},
          'Friday': {'start': '08:00', 'end': '17:00'},
          'Saturday': {'start': '09:00', 'end': '15:00'},
          'Sunday': {'start': 'Closed', 'end': 'Closed'},
        }
      };
      
      await setDoc(doc(db, "clinics", user.uid), clinicData);
      console.log('✅ Données de la clinique créées dans Firestore');
      
    } catch (error) {
      if (error.code === 'auth/email-already-in-use') {
        console.log('ℹ️ Le compte test existe déjà');
      } else {
        console.error('❌ Erreur création compte:', error.message);
      }
    }
    
    // Test 2: Tester la connexion avec le compte test
    console.log('\n🔐 Test 2: Test de connexion...');
    try {
      const userCredential = await signInWithEmailAndPassword(auth, testEmail, testPassword);
      const user = userCredential.user;
      
      console.log('✅ Connexion Firebase Auth réussie pour:', user.email);
      
      // Vérifier les données dans Firestore
      const clinicDoc = await getDoc(doc(db, 'clinics', user.uid));
      if (clinicDoc.exists()) {
        console.log('✅ Données clinique trouvées dans Firestore');
        const clinicData = clinicDoc.data();
        console.log('📋 Nom de la clinique:', clinicData.name || clinicData.clinicName);
      } else {
        console.log('❌ Données clinique NON TROUVÉES dans Firestore');
      }
      
    } catch (error) {
      console.error('❌ Erreur de connexion:', error.message);
    }
    
    // Test 3: Vérifier un compte existant
    console.log('\n🔍 Test 3: Vérifier vos identifiants...');
    console.log('Pour tester votre compte existant, entrez vos identifiants ci-dessous:');
    
    // Instructions pour l'utilisateur
    console.log('\n📋 INSTRUCTIONS POUR TESTER VOTRE COMPTE:');
    console.log('1. Modifiez ce script en remplaçant les identifiants test');
    console.log('2. Remplacez testEmail par votre vrai email');
    console.log('3. Remplacez testPassword par votre vrai mot de passe');
    console.log('4. Relancez le script: node test-login-debug.js');
    
    console.log('\n✅ COMPTE TEST CRÉÉ:');
    console.log('📧 Email: test-clinic@example.com');
    console.log('🔑 Mot de passe: test123456');
    console.log('🌐 URL: https://dynamic-color-production.up.railway.app');
    
  } catch (error) {
    console.error('❌ Erreur générale:', error);
  }
}

// Fonction pour tester un compte spécifique
async function testSpecificAccount(email, password) {
  try {
    console.log(`\n🔐 Test de connexion pour: ${email}`);
    
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;
    
    console.log('✅ Connexion Firebase Auth réussie');
    
    // Vérifier dans la collection clinics
    const clinicDoc = await getDoc(doc(db, 'clinics', user.uid));
    if (clinicDoc.exists()) {
      console.log('✅ Compte clinique trouvé');
      const clinicData = clinicDoc.data();
      console.log('📋 Nom:', clinicData.name || clinicData.clinicName);
      console.log('📋 Status:', clinicData.status);
      return true;
    } else {
      console.log('❌ Compte clinique NON TROUVÉ dans Firestore');
      console.log('💡 Ce compte existe dans Firebase Auth mais pas dans la collection clinics');
      console.log('💡 C\'est probablement un compte patient, pas un compte clinique');
      return false;
    }
    
  } catch (error) {
    console.error('❌ Erreur de connexion:', error.message);
    return false;
  }
}

testLoginDebug();

module.exports = { testSpecificAccount }; 