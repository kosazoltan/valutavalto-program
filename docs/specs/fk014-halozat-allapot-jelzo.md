# Modul: Árfolyamkészítő – Hálózat-állapot jelző javítása (frontend-react)

## 1. Cél
A Főlap szinkron-jelzője megbízhatóan mutassa az offline állapotot passzív
hálózat-vesztésnél is (jelenleg a zöld "Online" felirat rajta ragad), és ne
maradjon üres állapotban lapváltás utáni katalógus-betöltés közben.

## 2. Scope

### IN
- Passzív hálózat-vesztés érzékelése (böngésző online/offline esemény +
  időzített health-ping kombinációja)
- `serverSyncState` explicit `'offline'`-ra váltása passzív vesztésnél is,
  nem csak aktív szétküldési kísérlet sikertelenségekor
- Hálózat visszatérésekor automatikus visszaváltás `'online'`-ra és
  automatikus katalógus-újratöltés (resync)
- Az `'idle'` render-lyuk javítása: a mount-effect indulásakor azonnal
  `'loading'` állapotba kerüljön a jelző (nem csak a katalógus sikeres
  betöltése után), hogy lapváltás után offline állapotban se maradjon
  üres a jelző helye a katalógus-lekérés ideje alatt

### OUT
- A hálózat-vesztés **okának** kijelzése a felhasználónak (pl. "nincs net"
  vs. "szerver nem elérhető" megkülönböztetés) – a döntés szerint elég,
  ha megbízhatóan "Offline" jelenik meg, ok nélkül
- A halott `useOnlineStatus`/`OnlineIndicator` pár más felületen való
  bevezetése (pénztár/értéktár/központi kliens) – csak az árfolyamkészítő
  Főlapot érinti
- A `BranchMonitoringController` heartbeat-rendszerének bekötése a
  frontendbe – külön, jelenleg nem hívott mechanizmus, nem tartozik ide
- A `/api/v1/diagnostics/health` végpont vizsgálata/bevonása

## 3. Szakterületi szereplők (RBAC mátrix)

Ez a fejlesztés kizárólag UI-állapotjelzés, nem érint jogosultság-korlátozott
műveletet vagy új végpontot – RBAC-mátrix nem releváns ebben a scope-ban.

| Szerep | olvas | létrehoz | módosít | töröl | publikál | jóváhagy |
|---|---|---|---|---|---|---|
| Főértéktáros | ✓ | – | – | – | – | – |
| Főértéktáros helyettes | ✓ | – | – | – | – | – |

## 4. Funkcionális követelmények (FR)

