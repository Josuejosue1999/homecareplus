// Vercel API endpoint for the Express app
try {
  const app = require('../server');
  
  // Export as a Vercel function
  module.exports = (req, res) => {
    try {
      return app(req, res);
    } catch (error) {
      console.error('Error in Vercel function:', error);
      res.status(500).json({
        error: 'Function execution failed',
        message: error.message,
        stack: error.stack
      });
    }
  };
} catch (error) {
  console.error('Error loading server:', error);
  
  // Fallback function if server can't be loaded
  module.exports = (req, res) => {
    res.status(500).json({
      error: 'Server loading failed',
      message: error.message,
      stack: error.stack,
      note: 'Server could not be imported'
    });
  };
} 