# TELEPÍTŐ RENDSZER-TRANSZFORMÁCIÓS AUDIT JELENTÉS (2026-05-24)

> **Verzió:** 2.26.40  
> **Státusz:** COMPLETED (Installer Security & Architecture Review)  
> **Kapcsolt folyamat:** Négy különálló kliens telepítőről három összevont telepítőre való áttérés  
> **Auditor AI:** Antigravity Senior Principal Security Architect & Installer Specialist  

---

## 1. A TELEPÍTŐK ÁTALAKÍTÁSÁNAK KONTEXTUSA

A valutaváltó program monorepójában nemrégiben nagy horderejű architektúrális döntés született: a korábbi **négy különálló telepítőcsomagot** (Pénztár, Értéktár, Árfolyamkészítő, Központi irányítás) **három összevont telepítőcsomagra** redukálta a fejlesztőcsapat:
1. **`penztar-client`**: Pénztár és Értéktár közös kliens (induláskori módválasztással és backend login szinkronnal).
2. **`rfm-keszito-client`**: Fix Árfolyamkészítő kliens (főértéktárosoknak).
3. **`kozponti-client`**: Összevont Központi Munkaállomás, amely egyetlen Electron héjban, induláskori grafikus mód-választóval szolgálja ki a **Központi Irányítóközpont** (full) és az **Árfolyamkészítő** (rate-maker) üzemmódokat.

Ez az összevonás komoly előnyökkel jár (egyszerűbb verziókezelés, kisebb telepítési méret, egységes build pipeline), ugyanakkor **számos súlyos inkonzisztenciát és futásidejű hibát** hozott felszínre a kliensoldali perzisztencia, a PowerShell kompatibilitás és a monorepo szinkronizáció terén.

---

## 2. A 3 TELEPÍTŐS ÁLLAPOT ÁLTAL ELŐIDÉZETT LOGIKAI ÉS BUILD HIBÁK

### #ERR-INST-01: Perzisztenciális Adatütközések az Összevont Kliensek Helyi SQLite Adatbázisaiban

#### A probléma leírása
Amikor a korábbi különálló klienseket (Pénztár + Értéktár a `penztar-client`-ben, illetve Központ + Árfolyamkészítő a `kozponti-client`-ben) egyetlen Electron futtató környezetbe vonjuk össze, mindkét üzemmód ugyanazt az Electron `app.getPath('userData')` könyvtárat fogja használni a helyi konfigurációk és az offline SQLite adatbázisok mentéséhez.

Mivel az Electron az `appId` és a `productName` alapján határozza meg a felhasználói adatmappát, a közös mappában lévő `pending_transactions`, `pending_distributions` és a Local-first szinkronizációs táblák elérése összeütközik:
- Ha egy pénztáros ugyanazon a gépen átvált Pénztár üzemmódból Értéktár üzemmódba, a helyi adatbázis sémája és az offline outbox állapota összezavarodik.
- Az Értéktáros tranzakciók szinkronizációs állapota bekeveredhet a Pénztárosi tranzakciók közé, ami **kereszt-bérlő vagy kereszt-szerepkörű adatszivárgást** okoz az offline cache-ben.

#### AI Ügynök által végrehajtható javítási javaslat
Az `app.getPath('userData')` elérési utat dinamikusan módosítani kell az aktívan kiválasztott `appMode` (üzemmód) alapján, hogy az offline perzisztencia rétegek teljesen elszigeteltek maradjanak:

```typescript
// kozponti-client/electron/main.ts módosítása
app.whenReady().then(async () => {
  activeAppMode = await determineStartupMode();
  
  // Dinamikusan elszigeteljük a felhasználói adatmappát mód alapján!
  const baseUserData = app.getPath('userData');
  app.setPath('userData', path.join(baseUserData, activeAppMode));
  
  log.info(`[App] Dinamikus userData beállítva: ${app.getPath('userData')}`);
  // ... (további inicializáció változatlan)
});
```

---

### #ERR-INST-02: Verziószinkronizációs Integritási Hiba (Monorepo Drift)

#### A probléma leírása
A monorepo gyökerében lévő `package.json` verziója `2.26.39`, a `penztar-client/package.json` szintén `2.26.39`, viszont az új, összevont `kozponti-client/package.json` fájlban a verzió hibásan `2.27.0`-ra lett növelve (lásd a 3. sort).

A `scripts/check-four-area-alignment.mjs` (V270 alignment check) 57. sora szigorúan ellenőrzi az összes kliens és a monorepo verzió-azonosságát:
```javascript
57: const uniqueVersions = new Set(versions.map((entry) => entry.version))
58: check(uniqueVersions.size === 1,
59:   'a monorepo, frontend és három telepíthető kliens verziója nincs szinkronban',
60:   versions.map((entry) => `${entry.relativePath}=${entry.version}`).join(', '))
```

Mivel a verziószámok eltérnek, az **`npm run check:four-area-alignment` azonnal hibát dob és meghiúsítja a teljes build pipeline-t**, blokkolva a kiadási folyamatot.

#### AI Ügynök által végrehajtható javítási javaslat
Szinkronizálni kell az összevont Központi kliens verzióját a monorepo aktuális kiadásával (`2.26.39`):

```json
// kozponti-client/package.json javítása
{
  "name": "valuta-kozponti-client",
  "version": "2.26.39", // <-- JAVÍTVA! 2.27.0-ról visszaállítva az összhang érdekében
  "private": true,
  ...
}
```

---

### #ERR-INST-03: PowerShell Kompatibilitási Hiba az Aláíratlan Build Csomagolásánál Windows Környezetben

#### A probléma leírása
A `kozponti-client/package.json` 19. sorában az aláíratlan Windows telepítő generálására szolgáló parancs a klasszikus `cmd.exe` parancssori szintaxist használja:

