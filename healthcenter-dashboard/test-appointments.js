const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs } = require('firebase/firestore');

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

async function testAppointments() {
    try {
        console.log('=== TESTING APPOINTMENTS ===');
        
        // Récupérer tous les rendez-vous
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        console.log(`Total appointments: ${appointmentsSnapshot.size}`);
        
        let appointmentCount = 0;
        appointmentsSnapshot.forEach((docSnapshot) => {
            appointmentCount++;
            const appointment = docSnapshot.data();
            
            console.log(`\n--- Appointment ${appointmentCount}: ${docSnapshot.id} ---`);
            console.log('Hospital Name:', appointment.hospitalName);
            console.log('Clinic ID:', appointment.clinicId);
            console.log('Date:', appointment.date);
            console.log('Appointment Date:', appointment.appointmentDate);
            console.log('Status:', appointment.status);
            console.log('Patient Name:', appointment.patientName);
            
            // Vérifier si c'est un rendez-vous récent
            const hasDate = appointment.date || appointment.appointmentDate;
            const hasStatus = appointment.status;
            const hasHospital = appointment.hospitalName;
            
            console.log('Has Date:', !!hasDate);
            console.log('Has Status:', !!hasStatus);
            console.log('Has Hospital:', !!hasHospital);
            
            if (hasHospital && hasStatus) {
                console.log('✅ This appointment should be visible');
            } else {
                console.log('❌ This appointment has missing data');
            }
        });
        
        console.log('\n=== TEST SUMMARY ===');
        console.log(`Total appointments analyzed: ${appointmentCount}`);
        
    } catch (error) {
        console.error('Error testing appointments:', error);
    }
}

// Exécuter le test
testAppointments().then(() => {
    console.log('Test completed!');
    process.exit(0);
}).catch(console.error); 