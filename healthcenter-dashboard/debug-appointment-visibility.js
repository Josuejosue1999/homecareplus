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

async function debugAppointmentVisibility() {
  try {
    console.log('=== DEBUGGING APPOINTMENT VISIBILITY ===');
    
    // Step 1: Get all appointments
    console.log('\n📋 Step 1: Getting all appointments...');
    const appointmentsSnapshot = await getDocs(collection(db, 'appointments'));
    console.log(`Total appointments in database: ${appointmentsSnapshot.size}`);
    
    const appointments = [];
    appointmentsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      appointments.push({
        id: doc.id,
        patientName: data.patientName,
        hospitalName: data.hospitalName || data.hospital,
        department: data.department,
        status: data.status,
        appointmentDate: data.appointmentDate?.toDate?.() || data.createdAt?.toDate?.() || new Date(),
        createdAt: data.createdAt?.toDate?.() || new Date()
      });
    });
    
    // Step 2: Get all clinics
    console.log('\n🏥 Step 2: Getting all clinics...');
    const clinicsSnapshot = await getDocs(collection(db, 'clinics'));
    console.log(`Total clinics in database: ${clinicsSnapshot.size}`);
    
    const clinics = [];
    clinicsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      clinics.push({
        id: doc.id,
        name: data.name || data.clinicName || 'Unknown',
        clinicName: data.clinicName || data.name || 'Unknown'
      });
    });
    
    console.log('\nAvailable clinics:');
    clinics.forEach((clinic, index) => {
      console.log(`${index + 1}. ID: ${clinic.id} | Name: "${clinic.name}" | ClinicName: "${clinic.clinicName}"`);
    });
    
    // Step 3: Analyze appointment-hospital matching
    console.log('\n🔍 Step 3: Analyzing appointment-hospital matching...');
    
    const hospitalNames = [...new Set(appointments.map(apt => apt.hospitalName))];
    console.log('\nHospital names in appointments:');
    hospitalNames.forEach((hospitalName, index) => {
      const count = appointments.filter(apt => apt.hospitalName === hospitalName).length;
      console.log(`${index + 1}. "${hospitalName}" (${count} appointments)`);
    });
    
    // Step 4: Check for mismatches
    console.log('\n⚠️ Step 4: Checking for mismatches...');
    
    const mismatches = [];
    hospitalNames.forEach(hospitalName => {
      const matchingClinics = clinics.filter(clinic => 
        clinic.name === hospitalName || clinic.clinicName === hospitalName
      );
      
      if (matchingClinics.length === 0) {
        mismatches.push({
          hospitalName: hospitalName,
          appointmentCount: appointments.filter(apt => apt.hospitalName === hospitalName).length,
          reason: 'No matching clinic found'
        });
      } else if (matchingClinics.length > 1) {
        mismatches.push({
          hospitalName: hospitalName,
          appointmentCount: appointments.filter(apt => apt.hospitalName === hospitalName).length,
          reason: `Multiple matching clinics found: ${matchingClinics.map(c => c.id).join(', ')}`
        });
      }
    });
    
    if (mismatches.length > 0) {
      console.log('\n❌ MISMATCHES FOUND:');
      mismatches.forEach(mismatch => {
        console.log(`- "${mismatch.hospitalName}" (${mismatch.appointmentCount} appointments): ${mismatch.reason}`);
      });
    } else {
      console.log('\n✅ No mismatches found - all hospital names have matching clinics');
    }
    
    // Step 5: Test specific clinic appointment retrieval
    console.log('\n🧪 Step 5: Testing specific clinic appointment retrieval...');
    
    if (clinics.length > 0) {
      const testClinic = clinics[0];
      console.log(`\nTesting with clinic: "${testClinic.name}" (ID: ${testClinic.id})`);
      
      const clinicAppointments = appointments.filter(apt => 
        apt.hospitalName === testClinic.name || apt.hospitalName === testClinic.clinicName
      );
      
      console.log(`Found ${clinicAppointments.length} appointments for this clinic`);
      
      if (clinicAppointments.length > 0) {
        console.log('\nSample appointments:');
        clinicAppointments.slice(0, 3).forEach((apt, index) => {
          console.log(`${index + 1}. ${apt.patientName} - ${apt.department} - ${apt.status} - ${apt.appointmentDate.toLocaleDateString()}`);
        });
      }
    }
    
    // Step 6: Check recent appointments
    console.log('\n📅 Step 6: Checking recent appointments...');
    const now = new Date();
    const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const oneWeekFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    
    const recentAppointments = appointments.filter(apt => {
      const aptDate = apt.appointmentDate;
      return aptDate >= oneWeekAgo && aptDate <= oneWeekFromNow && 
             (apt.status === 'pending' || apt.status === 'confirmed');
    });
    
    console.log(`Recent appointments (within 1 week): ${recentAppointments.length}`);
    
    if (recentAppointments.length > 0) {
      console.log('\nRecent appointments by hospital:');
      const recentByHospital = {};
      recentAppointments.forEach(apt => {
        if (!recentByHospital[apt.hospitalName]) {
          recentByHospital[apt.hospitalName] = [];
        }
        recentByHospital[apt.hospitalName].push(apt);
      });
      
      Object.entries(recentByHospital).forEach(([hospital, apts]) => {
        console.log(`- "${hospital}": ${apts.length} appointments`);
        apts.forEach(apt => {
          console.log(`  * ${apt.patientName} - ${apt.department} - ${apt.status} - ${apt.appointmentDate.toLocaleDateString()}`);
        });
      });
    }
    
    // Step 7: Recommendations
    console.log('\n💡 Step 7: Recommendations...');
    
    if (mismatches.length > 0) {
      console.log('\n🔧 FIXES NEEDED:');
      console.log('1. Standardize hospital names between appointments and clinics');
      console.log('2. Update clinic names to match appointment hospital names');
      console.log('3. Or update appointment hospital names to match clinic names');
    }
    
    if (recentAppointments.length === 0) {
      console.log('\n⚠️ No recent appointments found - check if appointments are being created properly');
    }
    
    console.log('\n✅ Appointment visibility debug completed!');
    
  } catch (error) {
    console.error('❌ Error debugging appointment visibility:', error);
  }
}

// Run the debug
debugAppointmentVisibility(); 