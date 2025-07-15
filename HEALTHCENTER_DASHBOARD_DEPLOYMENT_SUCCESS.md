# 🏥 DÉPLOIEMENT DASHBOARD HÔPITAUX - CONFIGURATION CORRIGÉE

## ✅ **Statut : Prêt pour Déploiement**

### 🎯 **Dashboard Correctement Identifié**
**🔗 Dashboard Hôpitaux :** `server.js` (racine du projet)  
**🔌 Port Local :** 3000  
**📁 Dossier :** `/` (racine)  
**✅ Test Local :** Fonctionnel à `http://localhost:3000`

### 🔧 **Configuration Railway Corrigée**

#### 📋 **Package.json**
```json
{
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  }
}
```

#### ⚙️ **Railway.toml**
```toml
[deploy]
startCommand = "node server.js"
restartPolicyType = "ON_FAILURE"
```

#### 🚫 **.railwayignore**
- ✅ Exclut `healthcenter-dashboard/` (pas le principal)
- ✅ Inclut `server.js`, `routes/`, `views/`, `config/`
- ✅ Exclut `admin-dashboard/` (déploiement séparé)

### 🚀 **Prochaines Étapes pour Déploiement**

1. **Lier un Projet Railway :**
   ```bash
   railway link
   # Sélectionner : generous-magic (ou créer nouveau)
   ```

2. **Configurer Variables d'Environnement :**
   ```bash
   railway variables set NODE_ENV=production
   railway variables set PORT=3000
   railway variables set FIREBASE_API_KEY=your_key
   railway variables set GOOGLE_MAPS_API_KEY=your_key
   railway variables set SESSION_SECRET=your_secret
   ```

3. **Déployer :**
   ```bash
   railway up --detach
   ```

### 🏥 **Fonctionnalités du Dashboard Hôpitaux**
- ✅ **Gestion des Rendez-vous** - Voir et gérer les RDV patients
- ✅ **Profil Clinique** - Mise à jour des informations hôpital
- ✅ **Chat Temps Réel** - Communication avec les patients  
- ✅ **Notifications** - Alertes pour nouveaux RDV
- ✅ **Tableau de Bord** - Vue d'ensemble des activités
- ✅ **Socket.IO** - Connexions WebSocket pour temps réel

### 📊 **Architecture Technique**
- **Backend :** Node.js + Express
- **Base de Données :** Firebase Firestore
- **Stockage :** Firebase Storage
- **Temps Réel :** Socket.IO
- **Authentification :** Firebase Auth
- **Cartes :** Google Maps API

### 🔑 **Variables d'Environnement Nécessaires**
```bash
NODE_ENV=production
PORT=3000
FIREBASE_API_KEY=AIzaSyDYaKiltvi2oUAUO_mi4YNtqCpbJ3RbJI8
FIREBASE_AUTH_DOMAIN=homecare-9f4d0.firebaseapp.com  
FIREBASE_PROJECT_ID=homecare-9f4d0
FIREBASE_STORAGE_BUCKET=homecare-9f4d0.firebasestorage.app
GOOGLE_MAPS_API_KEY=AIzaSyA1g-UDJcfQS_33U3Sysxe9g4zlAOnpS3g
SESSION_SECRET=homecare-secret-key-2024
```

### 📱 **URLs Attendues**
- **🏠 Dashboard Principal :** `/dashboard`
- **👥 Patients :** `/patients`  
- **💬 Chat :** `/chat`
- **🏥 Profil :** `/profile`
- **⚙️ Paramètres :** `/settings`
- **📊 API :** `/api/*`

---

**📝 Note :** Ce dashboard est différent de l'admin-dashboard qui est pour l'administration générale. Celui-ci est spécifiquement pour les hôpitaux/cliniques pour gérer leurs activités quotidiennes. 