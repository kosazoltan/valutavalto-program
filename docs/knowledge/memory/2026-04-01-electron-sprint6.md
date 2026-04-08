# 2026-04-01 — Electron Sprint 6: Helyi penztari alkalmazas

## Architektura (Zoltan kotelező utasitas 2026-04-01)
- Valutavaltas KIZAROLAG helyi Electron alkalmazasban tortenik
- excvaluta.com weben NINCS React SPA, NINCS valutavaltas, NINCS ertektar
- A szerver (Hetzner 95.216.191.162) szerepe: API backend + jovobeli riportok/statisztikak
- Az Electron app a backend API-n keresztul kommunikal a szerverrel
- excvaluta.com: CSAK landing page + /api/ reverse proxy

## Electron allapot (2026-04-01 15:55)
- Repo: `D:\repo\valutavalto-program\penztar-client`
- Version: 1.1.0 (`valuta-penztar`)
- Electron: 41.1.0 (binaris: `node_modules\electron\dist\electron.exe`, 212MB)
- Build: `npm run build` = PASS (main.js + preload.js + lib + serial-printer)
- Frontend: `D:\repo\valutavalto-program\frontend-react` — kozos UI (web + electron)
- Frontend build: PASS (675ms, 229KB index bundle)
- TSC: PASS mindketto (frontend-react + penztar-client)

## Fontos fajlok
- `electron/main.ts` — foablak, IPC handlerek, app protocol, security
- `electron/sync-engine.ts` — offline → online szinkronizacio (30s interval)
- `electron/sqlite.ts` — helyi SQLite DB (pending tranzakciok, config, cache)
- `electron/printer.ts` — bizonylat nyomtatas
- `electron/scanner.ts` — dokumentum szkenner
- `electron/camera.ts` — kamera kezelese
- `electron/preload.ts` — contextIsolation preload
- `.env` — `VITE_API_URL=https://excvaluta.com/api/v1` (Hetzner backend)

## API URL-ek
- ELAVULT Render: `https://valutavalto-api.onrender.com/api/v1` — TOROLVE client.ts-bol
- Uj prod: `https://excvaluta.com/api/v1` (Hetzner nginx proxy)
- Dev: `http://localhost:3000` (Vite dev server) + `http://localhost:8080/api/v1` (lokalis backend)
- Sync-engine fallback: `http://localhost:8080/api/v1` (SQLite `server_url` config felulirja)

## KÖTELEZŐ SZABÁLY: Verziószám minden buildnél
- Minden build KÖTELEZŐEN új verziószámot kap
- Rögzíteni kell a memóriában melyik verzió mit tartalmaz
- Így garantált, hogy nem régi/sérült fájlt indítunk

### Build napló
- v1.1.0 — korábbi (Electron 41, serialport benne, sérült)
- v1.2.0 — 2026-04-01 16:50 CET — Electron 33.3.1, serialport eltavolitva, tiszta build
- v1.3.0 — 2026-04-01 16:53 CET — ekezetmentes exe nev, DE dist/assets/ hianyzott az ASAR-bol!
- v1.4.0 — 2026-04-01 17:02 CET — FIX: build sorrend (electron elobb, copy:frontend utoljara)

## KÖTELEZŐ SZABÁLY (2026-04-01 Zoltán utasítás)
- **Nincs találgatás, nincs hallucináció**
- Az adott célfájlt MINDIG kiolvasod és ABBAN keresed a hibát
- Nem égetjük feleslegesen a tokeneket felesleges próbálkozásokkal
- Célirányosan MINDIG megkeressük a hiba valós gyökérokát
- Ez KÖTELEZŐ ÉRVÉNYŰ minden ágens számára

## KRITIKUS: Electron Bug #49034 — require('electron') Windows
- **Bug:** Electron 31+ on Windows: `require('electron')` resolveolja `node_modules/electron/index.js`-t
  ami a string patht exportalja (exe utvonal), NEM az Electron API-t.
- **Gyokerok:** Az Electron `c._load` interceptje NEM kapja el a `require('electron')` hivanyt
  ha a `node_modules/electron/index.js` fizikailag letezik a resolve path-ban.
- **Miert mukodik production-ben:** Az ASAR-ban NINCS `node_modules/electron`, igy a belso modul elsoseget kap.
- **Workaround (vite.config.ts):** Dev modban a vite onstart callback-ban:
  1. Masolja a build outputot egy temp `.dev-app` konyvtarba (node_modules/electron NELKUL!)
  2. `npx asar pack` paranccsal ASAR-t csinal belole
  3. Az ASAR-t a `node_modules/electron/dist/resources/app.asar`-ba teszi
  4. Inditja az `electron.exe`-t (ami automatikusan a `resources/app.asar`-bol tolt)
- **Electron verzio:** 33.3.1 (korabban Dependabot 41-re emelte → ugyanaz a bug)
- **serialport:** Eltavolitva a dependenciakbol (Electron 33 v8 header inkompatibilis MSVC-vel)
  Opcionalis: `try/catch` a printer.ts-ben

