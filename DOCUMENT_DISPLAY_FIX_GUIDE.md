# Guide de correction - Affichage des documents dans l'Admin Dashboard

## 🔍 Problème identifié

L'utilisateur ne voyait pas les documents de certificat sur la page `http://localhost:4000/clinic-profile/nmy5dTctp8eGU9D9OgBsV08Fc7G3` malgré leur présence dans Firebase.

## 🕵️ Diagnostic effectué

1. **Vérification des données Firebase** : Les documents étaient bien présents dans Firestore
2. **Analyse du code d'affichage** : Le template EJS était correct pour afficher les documents
3. **Identification de la cause** : La fonction `getClinic` était manquante dans `firebase-admin.js`

## 🔧 Solution implémentée

### 1. Création de la fonction `getClinic`

**Fichier** : `admin-dashboard/config/firebase-admin.js`

```javascript
// Obtenir une clinique individuelle avec tous ses détails
getClinic: async (clinicId) => {
  try {
    console.log('🔍 Récupération de la clinique:', clinicId);
    
    // Utiliser l'API REST Firestore pour récupérer la clinique
    const url = `https://firestore.googleapis.com/v1/projects/homecare-9f4d0/databases/(default)/documents/clinics/${clinicId}`;
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    // ... traitement des données et documents
    
    return { success: true, clinic };
  } catch (error) {
    console.error('❌ Erreur lors de la récupération de la clinique:', error);
    return { success: false, error: error.message };
  }
}
```

### 2. Traitement des documents

La fonction récupère et traite trois types de documents :

- **Certificat** : Documents de certification hospitalière
- **ID/Passport** : Documents d'identité  
- **Additionnel** : Documents supplémentaires

Pour chaque document, elle extrait :
- Nom du fichier
- Type MIME
- Taille en bytes
- Données encodées en base64
- URL de stockage (si applicable)
- Date d'upload
- Méthode de stockage (Firestore/Firebase Storage)

### 3. Mise à jour du serveur

**Fichier** : `admin-dashboard/server.js`

Ajout des documents dans les données passées à la vue :

```javascript
// Format clinic data for display
const profileData = {
  title: `${clinic.clinicName || clinic.name} - Full Profile - HomeCare+`,
  clinic: {
    // ... autres propriétés
    documents: clinic.documents || null
  }
};
```

## ✅ Fonctionnalités disponibles

### Affichage des documents

1. **Documents de Certificat**
   - Badge bleu avec icône certificat
   - Nom du fichier et type
   - Taille formatée en KB
   - Date d'upload
   - Méthode de stockage
   - Bouton "View" pour visualiser

2. **Documents d'Identité**
   - Badge vert avec icône ID
   - Mêmes informations que les certificats
   - Bouton "View" pour visualiser

3. **Documents Supplémentaires**
   - Badge orange avec icône document
   - Mêmes informations que les autres
   - Bouton "View" pour visualiser

### Fonctionnalités de visualisation

- **Modal de visualisation** pour afficher les documents
- **Support des images** (JPG, PNG, etc.)
- **Gestion des erreurs** de chargement
- **Responsive design** pour tous les écrans

## 🧪 Tests effectués

1. **Test de récupération** : Vérification que `getClinic` récupère bien les documents
2. **Test d'affichage** : Confirmation que les documents apparaissent sur la page
3. **Test de fonctionnalité** : Vérification que la visualisation fonctionne

## 📋 Résultat

Les documents sont maintenant correctement affichés sur la page de profil des cliniques avec :
- ✅ Certificat : 1.JPG (107KB, Firestore)
- ✅ ID/Passport : 1.JPG (107KB, Firestore)  
- ✅ Document supplémentaire : 3.JPG (112KB, Firestore)

## 🔗 Pages affectées

- `http://localhost:4000/clinic-profile/[ID]` - Page de profil des cliniques
- Toutes les cliniques ayant des documents uploadés

## 📝 Notes importantes

- La fonction `getClinic` gère automatiquement l'enrichissement Google Places
- Les documents sont stockés en base64 dans Firestore comme fallback
- L'affichage est conditionnel (documents affichés uniquement s'ils existent)
- Le code conserve toute la logique existante sans modification destructive 