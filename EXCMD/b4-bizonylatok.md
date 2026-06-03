---
title: "Bizonylatok (forint átadás/átvétel, KKTG, pénztári bizonylatok)"
modul: b4-bizonylatok
kategoria: bizonylatok
alkalmazas: penztar-client
szerepokor:
  - ROLE_CASHIER
  - ROLE_TREASURER
forrasok:
  - "Felmérés/.../Bizonylatok/KKTG átadás és átvétel.jpg"
  - "Felmérés/.../Bizonylatok/pénztári átvétel.jpeg"
  - "Felmérés/.../Bizonylatok/Pénztári átadás 2.jpg"
  - "Felmérés/.../Bizonylatok/Áfolyam nyomtatás _ Pénztárosi nyilatkozat.jpg"
prio: Magas
utolso_frissites: "2026-06-02"
media_eredetu: true
---

# Modul: Kliens-oldali és Értéktári bizonylatok (bizonylat-képek alapján)

<system_context>
## Rendszerkontextus és Háttér
A valutaváltó program napi működése során keletkező bizonylatok, nyilatkozatok és elszámolások nyomtatási elrendezésének leírása az alábbi forrásképek alapján:
- `Kezelési díj bizonylatok.jpg` (Átvételi és átadási bizonylat)
- `KKTG bizonylat.jpg` (Költségek elszámolása)
- `Media elszámolás bizonylatok.jpg` (Media kiadások)
- `Valuta bizonylatok.jpg` (Vételi és eladási bizonylat)
- `valuta eladási bizonylat (2).jpg` (Alternatív eladási sablon)
- `valuta vételi bizonylat.jpg` (Alternatív vételi sablon)
- `Pénztári átadás átvétel bizonylatok.jpg` (Pénztárak közötti készletmozgás)
- `Jogcím nyilatkozat.jpg` (Pénzeszközök forrásának nyilatkozata)
- `Mégsem bizonylat.jpg` (Megszakított tranzakciók bizonylata)

### Szerepkörök (Roles)
- **Pénztáros** (RBAC: `ROLE_CASHIER`): Tranzakció rögzítése, bizonylat generálása és kinyomtatása. A bizonylatokon aláíróként ("penztaros" vagy "kifizeto/atvevo") szerepel.
- **Supervisor / Pénztárvezető** (RBAC: `ROLE_SUPERVISOR`): Sztornózások, limit feletti kifizetések és 50M HUF feletti kiemelt AML jogcímek jóváhagyása.
- **Ügyfél**: A bizonylat aláírója ("ugyfel" vagy "nyilatkozo").

### Hatókör (Scope)
#### IN
- A 18 különböző bizonylat- és nyilatkozat-típus logikai elrendezése, mezői és nyomtatott jogi záradékai.
- Devizanemek kezelése (HUF, EUR, USD stb.) és azok formázása.
- Pénzeszközök forrására vonatkozó jogcímkódok (GH, MN, IN, OR, AJ, NY, HI) és a kiemelt AML szabályok (50M HUF feletti okiratok, banki bizonylatok életkora).
- Pénztárközi és kezelési költség átadás-átvételeknél a plomba (seal) számának kötelező rögzítése és nyomtatása.
- Kliensoldali offline sorszámozás az SQLite adatbázisban, majd Postgres szinkronizáció.

#### OUT
- A nyomtató fizikai driver-beállításai (csak az ESC/POS szalaggenerálás és a standard papírelrendezés specifikált).
- A bizonylatképeken szereplő kézzel írt vagy javított számok és jelölések (ezek illusztratív jellegűek, nem képezik az adatmodell részét).

