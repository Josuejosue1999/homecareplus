const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, doc, updateDoc } = require('firebase/firestore');

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

async function quickFix() {
    try {
        console.log('=== QUICK FIX FOR APPOINTMENTS ===');
        
        // Récupérer tous les rendez-vous
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        console.log(`Total appointments: ${appointmentsSnapshot.size}`);
        
        let fixedCount = 0;
        
        for (const docSnapshot of appointmentsSnapshot.docs) {
            const appointment = docSnapshot.data();
            
            // Vérifier si le rendez-vous a besoin d'être corrigé
            const needsFix = !appointment.clinicId && appointment.hospitalName;
            
            if (needsFix) {
                console.log(`Fixing appointment ${docSnapshot.id} with hospital: ${appointment.hospitalName}`);
                
                // Trouver l'ID de la clinique par le nom
                const clinicId = await findClinicIdByName(appointment.hospitalName);
                
                if (clinicId) {
                    // Mettre à jour le rendez-vous
                    await updateDoc(docSnapshot.ref, {
                        clinicId: clinicId,
                        updatedAt: new Date()
                    });
                    
                    console.log(`✓ Fixed appointment ${docSnapshot.id} with clinicId: ${clinicId}`);
                    fixedCount++;
                } else {
                    console.log(`✗ Could not find clinic for: ${appointment.hospitalName}`);
                }
            }
        }
        
        console.log(`\n=== FIX COMPLETED ===`);
        console.log(`Fixed: ${fixedCount} appointments`);
        
    } catch (error) {
        console.error('Error in quick fix:', error);
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
                return clinicDoc.id;
            }
        }
        
        return null;
    } catch (error) {
        console.error('Error finding clinic ID:', error);
        return null;
    }
}

// Exécuter le script
quickFix().then(() => {
    console.log('Quick fix completed!');
    process.exit(0);
}).catch(console.error); 