```json
19: "package:unsigned": "node ../scripts/check-four-area-alignment.mjs && npm run build && set ALLOW_UNSIGNED_BUILD=1&& electron-builder --win",
```

Windows operációs rendszer alatt a modern fejlesztői környezetek (így a VS Code és a monorepo CLI szkriptjei is) alapértelmezetten **PowerShell** terminált indítanak. A PowerShell nem ismeri fel a `set VARIABLE=value&&` cmd-alapú környezetiváltozó-definíciót, ezért a parancs futtatásakor szintaktikai hibát dob, vagy figyelmen kívül hagyja a változót, így a build sikertelen lesz az aláírás hiánya miatt.

#### AI Ügynök által végrehajtható javítási javaslat
Platform-független környezeti változó deklarációt kell alkalmazni (pl. `cross-env` csomag használatával) vagy át kell írni a PowerShell szabványnak megfelelő formátumra:

```json
// Helyes, cross-env alapú platformfüggetlen package.json script:
"package:unsigned": "node ../scripts/check-four-area-alignment.mjs && npm run build && npx cross-env ALLOW_UNSIGNED_BUILD=1 electron-builder --win",
```

---

### #ERR-INST-04: Csomagolt Kliens Összeomlása Hiányzó `dotenv` Termelési Függőség Miatt

#### A probléma leírása
Az összevont `kozponti-client/electron/main.ts` fájl az 552. sorban dinamikusan behívja a `dotenv` csomagot az `.env` fájl beolvasásához a csomagolt verzióban:

```typescript
552:       const dotenv = require('dotenv') as { parse: (input: string | Buffer) => Record<string, string> }
```

Azonban a `kozponti-client/package.json` függőségei között a `dotenv` **nincs deklarálva termelési függőségként (`dependencies`)**, kizárólag a monorepo gyökerében vagy a `devDependencies` között érhető el a fejlesztői gépen.

Amikor az `electron-builder` becsomagolja az alkalmazást, a termelési `node_modules` mappából kimarad a `dotenv` modul. A végfelhasználó gépén az alkalmazás elindításakor a Node.js azonnal **`MODULE_NOT_FOUND` hibával elszáll és összeomlik**, amint a `require('dotenv')` sorra kerül a vezérlés.

#### AI Ügynök által végrehajtható javítási javaslat
Adjuk hozzá explicit módon a `dotenv` csomagot a `kozponti-client` termelési függőségeihez:

```bash
cd kozponti-client
npm install dotenv --save
```

Ezzel a `package.json` `dependencies` szekciója helyesen frissül:
```json
  "dependencies": {
    "electron-log": "^5.4.3",
    "sql.js": "^1.11.0",
    "dotenv": "^16.4.5" // <-- JAVÍTVA! Szükséges a futásidejű beolvasáshoz a csomagolt buildben
  }
```

---

### #ERR-INST-05: Dev-mód és Renderer-Flavor Kiszolgálási Eltérés a Központi Kliensben

#### A probléma leírása
A `kozponti-client/electron/main.ts` a dev-kiszolgálás során az alábbiak szerint határozza meg a módot:

```typescript
195:   if (isDev) {
196:     return readPersistedMode()
197:   }
```

Dev módban a rendszer kikerüli a grafikus választó-ablakot és a korábban elmentett móddal indul el (pl. `rate-maker`). Ezzel szemben a `package.json` fájl `dev:renderer` parancsa fixen rögzíti a frontend flavor-t:

```json
11: "dev:renderer": "powershell -NoProfile -Command \"$env:VITE_APP_FLAVOR='central-workstation'; ...\""
```

Ha a korábban elmentett mód a `config.json`-ben `rate-maker`, az Electron héj a `rate-maker` fület próbálja megnyitni a `3020`-as porton, de a Vite dev szerver a `central-workstation` bundlet szolgálja ki. Ez a **frontend és az Electron main process közötti teljes funkcionális inkonzisztenciát** okoz fejlesztési időben (pl. hiányzó menük, hibás jogosultságok).

#### AI Ügynök által végrehajtható javítási javaslat
Módosítsuk a `determineStartupMode` metódust, hogy fejlesztési módban is kérje be a kívánt módot a konzolon vagy grafikus ablakon keresztül, vagy szinkronizáljuk a dev-szerver futtatást a megadott argumentumokkal.

---

## 3. ZÁRÓ ÖSSZEHASONLÍTÓ ÉRTÉKELÉS (SUMMARY)

A négy telepítőről három telepítőre való áttérés technológiailag helyes döntés volt az üzemeltetési terhek csökkentésére. Azonban az **összevont kliensek közötti SQLite adatszigetelés hiánya (#ERR-INST-01)** és a **hiányzó termelési `dotenv` függőség (#ERR-INST-04)** kritikus futási hibákhoz vezethetnek éles környezetben (alkalmazás-összeomlás és adatsérülés).

A javasolt módosítások végrehajtásával a 3-telepítős rendszer teljesen stabillá, biztonságossá és a monorepo minőségi kapuival kompatibilissé válik.

---

## Állapot
Kész (Telepítő transzformációs audit jelentés elmentve a repóban és az Artifacts könyvtárban).

## Modell és hatály
- modell/tool: Gemini / Antigravity Agent
- szabályzat: AGENTS.md (multi-modell v2)
- bizonyíték-időpont: 2026-05-24T19:40:02+02:00

## Változtatott fájlok
- [telepito_audithiba_jelentes.md](file:///d:/repo/valutavalto-program/telepito_audithiba_jelentes.md): ÚJ telepítő audit és hiba-összefoglaló jelentés elmentése a monorepóban.
