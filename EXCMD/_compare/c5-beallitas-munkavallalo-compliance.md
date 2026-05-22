# C5 összevetés — Beállítások (b6) + Munkavállaló-nyilvántartás (b9) + Körlevelek/compliance (b9)

Forrás specek: `EXCMD/b6-beallitasok.md`, `EXCMD/b9-munkavallalo-nyilvantartas.md`, `EXCMD/b9-korlevelek-compliance.md`.
Kód-állapot: v2.26.18 (main). KUTATÁS-only.

---

## 1. Beállítások (b6) — pénztáros-gép konfigurációs képernyők

A spec a régi pénztáros program **gép-szintű** beállító képernyőit írja le (12 fül). A jelenlegi
`frontend-react/src/pages/settings/SettingsPage.tsx` egy **admin web tab-keret** (cégadatok,
felhasználók, jogosultságok, MFA…), NEM a pénztárgép-config képernyő. A `printing`/`database`/
`security`/`notifications`/`appearance` tab-ok **hardcoded dummy mezők, save-handler nélkül**
(pl. `SettingsPage.tsx:252-289` printing tab: `<button className="form-button-primary">Mentés</button>` — nincs `onClick`).
A penztar-client (Electron) renderer a frontend-react oldalt használja; **nincs gép-szintű config feature**
(`Grep` a `penztar-client/electron`-ban csak node_modules/electron belső találat futofeny/comport/ip-re).

| FR | Leírás | Státusz | Bizonyíték / hiány |
|---|---|---|---|
| FR-01 | Beállítás-keret (12 fül + 3 gomb) | PARTIAL | `SettingsPage.tsx:88-103` 14 tab, de más tartalom (admin), nem a 12 gép-fül |
| FR-02 | ALAPFUNKCIÓ (gép-szerep: pénztári/értéktári/áfás) | PARTIAL | gép-szerep = `appMode` build-flag (Electron), NEM futásidőben váltható radio. Nincs settings UI |
| FR-03 | ALKALMAZÁSOK multi-select (WU/Tesco ÁFA/Metro/e-keresk.) | MISSING | nincs UI/perzisztencia |
| FR-04 | KIJELZÉS SZÍNE (árfolyam-kijelző zöld/sárga/piros) | MISSING | nincs |
| FR-05 | IP-CÍM 4-oktett szerver-IP | MISSING | központi szerver URL `production-urls.json`-ból, nincs oktett-UI |
| FR-06 | JELSZÓ (napi jelentés) + értéktár e-mail + szombati nyitvatartás | MISSING | nincs napi-jelentés-jelszó / szombat-radio settings |
| FR-07 | KÉSZLETEK BEKÜLDÉSE gyakoriság (perc csúszka) | MISSING | sync van (`sync-engine.ts`), de nincs konfigurálható gyakoriság-UI |
| FR-08 | NYOMTATÓ port (LPT1/USB radio) | PARTIAL | `SettingsPage.tsx:252` printing tab dummy (Epson/Star select), nincs LPT/USB radio, nincs save |
| FR-09 | SCANNER driver-lista (WIA/TWAIN) | MISSING | nincs |
| FR-10 | KEZELÉSI KÖLTSÉG (nincs/ezrelékes/sávos + paraméter) | IMPLEMENTED | `entity/HandlingFeeType.java` (NONE/PER_MILLE/BRACKET) + `HandlingFeeService` + `HandlingFeeConfigController` + `HandlingFeeBracket`. Üzleti logika kész, csak a régi UI-képernyő hiányzik |
| FR-11 | FUTÓFÉNY (tábla-szám/comport/mód/sebesség) | MISSING | nincs |
| FR-12 | BANKKÁRTYA fizetés engedély radio | MISSING | nincs settings (a 7.sz körlevél gyanú-logika is hiányzik, lásd lent) |
| FR-13 | REKLÁM a kijelzőn radio | MISSING | nincs |
| FR-14 | Közös gombsor (Rögzítés/Kilépés/Vissza) | MISSING | nincs gép-config keret |

---

## 2. Munkavállaló-nyilvántartás (b9) — dolgozói törzs

Van `entity/Employee.java` (HR törzs, gazdag) + `EmployeeAddress` + `EmployeeBankAccount`.
Nincs külön szabadság / gyerek / üzemorvosi / okmány-tábla entitás (`Glob Employee*Leave*` → 0 találat;
`Grep child|leave|occupational|certificate_number` az entity csomagban → csak Employee.java a kedvezmény-mezőkkel).

