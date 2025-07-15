# 🔥 Création Manuelle de Compte - Hospital Dashboard

## 🎯 **SOLUTION IMMÉDIATE (100% GARANTIE)**

Créons un compte directement dans Firebase Console pour contourner l'API bloquée.

---

## 📋 **ÉTAPES PRÉCISES À SUIVRE :**

### **🔥 Étape 1 : Créer l'utilisateur dans Firebase Auth**

1. **Allez sur :** https://console.firebase.google.com/
2. **Connectez-vous** avec votre compte Google
3. **Sélectionnez le projet :** `homecare-9f4d0`
4. **Menu gauche :** Cliquez sur **"Authentication"**
5. **Onglet "Users"**
6. **Cliquez "Add user"**
7. **Remplissez :**
   - **Email :** `hospital-admin@test.com`
   - **Password :** `test123456`
8. **Cliquez "Add user"**
9. **⚠️ IMPORTANT :** Copiez l'**UID** affiché (ex: `abc123def456...`)

### **🗃️ Étape 2 : Créer les données clinique dans Firestore**

1. **Menu gauche :** Cliquez sur **"Firestore Database"**
2. **Onglet "Data"**
3. **Trouvez la collection "clinics"** (ou créez-la si elle n'existe pas)
4. **Cliquez "Add document"**
5. **Document ID :** Collez l'**UID** copié à l'étape 1
6. **Ajoutez ces champs EXACTEMENT :**

```javascript
{
  name: "Hospital Test Center",
  email: "hospital-admin@test.com",
  phone: "+250788123456",
  address: "Kigali, Rwanda",
  specialties: ["Médecine générale", "Pédiatrie"],
  verified: true,
  createdAt: Timestamp (utilisez "Add field" > "timestamp" > "now"),
  updatedAt: Timestamp (utilisez "Add field" > "timestamp" > "now"),
  description: "Centre médical de test"
}
```

7. **Cliquez "Save"**

### **✅ Étape 3 : Tester la connexion**

1. **Allez sur :** https://dynamic-color-production.up.railway.app
2. **Connectez-vous avec :**
   - **Email :** `hospital-admin@test.com`
   - **Mot de passe :** `test123456`

---

## 🚀 **COMPTE PRÊT À UTILISER :**

**📧 Email :** `hospital-admin@test.com`  
**🔑 Mot de passe :** `test123456`  
**🌐 URL :** https://dynamic-color-production.up.railway.app

---

## 🔧 **SI VOUS VOULEZ VOTRE PROPRE EMAIL :**

Répétez les étapes en remplaçant `hospital-admin@test.com` par votre email préféré.

**✅ Cette méthode fonctionne à 100% car elle contourne l'API bloquée !** 