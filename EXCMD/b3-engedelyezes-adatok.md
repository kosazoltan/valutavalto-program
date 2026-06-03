<system_context>
# Modul: Tranzakció-engedélyezéshez szükséges adatok

## Kontextus
Egy valutaváltási tranzakció felettesi engedélyezéséhez bemutatott engedélykérő adatlap mezőkészletének rögzítése a forrásdokumentum-minta alapján. A dokumentum célja az engedélyezési folyamat során kötelezően megjelenítendő pénztár, bizonylat, tranzakció és ügyféladatok pontos specifikálása, összevetve az AML és ügyféligazolási szabályokkal.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: Electron kliens (`penztar-client`, `kozponti-client` a felettesi jóváhagyáshoz)
- **Adatbázis**: PostgreSQL (szerver), SQLite offline mirror (kliens)

## Szakterületi Szereplők (Roles)
- **Kasszás / Pénztáros (Cashier)**: Kezdeményezi az engedélykérést a pénztári kliensben, ha a tranzakció engedélyköteles feltételt ér el (RBAC érték: `ROLE_CASHIER`).
- **Supervisor / Fiókvezető (Supervisor)**: A központi vagy helyi felületen elbírálja (jóváhagyja vagy elutasítja) a kérelmet a hitelesítő jelszava megadásával (RBAC érték: `ROLE_SUPERVISOR`).
- **Rendszeradminisztrátor (System Administrator)**: Teljes hozzáféréssel rendelkezik az engedélyezési naplókhoz és konfigurációkhoz (RBAC érték: `ROLE_ADMIN`).

## Hatókör (Scope)
- **IN**:
  - A „Engedély megadása egy tranzakcióhoz" engedélykérő adatlap kötelező mezői:
    - Pénztár-azonosítás (pénztár száma, pénztár neve).
    - Bizonylat adatok (bizonylatszám).
    - Tranzakció értéke (tranzakció összege HUF-ban) + valuta-sorok részletesen (valuta összege, valutanem, árfolyam, forintérték).
    - Ügyfél-azonosító adatok (név, anyja neve, születési idő, születési hely, lakcím, okmány típus, okmány szám, állampolgárság, tartózkodási hely).
    - Engedélyező személy azonosítója.
- **OUT**:
  - MNB vagy NAV közvetlen valós idejű engedélyezési folyamata (az engedélykérő csak belső tranzakciós jóváhagyásra és AML-megfelelőségre szolgál).
</system_context>

<functional_spec>
## Funkcionális Követelmények

### ### [FR-AUTH-01] [Pénztár-azonosítás engedélykérőn]
- **Leírás**: Az engedélykérő adatlapon kötelezően meg kell jelennie a kezdeményező pénztár számának és nevének (pl. „Penztar szama: 105", „Penztar neve: <FIOK_NEV>").
- **Forrás**: Engedélyezéshez szükséges adatok.docx
- **Prio**: Must
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Aktuális fiók adatai (`fiok_kod`, `fiok_nev`)
- **Kimenet / Visszajelzés**: Fiókadatok megjelenítése a felületen
- **Validációk és Kényszerek**: N/A

