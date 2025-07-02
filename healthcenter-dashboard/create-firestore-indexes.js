const { exec } = require('child_process');

console.log('🔧 Creating required Firestore indexes...\n');

const indexes = [
  {
    name: 'chat_conversations index',
    url: 'https://console.firebase.google.com/v1/r/project/homecare-9f4d0/firestore/indexes?create_composite=Cllwcm9qZWN0cy9ob21lY2FyZS05ZjRkMC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvY2hhdF9jb252ZXJzYXRpb25zL2luZGV4ZXMvXxABGgwKCGNsaW5pY0lkEAEaEwoPbGFzdE1lc3NhZ2VUaW1lEAIaDAoIX19uYW1lX18QAg',
    description: 'Collection: chat_conversations\nFields: clinicId (ASC), lastMessageTime (DESC), __name__ (ASC)'
  },
  {
    name: 'chat_messages index',
    url: 'https://console.firebase.google.com/v1/r/project/homecare-9f4d0/firestore/indexes?create_composite=ClRwcm9qZWN0cy9ob21lY2FyZS05ZjRkMC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvY2hhdF9tZXNzYWdlcy9pbmRleGVzL18QARoSCg5jb252ZXJzYXRpb25JZBABGg0KCXRpbWVzdGFtcBACGgwKCF9fbmFtZV9fEAI',
    description: 'Collection: chat_messages\nFields: conversationId (ASC), timestamp (DESC), __name__ (ASC)'
  }
];

console.log('📝 Required indexes:');
indexes.forEach((index, i) => {
  console.log(`\n${i + 1}. ${index.name}`);
  console.log(`   ${index.description}`);
  console.log(`   URL: ${index.url}`);
});

console.log('\n🌐 Opening Firebase Console URLs...');

// Function to open URL in default browser
function openURL(url) {
  let command;
  switch (process.platform) {
    case 'darwin': // macOS
      command = `open "${url}"`;
      break;
    case 'win32': // Windows
      command = `start "" "${url}"`;
      break;
    default: // Linux and others
      command = `xdg-open "${url}"`;
  }
  
  exec(command, (error) => {
    if (error) {
      console.error(`❌ Error opening URL: ${error.message}`);
    }
  });
}

// Open URLs with a delay between them
indexes.forEach((index, i) => {
  setTimeout(() => {
    console.log(`🔗 Opening ${index.name}...`);
    openURL(index.url);
  }, i * 2000); // 2 second delay between each URL
});

console.log('\n⏳ Instructions:');
console.log('1. The Firebase Console will open in your browser');
console.log('2. For each index, click "Create Index" button');
console.log('3. Wait for indexes to build (usually takes a few minutes)');
console.log('4. The index status will show "Enabled" when ready');
console.log('\n🔄 After creating both indexes, restart the server:');
console.log('   npm start');

setTimeout(() => {
  console.log('\n✅ URLs opened! Check your browser to create the indexes.');
}, 5000); 