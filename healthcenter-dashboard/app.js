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

// Route protégée pour le chat
app.get("/chat", requireAuth, (req, res) => {
    res.render("dashboard-new", { user: req.user, activeTab: 'messages' });
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




