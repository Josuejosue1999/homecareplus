const { testSpecificAccount } = require('./test-login-debug');

// 🔧 REMPLACEZ CES IDENTIFIANTS PAR LES VÔTRES
const YOUR_EMAIL = 'votre-email@example.com';  // ⬅️ CHANGEZ ICI
const YOUR_PASSWORD = 'votre-mot-de-passe';    // ⬅️ CHANGEZ ICI

async function testYourAccount() {
  console.log('🔍 === TEST DE VOTRE COMPTE PERSONNEL ===\n');
  
  if (YOUR_EMAIL === 'votre-email@example.com') {
    console.log('⚠️ ATTENTION: Vous devez modifier ce script !');
    console.log('📝 Éditez ce fichier et remplacez:');
    console.log('   - YOUR_EMAIL par votre vrai email');
    console.log('   - YOUR_PASSWORD par votre vrai mot de passe');
    console.log('\n🔧 Puis relancez: node test-user-account.js');
    return;
  }
  
  console.log(`📧 Test du compte: ${YOUR_EMAIL}`);
  console.log('🔐 Test du mot de passe: [MASQUÉ]');
  
  const success = await testSpecificAccount(YOUR_EMAIL, YOUR_PASSWORD);
  
  if (success) {
    console.log('\n✅ VOTRE COMPTE FONCTIONNE !');
    console.log('🌐 Connectez-vous sur: https://dynamic-color-production.up.railway.app');
  } else {
    console.log('\n❌ PROBLÈME IDENTIFIÉ !');
    console.log('\n🔧 SOLUTIONS:');
    console.log('1. Vérifiez vos identifiants (email/mot de passe)');
    console.log('2. Votre compte est peut-être un compte PATIENT, pas CLINIQUE');
    console.log('3. Créez un nouveau compte clinique via le formulaire d\'inscription');
    console.log('\n📝 Pour créer un compte clinique:');
    console.log('   1. Allez sur: https://dynamic-color-production.up.railway.app/register');
    console.log('   2. Créez un nouveau compte avec un email différent');
    console.log('   3. Utilisez ce nouveau compte pour vous connecter');
  }
}

testYourAccount(); 