| ID | Leírás | Forrás | Prioritás | Csomag | Acceptance (Given/When/Then) |
|---|---|---|---|---|---|
| FR-1 | Böngésző online/offline esemény figyelése | Interjú | MUST | frontend-react | Adott: Főlap betöltve. Amikor: `window` `'offline'` eseményt kap. Akkor: a szinkron-jelző állapota `'offline'`-ra vált (ha nincs függő dirty-védelem, lásd FR-6). |
| FR-2 | Időzített health-ping (`GET /api/v1/health`) | Interjú + Code-audit | MUST | frontend-react | Adott: Főlap aktív. Amikor: a beállított időköz (lásd NFR-1) letelik. Akkor: hívás történik a health-végpontra, és a válasz alapján a state frissül. Megjegyzés: a health-ping platformfüggetlenül fut, nincs `isElectron()` kapu — az árfolyamkészítő élesben kizárólag Electron-kliensben fut, a megkülönböztetésnek nincs értelme. |
| FR-3 | Explicit offline állapot megerősített hálózat-vesztésnél | Interjú | MUST | frontend-react | Adott: online esemény hiánya VAGY health-ping hiba. Amikor: a state jelenleg `'online'`. Akkor: state `'offline'`-ra vált, "Offline — helyi cache" felirat jelenik meg (meglévő vizuál, nincs új felirat/szín). |
| FR-4 | Automatikus visszaváltás és resync hálózat-visszatérésnél | Interjú | MUST | frontend-react | Adott: state `'offline'`. Amikor: a `window` `'online'` eseményt kap, VAGY egy health-ping önmagában sikeresen lefut (miközben a state `'offline'`). Akkor: mindkét trigger esetén a state `'online'`-ra vált ÉS a katalógus automatikusan újratöltődik (a mount-sync effect logikájának újrafuttatásával). |
| FR-5 | `'idle'` render-lyuk megszüntetése | Code-audit (előkerült hiba) | MUST | frontend-react | Adott: Főlap mountol (első betöltés vagy lapváltás utáni visszalépés). Amikor: a katalógus-lekérés elindul, még mielőtt válasz érkezne. Akkor: a state azonnal `'loading'`-ra áll (kék pulzáló ikon, "Szerver szinkron…"), nem `'idle'`-n marad. |
| FR-6 | Dirty-védelem tiszteletben tartása | Code-audit (kockázat) | MUST | frontend-react | Adott: van mentetlen szerkesztés (`dirtyRef.current === true`). Amikor: passzív hálózat-esemény vagy health-ping trigger fut. Akkor: a state-váltás megtörténhet, de cache-ből való felülírás/adat-csere nem történik dirty cellákon (a meglévő `!dirtyRef.current` védelem mintáját követve). |
| FR-7 | Listener/interval cleanup unmountkor | Code-audit (kockázat) | MUST | frontend-react | Adott: Főlap unmountol (lapváltás). Amikor: a komponens megsemmisül. Akkor: az online/offline event listener és a health-ping interval leiratkozik, nem fut tovább a háttérben. |

## 5. Nem-funkcionális követelmények (NFR)

| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-1 | Health-ping időköz | 30 mp (a meglévő, korábban tervezett `useOnlineStatus` mintájával egyezően), figyelembe véve hogy a health-végpont valódi DB-kapcsolat-ellenőrzést futtat hívásonként |
| NFR-2 | Toast-spam elkerülése | Rövid hálózat-ingadozásnál (pl. néhány másodperces glitch) ne generáljon ismétlődő/duplikált toast-értesítést – debounce vagy hiszterézis szükséges. A késleltetés/hiszterézis KIZÁRÓLAG a toast-értesítésre vonatkozik, nem az állapotváltásra: a jelző (state) azonnal `'offline'`-ra vált hálózat-vesztésnél vagy health-ping-hibánál. |
| NFR-3 | Timeout-korlát | A katalógus-hívás offline esetben a meglévő globális axios-timeouton (30 mp) belül hibázzon, ne lógjon tovább |
| NFR-4 | Lokalizáció | hu-HU, meglévő feliratok újrahasználva ("Offline — helyi cache", "Szerver szinkron…") |

## 6. Adatmodell-érintettség
- Új tábla / mező szükséges: **NEM**
- Ha igen: – (nincs)
- Flyway migráció: nincs szükség
- SQLite mirror: **NEM** (tisztán frontend állapotkezelés, nincs perzisztencia-igény)

## 6.b Biztonsági érintettség (security-standards.md hivatkozással)
- [ ] Új jogosultság / szerep (§2)
- [ ] PII / pénzügyi adat (§3)
- [ ] Cross-tenant teszt szükséges (§1)
- [ ] Új audit-esemény (§3 KAT: nincs – UI-only állapotjelzés, nem üzleti esemény)
- [ ] Secret / kulcs kezelést érint (§4)
- [ ] Offline szinkron biztonságát érinti (§5) – *csak jelzés, nem adatkezelés, ezért nem érinti a §5 offline-biztonsági (SQLCipher/safeStorage) kört*
- [ ] Új végpont (§2) – **nincs**, meglévő `GET /api/v1/health` végpontot használjuk (permitAll, már élesben fut)

## 7. Függőségek
- Belső modulok: Főlap (`MainRateSheetPage.tsx`) szinkron-jelzője
- Érintett más kliensek: **nincs** – kizárólag az árfolyamkészítő Főlapját érinti, a pénztári/értéktári/központi klienst nem
- Backend API: nincs új végpont, meglévő `GET /api/v1/health` felhasználása (kliens-oldali hívás, nincs backend-módosítás)

