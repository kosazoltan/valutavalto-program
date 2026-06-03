<system_context>
# Modul: Zárás Ablak (zárás-wizard)

## Kontextus
A Zárás Ablak feladata, hogy egy 16 lépéses lépésenkénti wizard (varázsló) segítségével végigvezesse a felhasználót a napi, dekád, havi és POS terminál zárási folyamatokon. A modul kezeli a napi összesítéseket, a pénzügyi eltérések magyarázatát, a bizonylatok nyomtatását és a központi rendszerbe küldött riportokat, valamint lehetővé teszi a korábbi zárások megtekintését és a bizonylatok újranyomtatását.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: Electron kliens (`penztar-client`)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)

## Szakterületi Szereplők (Roles)
- **Felhasználó** (pénztáros): Zárás indítása, összesítések ellenőrzése/jóváhagyása, eltérés-magyarázat megadása, bizonylat-nyomtatás, riport-küldés beállítása, zárás véglegesítése (RBAC érték: `ROLE_CASHIER`)
- **Zárást ellenőrző személy** (Supervisor / Ellenőr): A zárási adatok helyben történő ellenőrzése és aláírása (RBAC érték: `ROLE_SUPERVISOR` vagy `ROLE_AUDITOR`)

## Hatókör (Scope)
- **IN**:
  - Zárás Ablak fő funkciói: Zárások megtekintése, Bizonylatok újranyomtatása, Zárás indítása.
  - Zárás indítása gomb + rákérdezés a zárás típusára: napi / dekád / havi.
  - Dekád zárás rákérdezés időzítése: a hónap pontos naptári napjain (10-én, 20-án és a hónap utolsó napján) a napi zárás alkalmával.
  - Havi zárás rákérdezés időzítése: a hónap utolsó naptári napjának zárásakor.
  - Zárás kiválasztása - OK -> Zárás wizard indítása.
  - Wizard 16 lépése (Lépés 1–16), "Tovább"/"Vissza" navigációval és a záró "Megerősítés" gombbal.
  - Zárási típusválasztó a wizard 1. képernyőjén: Napi, POS terminál, Dekád, Havi.
- **OUT**:
  - A zárási bizonylatok pontos mezőtartalma (lásd: `b2-zaras-kepernyok-bizonylatok.md`).
</system_context>

<functional_spec>
## Funkcionális Követelmények

### ### [FR-ZAR-01] [Korábbi zárások megtekintése]
- **Leírás**: A felhasználó a Zárás Ablakon megtekintheti a korábban elvégzett lezárt napi, dekád és havi zárások listáját és részleteit.
- **Forrás**: zaras_ablak.docx bevezető
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Lekérdezési szűrők
- **Kimenet / Visszajelzés**: Korábbi zárások listája
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-02] [Bizonylatok újranyomtatása]
- **Leírás**: Lehetőség biztosítása a korábbi lezárt időszakok zárási bizonylatainak ismételt kinyomtatására.
- **Forrás**: zaras_ablak.docx bevezető
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Kiválasztott korábbi zárás
- **Kimenet / Visszajelzés**: Nyomtatási parancs küldése
- **Validációk és Kényszerek**: Csak lezárt időszak bizonylata nyomtatható újra.

### ### [FR-ZAR-03] [Zárás indítása és típusválasztás]
- **Leírás**: "Zárás indítása" gombra kattintva a rendszer rákérdez a zárás típusára (napi/dekád/havi), majd az "OK" gombbal elindítja a zárási wizardot.
- **Forrás**: zaras_ablak.docx bevezető
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Felhasználói kattintás + típus kiválasztás
- **Kimenet / Visszajelzés**: A zárási wizard megnyitása a kiválasztott konfigurációval
- **Validációk és Kényszerek**: Folyamatban lévő tranzakciók esetén figyelmeztetést kell adni.

### ### [FR-ZAR-04] [Dekád zárás trigger]
- **Leírás**: Dekád zárás automatikus felajánlása (rákérdezés) a hónap pontos naptári napjain (10-én, 20-án, és a hónap utolsó napján) a napi zárás elvégzésekor, nem pedig a "10. nyitvatartási napon".
- **Forrás**: zaras_ablak.docx bevezető
- **Prio**: Magas
- **Csomag/Komponens**: backend / penztar-client
- **Bemenő adatok**: Aktuális naptári dátum a napi záráskor
- **Kimenet / Visszajelzés**: Pop-up üzenet a dekád zárás elvégzésére
- **Validációk és Kényszerek**: Csak a megadott naptári napokon aktiválódik a napi zárási folyamat végén.

