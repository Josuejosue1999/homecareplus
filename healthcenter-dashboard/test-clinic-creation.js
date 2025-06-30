const { auth, db, createUserWithEmailAndPassword, setDoc, doc, getDoc } = require("./config/firebase");

async function testClinicCreation() {
  try {
    console.log('=== TESTING CLINIC CREATION ===');
    
    // Test clinic data
    const testClinicName = 'Test Clinic ' + Date.now();
    const testEmail = `test${Date.now()}@example.com`;
    const testPassword = 'test123456';
    
    console.log('Creating test clinic:', testClinicName);
    console.log('Email:', testEmail);
    
    // Create user in Firebase Auth
    const userCredential = await createUserWithEmailAndPassword(auth, testEmail, testPassword);
    const user = userCredential.user;
    
    console.log('User created with UID:', user.uid);
    
    // Create complete clinic data
    const completeClinicData = {
      clinicName: testClinicName,
      name: testClinicName,
      email: testEmail,
      about: `${testClinicName} is a healthcare facility committed to providing exceptional medical care and services.`,
      address: 'Test Address',
      location: 'Test Location',
      phone: 'Test Phone',
      facilities: ['General Medicine', 'Cardiology'],
      profileImageUrl: null,
      certificateUrl: null,
      createdAt: new Date(),
      updatedAt: new Date(),
      status: 'active',
      isVerified: false,
      availableSchedule: {
        'Monday': {'start': '08:00', 'end': '17:00'},
        'Tuesday': {'start': '08:00', 'end': '17:00'},
        'Wednesday': {'start': '08:00', 'end': '17:00'},
        'Thursday': {'start': '08:00', 'end': '17:00'},
        'Friday': {'start': '08:00', 'end': '17:00'},
        'Saturday': {'start': '09:00', 'end': '15:00'},
        'Sunday': {'start': 'Closed', 'end': 'Closed'},
      },
      latitude: null,
      longitude: null,
    };
    
    console.log('Saving clinic data to Firestore...');
    await setDoc(doc(db, "clinics", user.uid), completeClinicData);
    
    console.log('Clinic data saved successfully!');
    
    // Verify the data was saved correctly
    console.log('Verifying saved data...');
    const savedDoc = await getDoc(doc(db, "clinics", user.uid));
    
    if (savedDoc.exists()) {
      const savedData = savedDoc.data();
      console.log('✓ Clinic data verified:');
      console.log('  - Name:', savedData.name);
      console.log('  - Email:', savedData.email);
      console.log('  - Status:', savedData.status);
      console.log('  - Created:', savedData.createdAt);
      console.log('  - Facilities:', savedData.facilities);
    } else {
      console.log('❌ Clinic data not found!');
    }
    
    console.log('=== TEST COMPLETED ===');
    console.log('Test clinic created successfully!');
    console.log('You can now check your mobile app to see if this clinic appears.');
    
  } catch (error) {
    console.error('Test failed:', error);
  }
}

// Run the test
testClinicCreation(); 