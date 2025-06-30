const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, doc, getDoc } = require('firebase/firestore');

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

async function testAppointmentDetails() {
    try {
        console.log('=== TESTING APPOINTMENT DETAILS ===');
        
        // Récupérer tous les rendez-vous
        const appointmentsRef = collection(db, 'appointments');
        const appointmentsSnapshot = await getDocs(appointmentsRef);
        
        console.log(`Total appointments in database: ${appointmentsSnapshot.size}`);
        
        // Prendre le premier rendez-vous pour le test
        let testAppointment = null;
        let testAppointmentId = null;
        
        appointmentsSnapshot.forEach((doc) => {
            if (!testAppointment) {
                testAppointment = doc.data();
                testAppointmentId = doc.id;
            }
        });
        
        if (!testAppointment) {
            console.log('❌ No appointments found for testing');
            return;
        }
        
        console.log(`\n=== TESTING APPOINTMENT: ${testAppointmentId} ===`);
        console.log('Appointment data:', JSON.stringify(testAppointment, null, 2));
        
        // Tester la récupération des détails
        const appointmentRef = doc(db, 'appointments', testAppointmentId);
        const appointmentDoc = await getDoc(appointmentRef);
        
        if (appointmentDoc.exists()) {
            const appointmentData = appointmentDoc.data();
            console.log('\n✅ Appointment details retrieved successfully');
            console.log('Patient Name:', appointmentData.patientName);
            console.log('Hospital Name:', appointmentData.hospitalName);
            console.log('Status:', appointmentData.status);
            console.log('Date:', appointmentData.appointmentDate);
        } else {
            console.log('❌ Appointment not found');
        }
        
    } catch (error) {
        console.error('❌ Error testing appointment details:', error);
    }
}

// Exécuter le test
testAppointmentDetails(); 