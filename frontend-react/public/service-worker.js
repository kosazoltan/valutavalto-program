// Valuta Pénztári Rendszer — minimális Service Worker (Sprint 5 PWA, v2.5.50+)
//
// Stratégia: network-first (mindig a friss verzióval próbálkozik), offline esetén
// cache fallback. NEM cache-eli a /api/* hívásokat — azok mindig friss adatot kérnek.
//
// Cél: a frontend asset-eket cache-eli (JS/CSS/img), hogy az alkalmazás nyitható
// legyen rossz hálózati körülmények között is. Tranzakció üzleti logika NEM
// megy offline (a backend kell hozzá).

const CACHE_NAME = 'valuta-v1'
const STATIC_ASSETS = [
  '/',
  '/favicon.svg',
  '/manifest.webmanifest'
]

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_ASSETS))
  )
  self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n)))
    )
  )
  self.clients.claim()
})

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url)

  // API hívások — soha NE cache-eljük (tranzakciók, friss állapot)
  if (url.pathname.startsWith('/api/')) {
    return
  }

  // Auth/security érzékeny végpontok — soha
  if (url.pathname.includes('/auth/') || url.pathname.includes('/login')) {
    return
  }

  // Csak GET-eket cache-elünk
  if (event.request.method !== 'GET') {
    return
  }

  // Network-first
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Csak sikeres válaszok kerülnek cache-be
        if (response.ok && response.type === 'basic') {
          const responseClone = response.clone()
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone))
        }
        return response
      })
      .catch(() => caches.match(event.request).then((cached) => cached || new Response('Offline', {
        status: 503,
        headers: { 'Content-Type': 'text/plain;charset=utf-8' }
      })))
  )
})
