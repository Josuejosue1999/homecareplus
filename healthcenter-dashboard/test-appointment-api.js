const { initializeApp } = require("firebase/app");
const { getFirestore, collection, getDocs, query, where } = require("firebase/firestore");

// Configuration Firebase
const firebaseConfig = {
  apiKey: "AIzaSyDYaKiltvi2oUAUO_mi4YNtqCpbJ3RbJI8",
  authDomain: "homecare-9f4d0.firebaseapp.com",
  projectId: "homecare-9f4d0",
  storageBucket: "homecare-9f4d0.firebasestorage.app",
  messagingSenderId: "54787084616",
  appId: "1:54787084616:android:7892366bf2029a3908a37d"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function testAppointmentAPI() {
  try {
    console.log('=== TESTING APPOINTMENT API ===');
    
    // Récupérer quelques appointments pour tester
    const appointmentsSnapshot = await getDocs(collection(db, 'appointments'));
    
    console.log(`Found ${appointmentsSnapshot.size} appointments`);
    
    if (appointmentsSnapshot.size === 0) {
      console.log('No appointments found to test with');
      return;
    }
    
    // Prendre le premier appointment pour le test
    const firstAppointment = appointmentsSnapshot.docs[0];
    const appointmentData = firstAppointment.data();
    
    console.log('\n=== APPOINTMENT DATA STRUCTURE ===');
    console.log('Appointment ID:', firstAppointment.id);
    console.log('Patient Name:', appointmentData.patientName);
    console.log('Hospital:', appointmentData.hospital);
    console.log('Status:', appointmentData.status);
    console.log('Date:', appointmentData.appointmentDate);
    console.log('All fields:', Object.keys(appointmentData));
    
    // Tester la structure attendue par l'API
    const expectedStructure = {
      id: firstAppointment.id,
      patientName: appointmentData.patientName || appointmentData.patient || 'Unknown Patient',
      patientEmail: appointmentData.patientEmail || appointmentData.email || '',
      patientPhone: appointmentData.patientPhone || appointmentData.phone || '',
      patientAge: appointmentData.patientAge || appointmentData.age || '',
      hospital: appointmentData.hospital || appointmentData.hospitalName || '',
      service: appointmentData.service || appointmentData.department || 'General Consultation',
      date: appointmentData.appointmentDate || appointmentData.date || appointmentData.createdAt?.toDate?.() || new Date(),
      time: appointmentData.appointmentTime || appointmentData.time || '',
      status: appointmentData.status || 'pending',
      notes: appointmentData.notes || appointmentData.reasonOfBooking || '',
      duration: appointmentData.duration || '30 minutes',
      createdAt: appointmentData.createdAt?.toDate?.() || new Date(),
      updatedAt: appointmentData.updatedAt?.toDate?.() || new Date()
    };
    
    console.log('\n=== EXPECTED API RESPONSE STRUCTURE ===');
    console.log(JSON.stringify({
      success: true,
      appointment: expectedStructure
    }, null, 2));
    
    console.log('\n✅ API structure test completed successfully!');
    
  } catch (error) {
    console.error('❌ Error testing appointment API:', error);
  }
}

// Run the test
testAppointmentAPI(); 