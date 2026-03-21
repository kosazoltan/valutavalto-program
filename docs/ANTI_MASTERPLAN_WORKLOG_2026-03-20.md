# Anti Reverse Engineering Worklog (2026-03-20)

## 0. Cél
- Az Anti mappa és a meglévő dokumentációk alapján egyetlen végrehajtható AI programozási master utasítás készítése.
- Fókusz: kamera helyi rögzítés (50 nap), offline-first működés, szerver szinkron, napi jelentések (Darius/Raiffeisen), jogosultsági modell.

## 1. Első találatok
- Kötelező security skill beolvasva: `.claude/skills/security-deploy-gate/SKILL.md`.
- Anti gyökér fő ágak: `camera/`, `camera2/`, `camera3/`, `ERTEKTAR/`, `SZERVER/`, `VALUTA/`, `ARFOLYAM/`, `KORLEVEL_ZIP/`, `firebird/`.
- Repozitóriumban már léteznek erős kiinduló dokumentumok:
  - `docs/IMPLEMENTATION_PLAN_CAMERA_AND_RATES.md`
  - `docs/AI_EXECUTION_MASTERPLAN.md`
  - `docs/ANTI_LEGACY_PARITY_SPEC.md`
  - `docs/legacy-analysis-part1-core-docs.md`
  - `docs/legacy-analysis-part4-technical.md`
- Darius/Raiffeisen nyomok azonosítva (interjú és technikai elemzés dokumentumokban), plusz napi jelentés és jelentés workflow referenciák.

## 2. Anti fájltípus gyors inventory (első futás)
- java: 1614
- pas: 420
- dfm: 419
- dpr: 279
- xml: 204
- js: 10
- sql: 6
- cs: 5

## 3. Következő lépések
- Anti alatt a valódi forráskód fájlok strukturált kigyűjtése (kamera + szerver + értéktár + valuta).
- Működési folyamatok visszafejtése modulonként.
- Egységes végrehajtási terv összeállítása AI ügynök számára.

## 4. Tartósan mentett kód-inventár
- `docs/anti-code-files.txt`: Anti alatti kiválasztott kódfájl-lista.
- `docs/anti-code-summary.csv`: modul + kiterjesztés darabszám összesítő.

Fő megállapítás:
- `camera2` és `camera3` ágakban külön kameraalkalmazás-rétegek láthatók.
- `VALUTA` ágban a kulcs üzleti logika Delphi DLL-ekben van (napi jelentés, napzárás, átadás-átvétel, körlevél).

## 5. Legacy VALUTA kulcsmodulok (forrás bizonyítékok)

### 5.1 NAPIJEL (`Anti/VALUTA/DLL/NAPIJEL/MAKEDLL/Unit2.pas`)
- Napi jelentés összeállítás és beküldés logika (`JelentesIras`, `BekuldoGombClick`).
- Jelszó-kezelés hardverből (`Getjelszo`, `JELSZO`, `JELSZOKELTE` mezők).
- Értéktárhoz kötött jelentésfájl-képzés (`GetJelentesPath`, `_ertektar`).

### 5.2 NAPZAR (`Anti/VALUTA/DLL/NAPZAR/MAKEDLL/Unit2.pas`)
- Teljes napzárási lánc: ellenőrzések, napi jelentés, dekád, havi gyűjtő.
- Legacy függőségek: `napijel.dll`, `navzaro.dll`, `otp.dll`, `nznyomt.dll`.
- Nyitó/záró készlet és napi forgalom meghatározási logika (`NyitoMeghatarozas`, `NapiForgalomSzamitas`).

### 5.3 ATADVET (`Anti/VALUTA/DLL/ATADVET/MAKEDLL/Unit2.pas`)
- Pénztár↔értéktár tranzakciós műveletek (`PenztarAllAtvetel`, `ErtektarAllAtvetel`).
- Stornó és plomba-szám kezelési logika (`STORNO`, `PLOMBASZAM`, `TRBPENZTAR`).
- FTP/szerver irányú adatküldési útvonal (`FtpSzerverreLep`, `RemdirCtrlAndSend`).
- WU és egyéb mozgások külön könyvelése (`WUMOZGAS` insert minták).

### 5.4 KORLEV (`Anti/VALUTA/DLL/KORLEV/MAKEDLL/Unit2.pas`)
- Körlevél letöltés és olvasás FTP alapon.
- Hardcoded hitelesítési nyomok: `_userId`, `_ftpPassword`, `_ftpport`.
- Szerver oldali `korlevel.fdb` + `ptarosok.fdb` elérés.

## 6. Kamera rendszer visszafejtés (camera2)

### 6.1 Rögzítés
- `PublicCameraThread` és `PrivateCameraThread`: 300 ms ciklusú képlekérés, kamera állapotfigyelés.
- `PublicCameraFilmRecorderService` és `PrivateCameraFilmRecorderService`: 2 másodperces mentési ciklus.
- Fájlnévképzés órás szegmensben:
  - pénztári kamera: `...-hour.C1`
  - intim kamera: `...-hour.C2`
- Bizonylatszám bekötés: `CurrencyExchangeApi.getReceiptNumber()` (`C:\valuta\aktbizo.txt`).

Megjegyzés:
- A forrásban a tényleges fájlba írás sor kommentelt (`filmFileService.save(...)`), ezért a mentési lánc részben inaktív vagy más modulba szervezett lehet.

