// Middleware d"authentification
const requireAuth = (req, res, next) => {
  const sessionId = req.cookies?.sessionId;
  
  if (!sessionId) {
    // Si c'est une requête API, retourner une erreur JSON
    if (req.path.startsWith('/api/')) {
      return res.status(401).json({
        success: false,
        message: "Authentication required"
      });
    }
    return res.redirect("/login");
  }
  
  // Vérifier la session dans app.locals
  const sessions = req.app.locals.sessions;
  if (!sessions || !sessions.has(sessionId)) {
    res.clearCookie("sessionId");
    // Si c'est une requête API, retourner une erreur JSON
    if (req.path.startsWith('/api/')) {
      return res.status(401).json({
        success: false,
        message: "Session expired"
      });
    }
    return res.redirect("/login");
  }
  
  // Ajouter l"utilisateur à la requête
  req.user = sessions.get(sessionId);
  next();
};

// Middleware pour rediriger les utilisateurs déjà connectés
const redirectIfAuthenticated = (req, res, next) => {
  const sessionId = req.cookies?.sessionId;
  
  if (sessionId) {
    const sessions = req.app.locals.sessions;
    if (sessions && sessions.has(sessionId)) {
      return res.redirect("/dashboard");
    }
  }
  
  next();
};

module.exports = {
  requireAuth,
  redirectIfAuthenticated
};