### Technológiai verem (Tech Stack)
- Frontend: React 19 + TypeScript (szalagnézet és bizonylat-generálás).
- Backend: Java 21 + Spring Boot 4 (PDF export és bizonylatszám-szolgáltatás).
- Local DB: SQLite (offline bizonylat-adatok és helyi sorszámok).
- Global DB: PostgreSQL (szinkronizált bizonylattár).
- Nyomtatás: ESC/POS és A4 PDF bizonylat-nyomtatás.
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-1: VALUTA VÉTELI bizonylat struktúrája
- **Leírás**: A valuta vételi bizonylatnak tartalmaznia kell: cégfejléc, egyedi bizonylatszám, dátum, ügyfél adatai (név, cím, okmányszám), vásárolt deviza összege és valutaneme, alkalmazott árfolyam, kifizetett forintösszeg, jutalék/kezelési költség, NAV tranzakciós azonosító, jogi záradék, pénztáros és ügyfél aláírás helye.
- **Forrás**: `Valuta bizonylatok.jpg` / `valuta vételi bizonylat.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client` / backend
- **Validációk és Kényszerek**: Az elszámolt forintösszegnek meg kell egyeznie a deviza és az árfolyam szorzatának kerekített értékével.

### FR-2: VALUTA ELADÁSI bizonylat struktúrája
- **Leírás**: A valuta eladási bizonylat tartalmazza: cégfejléc, bizonylatszám, dátum, ügyféladatok, eladott deviza összege, alkalmazott eladási árfolyam, átvett forintösszeg, kezelési díj, aláírás mezők és jogi nyilatkozatok.
- **Forrás**: `Valuta bizonylatok.jpg` / `valuta eladási bizonylat (2).jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client` / backend

### FR-3: VALUTA ELADÁSI bizonylat (2) - egyszerűsített sablon
- **Leírás**: Alternatív egyszerűsített eladási sablon támogatása, ahol a jutalékok és kezelési költségek összevontan jelennek meg a nettó eladási árfolyamban.
- **Forrás**: `valuta eladási bizonylat (2).jpg`
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`

### FR-4: VALUTA VÉTELI bizonylat (2) - egyszerűsített sablon
- **Leírás**: Alternatív egyszerűsített vételi sablon támogatása a gyorsított tranzakciókhoz.
- **Forrás**: `valuta vételi bizonylat.jpg`
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`

### FR-5: Valuta vételi és eladási bizonylat (Összevont tranzakciós lap)
- **Leírás**: Olyan összevont bizonylat nyomtatása, amely egyazon ügyféllátogatás során tartalmaz vételi és eladási tételeket is, elkülönített összesítőkkel.
- **Forrás**: `Valuta bizonylatok.jpg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client` / backend

### FR-6: Valuta vételi és eladási bizonylat (2)
- **Leírás**: Összevont bizonylat másodlagos formátuma a kiemelt ügyfelek egyedi (alkudott) árfolyamainak részletezésével.
- **Forrás**: `Valuta bizonylatok.jpg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`

### FR-7: JOGCIM NYILATKOZAT külön lap
- **Leírás**: A Pmt. (AML) jogszabályoknak megfelelő nyilatkozat, melyet az ügyfél tölt ki a pénzeszközök forrásáról. Külön álló A4-es dokumentumként nyomtatandó.
- **Forrás**: `Jogcím nyilatkozat.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`

### FR-8: JOGCIM NYILATKOZAT külön bizonylat
- **Leírás**: A jogcím nyilatkozathoz kapcsolódó bizonylat, amely rögzíti a nyilatkozat egyedi azonosítóját, az ügyfél aláírását és a választott forráskódokat:
  - `GH`: Gazdasági tevékenység
  - `MN`: Munkabér/megtakarítás
  - `IN`: Ingatlan/ingóság értékesítés
  - `OR`: Örökség
  - `AJ`: Ajándék
  - `NY`: Nyeremény
  - `HI`: Hitel/kölcsön
  - **Kiemelt AML Szabályok**:
    - Ha az ügylet forint ellenértéke eléri vagy meghaladja az 50 millió HUF-ot, a pénzeszközök forrásaként kizárólag ügyvéd vagy közjegyző által ellenjegyzett "teljes bizonyító erejű magánokirat" fogadható el. Két tanúval ellátott magánnyilatkozat elfogadása szigorúan tilos. A rendszernek ezt a dokumentumot és adatait (kiállító, dátum) rögzítenie kell.
    - Ha az ügyfél banki kifizetési bizonylatot nyújt be, az nem lehet 3 évnél régebbi. A 3 évnél régebbi slips-eket a rendszer elutasítja.
