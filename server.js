const express = require("express");
const path = require("path");
const cors = require("cors");
const cookieParser = require("cookie-parser");
const http = require("http");
const { Server } = require("socket.io");
require("dotenv").config();

// Import Firebase configuration
const { db, doc, getDoc, collection, query, where, orderBy, getDocs, updateDoc, addDoc, serverTimestamp, writeBatch, increment, setDoc } = require("./config/firebase");

// Import des routes et middleware
const authRoutes = require("./routes/auth");
const { requireAuth, redirectIfAuthenticated } = require("./middleware/auth");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

const PORT = process.env.PORT || 3000;

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

// API pour sauvegarder les informations de contact structurées
app.post("/api/settings/contact", requireAuth, async (req, res) => {
    try {
        const { 
            phone,
            website, 
            street, 
            city, 
            sector,
            country, 
            address,
            latitude, 
            longitude 
        } = req.body;
        
        const userId = req.user.uid;
        console.log('📍 Updating contact info for user:', userId);
        console.log('📍 Contact data:', { phone, street, city, sector, country, latitude, longitude });
        
        // Valider les champs requis - trim les espaces pour éviter les erreurs
        const trimmedPhone = phone ? phone.trim() : '';
        const trimmedStreet = street ? street.trim() : '';
        const trimmedSector = sector ? sector.trim() : '';
        const trimmedCountry = country ? country.trim() : '';
        
        // Vérifier s'il y a au moins un champ à mettre à jour
        if (!trimmedPhone && !trimmedStreet && !trimmedSector && !website && !address && !latitude && !longitude && !trimmedCountry) {
            return res.status(400).json({
                success: false,
                message: "Au moins un champ doit être fourni pour la mise à jour"
            });
        }

        // Construire l'adresse complète si elle n'est pas fournie
        let fullAddress = address;
        if (!fullAddress) {
            const addressParts = [];
            if (trimmedStreet) addressParts.push(trimmedStreet);
            if (trimmedSector) addressParts.push(trimmedSector);
            if (trimmedCountry) addressParts.push(trimmedCountry);
            fullAddress = addressParts.join(', ');
        }

        // Préparer les données de mise à jour - ne mettre à jour que les champs fournis
        const updateData = {
            updatedAt: new Date()
        };

        // Ajouter seulement les champs fournis
        if (trimmedPhone) updateData.phone = trimmedPhone;
        if (trimmedStreet) updateData.street = trimmedStreet;
        if (trimmedSector) updateData.sector = trimmedSector;
        if (trimmedCountry) updateData.country = trimmedCountry;
        if (website) updateData.website = website;
        if (fullAddress) {
            updateData.address = fullAddress;
            updateData.location = fullAddress; // Pour compatibilité avec l'app mobile
        }
        
        // Ajouter les coordonnées GPS si fournies
        if (latitude && longitude) {
            updateData.latitude = parseFloat(latitude);
            updateData.longitude = parseFloat(longitude);
        }

        const clinicDocRef = doc(db, 'clinics', userId);
        await updateDoc(clinicDocRef, updateData);
        
        console.log('✅ Contact info updated successfully');
        
        res.json({
            success: true,
            message: "Contact information updated successfully",
            data: updateData
        });
    } catch (error) {
        console.error("❌ Contact update error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to update contact information"
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

// Route pour sauvegarder l'image de profil (base64)
app.post("/api/settings/profile-image", requireAuth, async (req, res) => {
    try {
        const userId = req.user.uid;
        const { profileImageUrl } = req.body;
        
        console.log('🖼️ Saving profile image for user:', userId);
        console.log('Image data length:', profileImageUrl ? profileImageUrl.length : 0);
        
        // Validation des données d'entrée
        if (!profileImageUrl) {
            return res.status(400).json({
                success: false,
                message: "Aucune donnée d'image fournie"
            });
        }
        
        // Vérifier que c'est bien une image base64
        if (!profileImageUrl.startsWith('data:image/')) {
            return res.status(400).json({
                success: false,
                message: "Format d'image invalide. Données base64 attendues."
            });
        }
        
        // Extraire le type MIME
        const mimeMatch = profileImageUrl.match(/data:image\/([^;]+)/);
        if (!mimeMatch) {
            return res.status(400).json({
                success: false,
                message: "Type MIME d'image invalide"
            });
        }
        
        const mimeType = mimeMatch[1].toLowerCase();
        const allowedTypes = ['jpeg', 'jpg', 'png', 'webp'];
        if (!allowedTypes.includes(mimeType)) {
            return res.status(400).json({
                success: false,
                message: "Type d'image non supporté. Utilisez JPG, PNG ou WebP."
            });
        }
        
        // Vérifier la taille (limiter à 3MB pour les données base64)
        const maxSize = 3 * 1024 * 1024; // 3MB
        if (profileImageUrl.length > maxSize) {
            return res.status(413).json({
                success: false,
                message: "Image trop volumineuse. Taille maximale : 3MB."
            });
        }
        
        // Valider que les données base64 sont correctes
        try {
            const base64Data = profileImageUrl.split(',')[1];
            if (!base64Data) {
                throw new Error('Données base64 invalides');
            }
            
            // Vérifier que c'est du base64 valide
            Buffer.from(base64Data, 'base64');
        } catch (base64Error) {
            console.error('Base64 validation error:', base64Error);
            return res.status(400).json({
                success: false,
                message: "Données d'image corrompues ou invalides"
            });
        }
        
        console.log('✅ Image validation passed');
        
        // Mettre à jour le document de la clinique avec l'image base64
        const clinicDocRef = doc(db, 'clinics', userId);
        
        // Vérifier si le document existe
        const clinicDoc = await getDoc(clinicDocRef);
        if (!clinicDoc.exists()) {
            // Créer le document s'il n'existe pas
            await setDoc(clinicDocRef, {
                profileImageUrl: profileImageUrl,
                profileImage: profileImageUrl, // Compatibilité
                updatedAt: new Date(),
                createdAt: new Date()
            });
        } else {
            // Mettre à jour le document existant
            await updateDoc(clinicDocRef, {
                profileImageUrl: profileImageUrl,
                profileImage: profileImageUrl, // Compatibilité
                updatedAt: new Date(),
                lastUpdated: new Date() // Compatibilité
            });
        }
        
        console.log('✅ Profile image saved successfully to Firestore');
        
        // Réponse de succès
        res.json({
            success: true,
            message: "Image de profil sauvegardée avec succès",
            imageUrl: profileImageUrl,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error("❌ Profile image save error:", error);
        
        // Gestion d'erreurs spécifiques
        let statusCode = 500;
        let errorMessage = "Erreur interne du serveur";
        
        if (error.code === 'permission-denied') {
            statusCode = 403;
            errorMessage = "Permission refusée pour sauvegarder l'image";
        } else if (error.code === 'unavailable') {
            statusCode = 503;
            errorMessage = "Service temporairement indisponible. Réessayez plus tard.";
        } else if (error.message.includes('quota')) {
            statusCode = 507;
            errorMessage = "Quota de stockage dépassé";
        }
        
        res.status(statusCode).json({
            success: false,
            message: errorMessage,
            error: process.env.NODE_ENV === 'development' ? error.message : undefined
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
        
        // Getting clinic appointments
        
        // Récupérer le nom exact de la clinique
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        let clinicName = req.user.clinicName || "Clinic Name";
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            clinicName = clinicData.name || clinicData.clinicName || clinicName;
        }
        
        // Récupérer TOUS les rendez-vous
        const allAppointmentsRef = collection(db, 'appointments');
        const allAppointmentsSnapshot = await getDocs(allAppointmentsRef);
        
        const appointments = [];
        const now = new Date();
        const nextWeek = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
        
        allAppointmentsSnapshot.forEach((doc) => {
            const data = doc.data();
            const hospitalName = data.hospital || data.hospitalName || '';
            
            // Correspondance exacte du nom de la clinique (optimized - no excessive logging)
            if (hospitalName === clinicName) {
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
                }
            }
        });
        
        // Found appointments for clinic
        
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
        
        // Getting appointment details (optimized logging)
        
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
        
        // Checking hospital permissions
        
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
            console.log('Creating confirmation message for appointment:', appointmentId);
            const result = await createAppointmentConfirmationMessage(appointmentData, clinicName, userId);
            if (result.success) {
                console.log('✅ Confirmation message sent successfully');
            } else {
                console.error('❌ Failed to send confirmation message:', result.error);
            }
        } catch (chatError) {
            console.error('❌ Error sending confirmation message:', chatError);
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

// Socket.IO connection handling
io.on('connection', (socket) => {
    console.log('🔌 User connected:', socket.id);
    
    // Join hospital room for real-time updates
    socket.on('join-hospital', (hospitalId) => {
        socket.join(`hospital-${hospitalId}`);
        console.log(`🏥 Hospital ${hospitalId} joined room`);
    });
    
    // Handle new message sending
    socket.on('send-message', async (data) => {
        try {
            const { conversationId, message, senderId, senderName, senderType } = data;
            
            // Broadcast message to conversation participants
            socket.to(`conversation-${conversationId}`).emit('new-message', {
                conversationId,
                message,
                senderId,
                senderName,
                senderType,
                timestamp: new Date()
            });
            
            // Notify hospital of new message
            if (senderType === 'patient') {
                const conversationRef = doc(db, 'chat_conversations', conversationId);
                const conversationDoc = await getDoc(conversationRef);
                if (conversationDoc.exists()) {
                    const conversationData = conversationDoc.data();
                    socket.to(`hospital-${conversationData.clinicId}`).emit('conversation-updated', {
                        conversationId,
                        hasNewMessage: true
                    });
                }
            }
        } catch (error) {
            console.error('Socket message error:', error);
        }
    });
    
    // Join conversation room
    socket.on('join-conversation', (conversationId) => {
        socket.join(`conversation-${conversationId}`);
        console.log(`💬 Joined conversation: ${conversationId}`);
    });
    
    // Leave conversation room
    socket.on('leave-conversation', (conversationId) => {
        socket.leave(`conversation-${conversationId}`);
        console.log(`👋 Left conversation: ${conversationId}`);
    });
    
    socket.on('disconnect', () => {
        console.log('🔌 User disconnected:', socket.id);
    });
});

// Start server
server.listen(PORT, () => {
    console.log("🚀 Server running on http://localhost:" + PORT);
    console.log("📊 Dashboard: http://localhost:" + PORT + "/dashboard");
    console.log("⚙️  Settings: http://localhost:" + PORT + "/settings");
    console.log("🔐 Demo Login: admin@homecare.com / admin123");
    console.log("📝 Register: http://localhost:" + PORT + "/register");
    console.log("🔌 Socket.IO enabled for real-time chat");
});

// Graceful shutdown
process.on("SIGINT", () => {
    console.log("Shutting down server gracefully...");
    process.exit(0);
});process.on("SIGTERM", () => {
    console.log("Shutting down server gracefully...");
    process.exit(0);
});

// === CHAT API ENDPOINTS ===

// Cache pour les conversations pour éviter les requêtes répétitives
const conversationsCache = new Map();
const CACHE_DURATION = 30000; // 30 secondes

// Fonction pour invalider le cache
function invalidateCache(userId, conversationId = null) {
    // Invalider le cache des conversations
    conversationsCache.delete(`conversations_${userId}`);
    
    // Invalider le cache des messages si conversationId est fourni
    if (conversationId) {
        messagesCache.delete(`messages_${conversationId}`);
    }
    
    console.log('🗑️ Cache invalidated for user:', userId);
}

// Route pour récupérer les conversations de la clinique (optimisée)
app.get("/api/chat/conversations", requireAuth, async (req, res) => {
    try {
        const userId = req.user.uid;
        const cacheKey = `conversations_${userId}`;
        
        // Vérifier le cache d'abord
        if (conversationsCache.has(cacheKey)) {
            const cached = conversationsCache.get(cacheKey);
            if (Date.now() - cached.timestamp < CACHE_DURATION) {
                console.log('📦 Returning cached conversations');
                return res.json({
                    success: true,
                    conversations: cached.data
                });
            }
        }
        
        // Fetching fresh conversations data
        
        // Get clinic information from user session (avoid extra DB call)
        let clinicName = req.user.clinicName || "Clinic";
        
        // Optimized query - only use clinicId for better performance
        const conversationsRef = collection(db, 'chat_conversations');
        const conversationsQuery = query(
                conversationsRef,
                where('clinicId', '==', userId)
            );
            
        const snapshot = await getDocs(conversationsQuery);
        // Found conversations: ${snapshot.docs.length}
        
        const conversations = snapshot.docs.map(doc => {
                const data = doc.data();
            return {
                    id: doc.id,
                    patientId: data.patientId,
                    clinicId: data.clinicId,
                    patientName: data.patientName,
                    clinicName: data.clinicName,
                    hospitalImage: data.hospitalImage,
                    lastMessageTime: data.lastMessageTime?.toDate?.() || new Date(),
                    lastMessage: data.lastMessage,
                    lastSenderType: data.lastSenderType || 'patient',
                    
                    // FIXED LOGIC: Use clinic-specific unread counters
                    hasUnreadMessages: data.clinicHasUnread || data.hasUnreadMessages || false,
                    unreadCount: data.clinicUnreadCount || data.unreadCount || 0,
                    
                    // Include both counters for debugging
                    clinicUnreadCount: data.clinicUnreadCount || 0,
                    patientUnreadCount: data.patientUnreadCount || 0,
                    
                        createdAt: data.createdAt?.toDate?.() || new Date(),
                        updatedAt: data.updatedAt?.toDate?.() || new Date()
            };
            });
            
            // Sort by last message time
            conversations.sort((a, b) => b.lastMessageTime - a.lastMessageTime);
            
        // Cache the result
        conversationsCache.set(cacheKey, {
            data: conversations,
            timestamp: Date.now()
        });
            
            res.json({
                success: true,
                conversations: conversations
            });
        
    } catch (error) {
        console.error("Get conversations error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch conversations",
            error: error.message
        });
    }
});

// Cache pour les messages
const messagesCache = new Map();

// Route pour récupérer les messages d'une conversation (optimisée)
app.get("/api/chat/conversations/:conversationId/messages", requireAuth, async (req, res) => {
    try {
        const conversationId = req.params.conversationId;
        const userId = req.user.uid;
        const cacheKey = `messages_${conversationId}`;
        
        // Vérifier le cache d'abord
        if (messagesCache.has(cacheKey)) {
            const cached = messagesCache.get(cacheKey);
            if (Date.now() - cached.timestamp < CACHE_DURATION) {
                console.log('📦 Returning cached messages');
                // Marquer comme lus même avec le cache
                await _markConversationMessagesAsRead(conversationId, userId);
                return res.json(cached.data);
            }
        }
        
        // Fetching fresh messages data
        
        // Vérifier que la conversation appartient à cette clinique
        const conversationRef = doc(db, 'chat_conversations', conversationId);
        const conversationDoc = await getDoc(conversationRef);
        
        if (!conversationDoc.exists()) {
            return res.status(404).json({
                success: false,
                message: "Conversation not found"
            });
        }
        
        const conversationData = conversationDoc.data();
        if (conversationData.clinicId !== userId) {
            return res.status(403).json({
                success: false,
                message: "You don't have permission to view this conversation"
            });
        }
        
        // Récupérer les messages (optimized query)
        const messagesRef = collection(db, 'chat_messages');
        const messagesQuery = query(
            messagesRef,
            where('conversationId', '==', conversationId)
        );
        
        const messagesSnapshot = await getDocs(messagesQuery);
        
        const messages = messagesSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
                id: doc.id,
                conversationId: data.conversationId,
                senderId: data.senderId,
                senderName: data.senderName,
                senderType: data.senderType,
                message: data.message,
                messageType: data.messageType,
                timestamp: data.timestamp?.toDate?.() || new Date(),
                isRead: data.isRead || false,
                appointmentId: data.appointmentId,
                hospitalName: data.hospitalName,
                hospitalImage: data.hospitalImage,
                department: data.department,
                appointmentDate: data.appointmentDate?.toDate?.() || null,
                appointmentTime: data.appointmentTime,
                metadata: data.metadata
            };
            });
        
        // Sort messages by timestamp
        messages.sort((a, b) => a.timestamp - b.timestamp);
        
        const responseData = {
            success: true,
            messages: messages,
            conversation: {
                id: conversationId,
                patientName: conversationData.patientName,
                clinicName: conversationData.clinicName,
                hospitalImage: conversationData.hospitalImage
            }
        };
        
        // Cache the result
        messagesCache.set(cacheKey, {
            data: responseData,
            timestamp: Date.now()
        });
        
        // Marquer les messages comme lus
        await _markConversationMessagesAsRead(conversationId, userId);
        
        res.json(responseData);
        
    } catch (error) {
        console.error("Get messages error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch messages",
            error: error.message
        });
    }
});

// Route pour envoyer un message
app.post("/api/chat/conversations/:conversationId/messages", requireAuth, async (req, res) => {
    try {
        const conversationId = req.params.conversationId;
        const userId = req.user.uid;
        const { message, messageType = 'text', appointmentId, metadata } = req.body;
        
        console.log('=== SEND MESSAGE DEBUG ===');
        console.log(`Conversation ID: ${conversationId}`);
        console.log(`User/Clinic ID: ${userId}`);
        console.log(`User object:`, JSON.stringify(req.user, null, 2));
        console.log(`Message: ${message}`);
        console.log(`Message Type: ${messageType}`);
        
        // Validation des paramètres
        if (!conversationId) {
            console.log('❌ Missing conversationId');
            return res.status(400).json({
                success: false,
                message: "Conversation ID is required"
            });
        }
        
        if (!message || message.trim() === '') {
            console.log('❌ Missing or empty message');
            return res.status(400).json({
                success: false,
                message: "Message content is required"
            });
        }
        
        // Vérifier que la conversation existe
        const conversationRef = doc(db, 'chat_conversations', conversationId);
        const conversationDoc = await getDoc(conversationRef);
        
        console.log(`Conversation exists: ${conversationDoc.exists()}`);
        
        if (!conversationDoc.exists()) {
            console.log('❌ Conversation not found');
            return res.status(404).json({
                success: false,
                message: "Conversation not found"
            });
        }
        
        const conversationData = conversationDoc.data();
        console.log(`Conversation data:`, JSON.stringify(conversationData, null, 2));
        console.log(`Conversation clinic ID: ${conversationData.clinicId}`);
        console.log(`Current user ID: ${userId}`);
        console.log(`IDs match: ${conversationData.clinicId === userId}`);
        
        // Vérifier les permissions avec plus de flexibilité
        if (!conversationData.clinicId) {
            console.log('⚠️ Conversation has no clinicId, checking if we can assign it...');
            
            // Si pas de clinicId, on peut l'assigner à l'utilisateur actuel
            await updateDoc(conversationRef, {
                clinicId: userId,
                updatedAt: serverTimestamp()
            });
            
            console.log(`✅ Assigned conversation to clinic: ${userId}`);
        } else if (conversationData.clinicId !== userId) {
            console.log(`❌ Permission denied. Conversation belongs to: ${conversationData.clinicId}, current user: ${userId}`);
            return res.status(403).json({
                success: false,
                message: "You don't have permission to send messages in this conversation"
            });
        }
        
        // Récupérer les informations de la clinique pour obtenir l'image
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        let clinicName = req.user.clinicName || "Clinic";
        let hospitalImage = null;
        
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            clinicName = clinicData.name || clinicData.clinicName || clinicName;
            
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
                console.log('⚠️ No hospital image found for clinic:', userId);
                console.log('Available fields:', Object.keys(clinicData));
            }
            
            console.log(`✅ Found clinic: ${clinicName}`);
        } else {
            console.log(`⚠️ Clinic document not found for ID: ${userId}`);
        }
        
        // Créer le message
        const messageData = {
            conversationId: conversationId,
            senderId: userId,
            senderName: clinicName,
            senderType: 'clinic',
            message: message.trim(),
            messageType: messageType,
            timestamp: serverTimestamp(),
            isRead: false, // Hospital messages start as unread for patient
            hospitalName: clinicName,
            hospitalImage: hospitalImage,
            ...(appointmentId && { appointmentId }),
            ...(metadata && { metadata })
        };
        
        console.log(`Creating message:`, JSON.stringify(messageData, null, 2));
        
        const messageRef = await addDoc(collection(db, 'chat_messages'), messageData);
        console.log(`✅ Message created with ID: ${messageRef.id}`);
        
        // FIXED LOGIC: Update conversation with separate unread counters
        await updateDoc(conversationRef, {
            lastMessageTime: serverTimestamp(),
            lastMessage: message.trim(),
            lastSenderType: 'clinic', // Track who sent the last message
            
            // Patient-side unread (clinic sent message TO patient)
            patientUnreadCount: increment(1), // Patient has new unread message
            patientHasUnread: true,
            
            // Clinic-side unread (reset since clinic just sent a message)
            clinicUnreadCount: 0, // Clinic has no unread messages
            clinicHasUnread: false,
            
            // Legacy fields for backward compatibility
            hasUnreadMessages: true,
            unreadCount: increment(1),
            
            updatedAt: serverTimestamp()
        });
        
        // Invalider le cache pour que les nouvelles données soient récupérées
        invalidateCache(userId, conversationId);
        
        console.log('✅ Conversation updated successfully');
        console.log('✅ Message sent successfully');
        
        res.json({
            success: true,
            messageId: messageRef.id,
            message: "Message sent successfully"
        });
        
    } catch (error) {
        console.error("❌ Send message error:", error);
        console.error("❌ Error stack:", error.stack);
        res.status(500).json({
            success: false,
            message: "Failed to send message",
            error: error.message,
            details: process.env.NODE_ENV === 'development' ? error.stack : undefined
        });
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

// Route pour approuver/rejeter un rendez-vous via le chat
app.post("/api/chat/appointments/:appointmentId/:action", requireAuth, async (req, res) => {
    try {
        const appointmentId = req.params.appointmentId;
        const action = req.params.action; // 'approve' or 'reject'
        const userId = req.user.uid;
        const { reason } = req.body;
        
        console.log('=== CHAT APPOINTMENT ACTION ===');
        console.log(`Appointment ID: ${appointmentId}`);
        console.log(`Action: ${action}`);
        console.log(`Clinic ID: ${userId}`);
        
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
        
        // Récupérer le nom exact de la clinique
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        let clinicName = req.user.clinicName || "Clinic Name";
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            clinicName = clinicData.name || clinicData.clinicName || clinicName;
        }
        
        // Vérifier que le rendez-vous appartient à cette clinique
        if (hospitalName !== clinicName) {
            return res.status(403).json({
                success: false,
                message: "You don't have permission to modify this appointment"
            });
        }
        
        // Mettre à jour le statut du rendez-vous
        const newStatus = action === 'approve' ? 'confirmed' : 'rejected';
        await updateDoc(appointmentRef, {
            status: newStatus,
            updatedAt: new Date(),
            [action === 'approve' ? 'approvedBy' : 'rejectedBy']: userId,
            [action === 'approve' ? 'approvedAt' : 'rejectedAt']: new Date(),
            ...(action === 'reject' && reason ? { rejectionReason: reason } : {})
        });
        
        // Créer le message de confirmation/rejet
        if (action === 'approve') {
            await createAppointmentConfirmationMessage(appointmentData, clinicName, userId);
        } else {
            await createAppointmentRejectionMessage(appointmentData, clinicName, userId, reason);
        }
        
        console.log(`Appointment ${action}d successfully`);
        
        res.json({
            success: true,
            message: `Appointment ${action}d successfully`
        });
        
    } catch (error) {
        console.error("Chat appointment action error:", error);
        res.status(500).json({
            success: false,
            message: `Failed to ${req.params.action} appointment`,
            error: error.message
        });
    }
});

// API endpoint to delete conversation
app.delete('/api/chat/conversations/:conversationId', requireAuth, async (req, res) => {
    try {
        const { conversationId } = req.params;
        const userId = req.user.uid;
        
        console.log(`=== DELETING CONVERSATION ===`);
        console.log(`Conversation ID: ${conversationId}`);
        console.log(`User ID: ${userId}`);
        
        // Vérifier que la conversation existe et appartient à cet utilisateur
        const conversationRef = doc(db, 'chat_conversations', conversationId);
        const conversationDoc = await getDoc(conversationRef);
        
        if (!conversationDoc.exists()) {
            return res.status(404).json({
                success: false,
                message: 'Conversation not found'
            });
        }
        
        const conversationData = conversationDoc.data();
        
        // Vérifier que l'utilisateur a accès à cette conversation
        if (conversationData.clinicId !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Access denied to this conversation'
            });
        }
        
        // Delete all messages in the conversation
        const messagesRef = collection(db, 'chat_messages');
        const messagesQuery = query(messagesRef, where('conversationId', '==', conversationId));
        const messagesSnapshot = await getDocs(messagesQuery);
        
        const batch = writeBatch(db);
        messagesSnapshot.docs.forEach(doc => {
            batch.delete(doc.ref);
        });
        
        // Delete the conversation document
        batch.delete(conversationRef);
        
        await batch.commit();
        
        console.log(`✅ Conversation ${conversationId} and ${messagesSnapshot.docs.length} messages deleted`);
        
        // Emit socket event to update UI
        io.to(`hospital-${userId}`).emit('conversation-deleted', { conversationId });
        
        res.json({
            success: true,
            message: 'Conversation deleted successfully'
        });
        
    } catch (error) {
        console.error("Error deleting conversation:", error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete conversation',
            error: error.message
        });
    }
});

// Helper function to handle patient message (when patient sends to clinic)
async function _handlePatientMessage(conversationId, patientId, messageData) {
    try {
        // Create message
        const messageRef = await addDoc(collection(db, 'chat_messages'), {
            ...messageData,
            conversationId: conversationId,
            senderId: patientId,
            senderType: 'patient',
            timestamp: serverTimestamp(),
            isRead: false // Clinic needs to read this
        });
        
        // Update conversation with correct unread logic
        const conversationRef = doc(db, 'chat_conversations', conversationId);
        await updateDoc(conversationRef, {
            lastMessageTime: serverTimestamp(),
            lastMessage: messageData.message,
            lastSenderType: 'patient',
            
            // Clinic-side unread (patient sent message TO clinic)
            clinicUnreadCount: increment(1), // Clinic has new unread message
            clinicHasUnread: true,
            
            // Patient-side unread (reset since patient just sent a message)
            patientUnreadCount: 0, // Patient has no unread messages
            patientHasUnread: false,
            
            // Legacy fields for backward compatibility
            hasUnreadMessages: true,
            unreadCount: increment(1),
            
            updatedAt: serverTimestamp()
        });
        
        console.log('📱 Patient message processed successfully');
        return messageRef.id;
        
    } catch (error) {
        console.error("Error handling patient message:", error);
        throw error;
    }
}

// Helper function to mark conversation messages as read (fixed logic)
async function _markConversationMessagesAsRead(conversationId, clinicId) {
    try {
        // Get all messages in this conversation
        const messagesRef = collection(db, 'chat_messages');
        const messagesQuery = query(
            messagesRef,
            where('conversationId', '==', conversationId)
        );
        
        const messagesSnapshot = await getDocs(messagesQuery);
        
        // FIXED LOGIC: Only mark messages as read that were SENT TO the current user
        // If clinic is reading: mark patient messages as read
        // If patient is reading: mark clinic messages as read
        const messagesToUpdate = messagesSnapshot.docs.filter(doc => {
            const data = doc.data();
            // Clinic reading patient messages
            return data.senderType === 'patient' && !data.isRead;
        });
        
        if (messagesToUpdate.length > 0) {
        const batch = writeBatch(db);
            messagesToUpdate.forEach(doc => {
                batch.update(doc.ref, { 
                    isRead: true,
                    readAt: serverTimestamp(),
                    readBy: clinicId
                });
        });
        
            await batch.commit();
            console.log(`📖 Marked ${messagesToUpdate.length} patient messages as read by clinic`);
        }
        
        // Update conversation - reset unread count for clinic side only
        await updateDoc(doc(db, 'chat_conversations', conversationId), {
            clinicUnreadCount: 0,
            clinicHasUnread: false,
            updatedAt: serverTimestamp()
        });
        
    } catch (error) {
        console.error("Error marking messages as read:", error);
    }
}

// API endpoint to mark conversation as read
app.post('/api/chat/conversations/:conversationId/mark-read', requireAuth, async (req, res) => {
    try {
        const { conversationId } = req.params;
        const userId = req.user.uid;
        
        console.log(`=== MARKING CONVERSATION AS READ ===`);
        console.log(`Conversation ID: ${conversationId}`);
        console.log(`User ID: ${userId}`);
        
        // Vérifier que la conversation existe et appartient à cet utilisateur
        const conversationRef = doc(db, 'chat_conversations', conversationId);
        const conversationDoc = await getDoc(conversationRef);
        
        if (!conversationDoc.exists()) {
            return res.status(404).json({
                success: false,
                message: 'Conversation not found'
            });
        }
        
        const conversationData = conversationDoc.data();
        
        // Vérifier que l'utilisateur a accès à cette conversation
        if (conversationData.clinicId !== userId) {
            return res.status(403).json({
                success: false,
                message: 'Access denied to this conversation'
            });
        }
        
        // Marquer les messages comme lus
        await _markConversationMessagesAsRead(conversationId, userId);
        
        console.log(`✅ Conversation ${conversationId} marked as read`);
        
        res.json({
            success: true,
            message: 'Conversation marked as read'
        });
        
    } catch (error) {
        console.error("Error marking conversation as read:", error);
        res.status(500).json({
            success: false,
            message: 'Failed to mark conversation as read',
            error: error.message
        });
    }
});

// Fonction pour créer un message de confirmation de rendez-vous
async function createAppointmentConfirmationMessage(appointmentData, clinicName, clinicId) {
  try {
    console.log('📝 Creating appointment confirmation message');
    
    const patientId = appointmentData.patientId;
    const patientName = appointmentData.patientName;
    const hospitalName = appointmentData.hospital || appointmentData.hospitalName;
    const department = appointmentData.department;
    const appointmentDate = appointmentData.appointmentDate;
    const appointmentTime = appointmentData.appointmentTime;
    
    // Get appointment ID from the document reference
    let appointmentId = null;
    if (appointmentData.id) {
      appointmentId = appointmentData.id;
    } else if (appointmentData.appointmentId) {
      appointmentId = appointmentData.appointmentId;
    }
    
    // Reduced logging for better performance

    // Gérer le champ date (Timestamp ou Date)
    let appointmentDateObj;
    if (appointmentDate && appointmentDate.toDate) {
      appointmentDateObj = appointmentDate.toDate();
    } else if (appointmentDate instanceof Date) {
      appointmentDateObj = appointmentDate;
    } else if (appointmentDate) {
      appointmentDateObj = new Date(appointmentDate);
    } else {
      appointmentDateObj = new Date();
    }

    // Récupérer l'image de l'hôpital depuis la collection clinics
    let hospitalImage = null;
    try {
      const clinicDoc = await getDoc(doc(db, 'clinics', clinicId));
      if (clinicDoc.exists()) {
        const clinicData = clinicDoc.data();
        hospitalImage = clinicData.profileImageUrl || clinicData.imageUrl || null;
        // Hospital image processed
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
      console.log('No existing conversation found, creating new one...');
      // FIXED LOGIC: Créer une nouvelle conversation avec compteurs séparés
      const conversationData = {
        patientId: patientId,
        clinicId: clinicId,
        patientName: patientName,
        clinicName: hospitalName, // Utiliser le nom de l'hôpital du rendez-vous
        hospitalImage: hospitalImage, // Ajouter l'image de l'hôpital
        lastMessageTime: serverTimestamp(),
        lastMessage: 'Appointment confirmed',
        lastSenderType: 'clinic',
        
        // Patient-side unread (clinic sent message TO patient)
        patientUnreadCount: 1, // Patient has new unread message
        patientHasUnread: true,
        
        // Clinic-side unread (clinic just sent, so no unread for clinic)
        clinicUnreadCount: 0, // Clinic has no unread messages
        clinicHasUnread: false,
        
        // Legacy fields for backward compatibility
        hasUnreadMessages: true,
        unreadCount: 1,
        
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
      };

      console.log('Creating conversation with data:', conversationData);
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
    const confirmationMessage = `✅ **Appointment Confirmed**\n\nYour appointment has been confirmed by **${hospitalName}**.\n\n**Details:**\n• **Hospital:** ${hospitalName}\n• **Department:** ${department}\n• **Date:** ${appointmentDateObj.toLocaleDateString()}\n• **Time:** ${appointmentTime}\n\nPlease arrive 15 minutes before your scheduled time. If you need to reschedule or cancel, please contact us at least 24 hours in advance.\n\nWe look forward to seeing you!`;

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
    console.log('✅ Confirmation message created in conversation', conversationId);

    // FIXED LOGIC: Mettre à jour la conversation avec compteurs séparés
    await updateDoc(doc(db, 'chat_conversations', conversationId), {
      lastMessageTime: serverTimestamp(),
      lastMessage: 'Appointment confirmed',
      lastSenderType: 'clinic',
      
      // Patient-side unread (clinic sent message TO patient)
      patientUnreadCount: increment(1), // Patient has new unread message
      patientHasUnread: true,
      
      // Clinic-side unread (clinic just sent, so no unread for clinic)
      clinicUnreadCount: 0, // Clinic has no unread messages
      clinicHasUnread: false,
      
      // Legacy fields for backward compatibility
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
        hospitalImage = clinicData.profileImageUrl || null;
        console.log('🏥 Hospital image found:', hospitalImage ? 'Yes' : 'No');
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