### ### [FR-ZAR-05] [Havi zárás trigger]
- **Leírás**: Havi zárás automatikus felajánlása (rákérdezés) a hónap utolsó naptári napjának napi zárásakor.
- **Forrás**: zaras_ablak.docx bevezető
- **Prio**: Magas
- **Csomag/Komponens**: backend / penztar-client
- **Bemenő adatok**: Aktuális dátum
- **Kimenet / Visszajelzés**: Pop-up üzenet a havi zárás elvégzésére
- **Validációk és Kényszerek**: Csak a hónap utolsó napján aktiválódik.

### ### [FR-ZAR-06] [Wizard 1. lépés: Tájékoztató és Típusválasztó]
- **Leírás**: A wizard 1. képernyője tájékoztatja a felhasználót a zárási folyamatról, és lehetőséget ad a zárási típus (Napi, POS terminál, Dekád, Havi) megerősítésére vagy módosítására.
- **Forrás**: zaras_ablak.docx 1. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Zárás típus kiválasztása
- **Kimenet / Visszajelzés**: Következő wizard lépésre navigáció
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-07] [Lépés 1: Napi tranzakciók összesítése]
- **Leírás**: Napi tranzakciók automatikus összesítése devizanemenként (vétel/eladás, és a pénztárak közötti belső mozgások), amelyet a felhasználónak ellenőriznie és jóvá kell hagynia.
- **Forrás**: zaras_ablak.docx 2. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Napi tranzakciós napló adatai
- **Kimenet / Visszajelzés**: Összesítő táblázat megjelenítése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-08] [Lépés 2: Készpénzkészlet ellenőrzése]
- **Leírás**: Készpénz nyitó- és zárókészlet ellenőrzése devizanemenként. A felhasználónak manuálisan jóvá kell hagynia a fizikai egyezőséget.
- **Forrás**: zaras_ablak.docx 2. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Rendszer szerinti készlet vs. fizikai egyenleg
- **Kimenet / Visszajelzés**: Egyezőség megerősítése
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-09] [Lépés 3: Kezelési költségek összesítése]
- **Leírás**: Az aznapi tranzakciók során felszámított kezelési költségek (díjak) összesített értékének megjelenítése és jóváhagyása.
- **Forrás**: zaras_ablak.docx 2. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Kezelési díj adatok
- **Kimenet / Visszajelzés**: Kezelési költség összesítő
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-10] [Lépés 4: Pénztárközi mozgások összesítése]
- **Leírás**: Pénztárak közötti mozgások (átadott/átvett devizák és forintok) összesített értékének megtekintése és egyeztetése.
- **Forrás**: zaras_ablak.docx 2. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Pénztárközi bizonylatok
- **Kimenet / Visszajelzés**: Mozgás összesítő lista
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-11] [Lépés 5: Napi valutaárfolyamok megjelenítése]
- **Leírás**: Az aznap használt és érvényesített valutaárfolyamok listájának megjelenítése ellenőrzési céllal.
- **Forrás**: zaras_ablak.docx 2. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Napi árfolyamtábla
- **Kimenet / Visszajelzés**: Árfolyamok listája
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-12] [Lépés 6: Dekád tranzakciók és készletek összesítése]
- **Leírás**: Dekád vagy havi zárás esetén a teljes dekád/havi tranzakciók és devizakészletek összesített bemutatása (csak dekád/havi záráskor jelenik meg).
- **Forrás**: zaras_ablak.docx 3. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Dekád/havi tranzakciók adatai
- **Kimenet / Visszajelzés**: Összesített dekád riport
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-13] [Lépés 7: Pénzügyi eltérések és magyarázat]
- **Leírás**: Pénzügyi eltérések (többlet/hiány) megjelenítése, valamint a felhasználó által megadható eltérés-magyarázat rögzítése (csak dekád/havi záráskor).
- **Forrás**: zaras_ablak.docx 3. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Eltérés összege + szöveges magyarázat
- **Kimenet / Visszajelzés**: Eltérés-magyarázat rögzítése
- **Validációk és Kényszerek**: Ha van eltérés, a magyarázat mező kitöltése kötelező.