- **Forrás**: `Jogcím nyilatkozat.jpg` / `Hang 003_sd.m4a.txt` átirat 5-7., 30-36. sorok
- **Prio**: M
- **Csomag/Komponens**: `penztar-client` / backend
- **Validációk és Kényszerek**: 50M HUF felett a magánokirat adatainak kitöltése kötelező, két tanús nyilatkozat letiltva. Banki bizonylat korlátozása maximum 1095 napra.

### FR-9: JOGCIM NYILATKOZAT külön bizonylat (2)
- **Leírás**: A jogcím nyilatkozat másodpéldánya az archívum számára, amely tartalmazza a pénztáros ellenőrző aláírását is.
- **Forrás**: `Jogcím nyilatkozat.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`

### FR-10: Kezelési költség ÁTVÉTELI bizonylat (KKTG)
- **Leírás**: Kezelési költségek átvételét igazoló bizonylat, mely tartalmazza az átvett összeget (HUF), a tranzakció dátumát, az átvevő nevét, valamint a biztonsági plomba (seal) számát.
- **Forrás**: `KKTG bizonylat.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Validációk és Kényszerek**: A plomba-szám formátuma kötött (pl. `PLB123456`), megadása kötelező.

### FR-11: Kezelési költség ÁTADÁSI bizonylat (KKTG)
- **Leírás**: Kezelési költség átadási bizonylat, mely tartalmazza az átadott összeget (HUF), dátumot, az átadó és az átvevő aláírását, valamint a biztonsági plomba számát.
- **Forrás**: `KKTG bizonylat.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`

### FR-12: Media kiadások elszámolás bizonylat
- **Leírás**: Marketing és média kiadások (pl. újsághirdetés, szórólap) elszámolására szolgáló bizonylat, mely tartalmazza a kiadás összegét, a számla számát, a költséghelyet és a jóváhagyó aláírását.
- **Forrás**: `Media elszámolás bizonylatok.jpg`
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`

### FR-13: Pénztári átadás bizonylat
- **Leírás**: Pénztárak közötti vagy a főértéktár felé történő készpénz-átadás bizonylata (devizanemenkénti bontásban, címletjegyzékkel, átadó és átvevő aláírásával, valamint a szállítási plomba számával).
- **Forrás**: `Pénztári átadás átvétel bizonylatok.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client` / backend

### FR-14: Pénztári átvétel bizonylat
- **Leírás**: Pénztárak közötti vagy a főértéktártól történő készpénz-átvétel bizonylata (devizanemenként, címletjegyzékkel, átvevő aláírásával és a plomba számával).
- **Forrás**: `Pénztári átadás átvétel bizonylatok.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client` / backend

### FR-15: MÉGSEM bizonylat (Megszakított tranzakció)
- **Leírás**: Ha egy tranzakciót a rögzítés közben vagy a nyomtatás előtt megszakítanak (mégsem gomb), a rendszernek egy "MEGSEM BIZONYLAT"-ot kell generálnia és nyomtatnia a rögzített adatokkal és a megszakítás okával, elkerülve a bizonylatszámok kiesését.
- **Forrás**: `Mégsem bizonylat.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client` / backend
- **Validációk és Kényszerek**: A bizonylaton nagy méretben, keresztben a "MEGSEM" feliratnak kell szerepelnie.

