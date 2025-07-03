const express = require("express");
const path = require("path");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const dotenv = require("dotenv");
const multer = require("multer");
dotenv.config();

// Import Firebase configuration
const { db, doc, getDoc, collection, query, where, orderBy, getDocs, updateDoc, addDoc, serverTimestamp, writeBatch, increment } = require("./config/firebase");

// Import Firebase functions from config
const { storage, ref, uploadBytes, getDownloadURL } = require("./config/firebase");

// Configure multer for file uploads (using memory storage)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max file size
    files: 1 // Maximum 1 file per upload
  },
  fileFilter: (req, file, cb) => {
    // Allow images and PDFs
    const allowedTypes = [
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'application/pdf'
    ];
    
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only JPG, PNG, and PDF files are allowed.'));
    }
  }
});

// Import des routes et middleware
const authRoutes = require("./routes/auth");
const { requireAuth, redirectIfAuthenticated } = require("./middleware/auth");

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, "public")));

// Set view engine
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

// Session management (simple in-memory for demo)
const sessions = new Map();

// Routes publiques
app.get("/", (req, res) => {
    res.render("index");
});

app.get("/login", redirectIfAuthenticated, (req, res) => {
    res.render("login");
});

app.get("/register", redirectIfAuthenticated, (req, res) => {
    res.render("register");
});

// Routes d"authentification API
app.use("/api/auth", authRoutes);

// Route protégée du dashboard
app.get("/dashboard", requireAuth, async (req, res) => {
    try {
        const user = req.user;
        
        // Get comprehensive clinic data from Firestore
        const clinicDoc = await getDoc(doc(db, 'clinics', user.uid));
        
        let clinicData = {};
        if (clinicDoc.exists()) {
            const data = clinicDoc.data();
            
            // Get profile image with multiple field name support
            const imageFields = [
                'profileImageUrl',
                'imageUrl', 
                'image',
                'profileImage',
                'hospitalImage',
                'logo',
                'avatar',
                'picture'
            ];
            
            let profileImage = null;
            for (const field of imageFields) {
                const imageValue = data[field];
                if (imageValue && imageValue.toString().trim().length > 0) {
                    profileImage = imageValue.toString().trim();
                    break;
                }
            }
            
            // Format schedule for display
            const formatSchedule = (schedule) => {
                if (!schedule || typeof schedule !== 'object') return {};
                
                const formatted = {};
                Object.keys(schedule).forEach(day => {
                    const daySchedule = schedule[day];
                    if (daySchedule && typeof daySchedule === 'object') {
                        if (daySchedule.start === 'Closed' || daySchedule.end === 'Closed') {
                            formatted[day] = 'Closed';
                        } else {
                            formatted[day] = `${daySchedule.start || '08:00'} - ${daySchedule.end || '17:00'}`;
                        }
                    } else {
                        formatted[day] = 'Not set';
                    }
                });
                return formatted;
            };
            
            // Format services for display
            const formatServices = (facilities) => {
                if (Array.isArray(facilities)) {
                    return facilities.filter(service => service && service.trim().length > 0);
                }
                return [];
            };
            
            // Prepare comprehensive clinic data
            clinicData = {
                // Basic Information
                name: data.name || data.clinicName || user.clinicName || 'Clinic Name Not Set',
                clinicName: data.clinicName || data.name || user.clinicName || 'Clinic Name Not Set',
                email: data.email || user.email || 'Email not set',
                phone: data.phone || 'Phone not set',
                
                // Location Information
                address: data.address || 'Address not set',
                city: data.city || 'City not set',
                country: data.country || 'Country not set',
                location: data.location || 'Location not set',
                
                // Profile Information
                about: data.about || 'About information not available',
                description: data.description || data.about || 'Description not available',
                website: data.website || null,
                
                // Services and Schedule
                services: formatServices(data.facilities || data.services),
                facilities: formatServices(data.facilities || data.services),
                schedule: formatSchedule(data.availableSchedule),
                workingHours: formatSchedule(data.availableSchedule),
                
                // Status and Verification
                status: data.status || 'active',
                isVerified: data.isVerified || false,
                
                // Images and Media
                profileImage: profileImage || '/assets/hospital.PNG',
                profileImageUrl: profileImage || '/assets/hospital.PNG',
                
                // Timestamps
                createdAt: data.createdAt || null,
                updatedAt: data.updatedAt || null,
                
                // Additional Information
                meetingDuration: data.meetingDuration || 30,
                specialties: data.specialties || [],
                sector: data.sector || 'Healthcare'
            };
        } else {
            // Default data structure if no clinic document exists
            clinicData = {
                name: user.clinicName || 'Clinic Name Not Set',
                clinicName: user.clinicName || 'Clinic Name Not Set',
                email: user.email || 'Email not set',
                phone: 'Phone not set',
                address: 'Address not set',
                city: 'City not set',
                country: 'Country not set',
                location: 'Location not set',
                about: 'About information not available',
                description: 'Description not available',
                services: [],
                facilities: [],
                schedule: {},
                workingHours: {},
                status: 'active',
                isVerified: false,
                profileImage: '/assets/hospital.PNG',
                profileImageUrl: '/assets/hospital.PNG',
                website: null,
                createdAt: null,
                updatedAt: null,
                meetingDuration: 30,
                specialties: [],
                sector: 'Healthcare'
            };
        }
        
        // Merge user data with clinic data for comprehensive profile
        const completeUserData = {
            ...user,
            ...clinicData,
            // Ensure user fields take precedence for auth-related data
            uid: user.uid,
            email: user.email || clinicData.email
        };
        
        res.render("dashboard-new", { 
            user: completeUserData,
            clinic: clinicData 
        });
    } catch (error) {
        console.error('Error loading dashboard with clinic data:', error);
        // Fallback to basic user data if there's an error
        res.render("dashboard-new", { user: req.user, clinic: null });
    }
});

// Route protégée pour le chat
app.get("/chat", requireAuth, (req, res) => {
    res.render("dashboard-new", { user: req.user, activeTab: 'messages' });
});

// Route protégée des paramètres
app.get("/settings", requireAuth, async (req, res) => {
    try {
        const userId = req.user.uid;
        
        // Fetch hospital data from Firestore
        const clinicDoc = await getDoc(doc(db, 'clinics', userId));
        
        let hospitalData = {
            clinicName: '',
            name: '',
            email: req.user.email || '',
            about: '',
            phone: '',
            address: '',
            sector: '',
            latitude: null,
            longitude: null,
            facilities: [],
            services: [],
            availableSchedule: {},
            meetingDuration: 30,
            profileImageUrl: ''
        };
        
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            hospitalData = {
                clinicName: clinicData.name || clinicData.clinicName || '',
                name: clinicData.name || clinicData.clinicName || '',
                email: req.user.email || clinicData.email || '',
                about: clinicData.about || '',
                phone: clinicData.phone || '',
                address: clinicData.address || '',
                sector: clinicData.sector || '',
                latitude: clinicData.latitude || null,
                longitude: clinicData.longitude || null,
                facilities: clinicData.facilities || clinicData.services || [],
                services: clinicData.facilities || clinicData.services || [],
                availableSchedule: clinicData.availableSchedule || {},
                meetingDuration: clinicData.meetingDuration || 30,
                profileImageUrl: clinicData.profileImageUrl || ''
            };
        }
        
        res.render("settings", { 
            user: {
                ...req.user,
                ...hospitalData
            },
            hospital: hospitalData
        });
    } catch (error) {
        console.error("Error fetching hospital data for settings:", error);
        // Fallback to basic user data
        res.render("settings", { 
            user: req.user,
            hospital: {
                clinicName: '',
                name: '',
                email: req.user.email || '',
                about: '',
                phone: '',
                address: '',
                sector: '',
                latitude: null,
                longitude: null,
                facilities: [],
                services: [],
                availableSchedule: {},
                meetingDuration: 30,
                profileImageUrl: ''
            }
        });
    }
});

// Routes API pour les paramètres
app.post("/api/settings/profile", requireAuth, upload.single('profileImage'), async (req, res) => {
    try {
        const { clinicName, about, meetingDuration } = req.body;
        const userId = req.user.uid;
        const clinicDocRef = doc(db, 'clinics', userId);
        
        let updateData = {
            clinicName,
            name: clinicName,
            about,
            meetingDuration: meetingDuration ? Number(meetingDuration) : 30,
            updatedAt: new Date()
        };

        // Handle image upload if present
        if (req.file) {
            try {
                console.log('📸 Processing image upload...');
                
                // Validate file type
                if (!req.file.mimetype.startsWith('image/')) {
                    return res.status(400).json({
                        success: false,
                        message: "Only image files are allowed"
                    });
                }
                
                // Validate file size (5MB max)
                if (req.file.size > 5 * 1024 * 1024) {
                    return res.status(400).json({
                        success: false,
                        message: "Image size should be less than 5MB"
                    });
                }
                
                // Upload to Firebase Storage
                const fileName = `clinics/${userId}/profile-${Date.now()}.${req.file.originalname.split('.').pop()}`;
                const fileRef = ref(storage, fileName);
                
                console.log('📤 Uploading to Firebase Storage:', fileName);
                
                await uploadBytes(fileRef, req.file.buffer, {
                    contentType: req.file.mimetype,
                });
                
                // Get download URL
                const downloadURL = await getDownloadURL(fileRef);
                updateData.profileImageUrl = downloadURL;
                
                console.log('✅ Image uploaded successfully:', downloadURL);
            } catch (uploadError) {
                console.error('❌ Image upload failed:', uploadError);
                return res.status(500).json({
                    success: false,
                    message: "Image upload failed"
                });
            }
        }
        
        await updateDoc(clinicDocRef, updateData);
        
        res.json({
            success: true,
            message: "Profile updated successfully",
            profileImageUrl: updateData.profileImageUrl
        });
    } catch (error) {
        console.error("Profile update error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to update profile"
        });
    }
});

