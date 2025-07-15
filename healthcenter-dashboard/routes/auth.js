const express = require("express");
const router = express.Router();
const authService = require("../services/authService");

// Route de login
router.post("/login", async (req, res) => {
  try {
    console.log("🚪 Auth Route - LOGIN request received");
    console.log("📧 Login email:", req.body.email);
    console.log("🔑 Password provided:", !!req.body.password);
    
    const { email, password } = req.body;
    
    // Validation
    if (!email || !password) {
      console.log("❌ Login validation failed - missing email or password");
      return res.status(400).json({
        success: false,
        message: "Email et mot de passe requis"
      });
    }

    // Authentification
    console.log("🔐 Calling authService.login...");
    const result = await authService.login(email, password, req);
    console.log("📋 Login result:", { success: result.success, message: result.message });
    
    if (result.success) {
      // Cookie de session
      res.cookie("sessionId", result.sessionId, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        maxAge: 24 * 60 * 60 * 1000 // 24 heures
      });
      
      console.log("✅ Login successful, session cookie set");
      
      res.json({
        success: true,
        message: "Connexion réussie",
        user: result.user
      });
    } else {
      console.log("❌ Login failed:", result.message);
      res.status(401).json(result);
    }
    
  } catch (error) {
    console.error("❌ Auth Route - LOGIN error:", {
      message: error.message,
      stack: error.stack
    });
    res.status(500).json({
      success: false,
      message: "Erreur interne du serveur"
    });
  }
});

// Route d'inscription
router.post("/register", async (req, res) => {
  try {
    console.log("📝 Auth Route - REGISTER request received");
    console.log("📧 Register email:", req.body.email);
    console.log("🔑 Password provided:", !!req.body.password);
    console.log("🏥 Clinic name provided:", req.body.clinicName || 'Not provided');
    console.log("📋 Full request body:", JSON.stringify(req.body, null, 2));
    
    const { email, password, clinicName } = req.body;
    
    // Validation des champs obligatoires
    if (!email || !password) {
      console.log("❌ Register validation failed - missing email or password");
      return res.status(400).json({
        success: false,
        message: "Email et mot de passe requis"
      });
    }

    // Validation email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      console.log("❌ Register validation failed - invalid email format");
      return res.status(400).json({
        success: false,
        message: "Format d'email invalide"
      });
    }

    // Validation mot de passe
    if (password.length < 6) {
      console.log("❌ Register validation failed - password too short");
      return res.status(400).json({
        success: false,
        message: "Le mot de passe doit contenir au moins 6 caractères"
      });
    }

    console.log("✅ Register validation passed");
    console.log("🔐 Calling authService.register...");
    
    // Inscription avec nom de clinique optionnel
    const result = await authService.register(email, password, req, clinicName);
    
    console.log("📋 Register result:", { 
      success: result.success, 
      message: result.message,
      errorCode: result.errorCode,
      errorDetails: result.errorDetails
    });
    
    if (result.success) {
      console.log("✅ Registration successful");
      res.status(201).json({
        success: true,
        message: "Compte créé avec succès. Vous pouvez maintenant vous connecter.",
        data: {
          email: result.email,
          clinicName: result.clinicName,
          uid: result.uid
        }
      });
    } else {
      console.log("❌ Registration failed:", result.message);
      
      // Déterminer le code d'erreur HTTP approprié
      let statusCode = 400;
      if (result.errorCode === 'auth/email-already-in-use') {
        statusCode = 409; // Conflict
      } else if (result.errorCode === 'auth/weak-password') {
        statusCode = 400; // Bad Request
      } else if (result.errorCode === 'auth/invalid-email') {
        statusCode = 400; // Bad Request
      } else if (result.errorCode && result.errorCode.includes('network')) {
        statusCode = 503; // Service Unavailable
      }
      
      res.status(statusCode).json({
        success: false,
        message: result.message,
        errorCode: result.errorCode,
        errorDetails: result.errorDetails
      });
    }
    
  } catch (error) {
    console.error("❌ Auth Route - REGISTER critical error:", {
      message: error.message,
      stack: error.stack,
      name: error.name
    });
    
    res.status(500).json({
      success: false,
      message: "Erreur interne du serveur",
      errorDetails: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Route de déconnexion
router.post("/logout", async (req, res) => {
  try {
    console.log("🚪 Auth Route - LOGOUT request received");
    
    const result = await authService.logout(req);
    
    if (result.success) {
      res.clearCookie("sessionId");
      console.log("✅ Logout successful, session cookie cleared");
    }
    
    res.json(result);
    
  } catch (error) {
    console.error("❌ Auth Route - LOGOUT error:", error);
    res.status(500).json({
      success: false,
      message: "Erreur interne du serveur"
    });
  }
});

module.exports = router;
