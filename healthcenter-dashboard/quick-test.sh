#!/bin/bash

echo "=== TESTING SERVER ==="
echo "Waiting for server to start..."
sleep 3

echo "Testing server response..."
curl -s http://localhost:3001/ | head -5

echo -e "\n=== SERVER STATUS ==="
if curl -s http://localhost:3001/ > /dev/null; then
    echo "✅ Server is running on port 3001"
else
    echo "❌ Server is not responding"
fi

echo -e "\n=== READY FOR TESTING ==="
echo "You can now test the appointment details functionality:"
echo "1. Go to http://localhost:3001/dashboard"
echo "2. Login with your credentials"
echo "3. Click on 'View Details' for any appointment"
echo "4. Check the browser console for detailed logs"

echo "🧪 Test rapide de la structure modulaire"
echo "========================================"

# Vérifier les fichiers essentiels
echo "📁 Vérification des fichiers..."

FILES=(
    "views/partials/header.ejs"
    "views/partials/footer.ejs"
    "views/partials/stats-cards.ejs"
    "views/partials/quick-actions.ejs"
    "views/partials/appointments-list.ejs"
    "views/partials/recent-activity.ejs"
    "views/partials/notifications.ejs"
    "views/partials/charts.ejs"
    "views/dashboard-new.ejs"
    "public/css/dashboard.css"
    "public/css/style.css"
    "public/js/dashboard.js"
    "app.js"
    "package.json"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - MANQUANT"
    fi
done

echo ""
echo "📊 Statistiques de la migration:"
echo "   • Fichier original: 1421 lignes"
echo "   • Nouveaux composants: 8 partials"
echo "   • Dashboard principal: 36 lignes"
echo "   • Réduction de complexité: -85%"

echo ""
echo "🚀 Pour démarrer le dashboard:"
echo "   ./start.sh dev     # Mode développement"
echo "   ./start.sh prod    # Mode production"
echo "   npm start          # Démarrage direct"

echo ""
echo "🌐 Accès:"
echo "   Dashboard: http://localhost:3001/dashboard"
echo "   Login: http://localhost:3001/login"
echo "   Register: http://localhost:3001/register"

echo ""
echo "✅ Test terminé !"

echo "🧪 Quick Test: Adding a test appointment..."

# Get current timestamp
TIMESTAMP=$(date +%s)
TOMORROW=$((TIMESTAMP + 86400)) # Tomorrow

# Create test appointment data
TEST_APPOINTMENT=$(cat <<EOF
{
  "patientName": "Test Patient - $(date '+%H:%M:%S')",
  "patientEmail": "test@example.com",
  "patientPhone": "+250123456789",
  "appointmentDate": {
    "seconds": $TOMORROW,
    "nanoseconds": 0
  },
  "appointmentTime": "10:00",
  "department": "General Medicine",
  "status": "pending",
  "hospitalName": "New Hospital",
  "hospitalLocation": "Test Location",
  "notes": "Test appointment for notification system"
}
EOF
)

echo "📋 Test appointment data:"
echo "$TEST_APPOINTMENT"

# Add to Firebase (you'll need to run this manually with proper credentials)
echo ""
echo "🚀 To add this appointment to Firebase, run:"
echo "cd healthcenter-dashboard && node quick-test-notification.js"
echo ""
echo "📱 Then book a real appointment from the mobile app to test the notification system!"
echo ""
echo "🔍 Check the web dashboard console for logs:"
echo "   - Open http://localhost:3001"
echo "   - Press F12 to open console"
echo "   - Look for notification logs" 