app.post("/api/settings/contact", requireAuth, upload.none(), async (req, res) => {
    try {
        const { phone, address, sector, latitude, longitude } = req.body;
        const userId = req.user.uid;
        const clinicDocRef = doc(db, 'clinics', userId);
        await updateDoc(clinicDocRef, {
            phone: phone || '',
            address: address || '',
            sector: sector || '',
            latitude: latitude ? Number(latitude) : null,
            longitude: longitude ? Number(longitude) : null,
            updatedAt: new Date()
        });
        res.json({
            success: true,
            message: "Contact details updated successfully"
        });
    } catch (error) {
        console.error("Contact update error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to update contact details"
        });
    }
});

app.post("/api/settings/services", requireAuth, upload.none(), async (req, res) => {
    try {
        let { facilities } = req.body;
        
        // Handle FormData - facilities might be a single value or array
        if (typeof facilities === 'string') {
            facilities = [facilities];
        } else if (!Array.isArray(facilities)) {
            facilities = facilities ? Object.values(facilities) : [];
        }
        
        const userId = req.user.uid;
        const clinicDocRef = doc(db, 'clinics', userId);
        await updateDoc(clinicDocRef, {
            facilities: facilities,
            services: facilities, // Also save as services for Flutter compatibility
            updatedAt: new Date()
        });
        res.json({
            success: true,
            message: "Services updated successfully"
        });
    } catch (error) {
        console.error("Services update error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to update services"
        });
    }
});

app.post("/api/settings/schedule", requireAuth, async (req, res) => {
    try {
        const { availableSchedule } = req.body;
        const userId = req.user.uid;
        const clinicDocRef = doc(db, 'clinics', userId);
        await updateDoc(clinicDocRef, {
            availableSchedule,
            updatedAt: new Date()
        });
        res.json({
            success: true,
            message: "Working hours updated successfully"
        });
    } catch (error) {
        console.error("Schedule update error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to update working hours"
        });
    }
});

app.post("/api/settings/password", requireAuth, async (req, res) => {
    try {
        const { currentPassword, newPassword } = req.body;
        const userId = req.user.uid;
        
        // Ici vous pouvez ajouter la logique pour changer le mot de passe dans Firebase Auth
        
        res.json({
            success: true,
            message: "Password changed successfully"
        });
    } catch (error) {
        console.error("Password change error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to change password"
        });
    }
});

// Route pour l'upload de documents
app.post("/api/settings/upload-documents", requireAuth, async (req, res) => {
    try {
        const userId = req.user.uid;
        
        // Ici vous pouvez ajouter la logique pour uploader les fichiers vers Firebase Storage
        // et sauvegarder les URLs dans Firestore
        // Pour l'instant, on simule un upload réussi
        
        console.log(`Documents uploaded for user: ${userId}`);
        
        res.json({
            success: true,
            message: "Documents uploaded successfully"
        });
    } catch (error) {
        console.error("Document upload error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to upload documents"
        });
    }
});

// Route pour récupérer les données de la clinique (pour profil et paramètres)
app.get("/api/settings/clinic-data", requireAuth, async (req, res) => {
    try {
        const userId = req.user.uid;
        const clinicDoc = await getDoc(doc(db, 'clinics', userId));
        
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            res.json({
                success: true,
                data: {
                    clinicName: clinicData.name || clinicData.clinicName || '',
                    about: clinicData.about || '',
                    phone: clinicData.phone || '',
                    address: clinicData.address || '',
                    sector: clinicData.sector || '',
                    latitude: clinicData.latitude || null,
                    longitude: clinicData.longitude || null,
                    facilities: clinicData.facilities || [],
                    availableSchedule: clinicData.availableSchedule || {},
                    meetingDuration: clinicData.meetingDuration || 30
                }
            });
        } else {
            res.json({
                success: true,
                data: {
                    clinicName: '',
                    about: '',
                    phone: '',
                    address: '',
                    sector: '',
                    latitude: null,
                    longitude: null,
                    facilities: [],
                    availableSchedule: {},
                    meetingDuration: 30
                }
            });
        }
    } catch (error) {
        console.error("Error fetching clinic data:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch clinic data"
        });
    }
});

// Route finale pour récupérer les rendez-vous de la clinique connectée
app.get("/api/appointments/clinic-appointments", requireAuth, async (req, res) => {
    try {
        const userId = req.user.uid;
        
        console.log('=== CLINIC APPOINTMENTS API ===');
        console.log(`User ID: ${userId}`);
        console.log(`User clinic name: ${req.user.clinicName}`);
        
        // Récupérer le nom exact de la clinique
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        let clinicName = req.user.clinicName || "Clinic Name";
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            clinicName = clinicData.name || clinicData.clinicName || clinicName;
        }
        
        console.log('Looking for appointments with hospital name:', clinicName);
        
        // Récupérer TOUS les rendez-vous
        const allAppointmentsRef = collection(db, 'appointments');
        const allAppointmentsSnapshot = await getDocs(allAppointmentsRef);
        
        console.log('Total appointments in database:', allAppointmentsSnapshot.size);
        
        const appointments = [];
        const now = new Date();
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
        
        allAppointmentsSnapshot.forEach((doc) => {
            const data = doc.data();
            const hospitalName = data.hospital || data.hospitalName || '';
            
            console.log(`Appointment ${doc.id}: hospital="${hospitalName}" vs clinic="${clinicName}"`);
            
            // Correspondance exacte du nom de la clinique
            if (hospitalName === clinicName) {
                console.log(`✓ MATCH FOUND for appointment ${doc.id}`);
                
                // Convertir la date
                let appointmentDate = data.appointmentDate || data.date || data.createdAt;
                if (appointmentDate && appointmentDate.toDate) {
                    appointmentDate = appointmentDate.toDate();
                } else if (appointmentDate && appointmentDate.seconds) {
                    appointmentDate = new Date(appointmentDate.seconds * 1000);
                } else if (typeof appointmentDate === 'string') {
                    appointmentDate = new Date(appointmentDate);
                }
                
                // Vérifier si c'est un rendez-vous à venir
                if (appointmentDate && 
                    appointmentDate > now && 
                    appointmentDate < nextWeek &&
                    (data.status === 'pending' || data.status === 'confirmed')) {
                    
                    console.log(`✓ Adding appointment ${doc.id} to results`);
                    appointments.push({
                        id: doc.id,
                        patientName: data.patientName || data.patient || 'Unknown Patient',
                        patientEmail: data.patientEmail || data.email || '',
                        patientPhone: data.patientPhone || data.phone || '',
                        service: data.service || data.department || 'General Consultation',
                        date: appointmentDate,
                        time: data.appointmentTime || data.time || '',
                        status: data.status || 'pending',
                        notes: data.notes || data.reasonOfBooking || '',
                        hospital: hospitalName,
                        duration: data.duration || '30 minutes',
                        createdAt: data.createdAt?.toDate?.() || new Date(),
                        updatedAt: data.updatedAt?.toDate?.() || new Date()
                    });
                } else {
                    console.log(`✗ Appointment ${doc.id} - date or status not matching`);
                }
            } else {
                console.log(`✗ Appointment ${doc.id} - hospital name doesn't match`);
            }
        });
        
        console.log(`Found ${appointments.length} appointments for ${clinicName}`);
        
        // Trier par date
        appointments.sort((a, b) => new Date(a.date) - new Date(b.date));
        
        res.json({
            success: true,
            appointments: appointments,
            totalCount: appointments.length,
            clinicName: clinicName,
            debug: {
                totalAppointmentsInDB: allAppointmentsSnapshot.size,
                clinicName: clinicName,
                foundAppointments: appointments.length
            }
        });
        
    } catch (error) {
        console.error("Appointments API error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch appointments",
            error: error.message
        });
    }
});

