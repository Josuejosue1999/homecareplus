# 🔥 Guide de Configuration Firebase + Netlify

## ✅ **Étape 1 : Configuration Firebase Console**

### 1.1 Domaines Autorisés
Allez dans **Firebase Console** → **Authentication** → **Settings** → **Authorized domains**

**AJOUTER CES DOMAINES :**
```
tangerine-torte-d4a6b5.netlify.app
```

### 1.2 APIs Google Cloud à Activer
Allez dans **Google Cloud Console** → **APIs & Services** → **Enabled APIs**

**ACTIVER CES APIs :**
- ✅ Identity and Access Management (IAM) API
- ✅ Google Identity Toolkit API  
- ✅ Cloud Resource Manager API
- ✅ Firebase Authentication API

### 1.3 Méthode de Connexion
Dans **Firebase Console** → **Authentication** → **Sign-in method**

**ACTIVER :**
- ✅ Email/Password

## ⚙️ **Étape 2 : Variables d'Environnement Netlify**

### 2.1 Accéder aux Variables Netlify
1. Aller sur votre tableau de bord Netlify
2. Sélectionner votre site `tangerine-torte-d4a6b5`
3. Aller dans **Site settings** → **Environment variables**

### 2.2 Ajouter les Variables Firebase
```bash
# Firebase Configuration
FIREBASE_API_KEY=AIzaSyBWnaj_7qrK9pSBSI2sKSnFVLkyskhcZog
FIREBASE_AUTH_DOMAIN=homecare-9f4d0.firebaseapp.com
FIREBASE_PROJECT_ID=homecare-9f4d0
FIREBASE_STORAGE_BUCKET=homecare-9f4d0.firebasestorage.app
FIREBASE_MESSAGING_SENDER_ID=54787084616
FIREBASE_APP_ID=1:54787084616:web:2fe62181a935fefc08a37d

# App Configuration
NODE_ENV=production
PORT=3001
```

## 🔧 **Étape 3 : Test de Fonctionnement**

### 3.1 Test Simple
Après déploiement, testez :
- https://tangerine-torte-d4a6b5.netlify.app/test.html

### 3.2 Test Navigation
- https://tangerine-torte-d4a6b5.netlify.app (page d'accueil)
- https://tangerine-torte-d4a6b5.netlify.app/register
- https://tangerine-torte-d4a6b5.netlify.app/login

## 🚨 **Dépannage**

### Si erreur 404 persiste :
1. **Vider le cache navigateur** (Ctrl+F5)
2. **Vérifier variables Netlify** sont bien configurées
3. **Vérifier domaine Firebase** est autorisé
4. **Vérifier logs Netlify** pour erreurs de build

### Si erreur Firebase :
1. **Vérifier APIs Google Cloud** sont activées
2. **Vérifier clés Firebase** sont correctes
3. **Vérifier domaine autorisé** dans Firebase Console

## 📋 **Checklist**

- [ ] Domaine Netlify ajouté à Firebase
- [ ] APIs Google Cloud activées  
- [ ] Email/Password activé dans Firebase
- [ ] Variables d'environnement configurées sur Netlify
- [ ] Test page accessible
- [ ] Navigation fonctionne

---

**🎯 Ordre des Actions :**
1. **D'ABORD** → Configurer Firebase (domaines + APIs)
2. **ENSUITE** → Configurer variables Netlify  
3. **ENFIN** → Tester le site 