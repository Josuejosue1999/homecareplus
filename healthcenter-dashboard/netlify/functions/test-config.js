exports.handler = async (event, context) => {
  const config = {
    FIREBASE_API_KEY: process.env.FIREBASE_API_KEY ? 'SET' : 'MISSING',
    FIREBASE_AUTH_DOMAIN: process.env.FIREBASE_AUTH_DOMAIN ? 'SET' : 'MISSING',
    FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID ? 'SET' : 'MISSING',
    FIREBASE_STORAGE_BUCKET: process.env.FIREBASE_STORAGE_BUCKET ? 'SET' : 'MISSING',
    FIREBASE_MESSAGING_SENDER_ID: process.env.FIREBASE_MESSAGING_SENDER_ID ? 'SET' : 'MISSING',
    FIREBASE_APP_ID: process.env.FIREBASE_APP_ID ? 'SET' : 'MISSING',
    NODE_ENV: process.env.NODE_ENV || 'undefined'
  };

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: 'Configuration Test',
      environment_variables: config,
      timestamp: new Date().toISOString()
    })
  };
}; 