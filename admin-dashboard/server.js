const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
const session = require('express-session');
const crypto = require('crypto');
require('dotenv').config();

// Import Firebase Admin configuration for admin dashboard
const { admin, db, adminUtils } = require('./config/firebase-admin');

const app = express();
const PORT = process.env.PORT || 4000;

// Admin credentials
const ADMIN_CREDENTIALS = {
  email: 'admin@homecare.com',
  password: 'admin123'
};

// Session configuration
const sessionConfig = {
  secret: process.env.SESSION_SECRET || crypto.randomBytes(64).toString('hex'),
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: process.env.NODE_ENV === 'production', // true for HTTPS in production
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000, // 24 hours
    sameSite: 'lax', // Important for cross-origin requests
    domain: process.env.NODE_ENV === 'production' ? undefined : 'localhost' // Let Railway handle domain automatically
  }
};

// Authentication middleware
const requireAuth = (req, res, next) => {
  console.log('🔍 RequireAuth middleware called');
  console.log('📋 Session exists:', !!req.session);
  console.log('🔑 Session data:', req.session);
  console.log('✅ Admin authenticated:', req.session && req.session.adminAuthenticated);
  
  if (req.session && req.session.adminAuthenticated) {
    console.log('✅ Authentication successful - proceeding to next middleware');
    next();
  } else {
    console.log('❌ Authentication failed - redirecting to login');
    res.redirect('/login');
  }
};

// Redirect if authenticated
const redirectIfAuthenticated = (req, res, next) => {
  if (req.session && req.session.adminAuthenticated) {
    res.redirect('/');
  } else {
    next();
  }
};

// Firebase Admin utilities are now imported from config/firebase-admin.js
// adminUtils now provides: getAllClinics(), approveClinic(), unapproveClinic()

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

// Session middleware
app.use(session(sessionConfig));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// View engine setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// ===== AUTHENTICATION ROUTES =====

// Login page
app.get('/login', redirectIfAuthenticated, (req, res) => {
  res.render('login', { title: 'Admin Login - HomeCare Plus' });
});

// Login API
app.post('/api/admin/login', (req, res) => {
  const { email, password, remember } = req.body;
  
  console.log('🔑 Admin login attempt:', email);
  
  if (email === ADMIN_CREDENTIALS.email && password === ADMIN_CREDENTIALS.password) {
    req.session.adminAuthenticated = true;
    req.session.adminEmail = email;
    
    if (remember) {
      req.session.cookie.maxAge = 7 * 24 * 60 * 60 * 1000; // 7 days
    }
    
    // Explicitly save the session
    req.session.save((err) => {
      if (err) {
        console.error('❌ Error saving session:', err);
        return res.status(500).json({ success: false, message: 'Session save failed' });
      }
      
      console.log('✅ Admin login successful - Session saved');
      res.json({ success: true, message: 'Login successful' });
    });
  } else {
    console.log('❌ Admin login failed - Invalid credentials');
    res.status(401).json({ success: false, message: 'Invalid credentials' });
  }
});

// Logout API
app.post('/api/admin/logout', (req, res) => {
  req.session.destroy((err) => {
    if (err) {
      console.error('❌ Error destroying session:', err);
      res.status(500).json({ success: false, message: 'Logout failed' });
    } else {
      console.log('✅ Admin logout successful');
      res.json({ success: true, message: 'Logout successful' });
    }
  });
});

// ===== ADMIN API ROUTES =====

// Route pour approuver une clinique
app.post('/api/clinics/:id/approve', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔄 Admin approving clinic:', id);
    console.log('📋 Request body:', req.body);
    console.log('👤 Admin session:', req.session.adminEmail);
    
    if (!adminUtils) {
      console.error('❌ adminUtils is not available');
      return res.status(500).json({
        success: false,
        error: 'Admin utilities not available'
      });
    }
    
    if (!adminUtils.approveClinic) {
      console.error('❌ approveClinic function is not available');
      return res.status(500).json({
        success: false,
        error: 'Approve function not available'
      });
    }
    
    const result = await adminUtils.approveClinic(id);
    console.log('✅ Approve result:', result);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'Clinic approved successfully',
        clinic: { id, status: 'verified', verified: true }
      });
    } else {
      console.error('❌ Approve failed:', result.error);
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ Error in approve route:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message
    });
  }
});