## 8. Domain-szótár

| Fogalom | Magyarázat |
|---|---|
| `serverSyncState` | A Főlap szinkron-állapotát tároló lokális React state: `'idle' \| 'loading' \| 'online' \| 'offline'` |
| Passzív hálózat-vesztés | A kliens elveszti a hálózati kapcsolatot anélkül, hogy aktív szétküldési kísérlet futna – jelenleg nem detektált eset |
| Health-ping | A `GET /api/v1/health` végpont periodikus hívása a szerver-elérhetőség megerősítésére (a böngésző online/offline eseménye önmagában csak a hálózati interfész meglétét jelzi, nem a szerver elérhetőségét) |

## 9. Végrehajtási utasítás az AI-fejlesztő ügynöknek

**Megjegyzés a folyamatról:** ez az FK a kettévágott teszt-előbb mintát követi
(Claude-workflow-szabályzat 2. pontja). A 9.2 Fázis 4 (tesztek) egy **külön,
első körben kiadott prompt**, implementáció nélkül – a tesztek megírása és
áttekintése után indul csak a Fázis 1–3 (implementáció). Ez az FK-nál
kifejezetten indokolt, mert a Code-audit során már most kiderült egy nem várt,
finom állapotgép-hiba (`'idle'` render-lyuk) – a fagyasztott tesztek segítenek
elkerülni, hogy egy hasonló, nem egyeztetett részlet észrevétlen maradjon.

### 9.1. Előkészítés
1. `cd C:\repo\valutavalto-program`
2. `git pull`
3. `git checkout -b tomi/fk14-halozat-allapot-jelzo`

### 9.2. Fázisok

**Fázis 0 – Tesztek megírása (implementáció NÉLKÜL, ELSŐ körben kiadandó prompt)**
- A fenti FR-1–FR-7 Given/When/Then sorai alapján írd meg a Vitest teszteket
  a `MainRateSheetPage.tsx` szinkron-jelző logikájára.
- A teszteknek **bukniuk kell** a jelenlegi kóddal szemben (kivéve, ahol a
  jelenlegi kód már véletlenül megfelel).
- Emeld ki külön, ha a tesztírás közben bármelyik FR kétértelműnek bizonyul –
  ne dönts helyette önállóan, jelezd vissza kérdésként.
- **Ne módosíts implementációs kódot ebben a lépésben.**
- Kimenet: a teszt-diff + rövid összefoglaló, melyik FR-hez hány teszt
  készült, és van-e olyan pont, ahol a spec alapján nem egyértelmű a várt
  viselkedés.

*(A Fázis 0 áttekintése után – Tomi + Claude review – csak ezután adjuk ki a
Fázis 1–3 implementációs promptot. A tesztek innentől fagyottak.)*

**Fázis 1 – Backend** (nincs szükség rá – meglévő végpont felhasználása)

**Fázis 2 – Frontend implementáció**
- Érintett fájl: `frontend-react/src/pages/rates/MainRateSheetPage.tsx`
  (mount-sync effect, 892–1094. sor környéke; `dispatchToServer` érintetlen
  marad)
- Új logika: online/offline event listener + health-ping interval bekötése
  (a halott `useOnlineStatus.ts` mintája újrafelhasználható, de a hibás
  `/actuator/health` végpontot cserélni kell `/api/v1/health`-re – NE
  importáld be változtatás nélkül, a hibát javítani kell)
- A mount-effect módosítása: `setServerSyncState('loading')` a catalog-hívás
  **elindításakor**, ne csak a sikeres válasz után
- Cleanup: `useEffect` return-ágban listener/interval leiratkozás
- Acceptance: a Fázis 0-ban írt tesztek zölddé válnak, nincs regresszió a
  meglévő `MainRateSheetPage.remount.test.tsx` suite-ban

