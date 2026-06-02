# 05 — Beállítások + Bank API + Engedélyezés-adatok (doc↔kód reverifikáció)

Dátum: 2026-06-02
Auditált specifikációk:
- `EXCMD/b6-beallitasok.md` (FR-01..FR-15, `gep_konfiguracio` adatmodell)
- `EXCMD/b3-bank-api.md` (FR-API-01, FR-API-02, BankApiConfig/ExternalRateLog)
- `EXCMD/b3-engedelyezes-adatok.md` (FR-AUTH-01..FR-AUTH-08, TransactionApproval/ApprovalItems)

Módszer: minden követelmény egyenként; IMPLEMENTED csak `file:line` bizonyítékkal;
találat hiányában MISSING + keresési kulcs; backend vs frontend megkülönböztetve;
bizonytalan eset → VERIFIKÁLANDÓ.

---

## A) b6-beallitasok.md

> KIEMELT FÓKUSZ verifikáció (G20): a PenztarSettings store + UI **kész és működik**
> a perzisztencia szintjén; a "hardver-kötés runtime" (szkenner/nyomtató/futófény COM/IP,
> kijelzőszín, bankkártya-engedély) **továbbra is sub-scope** — a kód maga is így dokumentálja
> (`penztarSettings.ts:6-9`, `PenztarSettingsPage.tsx:16-18`). A beállítások **localStorage**-ba
> mentődnek (NEM SQLite/Postgres, NEM `gep_konfiguracio` tábla), és **nincs hardver-driver bekötés**.

| Köv. | Állapot | Bizonyíték / megjegyzés |
|---|---|---|
| FR-01 keret + 3 akciógomb | ⚠️ PARTIAL | UI panel + 2 gomb: `PenztarSettingsPage.tsx:168-175` ("Rögzítés és kilépés", "Kilépés módosítás nélkül"). A spec 3. gombja ("VISSZA A MENURE") + a bal oldali 12-fülös "TEMAK" lista NINCS — egyetlen scroll-panel. A FR-01/TBD-2 szerint "jelszóval védett" belépés: a route `/settings/penztar` **nem** kap role/jelszó guardot (`App.tsx:563`). |
| FR-02 ALAPFUNKCIO (3 rádió PENZTARI/ERTEKTARI/AFAS) | ✅ IMPLEMENTED | `penztarSettings.ts:11,35-36`; UI `PenztarSettingsPage.tsx:81-85`. |
| FR-03 ALKALMAZASOK (5 checkbox) | ✅ IMPLEMENTED | `PenztarSettingsPage.tsx:12,90-95` (VALUTAVALTAS, WESTERN_UNION, TESCO_AFA, METRO_AFA, E_KERESKEDELEM). |
| FR-04 KIJELZES SZINE (ZOLD/SARGA/PIROS) | ⚠️ PARTIAL | Rádiógomb kész: `PenztarSettingsPage.tsx:102-104`. Az élő VETEL/ELADAS előnézeti táblázat HIÁNYZIK; **a fizikai kijelző-szín kiküldése (COM) sub-scope** (runtime). |
| FR-05 IP-CIM (4 oktett 0–255) | ⚠️ PARTIAL | 4-oktett bevitel + validáció: `PenztarSettingsPage.tsx:116-126`, `penztarSettings.ts:53-66`. Csak localStorage-ba ment; tényleges szerver-IP-kapcsolat NINCS bekötve (sub-scope, TBD-7). |
| FR-06 JELSZO + e-mail + szombat | ⚠️ PARTIAL | E-mail + szombati nyitvatartás kész: `PenztarSettingsPage.tsx:139-146`, modell `penztarSettings.ts:22-23`. **A "NAPI JELENTES JELSZAVA" megjelenítés + "JELSZO MODOSITAS" gomb HIÁNYZIK** (a modellben nincs `dailyReportPassword`/hash mező). |
| FR-07 KESZLETEK BEKULDESE (0–25 csúszka) | ✅ IMPLEMENTED | `PenztarSettingsPage.tsx:128-134`; clamp 0–25 `penztarSettings.ts:32-33,57-61`. (Tényleges sync-gyakoriság bekötés sub-scope.) |
| FR-08 NYOMTATO (LPT1/USB rádió) | ⚠️ PARTIAL | Rádió kész: `PenztarSettingsPage.tsx:151-153`. **Nyomtató-port runtime bekötés sub-scope.** |
| FR-09 SCANNER | ⚠️ PARTIAL | Csak szabad-szöveges driver-mező: `PenztarSettingsPage.tsx:154-158`. A spec WIA/TWAIN driver-**lista** rádiógombos felsorolása + "nincs szkenner" jelzés HIÁNYZIK (sub-scope). |
| FR-10 KEZELESI KOLTSEG (NINCS/EZRELEKES/SAVOS) | ⚠️ PARTIAL | Mód-rádió kész: `PenztarSettingsPage.tsx:159-161`. A paraméter-panel (ezrelék/max/sávok) NEM itt van — külön `HandlingFeeConfigPage` + backend `HandlingFeeConfigController` (lásd FR-15). A b6 UI csak a módot tárolja, paramétert nem. |
| FR-11 FUTOFENY (tábla-szám, 2 COM, mód, sebesség) | ❌ MISSING | A `PenztarSettings` modellben NINCS futofeny mező (`penztarSettings.ts:17-30`), és a UI-on nincs futófény-panel. Kerestem: `futofeny`, `comport`, `futofeny_com`. Sub-scope (COM runtime). |
| FR-12 BANKKARTYA FIZETES | ⚠️ PARTIAL | Checkbox (engedélyezve/nincs) kész: `PenztarSettingsPage.tsx:162-165`, modell `cardPaymentEnabled` `penztarSettings.ts:28`. **A flag NINCS bekötve a tranzakciós képernyők POS-funkciójához** (sub-scope, TBD-6). |
| FR-13 REKLAM A KIJELZON | ⚠️ PARTIAL | Checkbox kész: `PenztarSettingsPage.tsx:105-108`, `adOnDisplay` `penztarSettings.ts:29`. Másodkijelzős reklám-runtime sub-scope (TBD-3). |
| FR-14 alsó gombok működése | ⚠️ PARTIAL | "Rögzítés és kilépés" (mentés+validáció+nav) `PenztarSettingsPage.tsx:45-57`; "Kilépés módosítás nélkül" `:172-174`. **Mentés localStorage-ba, NEM SQLite+Postgres** (a spec FR-14 explicit "lokális SQLite-ba és Postgres adatbázisba"). 3. gomb hiányzik. |
| FR-15 Kezelési-költség config jogosultságok | ✅ IMPLEMENTED | `HandlingFeeConfigController.java:31` — `@PreAuthorize("hasAnyRole('MANAGER','ADMIN','UGYVEZETO','IRODAVEZETO','BELSO_ELLENOR')")`. ⚠️ Eltérés: a spec `FOERTEKTAR` (Főértéktáros) szerepkört nevez meg, a kód `IRODAVEZETO`+`BELSO_ELLENOR`-t enged; `FOERTEKTAR` nincs a listán. VERIFIKÁLANDÓ, hogy a kanonikus role-készletben a Főértéktáros melyik névre képződik. |
| Adatmodell: `gep_konfiguracio` Postgres+SQLite tábla | ❌ MISSING | Nincs `gep_konfiguracio` migráció/entity. Kerestem: `gep_konfiguracio`, `GepKonfiguracio`, `MachineConfig` → csak a spec MD-ben (`b6-beallitasok.md`). A perzisztencia kizárólag böngésző-localStorage (`penztarSettings.ts:50` STORAGE_KEY='penztar-settings'). |

