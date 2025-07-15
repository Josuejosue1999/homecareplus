const serverless = require('serverless-http');
const app = require('../../app');

const handler = serverless(app);

module.exports.handler = async (event, context) => {
  // Set CORS headers for all responses
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
  };

  // Handle preflight requests
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers: corsHeaders,
      body: ''
    };
  }

  try {
    const result = await handler(event, context);
    
    // Add CORS headers to all responses
    result.headers = {
      ...result.headers,
      ...corsHeaders
    };
    
    return result;
  } catch (error) {
    console.error('Netlify function error:', error);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ error: 'Internal Server Error' })
    };
  }
}; 