// Route pour récupérer les détails d'un rendez-vous
app.get("/api/appointments/:appointmentId", requireAuth, async (req, res) => {
    try {
        const appointmentId = req.params.appointmentId;
        const userId = req.user.uid;
        
        console.log('=== GET APPOINTMENT DETAILS ===');
        console.log(`Appointment ID: ${appointmentId}`);
        console.log(`User ID: ${userId}`);
        
        // Récupérer le nom exact de la clinique
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        let clinicName = req.user.clinicName || "Clinic Name";
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            clinicName = clinicData.name || clinicData.clinicName || clinicName;
        }
        
        // Récupérer le rendez-vous
        const appointmentRef = doc(db, 'appointments', appointmentId);
        const appointmentDoc = await getDoc(appointmentRef);
        
        if (!appointmentDoc.exists()) {
            return res.status(404).json({
                success: false,
                message: "Appointment not found"
            });
        }
        
        const appointmentData = appointmentDoc.data();
        const hospitalName = appointmentData.hospital || appointmentData.hospitalName || '';
        
        console.log(`Appointment hospital: "${hospitalName}" vs clinic: "${clinicName}"`);
        
        // Vérifier que le rendez-vous appartient à cette clinique
        if (hospitalName !== clinicName) {
            return res.status(403).json({
                success: false,
                message: "You don't have permission to view this appointment"
            });
        }
        
        // Préparer les données du rendez-vous
        const appointment = {
            id: appointmentId,
            patientName: appointmentData.patientName || appointmentData.patient || 'Unknown Patient',
            patientEmail: appointmentData.patientEmail || appointmentData.email || '',
            patientPhone: appointmentData.patientPhone || appointmentData.phone || '',
            patientAge: appointmentData.patientAge || appointmentData.age || '',
            hospital: hospitalName,
            service: appointmentData.service || appointmentData.department || 'General Consultation',
            date: appointmentData.appointmentDate || appointmentData.date || appointmentData.createdAt?.toDate?.() || new Date(),
            time: appointmentData.appointmentTime || appointmentData.time || '',
            status: appointmentData.status || 'pending',
            notes: appointmentData.notes || appointmentData.reasonOfBooking || '',
            duration: appointmentData.duration || '30 minutes',
            createdAt: appointmentData.createdAt?.toDate?.() || new Date(),
            updatedAt: appointmentData.updatedAt?.toDate?.() || new Date()
        };
        
        console.log('Appointment details retrieved successfully');
        
        res.json({
            success: true,
            appointment: appointment
        });
        
    } catch (error) {
        console.error("Get appointment details error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch appointment details",
            error: error.message
        });
    }
});

// Route pour approuver un rendez-vous
app.post("/api/appointments/:appointmentId/approve", requireAuth, async (req, res) => {
    try {
        console.log('=== APPROVE APPOINTMENT REQUEST ===');
        console.log('Headers:', req.headers);
        console.log('Body:', req.body);
        console.log('Raw body:', req.rawBody);
        
        const appointmentId = req.params.appointmentId;
        const userId = req.user.uid;
        
        console.log('=== APPROVE APPOINTMENT ===');
        console.log(`Appointment ID: ${appointmentId}`);
        console.log(`User ID: ${userId}`);
        
        // Récupérer le nom exact de la clinique
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        let clinicName = req.user.clinicName || "Clinic Name";
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            clinicName = clinicData.name || clinicData.clinicName || clinicName;
        }
        
        // Récupérer le rendez-vous
        const appointmentRef = doc(db, 'appointments', appointmentId);
        const appointmentDoc = await getDoc(appointmentRef);
        
        if (!appointmentDoc.exists()) {
            return res.status(404).json({
                success: false,
                message: "Appointment not found"
            });
        }
        
        const appointmentData = appointmentDoc.data();
        const hospitalName = appointmentData.hospital || appointmentData.hospitalName || '';
        
        // Vérifier que le rendez-vous appartient à cette clinique
        if (hospitalName !== clinicName) {
            return res.status(403).json({
                success: false,
                message: "You don't have permission to modify this appointment"
            });
        }
        
        // Mettre à jour le statut
        await updateDoc(appointmentRef, {
            status: 'confirmed',
            updatedAt: new Date(),
            approvedBy: userId,
            approvedAt: new Date()
        });
        
        console.log('Appointment approved successfully');
        
        // Créer automatiquement une conversation et envoyer un message de confirmation
        try {
            await createAppointmentConfirmationMessage(appointmentData, clinicName, userId);
            console.log('Confirmation message sent successfully');
        } catch (chatError) {
            console.error('Error sending confirmation message:', chatError);
            // Ne pas échouer la requête si l'envoi du message échoue
        }
        
        res.json({
            success: true,
            message: "Appointment approved successfully"
        });
        
    } catch (error) {
        console.error("Approve appointment error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to approve appointment",
            error: error.message
        });
    }
});

// Route pour rejeter un rendez-vous
app.post("/api/appointments/:appointmentId/reject", requireAuth, async (req, res) => {
    try {
        const appointmentId = req.params.appointmentId;
        const userId = req.user.uid;
        const { reason } = req.body;
        
        console.log('=== REJECT APPOINTMENT ===');
        console.log(`Appointment ID: ${appointmentId}`);
        console.log(`User ID: ${userId}`);
        console.log(`Reason: ${reason}`);
        
        // Récupérer le nom exact de la clinique
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        let clinicName = req.user.clinicName || "Clinic Name";
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            clinicName = clinicData.name || clinicData.clinicName || clinicName;
        }
        
        // Récupérer le rendez-vous
        const appointmentRef = doc(db, 'appointments', appointmentId);
        const appointmentDoc = await getDoc(appointmentRef);
        
        if (!appointmentDoc.exists()) {
            return res.status(404).json({
                success: false,
                message: "Appointment not found"
            });
        }
        
        const appointmentData = appointmentDoc.data();
        const hospitalName = appointmentData.hospital || appointmentData.hospitalName || '';
        
        // Vérifier que le rendez-vous appartient à cette clinique
        if (hospitalName !== clinicName) {
            return res.status(403).json({
                success: false,
                message: "You don't have permission to modify this appointment"
            });
        }
        
        // Mettre à jour le statut
        await updateDoc(appointmentRef, {
            status: 'rejected',
            updatedAt: new Date(),
            rejectedBy: userId,
            rejectedAt: new Date(),
            rejectionReason: reason || 'No reason provided'
        });
        
        console.log('Appointment rejected successfully');
        
        // Créer automatiquement une conversation et envoyer un message de rejet
        try {
            await createAppointmentRejectionMessage(appointmentData, clinicName, userId, reason);
            console.log('Rejection message sent successfully');
        } catch (chatError) {
            console.error('Error sending rejection message:', chatError);
            // Ne pas échouer la requête si l'envoi du message échoue
        }
        
        res.json({
            success: true,
            message: "Appointment rejected successfully"
        });
        
    } catch (error) {
        console.error("Reject appointment error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to reject appointment",
            error: error.message
        });
    }
});

// Route de logout (redirection)
app.get("/logout", (req, res) => {
    res.clearCookie("sessionId");
    res.redirect("/login");
});

// Middleware pour gérer les sessions
app.use((req, res, next) => {
    const sessionId = req.cookies?.sessionId;
    if (sessionId && sessions.has(sessionId)) {
        req.user = sessions.get(sessionId);
    }
    next();
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        success: false,
        message: "Something broke!"
    });
});

// 🔧 Settings API Endpoints
app.post('/api/settings/profile', requireAuth, async (req, res) => {
  try {
    const { clinicName, about } = req.body;
    const user = req.user;

    // Update clinic profile in Firestore
    await updateDoc(doc(db, 'clinics', user.uid), {
      name: clinicName,
      clinicName: clinicName,
      about: about,
      updatedAt: serverTimestamp()
    });

    res.json({
      success: true,
      message: 'Profile updated successfully'
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating profile'
    });
  }
});

app.post('/api/settings/contact', requireAuth, async (req, res) => {
  try {
    const { phone, website, address, city, country, latitude, longitude } = req.body;
    const user = req.user;

    // Update contact information in Firestore
    await updateDoc(doc(db, 'clinics', user.uid), {
      phone: phone,
      website: website,
      address: address,
      city: city,
      country: country,
      latitude: latitude ? parseFloat(latitude) : null,
      longitude: longitude ? parseFloat(longitude) : null,
      updatedAt: serverTimestamp()
    });

    res.json({
      success: true,
      message: 'Contact details updated successfully'
    });
  } catch (error) {
    console.error('Error updating contact details:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating contact details'
    });
  }
});

app.post('/api/settings/services', requireAuth, async (req, res) => {
  try {
    const { facilities, customFacilities } = req.body;
    const user = req.user;

    // Combine predefined and custom facilities
    let allFacilities = facilities || [];
    if (customFacilities) {
      const customArray = customFacilities.split(',').map(item => item.trim()).filter(item => item.length > 0);
      allFacilities = [...allFacilities, ...customArray];
    }

    // Update facilities in Firestore
    await updateDoc(doc(db, 'clinics', user.uid), {
      facilities: allFacilities,
      updatedAt: serverTimestamp()
    });

    res.json({
      success: true,
      message: 'Services updated successfully'
    });
  } catch (error) {
    console.error('Error updating services:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating services'
    });
  }
});

app.post('/api/settings/schedule', requireAuth, async (req, res) => {
  try {
    const user = req.user;
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    const schedule = {};

    days.forEach(day => {
      const startTime = req.body[`${day}_start`];
      const endTime = req.body[`${day}_end`];
      const isClosed = req.body[`${day}_closed`] === 'on';

      if (isClosed) {
        schedule[day.charAt(0).toUpperCase() + day.slice(1)] = {
          start: 'Closed',
          end: 'Closed'
        };
      } else {
        schedule[day.charAt(0).toUpperCase() + day.slice(1)] = {
          start: startTime || '08:00',
          end: endTime || '17:00'
        };
      }
    });

    // Update schedule in Firestore
    await updateDoc(doc(db, 'clinics', user.uid), {
      availableSchedule: schedule,
      updatedAt: serverTimestamp()
    });

    res.json({
      success: true,
      message: 'Schedule updated successfully'
    });
  } catch (error) {
    console.error('Error updating schedule:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating schedule'
    });
  }
});

