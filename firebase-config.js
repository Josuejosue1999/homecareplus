// Configuration Firebase centralisée pour éviter les duplications
const { initializeApp, getApps } = require('firebase/app');
const { getAuth } = require('firebase/auth');
const { getFirestore } = require('firebase/firestore');
const { getStorage } = require('firebase/storage');

// Configuration Firebase
const firebaseConfig = {
  apiKey: "AIzaSyA1g-UDJcfQS_33U3Sysxe9g4zlAOnpS3g",
  authDomain: "homecare-9f4d0.firebaseapp.com",
  projectId: "homecare-9f4d0",
  storageBucket: "homecare-9f4d0.appspot.com",
  messagingSenderId: "1092550453140",
  appId: "1:1092550453140:web:12345abcdef67890"
};

// Initialiser Firebase seulement si pas déjà initialisé
let app;
if (getApps().length === 0) {
  app = initializeApp(firebaseConfig);
  console.log('🔥 Firebase initialized successfully');
} else {
  app = getApps()[0];
  console.log('🔄 Using existing Firebase app');
}

// Exporter les services Firebase
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

module.exports = {
  app,
  auth,
  db,
  storage,
  // Réexporter les fonctions Firebase nécessaires
  signInWithEmailAndPassword: require('firebase/auth').signInWithEmailAndPassword,
  createUserWithEmailAndPassword: require('firebase/auth').createUserWithEmailAndPassword,
  signOut: require('firebase/auth').signOut,
  doc: require('firebase/firestore').doc,
  getDoc: require('firebase/firestore').getDoc,
  setDoc: require('firebase/firestore').setDoc,
  collection: require('firebase/firestore').collection,
  query: require('firebase/firestore').query,
  where: require('firebase/firestore').where,
  orderBy: require('firebase/firestore').orderBy,
  getDocs: require('firebase/firestore').getDocs,
  updateDoc: require('firebase/firestore').updateDoc,
  addDoc: require('firebase/firestore').addDoc,
  deleteDoc: require('firebase/firestore').deleteDoc,
  serverTimestamp: require('firebase/firestore').serverTimestamp,
  writeBatch: require('firebase/firestore').writeBatch,
  increment: require('firebase/firestore').increment,
  ref: require('firebase/storage').ref,
  uploadBytes: require('firebase/storage').uploadBytes,
  getDownloadURL: require('firebase/storage').getDownloadURL,
  deleteObject: require('firebase/storage').deleteObject
}; 