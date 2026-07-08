// Valuta Pénztári Rendszer — minimális Service Worker (Sprint 5 PWA, v2.5.50+)
//
// Network-first cache stratégia + restrictive cache filter.
// A 2026-05-13-i Codex P1 + Sourcery security + Copilot review-k alapján kijavítva:
// - precache list NEM tartalmaz hiányzó assetet (P1)
// - /login NEM auth — SPA shell route, ezt cache-eljük (Copilot)
// - cache filter restrictive: csak static asset extensions (Sourcery security)
// - offline navigate fallback a cached '/' shellre (Sourcery + Copilot)
// - cache.put waitUntil-ba (Copilot)
//
// FIGYELMEZTETÉS: tranzakciós üzleti adat NEM offline-képes; a backend kell hozzá.

const CACHE_NAME = 'valuta-v2-pwa'
const SHELL_URL = '/'
// Csak ami biztosan létezik a build-ben. /favicon.svg NEM precache-elve, mert nincs ott.
const STATIC_ASSETS = [SHELL_URL, '/manifest.webmanifest']

// Cache-elhető fájltípusok — engedélyezett extension lista
const CACHEABLE_EXTENSIONS = new Set([
  '.js',
  '.css',
  '.svg',
  '.png',
  '.jpg',
  '.jpeg',
  '.webp',
  '.gif',
  '.ico',
  '.woff',
  '.woff2',
  '.ttf',
  '.eot',
])

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) =>
      // addAll(SHELL+manifest) — ha bármi nem érhető el, az SW install fail-elne;
      // a STATIC_ASSETS most tisztított, így biztonságos.
      cache.addAll(STATIC_ASSETS),
    ),
  )
  self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((names) =>
        Promise.all(names.filter((n) => n !== CACHE_NAME).map((n) => caches.delete(n))),
      )
      .then(() => self.clients.claim()),
  )
})

function isCacheableStaticAsset(pathname) {
  if (pathname.startsWith('/assets/')) {
    return true
  }
  for (const ext of CACHEABLE_EXTENSIONS) {
    if (pathname.endsWith(ext)) {
      return true
    }
  }
  return false
}

self.addEventListener('fetch', (event) => {
  // Csak GET-eket kezeljük
  if (event.request.method !== 'GET') {
    return
  }

  const url = new URL(event.request.url)

  // 1. API hívás → soha NE cache (tranzakciók friss adatot igényelnek)
  if (url.pathname.startsWith('/api/')) {
    return
  }

  // 2. Tényleges auth endpoint — backend `/auth/*`. A `/login` SPA route, EZT cache-eljük!
  if (url.pathname.startsWith('/auth/')) {
    return
  }

  // 3. Navigációs kérés (SPA deep link) → network-first, offline esetén cached shell
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() =>
        caches.match(SHELL_URL).then(
          (cached) =>
            cached ||
            new Response('Offline', {
              status: 503,
              headers: { 'Content-Type': 'text/plain;charset=utf-8' },
            }),
        ),
      ),
    )
    return
  }

  // 4. Egyéb GET — csak ha cacheable static asset (security: nem cache-elünk
  //    cookie-függő/user-specific dinamikus content-et!)
  if (!isCacheableStaticAsset(url.pathname)) {
    return
  }

  // Network-first static asset-re
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Csak sikeres alap-válaszok kerülnek cache-be
        if (response.ok && response.type === 'basic') {
          const responseClone = response.clone()
          // waitUntil — az SW életciklusa biztosítja a cache.put befejezést
          event.waitUntil(
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseClone)),
          )
        }
        return response
      })
      .catch(() =>
        caches.match(event.request).then(
          (cached) =>
            cached ||
            new Response('Offline', {
              status: 503,
              headers: { 'Content-Type': 'text/plain;charset=utf-8' },
            }),
        ),
      ),
  )
})