app.post('/api/settings/password', requireAuth, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = req.user;

    // For password changes, we need to use Firebase Auth admin
    // This is a simplified version - in production, you'd want more robust password verification
    await admin.auth().updateUser(user.uid, {
      password: newPassword
    });

    res.json({
      success: true,
      message: 'Password updated successfully'
    });
  } catch (error) {
    console.error('Error updating password:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating password'
    });
  }
});

// 🔧 Hospital Image API Endpoint  
app.get('/api/settings/hospital-image', requireAuth, async (req, res) => {
  try {
    const user = req.user;
    
    // Get clinic document from Firestore
    const clinicDoc = await getDoc(doc(db, 'clinics', user.uid));
    
    if (clinicDoc.exists()) {
      const clinicData = clinicDoc.data();
      
      // Try multiple potential image field names
      const imageFields = [
        'profileImageUrl',
        'imageUrl', 
        'image',
        'profileImage',
        'hospitalImage',
        'logo',
        'avatar',
        'picture'
      ];
      
      let hospitalImage = null;
      for (const field of imageFields) {
        const imageValue = clinicData[field];
        if (imageValue && imageValue.toString().trim().length > 0) {
          hospitalImage = imageValue.toString().trim();
          console.log(`Found hospital image in field "${field}": ${hospitalImage.substring(0, 50)}...`);
          break;
        }
      }
      
      res.json({
        success: true,
        imageUrl: hospitalImage || '/assets/hospital.PNG'
      });
    } else {
      res.json({
        success: true,
        imageUrl: '/assets/hospital.PNG'
      });
    }
  } catch (error) {
    console.error('Error getting hospital image:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting hospital image',
      imageUrl: '/assets/hospital.PNG'
    });
  }
});

// Route pour récupérer l'image de l'hôpital
app.get("/api/settings/hospital-image", requireAuth, async (req, res) => {
    try {
        const userId = req.user.uid;
        const clinicDoc = await getDoc(doc(db, 'clinics', userId));
        
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            res.json({
                success: true,
                imageUrl: clinicData.profileImageUrl || '/assets/hospital.PNG'
            });
        } else {
            res.json({
                success: true,
                imageUrl: '/assets/hospital.PNG'
            });
        }
    } catch (error) {
        console.error("Error fetching hospital image:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch hospital image"
        });
    }
});

// Start server
app.listen(PORT, () => {
    console.log("Server running on http://localhost:" + PORT);
    console.log("Dashboard: http://localhost:" + PORT + "/dashboard");
    console.log("Settings: http://localhost:" + PORT + "/settings");
    console.log("Demo Login: admin@homecare.com / admin123");
    console.log("Register: http://localhost:" + PORT + "/register");
});// Graceful shutdown
process.on("SIGINT", () => {
    console.log("Shutting down server gracefully...");
    process.exit(0);
});process.on("SIGTERM", () => {
    console.log("Shutting down server gracefully...");
    process.exit(0);
});

