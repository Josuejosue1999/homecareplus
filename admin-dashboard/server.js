const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const compression = require('compression');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 4000;

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com", "https://fonts.googleapis.com"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://cdnjs.cloudflare.com", "https://cdn.jsdelivr.net"],
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

// Routes
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

app.get('/api/clinics', (req, res) => {
  const clinics = [
    { id: 1, name: 'ALU Clinic', location: 'Kigali', status: 'Verified', patients: 145, rating: 4.8 },
    { id: 2, name: 'Kimironko Hospital', location: 'Gasabo', status: 'Verified', patients: 289, rating: 4.9 },
    { id: 3, name: 'Zindiro Clinic', location: 'Nyarugenge', status: 'Pending', patients: 67, rating: 4.6 },
    { id: 4, name: 'Simba Clinic', location: 'Kicukiro', status: 'Verified', patients: 123, rating: 4.7 },
    { id: 5, name: 'BENIN CLINIC', location: 'Kigali', status: 'Verified', patients: 98, rating: 4.5 }
  ];
  res.json(clinics);
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Page not found' });
});

app.listen(PORT, () => {
  console.log(`🚀 Admin Dashboard Server running on http://localhost:${PORT}`);
  console.log(`📊 Dashboard: http://localhost:${PORT}`);
  console.log(`🔐 Admin Interface: Modern & Professional`);
  console.log(`📱 Responsive Design: Mobile & Desktop Ready`);
});

module.exports = app; 