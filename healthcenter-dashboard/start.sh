#!/bin/bash

# Script de démarrage rapide pour le Health Center Dashboard
# Usage: ./start.sh [dev|prod]

echo "🏥 Health Center Dashboard - Démarrage rapide"
echo "=============================================="

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    echo "❌ Node.js n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier la version de Node.js
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 14 ]; then
    echo "❌ Node.js version 14 ou supérieure requise. Version actuelle: $(node -v)"
    exit 1
fi

echo "✅ Node.js version: $(node -v)"

# Installer les dépendances si nécessaire
if [ ! -d "node_modules" ]; then
    echo "📦 Installation des dépendances..."
    npm install
fi

# Mode de démarrage
MODE=${1:-dev}

if [ "$MODE" = "prod" ]; then
    echo "🚀 Démarrage en mode production..."
    npm start
elif [ "$MODE" = "dev" ]; then
    echo "🔧 Démarrage en mode développement..."
    npm run dev
else
    echo "❌ Mode invalide. Utilisez 'dev' ou 'prod'"
    echo "Usage: ./start.sh [dev|prod]"
    exit 1
fi 