### ### [FR-ZAR-14] [Lépés 8: Korrekciós bizonylatok megtekintése]
- **Leírás**: A rendszer által az eltérések és magyarázatok alapján generált korrekciós bizonylatok megtekintése (csak dekád/havi záráskor).
- **Forrás**: zaras_ablak.docx 3. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Rögzített eltérések
- **Kimenet / Visszajelzés**: Korrekciós bizonylat előnézet
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-15] [Lépés 9: Kártyás tranzakciók összesítése]
- **Leírás**: Kártyás tranzakciók összesítése a POS terminál adatai alapján. Ez a lépés kizárólag azokon a munkahelyeken (desks) fut le, ahol kártyás terminál van konfigurálva (`Terminal.dll` / `F3TerminalGomb`).
- **Forrás**: zaras_ablak.docx 4. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: POS tranzakciós napló
- **Kimenet / Visszajelzés**: POS összesítő adatok
- **Validációk és Kényszerek**: Ha nincs terminál konfigurálva, a lépés automatikusan átugrásra kerül.

### ### [FR-ZAR-16] [Lépés 10: POS visszatérítések és sztornók]
- **Leírás**: Kártyás visszatérítések és sztornó műveletek összesített értékének bemutatása a POS terminál alapján. Csak konfigurált terminál esetén fut le.
- **Forrás**: zaras_ablak.docx 4. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: POS reversals adatok
- **Kimenet / Visszajelzés**: POS visszatérítés összesítő
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-17] [Lépés 11: POS díjak és költségek]
- **Leírás**: POS kezelési költségek és tranzakciós banki díjak összesített értékének megjelenítése. Csak konfigurált terminál esetén fut le.
- **Forrás**: zaras_ablak.docx 4. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: POS jutalék és díj adatok
- **Kimenet / Visszajelzés**: POS díj összesítő
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-18] [Lépés 12: Zárási bizonylatok nyomtatása]
- **Leírás**: Zárási bizonylatok többpéldányos nyomtatása. A felhasználó kiválaszthatja a nyomtatni kívánt bizonylat-típusokat (napi/dekád/havi/POS).
- **Forrás**: zaras_ablak.docx 5. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Nyomtatási beállítások (példányszám, típus)
- **Kimenet / Visszajelzés**: Nyomtatási feladat küldése a nyomtatónak
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-19] [Lépés 13: Forint átadás-átvételi bizonylat]
- **Leírás**: Napi forint készpénz átadás-átvételi bizonylatok generálása és nyomtatása folyamatos, hézagmentes sorszámozással.
- **Forrás**: zaras_ablak.docx 5. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Átadás-átvétel adatai
- **Kimenet / Visszajelzés**: Sorszámozott átadási bizonylat
- **Validációk és Kényszerek**: A sorszám kiosztásnak szigorúan folyamatosnak kell lennie.

### ### [FR-ZAR-20] [Lépés 14: Napi jelentések automatikus küldése]
- **Leírás**: Napi zárási jelentések automatikus küldése a központi rendszerbe. A továbbítás biztonságos HTTPS REST API-kon keresztül, vagy SFTP feltöltéssel történik a secure sync agent kimenő sorának (outbox queue) segítségével.
- **Forrás**: zaras_ablak.docx 6. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Lezárt nap adatai
- **Kimenet / Visszajelzés**: Riport export és továbbítás
- **Validációk és Kényszerek**: Hálózati hiba esetén az outbox queue-ban sorba kell állítani a küldést (offline működés).

### ### [FR-ZAR-21] [Lépés 15: Dekád/Havi jelentések automatikus küldése]
- **Leírás**: Dekád/havi zárási jelentések automatikus továbbítása a központi rendszerbe HTTPS REST API-n vagy SFTP feltöltésen keresztül a secure sync agent outbox queue segítségével.
- **Forrás**: zaras_ablak.docx 6. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Lezárt dekád/hónap adatai
- **Kimenet / Visszajelzés**: Továbbított jelentés státusza
- **Validációk és Kényszerek**: N/A

