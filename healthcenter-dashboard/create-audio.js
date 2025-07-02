const fs = require('fs');
const path = require('path');

// Créer un fichier audio MP3 simple (base64 encodé)
const audioBase64 = `//uQxAAAAAAAAAAAAAAAAAAAAAAAWGluZwAAAA8AAAAFAAAGUABISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhI//////////////////////////////////////////////////////////////////8AAAAATGF2YzU4LjI5LjEwMAAAAAAAAAAAAAAA//tQxAAAAAAAAAAAAAAAAAAAAAABJbmZvAAAADwAAAAUAAAZQAEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhI//////////////////////////////////////////////////////////////////8AAAAATGF2YzU4LjI5LjEwMAAAAAAAAAAAAAAA//tQxAAAAAAAAAAAAAAAAAAAAAABJbmZvAAAADwAAAAUAAAZQAEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhISEhI//////////////////////////////////////////////////////////////////8AAAAATGF2YzU4LjI5LjEwMAAAAAAAAAAAAAAA`;

// Convertir base64 en buffer
const audioBuffer = Buffer.from(audioBase64, 'base64');

// Créer le dossier assets s'il n'existe pas
const assetsDir = path.join(__dirname, 'public', 'assets');
if (!fs.existsSync(assetsDir)) {
    fs.mkdirSync(assetsDir, { recursive: true });
}

// Écrire le fichier audio
const audioPath = path.join(assetsDir, 'notification.mp3');
fs.writeFileSync(audioPath, audioBuffer);

console.log('✅ Fichier audio créé:', audioPath);
console.log('📁 Taille du fichier:', fs.statSync(audioPath).size, 'bytes'); 