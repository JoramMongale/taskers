importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
// Replace with your Firebase config
firebase.initializeApp({
apiKey: "AIzaSyD_h6i0poheiujW_jsRGBy5I7QUffLetoM",
  authDomain: "taskers---connect.firebaseapp.com",
  projectId: "taskers---connect",
  storageBucket: "taskers---connect.firebasestorage.app",
  messagingSenderId: "767941023108",
  appId: "1:767941023108:web:4dc9ed9ce4ec67019cb9d1",
  measurementId: "G-Z0F2P565ET"
});

// Retrieve firebase messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage(function(payload) {
  console.log('Received background message ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/icon-192.png',
    badge: '/icons/icon-72.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
