const serverless = require('serverless-http');
const path = require('path');

// Log current working directory and paths for debugging
console.log('Current working directory:', process.cwd());
console.log('Function directory:', __dirname);
console.log('Attempting to load server from:', path.resolve(__dirname, '../../server.js'));

let app;
try {
  app = require('../../server');
  console.log('✅ Server loaded successfully');
} catch (error) {
  console.error('❌ Failed to load server:', error);
  throw error;
}

// Create the handler for the main hospital dashboard
const handler = serverless(app);

// Export the handler
module.exports.handler = async (event, context) => {
  try {
    console.log('📍 Function called:', event.path, event.httpMethod);
    
    // Call the serverless handler
    const result = await handler(event, context);
    console.log('✅ Function executed successfully');
    return result;
  } catch (error) {
    console.error('❌ Netlify function error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ 
        error: 'Internal Server Error',
        message: error.message,
        stack: error.stack
      })
    };
  }
}; 