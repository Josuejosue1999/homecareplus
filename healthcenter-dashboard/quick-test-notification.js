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

async function addQuickTestAppointment() {
    try {
        console.log('🎯 Adding quick test appointment...');
        
        const now = new Date();
        const appointmentDate = new Date(now.getTime() + 24 * 60 * 60 * 1000); // Tomorrow
        
        const testAppointment = {
            patientName: "Test Patient - " + now.toLocaleTimeString(),
            patientEmail: "test@example.com",
            patientPhone: "+250123456789",
            appointmentDate: admin.firestore.Timestamp.fromDate(appointmentDate),
            appointmentTime: "10:00",
            department: "General Medicine",
            hospitalName: "New Hospital", // Change this to your clinic name
            hospitalLocation: "Test Location",
            status: "pending",
            createdAt: admin.firestore.Timestamp.fromDate(now),
            updatedAt: admin.firestore.Timestamp.fromDate(now)
        };
        
        const docRef = await db.collection('appointments').add(testAppointment);
        console.log('✅ Test appointment added with ID:', docRef.id);
        console.log('🔔 This should trigger a notification in the web dashboard');
        console.log('⏰ Check the web dashboard within 10-15 seconds');
        
        // Auto-cleanup after 30 seconds
        setTimeout(async () => {
            try {
                await db.collection('appointments').doc(docRef.id).delete();
                console.log('🧹 Test appointment cleaned up');
            } catch (error) {
                console.error('❌ Error cleaning up:', error);
            }
        }, 30000);
        
    } catch (error) {
        console.error('❌ Error adding test appointment:', error);
    }
}

// Run the test
addQuickTestAppointment(); 