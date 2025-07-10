const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
require('dotenv').config();

// Import Firebase configuration from main app
const { 
  db, 
  collection, 
  getDocs, 
  getDoc,
  query, 
  orderBy, 
  where, 
  doc, 
  updateDoc, 
  deleteDoc, 
  setDoc,
  addDoc,
  serverTimestamp
} = require('../config/firebase');

const app = express();
const PORT = process.env.PORT || 4000;

// Firebase utilities pour l'admin
const adminUtils = {
  // Approuver une clinique
  async approveClinic(clinicId) {
    try {
      console.log('✅ Approving clinic:', clinicId);
      
      const clinicRef = doc(db, 'clinics', clinicId);
      
      await updateDoc(clinicRef, {
        verified: true,
        isVerified: true,
        approved: true,
        status: 'verified',
        approvedAt: serverTimestamp(),
        lastUpdated: serverTimestamp()
      });
      
      console.log('✅ Clinic approved successfully:', clinicId);
      return { success: true, message: 'Clinic approved successfully' };
    } catch (error) {
      console.error('❌ Error approving clinic:', error);
      return { success: false, error: error.message };
    }
  },

  // Désapprouver une clinique
  async unapproveClinic(clinicId) {
    try {
      console.log('❌ Unapproving clinic:', clinicId);
      
      const clinicRef = doc(db, 'clinics', clinicId);
      
      await updateDoc(clinicRef, {
        verified: false,
        isVerified: false,
        approved: false,
        status: 'pending',
        unapprovedAt: serverTimestamp(),
        lastUpdated: serverTimestamp()
      });
      
      console.log('❌ Clinic unapproved successfully:', clinicId);
      return { success: true, message: 'Clinic unapproved successfully' };
    } catch (error) {
      console.error('❌ Error unapproving clinic:', error);
      return { success: false, error: error.message };
    }
  },

  // Rejeter une clinique
  async rejectClinic(clinicId) {
    try {
      console.log('🚫 Rejecting clinic:', clinicId);
      
      const clinicRef = doc(db, 'clinics', clinicId);
      
      await updateDoc(clinicRef, {
        verified: false,
        isVerified: false,
        approved: false,
        status: 'rejected',
        rejectedAt: serverTimestamp(),
        lastUpdated: serverTimestamp()
      });
      
      console.log('🚫 Clinic rejected successfully:', clinicId);
      return { success: true, message: 'Clinic rejected successfully' };
    } catch (error) {
      console.error('❌ Error rejecting clinic:', error);
      return { success: false, error: error.message };
    }
  },

  // Obtenir toutes les cliniques
  async getAllClinics() {
    try {
      const clinicsRef = collection(db, 'clinics');
      const q = query(clinicsRef, orderBy('createdAt', 'desc'));
      const snapshot = await getDocs(q);
      
      const clinics = [];
      snapshot.forEach(doc => {
        clinics.push({
          id: doc.id,
          ...doc.data()
        });
      });
      
      return { success: true, clinics };
    } catch (error) {
      console.error('❌ Error fetching clinics:', error);
      return { success: false, error: error.message };
    }
  },

  // Obtenir une clinique spécifique
  async getClinic(clinicId) {
    try {
      const clinicRef = doc(db, 'clinics', clinicId);
      const docSnap = await getDoc(clinicRef);
      
      if (!docSnap.exists()) {
        return { success: false, error: 'Clinic not found' };
      }
      
      return { 
        success: true, 
        clinic: {
          id: docSnap.id,
          ...docSnap.data()
        }
      };
    } catch (error) {
      console.error('❌ Error fetching clinic:', error);
      return { success: false, error: error.message };
    }
  }
};

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com", "https://fonts.googleapis.com", "https://cdn.jsdelivr.net"],
      scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'", "https://cdnjs.cloudflare.com", "https://cdn.jsdelivr.net"],
      scriptSrcAttr: ["'unsafe-inline'"],
      fontSrc: ["'self'", "https://fonts.gstatic.com", "https://cdnjs.cloudflare.com"],
      imgSrc: ["'self'", "data:", "https:", "blob:"],
      connectSrc: ["'self'", "https:"]
    }
  }
}));

// Middleware
app.use(compression());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// View engine setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// ===== ADMIN API ROUTES =====

