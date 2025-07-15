const { 
  auth, 
  db, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signOut,
  doc,
  setDoc,
  getDoc,
  collection,
  query,
  where,
  getDocs
} = require("../config/firebase");

class AuthService {
  // Login avec Firebase
  async login(email, password, req) {
    try {
      console.log("🔐 AuthService.login - Starting login process for:", email);
      
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;
      
      console.log("✅ Login successful for user:", user.uid);
      
      // Récupérer les données de la clinique depuis Firestore
      const clinicData = await this.getClinicData(user.uid);
      console.log("📋 Clinic data retrieved:", clinicData);
      
      // S'assurer que le nom de la clinique est correctement récupéré
      const clinicName = clinicData?.clinicName || clinicData?.name || clinicData?.hospitalName || "Clinic";
      
      const userData = {
        uid: user.uid,
        email: user.email,
        clinicName: clinicName,
        name: clinicName, // Ajouter aussi 'name' pour compatibilité
        profileImageUrl: clinicData?.profileImageUrl || null,
        role: "clinic",
        // Ajouter toutes les données importantes pour la synchronisation
        about: clinicData?.about || '',
        phone: clinicData?.phone || '',
        address: clinicData?.address || '',
        sector: clinicData?.sector || '',
        facilities: clinicData?.facilities || [],
        availableSchedule: clinicData?.availableSchedule || {},
        isVerified: clinicData?.isVerified || false,
        createdAt: clinicData?.createdAt || new Date(),
        updatedAt: clinicData?.updatedAt || new Date()
      };

      console.log("📦 User data prepared for session:", userData);

      // Créer une session
      const sessionId = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
      
      // Stocker la session dans app.locals
      req.app.locals.sessions = req.app.locals.sessions || new Map();
      req.app.locals.sessions.set(sessionId, userData);
      
      console.log("🎫 Session created with ID:", sessionId);

      return {
        success: true,
        sessionId,
        user: userData
      };

    } catch (error) {
      console.error("❌ AuthService.login - Error:", {
        message: error.message,
        code: error.code,
        stack: error.stack
      });
      
      return {
        success: false,
        message: this.getErrorMessage(error)
      };
    }
  }

  // Register avec Firebase - clinicName optionnel
  async register(email, password, req, clinicName = null) {
    try {
      console.log("🆕 AuthService.register - Starting registration process");
      console.log("📧 Email:", email);
      console.log("🏥 Clinic name provided:", clinicName || 'None (will generate default)');
      console.log("🔧 Firebase auth object:", !!auth ? "Available" : "Missing");
      
      // Vérifier que Firebase est correctement configuré
      if (!auth) {
        console.error("❌ Firebase auth is not initialized!");
        throw new Error("Firebase authentication not initialized");
      }

      console.log("🔥 Attempting to create user with Firebase Auth...");
      
      // Créer l'utilisateur dans Firebase Auth
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      console.log('✅ User created in Firebase Auth with UID:', user.uid);
      console.log('📧 User email confirmed:', user.email);

      // Utiliser le nom de clinique fourni ou générer un par défaut
      let finalClinicName;
      if (clinicName && clinicName.trim().length > 0) {
        finalClinicName = clinicName.trim();
        console.log('🏥 Using provided clinic name:', finalClinicName);
      } else {
        const emailPrefix = email.split('@')[0];
        finalClinicName = `${emailPrefix.charAt(0).toUpperCase() + emailPrefix.slice(1)} Health Center`;
        console.log('🏥 Generated default clinic name:', finalClinicName);
      }

      // Préparer les données de la clinique
      const clinicData = {
        clinicName: finalClinicName,
        name: finalClinicName, // Ajouter aussi 'name' pour compatibilité
        email,
        createdAt: new Date(),
        status: "active", // Changer de pending à active
        about: `Welcome to ${finalClinicName}. We are committed to providing exceptional medical care and services. Please update your clinic information in your profile settings.`,
        address: 'Address to be updated',
        location: 'Location to be updated',
        phone: 'Phone to be updated',
        facilities: ['General Medicine'],
        isVerified: false,
        verified: false, // Par défaut sur false
        profileSetupComplete: false, // Flag to indicate profile needs completion
        availableSchedule: {
          'Monday': {'start': '08:00', 'end': '17:00'},
          'Tuesday': {'start': '08:00', 'end': '17:00'},
          'Wednesday': {'start': '08:00', 'end': '17:00'},
          'Thursday': {'start': '08:00', 'end': '17:00'},
          'Friday': {'start': '08:00', 'end': '17:00'},
          'Saturday': {'start': '09:00', 'end': '15:00'},
          'Sunday': {'start': 'Closed', 'end': 'Closed'},
        }
      };

      console.log('📋 Clinic data prepared:', JSON.stringify(clinicData, null, 2));
      console.log('🔧 Firestore db object:', !!db ? "Available" : "Missing");

      // Sauvegarder les données de la clinique dans Firestore
      console.log('💾 Saving clinic data to Firestore...');
      await this.saveClinicData(user.uid, clinicData);

      console.log('✅ Clinic registration completed successfully for:', finalClinicName);

      // Ne pas créer de session après l'inscription
      // L'utilisateur devra se connecter manuellement
      
      return {
        success: true,
        message: "Compte créé avec succès",
        uid: user.uid,
        email: user.email,
        clinicName: finalClinicName
      };

    } catch (error) {
      console.error("❌ AuthService.register - Detailed error:", {
        message: error.message,
        code: error.code,
        stack: error.stack,
        name: error.name
      });

      // Log spécifique pour les erreurs Firebase
      if (error.code) {
        console.error("🔥 Firebase error code:", error.code);
        console.error("🔥 Firebase error message:", error.message);
      }
      
      return {
        success: false,
        message: this.getErrorMessage(error),
        errorCode: error.code,
        errorDetails: error.message
      };
    }
  }

