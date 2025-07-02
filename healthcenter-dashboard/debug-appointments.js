const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, doc, updateDoc, query, where } = require('firebase/firestore');

// Configuration Firebase
const firebaseConfig = {
    apiKey: "AIzaSyDYaKiltvi2oUAUO_mi4YNtqCpbJ3RbJI8",
    authDomain: "homecare-9f4d0.firebaseapp.com",
    projectId: "homecare-9f4d0",
    storageBucket: "homecare-9f4d0.firebasestorage.app",
    messagingSenderId: "54787084616",
    appId: "1:54787084616:android:7892366bf2029a3908a37d"
};

// Initialiser Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function debugAppointments() {
    console.log('🔍 Debugging appointments...\n');
    
    try {
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        console.log(`Total appointments found: ${appointmentsSnapshot.size}\n`);
        
        const hospitalCounts = {};
        let kingHospitalAppointments = [];
        
        for (const docSnapshot of appointmentsSnapshot.docs) {
            const appointment = { id: docSnapshot.id, ...docSnapshot.data() };
            
            // Count by hospital
            const hospital = appointment.hospital || appointment.hospitalName || 'Unknown';
            hospitalCounts[hospital] = (hospitalCounts[hospital] || 0) + 1;
            
            // Collect king Hospital appointments
            if (hospital === 'king Hospital') {
                kingHospitalAppointments.push(appointment);
            }
            
            // Show first few appointments structure
            if (Object.keys(hospitalCounts).length <= 5) {
                console.log(`📋 Appointment ${appointment.id}:`);
                console.log(`   Hospital: ${hospital}`);
                console.log(`   Patient: ${appointment.patientName || appointment.patient || 'Unknown'}`);
                console.log(`   Service: ${appointment.service || appointment.department || 'Unknown'}`);
                console.log(`   Status: ${appointment.status || 'Unknown'}`);
                console.log(`   Date: ${appointment.appointmentDate ? new Date(appointment.appointmentDate.seconds * 1000).toLocaleDateString() : 'Unknown'}`);
                console.log('');
            }
        }
        
        console.log('📊 Hospital breakdown:');
        for (const [hospital, count] of Object.entries(hospitalCounts)) {
            console.log(`   ${hospital}: ${count} appointments`);
        }
        
        console.log(`\n👑 King Hospital appointments: ${kingHospitalAppointments.length}`);
        
        if (kingHospitalAppointments.length > 0) {
            console.log('\n📋 King Hospital appointment details:');
            kingHospitalAppointments.forEach((appointment, index) => {
                console.log(`   ${index + 1}. ${appointment.patientName || 'Unknown'} - ${appointment.service || 'Unknown service'} (${appointment.status || 'Unknown status'})`);
            });
        }
        
    } catch (error) {
        console.error('❌ Error debugging appointments:', error);
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