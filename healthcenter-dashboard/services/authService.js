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
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;
      
      console.log("Login successful for user:", user.uid);
      
      // Récupérer les données de la clinique depuis Firestore
      const clinicData = await this.getClinicData(user.uid);
      console.log("Clinic data retrieved:", clinicData);
      
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

      console.log("User data prepared for session:", userData);

      // Créer une session
      const sessionId = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
      
      // Stocker la session dans app.locals
      req.app.locals.sessions = req.app.locals.sessions || new Map();
      req.app.locals.sessions.set(sessionId, userData);
      
      console.log("Session created with ID:", sessionId);
      
      return {
        success: true,
        user: userData,
        sessionId
      };
    } catch (error) {
      console.error("Login error:", error);
      return {
        success: false,
        message: this.getErrorMessage(error.code)
      };
    }
  }

  // Register avec Firebase
  async register(clinicName, email, password, req) {
    try {
      // Créer l"utilisateur dans Firebase Auth
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      console.log('User created with UID:', user.uid);

      // Sauvegarder les données de la clinique dans Firestore
      await this.saveClinicData(user.uid, {
        clinicName,
        name: clinicName, // Ajouter aussi 'name' pour compatibilité
        email,
        createdAt: new Date(),
        status: "active",
        about: `${clinicName} is a healthcare facility committed to providing exceptional medical care and services.`,
        address: 'Address to be updated',
        location: 'Location to be updated',
        phone: 'Phone to be updated',
        facilities: ['General Medicine'],
        isVerified: false,
        availableSchedule: {
          'Monday': {'start': '08:00', 'end': '17:00'},
          'Tuesday': {'start': '08:00', 'end': '17:00'},
          'Wednesday': {'start': '08:00', 'end': '17:00'},
          'Thursday': {'start': '08:00', 'end': '17:00'},
          'Friday': {'start': '08:00', 'end': '17:00'},
          'Saturday': {'start': '09:00', 'end': '15:00'},
          'Sunday': {'start': 'Closed', 'end': 'Closed'},
        }
      });

      console.log('Clinic registration completed for:', clinicName);

      // Ne pas créer de session après l'inscription
      // L'utilisateur devra se connecter manuellement
      
      return {
        success: true,
        message: "Compte créé avec succès"
      };
    } catch (error) {
      console.error("Register error:", error);
      return {
        success: false,
        message: this.getErrorMessage(error.code)
      };
    }
  }

  // Logout
  async logout(req) {
    try {
      await signOut(auth);
      
      // Supprimer la session
      const sessionId = req.cookies?.sessionId;
      if (sessionId && req.app.locals.sessions) {
        req.app.locals.sessions.delete(sessionId);
      }
      
      return { success: true };
    } catch (error) {
      console.error("Logout error:", error);
      return { success: false, message: "Logout failed" };
    }
  }

  // Récupérer les données de la clinique
  async getClinicData(uid) {
    try {
      console.log("Getting clinic data for UID:", uid);
      
      // Essayer d'abord la collection "clinics"
      let clinicDoc = await getDoc(doc(db, "clinics", uid));
      if (clinicDoc.exists()) {
        console.log("Found clinic data in 'clinics' collection");
        return clinicDoc.data();
      }
      
      // Si pas trouvé, essayer la collection "users" (pour compatibilité)
      clinicDoc = await getDoc(doc(db, "users", uid));
      if (clinicDoc.exists()) {
        console.log("Found clinic data in 'users' collection");
        return clinicDoc.data();
      }
      
      // Si toujours pas trouvé, chercher par email dans la collection "clinics"
      console.log("Searching for clinic by email...");
      const q = query(collection(db, "clinics"), where("email", "==", uid));
      const querySnapshot = await getDocs(q);
      if (!querySnapshot.empty) {
        console.log("Found clinic data by email search");
        return querySnapshot.docs[0].data();
      }
      
      console.log("No clinic data found");
      return null;
    } catch (error) {
      console.error("Error getting clinic data:", error);
      return null;
    }
  }

  // Sauvegarder les données de la clinique
  async saveClinicData(uid, data) {
    try {
      // Créer des données de clinique complètes avec des valeurs par défaut
      const completeClinicData = {
        ...data,
        name: data.clinicName || data.name || 'New Clinic',
        clinicName: data.clinicName || data.name || 'New Clinic',
        email: data.email || '',
        about: data.about || 'This healthcare facility is committed to providing exceptional medical care and services.',
        address: data.address || 'Address not set',
        location: data.location || 'Location not set',
        phone: data.phone || 'Phone not set',
        facilities: data.facilities || ['General Medicine'],
        profileImageUrl: data.profileImageUrl || null,
        certificateUrl: data.certificateUrl || null,
        createdAt: data.createdAt || new Date(),
        updatedAt: new Date(),
        status: data.status || 'active',
        isVerified: false,
        availableSchedule: data.availableSchedule || {},
        latitude: data.latitude || null,
        longitude: data.longitude || null,
      };

      console.log('Saving complete clinic data:', completeClinicData);
      await setDoc(doc(db, "clinics", uid), completeClinicData);
      console.log('Clinic data saved successfully for UID:', uid);
      return true;
    } catch (error) {
      console.error("Error saving clinic data:", error);
      return false;
    }
  }

  // Vérifier si l"email existe déjà
  async checkEmailExists(email) {
    try {
      const q = query(collection(db, "clinics"), where("email", "==", email));
      const querySnapshot = await getDocs(q);
      return !querySnapshot.empty;
    } catch (error) {
      console.error("Error checking email:", error);
      return false;
    }
  }

  // Convertir les codes d"erreur Firebase en messages utilisateur
  getErrorMessage(errorCode) {
    const errorMessages = {
      "auth/user-not-found": "Aucun compte trouvé avec cet email",
      "auth/wrong-password": "Mot de passe incorrect",
      "auth/email-already-in-use": "Cet email est déjà utilisé",
      "auth/weak-password": "Le mot de passe doit contenir au moins 6 caractères",
      "auth/invalid-email": "Email invalide",
      "auth/too-many-requests": "Trop de tentatives. Réessayez plus tard",
      "auth/network-request-failed": "Erreur de connexion réseau"
    };
    
    return errorMessages[errorCode] || "Une erreur est survenue";
  }
}

module.exports = new AuthService();