// Route pour désapprouver une clinique
app.post('/api/clinics/:id/unapprove', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    console.log('🔄 Admin unapproving clinic:', id);
    console.log('📋 Request body:', req.body);
    console.log('👤 Admin session:', req.session.adminEmail);
    
    if (!adminUtils || !adminUtils.unapproveClinic) {
      console.error('❌ unapproveClinic function is not available');
      return res.status(500).json({
        success: false,
        error: 'Unapprove function not available'
      });
    }
    
    const result = await adminUtils.unapproveClinic(id);
    console.log('✅ Unapprove result:', result);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'Clinic unapproved successfully',
        clinic: { id, status: 'pending', verified: false }
      });
    } else {
      console.error('❌ Unapprove failed:', result.error);
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ Error in unapprove route:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message
    });
  }
});

// Route pour rejeter une clinique
app.post('/api/clinics/:id/reject', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    console.log('🔄 Admin rejecting clinic:', id);
    console.log('📋 Request body:', req.body);
    console.log('🚫 Rejection reason:', reason);
    console.log('👤 Admin session:', req.session.adminEmail);
    
    if (!adminUtils || !adminUtils.rejectClinic) {
      console.error('❌ rejectClinic function is not available');
      return res.status(500).json({
        success: false,
        error: 'Reject function not available'
      });
    }
    
    const result = await adminUtils.rejectClinic(id, reason);
    console.log('✅ Reject result:', result);
    
    if (result.success) {
      res.json({
        success: true,
        message: 'Clinic rejected successfully',
        clinic: { id, status: 'rejected', verified: false }
      });
    } else {
      console.error('❌ Reject failed:', result.error);
      res.status(500).json({
        success: false,
        error: result.error
      });
    }
  } catch (error) {
    console.error('❌ Error in reject route:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message
    });
  }
});