// Route pour approuver une clinique
app.post('/api/clinics/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔄 Admin approving clinic:', id);
    
    const result = await adminUtils.approveClinic(id);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'Clinic approved successfully',
        clinic: { id, status: 'verified', verified: true }
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ Error in approve route:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Route pour désapprouver une clinique
app.post('/api/clinics/:id/unapprove', async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔄 Admin unapproving clinic:', id);
    
    const result = await adminUtils.unapproveClinic(id);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'Clinic unapproved successfully',
        clinic: { id, status: 'pending', verified: false }
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ Error in unapprove route:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Route pour rejeter une clinique
app.post('/api/clinics/:id/reject', async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔄 Admin rejecting clinic:', id);
    
    const result = await adminUtils.rejectClinic(id);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'Clinic rejected successfully',
        clinic: { id, status: 'rejected', verified: false }
      });
    } else {
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ Error in reject route:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Route to get individual clinic details
app.get('/api/clinics/:id', async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔍 Fetching clinic details for ID:', id);
    
    const result = await adminUtils.getClinic(id);
    
    if (result.success) {
      res.json({
        success: true,
        clinic: result.clinic
      });
    } else {
      res.status(404).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ Error fetching clinic details:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// ===== PAGE ROUTES =====

// Routes
// Route for clinics page
app.get('/clinics', async (req, res) => {
  try {
    console.log('🏥 Loading clinics page...');
    
    // Utiliser Firebase Admin pour obtenir les cliniques
    const result = await adminUtils.getAllClinics();
    
    if (!result.success) {
      throw new Error(result.error);
    }
    
    const clinics = result.clinics;
    const totalClinics = clinics.length;
    
    let verifiedCount = 0;
    let pendingCount = 0;
    let incompleteCount = 0;
    
    clinics.forEach((clinic) => {
      if (clinic.verified === true || clinic.isVerified === true) {
        verifiedCount++;
      } else if (clinic.profileSetupComplete) {
        pendingCount++;
      } else {
        incompleteCount++;
      }
    });
    
    const clinicsData = {
      title: 'Clinics Management - HomeCare+',
      totalClinics,
      verifiedClinics: verifiedCount,
      pendingClinics: pendingCount,
      incompleteClinics: incompleteCount
    };
    
    console.log('📊 Clinics stats:', clinicsData);
    res.render('clinics', clinicsData);
  } catch (error) {
    console.error('❌ Error loading clinics page:', error);
    res.status(500).send('Error loading clinics page');
  }
});

// Route for full clinic profile page
app.get('/clinic-profile/:id', async (req, res) => {
  try {
    const clinicId = req.params.id;
    console.log('🏥 Loading full clinic profile for ID:', clinicId);
    
    // Utiliser Firebase Admin pour obtenir les détails de la clinique
    const result = await adminUtils.getClinic(clinicId); // Changed from getClinicById to getClinic
    
    if (!result.success) {
      console.error('❌ Error fetching clinic:', result.error);
      return res.status(404).render('404', { 
        title: 'Clinic Not Found - HomeCare+',
        error: 'Clinic not found' 
      });
    }
    
    const clinic = result.clinic;
    console.log('✅ Clinic details fetched for full profile:', clinic.clinicName || clinic.name);
    
    // Format clinic data for display
    const profileData = {
      title: `${clinic.clinicName || clinic.name} - Full Profile - HomeCare+`,
      clinic: {
        id: clinic.id,
        name: clinic.clinicName || clinic.name || 'Name not defined',
        clinicName: clinic.clinicName || clinic.name || 'Name not defined',
        email: clinic.email || 'Email not defined',
        location: clinic.location || clinic.address || 'Address not defined',
        address: clinic.address || clinic.location || 'Address not defined',
        phone: clinic.phone || clinic.googlePhoneNumber || 'Phone not defined',
        googlePhoneNumber: clinic.googlePhoneNumber || clinic.phone || null,
        about: clinic.about || null,
        status: clinic.verified === true ? 'Verified' : (clinic.profileSetupComplete ? 'Pending' : 'Incomplete'),
        verified: clinic.verified === true || clinic.isVerified === true,
        isVerified: clinic.isVerified === true || clinic.verified === true,
        approved: clinic.approved === true || clinic.verified === true || clinic.isVerified === true,
        rating: clinic.rating || 0,
        facilities: clinic.facilities || clinic.services || [],
        services: clinic.services || clinic.facilities || [],
        isFromGooglePlaces: clinic.isFromGooglePlaces || false,
        placeId: clinic.placeId || null,
        profileSetupComplete: clinic.profileSetupComplete || false,
        createdAt: clinic.createdAt,
        lastUpdated: clinic.lastUpdated,
        appointmentDuration: clinic.appointmentDuration || 30,
        bufferTime: clinic.bufferTime || 15,
        availableSchedule: clinic.availableSchedule || {},
        googlePlaceDetails: clinic.googlePlaceDetails || null,
        profileImageUrl: clinic.profileImageUrl || null,
        certificateUrl: clinic.certificateUrl || null,
        clinicPhotos: clinic.clinicPhotos || [],
        googleWebsite: clinic.googleWebsite || null,
        googlePhotos: clinic.googlePhotos || [],
        openingHours: clinic.openingHours || null,
        priceLevel: clinic.priceLevel || null,
        types: clinic.types || [],
        paymentMethods: clinic.paymentMethods || [],
        emergencyServices: clinic.emergencyServices || false,
        onlineConsultation: clinic.onlineConsultation || false,
        homeVisit: clinic.homeVisit || false,
        insurance: clinic.insurance || [],
        languages: clinic.languages || [],
        specializations: clinic.specializations || [],
        doctors: clinic.doctors || [],
        certifications: clinic.certifications || [],
        awards: clinic.awards || [],
        socialMedia: clinic.socialMedia || {}
      }
    };
    
    console.log('📋 Rendering full clinic profile page');
    res.render('clinic-profile', profileData);
  } catch (error) {
    console.error('❌ Error loading clinic profile:', error);
    res.status(500).render('404', { 
      title: 'Error - HomeCare+',
      error: 'Error loading clinic profile' 
    });
  }
});

app.get('/', (req, res) => {
  const dashboardData = {
    title: 'HomeCare+ Admin Dashboard',
    totalUsers: 1248,
    totalClinics: 35,
    totalAppointments: 892,
    totalRevenue: '$45,678',
    recentUsers: [
      { id: 1, name: 'John Doe', email: 'john@example.com', role: 'Patient', status: 'Active', joinDate: '2025-01-15' },
      { id: 2, name: 'Dr. Sarah Wilson', email: 'sarah@clinic.com', role: 'Doctor', status: 'Active', joinDate: '2025-01-10' },
      { id: 3, name: 'ALU Clinic', email: 'contact@alu.com', role: 'Clinic', status: 'Verified', joinDate: '2025-01-08' },
      { id: 4, name: 'Marie Claire', email: 'marie@example.com', role: 'Patient', status: 'Active', joinDate: '2025-01-05' },
      { id: 5, name: 'Kimironko Hospital', email: 'info@kimironko.rw', role: 'Hospital', status: 'Verified', joinDate: '2025-01-03' }
    ],
    recentActivities: [
      { action: 'New clinic registration', details: 'Zindiro Clinic submitted registration', time: '2 hours ago', type: 'registration' },
      { action: 'Appointment booked', details: 'Patient John D. booked with Dr. Sarah W.', time: '3 hours ago', type: 'appointment' },
      { action: 'System maintenance', details: 'Scheduled backup completed successfully', time: '5 hours ago', type: 'system' },
      { action: 'New user registration', details: '5 new patients joined the platform', time: '6 hours ago', type: 'registration' },
      { action: 'Payment processed', details: 'Clinic payment of $250 processed', time: '8 hours ago', type: 'payment' }
    ],
    monthlyStats: [
      { month: 'Jan', users: 145, clinics: 3, revenue: 8500 },
      { month: 'Feb', users: 189, clinics: 5, revenue: 12300 },
      { month: 'Mar', users: 234, clinics: 4, revenue: 15600 },
      { month: 'Apr', users: 198, clinics: 6, revenue: 18900 },
      { month: 'May', users: 287, clinics: 8, revenue: 22400 },
      { month: 'Jun', users: 195, clinics: 9, revenue: 19800 }
    ]
  };
  
  res.render('dashboard', dashboardData);
});

// API Routes for dashboard data
app.get('/api/stats', (req, res) => {
  res.json({
    users: { total: 1248, thisMonth: 287, growth: '+12.5%' },
    clinics: { total: 35, thisMonth: 9, growth: '+28.6%' },
    appointments: { total: 892, thisMonth: 156, growth: '+8.3%' },
    revenue: { total: 45678, thisMonth: 19800, growth: '+15.2%' }
  });
});

app.get('/api/users', (req, res) => {
  // Mock data - in real app, this would come from database
  const users = [
    { id: 1, name: 'John Doe', email: 'john@example.com', role: 'Patient', status: 'Active', joinDate: '2025-01-15', lastLogin: '2025-01-20' },
    { id: 2, name: 'Dr. Sarah Wilson', email: 'sarah@clinic.com', role: 'Doctor', status: 'Active', joinDate: '2025-01-10', lastLogin: '2025-01-20' },
    { id: 3, name: 'ALU Clinic', email: 'contact@alu.com', role: 'Clinic', status: 'Verified', joinDate: '2025-01-08', lastLogin: '2025-01-19' },
    { id: 4, name: 'Marie Claire', email: 'marie@example.com', role: 'Patient', status: 'Active', joinDate: '2025-01-05', lastLogin: '2025-01-18' },
    { id: 5, name: 'Kimironko Hospital', email: 'info@kimironko.rw', role: 'Hospital', status: 'Verified', joinDate: '2025-01-03', lastLogin: '2025-01-17' }
  ];
  res.json(users);
});

app.get('/api/clinics', async (req, res) => {
  try {
    console.log('🔍 Fetching clinics from Firebase with Admin SDK...');
    
    // Utiliser Firebase Admin pour obtenir les cliniques
    const result = await adminUtils.getAllClinics();
    
    if (!result.success) {
      throw new Error(result.error);
    }
    
    const clinics = result.clinics.map(clinic => {
      // Format data for admin dashboard
      return {
        id: clinic.id,
        name: clinic.clinicName || clinic.name || 'Name not defined',
        clinicName: clinic.clinicName || clinic.name || 'Name not defined',
        email: clinic.email || 'Email not defined',
        location: clinic.location || clinic.address || 'Address not defined',
        address: clinic.address || clinic.location || 'Address not defined',
        phone: clinic.phone || clinic.googlePhoneNumber || 'Phone not defined',
        googlePhoneNumber: clinic.googlePhoneNumber || clinic.phone || null,
        about: clinic.about || null,
        status: clinic.verified === true ? 'Verified' : (clinic.profileSetupComplete ? 'Pending' : 'Incomplete'),
        verified: clinic.verified === true || clinic.isVerified === true,
        isVerified: clinic.isVerified === true || clinic.verified === true,
        approved: clinic.approved === true || clinic.verified === true || clinic.isVerified === true,
        rating: clinic.rating || 0,
        facilities: clinic.facilities || clinic.services || [],
        services: clinic.services || clinic.facilities || [],
        isFromGooglePlaces: clinic.isFromGooglePlaces || false,
        placeId: clinic.placeId || null,
        profileSetupComplete: clinic.profileSetupComplete || false,
        createdAt: clinic.createdAt,
        lastUpdated: clinic.lastUpdated,
        appointmentDuration: clinic.appointmentDuration || 30,
        bufferTime: clinic.bufferTime || 15,
        availableSchedule: clinic.availableSchedule || {},
        googlePlaceDetails: clinic.googlePlaceDetails || null,
        profileImageUrl: clinic.profileImageUrl || null,
        certificateUrl: clinic.certificateUrl || null,
        clinicPhotos: clinic.clinicPhotos || []
      };
    });
    
    console.log(`✅ Found ${clinics.length} clinics in Firebase`);
    
    res.json({
      success: true,
      clinics: clinics,
      total: clinics.length
    });
  } catch (error) {
    console.error('❌ Error fetching clinics:', error);
    res.status(500).json({
      success: false,
      error: error.message,
      clinics: []
    });
  }
});

// Route for User Management page
app.get('/user-management', (req, res) => {
  const userManagementData = {
    title: 'User Management - HomeCare Plus Admin',
    totalUsers: 1248,
    activeUsers: 892,
    newRegistrations: 156,
    blockedUsers: 12
  };
  
  res.render('user-management', userManagementData);
});

// Route for Settings page
app.get('/settings', (req, res) => {
  const settingsData = {
    title: 'Settings - HomeCare Plus Admin',
    applicationName: 'HomeCare Plus',
    systemEmail: 'admin@homecareplus.com',
    timeZone: 'UTC',
    language: 'English',
    currency: 'USD'
  };
  
  res.render('settings', settingsData);
});

// 404 handler
app.use((req, res) => {
  res.status(404).render('404', { 
    title: '404 - Page Not Found',
    message: 'The page you are looking for does not exist.'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).render('404', { 
    title: '500 - Server Error',
    message: 'Something went wrong on our server.'
  });
});

// Start server with graceful shutdown
const server = app.listen(PORT, () => {
  console.log('🚀 Admin Dashboard Server running on http://localhost:' + PORT);
  console.log('📊 Dashboard: http://localhost:' + PORT);
  console.log('🔐 Admin Interface: Modern & Professional');
  console.log('📱 Responsive Design: Mobile & Desktop Ready');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('💤 Shutting down admin dashboard server gracefully...');
  server.close(() => {
    console.log('✅ Admin dashboard server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('💤 Shutting down admin dashboard server gracefully...');
  server.close(() => {
    console.log('✅ Admin dashboard server closed');
    process.exit(0);
  });
}); 