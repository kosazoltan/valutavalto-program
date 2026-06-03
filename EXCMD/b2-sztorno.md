<system_context>
# Modul: Sztornókezelés

## Kontextus
A korábbi valuta vétel/eladás (és kártyás POS) tranzakciók szabályozott visszavonásának leírása. A sztornó történhet az eredeti árfolyamon, vagy — eltérés esetén — az aktuális árfolyamon számított visszatérítéssel. A harmadik napi sztornó után a művelet pénzügyi vezetői engedélyhez kötött, és minden esetben sztornó bizonylatot generál a rendszer.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: Electron kliens (`penztar-client`, `kozponti-client` a vezetői jóváhagyáshoz)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)

## Szakterületi Szereplők (Roles)
- **Pénztáros** ("felhasználó"): Sztornó kezdeményezése, eredeti tranzakció azonosítása, sztornó végrehajtása napi 3 sztornóig (RBAC érték: `ROLE_CASHIER`)
- **Supervisor** (Pénzügyi vezető): A 4. sztornótól kezdve a jóváhagyás megadása a pénztáros képernyőjén megjelenő jelszóbekérő ablakban (RBAC érték: `ROLE_SUPERVISOR`)

## Hatókör (Scope)
- **IN**:
  - Sztornó kezdeményezése a rendszerben vagy a POS terminálon.
  - Eredeti tranzakció azonosítása: időpont, vásárolt/eladott deviza, eredeti árfolyam, összeg.
  - Sztornó végrehajtása, visszafizetés az eredeti tranzakció szerint.
  - NAV felé sztornó (a bekötött pénztárgép külön művelet nélkül automatikusan kezeli a driveren keresztül).
  - Napi sztornó-számlálás és a 4. sztornótól kezdődő közvetlen Supervisor jelszavas jóváhagyás.
  - Eltérő árfolyamon történő sztornó: eltérés feljegyzése, felhasználói értesítés, visszatérítendő összeg újraszámítása aktuális árfolyamon.
  - POS terminál sztornókezelése: kártyás tranzakció visszahívása + visszatérítés.
  - Sztornó bizonylat generálása, nyomtatása, sorszám alapú archiválása.
- **OUT**:
  - A pénztárgép NAV-jelentés belső protokollja (automatikus).
  - Engedélykérés értesítési csatornája (e-mail/SMS/push) — felesleges, mivel a jóváhagyás közvetlenül a képernyőn történik.
</system_context>

<functional_spec>
## Funkcionális Követelmények

### ### [FR-SZT-01] [Sztornó kezdeményezése]
- **Leírás**: A sztornó tranzakció kezdeményezhető legyen mind a valutaváltó rendszerben, mind pedig a kapcsolódó POS terminálon.
- **Forrás**: sztorno.docx 1. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Felhasználói indítás
- **Kimenet / Visszajelzés**: Sztornó folyamat elindulása
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-02] [Eredeti tranzakció azonosítása]
- **Leírás**: Az eredeti tranzakció lekérése és azonosítása a rendszerben az alábbi adatok alapján: időpont, vásárolt/eladott deviza, eredeti árfolyam és összeg.
- **Forrás**: sztorno.docx 1. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Tranzakcióazonosító vagy keresési paraméterek
- **Kimenet / Visszajelzés**: Megtalált tranzakció adatai
- **Validációk és Kényszerek**: Csak létező, még nem sztornózott tranzakció választható ki.

### ### [FR-SZT-03] [Sztornó alapértelmezett végrehajtása]
- **Leírás**: Sztornó végrehajtásakor a visszafizetés az eredeti tranzakció adatai szerint történik, ha nincs rögzített eltérő árfolyam.
- **Forrás**: sztorno.docx 1. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Eredeti tranzakció adatai
- **Kimenet / Visszajelzés**: Sztornó bejegyzés és egyező összegű visszafizetés
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-04] [NAV felé történő automatikus sztornó]
- **Leírás**: NAV felé történő sztornó kezelése: a sztornó bizonylat kinyomtatása az online pénztárgép driverén keresztül történik, amely a kinyomtatással egyidejűleg automatikusan beküldi a sztornó adatokat a NAV-hoz.
- **Forrás**: sztorno.docx 1. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client (pénztárgép interfész)
- **Bemenő adatok**: Tranzakció sztornózása
- **Kimenet / Visszajelzés**: Sikeres pénztárgép sztornó jelzés
- **Validációk és Kényszerek**: A pénztárgép driver visszajelzését ("A NAV BIZONYLAT RENDBEN KINYOMODOTT ?") meg kell várni a tranzakció lezárásához.

