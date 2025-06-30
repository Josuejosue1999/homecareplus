const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, doc, updateDoc, query, where } = require('firebase/firestore');

// Configuration Firebase
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

async function debugAppointments() {
    try {
        console.log('=== DEBUGGING APPOINTMENTS ===');
        
        // Récupérer tous les rendez-vous
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        console.log(`Total appointments: ${appointmentsSnapshot.size}`);
        
        let appointmentCount = 0;
        appointmentsSnapshot.forEach((docSnapshot) => {
            appointmentCount++;
            const appointment = docSnapshot.data();
            
            console.log(`\n--- Appointment ${appointmentCount}: ${docSnapshot.id} ---`);
            console.log('Data:', JSON.stringify(appointment, null, 2));
            
            // Vérifier les champs importants
            const hasClinicId = appointment.clinicId || appointment.clinic_id;
            const hasHospital = appointment.hospital || appointment.hospitalName;
            const hasClinicName = appointment.clinicName;
            const hasDate = appointment.date;
            const hasStatus = appointment.status;
            
            console.log('Fields check:');
            console.log(`  - clinicId/clinic_id: ${hasClinicId ? '✓' : '✗'} (${appointment.clinicId || appointment.clinic_id || 'undefined'})`);
            console.log(`  - hospital/hospitalName: ${hasHospital ? '✓' : '✗'} (${appointment.hospital || appointment.hospitalName || 'undefined'})`);
            console.log(`  - clinicName: ${hasClinicName ? '✓' : '✗'} (${appointment.clinicName || 'undefined'})`);
            console.log(`  - date: ${hasDate ? '✓' : '✗'} (${appointment.date || 'undefined'})`);
            console.log(`  - status: ${hasStatus ? '✓' : '✗'} (${appointment.status || 'undefined'})`);
            
            if (!hasClinicId && !hasHospital && !hasClinicName) {
                console.log('  ⚠️  WARNING: This appointment has no clinic identification!');
            }
        });
        
        console.log('\n=== SUMMARY ===');
        console.log(`Total appointments analyzed: ${appointmentCount}`);
        
    } catch (error) {
        console.error('Error debugging appointments:', error);
    }
}

async function fixAppointments() {
    try {
        console.log('=== FIXING APPOINTMENTS ===');
        
        // Récupérer tous les rendez-vous
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        let fixedCount = 0;
        
        for (const docSnapshot of appointmentsSnapshot.docs) {
            const appointment = docSnapshot.data();
            
            // Vérifier si le rendez-vous a besoin d'être corrigé
            const needsFix = !appointment.clinicId && !appointment.clinic_id && 
                           !appointment.hospital && !appointment.hospitalName && 
                           !appointment.clinicName;
            
            if (needsFix) {
                console.log(`Fixing appointment ${docSnapshot.id}...`);
                
                // Essayer de déterminer la clinique à partir d'autres champs
                let clinicId = null;
                let hospitalName = null;
                
                // Si on a un userId, on peut essayer de trouver la clinique
                if (appointment.userId) {
                    try {
                        const userDocRef = doc(db, 'users', appointment.userId);
                        const userDoc = await getDocs(userDocRef);
                        if (userDoc.exists()) {
                            const userData = userDoc.data();
                            clinicId = appointment.userId;
                            hospitalName = userData.clinicName || userData.name || 'Unknown Clinic';
                        }
                    } catch (error) {
                        console.log(`Could not find user data for ${appointment.userId}`);
                    }
                }
                
                // Mettre à jour le rendez-vous avec les bonnes informations
                const updateData = {};
                if (clinicId) updateData.clinicId = clinicId;
                if (hospitalName) updateData.hospital = hospitalName;
                if (hospitalName) updateData.clinicName = hospitalName;
                
                if (Object.keys(updateData).length > 0) {
                    await updateDoc(docSnapshot.ref, updateData);
                    console.log(`✓ Fixed appointment ${docSnapshot.id} with:`, updateData);
                    fixedCount++;
                } else {
                    console.log(`✗ Could not fix appointment ${docSnapshot.id} - no clinic info found`);
                }
            }
        }
        
        console.log(`\n=== FIX SUMMARY ===`);
        console.log(`Fixed ${fixedCount} appointments`);
        
    } catch (error) {
        console.error('Error fixing appointments:', error);
    }
}

// Exécuter le debug
debugAppointments().then(() => {
    console.log('\nDebug completed. Run fixAppointments() if needed.');
});

// Décommenter la ligne suivante pour corriger les rendez-vous
// fixAppointments(); 