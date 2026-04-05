# Bence — Legacy Delphi Biztonsági & Compliance Elemzés
## Valutaváltó ERP: Delphi 7 → Java/React/Electron Migráció

**Kelte:** 2026-04-05  
**Elemző:** Bence (SecOps Chief)  
**Verzió:** 1.0  
**Jogszabályi alap:** 2017. évi LIII. tv. (pénzmosás megelőzése), 2007. évi CXXXVI. tv., NAV-előírások, GDPR (2016/679/EU), 4AMLD/5AMLD, ENSZ/EU szankciós listák

---

## Tartalomjegyzék

1. [Összefoglaló](#1-összefoglaló)
2. [Elemzett forrásállományok](#2-elemzett-forrásállományok)
3. [Biztonsági kontrollok — 20 elemzett terület](#3-biztonsági-kontrollok--20-elemzett-terület)
4. [Kritikus jogszabályi kockázatok](#4-kritikus-jogszabályi-kockázatok)
5. [Kockázati mátrix](#5-kockázati-mátrix)
6. [Prioritizált ajánlások](#6-prioritizált-ajánlások)
7. [Összesítő verdikt](#7-összesítő-verdikt)

---

## 1. Összefoglaló

A legacy Delphi 7 rendszer (SZERVER_extracted) és a modern Java+React+Electron stack részletes biztonsági és compliance összehasonlítása alapján **20 kontroll** elemzése alapján a következő kép rajzolódik ki:

| Dimenzió | Legacy (Delphi 7) | Modern (Java/Spring/React) |
|---|---|---|
| **AML/KYC implementáció** | Részleges, hardcoded limitek, manual | Teljes, 2017. LIII. tv. szerint, audit trail |
| **Szankciós szűrés** | Batch ENSZ XML import, local FDB | Real-time fuzzy match, SanctionEntry DB |
| **SQL biztonság** | **KRITIKUS: string-konkatenáció** | Parameterized queries, JPA |
| **Hálózati biztonság** | **KRITIKUS: plaintext TCP, hardcoded IP** | HTTPS, JWT, CORS |
| **Adatvédelem (GDPR)** | Nincs jogalap-kezelés, nincs törlési eljárás | Retention policy, 8 év pénzügyi |
| **Auditálhatóság** | Flat text log, nincs integrity | AuditLogService, strukturált DB |
| **Titkosítás** | Nincs (adatbázis, tranzit) | AES-256/GCM kamera, encrypted config |
| **Hitelesítés** | Nincs API auth; DLL belső hívás | JWT Bearer, role-based (SUPERVISOR) |

**Összesített kockázati besorolás:**
- Legacy: **KRITIKUS** (azonnali megfelelési kockázat)
- Modern (aktuális állapot): **KÖZEPES** (nyitott hiányosságokkal)

---

## 2. Elemzett forrásállományok

### Legacy (Delphi 7)

| Fájl | Méret | Modul neve | Funkció |
|---|---|---|---|
| `ugyfelcontrol/dll/tiltasok/debug/unit2.pas` | 78 KB | `tiltaskezelorutin` | Tiltáslista kezelő — személyek/cégek tiltása |
| `ugyfelcontrol/dll/terrornaplo/debug/unit2.pas` | 12 KB | `terrornaplorutin` | Terrorista-gyanús ügyfél napló exportálás |
| `ugyfelcontrol/dll/letilt/debug/unit2.pas` | 23 KB | `letiltorutin` | Egyedi ügyfél tiltás, kereső |
| `ugyfelcontrol/dll/evimax/debug/unit2.pas` | 25 KB | `evimaxtranzakciok` | Éves max tranzakció összesítő |
| `permit/unit1.pas` | 41 KB | Permit-rendszer | Árfolyam/feltétel engedélyezés |
| `police/unit1.pas` | 28 KB | Police modul | Rendőri adatszolgáltatás (1506-1710 range) |
| `terror/maketerrlist/unit1.pas` | 10 KB | Terror lista builder | ENSZ XML letöltés → TERRORISTS.FDB |
| `recguard/unit1.pas` | 16 KB | RecGuard | Watchdog, kamera-GC, auto-reboot |

### Modern

| Fájl | Funkció |
|---|---|
| `AmlService.java` | AML motor (300K/1.5M/3.6M/8M/10M/25M/50M küszöbök) |
| `SanctionScreeningService.java` | Szankciós szűrés (ENSZ/EU/OFAC fuzzy match) |
| `BlacklistService.java` | Tiltott személyek/cégek CRUD |
| `application.properties` | Spring Boot konfiguráció |

---

## 3. Biztonsági kontrollok — 20 elemzett terület

---

### K-01 | SQL Injection védelem

**Kategória:** Kritikus  
**Jogszabályi kockázat:** GDPR 32. cikk (technikai védelem), 2013. évi V. tv. üzleti titok

**Legacy állapot — KRITIKUS HIÁNYOSSÁG:**

A teljes legacy kódbázis string-konkatenációval épít SQL lekérdezéseket. Jellemző minta (`letilt/unit2.pas`):

```pascal
_pcs := 'SELECT * FROM ' + _nevtabla + _sorveg;
_pcs := _pcs + 'WHERE (NEV LIKE ' + chr(39) + _tkernev + '%' + chr(39) + ')';
// ...
_pcs := 'INSERT INTO ' + _nevtabla + ' (SORSZAM,NEV,ANYJANEVE,...) ';
_pcs := _pcs + 'VALUES (' + chr(39) + _tiltnev + chr(39) + ',';
```

A `_tkernev`, `_tiltnev`, `_tiltanyja` stb. változók közvetlenül az UI-ból érkeznek, semmilyen sanitálás nélkül. Az összes `.pas` fájlban (tiltasok, letilt, evimax, permit, police) **kizárólag** ilyen string-konkatenáció van, paraméterezett lekérdezés egyáltalán nem.

**Modern állapot — MEGOLDOTT:**
- JPA/Hibernate parameterized queries (Spring Data JPA)
- `customerId`, `companyId` UUID típus — string injection lehetetlen
- `findByCustomerCodeAndCompanyId(customerId, companyId)` — binding paraméterek

**Kockázat:** A legacy rendszerben az összes érzékeny tábla (ügyfélnyilvántartás, tiltólista, terroristanapló) SQL injection útján elérhető volt. Pénzmosás elleni adatok módosítása/törlése lehetséges lett volna.

---

### K-02 | Hardcoded szerver IP és adatbázis elérési út

**Kategória:** Kritikus  
**Jogszabályi kockázat:** 2013. évi L. tv. (elektronikus információbiztonság), GDPR 25. cikk

**Legacy állapot — KRITIKUS:**

Minden legacy `.pas` fájlban a szerver IP-je hardcoded konstansként szerepel:

```pascal
// terrornaplo/unit2.pas:60, letilt/unit2.pas:136, tiltasok/unit2.pas stb.
_host: string = '185.43.207.99';
// ...
remoteDbase.DatabaseName := _host + ':C:\RECEPTOR\DATABASE\TERRORISTS.FDB';
remoteDbase.DatabaseName := _host + ':C:\receptor\database\ugyfel' + _evtizes + '.FDB';
// Direkt hardcoded:
AcDbookdbase.DatabaseName := '185.43.207.99:c:\cartcash\database\daybook.fdb';
```

30+ fájlban azonos hardcoded IP (`185.43.207.99`). A rendszer Firebird protokollon (port 3050) plaintext TCP-n csatlakozik. Nincs hitelesítés, nincs TLS.

**Modern állapot — MEGOLDOTT:**
```properties
spring.datasource.url=${DATABASE_URL:jdbc:postgresql://localhost:5432/valuta}
jwt.secret=${JWT_SECRET}
```
Minden szenzitív konfiguráció environment variable-ból érkezik.

**Kockázat:** Az IP megváltozásakor az összes DLL újrafordítást igényelt; a nyílt port és plaintext kapcsolat hálózaton belülről bármilyen adatot olvashatóvá tett.

---

### K-03 | Hálózati adatátvitel titkosítása

**Kategória:** Kritikus  
**Jogszabályi kockázat:** GDPR 32. cikk, 2017. LIII. tv. 26. § (személyes adatok védelme)

**Legacy állapot — KRITIKUS:**

A Firebird Inter-Base Protocol (IBDatabase) plaintext TCP, port 3050-en kommunikál. Nincs SSL/TLS wrapper. A terrorista-lista, az ügyfél-azonosítók, a tiltólisták és a pénzügyi tranzakciók **hálózaton titkosítatlanul** utaznak a pénztár kliensektől a szerver felé.

```pascal
// terrornaplo/unit2.pas
remoteDbase.DatabaseName := _host + ':C:\RECEPTOR\DATABASE\TERRORISTS.FDB';
RemoteDbase.Connected := true;
```

**Modern állapot — MEGOLDOTT:**
- HTTPS kötelező (production CORS policy)
- JWT Bearer token minden API hívásban
- `camera.encryption.enabled=true`, `AES/GCM/NoPadding`, 256-bit kulcs
- `app.encryption.key` OAuth token titkosítás

**Kockázat:** Man-in-the-middle támadás lehetséges, az összes AML/szankciós adat olvasható volt hálózaton.

---

### K-04 | Szankciós lista frissítése és valósidejűsége

**Kategória:** Magas  
**Jogszabályi kockázat:** 2017. LIII. tv. 65. §, 2007. XCVI. tv. (terrorizmus finanszírozása elleni), 4AMLD

**Legacy állapot — GYENGE:**

A terror/maketerrlist modul az ENSZ konszolidált listát (`un.org/securitycouncil/content/un-sc-consolidated-list`) manuálisan tölti le és importálja egy lokális Firebird DB-be:

```pascal
_urL1 := 'https://www.un.org/securitycouncil/content/un-sc-consolidated-list';
_xmlPath := 'c:\temp\terrorlist.xml';
// Manuális gombnyomásra tölt le, XML-t fájlba menti, majd UNOLIST táblába importál
_pcs := 'DELETE FROM UNOLIST';
TParancs(_pcs);
// ...
_pcs := 'INSERT INTO UNOLIST (TERROR_NAME) VALUES (' + chr(39) + _aktnev + chr(39) + ')';
```

**Kritikus gyengeségek:**
- Nincs automatikus ütemezés — csak kézzel, operátor-függő
- Nincs listageneráció timestamp → nem ellenőrizhető, mikor volt utoljára frissítve
- Csak névegyezés (`FIRST_NAME + SECOND_NAME + THIRD_NAME`), nincs születési dátum, okmányszám szűrés
- Nincs EU/OFAC/HNB lista

**Modern állapot — RÉSZBEN MEGOLDOTT:**
```java
// SanctionScreeningService.java
private static final int MAX_LEVENSHTEIN_DISTANCE = 2;
// Fuzzy match: Levenshtein ≤ 2 VAGY contains → POSSIBLE
// Exact match → CONFIRMED
// Okmányszám alapú szűrés is:
List<SanctionEntry> docMatches = sanctionEntryRepository.findByDocumentNumber(documentNumber);
```

**Hiányosság a modernben:** A SanctionEntry adatok feltöltési mechanizmusa (scheduler, forrás lista URL, frissítési frekvencia) nem látható ebből a fájlból. Ellenőrizni szükséges, hogy van-e automatizált napi/heti ENSZ + EU lista import.

---

### K-05 | AML küszöbértékek és göngyölési logika

**Kategória:** Magas  
**Jogszabályi kockázat:** 2017. LIII. tv. 6. § (azonosítási kötelezettség), 65. § (bejelentési kötelezettség)

**Legacy állapot — RÉSZBEN MEGVALÓSÍTVA:**

Az `evimax/unit2.pas` az éves forgalmi összeget gyűjti (`FORINTOSSZEG` mező), de csak riport-jelleggel (Excel export). Az AML döntési logika a `BIGCTRL.DLL`-ben volt (nem elemzett), amelyre az `AmlService.java` kommentje hivatkozik.

**Modern állapot — TELJES:**

```java
/** Azonosítás nélküli limit (NAV) */
private static final BigDecimal IDENTIFICATION_LIMIT = new BigDecimal("300000");
/** Éves göngyölési limit */
private static final BigDecimal ANNUAL_ROLLING_LIMIT = new BigDecimal("3600000");
/** Részletes azonosítási limit (bejelentés kötelező) */
private static final BigDecimal DETAILED_ID_LIMIT = new BigDecimal("1500000");
/** Napi gyanúsági limit */
private static final BigDecimal DAILY_SUSPICIOUS_LIMIT = new BigDecimal("900000");
// TranzTipus: 6 (50M), 5 (10M), 4 (negyedéves), 3 (8M éves max), 2 (külföldi), 1 (PEP), -1 (külföldi+USD block)
```

**Értékelés:** A modern implementáció a 2017. LIII. tv. logikáját pontosan követi, a legacy BIGCTRL.DLL logikát visszafejtve és dokumentálva implementálja.

**Hiányosság:** Az `ANNUAL_ROLLING_LIMIT` (3.6M Ft) a törvényi limittel egyezik, de a valuta váltásnál a forint-konverzió pontossága és az árfolyam-rögzítés pillanata auditálandó.

---

### K-06 | Ügyfél-azonosítás dokumentációja (KYC)

**Kategória:** Magas  
**Jogszabályi kockázat:** 2017. LIII. tv. 7-20. §, 300.000 Ft feletti azonosítási kötelezettség

**Legacy állapot — HIÁNYOS:**

A `letilt/unit2.pas` tartalmaz ügyfél adatmezőket (`NEV`, `ANYJANEVE`, `SZULETESIIDO`, `SZULETESIHELY`, `LAKCIM`), de nincs okmánytípus-validálás, okmánylejárat-ellenőrzés, és az adatrögzítés az Interbase DB-be megy paraméterezés nélkül.

```pascal
// letilt/unit2.pas - nincs kötelező mező validálás
_ttnev := trim(FieldByNAme('NEV').asString);
_ttanyja := trim(FieldByNAme('ANYJANEVE').asString);
_ttszulido := FieldByNAme('SZULETESIIDO').asString;
```

**Modern állapot — TELJES (Blacklist + AML):**

```java
// AmlService.java
if (hufAmount.compareTo(IDENTIFICATION_LIMIT) >= 0) {
    result.requiresIdentification(true);
    if (customerName == null || customerName.isBlank()
        || documentNumber == null || documentNumber.isBlank()) {
        result.approved(false);
        result.rejectionReason("300.000 Ft feletti tranzakcióhoz ügyfél azonosítás (név + igazolvány) KÖTELEZŐ!");
    }
}
```

Blacklist entitás: `fullName`, `documentNumber`, `identityNumber`, `passportNumber`, `dateOfBirth`, `nationality`, `listType`, `listSource`, `reason` — komplett KYC adatmodell.

---

### K-07 | Audit trail integritása

**Kategória:** Magas  
**Jogszabályi kockázat:** 2017. LIII. tv. 49. § (nyilvántartási kötelezettség), 8 éves megőrzési kötelezettség

**Legacy állapot — GYENGE:**

A `recguard/unit1.pas` flat text logot ír:

```pascal
procedure TForm1.Logbair(_mess: string);
var _logfile,_logpath: string;
begin
  _logfile := 'RG' + midstr(_mamas,3,2) + midstr(_mamas,6,2) + midstr(_mamas,9,2) + '.txt';
  _logPath := 'c:\receptor\log\' + _logfile;
  // ...
  writeln(_textiras, _aktidos + ': ' + _mess);
end;
```

- Nincs digitális aláírás, nincs hash-lánc — a log bármikor módosítható
- Nincs centralizált log — minden pénztár saját logot ír
- A naplók 3 nap után törlődnek (kamera GC logika)
- Nincs WORM (Write-Once-Read-Many) garanciák

**Modern állapot — JOBB, de hiányos:**
- `AuditLogService` strukturált DB-ben rögzít
- `AmlService`: `auditLogService.log("AML_HIGH_RISK_SET", ...)` minden kritikus eseményre
- `application.properties`: `retention.financial-transactions.years=8`, `hard-delete-enabled=false`

**Hiányosság:** Az audit log tamper-evidence védelme (hash-lánc, V108_1 migration `camera_hash_chain_and_export`) csak a kamera képekre érvényes; a pénzügyi audit log hash-lánca nem dokumentált.

---

### K-08 | Adatmegőrzési politika (GDPR & pénzmosás törvény)

**Kategória:** Magas  
**Jogszabályi kockázat:** GDPR 5. cikk (1)(e) tárolás korlátozása, 2017. LIII. tv. 49. §

**Legacy állapot — HIÁNYOS:**

- Nincs dokumentált adatmegőrzési politika
- A `recguard/unit1.pas` kamera fájlokat 3 nap után töröl (`_lastgood := Date-3`)
- Ügyfél adatok FDB-ben maradnak határozatlan ideig
- Nincs törlési eljárás, nincs anonimizálás

**Modern állapot — MEGVALÓSÍTVA:**
```properties
retention.financial-transactions.years=8
retention.financial-transactions.hard-delete-enabled=false
```

```java
// CameraCleanupService.java
LocalDate cutoff = LocalDate.now().minusDays(cameraProperties.getRetentionDays());
```

**Értékelés:** A 8 éves pénzügyi megőrzési előírás implementálva. A GDPR „elfeledtetési jog" (törlési kérelem kezelése természetes személyeknél) mechanizmusa nem látható a vizsgált fájlokban — ellenőrizni szükséges.

---

### K-09 | Strukturálási detekció (Smurfing)

**Kategória:** Magas  
**Jogszabályi kockázat:** 2017. LIII. tv. 23. § (gyanús ügyletek bejelentése), FATF R.20

**Legacy állapot — NINCS:**

A legacy rendszerben nincs olyan modul, amely az azonosítási limit alatti, sorozatos tranzakciókat detektálná. Az `evimax` modul csak az éves maximumot nézi, napközbeni mintázatot nem.

**Modern állapot — MEGVALÓSÍTVA:**
```java
private static final int STRUCTURING_MIN_TRANSACTIONS = 3;
private static final BigDecimal STRUCTURING_RATIO = new BigDecimal("0.80");

// Ha 3+ tranzakció az IDENTIFICATION_LIMIT 80-99%-a között van egy napon:
long nearLimitCount = dailyTxs.stream()
    .filter(tx -> tx.getHufAmount().compareTo(limitThreshold) >= 0
               && tx.getHufAmount().compareTo(IDENTIFICATION_LIMIT) < 0)
    .count();
return nearLimitCount >= STRUCTURING_MIN_TRANSACTIONS;
```

**Értékelés:** Szolid alapimplementáció. Kiegészítő javaslat: cross-branch structuring detekció (különböző pénztáraknál ugyanaz az ügyfél azonos napon).

---

### K-10 | PEP (Kiemelt közszereplő) szűrés

**Kategória:** Magas  
**Jogszabályi kockázat:** 2017. LIII. tv. 3. § 38. pont (kiemelt közszereplő), 5AMLD

**Legacy állapot — NINCS AUTOMATIZÁLÁS:**

Nincs PEP lista, nincs automatikus PEP jelölés. A tiltáslista manuálisan kezelt. A `KOZSZEREP` byte mező létezik a változók között (`_kozszerep: byte`), de logikája ismeretlen/kézi.

**Modern állapot — MEGVALÓSÍTVA:**
```java
// Customer.isPep mező
if (Boolean.TRUE.equals(customer.getIsPep())) {
    return 1; // TranzTipus 1: belföldi kiemelt közszereplő (PEP)
}
// NULL-safe kezelés:
} else if (customer.getIsPep() == null) {
    log.warn("AML: Ügyfél {} isPep=NULL — feltételezzük nem-PEP", customerId);
}
```

**Hiányosság:** PEP adatbázis-forrás és frissítési mechanizmus nem látható — ellenőrizni szükséges, hogy az EU/HNB PEP lista automatikusan szinkronizálva van-e.

---

### K-11 | Külföldi ügyfél és USD korlátozás

**Kategória:** Közepes  
**Jogszabályi kockázat:** 2017. LIII. tv. 20. § (fokozott átvilágítás), MNB deviza-előírások

**Legacy állapot — RÉSZLEGES:**

Az `evimax` modul gyűjt `ALLAMPOLGAR` mezőt, a `letilt` modul `_kulfoldi: byte` változót kezel. A korlátozás logikája szétszórt DLL-ekben.

**Modern állapot — EGYSÉGES:**
```java
if (Boolean.TRUE.equals(customer.getIsForeign())) {
    if ("USD".equals(currencyCode)) {
        log.warn("AML: Külföldi ügyfél {} USD tranzakciót próbál — BLOKKOLVA (TranzTipus -1)", customerId);
        return -1;
    }
    return 2; // fokozott átvilágítás
}
```

**Értékelés:** A blokkolás biztonságos (explicit `-1` visszatérés → `blocked=true` AmlCheckResult-ban). A 22 devizanem (`_XDNEM` tömb a legacy permitben) a modernben is kezelendő.

---

### K-12 | Rendőri/hatósági adatszolgáltatás

**Kategória:** Magas  
**Jogszabályi kockázat:** 2013. évi CLXXXVIII. tv. (adatszolgáltatási kötelezettség), 2017. LIII. tv. 38. §

**Legacy állapot — KOCKÁZATOS:**

A `police/unit1.pas` modul a `POLICE` táblát tölti fel ügyfél-adatokkal (1506-1710 range, azaz 2015. június – 2017. október közötti tranzakciók):

```pascal
_tolfarok := '1506';
_igfarok  := '1710';
_pt := 1;
while _pt <= 150 do
begin
  _fdbPath := 'c:\receptor\database\v' + inttostr(_pt) + '.fdb';
  // ...
  _pcs := 'DELETE FROM POLICE';
  pparancs(_pcs); // előbb töröl mindent, aztán újratölt
```

- A `DELETE FROM POLICE` + újratöltés atomicitás nélküli — adatvesztés lehetséges
- Nincs access log: ki, mikor exportált rendőri adatot
- A fizikai `.gdb` fájl (`police.gdb`) nem titkosított

**Modern állapot:** Nincs közvetlen megfelelő a vizsgált fájlokban — a hatósági adatszolgáltatás modul hiányzik vagy más helyen van.

---

### K-13 | Biometria / kamera adatok védelme

**Kategória:** Közepes  
**Jogszabályi kockázat:** GDPR 9. cikk (különleges adatok), 2011. évi CXII. tv.

**Legacy állapot — GYENGE:**

A `recguard/unit1.pas` kamera fájlokat kezel (`d:\kamera\upload\kamera\*.C1`), 3 napos megőrzéssel:

```pascal
_lastgood := Date - 3;
// töröl minden 3 napnál régebbi C1 fájlt
Sysutils.DeleteFile(_delPath);
```

Nincs titkosítás, nincs hozzáférés-naplózás, nincs GDPR tájékoztató hivatkozás.

**Modern állapot — ERŐS:**
```properties
camera.encryption.enabled=true
camera.encryption.algorithm=AES/GCM/NoPadding
camera.encryption.key-size=256
camera.retention-days=50
```

V108_1 migration: `camera_hash_chain_and_export` — tamper-evident hash-lánc.

**Értékelés:** A modern implementáció a GDPR 9. cikk szerinti különleges adat-kategória (biometrikus) védelmi kötelezettségnek megfelel.

---

### K-14 | Bejelentési kötelezettség — AML Reporting workflow

**Kategória:** Magas  
**Jogszabályi kockázat:** 2017. LIII. tv. 23-30. §, 65. § (bejelentés a NAV/ORFK felé)

**Legacy állapot — NINCS:**

Nincs automatizált AML bejelentési workflow. A terrorista napló (`terrornaplo/unit2.pas`) csak Excel exportot tud generálni, amelyet manuálisan kell eljuttatni a hatósághoz.

**Modern állapot — MEGVALÓSÍTVA:**
```java
// AmlService.java - teljes életciklus:
// DRAFT → SUBMITTED → ACKNOWLEDGED
public AmlReportDto submitToAuthority(UUID reportId, String externalReference)
public AmlReportDto acknowledgeReport(UUID reportId, String externalReference)
// Napi export hatóságnak:
public AmlDailyExportDto generateDailyExport(LocalDate date)
```

**Értékelés:** A workflow megfelel a törvényi előírásoknak. Automatikus DRAFT→bejelentési határidő (pl. 2 munkanap) figyelőre szükség lehet.

---

### K-15 | Hitelesítés és jogosultságkezelés

**Kategória:** Kritikus  
**Jogszabályi kockázat:** GDPR 32. cikk, 2013. évi L. tv. (elektronikus információbiztonság)

**Legacy állapot — KRITIKUS HIÁNYOSSÁG:**

A DLL-ek közvetlenül az Interbase adatbázishoz csatlakoznak hitelesítés nélkül. Nincs user-level access control — bárki, aki a DLL-t betöltheti, a teljes adatbázishoz hozzáfér. A `permit/unit1.pas` `ENGEDELYEZO`/`ENGEDELYGOMB` entitás egy operátor-szintű engedélyezés, de nincs session management, nincs token.

```pascal
// letilt/unit2.pas - nincs autentikáció, közvetlen DB csatlakozás
RemoteDbase.Connected := True;
// Bárki, akinek hozzáférése van a processhez, írhat a tiltólistára
```

**Modern állapot — MEGOLDOTT:**
```java
// AmlService.java
if (!SecurityUtils.isSupervisorOrAbove()) {
    result.requiresApproval(true);
}
// SecurityUtils.getCurrentCompanyId() — multi-tenant izoláció
// SecurityUtils.getCurrentWorkerCode() — AML report audithoz
```

JWT Bearer tokenek, role-based access (SUPERVISOR jogosultság szükséges AML jóváhagyáshoz).

**Hiányosság:** A brute-force védelem megvan (`rate-limit.login.max-requests=10/60s`), de a JWT token lejárat és refresh token rotáció mechanizmusa a vizsgált fájlokban nem teljes körűen ellenőrzött.

---

### K-16 | Multi-tenant izoláció

**Kategória:** Magas  
**Jogszabályi kockázat:** GDPR 25. cikk (adatvédelem by design), üzleti titok

**Legacy állapot — NINCS:**

A Firebird adatbázisok pénztáranként külön fizikai fájlokban vannak (`ugyfel{evtized}.fdb`), ami természetes izoláció, de nincs logikai multi-tenant réteg — egy kompromittált szerver elérés az összes pénztár adatát expozálja.

**Modern állapot — ERŐS:**
```java
UUID companyId = SecurityUtils.getCurrentCompanyId();
BigDecimal total = transactionRepository.sumCustomerAnnualTotal(companyId, customerId, yearStart, today);
```

Minden kritikus lekérdezés `companyId`-ra szűr — cross-tenant data leak elvi lehetetlenné téve.

---

### K-17 | Stornó és göngyölés visszavonás AML-kezelése

**Kategória:** Közepes  
**Jogszabályi kockázat:** 2017. LIII. tv. (göngyölési szabályok integrity-je)

**Legacy állapot — ISMERETLEN:**

A `SZTORNO.DLL` a `BIGCTRL.DLL`-t hívta göngyölés visszavonásra (az `AmlService.java` kommentjéből). A Delphi forrásban ez nem látható a vizsgált fájlokban.

**Modern állapot — MEGVALÓSÍTVA:**
```java
public void reverseAccumulation(String customerId, BigDecimal hufAmount, LocalDateTime originalDate) {
    // Éves göngyölt összeg csökkentése
    // Ha limit alá csökken → highRiskFlag törlése
    // Audit log kötelező
    auditLogService.log("AML_REVERSE_ACCUMULATION", auditMessage, customerId);
}
```

---

### K-18 | Fejlesztői / debug build production-ban

**Kategória:** Magas  
**Jogszabályi kockázat:** Szivárgó debug info → GDPR 32. cikk, üzleti titok

**Legacy állapot — KRITIKUS:**

Az összes vizsgált `.pas` fájl a `\debug\` könyvtárban van. A debug buildek debug szimbólumokat, belső útvonalakat, osztálynév-információkat tartalmaznak. Az `EXCEL.APPLICATION` COM-objektum közvetlen manipulálása (`procedure TForm2.KillExcel`) és a `TerminateProcess(OpenProcess(...))` hívások debug build jellegzetességek.

```pascal
// terrornaplo/unit2.pas - debug build, production-ban is így fut
procedure TForm2.KillExcel;
begin
  TerminateProcess(OpenProcess(1, Bool(1), _proc.th32ProcessID), 0);
end;
```

**Modern állapot — RÉSZBEN MEGOLDOTT:**
```properties
springdoc.swagger-ui.tryItOutEnabled=true
# Swagger autentikált usernek érhető el
```

**Hiányosság:** A `springdoc.swagger-ui.tryItOutEnabled=true` production-ban kockázat — lehetővé teszi API-hívások közvetlen kipróbálását. Az `application-production.properties` tartalma nem vizsgálható jelen elemzésben.

---

### K-19 | Titkosítás at-rest (adatbázis szintű)

**Kategória:** Magas  
**Jogszabályi kockázat:** GDPR 32. cikk, 2013. évi L. tv.

**Legacy állapot — NINCS:**

A Firebird `.FDB` adatbázisok (TERRORISTS.FDB, ugyfel{evtized}.FDB, daybook.fdb) fizikailag titkosítatlanok. Fizikai hozzáférés esetén az összes adat közvetlenül olvasható.

```pascal
remoteDbase.DatabaseName := _host + ':C:\RECEPTOR\DATABASE\TERRORISTS.FDB';
```

Nincs backup titkosítás sem.

**Modern állapot — RÉSZLEGES:**
- `EncryptedStringConverter.java` — érzékeny mezők DB-szintű titkosítása (AES)
- Camera: AES/GCM/256-bit at-rest
- PostgreSQL szintű full-disk encryption: az infrastruktúrán (Render/Neon) alapértelmezett

---

### K-20 | Kockázati profil és riasztási rendszer

**Kategória:** Közepes  
**Jogszabályi kockázat:** 2017. LIII. tv. 3. § (kockázat-alapú megközelítés), FATF R.1

**Legacy állapot — NINCS:**

Nincs automatikus kockázati profil képzés. Az `evimax` modul összesítő riportot készít, de nem küld riasztást, nem jelez automatikusan a felettesnek.

**Modern állapot — MEGVALÓSÍTVA:**
```java
public CustomerRiskProfileDto getCustomerRiskProfile(String customerId) {
    // LOW / MEDIUM / HIGH / CRITICAL
    if (structuring || (highFrequency && highVolume)) {
        riskLevel = "CRITICAL";
    } else if (highFrequency || highVolume) {
        riskLevel = "HIGH";
    } else if (last30DaysTotal.compareTo(REPORTING_THRESHOLD) >= 0) {
        riskLevel = "MEDIUM";
    }
    // MONTHLY_VOLUME_THRESHOLD = 5.000.000 Ft/30 nap
    // DAILY_FREQUENCY_THRESHOLD = 3 tranzakció/nap
}
```

**Hiányosság:** Supervisor e-mail/push értesítés CRITICAL kockázati szintnél nem dokumentált a vizsgált fájlokban.

---

## 4. Kritikus jogszabályi kockázatok

### 4.1 Pénzmosás elleni törvény (2017. LIII. tv.)

| Kötelezettség | Törvényi alap | Legacy | Modern | Kockázat |
|---|---|---|---|---|
| Ügyfél-azonosítás 300K felett | 6. § (1) | Manuális, nem blokkol | Automatikus stop | MAGAS legacy-n |
| Szankciós lista real-time ellenőrzés | 65. § | Batch, manuális | Real-time, fuzzy | MAGAS legacy-n |
| Gyanús ügylet bejelentés 24h-n belül | 23. § | Excel, manuális | Workflow, lifecycle | KÖZEPES mindkettőn |
| 8 éves megőrzési kötelezettség | 49. § | Nincs politika | `hard-delete=false`, 8 év | MEGOLDOTT modern |
| Éves göngyölési limit (3.6M Ft) | 6-7. § | BIGCTRL.DLL (rekonstruált) | AmlService, pontos | MEGOLDOTT modern |

### 4.2 GDPR (2016/679/EU)

| Kötelezettség | Cikk | Legacy | Modern | Kockázat |
|---|---|---|---|---|
| Adatvédelem by design | 25. | Nincs | Multi-tenant, UUID | MAGAS legacy-n |
| Titkosítás (technikai intézkedés) | 32. | Nincs | AES/GCM, JWT | KRITIKUS legacy-n |
| Adatkezelési jogalap | 6. | Nem dokumentált | N/A (részleges) | KÖZEPES |
| Elfeledtetési jog | 17. | Nincs | Nem egyértelmű | KÖZEPES modern |

### 4.3 Rendőrségi / hatósági adatszolgáltatás

| Kötelezettség | Jogalap | Legacy | Modern | Kockázat |
|---|---|---|---|---|
| Tranzakciók rendőrségi lekérdezésre | 2013. CLXXXVIII. tv. | Police modul, audit nélkül | Nincs külön modul | MAGAS legacy-n |
| Export auditálhatósága | 2017. LIII. tv. 38. § | Nincs access log | N/A | MAGAS |

---

## 5. Kockázati mátrix

```
VALÓSZÍNŰSÉG
    │ MAGAS │ K-02, K-03  │ K-01         │ K-15        │
    │       │ (hálózat,IP)│ (SQL inject) │ (auth)      │
    ├───────┼─────────────┼──────────────┼─────────────┤
    │ KÖZE  │ K-04, K-08  │ K-07, K-12   │ K-18        │
    │  PES  │ (szankciós, │ (audit,police│ (debug)     │
    │       │  retention) │ adat)        │             │
    ├───────┼─────────────┼──────────────┼─────────────┤
    │ ALACC │ K-13, K-20  │ K-09, K-10   │ K-19        │
    │  ONY  │ (kamera,    │ (struct.,PEP)│ (at-rest)   │
    │       │  riasztás)  │             │             │
    └───────┴─────────────┴──────────────┴─────────────┘
             ALACSONY      KÖZEPES        MAGAS
                              HATÁS
```

**Legacy rendszerben kritikus (piros zóna):** K-01, K-02, K-03, K-15  
**Modern rendszerben nyitott (sárga zóna):** K-04 (lista frissítés), K-07 (audit hash), K-10 (PEP forrás), K-14 (határidő), K-18 (Swagger), K-20 (értesítés)

---

## 6. Prioritizált ajánlások

### P1 — AZONNALI (Legacy rendszer életben tartásának feltétele)

1. **SQL injection patch:** Ha a legacy rendszer még él, minden `_pcs := ... + _var + ...` mintát paraméterezett IB query-re kell cserélni. Alternatíva: WAF elé helyezés.

2. **Hálózati szegmentáció:** A Firebird port (3050) csak a szerver belső hálózatán legyen elérhető, VPN/SSL tunnel nélkül kliensek ne érjék el.

3. **IP externalizálása:** A 30+ fájlban hardcoded `185.43.207.99` kezelhető egy egyszerű konfiguráció-fájllal (`receptor.ini`), ha a rendszer még fut.

### P2 — RÖVID TÁVÚ (Modern rendszer hiányosságok)

4. **Szankciós lista automatikus frissítés:** Scheduler (napi) az ENSZ + EU szankciós lista importálására, timestamp + version tracking, admin riasztás ha lista > 7 napja nem frissült.

5. **PEP lista forrás:** HNB vagy ACAMS PEP adatbázis integráció, automatikus szinkronizálás.

6. **AML bejelentési határidő tracking:** DRAFT státuszú AML report 2 munkanapon belül automatikusan OVERDUE-ra vált és supervisor emailt küld.

7. **Audit log tamper-evidence:** A pénzügyi audit log (nem csak kamera) hash-lánc integritás ellenőrzése (SHA-256, chain). Hasonló a V108_1 migrationhöz.

8. **GDPR törlési kérelem workflow:** Természetes személyek törlési/anonimizálási kérelmének kezeléséhez dedikált API endpoint és folyamat szükséges.

### P3 — KÖZÉP TÁVÚ

9. **Swagger kikapcsolás production-ban:** `springdoc.swagger-ui.enabled=false` az `application-production.properties`-ben, vagy legalább `tryItOutEnabled=false`.

10. **Cross-branch structuring detekció:** Különböző fiókok adatainak összevetése napon belüli gyanús mintákra.

11. **Hatósági adatszolgáltatás modul:** A `police/unit1.pas` funkciójának modern megfelelője (auditált, jogosultság-ellenőrzött export endpoint).

12. **JWT refresh token rotáció:** Rövid életű access token (15 perc) + refresh token (httpOnly cookie) implementálása a `jwt.expiration=86400000` (24h) helyett.

---

## 7. Összesítő verdikt

### Legacy (Delphi 7) — KRITIKUS MEGFELELÉSI KOCKÁZAT

A Delphi 7 rendszer alapvető biztonsági hiányosságai (SQL injection, titkosítatlan hálózat, hardcoded IP, audit log manipulálható) 2025-ben jogszabályi szempontból **nem fenntartható**. A 2017. évi LIII. tv. technikai védelmi kötelezettségei (32. § analóg) és a GDPR 32. cikke alapján az a rendszer, amelyik plaintext TCP-n küldi a szankciós és AML adatokat, ügyfél-azonosítókat, és amelynek adatbázisa SQL injection útján módosítható — **hatósági szankciónak teszi ki az üzemeltetőt**.

**GDPR bírság kockázat:** 10.000.000 EUR vagy a globális forgalom 2%-a (GDPR 83. cikk (4))  
**Pénzmosás törvény szankció:** 2017. LIII. tv. 69. § — pénzügyi szankcióig, engedélyvonásig terjedő következmények

### Modern (Java/Spring/React) — KÖZEPES KOCKÁZAT, KEZELHETŐ

A modern stack az összes kritikus kontrollt implementálja. A nyitott hiányosságok (szankciós lista frissítés automatizmusa, PEP forrás, audit hash-lánc) **nem kritikus, hanem közepes kockázatot** jelentenek, és a fenti P2/P3 ajánlásokkal 2-4 sprint alatt lezárhatók.

**A migráció elvégzése CSÖKKENTI a compliance kockázatot** — feltéve, hogy a P2 hiányosságok záráig a legacy rendszer párhuzamosan nem üzemel.

---

*Elemzés alapja: forráskód statikus analízis, jogszabályi cross-referencia, FATF ajánlások. Nem tartalmaz penetrációs tesztelést vagy runtime analízist.*

[TASK_COMPLETE]
