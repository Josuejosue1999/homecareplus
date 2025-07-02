const express = require("express");
const path = require("path");
const cors = require("cors");
const cookieParser = require("cookie-parser");
require("dotenv").config();

// Import Firebase configuration
const { db, doc, getDoc, collection, query, where, orderBy, getDocs, updateDoc, addDoc, serverTimestamp, writeBatch, increment } = require("./config/firebase");

// Import des routes et middleware
const authRoutes = require("./routes/auth");
const { requireAuth, redirectIfAuthenticated } = require("./middleware/auth");

const app = express();
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

// === CHAT API ENDPOINTS ===

// Route pour récupérer les conversations de la clinique
app.get("/api/chat/conversations", requireAuth, async (req, res) => {
    try {
        const userId = req.user.uid;
        
        console.log('=== GET CLINIC CONVERSATIONS ===');
        console.log(`Clinic ID: ${userId}`);
        
        // Get clinic information first
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        let clinicName = req.user.clinicName || "Clinic";
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            clinicName = clinicData.name || clinicData.clinicName || clinicName;
        }
        
        console.log(`Clinic Name: ${clinicName}`);
        
        // Get conversations by both clinicId and clinicName to handle all cases
        const conversationsRef = collection(db, 'chat_conversations');
        
        try {
            // Query 1: Conversations with matching clinicId
            const conversationsQuery1 = query(
                conversationsRef,
                where('clinicId', '==', userId)
            );
            
            // Query 2: Conversations with matching clinicName (for legacy data)
            const conversationsQuery2 = query(
                conversationsRef,
                where('clinicName', '==', clinicName)
            );
            
            const [snapshot1, snapshot2] = await Promise.all([
                getDocs(conversationsQuery1),
                getDocs(conversationsQuery2)
            ]);
            
            console.log(`Query 1 (clinicId): ${snapshot1.docs.length} conversations`);
            console.log(`Query 2 (clinicName): ${snapshot2.docs.length} conversations`);
            
            // Combine and deduplicate conversations
            const conversationMap = new Map();
            
            // Process conversations by clinicId
            snapshot1.docs.forEach(doc => {
                const data = doc.data();
                console.log(`Processing conversation by ID: ${doc.id} - Patient: ${data.patientName}`);
                conversationMap.set(doc.id, {
                    id: doc.id,
                    patientId: data.patientId,
                    clinicId: data.clinicId,
                    patientName: data.patientName,
                    clinicName: data.clinicName,
                    hospitalImage: data.hospitalImage,
                    lastMessageTime: data.lastMessageTime?.toDate?.() || new Date(),
                    lastMessage: data.lastMessage,
                    hasUnreadMessages: data.hasUnreadMessages || false,
                    unreadCount: data.unreadCount || 0,
                    createdAt: data.createdAt?.toDate?.() || new Date(),
                    updatedAt: data.updatedAt?.toDate?.() || new Date()
                });
            });
            
            // Process conversations by clinicName (only if not already added)
            snapshot2.docs.forEach(doc => {
                if (!conversationMap.has(doc.id)) {
                    const data = doc.data();
                    console.log(`Processing conversation by name: ${doc.id} - Patient: ${data.patientName}`);
                    conversationMap.set(doc.id, {
                        id: doc.id,
                        patientId: data.patientId,
                        clinicId: data.clinicId,
                        patientName: data.patientName,
                        clinicName: data.clinicName,
                        hospitalImage: data.hospitalImage,
                        lastMessageTime: data.lastMessageTime?.toDate?.() || new Date(),
                        lastMessage: data.lastMessage,
                        hasUnreadMessages: data.hasUnreadMessages || false,
                        unreadCount: data.unreadCount || 0,
                        createdAt: data.createdAt?.toDate?.() || new Date(),
                        updatedAt: data.updatedAt?.toDate?.() || new Date()
                    });
                }
            });
            
            const conversations = Array.from(conversationMap.values());
            
            // Sort by last message time
            conversations.sort((a, b) => b.lastMessageTime - a.lastMessageTime);
            
            console.log(`Total unique conversations found: ${conversations.length}`);
            
            res.json({
                success: true,
                conversations: conversations
            });
            
        } catch (queryError) {
            console.error("Firestore query error:", queryError);
            
            // Fallback: try to get all conversations and filter client-side
            console.log("Trying fallback approach...");
            const allConversationsSnapshot = await getDocs(conversationsRef);
            const allConversations = [];
            
            allConversationsSnapshot.docs.forEach(doc => {
                const data = doc.data();
                if (data.clinicId === userId || data.clinicName === clinicName) {
                    allConversations.push({
                        id: doc.id,
                        patientId: data.patientId,
                        clinicId: data.clinicId,
                        patientName: data.patientName,
                        clinicName: data.clinicName,
                        hospitalImage: data.hospitalImage,
                        lastMessageTime: data.lastMessageTime?.toDate?.() || new Date(),
                        lastMessage: data.lastMessage,
                        hasUnreadMessages: data.hasUnreadMessages || false,
                        unreadCount: data.unreadCount || 0,
                        createdAt: data.createdAt?.toDate?.() || new Date(),
                        updatedAt: data.updatedAt?.toDate?.() || new Date()
                    });
                }
            });
            
            allConversations.sort((a, b) => b.lastMessageTime - a.lastMessageTime);
            console.log(`Fallback found ${allConversations.length} conversations`);
            
            res.json({
                success: true,
                conversations: allConversations
            });
        }
        
    } catch (error) {
        console.error("Get conversations error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to fetch conversations",
            error: error.message
        });
    }
});