---

## B) b3-bank-api.md

| Köv. | Állapot | Bizonyíték / megjegyzés |
|---|---|---|
| FR-API-01 MNB SOAP `GetExchangeRates` | ✅ IMPLEMENTED | `MnbExchangeRateService.java:51` (`MNB_SOAP_URL=https://www.mnb.hu/arfolyamok.asmx`), SOAP request build `:170`, válasz-parsing `:187+`, `SOAPAction ...GetExchangeRates` `:134`. |
| FR-API-02 Raiffeisen REST + HTML-scraping fallback | ⚠️ PARTIAL | HTML-scraping IMPLEMENTED: `RaiffeisenRateService.java:34,146-179` (Jsoup), text-fallback `:230`. ❌ A spec "elsődleges REST API" (`api.rbinternational.com`, OAuth2/mTLS, `X-IBM-Client-Id`) NINCS implementálva — a kód **kizárólag** a `raiffeisen.hu` weboldal scraping-jét csinálja (`:36-39` hardcoded URL). Tehát a "fallback" itt az egyetlen út, nincs REST elsődleges. |
| Ütemezés (naponta 9:00 + 15:00 / munkanap 8:00) | ⚠️ PARTIAL | Raiffeisen scheduler `RaiffeisenRateScheduler.java:30` — `MON-FRI 08:00 Europe/Budapest` (NEM a TBD-4 szerinti "9:00 és 15:00"). MNB-re külön napi-kétszer scheduler nem azonosítva e fájlban; VERIFIKÁLANDÓ a teljes scheduler-réteg. |
| Adatmodell: `BANK_API_CONFIG` (endpoint_url, auth_token, update_frequency) | ❌ MISSING | Nincs ilyen tábla/entity. Kerestem: `bank_api_config`, `BANK_API_CONFIG`, `endpoint_url`, `auth_token`, `BankApiConfig` a `db/migration`-ben → 0 találat (a `V62__email_accounts.sql` csak álpozitív a `auth_token` regexre). Az endpoint-ok **hardcoded konstansok** a service-ekben. Nincs admin-konfigurálható API-kulcs/végpont. |
| Adatmodell: `MNB_RATES` / ExternalRateLog | ⚠️ PARTIAL | A letöltött árfolyamok az `mnb_exchange_rate_cache` táblába mennek (forrás-oszloppal: MNB / RAIFFEISEN), `RaiffeisenRateService.java:307-315`, `V120__mnb_cache_add_source_column.sql`. NEM külön `external_rate_log` séma, de funkcionálisan lefedi a tárolást. |
| Admin monitoring felület (utolsó sync állapot) | ✅ IMPLEMENTED | Backend `BankIntegrationStatusController.java:39-99` (`/api/v1/admin/bank-integration/status`), frontend `BankIntegrationStatusPage.tsx`. Megj.: ez monitoring, NEM API-kulcs/végpont konfiguráló (a b3-bank-api Phase 3 "API végpontok, kulcsok konfigurálása" felülete HIÁNYZIK — összefügg a BANK_API_CONFIG hiánnyal). |
| OUT: pénztári kliens NEM hív közvetlen bank API-t | ✅ IMPLEMENTED (by design) | A bank-integrációk backend-only service-ek; kliens csak a backendről szinkronizál. |

