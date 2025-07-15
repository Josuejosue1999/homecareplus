const { initializeApp } = require("firebase/app");
const { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut } = require("firebase/auth");
const { getFirestore, doc, setDoc, getDoc, collection, query, where, orderBy, getDocs, updateDoc, addDoc, serverTimestamp, writeBatch, increment } = require("firebase/firestore");
const { getStorage, ref, uploadBytes, getDownloadURL } = require("firebase/storage");

// Configuration Firebase utilisant les variables d'environnement
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY || "AIzaSyDYaKiltvi2oUAUO_mi4YNtqCpbJ3RbJI8",
  authDomain: process.env.FIREBASE_AUTH_DOMAIN || "homecare-9f4d0.firebaseapp.com",
  projectId: process.env.FIREBASE_PROJECT_ID || "homecare-9f4d0",
  storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "homecare-9f4d0.firebasestorage.app",
  messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID || "54787084616",
  appId: process.env.FIREBASE_APP_ID || "1:54787084616:android:7892366bf2029a3908a37d"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

console.log('🔥 Firebase initialized successfully for Health Center Dashboard');
console.log('📦 Project ID:', firebaseConfig.projectId);

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