### ### [FR-ZAR-22] [Lépés 16: Zárás véglegesítése]
- **Leírás**: A zárási folyamat véglegesítése a "Megerősítés" gombbal. A rendszer lezárja a napi vagy dekád/havi időszakot, letiltja az új tranzakciók rögzítését arra a napra, és elkészíti a végleges jelentéseket.
- **Forrás**: zaras_ablak.docx 7. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Megerősítés kattintás
- **Kimenet / Visszajelzés**: Zárási állapot "LEZÁRT"-ra állítása
- **Validációk és Kényszerek**: A lezárás után az adott napra/időszakra új tranzakció nem rögzíthető.

### ### [FR-ZAR-23] [Wizard navigáció]
- **Leírás**: Minden wizard-lépésen biztosítani kell a "Tovább" és "Vissza" gombokat a lépések közötti navigációhoz.
- **Forrás**: zaras_ablak.docx 2–6. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Navigációs kattintások
- **Kimenet / Visszajelzés**: Megfelelő wizard lépés megjelenítése
- **Validációk és Kényszerek**: A "Tovább" lépéshez az adott képernyő kötelező mezőinek (pl. eltérés-magyarázat) validáltnak kell lenniük.
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok

A zárás-wizard lépéseihez az alábbi sémát javasoljuk PostgreSQL és SQLite mirror célpontokra:

### PostgreSQL
- **Closure (Zárás törzstábla)**:
  - `id` (serial, primary key)
  - `branch_id` (int, foreign key -> Branch)
  - `closure_type` (varchar, pl. 'DAILY', 'DECADE', 'MONTHLY', 'POS')
  - `closure_date` (date)
  - `started_at` (timestamp, default now())
  - `finished_at` (timestamp)
  - `status` (varchar, pl. 'IN_PROGRESS', 'COMPLETED')
  - `cashier_id` (int, foreign key -> User)
- **DailyCashBalance (Napi készpénz egyenleg)**:
  - `closure_id` (foreign key -> Closure)
  - `currency_code` (varchar(3))
  - `opening_balance` (decimal)
  - `closing_balance` (decimal)
  - `calculated_transactions` (decimal, a tranzakciók alapján)
  - `difference` (decimal, closing - calculated - opening)
- **ClosureCorrection (Eltérések és korrekciók)**:
  - `id` (serial, primary key)
  - `closure_id` (foreign key -> Closure)
  - `amount` (decimal)
  - `description` (text, a felhasználó által megadott eltérés-magyarázat)
  - `correction_receipt_no` (varchar, generált korrekciós bizonylatszám)
- **TransferReceipt (Forint átadás-átvételi bizonylat)**:
  - `id` (serial, primary key)
  - `closure_id` (foreign key -> Closure)
  - `serial_number` (varchar, egyedi folyamatos sorszám)
  - `amount` (decimal)
  - `sender_name` (varchar)
  - `receiver_name` (varchar)

### SQLite (Offline mirror a kliensen)
- Az összes fenti táblát le kell képezni SQLite-ban is, mivel a zárás offline módban is elvégezhető. A sorszámozott bizonylatok sorszám-generátorát az SQLite-ban is szigorúan konzisztensen kell tartani.

### Legacy adatbázis leképezés (Legacy Mappings)
- `NAPIOSSZESITO` / `NAPIZAR` (Napi zárások és összesítések)
- `ELOHAVI` / `HAVIOSSSZESITO` (Havi összesítések és havi nyitók)
- `BLOKKFEJ` / `BLOKKTETEL` (Napi tranzakciók ellenőrzéséhez és másolásához)
- `HARDWARE` (Lezárt nap dátumának beállítása: `LEZARTNAP` frissítése)
- `PENZTAR` (Kassza azonosító és készlet tároló)
- `CIMT` (Címlet darabszámok tárolása)
</data_structure>

<integration_points>
## Integrációs Pontok
- **POS Terminál API**:
  - Kártyás tranzakciók összesítésének és sztornóinak szinkronizálása a wizard 9–11. lépéseihez (FR-ZAR-15..FR-ZAR-17), amely csak a `Terminal.dll` / `F3TerminalGomb` konfiguráció megléte esetén fut le.
- **Központi Riportküldő Rendszer**:
  - Zárási jelentések automatikus továbbítása XML/JSON formátumban (FR-ZAR-20, FR-ZAR-21) secure HTTPS REST API-k vagy SFTP upload segítségével, a secure sync agent outbox queue soron keresztül.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
- Olvasd el a `zaras_ablak.docx` fájlt, és vesd össze a bizonylatok mezőit leíró `b2-zaras-kepernyok-bizonylatok.md` specifikációval.
- Határozd meg a naptári napok szerinti dekád indítási logikát.