### ### [FR-SZT-05] [Napi sztornó számláló]
- **Leírás**: A rendszer automatikusan számolja és nyilvántartja a pénztáros által az adott nap folyamán végrehajtott sztornó tranzakciók számát.
- **Forrás**: sztorno.docx 2. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: backend
- **Bemenő adatok**: Sztornó bejegyzés rögzítése
- **Kimenet / Visszajelzés**: Napi számláló növelése
- **Validációk és Kényszerek**: A számláló minden nap éjfélkor nullázódik.

### ### [FR-SZT-06] [Sztornó tiltás és engedélykérés]
- **Leírás**: A napon belüli 3. sikeres jelszó nélküli sztornó után minden újabb (4. és további) sztornó kísérlet esetén a rendszer zárolja a folyamatot, és a képernyőn közvetlenül megnyíló párbeszédablakban kéri a Supervisor jelszót a jóváhagyáshoz.
- **Forrás**: sztorno.docx 2. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: backend / penztar-client
- **Bemenő adatok**: Sztornó kezdeményezés, ha napi számláló >= 3
- **Kimenet / Visszajelzés**: Jelszóbekérő dialógus ablak a képernyőn
- **Validációk és Kényszerek**: Helyes Supervisor jelszó megadása nélkül a tranzakció nem menthető.

### ### [FR-SZT-07] [Supervisor közvetlen jóváhagyása]
- **Leírás**: A 4. sztornótól kezdve a Supervisor közvetlenül a pénztáros képernyőjén lévő jelszóbekérő promptban adja meg a jelszavát. Nincs szükség távoli értesítési csatornára (e-mail/SMS/push).
- **Forrás**: sztorno.docx 2. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Supervisor jelszó
- **Kimenet / Visszajelzés**: Jelszó validációja és jóváhagyás
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-08] [Engedély bírálata és zárolás]
- **Leírás**: A Supervisor a jelszó helyes megadásával oldja fel a tranzakciót. Elutasítás vagy hibás jelszó esetén a sztornó blokkolva marad.
- **Forrás**: sztorno.docx 2. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: backend / penztar-client
- **Bemenő adatok**: Jelszó egyezése
- **Kimenet / Visszajelzés**: Tranzakció feloldása vagy végleges elutasítása
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-09] [Aktuális árfolyamok lekérése]
- **Leírás**: A rendszer a sztornó pillanatában letölti az aktuális árfolyamokat a szerverről. Ha a hálózat offline, a Központi Értéktár telefonon diktálja le a napi elszámoló árfolyamot, amelyet a pénztáros manuálisan rögzít a rendszerbe (ez a művelet Supervisor jelszót igényel, és ilyenkor a sávos árfolyamok ki vannak kapcsolva, csak fix flat árfolyam alkalmazható). Online kapcsolat helyreállásakor a manuális árfolyam automatikusan felülíródik.
- **Forrás**: sztorno.docx 3. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Eredeti tranzakció valutája
- **Kimenet / Visszajelzés**: Aktuális és eredeti árfolyam összehasonlító nézet
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-10] [Árfolyam-különbség rögzítése]
- **Leírás**: Amennyiben a sztornó pillanatában érvényes aktuális árfolyam eltér az eredeti tranzakció árfolyamától, a rendszernek automatikusan ki kell számolnia és rögzítenie kell az árfolyam-különbséget.
- **Forrás**: sztorno.docx 3. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: backend
- **Bemenő adatok**: Eredeti árfolyam, aktuális árfolyam, összeg
- **Kimenet / Visszajelzés**: Árfolyam-különbség érték mentése
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-11] [Figyelmeztetés eltérésre és újraszámolás]
- **Leírás**: A rendszer figyelmezteti a pénztárost az árfolyam-eltérésről, és automatikusan kiszámítja a visszatérítendő összeget az aktuális árfolyam alapján.
- **Forrás**: sztorno.docx 3. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Árfolyam-eltérés megléte
- **Kimenet / Visszajelzés**: Figyelmeztető üzenet és az új számított visszatérítendő összeg
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-12] [Új árfolyam szerinti visszatérítés]
- **Leírás**: Eltérő árfolyamú sztornónál a visszatérítés összege az új (aktuális) árfolyam szerint kerül kiszámításra és kifizetésre.
- **Forrás**: sztorno.docx 3. szakasz
- **Prio**: Közepes
- **Csomag/Komponens**: backend
- **Bemenő adatok**: Újraszámított összeg
- **Kimenet / Visszajelzés**: Kifizetendő összeg rögzítése
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-13] [Visszatérítési módok]
- **Leírás**: A visszatérítés módjának meg kell egyeznie az eredeti tranzakció módjával. Ha az eredeti tranzakció készpénzes volt, a visszatérítés készpénzben történik. Ha kártyás (POS) volt, akkor a POS terminálon kell a visszahívást indítani és a kártyára visszatéríteni a pénzt.
- **Forrás**: sztorno.docx 3. szakasz
- **Prio**: Közepes
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Kiválasztott fizetési mód
- **Kimenet / Visszajelzés**: Kifizetési parancs küldése a fióknak / terminálnak
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-14] [POS kártyás tranzakció visszahívás]
- **Leírás**: POS terminálon végrehajtott kártyás tranzakció visszahívása az eredeti adatokkal (árfolyam, fizetett összeg).
- **Forrás**: sztorno.docx 4. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: POS tranzakció adatai
- **Kimenet / Visszajelzés**: POS terminál sztornó parancs futtatása
- **Validációk és Kényszerek**: Meggyőződni a POS terminál sikeres tranzakció-visszavonás válaszáról.

