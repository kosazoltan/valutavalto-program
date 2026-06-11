# Legacy/ledger re-verifikáció + valós gap-zárás — verdikt (2026-06-10, 3. kör)

**User-direktíva:** a forrásfák (EXCMD, Felmérés, forrasok, Anti) összevetése a ledgerrel /
fejlesztési tervvel; a hibásan implementált vagy el sem készített részek felderítése és
önálló javítása — hazugság és hallucináció nélkül.

## Forrás-elérhetőségi tényállás (blokkoló FELOLDVA 2026-06-11)

- ~~A `scripts/legacy-transfer.py` Base64-híd a repóban van, de a **kódolt forráscsomag
  (`legacy-transfer/`) nem került pushra**~~ — **FELOLDVA 2026-06-11:** az Anti-fa
  becsomagolva és pusholva a dedikált **`legacy-transfer-data`** branchre
  (10 461 fájl: 8 304 szöveges forrás UTF-8-ban + 810 sha256-dedupolt bináris blob,
  ~1,65 GB). SZÁNDÉKOSAN nem main-en él: a CI-checkoutok ne hízzanak +1,6 GB-bal.
- **Felhő-oldali használat:**
  ```
  # explicit cél-refspec: single-branch clone-ban a sima fetch csak FETCH_HEAD-be menne
  git fetch origin legacy-transfer-data:refs/remotes/origin/legacy-transfer-data
  git checkout origin/legacy-transfer-data -- legacy-transfer/
  python scripts/legacy-transfer.py unpack --in legacy-transfer --dest Anti_transfer
  python scripts/legacy-binary-analyzer.py --anti-root Anti_transfer
  ```
- A `forrasok/` fa (808 MB, ~74%-ban az Anti duplikátuma név+méret szerint) NEM került
  külön csomagolásra; ha a re-verifikáció hiányt talál, ugyanezzel az eszközzel pótolható
  (`pack --source forrasok --out legacy-transfer-forrasok`).
- E körben a repóban lévő forrás-hű kivonatokból dolgoztunk: 394 modul-MD (223 .dpr lefedve),
  TPF0 form-dumpok, Felmérés (406 fájl), EXCMD specek + javítási utasítások.

## Verifikációs módszer és megbízhatósági tanulság

3 párhuzamos felderítő ügynök (flag-lánc / EXCMD-utasítások / Felmérés-követelmények) +
**minden gap-állítás kézi kód-elleni ellenőrzése**. Tanulság: az ügynök-riportok több
hamis-negatívot tartalmaztak — ezeket NEM fogadtuk el:

| Ügynök-állítás | Valóság (file:line) |
|---|---|
| „FK02-C teljesen implementálatlan" | `BranchRepository.findRateCreationAssignableCashierBranches:194` + `RateCreationService:698,755,792` + teszt |
| „Google vault két-fázisú belépés hiányzik" | `GoogleAuthController:109` (`/google-vault/select-worker`) + SecurityConfig + LoginResponseDto |
| „FATF tier-bekötés hiányzik" | `AmlService.java:113` (6-arg overload customerNationality-vel) + `:175-221` tier-akciók |
| „HandlingFee override workflow hiányzik" | V287 + `HandlingFeeOverrideService` + enum-pár |
| „ShipmentNewPage nyomtatás-integráció hiányzik" | `ShipmentNewPage.tsx:588-611` (ReceiptPreviewModal + printReceipt) |
| „StockSnapshot régió-csoportosítás kérdéses" | `StockSnapshotService:79-132` (FK-019 fix dokumentálva) |
| Felmérés: „BranchExchangeRate entity hiányzik" | a fiók/csoport-árfolyam a workgroup-alapú RFM rate-sheet architektúrával fedett (más néven) |

## VALÓS gap-ek (verifikált) és zárásuk e körben

1. **G3 flag sosem volt seedelve** — a `CLOSING_DISCREPANCY_EXPLANATION_REQUIRED` enforcement
   (`ClosingWizardService:490-506`) és a FE-flow kész volt, de EGYETLEN migráció sem seedelte
   → a NAV-eltérés-gate soha nem tudott élesedni. **Zárva: V307** (idempotens, V305/306 minta).
2. **`window.prompt` az Electron rendererben nem támogatott** — a ClosingWizardPage
   magyarázat-bekérése és a WU-sztornó indok-bekérése prompt-alapú volt; a penztar-client
   (Electron) ugyanezt az oldalt futtatja → a V307-élesítés a zárást beragasztotta volna.
   **Zárva:** inline modal mindkét helyen (a repo saját precedense:
   `CurrencyManagerModal.tsx:47`).
3. **SOF/SOW 10M Ft / 7 nap kumulált trigger [M] hiányzott** (AML-go-live-terv 2. pont,
   V.2.8 A.1): sehol nem volt 7-napos kumulált lekérdezés. **Zárva:** WU-flow gate
   (a szabály pénzátutalási): `enforceWuSofCumulative` + repository-query-k (company-szűrt,
   WuCustomer-id + név-fallback) + `wu_transactions` SOF-oszlopok + FE-mezők + V308 flag-seed
   + 9 teszt (28/28 zöld).

## Lezárt tételek (a verdikt utáni körökben)

- **AML-terv 4) Megerősített eljárás (EDD) követés [M]** — **ZÁRVA 2026-06-11 (PR #1079, V309):**
  `customer.edd_until/edd_reason/edd_set_at` + `AmlEddService` napi scan (a) >=50M egyedi,
  b) >=100M havi KÉSZPÉNZ-forgalom, hónapvége+1 év horgony) + `checkAllThresholds` olvasó-ág.
  Flag `AML_EDD_TRACKING_ENFORCEMENT` default FALSE — élesítés compliance-vezetői döntés.
  Követő kör: EDD-badge UI, Pmt.30.§(1) manuális jelölő, profil-kiugrás (g), pass-through (f).

## Nyitva maradt (őszintén, döntés-/inputfüggő)

- **AML-terv 5) szankció-pontszám (0.9/0.8 vs 0.5/0.7)**: megfelelési vezetői megerősítés kell.
- **Anti/forrasok bináris re-verifikáció**: a `legacy-transfer-data` branch pushjával
  feloldva — felhő-sessionben futtatható (fetch-parancs fent).