---

## C) b3-engedelyezes-adatok.md

> Megjegyzés: a spec egyetlen `TransactionApproval` (AML_ENGEDELYEZES) + `ApprovalItems`
> adatlapot/táblát feltételez minden tranzakciós engedélyhez. A kód **NEM** ezt a modellt
> használja: az engedélyezés három külön mechanizmusra bomlik —
> (1) AML magas-értékű jóváhagyás (WARN-only gate), (2) `StornoApproval` (sztornó),
> (3) `RateApproval` (árfolyam-felülírás). Nincs egységes "engedélykérő adatlap" entity
> a teljes FR-AUTH-01..06 mezőkészlettel.

| Köv. | Állapot | Bizonyíték / megjegyzés |
|---|---|---|
| FR-AUTH-01 Pénztár-azonosítás engedélykérőn (szám+név) | ⚠️ VERIFIKÁLANDÓ | Nincs dedikált "engedély megadása" adatlap-panel, ami pénztár-számot+nevet jelenít. A sztornó/4-szem flow `StornoService` branch-alapú (`StornoApproval.branch`), de a spec szerinti adatlap-megjelenítés (penztar_szama/penztar_neve mező) nem azonosított. Kerestem: `engedélykér`, `ApprovalPanel`, `SupervisorApproval`. |
| FR-AUTH-02 Bizonylatszám megjelenítése | ⚠️ VERIFIKÁLANDÓ | Bizonylatszám létezik a tranzakciós/sztornó-adatban, de dedikált engedélykérő-adatlapon való kötelező megjelenítés nem azonosított külön komponensként. |
| FR-AUTH-03 Tranzakció teljes forintértéke | ⚠️ PARTIAL | A HUF-érték végigvonul a tranzakción és AML-en (`TransactionService` hufAmount), de a spec szerinti engedélykérő-adatlap mező nem dedikált. |
| FR-AUTH-04 Valuta-soronkénti bontás (ApprovalItems) | ❌ MISSING | Nincs `ApprovalItems`/`AML_ENGEDELY_TETEL` tábla/entity soronkénti valuta-árfolyam-érték bontással engedélyhez kötve. Kerestem: `ApprovalItems`, `AML_ENGEDELY_TETEL`, `approval_id`. |
| FR-AUTH-05 Ügyfél-azonosító adatok (9 mező) | ✅ IMPLEMENTED (frontend) | `CustomerPanel.tsx`: név `:766`, anyja neve `:834-836`, szül. idő `:771-773`, szül. hely `:776-778`, lakcím `:839-842`, okmány típus `:806-814`, okmányszám `:817-821`, állampolgárság `:782-797`, tartózkodási hely (residence) `:844-848`. Megj.: ez a tranzakciós CustomerPanel, nem külön engedélykérő adatlap, de a teljes mezőkészletet tartalmazza. |
| FR-AUTH-06 Engedélyező személy rögzítése | ⚠️ PARTIAL | `StornoApproval.approvedByWorker` (`StornoApproval.java:85-87`) + `StornoService.approve` `:337` rögzíti a jóváhagyót, 4-szem-elv `:331`. De ez sztornó-specifikus; a magas-értékű AML-jóváhagyás `TransactionService.java:809-821` jelenleg **WARN-only** (enforcement default OFF, nincs supervisor-jóváhagyó UI a Buy/Sell képernyőn — a kód kommentje is így mondja `:803-805`). Általános "engedelyezo" mező a tranzakció-bizonylaton nem egységes. |
| FR-AUTH-07 Kétlépcsős Google OAuth belépés | ✅ IMPLEMENTED | Backend `GoogleAuthController.java:57-139` (`/google-login` → `vaultWorkerSelectionRequired`, majd `/google-vault/select-worker` jelszó+JWT), service `GoogleLoginService.java`, `Worker.shared_account` flag `V285__worker_shared_account_flag.sql`. (V285 — egyezik a memóriával.) |
| FR-AUTH-08 Állampolgárság kereshető szótár-dropdown | ⚠️ PARTIAL | `CustomerPanel.tsx:153` — `dictionaryApi.getByCategory('NATIONALITY')` betölt, `<select>` `:783-797` + SIMPLE ágon `:693-710`; seed `V286__nationality_dictionary_seed.sql`. ⚠️ A spec "kereshető, autocomplete" — a render sima `<select>` (NEM autocomplete/typeahead). Betöltési hibára 3-opciós fallback (`:789-795`). |
| Adatmodell: `TransactionApproval` (AML_ENGEDELYEZES) | ❌ MISSING | Nincs ilyen egységes entity/tábla. A `approval_status` találatok `StornoApproval`/`RateApproval` (`StornoApproval.java:18`, `RateApproval.java:21`) — más célú, szűkebb modellek. |
| SQLite offline OFFLINE_APPROVED + 4. sztornó supervisor jelszó | ⚠️ VERIFIKÁLANDÓ | A 4+ napi sztornó supervisor-jóváhagyása létezik (`StornoService` 4-szem + daily count), de a kliens-oldali SQLite `OFFLINE_APPROVED` státusz külön nem verifikált ebben a körben. |
| Integráció: WebSocket/HTTP push a kozponti-client felé | ⚠️ VERIFIKÁLANDÓ | Külön nem verifikált ebben a körben. |

