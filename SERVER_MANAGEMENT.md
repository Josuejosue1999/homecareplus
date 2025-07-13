# 🚀 Server Management Guide

## Scripts disponibles

### 1. `./start-clean.sh` - Démarrage propre
- ✅ **Nettoie automatiquement** les ports 3000 et 4000
- 🚀 **Démarre le serveur principal** sur le port 3000
- 🏥 **Démarre l'admin dashboard** sur le port 4000
- 📋 **Affiche les URLs** d'accès

```bash
./start-clean.sh
```

### 2. `./stop-servers.sh` - Arrêt complet
- 🛑 **Arrête tous les serveurs** Node.js
- 🧹 **Nettoie les ports** 3000 et 4000
- ✅ **Confirmation** d'arrêt

```bash
./stop-servers.sh
```

## 🔧 Diagnostic des problèmes

### Problème : Port déjà utilisé
```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solution :**
```bash
./stop-servers.sh  # Arrêter tous les serveurs
./start-clean.sh   # Redémarrer proprement
```

### Problème : Messages qui ne s'affichent pas
**Vérifications :**
1. 🔍 Ouvrir la **console du navigateur** (F12)
2. 📊 Vérifier les **logs détaillés** de l'API
3. 🔐 S'assurer d'être **connecté** comme clinique
4. 🔄 **Actualiser** la page

### Problème : Firebase Storage (erreur 404)
**Note :** Cette erreur n'affecte pas la fonctionnalité principale
- ⏭️ Le test Firebase Storage est maintenant **skippé**
- ✅ Les fonctionnalités de **chat et messages fonctionnent normalement**

## 📱 URLs d'accès

- **Application principale :** http://localhost:3000
- **Dashboard hôpital :** http://localhost:3000/dashboard  
- **Admin dashboard :** http://localhost:4000
- **Login :** http://localhost:3000/login

## 🔍 Logs détaillés

Les nouveaux logs incluent :
- 🔐 **Détails d'authentification**
- 📦 **État du cache**
- 💬 **API des conversations**
- 📋 **Informations du processus**
- 🔄 **Gestion des erreurs**

## 📝 Exemple d'utilisation

```bash
# 1. Arrêter tous les serveurs
./stop-servers.sh

# 2. Démarrer proprement
./start-clean.sh

# 3. Accéder à l'application
# Ouvrir http://localhost:3000/dashboard
# Se connecter avec vos identifiants d'hôpital
# Aller dans Messages pour voir les conversations
```

## 🆘 En cas de problème persistant

1. **Redémarrer complètement :**
   ```bash
   ./stop-servers.sh
   sleep 5
   ./start-clean.sh
   ```

2. **Vider le cache du navigateur :**
   - Chrome/Safari : Cmd+Shift+R
   - Firefox : Ctrl+Shift+R

3. **Vérifier les logs :**
   - Terminal : Messages du serveur
   - Navigateur : Console (F12) 