### Phase 2: Backend (Backend)
- Készítsd el az adatbázis sémát (Postgres + SQLite mirror táblák, legacy tábla hivatkozások).
- Írd meg a dekád- (10., 20. és hónap utolsó napja) és havi zárás esedékességét ellenőrző lekérdező logikát (FR-ZAR-04, FR-ZAR-05).
- Fejleszd le az átadás-átvételi bizonylatok folyamatos sorszám-kiosztó szolgáltatását tranzakciós garanciákkal.
- Készítsd el a riportok exportálását és a központba való küldés outbox queue sor-kezelőjét.

### Phase 3: Frontend/Client (Frontend/Client)
- Készítsd el a Zárás Ablak alapfelületét (korábbi zárások megtekintése, bizonylat újranyomtatás gomb).
- Implementáld a 16 lépéses Wizard modal komponenst dinamikus léptetéssel.
- Fejleszd le a dekád/havi feltételes lépéseket (6–8. lépés), és a POS összesítő lépéseket (9–11. lépés), amelyek a terminál konfiguráció alapján jelennek meg.
- Építsd be a kötelező mezők validációját (pl. eltérés esetén a magyarázat kötelezővé tétele).
- Integráld a bizonylatok nyomtatását és a végső megerősítési folyamatot.

### Phase 4: Verification (Verification)
- **Unit tesztek**: Ellenőrizd a wizard lépéseinek útválasztását (napi vs. dekád/havi zárás esetén a lépések száma és sorrendje).
- **Unit tesztek**: Teszteld a dekád zárás naptári napok szerinti triggerét (10., 20., hó vége) és a havi zárás utolsó nap triggerét.
- **Integrációs tesztek**: Ellenőrizd a tranzakció-lezárást (megerősítés után az adott napra új tranzakció rögzítési kísérletnek el kell buknia).
- **Negatív tesztek**: Sikertelen központi hálózati küldés tesztelése -> a lokális zárásnak sikeresen be kell fejeződnie, a küldésnek a sorban kell maradnia.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)
| # | Kérdés | Miért fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | A riportok központba küldésének technikai csatornája és formátuma | Központi adatok konszolidációja | **LEZÁRVA**: Biztonságos HTTPS REST API-kon keresztül, vagy SFTP feltöltéssel a secure sync agent kimenő sorának (outbox queue) segítségével történik a küldés. |
| TBD-2 | A zárást végző felhasználó konkrét RBAC szerepkör-értéke | Jogosultság-kezelés és naplózás | **LEZÁRVA**: Cashier (`ROLE_CASHIER`) és Ellenőrző személy (`ROLE_SUPERVISOR` vagy `ROLE_AUDITOR`). |
| TBD-3 | Zárás/összesítés/eltérés/bizonylat pontos adatmodellje + SQLite mirror mezők | Offline működés biztonsága | **LEZÁRVA**: SQLite mirroron is tárolni kell a zárási adatokat. Legacy leképezések: `NAPIOSSZESITO`, `HAVIOSSSZESITO`/`ELOHAVI`, `BLOKKFEJ`, `BLOKKTETEL`, `HARDWARE`, `CIMT`. |
| TBD-4 | "Nyitvatartási nap" pontos definíciója és naptár-forrása | Dekád/havi rákérdezés időzítése | **LEZÁRVA**: Nem nyitvatartási napok számítanak; a dekád zárás a hónap konkrét naptári napjain (10., 20. és az utolsó napon) fut le a napi zárással együtt. |
| TBD-5 | A POS lépések feltételessége (minden fióknál fut-e, vagy csak ahol van terminál) | Wizard-lépéssor konfigurálhatósága | **LEZÁRVA**: Csak azokon a munkahelyeken/pénztárakban fut le, ahol kártyás terminál van konfigurálva (`Terminal.dll` / `F3TerminalGomb`). |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden funkcionális követelmény (FR-ZAR) visszavezethető a `zaras_ablak.docx` forrásfájlra és a megerősített tényekre.
- [x] 0 hallucináció (az üzleti szabályok és a wizard lépések szigorúan a forrás alapján lettek felvéve).
- [x] Minden nyitott kérdés (TBD-1..TBD-5) feloldásra és katalogizálásra került.
</verification_checklist>
