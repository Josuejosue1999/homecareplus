const serverless = require('serverless-http');
const app = require('../../server');

// Create the handler for the main hospital dashboard
const handler = serverless(app);

// Export the handler
module.exports.handler = async (event, context) => {
  try {
    // Call the serverless handler
    const result = await handler(event, context);
    return result;
  } catch (error) {
    console.error('Netlify function error:', error);
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ 
        error: 'Internal Server Error',
        message: error.message 
      })
    };
  }
}; 