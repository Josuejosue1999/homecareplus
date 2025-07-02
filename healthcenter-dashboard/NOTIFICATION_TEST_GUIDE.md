# Guide de Test des Notifications Sonores - Version Améliorée

## 🎯 Objectif
Vérifier que le système de notifications sonores fonctionne correctement quand un patient réserve un rendez-vous depuis l'app mobile.

## 🔧 Améliorations Apportées

### ✅ **Nouvelles Fonctionnalités**
1. **Détection améliorée** : Fenêtre de détection étendue à 10 minutes
2. **Audio robuste** : 3 niveaux de fallback audio
3. **Activation automatique** : Audio débloqué au premier clic
4. **Logging détaillé** : Logs avec emojis pour faciliter le debugging
5. **Gestion d'erreurs** : Meilleure gestion des erreurs audio

### 🔊 **Système Audio Multi-niveaux**
1. **Niveau 1** : Fichier MP3 principal (`appointment.mp3`)
2. **Niveau 2** : Web Audio API (beeps générés)
3. **Niveau 3** : System beep (dernière chance)

## 🧪 Tests à Effectuer

### Test 1 : Bouton de Test
1. Ouvrez le dashboard web (http://localhost:3001)
2. Connectez-vous avec votre compte clinic
3. Cliquez sur le bouton de test (🔊) dans le header
4. Vous devriez entendre un son de notification

### Test 2 : Test Audio Direct
1. Ouvrez la console du navigateur (F12)
2. Exécutez : `window.testNotificationService.playNotificationSound()`
3. Vous devriez entendre plusieurs sons de test

### Test 3 : Test avec Rendez-vous Réel
1. Depuis l'app mobile, réservez un nouveau rendez-vous
2. Le dashboard web devrait automatiquement :
   - Détecter le nouveau rendez-vous
   - Jouer un son de notification
   - Afficher une notification toast
   - Animer la cloche de notification

## 🔍 Debugging

### Vérifier les Logs
1. Ouvrez la console du navigateur (F12)
2. Regardez les logs avec emojis :
   - 🔔 : Initialisation du service
   - 🔍 : Vérification des rendez-vous
   - 🎉 : Nouveau rendez-vous détecté
   - 🔊 : Tentative de lecture audio
   - ✅ : Succès
   - ❌ : Erreur

### Problèmes Courants

#### 1. Pas de Son
- **Cause** : Audio non activé par l'utilisateur
- **Solution** : Cliquez n'importe où sur la page pour activer l'audio

#### 2. Rendez-vous Non Détectés
- **Cause** : Fenêtre de détection trop courte
- **Solution** : Le système vérifie maintenant les 10 dernières minutes

#### 3. Erreurs Audio
- **Cause** : Navigateur bloque l'audio
- **Solution** : Le système utilise 3 niveaux de fallback

## 🎵 Fichiers Audio

### Fichiers Requis
- `public/assets/appointment.mp3` : Son principal
- `public/assets/notification.mp3` : Son de fallback

### Création de Fichiers Audio
Si vous n'avez pas de fichiers audio, le système utilise des sons générés automatiquement.

## 📱 Test Mobile → Web

### Étapes de Test
1. **Ouvrez le dashboard web** sur votre ordinateur
2. **Connectez-vous** avec votre compte clinic
3. **Depuis l'app mobile**, réservez un nouveau rendez-vous
4. **Vérifiez** que le dashboard web :
   - Affiche le nouveau rendez-vous
   - Joue un son de notification
   - Montre une notification toast

### Vérifications
- ✅ Rendez-vous apparaît dans la liste
- ✅ Son de notification joué
- ✅ Notification toast affichée
- ✅ Cloche animée
- ✅ Badge de notification mis à jour

## 🛠️ Configuration

### Paramètres Modifiables
- **Intervalle de vérification** : 10 secondes
- **Fenêtre de détection** : 10 minutes
- **Volume audio** : 0.8 (80%)
- **Durée des beeps** : 0.3 secondes

### Activation/Désactivation
- Cliquez sur l'icône 🔊 dans le header pour activer/désactiver le son
- La préférence est sauvegardée dans localStorage

## 🚨 Dépannage

### Le Son Ne Fonctionne Pas
1. Vérifiez que le son n'est pas coupé sur votre ordinateur
2. Cliquez sur la page pour activer l'audio
3. Vérifiez les logs dans la console
4. Testez avec le bouton de test

### Les Rendez-vous Ne Sont Pas Détectés
1. Vérifiez que vous êtes connecté avec le bon compte
2. Vérifiez que le nom de l'hôpital correspond
3. Vérifiez les logs de détection
4. Attendez quelques secondes (polling toutes les 10s)

### Erreurs dans la Console
1. Vérifiez que tous les fichiers sont présents
2. Vérifiez les permissions du navigateur
3. Essayez de rafraîchir la page
4. Vérifiez la connexion internet

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs dans la console
2. Testez avec le bouton de test
3. Vérifiez que le serveur fonctionne
4. Contactez le support technique 