**Fázis 3 – Tesztek kiegészítése (ha szükséges)**
- Offline-remount eset felvétele a meglévő remount-teszt suite-ba (a
  Code-audit szerint ez jelenleg hiányzik)
- Edge case katalógus:
  - Rövid hálózat-glitch (néhány mp) → nincs duplikált toast
  - Health-ping hibázik, de böngésző online eseményt nem kapott → offline
  - Böngésző online eseményt kap, de health-ping még nem erősítette meg →
    lásd 10. TBD-1
  - Dirty cellák mellett történő state-váltás → nincs adatfelülírás
  - Unmount hálózat-esemény közben → nincs memory leak / hibás setState

### 9.3. Pipeline (Definition of Done)
1. `lint` (eslint) PASS
2. `npm run test` (Vitest) PASS
3. Manuális ellenőrzés Electron EXE-ben (a hiba ott lett megfigyelve, nem
   böngészőben) – WiFi ki/be kapcsolással, lapváltással
4. `gitleaks` secret-scan PASS
5. `grep -r "@Disabled\|@Ignore\|skip("` → 0 találat új kódon
6. Code-audit (git log/branch/commit-verifikáció) beadás előtt

## 10. Kockázatok / Nyitott kérdések (TBD)

| # | Kérdés | Miért fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A böngésző `'online'` eseménye csak a hálózati interfész meglétét jelzi, nem a szerver elérhetőségét (Code-audit megállapítása). Tomi döntése szerint a visszaváltás azonnal történjen az eseményre. Ez azt jelenti, hogy captive portal / félkész kapcsolat esetén tévesen `'online'`-ra válthat a jelző, mielőtt a health-ping megerősítené. | UX-pontosság vs. egyszerűség | Alapértelmezésben Tomi döntése szerint azonnali váltás; ha a gyakorlatban zavaró tévesen "online" jelzés fordul elő, később finomítható health-ping megerősítésre |
| 2 | Az Electron main-process `apiRequest` proxy tényleges timeout-viselkedése lekapcsolt hálózatnál nem verifikált (Code-audit) | A NFR-3 (30 mp timeout) feltételezi, hogy ez érvényesül Electronban is | Fázis 2 közben, ha eltérést tapasztal az agent, jelezze |
| 3 | Health-ping gyakoriság (30 mp) és a végpont valódi DB-ellenőrzést futtat hívásonként – terhelés több egyidejű kliensnél | Skálázhatóság | Egyelőre egyfelhasználós/kevés-klienses használat, később felülvizsgálandó ha több kliens fut párhuzamosan |
| 4 | Offline-remount eset tesztlefedettsége jelenleg hiányzik a meglévő suite-ban (Code-audit) | Regresszió-védelem | Fázis 3-ban pótlandó |

## 11. Kapcsolódó modulok
- [x] Árfolyamkészítő (elsődleges, kizárólagos)
- [ ] Központi kliens
- [ ] Pénztári felület
- [ ] Értéktári felület

## 12. Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás (Interjú / Code-audit)
- [x] Minden FR-hez Acceptance Given/When/Then
- [x] NFR-ek számszerűsítve (30 mp ping, 30 mp timeout)
- [x] Nincs hallucináció (csak interjúban elhangzott + Code-audit bizonyíték)
- [x] TBD-ek külön jelölve (4 db)
- [x] Adatmodell konkrét (nincs új tábla/mező)
- [x] Flyway migráció: nem releváns
- [x] Pipeline + Definition of Done teljes
- [x] Cross-tenant teszt: nem releváns (nincs backend-végpont-változás)
- [x] @PreAuthorize: nem releváns (nincs új végpont)
- [x] Audit-esemény: nincs (UI-only)
- [x] Nincs hard-coded secret
- [x] Input DTO: nem releváns (nincs backend-változás)
- [x] Más klienst nem érint (kizárólag árfolyamkészítő)
- [x] Teszt-előbb (freeze) folyamat explicit jelölve a 9. szekcióban

---
FR-ek száma: 7 db
TBD-ek száma: 4 db
Érintett csomagok: frontend-react (kizárólag)
