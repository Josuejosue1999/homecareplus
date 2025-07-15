// Simple test function for Vercel
module.exports = (req, res) => {
  res.json({
    message: "Vercel function is working! 🎉",
    timestamp: new Date().toISOString(),
    url: req.url,
    method: req.method
  });
}; 