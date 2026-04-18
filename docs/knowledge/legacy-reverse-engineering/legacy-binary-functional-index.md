---
type: registry
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Legacy Binary Functional Index"
load: on-demand
---

# Legacy Binary Functional Index

> Elokeszites datum: 2026-04-09
> Forrasgyoker: `D:\repo\valutavalto-program\Anti\`
> Geppel generalva: `generated/legacy-binary-inventory-2026-04-09.csv`
> SQLite tabla: `docs/valuta-knowledge.sqlite -> legacy_binary_inventory`

---

## S1 ELJARAS_ES_HATOKOR

Ez a dokumentum a tenylegesen elerheto legacy binaris allomanyok (`.exe`, `.dll`) elofordulasara epul. A felmeres a kibontott es eredeti farol egyszerre keszult, igy:

- eredeti binarisok: `Anti\VALUTA\`, `Anti\SZERVER\`, `Anti\ARFOLYAM\`, `Anti\camera*`, `Anti\firebird`
- automatikusan kibontott binarisok: `Anti\SZERVER\_extracted_auto\`
- kiegeszito funkciohivatkozasok:
  - `antivaluta.GPT-5.4.md`
  - `szerver-modules-index.md`
  - `szerver-core-analysis.md`
  - `RE-egyestitett-osszes-csapat-elemzes.md`

Az index nem csak fajlnev-szintu leltar: minden binarishoz hozzarendel egy becsult funkcionalis klasztert es egy `source_hint` mezot is, ahol ez egyertelmuen kikovetkeztetheto.

---

## S2 ELŐFORDULASI_OSSZESITO

| Terulet | EXE | DLL | Megjegyzes |
|---------|----:|----:|------------|
| `ARFOLYAM` | 2 | 0 | Onallo arfolyam-kezeloi alkalmazas |
| `VALUTA` | 155 | 129 | Cashdesk shell + legacy plugin DLL farm |
| `SZERVER` | 430 | 294 | Kozponti szerver es fejlesztoi build artefaktok |
| `SZERVER_EXTRACTED_AUTO` | 705 | 406 | Kibontott csomagokbol eloallt teljesebb binaris kep |
| `CAMERA` | 6 | 0 | Kamera telepitok es lejatszo |
| `CAMERA2` | 2 | 0 | Kamera Office / Player telepitett binarisok |
| `CAMERA3` | 20 | 2 | Regi Java kamera es partner-integracios kliens binarisok |
| `FIREBIRD` | 3 | 0 | Firebird runtime/telepito |
| `KESZLEX` | 1 | 0 | Onallo keszlet export alkalmazas |
| `KORLEVEL_ZIP` | 1 | 0 | Korlevel desktop program |
| `OTHER` | 1 | 0 | Egyeb segedprogram |

**Osszes binaris:** `2157`

---

## S3 FO_FUNCTIONALIS_KLASZTEREK

| Klaszter | Jellegzetes fajlok | Forrasgyoker | Funkcio | Modern megfeleltetes |
|----------|--------------------|--------------|---------|----------------------|
| `cashdesk-shell` | `IBVALTO.EXE` | `Anti\VALUTA\IBVALTO\IBVALTO.DPR` | Penztaros shell, napi workflow, menu-dispatch | `penztar-client/` + `frontend-react/` tranzakcios oldalak |
| `transaction-buy` / `transaction-sell` | `vasarlas.dll`, `eladas.dll` | `Anti\VALUTA\DLL\*\MAKEDLL\` | Devizavetel es -eladas | `TransactionService`, `CashierTransactionPage`, `ConversionPage` |
| `denomination` | `cimlet.dll`, `cimlctrl.dll`, `cimlmenu.dll`, `cimlnyom.dll` | `Anti\VALUTA\DLL\CIML*\` | Cimletkezeles, cimletnyomtatas, kassza-ellenorzes | treasury es denomination modulok |
| `closing` | `napzar.dll`, `havizar.dll`, `nznyomt.exe` | `Anti\VALUTA\DLL\NAPZAR*`, `HAVIZAR*` | Napzaro es havi zaro folyamatok | `EveningClosingPage`, zaro service-ek |
| `vault-transfer` | `atadvet.dll`, `atadolap.dll` | `Anti\VALUTA\DLL\ATADVET\`, `ATADOLAP\` | Atadas-atvetel penztarak/ertektarak kozott | handover es vault transfer modulok |
| `auth-cashier` | `prosbe.dll`, `proski.dll`, `prostmk.dll` | `Anti\VALUTA\DLL\PROS*\` | Penztaros belepes, kilepes, karbantartas | auth + user/role pages |
| `customer-aml` | `bigctrl.dll`, `ugyfel*.dll`, `terror.dll` | `Anti\VALUTA\DLL\BIGCTRL\`, `UGYFEL*\` | Azonositas, AML, szankcios kontroll | `AmlService`, `BlacklistService`, customer modulok |
| `western-union` | `wunion.dll`, `western*.exe` | `VALUTA`, `SZERVER`, `camera3\old` | WU folyamatok es szerveroldali komponensek | `WesternUnionPage`, backend WU service-ek |
| `server-core` | `server.exe`, `project1.exe` build-maradvanyok | `Anti\SZERVER\fejleszt\server\server.dpr` | Kozponti szerver, adatgyujtes, daybook, kontrollok | backend scheduled/import/reporting reszek |
| `server-receptor` | `recptor`, `wrecept`, `import` | `Anti\SZERVER\fejleszt\recptor\` | Penztari adatfogado es import | offline sync + backend ingest |
| `rates` / `rates-sync` | `Arfolyam.exe`, `arftmk`, `getarf` | `Anti\ARFOLYAM\`, `Anti\SZERVER\fejleszt\arfolyam\` | Arfolyam eloallitas, karbantartas, terites | `RateService`, rate management UI |
| `reservation` | `booking`, `foglalo` | `Anti\SZERVER\fejleszt\booking\` | Foglalasi workflow | `ReservationPage` |
| `camera` / `camera-player` | `CameraSetup.exe`, `ExclusivePlayer.exe`, `EC Camera Player.exe` | `Anti\camera2\camera\pom.xml`, `Anti\camera3\old\` | Kameras rogzitok, player, telepitok | modern camera oldalak + Java tooling |
| `mariadb-runtime` | `mysqld.exe`, `libmariadb.dll`, plugin DLL-ek | `camera-office` deploy csomagok | Kamera alrendszer csomagolt adatbazisa | modern backend/infra donteshez input |
| `firebird-runtime` | `firebird.exe`, `ibmanager.exe` | `Anti\firebird\` | Legacy DB runtime es admin tooling | modern PostgreSQL migracio referencia |

---

## S4 FONTOS_MEGFIGYELESEK

### 1. A `Project1.exe` sok helyen nem valodi termeknev

A Delphi projektek nagy resze debug vagy atmeneti buildnevvel maradt meg. Ezert az igazi funkcio legbiztosabban:

- az eleresi utbol
- a `MAKEDLL` / `DEBUG` / `EXEPROBA` kornyezetbol
- a parban levo DLL nevekbol
- a kozeli `.dpr` / `.pas` forrasokbol

allapithato meg.

### 2. A `_extracted_auto` hasznos, de nem tekintheto onallo rendszernek

Ez a fa a top-level archivumok kibontasabol jott letre. Emiatt:

- sok redundans binarist tartalmaz
- jo a teljesseg novelesere
- de a funkcionalis igazsag forrasa tovabbra is az eredeti `VALUTA`, `SZERVER`, `ARFOLYAM`, `camera*` struktura

### 3. A kamera alrendszer kulon technologiai csalad

A `camera2` es `camera3` vilag mar nem Delphi-only:

- Java / JavaFX
- Maven modulok
- csomagolt MySQL/MariaDB runtime
- kulon player, inspecter, server manager, NAV/WU kapcsolatok

Ez kulon modernizacios workstreamet indokol.

---

## S5 HARMADIK_FELES_RUNTIME_OK

| Runtime | Hely | Szerep |
|--------|------|--------|
| Firebird | `Anti\firebird\` | legacy adatbazis motor |
| MariaDB / MySQL | `camera-office` deploy csomagok | kamera platform helyi adatbazisa |
| OpenIMAJGrabber | `camera3\old\...OpenIMAJGrabber.dll/.exe` | Java webcam capture native bridge |
| NSIS / Windows installer segedek | kamera setup csomagok | telepito infrastruktura |

---

## S6 GYAKORLATI_HASZNALAT

### Agent / SQL keresesi pontok

- teljes binaris lista: `generated/legacy-binary-inventory-2026-04-09.csv`
- osszesito: `generated/legacy-binary-summary-2026-04-09.json`
- SQLite:
  - `legacy_binary_inventory`
  - `agent_knowledge_segments`

### Tipikus keresesek

```sql
SELECT area, cluster, COUNT(*)
FROM legacy_binary_inventory
GROUP BY area, cluster
ORDER BY area, COUNT(*) DESC;
```

```sql
SELECT relative_path, source_hint
FROM legacy_binary_inventory
WHERE cluster = 'customer-aml'
ORDER BY relative_path;
```

### Javasolt olvasasi sorrend

1. `legacy-binary-functional-index.md`
2. `szerver-modules-index.md`
3. `antivaluta.GPT-5.4.md`
4. `legacy-analysis-rebuild-knowledge-base.md`

---

## S7 KORLATOK

- A funkcionalis besorolas szabalyalapu es utvonal/fajlnev heurisztikaval keszult.
- A duplikalt build-artefaktok szandekosan benne maradtak az inventoryban, mert a legacy build szokasokrol is bizonyitekot adnak.
- Az `EXE/DLL` index nem helyettesiti a `.pas`, `.dpr`, `.dfm`, `.java`, `.fxml` forrasok melyelemzeset; csak egy belatasi kapu a teljes legacy topologiaba.