### ### [FR-SZT-15] [POS eltérő árfolyam kezelés]
- **Leírás**: POS sztornó végrehajtása az eredeti tranzakció adatai szerint, vagy eltérő árfolyam esetén a 3. szakasz szerinti eltérő árfolyamú kalkuláció alkalmazásával.
- **Forrás**: sztorno.docx 4. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: POS tranzakció + aktuális árfolyamok
- **Kimenet / Visszajelzés**: Eltérő összegű visszatérítés kártyára
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-16] [Sztornó bizonylat generálása]
- **Leírás**: Sztornó bizonylat automatikus előállítása a rendszerben, mely tartalmazza: eredeti tranzakció adatai (összeg, deviza, árfolyam), sztornó időpontja, alkalmazott árfolyam (ha eltér), és az árfolyam-különbség összege.
- **Forrás**: sztorno.docx 5. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Sztornózott tranzakció adatai
- **Kimenet / Visszajelzés**: Sztornó bizonylat objektum
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-17] [Sztornó bizonylat nyomtatása]
- **Leírás**: A sztornó bizonylat fizikai nyomtatása a visszatérítés pontos összegével.
- **Forrás**: sztorno.docx 5. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Bizonylat adatai
- **Kimenet / Visszajelzés**: Nyomtatási parancs a bizonylatnyomtatónak
- **Validációk és Kényszerek**: N/A

### ### [FR-SZT-18] [Sorszámozott archiválás]
- **Leírás**: A sztornó bizonylatok folyamatos, sorszám alapú nyilvántartása és archiválása az adatbázisban.
- **Forrás**: sztorno.docx 5. szakasz
- **Prio**: Magas
- **Csomag/Komponens**: backend
- **Bemenő adatok**: Generált bizonylat
- **Kimenet / Visszajelzés**: Sorszámozott bejegyzés az archívumban
- **Validációk és Kényszerek**: A sorszámoknak hézagmentesnek kell lenniük.

### ### [FR-SZT-19] [Készletmozgások sztornója az új készletpolitika alapján]
- **Leírás**: A sztornózás (reversal) során a készlet-egyenlegek korrekciójának szigorúan illeszkednie kell a 2026-06-02-i audit szerinti új készletpolitikához:
  - Vételi (Buy) tranzakció visszavonása/sztornója esetén: Sem a deviza, sem a HUF készlet-egyenleg (`cash_balance`) nem változhat (mivel maga a vétel sem módosította azokat).
  - Eladási (Sell) tranzakció visszavonása/sztornója esetén: Kizárólag a tranzakció deviza-egyenlege növekszik vissza a kasszában a visszavont összeggel, a HUF készlet-egyenleg változatlan marad.
  - Ezt a szabályt a backend `TransactionReversalService` és a kliensoldali offline SQLite/sync rétegekben is konzisztensen érvényesíteni kell.
