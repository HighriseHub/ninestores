'use strict';

const HHUB_CACHE_NAME = 'hhub-static-cache-v2';

const FILES_TO_CACHE = [
    '/offline.html',
    '/img/logo.png',
    '/img/intro-bg.jpg',
    '/img/hhublogo.png',
    '/img/badge.png',
    '/css/style.css',
    '/css/bootstrap.min.css',
    '/hhub/customer-login.html',
    '/hhub/vendor-login.html',
    '/hhub/dodcustordersdata'
];

// Install event
self.addEventListener('install', (evt) => {
    console.log('[ServiceWorker] Install');
    evt.waitUntil(
        caches.open(HHUB_CACHE_NAME).then((cache) => {
            console.log('[ServiceWorker] Pre-caching offline resources');
            return cache.addAll(FILES_TO_CACHE);
        })
    );
    self.skipWaiting();
});

// Activate event
self.addEventListener('activate', (evt) => {
    console.log('[ServiceWorker] Activate');
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

// Fetch event
self.addEventListener('fetch', (evt) => {
    console.log('[ServiceWorker] Fetch', evt.request.url);

    if (evt.request.mode !== 'navigate') {
        return;
    }

    evt.respondWith(
        fetch(evt.request).catch(() => {
            return caches.open(HHUB_CACHE_NAME).then((cache) => {
                return cache.match('/offline.html');
            });
        })
    );
});

// Push event
self.addEventListener("push", function(event) {
    console.log("[Service Worker] Push Received");

    let data = {};
    if (event.data) {
        try {
            data = event.data.json();
        } catch (e) {
            console.error("Push event data is not JSON:", e);
        }
    }

    const title = data.title || "New Notification";
    const message = data.message || "You have a new message.";
    const clickTarget = data.clickTarget || "/hhub/vendor-dashboard.html";

    const options = {
        body: message,
        icon: "/img/hhublogo.png",
        badge: "/img/badge.png",
        data: {
            url: clickTarget
        }
    };

    event.waitUntil(
        self.registration.showNotification(title, options)
    );
});

// Notification click event
self.addEventListener('notificationclick', function(event) {
    console.log('[Service Worker] Notification click received');
    event.notification.close();

    const targetUrl = event.notification.data?.url || "/";

    event.waitUntil(
        clients.matchAll({ type: "window", includeUncontrolled: true }).then(function(clientList) {
            for (const client of clientList) {
                if (client.url === targetUrl && 'focus' in client) {
                    return client.focus();
                }
            }
            if (clients.openWindow) {
                return clients.openWindow(targetUrl);
            }
        })
    );
});
