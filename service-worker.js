const CACHE_NAME = "tuition-manager-static-v9-colourful-reminders-backup";
const CORE = ["./", "./index.html", "./styles.css", "./app.js", "./manifest.webmanifest", "./app-icon.svg", "./app-icon-192.png", "./app-icon-512.png"];
self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE_NAME).then(cache => cache.addAll(CORE)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE_NAME).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", event => {
  const req = event.request;
  const url = new URL(req.url);
  if (req.method !== "GET" || url.origin !== self.location.origin) return;
  // HTML navigation is network-first so users receive updated app code when online.
  if (req.mode === "navigate") {
    event.respondWith(fetch(req).then(response => {
      if (response.ok) caches.open(CACHE_NAME).then(cache => cache.put("./index.html", response.clone()));
      return response;
    }).catch(() => caches.match("./index.html")));
    return;
  }
  event.respondWith(caches.match(req).then(cached => cached || fetch(req).then(response => {
    if (response.ok) { const copy = response.clone(); caches.open(CACHE_NAME).then(cache => cache.put(req, copy)); }
    return response;
  })));
});
