'use strict';


const HHUB_CACHE_NAME = 'hhub-static-cache-v2';

// CODELAB: Add list of files to cache here.
const FILES_TO_CACHE = [
    '/offline.html',
    '/img/logo.png', 
    '/hhub/customer-login.html',
    '/hhub/vendor-login.html',
    '/img/intro-bg.jpg',
    '/css/style.css',
    '/css/bootstrap.min.css',
    '/hhub/dodcustordersdata'
];

self.addEventListener('install', (evt) => {
  console.log('[ServiceWorker] Install');
  // CODELAB: Precache static resources here.
    evt.waitUntil(
	caches.open(HHUB_CACHE_NAME).then((cache) => {
	    console.log('[ServiceWorker] Pre-caching offline page');
	    return cache.addAll(FILES_TO_CACHE);
	})
    );
    self.skipWaiting();
});

self.addEventListener('activate', (evt) => {
  console.log('[ServiceWorker] Activate');
  // CODELAB: Remove previous cached data from disk.
    evt.waitUntil(
	caches.keys().then((keyList) => {
	    return Promise.all(keyList.map((key) => {
		if (key !== HHUB_CACHE_NAME) {
		    console.log('[ServiceWorker] Removing old cache', key);
		    return caches.delete(key);
		}
	    }));
	})
    );
    self.clients.claim();
});

self.addEventListener('fetch', (evt) => {
  console.log('[ServiceWorker] Fetch', evt.request.url);
  // CODELAB: Add fetch event handler here.
if (evt.request.mode !== 'navigate') {
  // Not a page navigation, bail.
  return;
}
evt.respondWith(
    fetch(evt.request)
        .catch(() => {
          return caches.open(HHUB_CACHE_NAME)
              .then((cache) => {
                return cache.match('offline.html');
              });
        })
);

});



self.addEventListener("push", function(event) {
    console.log("[Service Worker] Push Received.");
    console.log(`[Service Worker] Push had this data: "${event.data.text()}"`);

    var data = {};
    if (event.data) {
	data = event.data.json();
    }

    var title = data.title;
    var message = data.message;
    var icon = "img/FM_logo_2013.png";

    //const title = "Push Codelab";
    const options = {
	body: message,
	icon: "img/hhublogo.png",
	badge: "images/badge.png"
    };
    self.clickTarget = data.clickTarget;

    event.waitUntil(self.registration.showNotification(title, options));
});


self.addEventListener('notificationclick', function(event) {
    console.log('[Service Worker] Notification click Received.');

    event.notification.close();

    if(clients.openWindow){
	event.waitUntil(clients.openWindow(self.clickTarget));
    }
});
