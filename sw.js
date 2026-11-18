// Khedar48 service worker: makes the app installable and opens fast.
// Pages and config are network-first (always fresh when online); photos and icons are cache-first.
const CACHE = "k48-v44";
const SHELL = ["./", "index.html", "manifest.webmanifest", "icons/icon-192.png", "icons/icon-512.png", "img/hero.jpg"];

self.addEventListener("install", e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});
self.addEventListener("activate", e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener("fetch", e => {
  const url = new URL(e.request.url);
  if (e.request.method !== "GET" || url.origin !== location.origin) return; // Firebase traffic goes straight to the network
  const isAsset = /\/(img|icons)\//.test(url.pathname);
  if (isAsset) {
    e.respondWith(caches.match(e.request).then(r => r || fetch(e.request).then(res => {
      const copy = res.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); return res;
    })));
  } else {
    e.respondWith(fetch(e.request).then(res => {
      const copy = res.clone(); caches.open(CACHE).then(c => c.put(e.request, copy)); return res;
    }).catch(() => caches.match(e.request).then(r => r || caches.match("index.html"))));
  }
});

// push notifications (new orders for the admin, assignments for drivers), sent by the Supabase function "notify"
self.addEventListener("push", e => {
  let d = {};
  try { d = e.data ? e.data.json() : {}; } catch (x) { d = { body: e.data ? e.data.text() : "" }; }
  e.waitUntil(Promise.all([
    self.registration.showNotification(d.title || "Khedar48", {
      body: d.body || "", icon: "icons/icon-192.png", badge: "icons/badge-96.png", lang: d.lang || "fr", dir: d.dir || "auto",
      tag: d.tag || "k48", renotify: true, requireInteraction: !!d.sticky, timestamp: Date.now(),
      vibrate: [180, 80, 180, 80, 320], data: { url: d.url || "/" }
    }),
    // an open app plays its "ka-ching" sound
    clients.matchAll({ type: "window", includeUncontrolled: true }).then(ws => ws.forEach(w => w.postMessage({ type: "k48-push" })))
  ]));
});
self.addEventListener("notificationclick", e => {
  e.notification.close();
  const url = new URL((e.notification.data && e.notification.data.url) || "/", self.location.origin).href;
  e.waitUntil(clients.matchAll({ type: "window", includeUncontrolled: true }).then(ws => {
    for (const w of ws) if (new URL(w.url).pathname === new URL(url).pathname && "focus" in w) return w.focus();
    return clients.openWindow(url);
  }));
});