| FR | Leírás | Státusz | Bizonyíték / hiány |
|---|---|---|---|
| FR-01 | Felhasználónév (login) | IMPLEMENTED | `Worker` entity (login) — Employee `worker_id` FK `Employee.java:48` |
| FR-02 | Jelszó | IMPLEMENTED | Worker auth |
| FR-03 | Kötelező `Kód` azonosító | PARTIAL | `Employee.serialNumber` (`:57`) import-sorszám, nem a "Kód *" kötelező mező |
| FR-04 | `Egyedi jel` szabad mező | MISSING | nincs `unique_mark`/`egyediJel` mező az Employee-ban |
| FR-05 | Név-mezők (vezeték/utó/titulus/szül.nevek) | PARTIAL | `lastName/firstName/birthLastName/birthFirstName` (`:62-75`) megvan; **Titulus hiányzik** |
| FR-06 | Anyja neve 2 mezőben | PARTIAL | csak `mothersName` egy mező (`:87`), nincs vezeték+kereszt bontás |
| FR-07 | Szül. hely + dátum/idő | PARTIAL | `birthPlace`+`birthDate` (`:91,99`); **születési idő (óra:perc) hiányzik** |
| FR-08 | Két állampolgárság (1*/2) | PARTIAL | csak `citizenship` egy mező (`:103`), nincs állampolgárság_2 |
| FR-09 | 3 strukturált cím | PARTIAL | `EmployeeAddress` 1:N létezik; strukturáltság/3-féle típus a típus-enumtól függ (nem ellenőrzött) |
| FR-10 | "Megegyezik a … címmel" másoló checkbox | MISSING | frontend logika, nem ellenőrizhető backend-ből (UI hiány valószínű) |
| FR-11 | Igazoló okmányok 1:N tábla (típus/szám/lejárat/dok) | PARTIAL | csak egy `idCardNumber`+`idCardExpiry` (`:108-113`), NINCS 1:N okmány-tábla több okmányra |
| FR-12 | Bankszámla szám | IMPLEMENTED | `EmployeeBankAccount` 1:N (`:266`) |
| FR-13 | Iskolai végzettség + bizonyítvány szám | PARTIAL | `vocationalQualification`+`certificateDate` (`:198,203`); **bizonyítvány SZÁMA mező hiányzik** |
| FR-14 | Becsüs / Eladói / Valutapénztárosi bizonyítvány szám + checkbox | MISSING | nincs egyik szakmai bizonyítvány-szám mező sem |
| FR-15 | Elérhetőségek 1:N (típus + érték) | PARTIAL | csak `email`+`phone` skalár (`:119,123`), nincs 1:N elérhetőség-blokk |
| FR-16 | Fiókok+jogosultságok fontossági sorrend | PARTIAL | `WorkerRoleAssignment`/`WorkerBranchAccess` létezik, de a "fontossági sorrend" UI/mező nem ellenőrzött |
| FR-17 | Jogviszony kezdete/vége | IMPLEMENTED | `employmentStartDate`/`employmentEndDate` (`:148,156`) |
| FR-18 | Dolgozó státusza + foglalkoztatás típusa | PARTIAL | `employmentType` (`:152`) megvan, külön "státusz" legördülő nincs (van `active` boolean) |
| FR-19 | Szabadságok évenkénti tábla (10 oszlop) | MISSING | nincs `EmployeeLeave`/szabadság entitás |
| FR-20 | Gyerekek szekció | MISSING | nincs gyerek entitás (csak adókedvezmény-szöveg mezők `:216-249`) |
| FR-21 | Egyéb iratok 1:N tábla | MISSING | nincs irat/dokumentum entitás az Employee-hoz |
| FR-22 | Üzemorvosi vizsgálat tábla | MISSING | nincs `OccupationalMedical`/üzemorvosi entitás |
| FR-23 | További fülek (Képesítések/Iratok/Autók/Tappénz/Kapcsolatok…) | MISSING | nincs |
| FR-24 | Adatlap gombok (Vissza/Mentés/Megsem) | PARTIAL | EmployeePage CRUD valószínű, de a fent hiányzó mezők miatt nem teljes |
| FR-25 | Születésnap/névnap értesítés kapcsoló | MISSING | nincs |
| FR-26 | Fénykép/avatar | MISSING | nincs photo mező |

---

## 3. Körlevelek / compliance (b9)

Van teljes körlevél-modul: `entity/Circular.java`, `CircularAcknowledgment`, `CircularType` (17 típus),
`CircularService` (CRUD+ack), `CircularController`, frontend `CircularPage.tsx` + `ReportsCirculars.tsx`.
Van szankció-szűrés: `SanctionScreeningService` (UN/EU/OFAC XML import, **név/okmány-alapú**),
`SanctionEntry`, `SanctionListScheduler`. **FATF ország-szintű többszintű lista NINCS** sehol
(`Grep FATF|North Korea|Myanmar|tier` a backend java-ban → 0 valós találat; `SanctionEntry` csak
`nationality` String mezőt tárol, nincs 1/a-1/b-2 csoport-szint).

