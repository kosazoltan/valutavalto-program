# Legacy vs Új Rendszer — Részletes Üzleti Logika Összehasonlítás

**Dátum:** 2026-03-05
**Forrás:** D:\repo\valutavalto-program\forrasok\ (VALUTA, ERTEKTAR, SZERVER)

---

## 1. ELADÁS (ELADAS.DLL → TransactionService.sell)

### Legacy (136K, 228 proc/func):
- **SorBeirasVTempbe**: INSERT/UPDATE INTO VTEMP tábla (max 6 sor, valutanemenként)
- **GetKezelesidij**: Sávos VAGY ezrelékes (`_realEzrelek/1000`), max limit (`_kezdijmax`)
- **KedvezmenyAnalizis**: `_sorEngedmeny[cc]=8` → setraterutin() → kedvezmény típus kód
- **BlokkFejIro/Blokkteteliro**: Bizonylat nyomtatás COM porton
- **FizetendoDisplay**: `_netto + _kerekites + _fizetendo` számítás
- **VtempDataPotlas**: Dátum, idő, pénztáros, stornó flag, fizetendő beírás VTEMP-be
- **QRkodLerendezes**: QR kód generálás a bizonylathoz
- **LimitDisplay/GetLimitOsszeg**: Göngyölés limit megjelenítés
- **RemoteParancs**: Távoli szerver kommunikáció
- **KonvertHiba/GetKonvertAdatok**: Konverziós tranzakció kezelés

### Új rendszer (TransactionService.java):
- ✅ TransactionLine entity (N sor, nem max 6)
- ✅ HandlingFeeService (sávos + ezrelékes + SHK)
- ✅ Kedvezmény 5 típus (VIP, F1, SENIOR, FŐÉRTÉKTÁROS, SHK)
- ✅ QrCodeService (bizonylat QR)
- ⚠️ VTEMP logika → nincs közvetlen megfelelője (tranzakció közvetlenül az Entity-be megy)
- ⚠️ Bizonylat nyomtatás → Receipt entity kész, de fizikai nyomtatás (COM port) NINCS
- ⚠️ Remote parancs → nem releváns (REST API-n keresztül megy minden)

### HIÁNYZIK az új rendszerből:
1. ~~Foglaló kezelés~~ → FOGLALO.DLL (83K, 166 func!) — valuta foglaló ügyfélnek, határidős ügylet
2. ~~Konverzió részletes hibakezelés~~ → a konverziós hiba workflow hiányzik
3. ~~Bankjegy specifikus kezelés~~ → `_aktbankjegy` — a legacy különválasztotta a bankjegy darabszámot

---

## 2. VÁSÁRLÁS (VASARLAS.DLL → TransactionService.buy)

### Legacy (104K, 161 proc/func):
- Szinte TÜKÖRKÉPE az eladásnak, de fordított irányban
- **GetKezelesidij**: Ugyanaz mint eladásnál
- Ügyfél azonosítás: BIGCTRL.DLL hívás (göngyölés ellenőrzés)

### Új rendszer:
- ✅ TransactionService.buy() — működik
- ✅ AmlService — göngyölés ellenőrzés
- ❌ **A vásárlás és eladás SZÁMÍTÁSI IRÁNYA** — ellenőrizendő!

### Legacy számítás iránya:
- **ELADÁS** (mi adunk valutát, kapunk HUF-ot): `HUF = bankjegy × eladási_ár`
- **VÁSÁRLÁS** (mi kapunk valutát, adunk HUF-ot): `HUF = bankjegy × vételi_ár`
- **A kezelési díj MINDIG a HUF összegből számolódik**

---

## 3. AML / GÖNGYÖLÉS (BIGCTRL.DLL → AmlService)

### Legacy (45K, 69 proc/func):
- **_evimax**: Éves maximum összeg (FieldByName('EVIMAX').asInteger)
- **_gongyolt**: Göngyölt forgalom
- **_hetiforint**: Heti forint forgalom
- Azonosítás: 4 adatból 2 egyezés → azonosított ügyfél
- ÜGYFÉL tábla: `AZONOSITO`, `OKMANYTIPUS`, `ALLAMPOLGAR`, `LAKCIM`, `TARTOZKODASIHELY`
- **Küszöbök**: A kódban `8000000` (8M) jelenik meg mint ellenőrzési határ
- **Természetes és jogi személy külön kezelés** (NaturAdatBeolvasas, JogiAdatBeolvasas)

### Új rendszer (AmlService.java):
- ✅ 300K (napi), 1.5M (90 nap), 3.6M (365 nap) küszöbök
- ✅ Customer entity (documentNumber, documentType)
- ⚠️ **_evimax=8M**: A legacy-ban 8M a felső határ — ez lehet **éves bejelentési kötelezettség**
- ⚠️ **Jogi személy**: Külön kezelés a legacy-ban, az új rendszerben EGY Customer entity
- ❌ **Heti forint göngyölés**: `_hetiforint` — az új rendszerben NINCS heti limit
- ❌ **4-ből-2 azonosítási logika**: A legacy így azonosítja az ügyfelet — az új rendszer EXACT match

