const admin = require('firebase-admin');
const serviceAccount = require('./config/firebase.js');

// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: "https://homecareplus-4b8c8-default-rtdb.firebaseio.com"
    });
}

const db = admin.firestore();

async function addTestAppointment() {
    try {
        console.log('🎯 Adding test appointment for notification testing...');
        
        // Get current timestamp
        const now = new Date();
        const appointmentDate = new Date(now.getTime() + 24 * 60 * 60 * 1000); // Tomorrow
        
        const testAppointment = {
            patientName: "Test Patient - " + now.toLocaleTimeString(),
            patientEmail: "test@example.com",
            patientPhone: "+250123456789",
            appointmentDate: {
                seconds: Math.floor(appointmentDate.getTime() / 1000),
                nanoseconds: 0
            },
            appointmentTime: "10:00",
            department: "General Medicine",
            status: "pending",
            hospitalName: "New Hospital", // Change this to match your clinic name
            hospitalLocation: "Test Location",
            notes: "Test appointment for notification system",
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        };
        
        console.log('📋 Test appointment data:', testAppointment);
        
        // Add to Firestore
        const docRef = await db.collection('appointments').add(testAppointment);
        console.log('✅ Test appointment added with ID:', docRef.id);
        
        console.log('🎵 Now check your web dashboard - you should hear a notification sound!');
        console.log('📱 Make sure your web dashboard is open and the sound is enabled');
        
    } catch (error) {
        console.error('❌ Error adding test appointment:', error);
    }
}

// Run the test
addTestAppointment().then(() => {
    console.log('🧪 Test completed');
    process.exit(0);
}).catch(error => {
    console.error('❌ Test failed:', error);
    process.exit(1);
}); 