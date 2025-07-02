# Guide de Test des Notifications Sonores

## 🎯 Objectif
Tester que le système de notifications sonores fonctionne quand un patient réserve un rendez-vous.

## ✅ Prérequis
1. Serveur web démarré sur http://localhost:3001
2. Dashboard web ouvert dans le navigateur
3. Son activé dans le navigateur
4. Fichiers audio créés dans `public/assets/`

## 🧪 Test Simple

### Étape 1: Vérifier les fichiers audio
```bash
ls -la public/assets/
# Vous devriez voir:
# - notification.mp3
# - appointment.mp3
```

### Étape 2: Ouvrir le dashboard web
1. Allez sur http://localhost:3001
2. Connectez-vous avec votre compte clinic
3. Assurez-vous que le son est activé (icône 🔊 dans le header)

### Étape 3: Tester le son manuellement
1. Cliquez sur le bouton de test (🔊) dans le header
2. Vous devriez entendre un son

### Étape 4: Ajouter un rendez-vous de test
```bash
node test-notification-sound.js
```

### Étape 5: Vérifier la notification
1. Le système devrait détecter le nouveau rendez-vous dans 10 secondes
2. Vous devriez entendre un son de notification
3. Une notification toast devrait apparaître

## 🔧 Dépannage

### Si vous n'entendez pas de son :
1. Vérifiez que le son est activé dans le navigateur
2. Cliquez quelque part sur la page pour activer l'audio
3. Vérifiez la console du navigateur pour les erreurs
4. Essayez le bouton de test manuel

### Si les notifications ne se déclenchent pas :
1. Vérifiez que le nom de l'hôpital dans le script correspond à votre clinic
2. Vérifiez les logs du serveur
3. Vérifiez la console du navigateur

## 📝 Logs à surveiller

### Console du navigateur :
- 🔔 Initializing notification service...
- 🔄 Starting appointment polling...
- 🔍 Checking for new appointments...
- 🔊 Attempting to play notification sound...

### Logs du serveur :
- === CLINIC APPOINTMENTS API ===
- Found X appointments for [Clinic Name] 