### FR-16: MÉGSEM bizonylat (2) - másodpéldány
- **Leírás**: A megszakított tranzakció bizonylatának másodpéldánya a napi elszámoláshoz csatolva.
- **Forrás**: `Mégsem bizonylat.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma (PostgreSQL és SQLite mirror)

### PostgreSQL és SQLite táblák:

#### 1. `receipts`
Minden kiadott bizonylat közös metaadat-táblája.
- `id` (SERIAL / INTEGER PRIMARY KEY AUTOINCREMENT)
- `receipt_number` (VARCHAR(50) UNIQUE NOT NULL) -- Pl. V00412 vagy E00982
- `receipt_type` (VARCHAR(30) NOT NULL) -- VALUTA_VETEL, VALUTA_ELADAS, JOGCIM_NYILATKOZAT, KKTG_ATADAS, KKTG_ATVETEL, PTAR_ATADAS, PTAR_ATVETEL, MEGSEM
- `created_at` (TIMESTAMP NOT NULL DEFAULT NOW())
- `cashier_id` (INTEGER NOT NULL)
- `branch_id` (INTEGER NOT NULL)
- `plomba_szama` (VARCHAR(50)) -- Csak átadás-átvételi és KKTG bizonylatoknál
- `storno_receipt_id` (INTEGER REFERENCES receipts(id)) -- Ha sztornózva lett, a sztornó bizonylat ID-ja

#### 2. `receipt_items`
A bizonylatokon szereplő tételek devizánként.
- `id` (SERIAL / INTEGER PRIMARY KEY AUTOINCREMENT)
- `receipt_id` (INTEGER REFERENCES receipts(id) ON DELETE CASCADE)
- `currency_code` (VARCHAR(3) NOT NULL)
- `amount` (NUMERIC(15, 4) NOT NULL)
- `exchange_rate` (NUMERIC(12, 4) NOT NULL)
- `huf_value` (NUMERIC(15, 2) NOT NULL)

#### 3. `aml_declarations`
A jogcím nyilatkozatok adatai.
- `id` (SERIAL / INTEGER PRIMARY KEY AUTOINCREMENT)
- `receipt_id` (INTEGER REFERENCES receipts(id) ON DELETE CASCADE)
- `customer_name` (VARCHAR(100) NOT NULL)
- `source_code` (VARCHAR(5) NOT NULL) -- GH, MN, IN, OR, AJ, NY, HI
- `declaration_text` (TEXT NOT NULL)
- `is_large_amount` (BOOLEAN DEFAULT FALSE) -- True, ha >= 50M HUF
- `proof_type` (VARCHAR(50)) -- 'MAGANOKIRAT', 'BANK_SZLIP'
- `proof_date` (DATE)
- `proof_verifier` (VARCHAR(100)) -- Ügyvéd/közjegyző neve

### Legacy adatbázis leképezés (Legacy Mappings)
- `BLOKKFEJ` (Legacy bizonylat fejléc adatok: bizonylatszám, dátum, ügyfélszám, deviza, árfolyam)
- `BLOKKTETEL` (Legacy bizonylat tétel adatok: valutanem, összeg, árfolyam, forintérték)
- `ADATLAP` (Pénztári adatlap és belső átadások)
- `CIMT` (Címlet darabszámok bizonylatonként)
- `HARDWARE` (Online pénztárgép és nyomtató konfigurációk)
</data_structure>

<integration_points>
## Integrációs Pontok
- **NAV Online Pénztárgép driver**: A vételi, eladási és sztornó bizonylatok nyomtatásakor a driver automatikusan küldi a kötelező adatokat a NAV szerverére.
- **Kliensoldali Nyomtatásvezérlő**: React alapú nyomtatási sablonok renderelése monospaced formátumban a szalagnyomtatókhoz.
- **Secure Sync Agent outbox queue**: Biztosítja, hogy offline módban létrejött bizonylatok sorszámai és adatai a hálózat helyreállásakor szinkronizálásra kerüljenek a PostgreSQL központi szerverre.
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- Térképezd fel az SQLite és Postgres migrációs szkripteket a `receipts`, `receipt_items` és `aml_declarations` táblákhoz.
- Importáld a bizonylatokon szereplő statikus záradékszövegeket.

### Fázis 2: Backend megvalósítás
- Készítsd el a bizonylat generálási és tárolási API végpontokat.
- Valósítsd meg az offline sorszám-ütközés elkerülési stratégiát (kliensoldali SQLite prefix használatával, ami szinkronizációkor feloldódik).
- Építsd be a plomba-szám validációkat és a Pmt. 50M HUF feletti szigorított forrásigazolási és szlip-életkori (3 év) szabályokat.

### Fázis 3: Frontend megvalósítás
- Készítsd el az Electron `penztar-client` felületén a bizonylatok előnézetét.
- Valósítsd meg a "MÉGSEM" bizonylat generálását, ha a felhasználó megszakítja a valutaváltást.

### Fázis 4: Verifikáció
- Unit tesztekkel ellenőrizd az offline sorszám-generátor konzisztenciáját és a szinkronizációs ütközések feloldását.
- Unit tesztekkel ellenőrizd a plomba-szám validációját.
- Ellenőrizd a Pmt. 50M HUF feletti okirat-ellenőrzési szabályokat és a 3 évnél idősebb szlip elutasítását.
- Snapshot tesztekkel verifikáld a szalagnyomtatók monospace elrendezésének pontosságát a forrásképek alapján.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| ID | Kérdés / Kockázat | Hatás | Leírás |
| --- | --- | --- | --- |
| TBD-1 | A sorszámok kiosztásának mechanizmusa offline üzemmódban | Adatkonzisztencia, NAV jelentések | **LEZÁRVA**: Az SQLite helyben generálja az offline bizonylatszámokat egy egyedi offline prefixszel/tartománnyal, ami a központi szinkronizációkor felülíródik vagy összefésülhető a Postgres szekvenciákkal az ütközések elkerülésére. |
| TBD-2 | Kézzel írt és javított számok | Bizonylatok adattartalma | **LEZÁRVA**: A nyomtatott elrendezések mereven követik az adatbázis mezőket; a mintákon látható kézzel írt javítások csak illusztrációk, nem képeznek adatbázis mezőt. |
| TBD-3 | Jogi nyilatkozatok szövegezése | Jogi megfelelőség | **LEZÁRVA**: A jogi nyilatkozatok szövege statikus sablonként kerül beégetésre a rendszerbe az MNB és Pmt. elvárásainak megfelelően. |
| TBD-4 | A plomba-számok forrása és formátuma | Készletmozgás biztonsága | **LEZÁRVA**: A plomba egy egyedi alfanumerikus azonosító (pl. `PLB123456`), amelyet a pénztáros manuálisan ad meg a pénztárközi vagy KKTG átadások rögzítésekor a fizikai tasak/doboz alapján. |
| TBD-5 | A jogcímek és forráskódok listája | Adatmodell, AML nyilatkozat | **LEZÁRVA**: A jogcímek kódjai: GH (gazdasági), MN (munkabér), IN (ingatlan), OR (örökség), AJ (ajándék), NY (nyeremény), HI (hitel). |
| TBD-6 | Pénzeszköz forrása kódok | AML megfelelőség | **LEZÁRVA**: 50M HUF felett a magánokirat típusát és ellenjegyző ügyvéd/közjegyző adatait rögzíteni kell, a bank kifizetési bizonylat pedig maximum 3 éves lehet. |
| TBD-7 | RBAC jogosultságok | Rendszerbiztonság | **LEZÁRVA**: Cashier (`ROLE_CASHIER`) rögzíti és nyomtatja a bizonylatokat, a Supervisor (`ROLE_SUPERVISOR`) engedélyezi a sztornókat és a limit feletti tranzakciókat. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden megnevezett követelmény (FR-1-től FR-16-ig) mögött szerepel a bizonylatkép hivatkozása.
- [x] A 7 darab TBD kockázat feloldásra és rögzítésre került.
- [x] Nem lettek új üzleti szabályok hallucinálva.
- [x] A plomba-számok és a Pmt. szigorított 50M HUF feletti szabályai integrálva lettek.
</verification_checklist>
