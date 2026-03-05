importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

// Скопируй значения из своего firebase_options.dart
firebase.initializeApp({

     apiKey: "AIzaSyDtaU-sAzzW-9flDsw4_NpXytiI1WgzIPk",
      authDomain: "aq-toi.firebaseapp.com",
      projectId: "aq-toi",
      storageBucket: "aq-toi.firebasestorage.app",
      messagingSenderId: "745460234210",
      appId: "1:745460234210:web:41af58acf1ad811fa86bbb",
      measurementId: "G-JMCNSK71E6"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification ?? {};
  if (title) {
    self.registration.showNotification(title, {
      body: body ?? "",
      icon: "/icons/Icon-192.png",
    });
  }
});