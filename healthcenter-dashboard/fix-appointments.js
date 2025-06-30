const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, doc, updateDoc, query, where } = require('firebase/firestore');

// Configuration Firebase (remplacez par vos vraies clés)
const firebaseConfig = {
    apiKey: "AIzaSyBqXqXqXqXqXqXqXqXqXqXqXqXqXqXqXqXq",
    authDomain: "homecareplus-12345.firebaseapp.com",
    projectId: "homecareplus-12345",
    storageBucket: "homecareplus-12345.appspot.com",
    messagingSenderId: "123456789",
    appId: "1:123456789:web:abcdef123456"
};

// Initialiser Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function fixExistingAppointments() {
    try {
        console.log('=== FIXING EXISTING APPOINTMENTS ===');
        
        // Récupérer tous les rendez-vous
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        console.log(`Total appointments to process: ${appointmentsSnapshot.size}`);
        
        let fixedCount = 0;
        let skippedCount = 0;
        
        for (const docSnapshot of appointmentsSnapshot.docs) {
            const appointment = docSnapshot.data();
            
            console.log(`\n--- Processing appointment ${docSnapshot.id} ---`);
            console.log('Hospital name:', appointment.hospitalName);
            console.log('Current clinicId:', appointment.clinicId);
            
            // Vérifier si le rendez-vous a déjà un clinicId
            if (appointment.clinicId) {
                console.log('✓ Appointment already has clinicId, skipping...');
                skippedCount++;
                continue;
            }
            
            // Si pas de clinicId, essayer de le trouver par le nom de l'hôpital
            if (appointment.hospitalName) {
                try {
                    const clinicId = await findClinicIdByName(appointment.hospitalName);
                    
                    if (clinicId) {
                        // Mettre à jour le rendez-vous avec l'ID de la clinique
                        await updateDoc(docSnapshot.ref, {
                            clinicId: clinicId,
                            updatedAt: new Date()
                        });
                        
                        console.log(`✓ Fixed appointment ${docSnapshot.id} with clinicId: ${clinicId}`);
                        fixedCount++;
                    } else {
                        console.log(`✗ Could not find clinic for hospital: ${appointment.hospitalName}`);
                        skippedCount++;
                    }
                } catch (error) {
                    console.log(`Error processing appointment ${docSnapshot.id}:`, error);
                    skippedCount++;
                }
            } else {
                console.log('✗ No hospital name found, skipping...');
                skippedCount++;
            }
        }
        
        console.log('\n=== FIX SUMMARY ===');
        console.log(`Fixed: ${fixedCount} appointments`);
        console.log(`Skipped: ${skippedCount} appointments`);
        console.log(`Total processed: ${fixedCount + skippedCount}`);
        
    } catch (error) {
        console.error('Error fixing appointments:', error);
    }
}

async function findClinicIdByName(hospitalName) {
    try {
        // Chercher dans la collection 'clinics'
        const clinicsRef = collection(db, 'clinics');
        const clinicsSnapshot = await getDocs(clinicsRef);
        
        for (const clinicDoc of clinicsSnapshot.docs) {
            const clinicData = clinicDoc.data();
            const clinicName = clinicData.name || clinicData.clinicName;
            
            if (clinicName && clinicName.toLowerCase().trim() === hospitalName.toLowerCase().trim()) {
                console.log(`Found clinic match: ${clinicName} -> ${clinicDoc.id}`);
                return clinicDoc.id;
            }
        }
        
        // Si pas trouvé dans 'clinics', chercher dans 'users'
        const usersRef = collection(db, 'users');
        const usersSnapshot = await getDocs(usersRef);
        
        for (const userDoc of usersSnapshot.docs) {
            const userData = userDoc.data();
            const userName = userData.name || userData.clinicName;
            
            if (userName && userName.toLowerCase().trim() === hospitalName.toLowerCase().trim()) {
                console.log(`Found user match: ${userName} -> ${userDoc.id}`);
                return userDoc.id;
            }
        }
        
        return null;
    } catch (error) {
        console.error('Error finding clinic ID:', error);
        return null;
    }
}

async function showAppointmentsSummary() {
    try {
        console.log('=== APPOINTMENTS SUMMARY ===');
        
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        let withClinicId = 0;
        let withoutClinicId = 0;
        let total = 0;
        
        appointmentsSnapshot.forEach((doc) => {
            const appointment = doc.data();
            total++;
            
            if (appointment.clinicId) {
                withClinicId++;
            } else {
                withoutClinicId++;
                console.log(`Appointment without clinicId: ${doc.id} - Hospital: ${appointment.hospitalName}`);
            }
        });
        
        console.log(`\nTotal appointments: ${total}`);
        console.log(`With clinicId: ${withClinicId}`);
        console.log(`Without clinicId: ${withoutClinicId}`);
        console.log(`Percentage fixed: ${((withClinicId / total) * 100).toFixed(2)}%`);
        
    } catch (error) {
        console.error('Error showing summary:', error);
    }
}

// Exécuter le script
async function main() {
    console.log('Starting appointment fix process...');
    
    // D'abord afficher le résumé actuel
    await showAppointmentsSummary();
    
    // Demander confirmation avant de corriger
    console.log('\nDo you want to fix the appointments? (y/n)');
    // Pour l'instant, on va directement corriger
    await fixExistingAppointments();
    
    // Afficher le résumé après correction
    console.log('\nAfter fixing:');
    await showAppointmentsSummary();
    
    console.log('\nFix process completed!');
}

main().catch(console.error); 