const { initializeApp } = require("firebase/app");
const { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut } = require("firebase/auth");
const { getFirestore, doc, setDoc, getDoc, collection, query, where, orderBy, getDocs, updateDoc, addDoc, serverTimestamp, writeBatch, increment } = require("firebase/firestore");
const { getStorage, ref, uploadBytes, getDownloadURL } = require("firebase/storage");

console.log("🔥 Firebase Config - Loading environment variables...");
console.log("📋 Environment check:", {
  NODE_ENV: process.env.NODE_ENV,
  FIREBASE_API_KEY: process.env.FIREBASE_API_KEY ? `${process.env.FIREBASE_API_KEY.substring(0, 10)}...` : 'NOT SET',
  FIREBASE_AUTH_DOMAIN: process.env.FIREBASE_AUTH_DOMAIN || 'NOT SET',
  FIREBASE_PROJECT_ID: process.env.FIREBASE_PROJECT_ID || 'NOT SET',
  FIREBASE_STORAGE_BUCKET: process.env.FIREBASE_STORAGE_BUCKET || 'NOT SET',
  FIREBASE_MESSAGING_SENDER_ID: process.env.FIREBASE_MESSAGING_SENDER_ID || 'NOT SET',
  FIREBASE_APP_ID: process.env.FIREBASE_APP_ID ? `${process.env.FIREBASE_APP_ID.substring(0, 15)}...` : 'NOT SET'
});

// Configuration Firebase - Using environment variables for production
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY || "AIzaSyBWnaj_7qrK9pSBSI2sKSnFVLkyskhcZog",
  authDomain: process.env.FIREBASE_AUTH_DOMAIN || "homecare-9f4d0.firebaseapp.com",
  projectId: process.env.FIREBASE_PROJECT_ID || "homecare-9f4d0",
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "homecare-9f4d0.firebasestorage.app",
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || "54787084616",
  appId: process.env.FIREBASE_APP_ID || "1:54787084616:web:2fe62181a935fefc08a37d"
};

console.log('🔥 Firebase Config Final:', {
  apiKey: firebaseConfig.apiKey ? `${firebaseConfig.apiKey.substring(0, 10)}...` : 'missing',
  authDomain: firebaseConfig.authDomain,
  projectId: firebaseConfig.projectId,
  storageBucket: firebaseConfig.storageBucket,
  messagingSenderId: firebaseConfig.messagingSenderId,
  appId: firebaseConfig.appId ? `${firebaseConfig.appId.substring(0, 15)}...` : 'missing'
});

// Vérifier que tous les champs sont présents
const requiredFields = ['apiKey', 'authDomain', 'projectId', 'storageBucket', 'messagingSenderId', 'appId'];
const missingFields = requiredFields.filter(field => !firebaseConfig[field] || firebaseConfig[field] === 'NOT SET');

if (missingFields.length > 0) {
  console.error("❌ Firebase Config - Missing required fields:", missingFields);
  console.error("🚨 This will cause authentication failures!");
} else {
  console.log("✅ Firebase Config - All required fields present");
}

// Initialize Firebase
console.log("🚀 Initializing Firebase app...");
let app, auth, db, storage;

try {
  app = initializeApp(firebaseConfig);
  console.log("✅ Firebase app initialized successfully");
  
  auth = getAuth(app);
  console.log("✅ Firebase Auth initialized successfully");
  
  db = getFirestore(app);
  console.log("✅ Firestore initialized successfully");
  
  storage = getStorage(app);
  console.log("✅ Firebase Storage initialized successfully");
  
  console.log("🎉 All Firebase services ready!");
  
} catch (error) {
  console.error("❌ Firebase initialization failed:", {
    message: error.message,
    code: error.code,
    stack: error.stack
  });
  throw error;
}

module.exports = {
  auth,
  db,
  storage,
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  doc,
  setDoc,
  getDoc,
  collection,
  query,
  where,
  orderBy,
  getDocs,
  updateDoc,
  addDoc,
  serverTimestamp,
  writeBatch,
  increment,
  ref,
  uploadBytes,
  getDownloadURL
};