---

## Záró statisztika

| Terület | ✅ teljes | ⚠️ részleges/eltérés | ❌ hiányzó | VERIFIKÁLANDÓ |
|---|---|---|---|---|
| b6-beallitasok (FR-01..15 + adatmodell) | 3 | 9 | 2 | 0 |
| b3-bank-api | 3 | 3 | 2 | 0 |
| b3-engedelyezes-adatok | 3 | 4 | 3 | 4 |
| **Összesen** | **9** | **16** | **7** | **4** |

### Kiemelt megállapítások (prioritás szerint)
- 🔴 **G20 perzisztencia-szint NEM a spec szerinti**: `gep_konfiguracio` SQLite+Postgres tábla HIÁNYZIK; a beállítások csak böngésző-localStorage-ban élnek (`penztarSettings.ts:50`). FR-14 explicit SQLite+Postgres mentést ír elő.
- 🔴 **Bank API config tábla HIÁNYZIK** (`BANK_API_CONFIG`): nincs admin-konfigurálható végpont/kulcs; URL-ek hardcoded. Raiffeisen REST API (OAuth2/mTLS) sincs — csak weboldal-scraping.
- 🔴 **Egységes `TransactionApproval`/`ApprovalItems` engedélykérő adatlap HIÁNYZIK**; az engedélyezés szétszórt (AML WARN-only gate + StornoApproval + RateApproval), és a magas-értékű AML-jóváhagyás enforcement default OFF, supervisor-UI nélkül.
- ⚠️ **FR-15 RBAC eltérés**: kód `MANAGER/ADMIN/UGYVEZETO/IRODAVEZETO/BELSO_ELLENOR`; a spec `FOERTEKTAR`-t kér, ami a listából hiányzik (`HandlingFeeConfigController.java:31`).
- ⚠️ **FR-11 FUTOFENY teljesen hiányzik** a beállítás-modellből és UI-ból (sub-scope, COM-runtime).
- ⚠️ **FR-AUTH-08 nem autocomplete**, csak sima `<select>` (spec "kereshető/autocomplete").
- ✅ Megerősítve: G20 store+UI a perzisztencia-szinten kész és működik; a hardver-kötés runtime (szkenner/nyomtató/futófény COM/IP, kijelzőszín, bankkártya-engedély) maradt sub-scope — ezt a kód kommentjei is explicit így jelölik.