### JAVÍTANDÓ:
- **8M éves küszöb** hozzáadása az AML-hez
- **Heti göngyölés** hozzáadása
- **Jogi/természetes személy szétválasztás** a Customer entity-ben

---

## 4. KEZELÉSI DÍJ (KEZDIJ.DLL → HandlingFeeService)

### Legacy (31K, 80 proc/func):
- **Sávos rendszer**: `_kdij[1..maxsavdb]` + `_tranzsav[1..maxsavdb]` → ha összeg ≤ sáv → díj
- **Ezrelékes rendszer**: `_realEzrelek > 0` → `összeg × ezrelék / 1000`, max `_kezdijmax`
- **Kerekítés**: `Kerekito()` → HALF_UP
- **Kezdij engedmény**: F1 → 50%, VIP → 70%, Főértéktáros → 100%, stb.
- **SHK (Speciális Házi Kedvezmény)**: Napi keret, DB-ből olvasva

### Új rendszer (HandlingFeeService.java):
- ✅ Sávos (HandlingFeeBracket)
- ✅ Ezrelékes (SHK)
- ✅ Kerekítés HALF_UP
- ✅ 5 kedvezmény típus
- ✅ SHK napi keret (countShkTransactionsToday query — HIGH fix)
- ⚠️ **roundToFive()**: A legacy `Kerekito()` 5-re kerekít (5 Ft-os érmék) — ELLENŐRIZNI

---

## 5. NAPZÁRÁS (NAPZAR.DLL → DailyClosingService)

### Legacy (44K, 65 proc/func) — 11 ellenőrzési pont:
1. **MTCN kontroll** (Western Union — van-e kitöltetlen MTCN szám?)
2. **Esti pénztár címletezés** (CimletCtrlRutin — egyezik-e?)
3. **Kezelési díj címletezés** (CimletCtrlRutin — egyezik-e?)
4. **Western Union címletezés** (ha van WU)
5. **OTP címletezés** (ha van OTP POS)
6. **Foglaló címletezés** (ha van foglaló)
7. **Dekád zárás** (10 naponként — DekZarCtrl)
8. **Havi zárás** (utolsó munkanapon — HaviGyujtokbeMasolas)
9. **Napkönyv nyomtatás** (NzNyomtRutin)
10. **Forgalom beolvasás és elküldés** (ForgalomBeolvasas + SendingRutin)
11. **Nyitó meghatározás** (NyitoMeghatarozas — másnapi nyitókészlet)

### Új rendszer (DailyClosingService + ClosingWizard):
- ✅ 9 lépéses wizard (ClosingWizardStep entity)
- ⚠️ **MTCN kontroll hiányzik** (Western Union nem implementált)
- ⚠️ **Dekád zárás**: A kód mostmár létrehoz AuditLog record-ot (HIGH fix), de a dekád riport generálás HIÁNYZIK
- ⚠️ **Havi zárás**: `HaviGyujtokbeMasolas` — ez a havi összesítő táblába másolja az adatokat → NINCS implementálva
- ⚠️ **Nyitó meghatározás**: `NyitoMeghatarozas` — ez a másnapi nyitókészletet határozza meg → RÉSZLEGES (DailySession.closingBalance van, de a LOGIKA nincs)
- ❌ **Forgalom beolvasás és elküldés**: `ForgalomBeolvasas + SendingRutin` → a szerverre küldés az új rendszerben a DB-ben van (nincs FTP)

### JAVÍTANDÓ:
- Dekád riport generálás logika
- Havi zárás összesítés
- Nyitókészlet automatikus meghatározás (záró = következő napi nyitó)

---

## 6. ÉRTÉKTÁRI PÉNZTÁRAK (ERTEKTAR\penztarak → InventoryService + TreasuryDashboard)

### Legacy (98K):
- **AlapAdatBeolvasas**: pk file-ok olvasása FTP-ről (bináris, 737 byte/iroda)
- **PkDekodolo**: Bináris dekódolás → 27 valuta × (készlet, készletFt, vétel, vételFt, eladás, eladásFt)
- **AdatSummazas**: Összesítés irodánként és valutanemenként
- **KeszForgtombFeltoltes**: Készlet-forgalom mátrix feltöltés
- **IrodaAdatBeolvasas**: Egy iroda összes adata

### Új rendszer (InventoryService — most készül):
- ✅ InventoryMovement entity (bank↔pénztár)
- ✅ InventorySummary entity (összesítő)
- ✅ getStockMatrix() (összes iroda × valuta)
- ✅ REST API közvetlen DB query (nincs pk file)
- ⚠️ A legacy pk file formátum DOKUMENTÁLVA van a TREASURY-ANALYSIS.md-ben

---

## 7. SZERVER ADATGYŰJTŐ (SZERVER\adatgyujto → TreasuryDashboardService)

