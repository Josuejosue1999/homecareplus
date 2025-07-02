const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, serverTimestamp } = require('firebase/firestore');

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

async function createTestAppointment() {
    try {
        console.log('=== CREATING TEST APPOINTMENT ===');
        
        const testAppointment = {
            patientId: 'test-patient-' + Date.now(),
            patientName: 'Test Patient ' + Math.floor(Math.random() * 1000),
            patientEmail: 'test@example.com',
            patientPhone: '+250 123 456 789',
            hospitalName: 'New Hospital', // Changez ceci selon votre clinique
            hospitalImage: '/assets/hospital.PNG',
            hospitalLocation: 'Test Location',
            department: 'General Medicine',
            appointmentDate: {
                seconds: Math.floor(Date.now() / 1000),
                nanoseconds: 0
            },
            appointmentTime: '10:00',
            reasonOfBooking: 'Test appointment for notification system',
            meetingDuration: 30,
            status: 'pending',
            createdAt: serverTimestamp(),
            updatedAt: null
        };
        
        const docRef = await addDoc(collection(db, 'appointments'), testAppointment);
        console.log('✅ Test appointment created with ID:', docRef.id);
        console.log('📋 Appointment details:', testAppointment);
        console.log('🔔 This should trigger a notification in the dashboard');
        
        return docRef.id;
        
    } catch (error) {
        console.error('❌ Error creating test appointment:', error);
        throw error;
    }
}

async function createMultipleTestAppointments(count = 3) {
    console.log(`=== CREATING ${count} TEST APPOINTMENTS ===`);
    
    for (let i = 0; i < count; i++) {
        try {
            await createTestAppointment();
            console.log(`✅ Created appointment ${i + 1}/${count}`);
            
            // Wait 2 seconds between appointments
            if (i < count - 1) {
                console.log('⏳ Waiting 2 seconds...');
                await new Promise(resolve => setTimeout(resolve, 2000));
            }
        } catch (error) {
            console.error(`❌ Failed to create appointment ${i + 1}:`, error);
        }
    }
    
    console.log('🎉 All test appointments created!');
}

// Fonction principale
async function main() {
    const args = process.argv.slice(2);
    const count = parseInt(args[0]) || 1;
    
    console.log('🚀 Starting notification test...');
    console.log(`📅 Will create ${count} test appointment(s)`);
    console.log('');
    
    if (count === 1) {
        await createTestAppointment();
    } else {
        await createMultipleTestAppointments(count);
    }
    
    console.log('');
    console.log('✅ Test completed!');
    console.log('📱 Check your dashboard for notifications');
    console.log('🔊 Make sure sound is enabled in the dashboard');
}

// Exécuter le script
if (require.main === module) {
    main().catch(console.error);
}

module.exports = {
    createTestAppointment,
    createMultipleTestAppointments
}; 