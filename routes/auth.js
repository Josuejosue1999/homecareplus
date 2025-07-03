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
    
    // Créer le document clinique
    await setDoc(doc(db, 'clinics', user.uid), {
      name: clinicName,
      clinicName: clinicName,
      email: email,
      createdAt: new Date(),
      updatedAt: new Date()
    });
    
    // Créer une session
    const sessionId = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
    
    // Stocker la session dans app.locals
    if (!req.app.locals.sessions) {
      req.app.locals.sessions = new Map();
    }
    
    req.app.locals.sessions.set(sessionId, {
      uid: user.uid,
      email: user.email,
      clinicName: clinicName
    });
    
    // Cookie de session
    res.cookie("sessionId", sessionId, {
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      maxAge: 24 * 60 * 60 * 1000 // 24 heures
    });
    
    res.json({
      success: true,
      message: "Compte créé avec succès",
      user: {
        uid: user.uid,
        email: user.email,
        clinicName: clinicName
      }
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
