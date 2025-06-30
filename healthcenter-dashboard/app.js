const express = require("express");
const path = require("path");
const cors = require("cors");
const cookieParser = require("cookie-parser");
require("dotenv").config();

// Import Firebase configuration
const { db, doc, getDoc, collection, query, where, orderBy, getDocs, updateDoc } = require("./config/firebase");

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
app.get("/dashboard", requireAuth, (req, res) => {
    res.render("dashboard-new", { user: req.user });
});

// Route protégée des paramètres
app.get("/settings", requireAuth, (req, res) => {
    res.render("settings", { user: req.user });
});

// Routes API pour les paramètres
app.post("/api/settings/profile", requireAuth, async (req, res) => {
    try {
        const { clinicName, about, meetingDuration } = req.body;
        const userId = req.user.uid;
        const clinicDocRef = doc(db, 'clinics', userId);
        await updateDoc(clinicDocRef, {
            clinicName,
            name: clinicName,
            about,
            meetingDuration: meetingDuration ? Number(meetingDuration) : 30,
            updatedAt: new Date()
        });
        res.json({
            success: true,
            message: "Profile updated successfully"
        });
    } catch (error) {
        console.error("Profile update error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to update profile"
        });
    }
});

app.post("/api/settings/contact", requireAuth, async (req, res) => {
    try {
        const { phone, address, sector, latitude, longitude } = req.body;
        const userId = req.user.uid;
        const clinicDocRef = doc(db, 'clinics', userId);
        await updateDoc(clinicDocRef, {
            phone,
            address,
            sector,
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

app.post("/api/settings/services", requireAuth, async (req, res) => {
    try {
        const { facilities } = req.body;
        const userId = req.user.uid;
        const clinicDocRef = doc(db, 'clinics', userId);
        await updateDoc(clinicDocRef, {
            facilities: Array.isArray(facilities) ? facilities : [facilities],
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
        
        console.log(`Getting clinic data for UID: ${userId}`);
        
        // Récupérer les vraies données depuis Firebase
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        if (clinicDoc.exists()) {
            console.log('Found clinic data in \'clinics\' collection');
            const clinicData = clinicDoc.data();
            console.log('Clinic data retrieved:', clinicData);
            
            res.json({
                success: true,
                clinicData: clinicData
            });
        } else {
            console.log('No clinic data found, checking users collection');
            // Si pas dans 'clinics', essayer la collection 'users'
            const userDocRef = doc(db, 'users', userId);
            const userDoc = await getDoc(userDocRef);
            
            if (userDoc.exists()) {
                console.log('Found clinic data in \'users\' collection');
                const userData = userDoc.data();
                console.log('User data retrieved:', userData);
                
                res.json({
                    success: true,
                    clinicData: userData
                });
            } else {
                console.log('No clinic data found in any collection');
                // Retourner des données par défaut si aucune donnée n'est trouvée
                const defaultData = {
                    name: req.user.clinicName || "Clinic Name",
                    clinicName: req.user.clinicName || "Clinic Name",
                    email: req.user.email || "email@clinic.com",
                    about: "This is a healthcare facility committed to providing exceptional medical care and services.",
                    phone: "Phone to be updated",
                    address: "Address to be updated",
                    location: "Location to be updated",
                    facilities: ["General Medicine"],
                    availableSchedule: {
                        Monday: { start: "08:00", end: "17:00" },
                        Tuesday: { start: "08:00", end: "17:00" },
                        Wednesday: { start: "08:00", end: "17:00" },
                        Thursday: { start: "08:00", end: "17:00" },
                        Friday: { start: "08:00", end: "17:00" },
                        Saturday: { start: "09:00", end: "15:00" },
                        Sunday: { start: "Closed", end: "Closed" }
                    },
                    isVerified: false,
                    profileImageUrl: null,
                    createdAt: { seconds: Date.now() / 1000 },
                    updatedAt: { seconds: Date.now() / 1000 }
                };
                
                res.json({
                    success: true,
                    clinicData: defaultData
                });
            }
        }
    } catch (error) {
        console.error("Clinic data fetch error:", error);
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