  // Récupérer les données de la clinique
  async getClinicData(uid) {
    try {
      console.log("📖 Getting clinic data for UID:", uid);
      
      const clinicDoc = await getDoc(doc(db, 'clinics', uid));
      
      if (clinicDoc.exists()) {
        console.log("✅ Clinic document found");
        return clinicDoc.data();
      } else {
        console.log("⚠️ No clinic document found for UID:", uid);
        return null;
      }
    } catch (error) {
      console.error("❌ Error getting clinic data:", error);
      return null;
    }
  }

  // Sauvegarder les données de la clinique
  async saveClinicData(uid, data) {
    try {
      console.log("💾 Saving clinic data for UID:", uid);
      console.log("📋 Data to save:", JSON.stringify(data, null, 2));
      
      await setDoc(doc(db, 'clinics', uid), data);
      console.log("✅ Clinic data saved successfully");
      
    } catch (error) {
      console.error("❌ Error saving clinic data:", {
        message: error.message,
        code: error.code,
        stack: error.stack
      });
      throw error; // Re-throw to be caught by register method
    }
  }

  // Gestion des messages d'erreur
  getErrorMessage(error) {
    console.log("🔍 Processing error message for code:", error.code);
    
    switch (error.code) {
      case 'auth/email-already-in-use':
        return 'Cette adresse email est déjà utilisée';
      case 'auth/weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères';
      case 'auth/invalid-email':
        return 'Adresse email invalide';
      case 'auth/user-not-found':
        return 'Utilisateur non trouvé';
      case 'auth/wrong-password':
        return 'Mot de passe incorrect';
      case 'auth/network-request-failed':
        return 'Erreur de connexion réseau';
      case 'auth/too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'auth/operation-not-allowed':
        return 'Cette opération n\'est pas autorisée';
      case 'auth/api-key-not-valid':
        return 'Configuration Firebase invalide';
      default:
        console.log("⚠️ Unknown error code, returning generic message");
        return error.message || 'Erreur inconnue';
    }
  }

  // Logout
  async logout(req) {
    try {
      console.log("🚪 AuthService.logout - Starting logout process");
      
      await signOut(auth);
      
      // Supprimer la session
      const sessionId = req.cookies?.sessionId;
      if (sessionId && req.app.locals.sessions) {
        req.app.locals.sessions.delete(sessionId);
        console.log("🗑️ Session deleted:", sessionId);
      }
      
      console.log("✅ Logout completed successfully");
      
      return { success: true, message: "Déconnexion réussie" };
    } catch (error) {
      console.error("❌ AuthService.logout - Error:", error);
      return { success: false, message: "Erreur lors de la déconnexion" };
    }
  }
}

module.exports = new AuthService();
