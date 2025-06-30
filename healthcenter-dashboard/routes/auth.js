const express = require("express");
const router = express.Router();
const authService = require("../services/authService");

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

    // Authentification
    const result = await authService.login(email, password, req);
    
    if (result.success) {
      // Cookie de session
      res.cookie("sessionId", result.sessionId, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        maxAge: 24 * 60 * 60 * 1000 // 24 heures
      });
      
      res.json({
        success: true,
        message: "Connexion réussie",
        user: result.user
      });
    } else {
      res.status(401).json(result);
    }
    
  } catch (error) {
    console.error("Login route error:", error);
    res.status(500).json({
      success: false,
      message: "Erreur interne du serveur"
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
    
    // Vérifier si l"email existe déjà
    const emailExists = await authService.checkEmailExists(email);
    if (emailExists) {
      return res.status(409).json({
        success: false,
        message: "Cet email est déjà utilisé"
      });
    }
    
    // Créer le compte
    const result = await authService.register(clinicName, email, password, req);
    
    if (result.success) {
      // Cookie de session
      res.cookie("sessionId", result.sessionId, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        maxAge: 24 * 60 * 60 * 1000 // 24 heures
      });
      
      res.json({
        success: true,
        message: "Compte créé avec succès",
        user: result.user
      });
    } else {
      res.status(400).json(result);
    }
    
  } catch (error) {
    console.error("Register route error:", error);
    res.status(500).json({
      success: false,
      message: "Erreur interne du serveur"
    });
  }
});

// Route de logout
router.post("/logout", async (req, res) => {
  try {
    // Supprimer le cookie de session
    res.clearCookie("sessionId");
    
    // Logout Firebase
    await authService.logout(req);
    
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