### ### [FR-AUTH-02] [Bizonylatszám megjelenítése]
- **Leírás**: Az engedélykérő adatlapon szerepelnie kell az engedélyezés alatt álló tranzakció bizonylatszámának (pl. „Bizonylatszam: <BIZONYLAT_SZAM>").
- **Forrás**: Engedélyezéshez szükséges adatok.docx
- **Prio**: Must
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Generált bizonylatszám (`VTEMP` vagy `BLOKKFEJ` alapján)
- **Kimenet / Visszajelzés**: Bizonylatszám mező
- **Validációk és Kényszerek**: N/A

### ### [FR-AUTH-03] [Tranzakció teljes forintértéke]
- **Leírás**: Meg kell jeleníteni a tranzakció összesített forintértékét (pl. „Tranz.osszege: 10088410").
- **Forrás**: Engedélyezéshez szükséges adatok.docx
- **Prio**: Must
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Számított tranzakciós összeg HUF-ban
- **Kimenet / Visszajelzés**: Összeg mező HUF-ban
- **Validációk és Kényszerek**: N/A

### ### [FR-AUTH-04] [Valuta-soronkénti bontás]
- **Leírás**: Az engedélykérőn meg kell jeleníteni a tranzakció valutás tételeit soronként részletezve: valuta összege, valutaneme, az alkalmazott árfolyam és a számított forintérték (pl. „1. valuta: 26,000 EUR / 1. arfoly: 38840 / 1. ertek: 10,098,400 Ft").
- **Forrás**: Engedélyezéshez szükséges adatok.docx
- **Prio**: Must
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Valuta tételek listája (`BLOKKTETEL`)
- **Kimenet / Visszajelzés**: Részletező táblázat
- **Validációk és Kényszerek**: N/A

### ### [FR-AUTH-05] [Ügyfél-azonosító adatok]
- **Leírás**: Az engedélykérő adatlapon kötelezően meg kell jeleníteni az ügyfél alábbi azonosító adatait: név, anyja neve, születési idő, születési hely, lakcím, okmány típusa, okmány száma, állampolgárság és tartózkodási hely.
- **Forrás**: Engedélyezéshez szükséges adatok.docx
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Ügyfél törzs- és okmányadatok (`UGYFEL` tábla)
- **Kimenet / Visszajelzés**: Ügyféladatok adatlapja
- **Validációk és Kényszerek**: Az adatoknak meg kell egyezniük a bemutatott és beolvasott okmányok adataival.

### ### [FR-AUTH-06] [Engedélyező személy rögzítése]
- **Leírás**: Az engedélyezési döntést hozó felettes (engedélyező) nevét / azonosítóját rögzíteni és tárolni kell a bizonylaton (pl. „engedelyezo: <NEV>").
- **Forrás**: Engedélyezéshez szükséges adatok.docx
- **Prio**: Must
- **Csomag/Komponens**: penztar-client / backend
- **Bemenő adatok**: Jóváhagyó supervisor azonosítója
- **Kimenet / Visszajelzés**: Engedélyező mező kitöltése a bizonylaton
- **Validációk és Kényszerek**: Csak érvényes supervisor kóddal/jelszóval hagyható jóvá.

### ### [FR-AUTH-07] [Kétlépcsős Google OAuth belépés (személyes bejelentkezés)]
- **Leírás**: A megosztott/intézményi Google fiókokkal történő bejelentkezésnél (pl. `szeged.ebc@gmail.com` e-mail cím, ami a `G_SZEGED_ET` technikai workerhez van rendelve) a rendszernek kétlépcsős bejelentkezési folyamatot kell kikényszerítenie:
  - 1. lépés: Sikeres Google OAuth hitelesítés.
  - 2. lépés: A rendszer lekéri a Google fiókhoz tartozó iroda/értéktár (`branchId`) aktív személyes dolgozóinak listáját (a `Worker` táblából), majd a felhasználó kiválasztja saját magát és megadja a személyes jelszavát.
  - A személyes jelszót a backend a `Worker.passwordHash` alapján BCrypt-tel ellenőrzi. 5 sikertelen jelszó-próbálkozás után a személyes dolgozó fiókját 15 percre le kell tiltani (in-memory lockout).
  - Sikeres hitelesítés után a végleges alkalmazás-JWT session a személyes dolgozó azonosítójával (`workerId`), jogosultságával (`ertektar` vagy `penztar` role) és saját nevével jön létre az auditálhatóság érdekében.
- **Forrás**: 2026-06-02 Google OAuth audit
- **Prio**: Magas (P0)
- **Csomag/Komponens**: backend / penztar-client
- **Bemenő adatok**: Google ID token, majd kiválasztott dolgozó azonosító és jelszó
- **Kimenet / Visszajelzés**: Személyre szabott JWT token és session

### ### [FR-AUTH-08] [Állampolgárság kereshető szótár dropdown]
- **Leírás**: Az ügyfél azonosító panelen (`CustomerPanel.tsx`) a korábbi három fix állampolgárság-opció (`Magyar`, `EU-állampolgárság`, `Egyéb`) helyett a rendszerszintű szótárból kell betölteni az adatokat. A frontendnek le kell kérnie az állampolgárságokat a `dictionaryApi.getByCategory('NATIONALITY')` API-n keresztül, és kereshető, autocomplete-képes választóként (select/dropdown) kell megjelenítenie azokat a felületen.
- **Forrás**: 2026-06-02 tranzakciós audit 3. pont
- **Prio**: Magas (P1)
- **Csomag/Komponens**: frontend-react
- **Bemenő adatok**: Szótár lekérdezés eredménye
- **Kimenet / Visszajelzés**: Kereshető állampolgárság választó
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok

Az engedélyezési adatok mentéséhez használt PostgreSQL és SQLite sémák:

### PostgreSQL
- **TransactionApproval (Tranzakciós engedély - AML_ENGEDELYEZES)**:
  - `id` (serial, primary key)
  - `transaction_id` (int) -- Tranzakció azonosító (legacy: `BLOKKFEJ` sorszám)
  - `cashier_id` (int, a kezdeményező pénztáros kódja)
  - `receipt_number` (varchar(50), bizonylatszám, pl. 'V00412')
  - `total_amount_huf` (decimal, tranzakció forintértéke)
  - `customer_name` (varchar(100))
  - `customer_mother_name` (varchar(100))
  - `customer_birth_date` (date)
  - `customer_birth_place` (varchar(100))
  - `customer_address` (varchar(200))
  - `customer_doc_type` (varchar(50))
  - `customer_doc_number` (varchar(50))
  - `customer_citizenship` (varchar(50))
  - `customer_residence` (varchar(100), nullolható)
  - `approver_user_id` (int, engedélyező supervisor azonosítója)
  - `approval_status` (varchar(20), pl. 'PENDING', 'APPROVED', 'REJECTED')
  - `created_at` (timestamp, default now())
- **ApprovalItems (Engedélyezett valutatételek - AML_ENGEDELY_TETEL)**:
  - `id` (serial, primary key)
  - `approval_id` (foreign key -> TransactionApproval)
  - `item_index` (int)
  - `amount` (decimal)
  - `currency_code` (varchar(3))
  - `exchange_rate` (decimal)
  - `value_huf` (decimal)

### SQLite (Offline mirror a kliensen)
- Offline működés esetén, ha az online kapcsolat megszakad, a 10 millió HUF feletti Source of Funds nyilatkozatot a pénztáros köteles helyben, papír alapon kitöltetni, és a Supervisor helyi jelszavas jóváhagyásával a tranzakciót rögzíteni.
- Az SQLite mirror a helyi `TransactionApproval` táblában tárolja a jóváhagyás tényét `OFFLINE_APPROVED` státusszal. A hálózati kapcsolat helyreállásakor a szinkronizációs modul soron kívül feltölti az engedélykéréseket a központi szerverre.
- A 4. és azt követő napi sztornó tranzakciókat a helyi kliensen is Supervisor jelszó beírásával kell engedélyezni.
</data_structure>

<integration_points>
## Integrációs Pontok
- **Ügyfél-nyilvántartó modul (belső)**:
  - Ügyféladatok beolvasása az engedélykérő automatikus kitöltéséhez (FR-AUTH-05) a legacy `UGYFEL` táblából.
- **NAV Online Kassza Integráció**:
  - A sztornó engedélyezése után az online pénztárgép driveren keresztül a nyugta automatikusan elküldésre kerül a NAV szerverére.
- **Központi jóváhagyó rendszer (belső REST API)**:
  - WebSocket vagy HTTP push értesítés küldése a központi supervisor felületre (`kozponti-client`) új engedélykérés érkezésekor.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
- Olvasd el a tranzakció- és ügyfél-adatmodelleket.
- Tisztázd a felettesi engedélyt kiváltó feltételeket.

### Phase 2: Backend (Backend)
- Készítsd el a PostgreSQL adatbázis sémát.
- Implementáld az engedélyezési munkafolyamat REST API-t (jóváhagyás, elutasítás, naplózás).

### Phase 3: Frontend/Client (Frontend/Client)
- Készítsd el a pénztári kliensben megjelenő jóváhagyás-kérő panelt az ügyfél- és tranzakciós adatokkal.
- Fejleszd le a supervisor jóváhagyási ablakát.

### Phase 4: Verification (Verification)
- **Integrációs tesztek**: Szimulálj egy tranzakciót (Pénztár 105, EUR 26 000 @ 38840 = 10 098 400 Ft) és ellenőrizd, hogy az adatok helyesen mentődnek-e a táblákba és a logba.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)
| # | Kérdés | Miért fontos | Státusz / Megoldás |
|---|---|---|---|
| TBD-1 | Mi váltja ki konkrétan a felettesi engedélyezést? | Folyamat-indítás és validáció | **LEZÁRVA**: A felettesi engedélyezést kiváltó okok: 1. A tranzakció forintértéke eléri vagy meghaladja a 10 millió HUF összeghatárt (AML nyilatkozat kötelező). 2. A pénztáros kézzel írja felül a napi árfolyamot. 3. Pénztáranként a 4. és minden további napi sztornó tranzakció rögzítése. |
| TBD-2 | Mely szerepkörök/RBAC jogosultak az engedély megadására? | Rendszerbiztonság és hozzáférés | **LEZÁRVA**: A tranzakció jóváhagyására a Supervisor (`ROLE_SUPERVISOR`) vagy a Rendszeradminisztrátor (`ROLE_ADMIN`) jogosult. A pénztáros (`ROLE_CASHIER`) kezdeményező. |
| TBD-3 | Az engedélykérő adatlap fizikai megjelenése (képernyő dialógus, nyomtatott PDF, vagy mindkettő)? | UI és kimenet tervezés | **LEZÁRVA**: Mindkettő. A pénztári programban egy felugró dialógus panel jelenik meg, az engedély megadása után pedig a tranzakcióról a Jogcím-nyilatkozat automatikusan kinyomtatásra kerül az ügyfél aláírásához. |
| TBD-4 | Az ügyfél "tartózkodási hely" mezője a mintában üresen szerepelt. Kötelező-e a kitöltése? | Adatvalidáció | **LEZÁRVA**: Opcionális mező. Csak külföldi állampolgárok esetében kötelező kitölteni, ha nincs magyarországi állandó lakcímük, de tartózkodnak az országban. Magyar állampolgároknál üresen maradhat. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden mező és funkcionális követelmény (FR-AUTH) visszakövethető az engedélyezési docx forrásmintára.
- [x] 0 hallucináció (csak a mintában szereplő konkrét mezők és elrendezések szerepelnek).
- [x] Minden nyitott kérdés (TBD-1..TBD-4) pontosan rögzítésre került.
</verification_checklist>
