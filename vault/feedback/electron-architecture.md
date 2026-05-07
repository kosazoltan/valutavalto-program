---
name: electron-architecture-principle
description: Az Electron csak lokális backend (SQLite, offline, nyomtatás) — a frontend-react a UI réteg mindkét platformon (web + Electron). Offline módban automatikusan lokális adatokra vált.
type: feedback
---

Az Electron alkalmazásban a frontend-react kódnak kell futnia, NEM külön penztar-client renderernek.

**Why:** A felhasználó (CEO) kifejezetten kérte: "Az elektronnak csak backendnek kéne lennie, hogy tudjon helyben tárolni. De az elektront a webes résznek kéne vezérelnie." A két külön frontend karbantarthatatlan és zavaró (más kinézet, más funkciók).

**Offline stratégia (2026-03-17):**
Az Electron rögzíti a weben történő MINDEN adatot és működést lokálisan (SQLite). Ha elmegy az internet, automatikusan lokál módra vált — a felhasználó ugyanúgy dolgozhat tovább a webes felületen, csak a háttérben a lokális adatokból dolgozik. Ha visszajön a net, visszaszinkronizál.

**How to apply:**
- Az Electron app a `frontend-react` buildjét szolgálja ki (nem a penztar-client src/-t)
- Az Electron main process = lokális backend: SQLite, sync engine, nyomtatás, kamera, szkenner
- A frontend-react IPC-n keresztül éri el az Electron lokális szolgáltatásokat
- Ugyanaz a kód fut a böngészőben ÉS az Electronban — az Electron-specifikus funkciók graceful degradation-nel működnek (ha nincs electronAPI, web módban fut)
- **Online mód:** API hívások a szerverre mennek + Electron háttérben SQLite-ba is ment mindent
- **Offline mód:** Ha a szerver nem elérhető → automatikusan átáll lokális SQLite-ra → a felhasználó észre sem veszi → ha visszajön a net, szinkronizál
