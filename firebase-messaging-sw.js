importScripts('https://www.gstatic.com/firebasejs/12.5.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.5.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCNHfjgw5mcgg5d7NayRluVTXwHPlpoGWM",
  authDomain: "drive-test-a4f94.firebaseapp.com",
  projectId: "drive-test-a4f94",
  storageBucket: "drive-test-a4f94.firebasestorage.app",
  messagingSenderId: "640394192831",
  appId: "1:640394192831:web:2f7c45b3bae1a15f1a630a",
});

const messaging = firebase.messaging();
