const express = require("express");
const router = express.Router();
const { auth, db, doc, getDoc, setDoc, collection, query, where, getDocs } = require("../config/firebase");
const { signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut } = require("firebase/auth");

// Route de login
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email et mot de passe requis"
      });
    }

    // Authentification Firebase
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;
    
    // Récupérer les informations de la clinique
    const clinicDoc = await getDoc(doc(db, 'clinics', user.uid));
    
    if (!clinicDoc.exists()) {
      return res.status(404).json({
        success: false,
        message: "Clinique non trouvée"
      });
    }
    
    const clinicData = clinicDoc.data();
    
    // Créer une session
    const sessionId = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
    
    // Stocker la session dans app.locals
    if (!req.app.locals.sessions) {
      req.app.locals.sessions = new Map();
    }
    
    req.app.locals.sessions.set(sessionId, {
      uid: user.uid,
      email: user.email,
      clinicName: clinicData.name || clinicData.clinicName || email.split('@')[0],
      ...clinicData
    });
    
    // Cookie de session
    res.cookie("sessionId", sessionId, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      maxAge: 24 * 60 * 60 * 1000 // 24 heures
    });
    
    res.json({
      success: true,
      message: "Connexion réussie",
      user: {
        uid: user.uid,
        email: user.email,
        clinicName: clinicData.name || clinicData.clinicName
      }
    });
    
  } catch (error) {
    console.error("Login route error:", error);
    res.status(401).json({
      success: false,
      message: "Email ou mot de passe incorrect"
    });
  }
});

// Route de register
router.post("/register", async (req, res) => {
  try {
    const { clinicName, email, password, confirmPassword } = req.body;
    
    // Validation
    if (!clinicName || !email || !password || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "Tous les champs sont requis"
      });
    }
    
    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: "Les mots de passe ne correspondent pas"
      });
    }
    
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Le mot de passe doit contenir au moins 6 caractères"
      });
    }
    
    // Créer l'utilisateur Firebase
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;
    
    // Générer un avatar par défaut (initiales avec couleur de fond)
    const initials = clinicName.split(' ').map(word => word.charAt(0).toUpperCase()).join('').substring(0, 2);
    const colors = ['#159BBD', '#28a745', '#dc3545', '#ffc107', '#6f42c1', '#fd7e14', '#20c997'];
    const randomColor = colors[Math.floor(Math.random() * colors.length)];
    
    // Créer un SVG avatar par défaut
    const defaultAvatar = `data:image/svg+xml;base64,${Buffer.from(`
      <svg width="120" height="120" xmlns="http://www.w3.org/2000/svg">
        <circle cx="60" cy="60" r="60" fill="${randomColor}"/>
        <text x="60" y="75" font-family="Arial, sans-serif" font-size="36" font-weight="bold" 
              fill="white" text-anchor="middle">${initials}</text>
      </svg>
    `).toString('base64')}`;
    
    // Créer le document clinique avec avatar par défaut
    await setDoc(doc(db, 'clinics', user.uid), {
      name: clinicName,
      clinicName: clinicName,
      email: email,
      profileImageUrl: defaultAvatar,
      profileImage: defaultAvatar, // Pour compatibilité
      createdAt: new Date(),
      updatedAt: new Date(),
      lastUpdated: new Date()
    });
    
    // Ne pas créer de session automatiquement - forcer l'utilisateur à se connecter
    // Déconnecter l'utilisateur après création du compte
    await signOut(auth);
    
    res.json({
      success: true,
      message: "Compte créé avec succès! Veuillez vous connecter.",
      redirectToLogin: true // Indicateur pour la redirection
    });
    
  } catch (error) {
    console.error("Register route error:", error);
    let message = "Erreur interne du serveur";
    
    if (error.code === 'auth/email-already-in-use') {
      message = "Cet email est déjà utilisé";
    } else if (error.code === 'auth/weak-password') {
      message = "Le mot de passe est trop faible";
    } else if (error.code === 'auth/invalid-email') {
      message = "Email invalide";
    }
    
    res.status(400).json({
      success: false,
      message: message
    });
  }
});

// Route de logout
router.post("/logout", async (req, res) => {
  try {
    const sessionId = req.cookies?.sessionId;
    
    // Supprimer le cookie de session
    res.clearCookie("sessionId");
    
    // Supprimer la session
    if (sessionId && req.app.locals.sessions) {
      req.app.locals.sessions.delete(sessionId);
    }
    
    // Logout Firebase
    await signOut(auth);
    
    res.json({
      success: true,
      message: "Déconnexion réussie"
    });
    
  } catch (error) {
    console.error("Logout route error:", error);
    res.status(500).json({
      success: false,
      message: "Erreur lors de la déconnexion"
    });
  }
});

module.exports = router;