// API pour envoyer un message de confirmation de rendez-vous via le chat
app.post('/api/appointments/:appointmentId/send-confirmation-message', async (req, res) => {
  try {
    const { appointmentId } = req.params;
    const { clinicId, clinicName } = req.body;

    console.log('=== SENDING APPOINTMENT CONFIRMATION MESSAGE ===');
    console.log('Appointment ID:', appointmentId);
    console.log('Clinic ID:', clinicId);
    console.log('Clinic Name:', clinicName);

    // Récupérer les détails du rendez-vous
    const appointmentDoc = await admin.firestore()
      .collection('appointments')
      .doc(appointmentId)
      .get();

    if (!appointmentDoc.exists) {
      return res.status(404).json({ 
        success: false, 
        message: 'Appointment not found' 
      });
    }

    const appointmentData = appointmentDoc.data();
    const patientId = appointmentData.patientId;
    const patientName = appointmentData.patientName;
    const hospitalName = appointmentData.hospitalName;
    const department = appointmentData.department;
    const appointmentDate = appointmentData.appointmentDate.toDate();
    const appointmentTime = appointmentData.appointmentTime;

    console.log('Patient ID:', patientId);
    console.log('Patient Name:', patientName);
    console.log('Hospital Name:', hospitalName);
    console.log('Department:', department);
    console.log('Appointment Date:', appointmentDate);
    console.log('Appointment Time:', appointmentTime);

    // Créer ou obtenir la conversation
    const conversationQuery = await admin.firestore()
      .collection('chat_conversations')
      .where('patientId', '==', patientId)
      .where('clinicId', '==', clinicId)
      .get();

    let conversationId;
    if (conversationQuery.empty) {
      // Créer une nouvelle conversation
      const conversationData = {
        patientId: patientId,
        clinicId: clinicId,
        patientName: patientName,
        clinicName: clinicName,
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: 'Appointment confirmed',
        hasUnreadMessages: true,
        unreadCount: 1,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const conversationRef = await admin.firestore()
        .collection('chat_conversations')
        .add(conversationData);
      
      conversationId = conversationRef.id;
      console.log('New conversation created:', conversationId);
    } else {
      conversationId = conversationQuery.docs[0].id;
      console.log('Existing conversation found:', conversationId);
    }

    // Créer le message de confirmation
    const confirmationMessage = `🎉 **Appointment Confirmed!**

Your appointment has been confirmed by **${clinicName}**.

**Details:**
• **Hospital:** ${hospitalName}
• **Department:** ${department}
• **Date:** ${appointmentDate.toLocaleDateString()}
• **Time:** ${appointmentTime}

Please arrive 15 minutes before your scheduled time. If you need to reschedule or cancel, please contact us as soon as possible.

Thank you for choosing our services!`;

    // Ajouter le message à la conversation
    const messageData = {
      conversationId: conversationId,
      senderId: clinicId,
      senderName: clinicName,
      senderType: 'clinic',
      message: confirmationMessage,
      messageType: 'appointmentConfirmation',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      appointmentId: appointmentId,
      hospitalName: hospitalName,
      department: department,
      appointmentDate: appointmentData.appointmentDate,
      appointmentTime: appointmentTime,
      metadata: {
        action: 'appointment_confirmed',
        appointmentId: appointmentId,
      },
    };

    await admin.firestore()
      .collection('chat_messages')
      .add(messageData);

    // Mettre à jour la conversation
    await admin.firestore()
      .collection('chat_conversations')
      .doc(conversationId)
      .update({
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: 'Appointment confirmed',
        hasUnreadMessages: true,
        unreadCount: 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log('✓ Confirmation message sent successfully');

    res.json({
      success: true,
      message: 'Confirmation message sent successfully',
      conversationId: conversationId,
    });

  } catch (error) {
    console.error('Error sending confirmation message:', error);
    res.status(500).json({
      success: false,
      message: 'Error sending confirmation message',
      error: error.message,
    });
  }
});

// API pour envoyer un message d'annulation de rendez-vous via le chat
app.post('/api/appointments/:appointmentId/send-cancellation-message', async (req, res) => {
  try {
    const { appointmentId } = req.params;
    const { clinicId, clinicName, reason } = req.body;

    console.log('=== SENDING APPOINTMENT CANCELLATION MESSAGE ===');
    console.log('Appointment ID:', appointmentId);
    console.log('Clinic ID:', clinicId);
    console.log('Clinic Name:', clinicName);
    console.log('Reason:', reason);

    // Récupérer les détails du rendez-vous
    const appointmentDoc = await admin.firestore()
      .collection('appointments')
      .doc(appointmentId)
      .get();

    if (!appointmentDoc.exists) {
      return res.status(404).json({ 
        success: false, 
        message: 'Appointment not found' 
      });
    }

    const appointmentData = appointmentDoc.data();
    const patientId = appointmentData.patientId;
    const patientName = appointmentData.patientName;
    const hospitalName = appointmentData.hospitalName;
    const department = appointmentData.department;
    const appointmentDate = appointmentData.appointmentDate.toDate();
    const appointmentTime = appointmentData.appointmentTime;

    // Créer ou obtenir la conversation
    const conversationQuery = await admin.firestore()
      .collection('chat_conversations')
      .where('patientId', '==', patientId)
      .where('clinicId', '==', clinicId)
      .get();

    let conversationId;
    if (conversationQuery.empty) {
      // Créer une nouvelle conversation
      const conversationData = {
        patientId: patientId,
        clinicId: clinicId,
        patientName: patientName,
        clinicName: clinicName,
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: 'Appointment cancelled',
        hasUnreadMessages: true,
        unreadCount: 1,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      const conversationRef = await admin.firestore()
        .collection('chat_conversations')
        .add(conversationData);
      
      conversationId = conversationRef.id;
    } else {
      conversationId = conversationQuery.docs[0].id;
    }

    // Créer le message d'annulation
    const cancellationMessage = `❌ **Appointment Cancelled**

Your appointment has been cancelled by **${clinicName}**.

**Details:**
• **Hospital:** ${hospitalName}
• **Department:** ${department}
• **Date:** ${appointmentDate.toLocaleDateString()}
• **Time:** ${appointmentTime}
${reason ? `• **Reason:** ${reason}` : ''}

Please contact us to reschedule your appointment at your convenience.

We apologize for any inconvenience caused.`;

    // Ajouter le message à la conversation
    const messageData = {
      conversationId: conversationId,
      senderId: clinicId,
      senderName: clinicName,
      senderType: 'clinic',
      message: cancellationMessage,
      messageType: 'appointmentCancellation',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      appointmentId: appointmentId,
      hospitalName: hospitalName,
      department: department,
      appointmentDate: appointmentData.appointmentDate,
      appointmentTime: appointmentTime,
      metadata: {
        action: 'appointment_cancelled',
        appointmentId: appointmentId,
        reason: reason,
      },
    };

    await admin.firestore()
      .collection('chat_messages')
      .add(messageData);

    // Mettre à jour la conversation
    await admin.firestore()
      .collection('chat_conversations')
      .doc(conversationId)
      .update({
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
        lastMessage: 'Appointment cancelled',
        hasUnreadMessages: true,
        unreadCount: 1,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    console.log('✓ Cancellation message sent successfully');

    res.json({
      success: true,
      message: 'Cancellation message sent successfully',
      conversationId: conversationId,
    });

  } catch (error) {
    console.error('Error sending cancellation message:', error);
    res.status(500).json({
      success: false,
      message: 'Error sending cancellation message',
      error: error.message,
    });
  }
});

// API pour récupérer les informations de la clinique connectée
app.get('/api/clinic/info', async (req, res) => {
  try {
    // Vérifier si l'utilisateur est connecté
    if (!req.session.userId) {
      return res.status(401).json({
        success: false,
        message: 'User not authenticated'
      });
    }

    const clinicId = req.session.userId;
    
    // Récupérer les informations de la clinique depuis Firestore
    const clinicDoc = await admin.firestore()
      .collection('clinics')
      .doc(clinicId)
      .get();

    if (!clinicDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Clinic not found'
      });
    }

    const clinicData = clinicDoc.data();
    
    res.json({
      success: true,
      clinicId: clinicId,
      clinicName: clinicData.name || clinicData.clinicName || 'Health Center',
      email: clinicData.email,
      phone: clinicData.phone,
      address: clinicData.address,
      specialties: clinicData.specialties || [],
    });

  } catch (error) {
    console.error('Error getting clinic info:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving clinic information',
      error: error.message
    });
  }
});

// Import du nouveau système de chat simplifié (SANS INDEX FIRESTORE)
const { getHospitalConversations, getConversationMessages, sendMessage, markConversationAsRead, deleteConversation, getHospitalConversationsFiltered } = require('./fix-chat-no-index.js');

// Route pour récupérer les conversations de la clinique (Version simplifiée sans index)
app.get("/api/chat/clinic-conversations", requireAuth, getHospitalConversations);

// 🔧 FIX: Add missing /api/chat/conversations endpoint (alias for clinic-conversations)
app.get("/api/chat/conversations", requireAuth, getHospitalConversations);

// Route pour récupérer les messages d'une conversation (Version simplifiée sans index)
app.get("/api/chat/conversation/:conversationId/messages", requireAuth, getConversationMessages);

// Route pour marquer les messages comme lus (Version simplifiée sans index)
app.post("/api/chat/mark-as-read/:conversationId", requireAuth, markConversationAsRead);

// 🗑️ Route pour supprimer une conversation
app.delete("/api/chat/conversation/:conversationId", requireAuth, deleteConversation);

// 📋 Route pour récupérer les conversations filtrées (non supprimées)
app.get("/api/chat/clinic-conversations-filtered", requireAuth, getHospitalConversationsFiltered);

// 🔧 FIX: Send message endpoint for hospital dashboard (Fixed duplicate issue)
app.post('/api/chat/send-message', requireAuth, async (req, res) => {
  try {
    const { conversationId, message, messageType = 'text' } = req.body;
    const user = req.user;
    
    console.log('🏥 Hospital sending message:', { conversationId, message, messageType, userId: user?.uid });
    
    if (!user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    
    if (!conversationId || !message) {
      return res.status(400).json({ success: false, error: 'Missing conversationId or message content' });
    }

    // Verify conversation belongs to this clinic
    const conversationRef = doc(db, 'chat_conversations', conversationId);
    const conversationDoc = await getDoc(conversationRef);
    
    if (!conversationDoc.exists()) {
      return res.status(404).json({ success: false, error: 'Conversation not found' });
    }
    
    const conversationData = conversationDoc.data();
    if (conversationData.clinicId !== user.uid) {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }
    
    // Get clinic information
    let senderName = user.displayName || 'Hospital';
    let hospitalImage = null;
    
    try {
      const clinicDoc = await getDoc(doc(db, 'clinics', user.uid));
      if (clinicDoc.exists()) {
        const clinicData = clinicDoc.data();
        senderName = clinicData.name || clinicData.clinicName || senderName;
        
        // 🔧 FIX: Try multiple potential image field names for hospitals
        const imageFields = [
          'imageUrl',
          'profileImageUrl', 
          'image',
          'profileImage',
          'hospitalImage',
          'logo',
          'avatar',
          'picture'
        ];
        
        for (const field of imageFields) {
          const imageValue = clinicData[field];
          if (imageValue && imageValue.toString().trim() !== '' && imageValue.toString() !== 'null') {
            hospitalImage = imageValue.toString();
            console.log(`🏥 Found hospital image using field "${field}": ${hospitalImage.length > 50 ? hospitalImage.substring(0, 50) + "..." : hospitalImage}`);
            break;
          }
        }
        
        if (!hospitalImage) {
          console.log('⚠️ No hospital image found for clinic:', user.uid);
          console.log('Available fields:', Object.keys(clinicData));
        }
      } else {
        console.log('⚠️ Clinic document not found for user:', user.uid);
      }
    } catch (error) {
      console.log('⚠️ Could not fetch clinic info:', error.message);
    }

    // Create the message
    const messageData = {
      conversationId: conversationId,
      senderId: user.uid,
      senderName: senderName,
      senderType: 'clinic',
      message: message,
      messageType: messageType,
      timestamp: serverTimestamp(),
      isRead: false,
      hospitalImage: hospitalImage,
      hospitalName: senderName,
    };
    
    const messageRef = await addDoc(collection(db, 'chat_messages'), messageData);
    
    // Update conversation
    await updateDoc(conversationRef, {
      lastMessageTime: serverTimestamp(),
      lastMessage: message.substring(0, 100) + (message.length > 100 ? '...' : ''),
      hasUnreadMessages: true,
      unreadCount: increment(1),
      updatedAt: serverTimestamp()
    });
    
    console.log('✅ Message sent successfully');
    
    res.json({ 
      success: true, 
      messageId: messageRef.id,
      message: "Message sent successfully"
    });
    
  } catch (error) {
    console.error('❌ Error in sendMessage:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to send message',
      details: error.message 
    });
  }
});

// 🔧 FIX: Get hospital image for settings API
app.get('/api/settings/hospital-image', requireAuth, async (req, res) => {
  try {
    const user = req.user;
    
    console.log(`🏥 Getting hospital image for user: ${user.uid}`);
    
    // Try to get hospital info from clinics collection
    const clinicDoc = await getDoc(doc(db, 'clinics', user.uid));
    
    if (clinicDoc.exists()) {
      const clinicData = clinicDoc.data();
      
      // 🔧 FIX: Try multiple potential image field names for hospitals
      const imageFields = [
        'imageUrl',
        'profileImageUrl', 
        'image',
        'profileImage',
        'hospitalImage',
        'logo',
        'avatar',
        'picture'
      ];
      
      let hospitalImage = null;
      for (const field of imageFields) {
        const imageValue = clinicData[field];
        if (imageValue && imageValue.toString().trim() !== '' && imageValue.toString() !== 'null') {
          hospitalImage = imageValue.toString();
          console.log(`✅ Found hospital image using field "${field}": ${hospitalImage.length > 50 ? hospitalImage.substring(0, 50) + "..." : hospitalImage}`);
          break;
        }
      }
      
      if (hospitalImage) {
        res.json({
          success: true,
          imageUrl: hospitalImage
        });
      } else {
        console.log('⚠️ Hospital document exists but no valid image found for clinic:', user.uid);
        res.json({
          success: true,
          imageUrl: null
        });
      }
    } else {
      console.log('❌ Hospital document not found for user:', user.uid);
      res.json({
        success: true,
        imageUrl: null
      });
    }
  } catch (error) {
    console.error('❌ Error getting hospital image:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// 🔧 FIX: Get patient avatar for hospital chat
app.get('/api/chat/patient-avatar/:patientId', requireAuth, async (req, res) => {
  try {
    const { patientId } = req.params;
    
    console.log(`🔍 Looking for patient avatar with ID: ${patientId}`);
    
    // Try to get patient info from users collection
    const userDoc = await getDoc(doc(db, 'users', patientId));
    
    if (userDoc.exists()) {
      const userData = userDoc.data();
      
      // 🔧 FIX: Try multiple potential image field names for patients
      const imageFields = [
        'profileImage',
        'imageUrl', 
        'profileImageUrl',
        'avatar',
        'photoURL',
        'image',
        'picture'
      ];
      
      let avatar = null;
      for (const field of imageFields) {
        const imageValue = userData[field];
        if (imageValue && imageValue.toString().trim() !== '' && imageValue.toString() !== 'null') {
          avatar = imageValue.toString();
          console.log(`✅ Found patient avatar using field "${field}": ${avatar.length > 50 ? avatar.substring(0, 50) + "..." : avatar}`);
          break;
        }
      }
      
      if (!avatar) {
        console.log('⚠️ Patient document exists but no valid image found in any field for patient:', patientId);
        console.log('Available fields:', Object.keys(userData));
      }
      
      res.json({
        success: true,
        avatar: avatar,
        name: userData.name || userData.fullName || userData.displayName || 'Patient'
      });
    } else {
      console.log('❌ Patient document not found for ID:', patientId);
      res.json({
        success: true,
        avatar: null,
        name: 'Patient'
      });
    }
  } catch (error) {
    console.error('❌ Error getting patient avatar:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// 🔧 FIX: Mark conversation as read for notification system
app.post('/api/chat/mark-read', requireAuth, async (req, res) => {
  try {
    const { conversationId } = req.body;
    const user = req.user;
    
    console.log('📖 Marking conversation as read:', { conversationId, userId: user?.uid });
    
    if (!user) {
      return res.status(401).json({ success: false, error: 'Unauthorized' });
    }
    
    if (!conversationId) {
      return res.status(400).json({ success: false, error: 'Missing conversationId' });
    }

    // Verify conversation belongs to this clinic
    const conversationRef = doc(db, 'chat_conversations', conversationId);
    const conversationDoc = await getDoc(conversationRef);
    
    if (!conversationDoc.exists()) {
      return res.status(404).json({ success: false, error: 'Conversation not found' });
    }
    
    const conversationData = conversationDoc.data();
    if (conversationData.clinicId !== user.uid) {
      return res.status(403).json({ success: false, error: 'Access denied' });
    }
    
    // Mark conversation as read
    await updateDoc(conversationRef, {
      hasUnreadMessages: false,
      unreadCount: 0,
      updatedAt: serverTimestamp(),
    });
    
    // Mark all messages in this conversation as read
    const messagesQuery = query(
      collection(db, 'chat_messages'),
      where('conversationId', '==', conversationId),
      where('isRead', '==', false)
    );
    
    const messagesSnapshot = await getDocs(messagesQuery);
    const batch = writeBatch(db);
    
    messagesSnapshot.docs.forEach(messageDoc => {
      batch.update(messageDoc.ref, { isRead: true });
    });
    
    await batch.commit();
    
    console.log('✅ Conversation and messages marked as read successfully');
    
    res.json({ 
      success: true, 
      message: 'Conversation marked as read',
      updatedMessages: messagesSnapshot.docs.length
    });
    
  } catch (error) {
    console.error('❌ Error marking conversation as read:', error);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
});

// Fonction pour créer un message de confirmation de rendez-vous
async function createAppointmentConfirmationMessage(appointmentData, clinicName, clinicId) {
  try {
    console.log('=== CREATING APPOINTMENT CONFIRMATION MESSAGE ===');
    
    const patientId = appointmentData.patientId;
    const patientName = appointmentData.patientName;
    const hospitalName = appointmentData.hospital || appointmentData.hospitalName;
    const department = appointmentData.department;
    const appointmentDate = appointmentData.appointmentDate;
    const appointmentTime = appointmentData.appointmentTime;
    const appointmentId = appointmentData.id || appointmentData.appointmentId || null;

    // Gérer le champ date (Timestamp ou Date)
    let appointmentDateObj;
    if (appointmentDate instanceof admin.firestore.Timestamp) {
      appointmentDateObj = appointmentDate.toDate();
    } else if (appointmentDate instanceof Date) {
      appointmentDateObj = appointmentDate;
    } else {
      appointmentDateObj = new Date(appointmentDate);
    }

    // Récupérer l'image de l'hôpital depuis la collection clinics
    let hospitalImage = null;
    try {
      const clinicDoc = await admin.firestore()
        .collection('clinics')
        .doc(clinicId)
        .get();
      
      if (clinicDoc.exists) {
        const clinicData = clinicDoc.data();
        
        // 🔧 FIX: Try multiple potential image field names for hospitals
        const imageFields = [
          'imageUrl',
          'profileImageUrl', 
          'image',
          'profileImage',
          'hospitalImage',
          'logo',
          'avatar',
          'picture'
        ];
        
        for (const field of imageFields) {
          const imageValue = clinicData[field];
          if (imageValue && imageValue.toString().trim() !== '' && imageValue.toString() !== 'null') {
            hospitalImage = imageValue.toString();
            console.log(`🏥 Hospital image found using field "${field}": ${hospitalImage.length > 50 ? hospitalImage.substring(0, 50) + "..." : hospitalImage}`);
            break;
          }
        }
        
        if (!hospitalImage) {
          console.log('⚠️ Hospital document exists but no valid image found in any field for clinic:', clinicId);
          console.log('Available fields:', Object.keys(clinicData));
        }
      } else {
        console.log('❌ Hospital document not found for clinic ID:', clinicId);
      }
    } catch (error) {
      console.log('⚠️ Could not fetch hospital image:', error.message);
    }

    // Créer ou obtenir la conversation
    const conversationQuery = await getDocs(
      query(
        collection(db, 'chat_conversations'),
        where('patientId', '==', patientId),
        where('clinicId', '==', clinicId)
      )
    );

    let conversationId;
    if (conversationQuery.empty) {
      // Créer une nouvelle conversation
      const conversationData = {
        patientId: patientId,
        clinicId: clinicId,
        patientName: patientName,
        clinicName: hospitalName, // Utiliser le nom de l'hôpital du rendez-vous
        hospitalImage: hospitalImage, // Ajouter l'image de l'hôpital
        lastMessageTime: serverTimestamp(),
        lastMessage: 'Appointment confirmed',
        hasUnreadMessages: true,
        unreadCount: 1,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };

      const conversationRef = await addDoc(collection(db, 'chat_conversations'), conversationData);
      conversationId = conversationRef.id;
      console.log('✅ New conversation created:', conversationId);
    } else {
      conversationId = conversationQuery.docs[0].id;
      console.log('✅ Existing conversation found:', conversationId);
      
      // Mettre à jour l'image de l'hôpital si elle n'existe pas
      const existingConversation = conversationQuery.docs[0].data();
      if (!existingConversation.hospitalImage && hospitalImage) {
        await updateDoc(doc(db, 'chat_conversations', conversationId), {
          hospitalImage: hospitalImage,
        });
        console.log('✅ Updated conversation with hospital image');
      }
    }

    // Créer le message de confirmation
    const confirmationMessage = `✅ **Appointment Confirmed**

Your appointment has been confirmed by **${hospitalName}**.

**Details:**
• **Hospital:** ${hospitalName}
• **Department:** ${department}
• **Date:** ${appointmentDateObj.toLocaleDateString()}
• **Time:** ${appointmentTime}

Please arrive 15 minutes before your scheduled time. If you need to reschedule or cancel, please contact us at least 24 hours in advance.

We look forward to seeing you!`;

    // Ajouter le message à la conversation
    const messageData = {
      conversationId: conversationId,
      senderId: clinicId,
      senderName: hospitalName, // Utiliser le nom de l'hôpital du rendez-vous
      senderType: 'clinic',
      message: confirmationMessage,
      messageType: 'appointmentConfirmation',
      timestamp: serverTimestamp(),
      isRead: false,
      appointmentId: appointmentId,
      hospitalName: hospitalName,
      hospitalImage: hospitalImage, // Ajouter l'image de l'hôpital
      department: department,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      metadata: {
        action: 'appointment_confirmed',
        appointmentId: appointmentId,
      },
    };

    await addDoc(collection(db, 'chat_messages'), messageData);
    console.log('✅ Confirmation message created');

    // Mettre à jour la conversation
    await updateDoc(doc(db, 'chat_conversations', conversationId), {
      lastMessageTime: serverTimestamp(),
      lastMessage: 'Appointment confirmed',
      hasUnreadMessages: true,
      unreadCount: increment(1),
      updatedAt: serverTimestamp(),
    });

    console.log('✅ Conversation updated');
    return { success: true, conversationId: conversationId };

  } catch (error) {
    console.error('❌ Error creating confirmation message:', error);
    return { success: false, error: error.message };
  }
}

// Fonction pour créer un message de rejet de rendez-vous
async function createAppointmentRejectionMessage(appointmentData, clinicName, clinicId, reason) {
  try {
    console.log('=== CREATING APPOINTMENT REJECTION MESSAGE ===');
    
    const patientId = appointmentData.patientId;
    const patientName = appointmentData.patientName;
    const hospitalName = appointmentData.hospital || appointmentData.hospitalName;
    const department = appointmentData.department;
    const appointmentDate = appointmentData.appointmentDate;
    const appointmentTime = appointmentData.appointmentTime;

    // Gérer le champ date (Timestamp ou Date)
    let appointmentDateObj;
    if (appointmentDate instanceof admin.firestore.Timestamp) {
      appointmentDateObj = appointmentDate.toDate();
    } else if (appointmentDate instanceof Date) {
      appointmentDateObj = appointmentDate;
    } else {
      appointmentDateObj = new Date(appointmentDate);
    }

    // Récupérer l'image de l'hôpital depuis la collection clinics
    let hospitalImage = null;
    try {
      const clinicDoc = await admin.firestore()
        .collection('clinics')
        .doc(clinicId)
        .get();
      
      if (clinicDoc.exists) {
        const clinicData = clinicDoc.data();
        
        // 🔧 FIX: Try multiple potential image field names for hospitals
        const imageFields = [
          'imageUrl',
          'profileImageUrl', 
          'image',
          'profileImage',
          'hospitalImage',
          'logo',
          'avatar',
          'picture'
        ];
        
        for (const field of imageFields) {
          const imageValue = clinicData[field];
          if (imageValue && imageValue.toString().trim() !== '' && imageValue.toString() !== 'null') {
            hospitalImage = imageValue.toString();
            console.log(`🏥 Hospital image found using field "${field}": ${hospitalImage.length > 50 ? hospitalImage.substring(0, 50) + "..." : hospitalImage}`);
            break;
          }
        }
        
        if (!hospitalImage) {
          console.log('⚠️ Hospital document exists but no valid image found in any field for clinic:', clinicId);
          console.log('Available fields:', Object.keys(clinicData));
        }
      } else {
        console.log('❌ Hospital document not found for clinic ID:', clinicId);
      }
    } catch (error) {
      console.log('⚠️ Could not fetch hospital image:', error.message);
    }

    // Créer ou obtenir la conversation
    const conversationQuery = await getDocs(
      query(
        collection(db, 'chat_conversations'),
        where('patientId', '==', patientId),
        where('clinicId', '==', clinicId)
      )
    );

    let conversationId;
    if (conversationQuery.empty) {
      // Créer une nouvelle conversation
      const conversationData = {
        patientId: patientId,
        clinicId: clinicId,
        patientName: patientName,
        clinicName: hospitalName, // Utiliser le nom de l'hôpital du rendez-vous
        hospitalImage: hospitalImage, // Ajouter l'image de l'hôpital
        lastMessageTime: serverTimestamp(),
        lastMessage: 'Appointment rejected',
        hasUnreadMessages: true,
        unreadCount: 1,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };

      const conversationRef = await addDoc(collection(db, 'chat_conversations'), conversationData);
      conversationId = conversationRef.id;
      console.log('✅ New conversation created:', conversationId);
    } else {
      conversationId = conversationQuery.docs[0].id;
      console.log('✅ Existing conversation found:', conversationId);
      
      // Mettre à jour l'image de l'hôpital si elle n'existe pas
      const existingConversation = conversationQuery.docs[0].data();
      if (!existingConversation.hospitalImage && hospitalImage) {
        await updateDoc(doc(db, 'chat_conversations', conversationId), {
          hospitalImage: hospitalImage,
        });
        console.log('✅ Updated conversation with hospital image');
      }
    }

    // Créer le message de rejet
    const rejectionMessage = `❌ **Appointment Rejected**

Your appointment request has been rejected by **${hospitalName}**.

**Details:**
• **Hospital:** ${hospitalName}
• **Department:** ${department}
• **Date:** ${appointmentDateObj.toLocaleDateString()}
• **Time:** ${appointmentTime}
• **Reason:** ${reason || 'No specific reason provided'}

Please contact us if you have any questions or would like to book a different appointment.

We apologize for any inconvenience.`;

    // Ajouter le message à la conversation
    const messageData = {
      conversationId: conversationId,
      senderId: clinicId,
      senderName: hospitalName, // Utiliser le nom de l'hôpital du rendez-vous
      senderType: 'clinic',
      message: rejectionMessage,
      messageType: 'appointmentCancellation',
      timestamp: serverTimestamp(),
      isRead: false,
      appointmentId: null,
      hospitalName: hospitalName,
      hospitalImage: hospitalImage, // Ajouter l'image de l'hôpital
      department: department,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      metadata: {
        action: 'appointment_rejected',
        reason: reason,
      },
    };

    await addDoc(collection(db, 'chat_messages'), messageData);
    console.log('✅ Rejection message created');

    // Mettre à jour la conversation
    await updateDoc(doc(db, 'chat_conversations', conversationId), {
      lastMessageTime: serverTimestamp(),
      lastMessage: 'Appointment rejected',
      hasUnreadMessages: true,
      unreadCount: increment(1),
      updatedAt: serverTimestamp(),
    });

    console.log('✅ Conversation updated');
    return { success: true, conversationId: conversationId };

  } catch (error) {
    console.error('❌ Error creating rejection message:', error);
    return { success: false, error: error.message };
  }
}

// 🔧 Enhanced Profile API Endpoint - Get complete clinic profile data
app.get('/api/profile/clinic-data', requireAuth, async (req, res) => {
  try {
    const user = req.user;
    
    // Get clinic document from Firestore
    const clinicDoc = await getDoc(doc(db, 'clinics', user.uid));
    
    if (clinicDoc.exists()) {
      const clinicData = clinicDoc.data();
      
      // Get profile image with multiple field name support
      const imageFields = [
        'profileImageUrl',
        'imageUrl', 
        'image',
        'profileImage',
        'hospitalImage',
        'logo',
        'avatar',
        'picture'
      ];
      
      let profileImage = null;
      for (const field of imageFields) {
        const imageValue = clinicData[field];
        if (imageValue && imageValue.toString().trim().length > 0) {
          profileImage = imageValue.toString().trim();
          break;
        }
      }
      
      // Format schedule for better display
      const formatSchedule = (schedule) => {
        if (!schedule || typeof schedule !== 'object') return {};
        
        const formatted = {};
        Object.keys(schedule).forEach(day => {
          const daySchedule = schedule[day];
          if (daySchedule && typeof daySchedule === 'object') {
            if (daySchedule.start === 'Closed' || daySchedule.end === 'Closed') {
              formatted[day] = 'Closed';
            } else {
              formatted[day] = `${daySchedule.start || '08:00'} - ${daySchedule.end || '17:00'}`;
            }
          } else {
            formatted[day] = 'Not set';
          }
        });
        return formatted;
      };
      
      // Format facilities/services for display
      const formatServices = (facilities) => {
        if (Array.isArray(facilities)) {
          return facilities.filter(service => service && service.trim().length > 0);
        }
        return [];
      };
      
      // Prepare comprehensive profile data
      const profileData = {
        // Basic Information
        name: clinicData.name || clinicData.clinicName || 'Clinic Name Not Set',
        clinicName: clinicData.clinicName || clinicData.name || 'Clinic Name Not Set',
        email: clinicData.email || 'Email not set',
        phone: clinicData.phone || 'Phone not set',
        
        // Location Information
        address: clinicData.address || 'Address not set',
        city: clinicData.city || 'City not set',
        country: clinicData.country || 'Country not set',
        location: clinicData.location || 'Location not set',
        
        // Profile Information
        about: clinicData.about || 'About information not available',
        description: clinicData.description || clinicData.about || 'Description not available',
        website: clinicData.website || null,
        
        // Services and Schedule
        services: formatServices(clinicData.facilities || clinicData.services),
        facilities: formatServices(clinicData.facilities || clinicData.services),
        schedule: formatSchedule(clinicData.availableSchedule),
        workingHours: formatSchedule(clinicData.availableSchedule),
        
        // Status and Verification
        status: clinicData.status || 'active',
        isVerified: clinicData.isVerified || false,
        
        // Images and Media
        profileImage: profileImage || '/assets/hospital.PNG',
        profileImageUrl: profileImage || '/assets/hospital.PNG',
        
        // Timestamps
        createdAt: clinicData.createdAt || null,
        updatedAt: clinicData.updatedAt || null,
        
        // Additional Information
        meetingDuration: clinicData.meetingDuration || 30,
        specialties: clinicData.specialties || [],
        sector: clinicData.sector || 'Healthcare'
      };
      
      res.json({
        success: true,
        profile: profileData,
        message: 'Profile data retrieved successfully'
      });
    } else {
      // Return default structure if no document exists
      res.json({
        success: true,
        profile: {
          name: 'Clinic Name Not Set',
          clinicName: 'Clinic Name Not Set',
          email: 'Email not set',
          phone: 'Phone not set',
          address: 'Address not set',
          city: 'City not set',
          country: 'Country not set',
          location: 'Location not set',
          about: 'About information not available',
          description: 'Description not available',
          services: [],
          facilities: [],
          schedule: {},
          workingHours: {},
          status: 'active',
          isVerified: false,
          profileImage: '/assets/hospital.PNG',
          profileImageUrl: '/assets/hospital.PNG',
          website: null,
          latitude: null,
          longitude: null,
          createdAt: null,
          updatedAt: null,
          meetingDuration: 30,
          specialties: [],
          sector: 'Healthcare'
        },
        message: 'Default profile data returned - clinic document not found'
      });
    }
  } catch (error) {
    console.error('Error getting clinic profile data:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving clinic profile data',
      error: error.message
    });
  }
});

// 💾 **Profile Update API Endpoint**
app.post('/api/profile/update', requireAuth, async (req, res) => {
  try {
    const user = req.user;
    const { section, ...updateData } = req.body;
    
    console.log('📝 Updating profile section:', section || 'all', 'for user:', user.uid);
    console.log('📄 Update data:', updateData);
    
    let dataToUpdate = {};
    let requiredFields = [];
    
    // Handle section-based updates
    switch (section) {
      case 'general':
        dataToUpdate = {
          name: updateData.name?.trim(),
          email: updateData.email?.trim(),
          type: updateData.type,
          establishedYear: updateData.establishedYear ? parseInt(updateData.establishedYear) : null,
          about: updateData.about?.trim()
        };
        requiredFields = ['name'];
        break;
        
      case 'contact':
        dataToUpdate = {
          phone: updateData.phone?.trim(),
          website: updateData.website?.trim(),
          address: updateData.address?.trim(),
          sector: updateData.sector,
          city: updateData.city?.trim(),
          state: updateData.state?.trim(),
          country: updateData.country?.trim()
        };
        requiredFields = ['phone', 'address', 'city', 'country'];
        break;
        
      case 'services':
        dataToUpdate = {
          services: Array.isArray(updateData.services) ? updateData.services : []
        };
        requiredFields = [];
        break;
        
      case 'availability':
        dataToUpdate = {
          availability: {
            workingDays: Array.isArray(updateData.workingDays) ? updateData.workingDays : [],
            startTime: updateData.startTime,
            endTime: updateData.endTime,
            appointmentDuration: updateData.appointmentDuration || 30
          }
        };
        requiredFields = [];
        break;
        
      default:
        // For backward compatibility, handle complete profile update
        dataToUpdate = {
          name: updateData.name?.trim(),
          phone: updateData.phone?.trim(),
          address: updateData.address?.trim(),
          city: updateData.city?.trim(),
          country: updateData.country?.trim(),
          website: updateData.website?.trim(),
          about: updateData.about?.trim(),
          services: Array.isArray(updateData.services) ? updateData.services : [],
          schedule: updateData.schedule || {},
          profileImageUrl: updateData.profileImageUrl,
          certificationUrl: updateData.certificationUrl
        };
        requiredFields = ['name', 'phone', 'address', 'city', 'country'];
        break;
    }
    
    // Validate required fields
    for (const field of requiredFields) {
      if (!dataToUpdate[field] || (typeof dataToUpdate[field] === 'string' && dataToUpdate[field].trim() === '')) {
        return res.status(400).json({
          success: false,
          message: `${field.charAt(0).toUpperCase() + field.slice(1)} is required`
        });
      }
    }
    
    // Remove undefined/null values
    Object.keys(dataToUpdate).forEach(key => {
      if (dataToUpdate[key] === undefined || dataToUpdate[key] === null || 
          (typeof dataToUpdate[key] === 'string' && dataToUpdate[key].trim() === '')) {
        delete dataToUpdate[key];
      }
    });
    
    // Add timestamp
    dataToUpdate.updatedAt = new Date().toISOString();
    
    // Update Firestore document
    const clinicRef = doc(db, 'clinics', user.uid);
    await updateDoc(clinicRef, dataToUpdate);
    
    console.log('✅ Profile section updated successfully:', Object.keys(dataToUpdate));
    
    res.json({
      success: true,
      message: `${section ? section.charAt(0).toUpperCase() + section.slice(1) : 'Profile'} updated successfully`,
      data: dataToUpdate,
      updatedFields: Object.keys(dataToUpdate)
    });
    
  } catch (error) {
    console.error('❌ Error updating profile:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update profile: ' + error.message
    });
  }
});

// ⏰ **Get Availability Data API Endpoint**
app.get('/api/profile/availability', requireAuth, async (req, res) => {
  try {
    const user = req.user;
    
    console.log('⏰ Getting availability data for user:', user.uid);
    
    const clinicRef = doc(db, 'clinics', user.uid);
    const clinicDoc = await getDoc(clinicRef);
    
    if (clinicDoc.exists()) {
      const clinicData = clinicDoc.data();
      res.json({
        success: true,
        availability: clinicData.availability || {
          workingDays: [],
          startTime: '08:00',
          endTime: '17:00',
          appointmentDuration: 30
        }
      });
    } else {
      res.json({
        success: true,
        availability: {
          workingDays: [],
          startTime: '08:00',
          endTime: '17:00',
          appointmentDuration: 30
        }
      });
    }
  } catch (error) {
    console.error('❌ Error getting availability data:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get availability data: ' + error.message
    });
  }
});

// 📤 **Profile Image Upload API Endpoint**
app.post('/api/profile/upload-image', requireAuth, upload.single('profileImage'), async (req, res) => {
  try {
    const user = req.user;
    const file = req.file;
    
    if (!file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided'
      });
    }
    
    console.log('📤 Uploading profile image for user:', user.uid);
    console.log('📄 File info:', { name: file.originalname, size: file.size, type: file.mimetype });
    
    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png'];
    if (!allowedTypes.includes(file.mimetype)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid file type. Only JPG, JPEG, and PNG are allowed.'
      });
    }
    
    // Validate file size (5MB max)
    const maxSize = 5 * 1024 * 1024; // 5MB
    if (file.size > maxSize) {
      return res.status(400).json({
        success: false,
        message: 'File size too large. Maximum size is 5MB.'
      });
    }
    
    try {
      // Generate unique filename
      const timestamp = Date.now();
      const fileExtension = path.extname(file.originalname);
      const fileName = `profile-images/${user.uid}-${timestamp}${fileExtension}`;
      
      // Create a reference to Firebase Storage
      const storageRef = ref(storage, fileName);
      
      // Upload file buffer to Firebase Storage
      const snapshot = await uploadBytes(storageRef, file.buffer, {
        contentType: file.mimetype,
        customMetadata: {
          uploadedBy: user.uid,
          uploadDate: new Date().toISOString(),
          originalName: file.originalname
        }
      });
      
      // Get download URL
      const downloadURL = await getDownloadURL(snapshot.ref);
      
      // Update user profile in Firestore with new image URL
      const clinicRef = doc(db, 'clinics', user.uid);
      await updateDoc(clinicRef, {
        profileImageUrl: downloadURL,
        updatedAt: new Date().toISOString()
      });
      
      console.log('✅ Profile image uploaded successfully:', downloadURL);
      
      res.json({
        success: true,
        message: 'Profile image uploaded successfully',
        imageUrl: downloadURL
      });
      
    } catch (uploadError) {
      console.error('❌ Error uploading to Firebase Storage:', uploadError);
      res.status(500).json({
        success: false,
        message: 'Failed to upload image to storage: ' + uploadError.message
      });
    }
    
  } catch (error) {
    console.error('❌ Error in profile image upload:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload profile image: ' + error.message
    });
  }
});

// 📋 **Certificate Upload API Endpoint**
app.post('/api/profile/upload-certificate', requireAuth, upload.single('certificate'), async (req, res) => {
  try {
    const user = req.user;
    const file = req.file;
    
    if (!file) {
      return res.status(400).json({
        success: false,
        message: 'No certificate file provided'
      });
    }
    
    console.log('📋 Uploading certificate for user:', user.uid);
    console.log('📄 File info:', { name: file.originalname, size: file.size, type: file.mimetype });
    
    // Validate file type
    const allowedTypes = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png'];
    if (!allowedTypes.includes(file.mimetype)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid file type. Only PDF, JPG, JPEG, and PNG are allowed.'
      });
    }
    
    // Validate file size (10MB max)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      return res.status(400).json({
        success: false,
        message: 'File size too large. Maximum size is 10MB.'
      });
    }
    
    try {
      // Generate unique filename
      const timestamp = Date.now();
      const fileExtension = path.extname(file.originalname);
      const fileName = `certificates/${user.uid}-certificate-${timestamp}${fileExtension}`;
      
      // Create a reference to Firebase Storage
      const storageRef = ref(storage, fileName);
      
      // Upload file buffer to Firebase Storage
      const snapshot = await uploadBytes(storageRef, file.buffer, {
        contentType: file.mimetype,
        customMetadata: {
          uploadedBy: user.uid,
          uploadDate: new Date().toISOString(),
          originalName: file.originalname,
          documentType: 'certification'
        }
      });
      
      // Get download URL
      const downloadURL = await getDownloadURL(snapshot.ref);
      
      // Update user profile in Firestore with new certificate URL
      const clinicRef = doc(db, 'clinics', user.uid);
      await updateDoc(clinicRef, {
        certificationUrl: downloadURL,
        certificationFileName: file.originalname,
        certificationUploadDate: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });
      
      console.log('✅ Certificate uploaded successfully:', downloadURL);
      
      res.json({
        success: true,
        message: 'Certificate uploaded successfully',
        certificateUrl: downloadURL,
        fileName: file.originalname
      });
      
    } catch (uploadError) {
      console.error('❌ Error uploading certificate to Firebase Storage:', uploadError);
      res.status(500).json({
        success: false,
        message: 'Failed to upload certificate to storage: ' + uploadError.message
      });
    }
    
  } catch (error) {
    console.error('❌ Error in certificate upload:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload certificate: ' + error.message
    });
  }
});