### 6.2 Visszajátszás és export
- `ExportModel` + `ExportController`: dátumtartományos export, public/private kamera szelekció, lejátszó másolása.
- `FilmConverterMainThread` + `FilmConverterWorkerThread`: fájl alapú export a célnyvtárba.
- `PlayerModel`: C1/C2 bináris frame-formátum feldolgozás, 16 byte headerből idő és bizonylatszám olvasás.

### 6.3 Retention és adatjavítás
- `FilmMaintenanceConfiguration`: 50 napos törlési küszöb, diszk telítettség esetén agresszívabb takarítás.
- `ExcludedFilmMaintenanceConfiguration` és `ExcludedOldFilmMaintenanceConfiguration`: régi mappákból (`Kamera filmek`, `Régi kamera filmek`) 50 napos takarítás.
- `LastFilmValidatorConfiguration`: sérült kamerafájl végének levágása (repair) valid JPEG olvasás alapján.

### 6.4 Jogosultság
- `SupervisorController` + `SupervisorModel`: külön supervisor unlock folyamat (QR + kód).

## 7. Kamera rendszer visszafejtés (camera3/old)
- `StorageMaintanerThread`: explicit 50 napos retention (`dayLimit = 50`) + tárhely alapon dinamikus csökkentés.
- `AuthsEnum`: szerepkörök: `Adminisztrátor`, `Területi vezető`, `Kamera ellenőr`.
- `RemoteClient` és kapcsolódó szálak: központi listázás, film szinkron, fájldarabolt továbbítás.
- `ConfigurationReader`: film/error/log path + email konfiguráció szerveroldalon.

## 8. Darius/Raiffeisen és jelentéskötelezettség
- Forrásdokumentum bizonyíték: `docs/legacy-analysis-part1-core-docs.md`.
- Üzleti elvárás azonosítva:
  - napi elszámolási kötelezettség a Raiffeisen felé,
  - tranzakciók beküldése Darius felületen,
  - havi teljes elszámolás.
- Adatbázis nyom: `darius.fdb` szerepel technikai elemzésben (`docs/legacy-analysis-part4-technical.md`).

## 9. Kockázati megállapítások
- Több legacy komponensben hardcoded hitelesítő adatok/jelszó-nyomok.
- Vegyes technológiai generációk (Delphi DLL + Java desktop + FTP/file alapú adatcsere).
- Számos folyamat még fájlrendszer-függő, részben implicit (kódban szétszórt).

## 10. Uj konszolidalt vegrehajtasi anyag
- Letrehozva: `docs/AI_AGENT_END_TO_END_EXECUTION_PLAYBOOK_2026-03-20.md`
- Cel: egyetlen 1->N sorrendu AI implementacios utasitascsomag.
- Tartalom:
  - fix stack dontes (backend/frontend/electron),
  - kotelezo kovetelmenyek (kamera 50 nap, role gate, Darius),
  - vegrehajtasi sorrend kapukkal,
  - komponensenkenti kotelezo feladatszalak,
  - teszt/security gate szabalyok,
  - atadasi Definition of Done.

## 11. Current rendszer kodalapu parity-felmeres (2026-03-20, kesoi frissites)

### 11.1 Vizsgalt current forrasteruletek
- Backend core: `TransactionController/Service`, `TransferController/Service`, `DailyReportController/Service`, `TreasuryController/TreasuryDashboardService`, `ExchangeRateService`, `Sync*`, `FtpSync*`, `Camera*` service-ek.
- Electron: `sync-engine.ts`, `sqlite.ts`, `camera.ts`, `main.ts`, `preload.ts`.
- Frontend route felulet: `frontend-react/src/App.tsx` + camera/sync/treasury oldalak.

### 11.2 Bizonyitott current erossegek
- Tranzakcios magfolyamatok es AML/POS/idempotencia jelen vannak.
- Transfer domainben direction-fuggo (F/U/UF/FF) counter-tranzakcio logika implementalt.
- Offline queue es periodikus sync motor stabil alapot ad (pending tablak + idempotency key-k).
- Kamera local recording + retention + local cleanup/export mukodik.
- 24 oras arfolyam TTL ellenorzes es max deviation validacio implementalt.

### 11.3 Azonositott parity gap-ek (kritikus)
- Darius/Raiffeisen napi riport adapter nem latszik implementaltnak.
- `FtpSyncService` jelenleg mock/log bridge.
- `SyncService` es `SynchronizationService` simplified/szimulacios jellegu.
- `CameraUploadService` valos upload helyett mock uploadot jelez.
- Kamera titkositas jelenleg konfiguracios deklaracio (futo crypto pipeline nem azonositott).
- `CameraTransactionLinker` letezik, de tranzakcio mentesi flow-hoz nincs explicit bekotese.

### 11.4 Dokumentumfrissites eredmenye
- `ANTI_UNIFIED_MASTERPLAN_AND_AI_INSTRUCTION_2026-03-20.md`: uj "Current kodszintu allapotfelmeres" + parity matrix + P0/P1/P2 zarasi terv.
- `JIRA_SPRINT_BREAKDOWN_AND_DEV_CHECKLIST_2026-03-20.md`: uj "Current parity gap backlog" (VAL-CH-* issuek).
- `AI_AGENT_END_TO_END_EXECUTION_PLAYBOOK_2026-03-20.md`: uj "Delta mod" vegrehajtasi fejezet mar reszben implementalt rendszerre.