// Route to get individual clinic details
app.get('/api/clinics/:id', requireAuth, async (req, res) => {
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
app.get('/clinics', requireAuth, async (req, res) => {
  try {
    console.log('🏥 Loading clinics page...');
    console.log('👤 Admin session:', req.session.adminAuthenticated);
    console.log('📧 Admin email:', req.session.adminEmail);
    
    // Utiliser Firebase Admin pour obtenir les cliniques
    console.log('🔄 Calling adminUtils.getAllClinics()...');
    const result = await adminUtils.getAllClinics();
    console.log('📊 AdminUtils result:', result);
    
    if (!result.success) {
      console.error('❌ AdminUtils failed with error:', result.error);
      throw new Error(result.error);
    }
    
    const clinics = result.clinics;
    const totalClinics = clinics.length;
    console.log('📋 Total clinics found:', totalClinics);
    
    let verifiedCount = 0;
    let pendingCount = 0;
    let incompleteCount = 0;
    
    clinics.forEach((clinic) => {
      console.log('🏥 Processing clinic:', clinic.id, '- Verified:', clinic.verified, '- Complete:', clinic.profileSetupComplete);
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
    
    console.log('📊 Clinics stats prepared:', clinicsData);
    console.log('🎨 Rendering clinics page...');
    res.render('clinics', clinicsData);
  } catch (error) {
    console.error('❌ Error loading clinics page:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).send('Error loading clinics page: ' + error.message);
  }
});

// Route for full clinic profile page
app.get('/clinic-profile/:id', requireAuth, async (req, res) => {
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
        socialMedia: clinic.socialMedia || {},
        documents: clinic.documents || null
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

app.get('/', requireAuth, (req, res) => {
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
app.get('/api/stats', requireAuth, (req, res) => {
  res.json({
    users: { total: 1248, thisMonth: 287, growth: '+12.5%' },
    clinics: { total: 35, thisMonth: 9, growth: '+28.6%' },
    appointments: { total: 892, thisMonth: 156, growth: '+8.3%' },
    revenue: { total: 45678, thisMonth: 19800, growth: '+15.2%' }
  });
});

app.get('/api/users', requireAuth, (req, res) => {
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

app.get('/api/clinics', requireAuth, async (req, res) => {
  try {
    console.log('🔍 API: Fetching clinics from Firebase with Admin SDK...');
    console.log('👤 API Admin session:', req.session.adminAuthenticated);
    console.log('📧 API Admin email:', req.session.adminEmail);
    
    // Utiliser Firebase Admin pour obtenir les cliniques
    console.log('🔄 API: Calling adminUtils.getAllClinics()...');
    const result = await adminUtils.getAllClinics();
    console.log('📊 API: AdminUtils result:', result);
    
    if (!result.success) {
      console.error('❌ API: AdminUtils failed with error:', result.error);
      throw new Error(result.error);
    }
    
    console.log('📋 API: Processing', result.clinics.length, 'clinics...');
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
    
    console.log(`✅ API: Found ${clinics.length} clinics in Firebase`);
    
    const response = {
      success: true,
      clinics: clinics,
      total: clinics.length
    };
    
    console.log('📤 API: Sending response with', clinics.length, 'clinics');
    res.json(response);
  } catch (error) {
    console.error('❌ API Error fetching clinics:', error);
    console.error('❌ API Error stack:', error.stack);
    res.status(500).json({
      success: false,
      error: error.message,
      clinics: []
    });
  }
});

// Route for suggestions page
app.get('/suggestions', requireAuth, async (req, res) => {
  try {
    console.log('💡 Loading suggestions page...');
    console.log('👤 Admin session:', req.session.adminAuthenticated);
    console.log('📧 Admin email:', req.session.adminEmail);
    
    // Utiliser Firebase Admin pour obtenir les suggestions
    console.log('🔄 Calling adminUtils.getAllSuggestions()...');
    const result = await adminUtils.getAllSuggestions();
    console.log('📊 AdminUtils result:', result);
    
    if (!result.success) {
      console.error('❌ AdminUtils failed with error:', result.error);
      // Fallback avec des données par défaut
      const suggestionsData = {
        title: 'Suggestions Management - HomeCare+',
        totalSuggestions: 0,
        pendingSuggestions: 0,
        reviewedSuggestions: 0,
        implementedSuggestions: 0,
        error: 'Unable to fetch suggestions from Firebase'
      };
      return res.render('suggestions', suggestionsData);
    }
    
    const suggestions = result.suggestions;
    const totalSuggestions = suggestions.length;
    console.log('📋 Total suggestions found:', totalSuggestions);
    
    let pendingCount = 0;
    let reviewedCount = 0;
    let implementedCount = 0;
    
    suggestions.forEach((suggestion) => {
      console.log('💡 Processing suggestion:', suggestion.id, '- Status:', suggestion.status);
      if (suggestion.status === 'pending') {
        pendingCount++;
      } else if (suggestion.status === 'reviewed') {
        reviewedCount++;
      } else if (suggestion.status === 'implemented') {
        implementedCount++;
      }
    });
    
    const suggestionsData = {
      title: 'Suggestions Management - HomeCare+',
      totalSuggestions,
      pendingSuggestions: pendingCount,
      reviewedSuggestions: reviewedCount,
      implementedSuggestions: implementedCount
    };
    
    console.log('📊 Suggestions stats prepared:', suggestionsData);
    console.log('🎨 Rendering suggestions page...');
    res.render('suggestions', suggestionsData);
  } catch (error) {
    console.error('❌ Error loading suggestions page:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).send('Error loading suggestions page: ' + error.message);
  }
});



app.get('/api/suggestions', requireAuth, async (req, res) => {
  try {
    console.log('🔍 API: Fetching suggestions from Firebase...');
    console.log('👤 API Admin session:', req.session.adminAuthenticated);
    console.log('📧 API Admin email:', req.session.adminEmail);
    
    // Utiliser Firebase Admin pour obtenir les suggestions
    console.log('🔄 API: Calling adminUtils.getAllSuggestions()...');
    const result = await adminUtils.getAllSuggestions();
    console.log('📊 API AdminUtils result:', result);
    
    if (!result.success) {
      console.error('❌ API AdminUtils failed with error:', result.error);
      return res.status(500).json({
        success: false,
        error: 'Unable to fetch suggestions from Firebase: ' + result.error,
        suggestions: []
      });
    }
    
    const suggestions = result.suggestions;
    console.log('📋 API: Total suggestions found:', suggestions.length);
    console.log('✅ API: Returning Firebase suggestions');
    
    res.json({
      success: true,
      suggestions: suggestions,
      total: suggestions.length
    });
  } catch (error) {
    console.error('❌ API Error fetching suggestions:', error);
    console.error('❌ API Error stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Internal server error: ' + error.message,
      suggestions: []
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).render('404', { 
    title: '404 - Page Not Found',
    error: 'The page you are looking for does not exist.'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).render('404', { 
    title: '500 - Server Error',
    error: 'Something went wrong on our server.'
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