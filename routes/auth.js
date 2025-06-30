const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
    try {
        admin.initializeApp({
            credential: admin.credential.applicationDefault(),
            // You can also use service account key file:
            // credential: admin.credential.cert(require('../config/serviceAccountKey.json')),
        });
    } catch (error) {
        console.error('Firebase Admin initialization error:', error);
    }
}

// Login route
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Validate input
        if (!email || !password) {
            return res.status(400).json({
                error: 'Email and password are required'
            });
        }

        // For now, we'll use a simple authentication check
        // In production, you should use Firebase Auth or your own authentication system
        console.log('Login attempt:', { email, password });

        // Mock authentication - replace with real Firebase Auth
        // This is just for demonstration purposes
        if (email === 'admin@healthcenter.com' && password === 'admin123') {
            // Generate a simple token (in production, use JWT)
            const token = Buffer.from(`${email}:${Date.now()}`).toString('base64');
            
            return res.json({
                success: true,
                message: 'Login successful',
                token: token,
                user: {
                    email: email,
                    role: 'admin',
                    name: 'Health Center Admin'
                }
            });
        } else {
            return res.status(401).json({
                error: 'Invalid email or password'
            });
        }

    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
});

// Logout route
router.post('/logout', (req, res) => {
    try {
        // In a real application, you would invalidate the token
        res.json({
            success: true,
            message: 'Logout successful'
        });
    } catch (error) {
        console.error('Logout error:', error);
        res.status(500).json({
            error: 'Internal server error'
        });
    }
});

// Verify token middleware (for protected routes)
const verifyToken = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(' ')[1];
        
        if (!token) {
            return res.status(401).json({
                error: 'Access token required'
            });
        }

        // In production, verify the JWT token
        // For now, we'll just check if token exists
        req.user = { email: 'admin@healthcenter.com' }; // Mock user
        next();
    } catch (error) {
        console.error('Token verification error:', error);
        res.status(401).json({
            error: 'Invalid token'
        });
    }
};

// Protected route example
router.get('/profile', verifyToken, (req, res) => {
    res.json({
        user: req.user
    });
});

module.exports = router; 