## Electron inditas modok
- DEV: `cd penztar-client && npm run dev` — ASAR workaround-dal indit (vite.config.ts)
- TELEPITETT: `C:\Program Files\valuta-penztar\` (electron-builder NSIS installer)
- TESZT build: `npm run package` (electron-builder --win)
- TILOS: `npx electron .` vagy `node dist-electron/main.js` — Electron bug #49034 miatt NEM mukodik

## Utolso sikeres futasok (logokbol)
- 2026-04-01 12:40 — telepitett mod (`C:\Program Files\valuta-penztar\`)
- 2026-03-28 08:29 — dev mod (`http://localhost:3000`)
- 2026-03-27 20:09 — telepitett mod (`C:\Program Files\Valutavalto Penztar\`)

## Korabbi telepito utvonalak
- `C:\Program Files\Valutavalto Penztar\` — regi nev
- `C:\Program Files\valuta-penztar\` — uj nev (04-01)

## UI kovetelmeny (Zoltan 2026-04-01)
- Egyszeru, atlathato, ergonomikus penztarosi interface
- NEM kartyak, NEM bonyolitas
- ~60 penztar, sok penztaros — dolgozoi es penztar torzsadatbazis
- A lenyeg: helybenfutas, helyi valutavaltas
- A backend kuldi az adatokat a szerverre (Hetzner → Neon DB)

## CashierTransactionPage
- 798 sor, legacy ELADAS.DLL + VASARLAS.DLL paritas
- Max 6 valutasor/bizonylat
- F2=Vetel, F3=Eladas, F5=Storno, F8=Arfolyam, F9=Kedvezmeny, Esc=Megse
- Tab/Enter navigacio sorok kozott
- Offline queue tamogatas (electronTransactions util)
- Customer AML panel (300k+ HUF = azonositas kotelezo)

## CashierMainMenu
- Legacy Unit47.pas — 9+9 menupont, 2 oldalas
- Szam billentyuvel valaszthato (1-9), nyilakkal lapozhato
- 1.oldal: VETEL, ELADAS, KONVERZIO, ATADAS, -, STORNO, ARFOLYAM, KESZLET, FORGALOM
- 2.oldal: NAPI ZARAS, BIZONYLATOK, TARSPENZTARAK, LISTAK, PENZTAROSOK, NAPI FORGALOM, REGI ZARAS, REGENERALAS, EGYEB

## Elvegzett valtozasok (2026-04-01 15:55)
- [x] Render URL → Hetzner URL csere (`client.ts`: `excvaluta.com/api/v1`)
- [x] penztar-client `.env`: `VITE_API_URL=https://excvaluta.com/api/v1`
- [x] Frontend build PASS
- [x] Electron build PASS (main.js + preload.js)
- [x] copy:frontend PASS (dist/ frissitve)

## KRITIKUS: Windows 11 Insider (26200.8116) Chromium Sandbox FAIL (2026-04-01 17:10)

### Tünetek
- MINDEN Electron verzió (33.3.1, 33.4.11, 41.x) azonnal kilép code 0-val (packaged) vagy code 1-vel (dev)
- A main.js SOHA NEM FUT LE — a debug fájl nem jön létre
- A régi telepített verzió (`C:\Program Files\valuta-penztar\`) IS code 0-val lép ki (korábban 12:40-kor MŰKÖDÖTT)
- Minimal Electron teszt app IS FAIL (code 1, main.js never ran)

### Gyökérok
- A **Chromium sandbox initialization** failel MIELŐTT a main.js betöltődne
- Windows 11 Insider Build 10.0.26200.8116 — valószínűleg friss Windows Update rontotta el
- Az `app.commandLine.appendSwitch('no-sandbox')` a main.ts-ben NEM ELÉG — a sandbox ELŐBB inicializálódik
- A packaged EXE NEM fogadja a `--no-sandbox` flag-et ("bad option")
- `ELECTRON_NO_SANDBOX=1` env var NEM hat

### Bizonyítékok
- `--no-sandbox` flag-gel a raw `electron.exe`-nek: a main.js LEFUT (debug fájl létrejön: "Electron started at...")
- DE a BrowserWindow create STILL FAIL (code 1) — a GPU sandbox is probléma
- A packaged app NEM tud `--no-sandbox`-t kapni → megkerülhetetlen

### Próbált verziók
- v1.2.0 (Electron 33.3.1) → code 0
- v1.3.0 (Electron 33.3.1, ékezettelen exe) → code 0
- v1.4.0 (Electron 33.3.1, fix build sorrend) → code 0
- v1.5.0 (Electron 33.4.11) → code 0
- v1.6.0 (Electron 33.4.11, no-sandbox + disable-gpu-sandbox a main.ts-ben) → code 0

### Jelenlegi állapot (17:10 CET)
- A kód és a build TELJESEN RENDBEN VAN — a gép sandbox kompatibilitása a blocker
- `penztar-client/package.json` verzió: 1.6.0, Electron: 33.4.11
- A `main.ts`-ben benne van a `no-sandbox` + `disable-gpu-sandbox` appendSwitch (de nem ér el)
- Installer: `release\Penztar-Setup-1.6.0.exe` — KÉSZ, de a sandbox bug miatt nem indul

### Lehetséges megoldások (ZOLTÁN DÖNTÉS KELL)
1. **Windows Update visszagörgetése** — ha tegnap/ma volt Insider update
2. **Electron 35+ próba** — újabb Chromium verzió, hátha kompatibilis
3. **NSIS wrapper** — az installer `.cmd` launcher-t hoz létre ami `electron.exe --no-sandbox`-dal indít
4. **Chromium `--no-sandbox` az EXE-be** — a packaged EXE resource-ába patchelni (hacky)
5. **Nem-Insider gépen tesztelés** — Borsinál/Kaszánál tesztelés, ott valószínűleg MŰKÖDIK

## Kovetkezo lepesek
- [ ] Zoltán döntése a sandbox workaround-ról
- [ ] Ha Insider-specifikus: Borsik/Kasza gépen tesztelni (normál Windows 11)
- [ ] Ha launcher kell: NSIS wrapper implementálás
- [ ] Login tesztelese a Hetzner backend ellen
- [ ] Tranzakcio kepernyok tesztelese (vetel/eladas)
- [ ] UI egyszerusites ha Zoltan keri
- [ ] Commit + pipeline (Eszter → Tamas → Bence)
