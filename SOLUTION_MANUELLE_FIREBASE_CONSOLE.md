# 🔥 Solution Manuelle - Créer un compte via Firebase Console

## 🎯 **Problème**
API Identity Toolkit activée, mais signup bloqué temporairement.

## ✅ **SOLUTION IMMÉDIATE** 

### **👉 Étapes pour créer un compte manuellement :**

#### **1. Allez sur Firebase Console**
- URL : https://console.firebase.google.com/
- Connectez-vous avec votre compte Google
- Sélectionnez le projet : `homecare-9f4d0`

#### **2. Créer l'utilisateur**
1. **Cliquez sur "Authentication"** (dans le menu de gauche)
2. **Onglet "Users"**
3. **Cliquez "Add user"**
4. **Remplissez :**
   - **Email :** `votre-email@example.com` (votre choix)
   - **Password :** `test123456`
5. **Cliquez "Add user"**

#### **3. Ajouter les données clinique**
1. **Allez dans "Firestore Database"**
2. **Trouvez la collection "clinics"**
3. **Cliquez "Add document"**
4. **Document ID :** Utilisez l'UID de l'utilisateur créé (copié depuis Authentication)
5. **Ajoutez ces champs :**

```javascript
{
  name: "Ma Clinique Test",
  email: "votre-email@example.com",  // Le même que l'utilisateur
  phone: "+250123456789",
  address: "Kigali, Rwanda",
  specialties: ["Médecine générale"],
  verified: true,
  createdAt: new Date(),
  updatedAt: new Date()
}
```

#### **4. Tester la connexion**
1. **Allez sur :** https://dynamic-color-production.up.railway.app
2. **Connectez-vous avec :**
   - Email : `votre-email@example.com`
   - Mot de passe : `test123456`

---

## 🚀 **SOLUTION AUTOMATISÉE (en attendant)**

### **Test dans 5 minutes :** 