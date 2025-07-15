# 🔧 Guide de Diagnostic Netlify - "Something broke!"

## 🚨 **Erreur Actuelle**
```json
{"success":false,"message":"Something broke!"}
```

Cette erreur indique que les **variables d'environnement Firebase** ne sont **PAS configurées** sur Netlify.

## ✅ **SOLUTION IMMÉDIATE**

### **ÉTAPE 1: Configurer Variables Netlify**

1. **Aller sur Netlify Dashboard**
   - https://app.netlify.com/sites/zippy-bonbon-ed8974/settings/env

2. **Cliquer "Add variable"** et ajouter **UNE PAR UNE** :

```bash
FIREBASE_API_KEY
Valeur: AIzaSyBWnaj_7qrK9pSBSI2sKSnFVLkyskhcZog

FIREBASE_AUTH_DOMAIN  
Valeur: homecare-9f4d0.firebaseapp.com

FIREBASE_PROJECT_ID
Valeur: homecare-9f4d0

FIREBASE_STORAGE_BUCKET
Valeur: homecare-9f4d0.firebasestorage.app

FIREBASE_MESSAGING_SENDER_ID
Valeur: 54787084616

FIREBASE_APP_ID
Valeur: 1:54787084616:web:2fe62181a935fefc08a37d

NODE_ENV
Valeur: production
```

### **ÉTAPE 2: Test de Diagnostic**

Après avoir ajouté les variables, testez :
- https://zippy-bonbon-ed8974.netlify.app/test-config

**Résultat attendu :**
```json
{
  "message": "Configuration Test",
  "environment_variables": {
    "FIREBASE_API_KEY": "SET",
    "FIREBASE_AUTH_DOMAIN": "SET", 
    "FIREBASE_PROJECT_ID": "SET",
    "FIREBASE_STORAGE_BUCKET": "SET",
    "FIREBASE_MESSAGING_SENDER_ID": "SET",
    "FIREBASE_APP_ID": "SET",
    "NODE_ENV": "production"
  }
}
```

### **ÉTAPE 3: Redéploiement**

Après avoir configuré les variables :
1. **Netlify redéploie automatiquement** (attendre 2-3 minutes)
2. **Tester** : https://zippy-bonbon-ed8974.netlify.app/register

## 🎯 **Firebase Console (aussi requis)**

Ajouter le domaine autorisé :
1. **Firebase Console** → **Authentication** → **Settings** → **Authorized domains**
2. **Ajouter** : `zippy-bonbon-ed8974.netlify.app`

---

## 📋 **Checklist**

- [ ] Variables d'environnement ajoutées sur Netlify
- [ ] Test diagnostic passe (toutes les variables "SET")
- [ ] Domaine ajouté à Firebase
- [ ] Application testée sur /register

**🚨 IMPORTANT: Les variables sont OBLIGATOIRES - l'app ne peut pas fonctionner sans !** 