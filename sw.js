/* ==========================================================================
   CHILESHE INNOVATIONS MONEY LENDERS - Service Worker
   Makes the app installable and usable offline on GitHub Pages.
   ========================================================================== */
var VERSION = "chileshe-pwa-v1.5.2";
var CORE = [
  "./",
  "./index.html",
  "./manifest.json",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-maskable-512.png",
  "./icons/apple-touch-icon.png",
  "./icons/favicon-32.png"
];

self.addEventListener("install", function (event) {
  event.waitUntil(
    caches.open(VERSION).then(function (cache) {
      return cache.addAll(CORE).catch(function (err) {
        console.warn("Pre-cache partially failed:", err);
      });
    }).then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener("activate", function (event) {
  event.waitUntil(
    caches.keys().then(function (keys) {
      return Promise.all(
        keys.filter(function (k) { return k !== VERSION; })
            .map(function (k) { return caches.delete(k); })
      );
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener("fetch", function (event) {
  var req = event.request;
  if (req.method !== "GET") return;

  var url = new URL(req.url);
  // Never intercept other origins (WhatsApp, Google sync, etc.)
  if (url.origin !== self.location.origin) return;

  // App pages: network first, fall back to the cached app when offline
  if (req.mode === "navigate") {
    event.respondWith(
      fetch(req).catch(function () {
        return caches.match("./index.html").then(function (r) {
          return r || caches.match("./");
        });
      })
    );
    return;
  }

  // Static files: serve from cache, refresh in the background
  event.respondWith(
    caches.match(req).then(function (cached) {
      var network = fetch(req).then(function (res) {
        if (res && res.ok) {
          var copy = res.clone();
          caches.open(VERSION).then(function (c) { c.put(req, copy); });
        }
        return res;
      }).catch(function () { return cached; });
      return cached || network;
    })
  );
});

self.addEventListener("message", function (event) {
  if (event.data === "SKIP_WAITING") self.skipWaiting();
});
