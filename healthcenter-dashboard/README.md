# Health Center Dashboard

Un dashboard web moderne pour la gestion des centres de santé, avec système de notifications en temps réel.

## 🚀 Fonctionnalités

### 📊 Dashboard Principal
- Vue d'ensemble des statistiques
- Rendez-vous à venir
- Graphiques et métriques
- Interface responsive

### 📅 Gestion des Rendez-vous
- Affichage des rendez-vous en temps réel
- Détails complets des rendez-vous
- Approuver/Rejeter les rendez-vous
- Filtrage par statut

### 🔔 Système de Notifications
- **Notifications sonores** quand un patient réserve un rendez-vous
- **Notifications visuelles** avec toast messages
- **Animation de la cloche** de notification
- **Contrôle du son** (activer/désactiver)
- **Monitoring en temps réel** (vérification toutes les 10 secondes)

### ⚙️ Paramètres
- Gestion du profil de la clinique
- Configuration des services
- Horaires de travail
- Documents et certificats

## 🎵 Notifications Sonores

Le système de notifications inclut :

1. **Son de notification général** (`notification.mp3`)
2. **Son spécifique aux rendez-vous** (`appointment.mp3`)
3. **Contrôle du son** via le bouton flottant
4. **Préférences sauvegardées** dans le navigateur

### Comment ça fonctionne :
- Le dashboard vérifie les nouveaux rendez-vous toutes les 10 secondes
- Si un rendez-vous a été créé dans les 2 dernières minutes, une notification est déclenchée
- Le son joue automatiquement (si activé)
- Une notification toast apparaît avec les détails du rendez-vous

## 🛠️ Installation

1. **Cloner le projet**
```bash
git clone <repository-url>
cd healthcenter-dashboard
```

2. **Installer les dépendances**
```bash
npm install
```

3. **Configurer Firebase**
- Copier vos clés Firebase dans `config/firebase.js`
- Remplacer les clés de test par vos vraies clés

4. **Ajouter les fichiers audio**
- Remplacer `public/assets/notification.mp3` par un vrai fichier audio
- Remplacer `public/assets/appointment.mp3` par un vrai fichier audio

5. **Démarrer le serveur**
```bash
npm start
```

## 🧪 Tests

### Tester les notifications manuellement :
```bash
# Créer un rendez-vous de test
node test-notifications.js

# Créer plusieurs rendez-vous de test
node test-notifications.js 5
```

### Tester depuis le navigateur :
```javascript
// Dans la console du navigateur
window.notificationService.testNotification()
```

## 📱 Utilisation

### Pour les Centres de Santé :
1. Se connecter au dashboard
2. Les notifications apparaîtront automatiquement
3. Cliquer sur la cloche pour voir l'historique
4. Utiliser le bouton de contrôle du son pour activer/désactiver

### Pour les Patients :
1. Réserver un rendez-vous depuis l'app mobile
2. Le centre de santé recevra automatiquement une notification
3. Le centre peut approuver/rejeter le rendez-vous

## 🔧 Configuration

### Personnaliser les sons :
- Remplacer `public/assets/notification.mp3` pour les notifications générales
- Remplacer `public/assets/appointment.mp3` pour les rendez-vous

### Ajuster les intervalles :
- Modifier `checkInterval` dans `notification-service.js` (actuellement 10 secondes)
- Modifier la fenêtre de détection (actuellement 2 minutes)

## 🎨 Personnalisation

### Styles CSS :
- Modifier `public/css/dashboard-styles.css` pour les animations
- Ajuster les couleurs et effets dans la section `.notification-toast`

### Comportement JavaScript :
- Modifier `public/js/notification-service.js` pour le comportement
- Ajuster les messages et la logique de détection

## 📊 API Endpoints

- `GET /api/appointments/clinic-appointments` - Rendez-vous de la clinique
- `GET /api/appointments/:id` - Détails d'un rendez-vous
- `POST /api/appointments/:id/approve` - Approuver un rendez-vous
- `POST /api/appointments/:id/decline` - Rejeter un rendez-vous
- `GET /api/test-notification` - Tester les notifications
- `GET /api/notifications/stats` - Statistiques des notifications

## 🔒 Sécurité

- Authentification requise pour toutes les routes API
- Validation des données côté serveur
- Protection CSRF
- Gestion sécurisée des sessions

## 🚀 Déploiement

1. **Variables d'environnement**
```bash
NODE_ENV=production
PORT=3001
```

2. **Build et déploiement**
```bash
npm run build
npm start
```

## 📞 Support

Pour toute question ou problème :
- Vérifier les logs du serveur
- Tester les notifications avec `node test-notifications.js`
- Vérifier que les fichiers audio sont présents
- S'assurer que le son n'est pas désactivé dans le navigateur

---

**Note :** N'oubliez pas de remplacer les fichiers audio de test par de vrais fichiers audio pour une meilleure expérience utilisateur. 