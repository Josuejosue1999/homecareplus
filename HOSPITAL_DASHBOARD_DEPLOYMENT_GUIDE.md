# 🏥 GUIDE DE DÉPLOIEMENT - DASHBOARD HÔPITAUX

## 🚨 **Important : Bon Dashboard Identifié**
Le **dashboard des hôpitaux** est le fichier `server.js` à la racine du projet (port 3000), **PAS** le dossier `healthcenter-dashboard`.

## 🎯 **Projet Railway Créé**
- **Nom du projet :** `amuck-beam`
- **URL du projet :** https://railway.com/project/f5d76fc0-6d71-4027-8a3e-306d9e3bd292
- **Environnement :** production

## 📋 **Étapes de Déploiement Manual (Interface Web)**

### 1. **Accéder au Dashboard Railway**
```bash
# Commande pour ouvrir le dashboard
railway open
```

### 2. **Créer un Service**
- Cliquer sur "New Service"
- Sélectionner "Empty Service"
- Nommer le service : `hospital-dashboard`

### 3. **Configurer les Variables d'Environnement**
Dans les Settings du service, ajouter :

```bash
FIREBASE_API_KEY=AIzaSyDYaKiltvi2oUAUO_mi4YNtqCpbJ3RbJI8
FIREBASE_AUTH_DOMAIN=homecare-9f4d0.firebaseapp.com
FIREBASE_PROJECT_ID=homecare-9f4d0
FIREBASE_STORAGE_BUCKET=homecare-9f4d0.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=54787084616
FIREBASE_APP_ID=1:54787084616:android:7892366bf2029a3908a37d
NODE_ENV=production
PORT=3000
```

### 4. **Déployer le Code**
Une fois le service créé, retourner au terminal :
```bash
railway up
```

## 🔧 **Configuration Alternative : Via Terminal**

Si l'interface web fonctionne, essayez :

```bash
# Lier le service créé
railway service hospital-dashboard

# Configurer les variables d'environnement
railway variables --set "FIREBASE_API_KEY=AIzaSyDYaKiltvi2oUAUO_mi4YNtqCpbJ3RbJI8"
railway variables --set "FIREBASE_AUTH_DOMAIN=homecare-9f4d0.firebaseapp.com"
railway variables --set "FIREBASE_PROJECT_ID=homecare-9f4d0"
railway variables --set "FIREBASE_STORAGE_BUCKET=homecare-9f4d0.firebasestorage.app"
railway variables --set "FIREBASE_MESSAGING_SENDER_ID=54787084616"
railway variables --set "FIREBASE_APP_ID=1:54787084616:android:7892366bf2029a3908a37d"
railway variables --set "NODE_ENV=production"
railway variables --set "PORT=3000"

# Déployer
railway up
```

## 📊 **Fichiers à Déployer**
- `server.js` (fichier principal)
- `package.json`
- `public/` (ressources statiques)
- `views/` (templates EJS)
- `config/` (configuration Firebase)
- `routes/` (routes d'authentification)
- `middleware/` (middleware d'authentification)
- `services/` (services d'authentification)

## 🎯 **Résultat Attendu**
Une fois déployé, le dashboard des hôpitaux sera accessible via :
- **URL :** https://amuck-beam-production.up.railway.app
- **Login :** Via les comptes hôpitaux créés dans Firebase
- **Fonctionnalités :** Gestion des rendez-vous, profils, chat, etc.

## 🔍 **Vérification**
```bash
# Vérifier le statut
railway status

# Voir les logs
railway logs

# Vérifier les variables
railway variables
```

## 🚨 **Problèmes Connus**
- **Timeout lors du déploiement :** Utiliser l'interface web Railway
- **Service non lié :** Créer d'abord le service via l'interface web
- **Variables d'environnement :** Les configurer via l'interface web si le terminal ne fonctionne pas

---

**📝 Note :** Ce dashboard est distinct du dashboard admin déjà déployé. Il s'agit du dashboard spécifiquement pour les hôpitaux/centres de santé. 