
# 2026-04-01 Sprint 5 — Architekturalis javitas

## KRITIKUS SZABALY (Zoltan utasitasa)
- Valutavaltas kizarolag LOKALIS ELECTRON alkalmazasban tortenik
- excvaluta.com weben NINCS React SPA, NINCS valutevaltas, NINCS ertektar
- A szerver (Hetzner VPS) szerepe: API backend + jovobeli riportok/statisztikak/kimuatasok
- Az Electron app a backend API-n keresztul kommunikal a szerverrel

## Elvegzett javitas
- Nginx atirva: React SPA eltavolitva, egyszerű landing page
- API proxy megmaradt (Electron hasznatra)
- Regi config backup: /opt/valutavalto/valutavalto-nginx.bak.20260401
- Uj webroot: /opt/valutavalto/public-web/

## Kovetkezo lepesek
- Riport/statisztika oldal tervezese (web-only, NEM valutevaltas)
- Electron app fejlesztes a teljes penztari munkafolyamathoz