- **Forrás**: 2026-06-02 tranzakciós audit 1. pont
- **Prio**: Magas (P0)
- **Csomag/Komponens**: backend / penztar-client
- **Bemenő adatok**: Visszavonandó eredeti tranzakció típusa és adatai
- **Kimenet / Visszajelzés**: Készletkorrekció lefutása a fenti szabályok szerint
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok

Az adatbázis sémában az alábbi táblák és mezők szükségesek a sztornókezelés támogatásához:

### PostgreSQL
- **Reversal (Sztornó tranzakció)**:
  - `id` (serial, primary key)
  - `original_transaction_id` (int, foreign key -> Transaction, egyedi)
  - `reversal_timestamp` (timestamp, default now())
  - `cashier_id` (int, foreign key -> User)
  - `reversal_rate` (decimal, az alkalmazott aktuális árfolyam)
  - `rate_difference` (decimal, az eredeti és a reversal rate különbsége)
  - `refund_amount` (decimal, a ténylegesen visszatérített összeg)
  - `refund_method` (varchar, pl. 'CASH', 'CARD')
  - `receipt_serial` (varchar, egyedi sorszám az archiváláshoz)
- **DailyReversalCounter (Napi sztornó számláló)**:
  - `cashier_id` (int, primary key)
  - `date` (date, primary key)
  - `reversal_count` (int, default 0)
- **ReversalApproval (Jóváhagyási kérelem)**:
  - `id` (serial, primary key)
  - `reversal_id` (int, foreign key -> Reversal, nullolható amíg nincs mentve)
  - `requested_by` (int, foreign key -> User)
  - `approved_by` (int, foreign key -> User, nullolható)
  - `status` (varchar, pl. 'PENDING', 'APPROVED', 'REJECTED')
  - `request_timestamp` (timestamp, default now())
  - `decision_timestamp` (timestamp)

### SQLite (Offline mirror a kliensen)
- A `DailyReversalCounter` táblát a kliensnek offline módban is vezetnie kell.
- A `Reversal` tranzakciókat offline módban is rögzíteni kell. Ha a Supervisor fizikailag jelen van, a 4. feletti sztornók offline módban is jóváhagyhatók a jelszó helyi beírásával.

### Legacy adatbázis leképezés (Legacy Mappings)
- `BLOKKFEJ` (Sztornózott tranzakciók jelölése a fejléc táblában `STORNO = 2` értékkel)
- `BLOKKTETEL` (Tételszintű sztornó jelölés a tétel táblában `STORNO = 2` értékkel)
- `HARDWARE` (Pénztárgép driver és konfiguráció beolvasása)
- `PENZTAR` (Kassza azonosítás és napi egyenleg tábla)
- `VTEMP` (Sztornó kalkulációk során használt ideiglenes tábla)
</data_structure>

<integration_points>
## Integrációs Pontok
- **NAV (Online Pénztárgép interfész)**:
  - Automatikus sztornó-jelentés beküldése az online pénztárgép driverén keresztül (FR-SZT-04), amely a fizikai nyomtatással egy időben küldi a jelentést.
- **POS Terminál API**:
  - Kártyás tranzakciók visszahívása és visszatérítése a kártyás terminál driveren keresztül (FR-SZT-14).
- **Aktuális árfolyam szolgáltatás**:
  - A sztornó pillanatában érvényes valutaárfolyamok lekérése a központi szerverről (FR-SZT-09). Offline módban a kézi bevitel validálása a Központi Értéktár telefonos diktálása alapján.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
- Olvasd be ezt a specifikációt és a `sztorno.docx` forrásfájlt.
- Tisztázd a jelszóellenőrzési és driver protokollokat.