### Legacy (3203 sor!):
- **IrodaBetolto**: Irodák betöltése
- **CimletGyujtes**: Címlet gyűjtés CIMLETGYUJTO táblába
- **ForgalomGyujtes**: Forgalom gyűjtés (vétel/eladás irodánként)
- **BankGyujtes**: Bank forgalom gyűjtés (SUMBANKFORGALOM tábla)
- **KeszletKorzetSummazas**: Készlet összesítés KÖRZETENKÉNT (regionális)
- **KeszletKftSummazas**: Készlet összesítés KFT-NKÉNT (cég szintű)
- **KeszletCegSummazas**: Készlet összesítés TELJES CÉGRE
- **ForgKorzetSummazas/ForgKftSummazas/ForgCegSummazas**: Forgalom összesítés 3 szinten
- **MNBArfolyamLetoltes**: ARFOLYAM táblából olvassa az MNB árfolyamot
- **StornoRegisztracio**: Stornó tranzakciók regisztrálása
- **WuniForgalomGyujtes**: Western Union forgalom
- **MetroForgalomGyujtes**: Metro forgalom
- **TescoForgalomGyujtes**: Tesco forgalom

### Összesítési szintek (Legacy 3 szint):
```
Iroda → Körzet → Kft → Teljes cég
```
Ahol: Körzet = értéktári körzet (pl. Debrecen régió), Kft = jogi személy (Best Change, Expressz Zálog, stb.)

### Új rendszer (TreasuryDashboardService — most készül):
- ✅ getCompanyWideSummary() — céges összesítés
- ✅ getBranchComparison() — irodák összehasonlítása
- ⚠️ **HIÁNYZIK: Körzet szint** — a legacy 3 szinten összesít (iroda→körzet→kft→cég), az újban NINCS körzet fogalom
- ⚠️ **HIÁNYZIK: KFT szétválasztás** — több cég (Best Change, Expressz Zálog, Sun Exclusive) → az új rendszerben OwnCompany entity van, de az összesítés nem KFT-nkénti

### JAVÍTANDÓ:
- BranchGroup entity-t használni körzet/régió szintű összesítéshez
- OwnCompany-nkénti szétválasztott összesítés

---

## 8. FOGLALÓ (FOGLALO.DLL → ???)

### Legacy (83K, 166 proc/func!):
- **TELJES MÉRTÉKBEN HIÁNYZIK AZ ÚJ RENDSZERBŐL!**
- A foglaló rendszer: ügyfél lefoglal egy valutaösszeget adott árfolyamon, és később veszi át
- Foglaló bizonylat nyomtatás
- Foglaló lejárat kezelés
- Foglaló visszavonás
- Foglaló készlet elkülönítés (a készletből "fenntartva")

### JAVÍTANDÓ: Teljes foglaló modul implementáció szükséges

---

## 9. TOVÁBBI HIÁNYZÓ MODULOK

| Legacy modul | Méret | Funkció | Új rendszer |
|--------------|-------|---------|-------------|
| METRO.DLL | 74K | Metro áruház pénzváltó | ❌ HIÁNYZIK |
| TESCO.DLL | ? | Tesco áruház pénzváltó | ❌ HIÁNYZIK |
| OTP.DLL | ? | OTP bank POS terminál | ❌ HIÁNYZIK |
| OTPLOG.DLL | ? | OTP log | ❌ HIÁNYZIK |
| NAVZARO.DLL | ? | NAV zárás | ❌ HIÁNYZIK (NavIntegration mock) |
| WUNION.DLL | 91K | Western Union | ❌ HIÁNYZIK (Transfer entity részleges) |
| FOGLALO.DLL | 83K | Foglaló | ❌ HIÁNYZIK |
| SCANNING.DLL | 7K | Dokumentum szkennelés | ❌ HIÁNYZIK |
| EURO AKCIÓ | ? | EUR speciális kampány | ❌ HIÁNYZIK |
| CONFIDEN | ? | Bizalmas adatok kezelés | ❌ HIÁNYZIK |
| XTRANZ | ? | Speciális tranzakciók | ❌ HIÁNYZIK |
| DEKRUTIN | ? | Dekád rutin | ❌ HIÁNYZIK |

---

## 10. ÖSSZEFOGLALÓ — IMPLEMENTÁCIÓS PRIORITÁS

### 🔴 KRITIKUS (üzleti működéshez szükséges):
1. **Foglaló modul** — 83K legacy kód, teljes implementáció kell
2. **Értéktári összesítés 3 szint** — körzet + kft + cég
3. **Heti forint göngyölés** az AML-ben
4. **Havi zárás** összesítés
5. **Nyitókészlet automatikus meghatározás**

### 🟡 FONTOS (teljes működéshez):
6. **Western Union integráció** (ha még szükséges)
7. **NAV integráció** (valódi COM port kommunikáció)
8. **Bizonylat nyomtatás** (fizikai nyomtató)
9. **Dekád zárás riport generálás**
10. **8M éves AML küszöb**

### 🟢 OPCIONÁLIS (speciális esetek):
11. Metro/Tesco áruházi modulok
12. OTP POS terminál
13. Dokumentum szkennelés
14. EUR akció kezelés
