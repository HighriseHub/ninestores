'use strict';

const HHUB_CACHE_NAME = 'hhub-static-cache-v3'; // Incrementing version number

// Removed the dynamic endpoint '/hhub/dodcustordersdata'
const FILES_TO_CACHE = [
    '/offline.html',
    '/img/logo.png',
    '/img/intro-bg.jpg',
    '/img/badge.png',
    '/css/style.css',
    '/css/bootstrap.min.css',
    '/hhub/hhubcustloginv2',
    '/hhub/hhubvendloginv2'
];

// Install event: Pre-cache static assets
self.addEventListener('install', (evt) => {
    console.log('[ServiceWorker] Install: Beginning pre-caching.');
    evt.waitUntil(
        caches.open(HHUB_CACHE_NAME).then((cache) => {
            console.log('[ServiceWorker] Pre-caching offline resources complete.');
            return cache.addAll(FILES_TO_CACHE);
        })
    );
    // Forces the waiting service worker to become the active service worker immediately
    self.skipWaiting();
});

// Activate event: Clean up old caches
self.addEventListener('activate', (evt) => {
    console.log('[ServiceWorker] Activate: Cleaning up old caches.');
    evt.waitUntil(
        caches.keys().then((keyList) => {
            return Promise.all(keyList.map((key) => {
                // Delete caches that don't match the current cache name
                if (key !== HHUB_CACHE_NAME) {
                    console.log('[ServiceWorker] Removing old cache', key);
                    return caches.delete(key);
                }
            }));
        })
    );
    // Takes control of the clients associated with the Service Worker's scope
    self.clients.claim();
});

// Fetch event (REVISED: Cache-First Strategy)
self.addEventListener('fetch', (evt) => {
    // Only handle GET requests
    if (evt.request.method !== 'GET') {
        return;
    }

    // Use Cache-First strategy for all GET requests
    evt.respondWith(
        caches.match(evt.request).then((response) => {
            // 1. If asset is found in cache, return it immediately
            if (response) {
                console.log('[ServiceWorker] Cache-First: Serving from cache', evt.request.url);
                return response;
            }

            // 2. If not in cache, fetch it from the network
            return fetch(evt.request).catch((err) => {
                console.log('[ServiceWorker] Network Failed:', evt.request.url, err);

                // 3. Network fallback for navigation requests
                // If fetching fails AND the request is for a page navigation (HTML request),
                // serve the offline page.
                if (evt.request.mode === 'navigate') {
                    return caches.match('/offline.html');
                }
                
                // For other types of failed fetches (API, images, etc.), return the error.
                throw err;
            });
        })
    );
});

// Push event: Handle incoming push messages
self.addEventListener("push", function(event) {
    console.log("[Service Worker] Push Received");
    let data = {};
    if (event.data) {
        try {
            // Attempt to parse the incoming data as JSON
            data = event.data.json();
        } catch (e) {
            console.error("Push event data is not JSON:", e);
        }
    }
    const title = data.title || "New Notification";
    const message = data.message || "You have a new message.";
    // Ensure the click target defaults to a secure path
    const clickTarget = data.clickTarget || "/hhub/hhubvendloginv2";

    const options = {
        body: message,
        icon: "/img/logo.png",
        badge: "/img/badge.png",
        data: {
            url: clickTarget // Passed to the notificationclick handler
        }
    };

    event.waitUntil(
        self.registration.showNotification(title, options)
    );
});

// Notification click event: Handle user interaction with the notification
self.addEventListener('notificationclick', function(event) {
    console.log('[Service Worker] Notification click received');
    event.notification.close();

    const targetUrl = event.notification.data?.url || "/";

    event.waitUntil(
        clients.matchAll({ type: "window", includeUncontrolled: true }).then(function(clientList) {
            // Try to focus an existing window with the target URL
            for (const client of clientList) {
                if (client.url === targetUrl && 'focus' in client) {
                    return client.focus();
                }
            }
            // If no window is found, open a new one
            if (clients.openWindow) {
                return clients.openWindow(targetUrl);
            }
        })
    );
});