// Route pour récupérer les messages d'une conversation
app.get("/api/chat/conversations/:conversationId/messages", requireAuth, async (req, res) => {
    try {
        const conversationId = req.params.conversationId;
        const userId = req.user.uid;
        
        console.log('=== GET CONVERSATION MESSAGES ===');
        console.log(`Conversation ID: ${conversationId}`);
        console.log(`Clinic ID: ${userId}`);
        
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
        
        // Récupérer les messages (without orderBy to avoid index issues)
        const messagesRef = collection(db, 'chat_messages');
        const messagesQuery = query(
            messagesRef,
            where('conversationId', '==', conversationId)
        );
        
        const messagesSnapshot = await getDocs(messagesQuery);
        
        const messages = [];
        for (const doc of messagesSnapshot.docs) {
            const data = doc.data();
            messages.push({
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
            });
        }
        
        // Sort messages by timestamp
        messages.sort((a, b) => a.timestamp - b.timestamp);
        
        console.log(`Found ${messages.length} messages`);
        
        // Marquer les messages comme lus
        await _markConversationMessagesAsRead(conversationId, userId);
        
        res.json({
            success: true,
            messages: messages,
            conversation: {
                id: conversationId,
                patientName: conversationData.patientName,
                clinicName: conversationData.clinicName,
                hospitalImage: conversationData.hospitalImage
            }
        });
        
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
        
        console.log('=== SEND MESSAGE ===');
        console.log(`Conversation ID: ${conversationId}`);
        console.log(`Clinic ID: ${userId}`);
        console.log(`Message: ${message}`);
        
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
                message: "You don't have permission to send messages in this conversation"
            });
        }
        
        // Récupérer les informations de la clinique
        const clinicDocRef = doc(db, 'clinics', userId);
        const clinicDoc = await getDoc(clinicDocRef);
        
        let clinicName = req.user.clinicName || "Clinic";
        if (clinicDoc.exists()) {
            const clinicData = clinicDoc.data();
            clinicName = clinicData.name || clinicData.clinicName || clinicName;
        }
        
        // Créer le message
        const messageData = {
            conversationId: conversationId,
            senderId: userId,
            senderName: clinicName,
            senderType: 'clinic',
            message: message,
            messageType: messageType,
            timestamp: serverTimestamp(),
            isRead: false,
            appointmentId: appointmentId,
            hospitalName: clinicName,
            metadata: metadata
        };
        
        const messageRef = await addDoc(collection(db, 'chat_messages'), messageData);
        
        // Mettre à jour la conversation
        await updateDoc(conversationRef, {
            lastMessageTime: serverTimestamp(),
            lastMessage: message,
            hasUnreadMessages: true,
            unreadCount: increment(1),
            updatedAt: serverTimestamp()
        });
        
        console.log('Message sent successfully');
        
        res.json({
            success: true,
            messageId: messageRef.id,
            message: "Message sent successfully"
        });
        
    } catch (error) {
        console.error("Send message error:", error);
        res.status(500).json({
            success: false,
            message: "Failed to send message",
            error: error.message
        });
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

// Helper function to mark conversation messages as read
async function _markConversationMessagesAsRead(conversationId, clinicId) {
    try {
        const messagesRef = collection(db, 'chat_messages');
        const messagesQuery = query(
            messagesRef,
            where('conversationId', '==', conversationId),
            where('senderId', '!=', clinicId),
            where('isRead', '==', false)
        );
        
        const messagesSnapshot = await getDocs(messagesQuery);
        
        const batch = writeBatch(db);
        messagesSnapshot.docs.forEach(doc => {
            batch.update(doc.ref, { isRead: true });
        });
        
        if (messagesSnapshot.docs.length > 0) {
            await batch.commit();
            console.log(`Marked ${messagesSnapshot.docs.length} messages as read`);
        }
        
        // Mettre à jour la conversation
        await updateDoc(doc(db, 'chat_conversations', conversationId), {
            hasUnreadMessages: false,
            unreadCount: 0,
            updatedAt: serverTimestamp()
        });
        
    } catch (error) {
        console.error("Error marking messages as read:", error);
    }
}

// Fonction pour créer un message de confirmation de rendez-vous
async function createAppointmentConfirmationMessage(appointmentData, clinicName, clinicId) {
  try {
    console.log('=== CREATING APPOINTMENT CONFIRMATION MESSAGE ===');
    console.log('Appointment data:', JSON.stringify(appointmentData, null, 2));
    
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
    
    console.log('Patient ID:', patientId);
    console.log('Patient Name:', patientName);
    console.log('Hospital Name:', hospitalName);
    console.log('Department:', department);
    console.log('Appointment ID:', appointmentId);

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
        console.log('🏥 Hospital image found:', hospitalImage ? 'Yes' : 'No');
      }
    } catch (error) {
      console.log('⚠️ Could not fetch hospital image:', error.message);
    }

    // Créer ou obtenir la conversation
    console.log('Looking for existing conversation...');
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