| FR | Leírás | Státusz | Bizonyíték / hiány |
|---|---|---|---|
| FR-01 | Körlevél metaadatok (iktatószám/tárgy/készítő/dátum) | IMPLEMENTED | `Circular.java:39,53,113,125` (title, createdBy, validFrom/To, registrationNumber) |
| FR-02 | Szerepkörönkénti "elolvasta/visszaigazolta" | PARTIAL | `CircularAcknowledgment` per-worker (`:30 worker_id`), de **NINCS szerepkör-bontás** (Területi vezető / Belső ellenőr / Pénztáros külön nincs követve) |
| FR-03 | Bankkártya-csalás eszkaláció (gyanú jelzés + tranzakció-felfüggesztés) | MISSING | nincs eszkalációs/felfüggesztési flow |
| FR-04 | Gyanú-jelek (több penztár/papírról PIN/telefonról összeg) | MISSING | nincs gyanú-jel értékelő |
| FR-05 | FATF 3 szint (1/a, 1/b, 2.) tárolás | MISSING | nincs FATF entitás/tier |
| FR-06 | FATF lista változtatható + verzió/dátum követés | MISSING | nincs FATF verziókövetés |
| FR-07 | 9.sz körlevél kezdő FATF állapot betölthető | MISSING | nincs FATF seed (Észak-Korea/Irán/Myanmar/21 ország) |
| FR-08 | Ügyfél állampolgárság ellenőrzése FATF lista ellen tranzakciókor | MISSING | tranzakció-flow csak név/okmány szankció-szűrést hív, nincs ország-FATF check |
| FR-09 | Körlevél-tár megjelenítés a kliensben | IMPLEMENTED | `CircularPage.tsx` + `ReportsCirculars.tsx` |
| FR-10 | Körlevél elolvasás naplózása auditra | IMPLEMENTED | `CircularAcknowledgment.acknowledgedAt`+`ipAddress` (`:33,36`) |

---

## VALÓS GAP-EK (prioritással)

### P0 — compliance-kritikus (jogszabályi / AML)
1. **FATF többszintű ország-lista teljesen hiányzik** (b9-korlevel FR-05..FR-08). A `SanctionScreeningService`
   csak név/okmány-alapú UN/EU/OFAC szűrést végez; `SanctionEntry.java:51` csak `nationality` String,
   nincs 1/a (Észak-Korea, Irán) / 1/b (Myanmar) / 2. csoport tier, nincs ország-alapú tranzakció-ellenőrzés,
   nincs verzió/dátum-követés. **Ez a 9.sz körlevél lényege — nincs implementálva.**
2. **Bankkártya-csalás gyanú-eszkaláció hiányzik** (7.sz körlevél, FR-03/FR-04). Nincs gyanú-jel értékelés
   (több pénztár/napi ismétlés/papírról PIN) és nincs tranzakció-felfüggesztés-döntésig flow.

### P1 — HR-törzs hiányzó kötelező nyilvántartások
3. **Üzemorvosi vizsgálat nyilvántartás teljesen hiányzik** (FR-22) — nincs entitás, pedig munkavédelmi kötelezettség.
4. **Szabadság-nyilvántartás (évenkénti, 10 oszlop) hiányzik** (FR-19) — nincs `EmployeeLeave` entitás.
5. **Gyerekek nyilvántartás hiányzik** (FR-20) — csak adókedvezmény-szöveg mezők (`Employee.java:216-249`),
   nincs gyermek-rekord (név/szül.dátum).
6. **Igazoló okmányok 1:N tábla hiányzik** (FR-11) — csak egyetlen `idCardNumber` (`:108`); több okmány
   (útlevél/jogosítvány/lejárat) nem rögzíthető.
7. **Szakmai bizonyítvány-számok hiányoznak** (FR-14) — Becsüs/Eladói/Valutapénztárosi bizonyítvány szám
   nincs; ez valutaváltó-szakmaspecifikus képesítés-igazolás.

### P2 — beállítás-képernyők (gép-szintű config)
8. **A pénztáros-gép beállító-képernyő nem létezik** (b6 FR-02..FR-14, FR-10 kivételével). Hiányzik:
   árfolyam-kijelző szín, futófény-config, szkenner-driver, IP-oktett UI, bankkártya-engedély,
   napi-jelentés-jelszó, adatküldés-gyakoriság, reklám. A `SettingsPage` printing/security/database tab-ok
   **dummy-k save nélkül** (`SettingsPage.tsx:252-418`).
9. **Körlevél szerepkörönkénti visszaigazolás-bontás hiányzik** (FR-02) — `CircularAcknowledgment` csak
   `worker_id`-t tárol, nincs Területi vezető / Belső ellenőr / Pénztáros szerep-szintű compliance-követés.

### P3 — HR mező-finomságok
10. Hiányzó skalár mezők: `Egyedi jel` (FR-04), Titulus (FR-05), Anyja neve 2 mezőben (FR-06),
    születési idő óra:perc (FR-07), állampolgárság_2 (FR-08), bizonyítvány-szám (FR-13),
    1:N elérhetőség-blokk (FR-15), fénykép (FR-26), születésnap/névnap értesítés (FR-25).