### Phase 2: Backend (Backend)
- Készítsd el az adatbázis migrációs szkripteket (sztornó, napi számláló, engedélyezés táblák, legacy tábla hivatkozások).
- Implementáld a napi számlálót ellenőrző middleware-t/szolgáltatást.
- Írd meg a helyi Supervisor jelszavas jóváhagyási munkafolyamatot.
- Fejleszd le az árfolyam-különbség és visszatérítés-számítás kalkulációs logikáját.

### Phase 3: Frontend/Client (Frontend/Client)
- Készítsd el a tranzakciókereső és kiválasztó felületet.
- Fejleszd ki az engedélykérő jelszóbekérő dialógust, amely a 4. sztornó indításakor felugrik.
- Építsd be az árfolyam-eltérést vizualizáló figyelmeztetést és a számított visszatérítés kijelzését.
- Integráld a POS terminál visszahívási folyamatát és a sztornó bizonylat nyomtatását.

### Phase 4: Ellenőrzés (Verification)
- **Unit tesztek**: Napi számláló inkrementálása, 3-ról 4-re váltáskor a jelszóbekérő dialógus trigger lefutása.
- **Unit tesztek**: Visszatérítendő összeg helyes kalkulációja azonos és eltérő árfolyamok esetén is.
- **Integrációs tesztek**: A sztornó bizonylat generálása a pontos különbség-összegekkel és a sorszám-folytonosság ellenőrzése.
- **Negatív tesztek**: 4. sztornó végrehajtásának kísérlete jóváhagyó Supervisor jelszó nélkül -> a rendszernek meg kell akadályoznia a mentést.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)
| # | Kérdés | Miért fontos | Mit kell tudni |
|---|---|---|---|
| TBD-1 | A pénztárgép NAV felé történő automatikus sztornó-jelentésének pontos protokollja | NAV-megfelelőség és adatszolgáltatás | **LEZÁRVA**: A storno bizonylatot az online pénztárgép driverén keresztül kell nyomtatni, amely automatikusan beküldi az adatokat. |
| TBD-2 | A pénzügyi vezető értesítésének csatornája (rendszer/e-mail/SMS) | Engedélyezési folyamat késleltetésének minimalizálása | **LEZÁRVA**: Nincs szükség külső értesítési csatornára; a Supervisor helyben írja be a jelszót a kassza képernyőjén. |
| TBD-3 | A pénztáros és pénzügyi vezető konkrét RBAC szerepkör-értékei | Biztonság és jogosultság-kezelés | **LEZÁRVA**: Pénztáros: `ROLE_CASHIER` (jelszó nélkül napi 3 sztornó), Supervisor: `ROLE_SUPERVISOR` (4. sztornótól szükséges a jelszava). |
| TBD-4 | Sztornó/engedélyezés/bizonylat pontos adatmodellje és SQLite mirror mezőkészlete | Helyi tárolás és offline működőképesség | **LEZÁRVA**: Offline üzemmódban is engedélyezett a 4.+ sztornó, ha a Supervisor beírja a jelszót helyben. Legacy leképezések: `BLOKKFEJ`, `BLOKKTETEL` (`STORNO=2`), `HARDWARE`, `PENZTAR`, `VTEMP`. |
| TBD-5 | Az "aktuális árfolyam" pontos forrása sztornózáskor | Pontos elszámolás és visszatérítés | **LEZÁRVA**: Szerverről letöltve. Offline esetén a Központi Értéktár telefonon diktálja, manuális rögzítéshez Supervisor jelszó kell, és sávos helyett flat árfolyamot alkalmaz. |
| TBD-6 | A forrásben "??"/"???"-el jelölt pontok végleges üzleti döntései | Üzleti szabályok tisztázása | **LEZÁRVA**: Új árfolyam esetén az aktuális árfolyammal számolunk. A visszatérítési módnak meg kell egyeznie az eredeti fizetési móddal (kártyásnál POS visszahívás kártyára). |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden funkcionális követelmény (FR-SZT) visszavezethető a `sztorno.docx` forrásfájl megfelelő szakaszára és a verifikált tényekre.
- [x] 0 hallucináció (az üzleti szabályok szigorúan a forrás és a megerősített adatok alapján íródtak).
- [x] Minden nyitott üzleti kérdés és bizonytalanság (?/??/???) feloldásra és rögzítésre került a TBD naplóban.
</verification_checklist>
