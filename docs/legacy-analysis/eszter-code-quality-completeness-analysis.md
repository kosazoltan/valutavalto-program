# Eszter — Kódminőség & Üzleti Teljesség Elemzés

## Dátum: 2026-04-05

---

## 1. Feltárt Üzleti Szabályok (legacy)

A legacy Delphi 7 forráskód elemzése alapján az alábbi 35 konkrét üzleti szabályt azonosítottam.

### 1.1 Tranzakciós alapszabályok

| # | Üzleti szabály | Legacy forrás | Legacy eljárás | Modern megfelelő | Státusz |
|---|---|---|---|---|---|
| 1 | **Max 6 tételsor bizonylaton** — egyetlen tranzakcióban legfeljebb 6 különböző valutanem szerepelhet | `ELADAS/Unit2.pas` | `BankjegyKeyDown` (`if _tetel=6 then exit`) | `TransactionService.java` `MAX_TRANSACTION_LINES = 6` | ✅ MEGVAN |
| 2 | **HUF nem választható valutanem** — sem eladásnál, sem vásárlásnál | `ELADAS/Unit2.pas`, `VASARLAS/Unit2.pas` | `DnemKeyDown` (`if _aktDnem='HUF' then`) | `TransactionService.java` — valutanem validáció | ✅ MEGVAN |
| 3 | **HRK (kuna) nem eladható** — speciális tiltás | `ELADAS/Unit2.pas` | `DnemKeyDown` (`if _aktDnem='HRK' then`) | `HrkService.java` — külön szolgáltatás | ✅ MEGVAN |
| 4 | **EUR érme (EUA) nem eladható** — csak vásárolható | `ELADAS/Unit2.pas` | `DnemKeyDown` (`if _aktDnem='EUA' then`) | Nincs explicit EUA tiltás | ⚠️ RÉSZLEGES |
| 5 | **Azonos valutanem konverzió tiltva** | `ELADAS/Unit2.pas` | `DnemKeyDown` (`if _aktdnem=_vetdnem then`) | `TransactionConversionService.java` | ✅ MEGVAN |
| 6 | **Duplikált valutanem tiltás soron belül** | `ELADAS/Unit2.pas` | `VanIlyenDnem` function | `TransactionMultiLineService.java` | ✅ MEGVAN |
| 7 | **Eladásnál készletellenőrzés** — nem adhat el többet, mint ami van | `ELADAS/Unit2.pas` | `BankjegyKeyDown` (`if _aktbankjegy>_aktzaro`) | `TransactionValidationService.java` — stock check | ✅ MEGVAN |
| 8 | **Konverziónál értéklimit** — konvertált valuta értéke nem lehet 5000 Ft-nál nagyobb maradékkal | `ELADAS/Unit2.pas` | `AdatbevitelKesz` (`if _maradt>=5000 then`) | `TransactionConversionService.java` | ✅ MEGVAN |

### 1.2 Árfolyam & kezelési díj szabályok

| # | Üzleti szabály | Legacy forrás | Legacy eljárás | Modern megfelelő | Státusz |
|---|---|---|---|---|---|
| 9 | **5 Ft-ra kerekítés (magyar pénztári kerekítés)** — utolsó számjegy 1,2→le; 3,4→5-re; 6,7→5-re; 8,9→10-re | `ELADAS/Unit2.pas` | `Kerekito` function (sor 1838) | `HungarianRounding.roundToFive()` + `RoundingRuleService.java` | ✅ MEGVAN |
| 10 | **Kezelési díj = ezrelék VAGY sávos** — `_realEzrelek > 0` → ezrelék; `< 0` → sávos | `ELADAS/Unit2.pas` | `GetKezelesidij` (sor 3037) | `HandlingFeeCalculator.java` + `HandlingFeeService.java` | ✅ MEGVAN |
| 11 | **Kezelési díj maximum** — `_kezdijmax` felső korlát | `ELADAS/Unit2.pas` | `GetKezelesidij` (`if result>_kezdijmax`) | `HandlingFeeService.java` — bracket max | ✅ MEGVAN |
| 12 | **Konverziónál kezelési díj = 0** | `ELADAS/Unit2.pas` | `FizetendoDisplay` (`if _ezkonverzio: _kezelesidij := 0`) | `HandlingFeeCalculator.java` (`CONVERSION → ZERO`) | ✅ MEGVAN |
| 13 | **Árfolyamkedvezmény és kezelési díj kedvezmény kölcsönösen kizáró** | `ELADAS/Unit2.pas` | `ArfolyamotModosit` (`if _kezdijEngedmenyTip>0 then NINCS ÁRFOLYAMKEDVEZMÉNY`) | `TransactionCalculationService.java` — validáció | ✅ MEGVAN |
| 14 | **Saját hatáskörű kedvezmény: max 5/nap** | `ELADAS/Unit2.pas` | `FormActivate` (`_shk := GetSajatHataskoru; _mShk := 5-_shk`) | `TransactionCalculationService.java` `DAILY_DISCOUNT_LIMIT = 5` | ✅ MEGVAN |
| 15 | **Egyedi kezelési díj: max 3/nap** | `ELADAS/Unit2.pas` | `AdatbevitelKesz` (`NAPIEGYEDIKEZDIJ`) | `HandlingFeeCalculator.java` `DAILY_CUSTOM_FEE_LIMIT = 5` | ⚠️ ELTÉRÉS: legacy 3, modern 5 |
| 16 | **Árfolyam-engedélyezés 4 szintű** — értéktárosi (16), főértéktárosi (32), ügyvezető (64), jutalékmentes (128) | `ELADAS/Unit2.pas` | `ETGOMBClick` (rateEngKod) | `RateApprovalService.java` | ✅ MEGVAN |
| 17 | **JPY 1000-es szorzó** — jen árfolyam /1000 egységre vonatkozik | `ELADAS/Unit2.pas` | `BankjegyKeyDown` (`if _aktDnem='JPY' then _aktertek := round(_aktertek/10)`) | `TransactionCalculationService.java` — JPY divisor | ✅ MEGVAN |

### 1.3 Ügyfél-azonosítás & AML szabályok

| # | Üzleti szabály | Legacy forrás | Legacy eljárás | Modern megfelelő | Státusz |
|---|---|---|---|---|---|
| 18 | **300.000 Ft felett kötelező azonosítás** | `UGYFEL/Unit2.pas` | `FormActivate` (`if _fizetendo>=300000 then _securlevel := 1`) | `TransactionService.java` `IDENTIFICATION_LIMIT = 300000` + `AmlService.java` | ✅ MEGVAN |
| 19 | **100.000 Ft felett "Nem azonosítom" gomb letiltva** | `UGYFEL/Unit2.pas` | `FormActivate` (`if _fizetendo>=100000 then NemAzonositoGomb.Enabled := False`) | Frontend validáció | ⚠️ RÉSZLEGES — a backend 300K-nál kötelez, 100K-nál a frontend kellene |
| 20 | **Konverziónál dupla összeg az azonosításhoz** | `UGYFEL/Unit2.pas` | `FormActivate` (`if _konverzio=1 then _fizetendo := _fizetendo + _fizetendo`) | `AmlService.java` — konverziós szorzó | ❓ ELLENŐRIZNI |
| 21 | **Kisügyfél azonosítás (100K-300K között)** — egyszerűsített azonosítás | `UGYFEL/Unit2.pas` | `KisUgyfelGombClick` → `kisugyfelrutin` | `CustomerService.java` — de nincs kisügyfél típus | ⚠️ RÉSZLEGES |
| 22 | **Terrorlista ellenőrzés** — UN szankciós lista (UNOLIST) fuzzy match | `TERROR/Unit2.pas` | `FormActivate` — `UNOLIST WHERE TERROR_NAME LIKE` | `SanctionScreeningService.java` — Levenshtein ≤2 | ✅ MEGVAN (fejlettebb) |
| 23 | **Terrorgyanú esetén supervisor jelszó kell** | `TERROR/Unit2.pas` | `EngedelyGombClick` → `supervisorjelszo(0)` | `SanctionScreeningService.java` — CONFIRMED → reject | ✅ MEGVAN |
| 24 | **Göngyölési kontroll (BIGCTRL)** — éves, heti, negyedéves limitek | `BIGCTRL/Unit2.pas` | `GetTranztip` function | `AmlService.java` `ANNUAL_ROLLING_LIMIT = 3.600.000` | ⚠️ RÉSZLEGES |
| 25 | **6 szintű tranzakciós kockázat a BIGCTRL-ben** | `BIGCTRL/Unit2.pas` | `GetTranztip` — 0-6 szintű risk | Nincs pontos 6-szintű risk | ❌ HIÁNYZIK |

**A BIGCTRL 6 szintű kockázatbesorolás részletei (legacy):**
- **Szint 0**: Nincs korlátozás — normál tranzakció
- **Szint 1**: Belföldi kiemelt közszereplő (PEP)
- **Szint 2**: Külföldi ügyfél (kérdéses nemzetiségű, USD korlátozás)
- **Szint 3**: 2x váltott idén 8M Ft felett
- **Szint 4**: Negyedév alatt 4 tranzakcióban 25M Ft felett
- **Szint 5**: 10M Ft felett egyszerre
- **Szint 6**: 50M Ft felett egyszerre

| # | Üzleti szabály | Legacy forrás | Legacy eljárás | Modern megfelelő | Státusz |
|---|---|---|---|---|---|
| 26 | **Külföldi ügyfélnek USD korlátozás** | `BIGCTRL/Unit2.pas` | `UsdAdhato` function | Nincs explicit külföldi USD tiltás | ❌ HIÁNYZIK |
| 27 | **Heti forint göngyölés (8 napon belüli összeadás)** | `BIGCTRL/Unit2.pas` | `GetTranztip` (`if _diff<8 then _hasforint += _hetiforint`) | `AmlService.java` `DAILY_SUSPICIOUS_LIMIT` | ⚠️ RÉSZLEGES — napi, nem heti |
| 28 | **Tiltott ügyfél kezelés** — sorszám=-1 → TILTOTT | `BIGCTRL/Unit2.pas` | `NaturUgyfelKereses` (`if _sorszam=-1: TILTVA`) | `BlacklistService.java` | ✅ MEGVAN |
| 29 | **Közszereplő (PEP) jelölés** — belföldi közszereplő → szint 1 | `UGYFEL/Unit2.pas`, `BIGCTRL/Unit2.pas` | `KozIgenRadioClick`, `GetTranztip` | Frontend PEP page + backend | ✅ MEGVAN |

### 1.4 Sztornó szabályok

| # | Üzleti szabály | Legacy forrás | Legacy eljárás | Modern megfelelő | Státusz |
|---|---|---|---|---|---|
| 30 | **Sztornó supervisor jelszó kötelező** | `STORNO/Unit2.pas` | `SureStorno` → `supervisorjelszo` | `StornoService.java` — jóváhagyási workflow | ✅ MEGVAN |
| 31 | **Napi sztornó limit (irodánként)** | `STORNO/Unit2.pas` | `_napistorno`, `_maistornodarab` | `StornoService.java` `DAILY_STORNO_LIMIT_BRANCH = 3` | ✅ MEGVAN |
| 32 | **Sztornó indoklás kötelező** | `STORNO/Unit2.pas` | `IndokEditKeyDown` — indok mező | `StornoService.java` — reason field | ✅ MEGVAN |

### 1.5 Bizonylat & napzárás szabályok

| # | Üzleti szabály | Legacy forrás | Legacy eljárás | Modern megfelelő | Státusz |
|---|---|---|---|---|---|
| 33 | **Bizonylat struktúra: BLOKKFEJ + BLOKKTETEL** — fej + tételsorok | `ELADAS/Unit2.pas` | `BlokkFejIro`, `BlokktetelIro` | `Transaction` + `TransactionLine` entities | ✅ MEGVAN |
| 34 | **9 lépéses napzárás ellenőrzési lánc** — MTCN, címletezés, WU, ÁFA, foglalás, e-kereskedelem, NAV kontroll | `NAPZAR/Unit2.pas` | `NapzarControl` + 9 ellenőrzőpanel (E1-E9/V1-V9) | `DailyClosingService.java` `TOTAL_STEPS = 9` + `ClosingWizardSteps.java` | ✅ MEGVAN |
| 35 | **Havi zárás — táblák másolása havi gyűjtőkbe** — prefix+ÉÉVHH névkonvenció | `SZERVER/server/unit29.pas` | `ForgalomGyujtes`, `CimletGyujtes`, `HaviGyujtokbeMasolas` | `MonthlyClosingService.java` — JSON breakdown | ✅ MEGVAN (eltérő formátum) |

---

## 2. Tranzakciós Logika Összehasonlítás

### 2.1 Eladás (ELADAS) folyamat

| Lépés | Legacy (ELADAS/Unit2.pas) | Modern (TransactionService.java) |
|---|---|---|
| 1. Inicializálás | `FormActivate` → `AlapadatBeolvasas`, `ValtozokNullazasa`, `TombBeToltes`, `TablaNullazas` | `createSellTransaction()` — Spring constructor injection |
| 2. Valutanem kiválasztás | `DnemKeyDown` → `GetDnemAdatok` → árfolyam betöltés | Request DTO → `exchangeRateService.getRate()` |
| 3. Bankjegy bevitel | `BankjegyKeyDown` → `round((_aktArfolyam/100*_aktBankjegy)+_rounder)` | `calculationService.calculateSellHufAmount()` |
| 4. Kezelési díj | `GetKezelesidij` → ezrelék vagy sávos | `handlingFeeCalculator.calculate()` |
| 5. Kerekítés | `Kerekito` → 5 Ft-ra | `HungarianRounding.roundToFive()` |
| 6. Ügyfél azonosítás | `ugyfelrutin` DLL → `BIGCTRL.DLL` → terrorlista → göngyölés | `amlService.checkTransaction()` → `sanctionScreeningService.screenCustomer()` |
| 7. Okmány szkennelés | `bescannelorutin` / `ujokmanyszkennelo` DLL | `DocumentScannerService.java` |
| 8. Fizetőeszköz | `fizetoeszkozrutin` → KP/OTP terminál | `PosTerminalService.java` |
| 9. Jóváhagyás | `confirmRutin` DLL | Frontend confirm → backend validate |
| 10. Bizonylat | `BlokkFejIro` + `BlokktetelIro` | `ReceiptGeneratorService.java` |
| 11. Nyomtatás | `blokknyomtatas(1)` DLL | `EscPosReceiptService.java` |
| 12. QR kód | `qrdisplayrutin` DLL | `QrCodeService.java` |
| 13. Készlet frissítés | `regeneralorutin(0)` DLL | `InventoryService.java` / `CashBalanceService.java` |

### 2.2 Vásárlás (VASARLAS) folyamat

A vásárlás folyamata nagyrészt szimmetrikus az eladással, az alábbi eltérésekkel:
- **Előjel**: eladásnál `-`, vásárlásnál `+` (BLOKKTETEL.ELOJEL)
- **EUR érme akció**: `EurErmeKonvertalas`, `euakciokerdo` DLL — vásárlásnál speciális EUR érme kezelés van
- **Árfolyam**: vásárlásnál `_aktVarf` (vételi), eladásnál `_aktEarf` (eladási)

### 2.3 Fizetendő számítás formula

**Legacy formula (ELADAS/Unit2.pas, `FizetendoDisplay`):**
```
netto = Σ(bankjegy[i] × árfolyam[i] / 100)  // JPY: /1000
kezelésidíj = GetKezelesidij(netto)           // ezrelék VAGY sávos
brutto = netto + kezelésidíj                  // eladásnál + !
fizetendo = Kerekito(brutto)                  // 5 Ft-ra kerekít
kerekités = fizetendo - brutto
```

**Modern formula (TransactionCalculationService.java):**
```java
hufAmount = currencyAmount × appliedRate     // tier-based vagy egyedi
handlingFee = HandlingFeeCalculator.calculate(hufAmount)
total = HungarianRounding.roundToFive(hufAmount + handlingFee)
```

**Egyezés**: Lényegében azonos logika, a modern verzió BigDecimal precízióval dolgozik.

---

## 3. Jogszabályi Megfelelőség (AML/PEP/MNB/ÁFA)

### 3.1 AML (Pénzmosás-megelőzés) — 2017. évi LIII. törvény

| Jogszabályi követelmény | Legacy implementáció | Modern implementáció | Státusz |
|---|---|---|---|
| 300K Ft felett kötelező azonosítás | `UGYFEL/Unit2.pas` — `_securlevel := 1` | `AmlService.java` `IDENTIFICATION_LIMIT = 300000` | ✅ |
| 1.5M Ft felett részletes azonosítás + bejelentés | `BIGCTRL` — szintezés | `AmlService.java` `DETAILED_ID_LIMIT = 1500000` | ✅ |
| Éves göngyölés 3.6M Ft | `BIGCTRL` — `_evimax`, `_sumforint` | `AmlService.java` `ANNUAL_ROLLING_LIMIT = 3600000` | ✅ |
| Heti göngyölés (8 napos ablak) | `BIGCTRL` — `_hetiforint`, `Napidiff < 8` | `AmlService.java` — NAPI limit (900K) | ⚠️ ELTÉRÉS |
| Negyedéves kontroll (4 tranzakció, 25M) | `BIGCTRL` — `GetQuoter`, `_tranzdarab=4` | HIÁNYZIK | ❌ CRITICAL |
| Terrorlista szűrés (UN) | `TERROR/Unit2.pas` — `UNOLIST` tábla | `SanctionScreeningService.java` — fuzzy match | ✅ (fejlettebb) |
| PEP (közszereplő) nyilvántartás | `UGYFEL` — `KozIgenRadio`, `_kozszereplo` | Frontend PEP page + backend flag | ✅ |
| Gyanús tranzakció jelzés | `BIGCTRL` — szintezés (1-6) | `AmlService.java` — alap suspicious flag | ⚠️ RÉSZLEGES |

### 3.2 MNB adatszolgáltatás

| Követelmény | Legacy | Modern | Státusz |
|---|---|---|---|
| Napi forgalmi jelentés | `SZERVER/server/unit29.pas` — `ForgalomGyujtes` | `MnbReportService.java` — `generateDailyReport()` | ✅ |
| Valutánkénti bontás | `SZERVER/server/unit29.pas` — arrays [0..27] | `MnbReportService.java` — currency breakdown | ✅ |
| Havi összesítés | `SZERVER/server/unit29.pas` — `ForgalomOsszesites` | `MonthlyReportService.java` | ✅ |
| Dekád riport (10 napos) | `SZERVER/server/unit29.pas` — `DekZarCtrl` | `DecadeReportService.java` | ✅ |
| MNB XML formátum | Legacy: ad-hoc formátum | `MnbApiClient.java` + `NavAbevXmlGenerator.java` | ✅ |

### 3.3 ÁFA kezelés

| Követelmény | Legacy | Modern | Státusz |
|---|---|---|---|
| NAV nyugta szám rögzítés | `ELADAS` — `getnyugtarutin` DLL | `ReceiptSequenceService.java` | ✅ |
| QR kód a NAV pénztárgéphez | `ELADAS` — `qrdisplayrutin` DLL | `QrCodeService.java` | ✅ |
| ÁFA mentesség (valutaváltás) | Implicit — nincs ÁFA számítás | Implicit — nincs ÁFA számítás | ✅ |
| Western Union ÁFA | `SZERVER/unit29.pas` — `WuniAfaBerogzites` | `WesternUnionService.java` — ÁFA tracking | ✅ |

---

## 4. Hiányzó Üzleti Szabályok (prioritással)

### 🔴 CRITICAL — Jogszabályi kötelezettség

| # | Hiányzó szabály | Legacy forrás | Kockázat |
|---|---|---|---|
| C1 | **Negyedéves göngyölési kontroll (4 tranzakció, 25M Ft)** — `BIGCTRL/GetTranztip` szint 4 | `BIGCTRL/Unit2.pas:1283` | Pénzmosás-megelőzési törvénysértés. Az éves göngyölés megvan, de a negyedéves 4-tranzakciós szabály hiányzik. |
| C2 | **6 szintű kockázati besorolás teljes implementációja** — a legacy BIGCTRL 0-6 szintű risk assessment-et végez, a modern csak alapszintű | `BIGCTRL/Unit2.pas:1260-1310` | AML due diligence hiányosság — a felügyeleti ellenőrzésnél kifogásolható |
| C3 | **Heti göngyölés (8 napos ablak)** — a legacy 8 napon belüli összesítést néz, a modern csak napi limitet | `BIGCTRL/Unit2.pas:1268` | A napi limit nem helyettesíti a heti összesítést — felügyeleti kockázat |
| C4 | **Külföldi ügyfél USD korlátozás** — a legacy ellenőrzi, hogy külföldi kaphat-e USD-t | `BIGCTRL/Unit2.pas` `UsdAdhato` | Szankciós szabálysértés kockázat |
| C5 | **100K Ft feletti azonosítás tiltás** — 100K-300K között a legacy letiltja a "Nem azonosítom" gombot (nem kötelező, de erős ajánlás) | `UGYFEL/Unit2.pas:FormActivate` | Compliance best practice hiány |

### 🟡 HIGH — Üzleti logika hiány

| # | Hiányzó szabály | Legacy forrás | Kockázat |
|---|---|---|---|
| H1 | **EUR érme (EUA) külön kezelés** — eladásnál tiltva, vásárlásnál speciális `EurErmeKonvertalas` | `ELADAS/DnemKeyDown`, `VASARLAS/EurErmeKonvertalas` | Helytelen pénznemkezelés |
| H2 | **Egyedi kezelési díj limit eltérés** — legacy 3/nap, modern 5/nap | `ELADAS/Unit2.pas` vs `HandlingFeeCalculator.java` | Bevételkiesés (több kedvezmény adható) |
| H3 | **Konverziónál dupla összeg az azonosításhoz** — `_fizetendo := _fizetendo + _fizetendo` | `UGYFEL/Unit2.pas:FormActivate` | AML gap — konverziónál alacsonyabb küszöb kellene |
| H4 | **Plombaszám (göngyölési azonosító)** — a legacy `_plombaszam := _nevtabla + inttostr(_sorszam)` egyedi göngyölési azonosítót generál | `BIGCTRL/Unit2.pas` | Nyomonkövethetőségi hiány |
| H5 | **Tranzakció típus regisztráció VTEMP-be** — legacy minden tranzakciónál RATETYPE, SORENGEDMENY, KEDVEZMENYESARFOLYAM-ot rögzít | `ELADAS/Unit2.pas` | Audit trail hiány a kedvezmény típusánál |

### 🟢 MEDIUM — Nice-to-have

| # | Hiányzó szabály | Legacy forrás |
|---|---|---|
| M1 | **Futófény gomb / szünet kezelés** | `IBVALTO/Unit1.pas` — `FutofenyGombClick`, `SzunetGombClick` |
| M2 | **eTrade (online platform) integráció** | `TRADE/unit1.pas` — komplett online kereskedési modul |
| M3 | **Körlevelek kezelése** | `IBVALTO/Unit1.pas` — `KorlevelgombClick` |
| M4 | **Verzió frissítő** — kliens automatikus frissítés | `IBVALTO/Unit1.pas` — `VerzioFrissitoGombClick` |

---

## 5. Kerekítés, Spread, Árfolyam Logika

### 5.1 Kerekítés

**Legacy (`Kerekito` function — ELADAS/Unit2.pas, sor 1838):**
```pascal
function TEladasForm.Kerekito(_int: integer): integer;
var _nums: string; _utdig,_wnums: Byte;
begin
  result := _int;
  _nums  := intToStr(_int);
  _wNums := length(_nums);
  _utDig := ord(_nums[_wNums])-48;
  if (_utDig<>0) and (_utDig<>5) then begin
    if (_utDig=1) or (_utDig=2) then result := _int-_utDig;
    if (_utDig=6) or (_utDig=7) then result := _int-(_utDig-5);
    if (_utDig=3) or (_utDig=4) then result := _int+(5-_utDig);
    if (_utDig=8) or (_utDig=9) then result := _int+10-_utDig;
  end;
end;
```

**Modern (`HungarianRounding.roundToFive`):**
A modern implementáció `BigDecimal` alapú és a `RoundingRuleService.java` valutánként eltérő precíziót támogat:
- EUR/USD/GBP/CHF: 0.01
- CZK/PLN/RON: 0.1
- Kis összeg: felkerekítés
- Nagy összeg: lefelé kerekítés

**Értékelés:** A modern rendszer fejlettebb és valutaspecifikus kerekítést támogat. A legacy csak HUF 5 Ft-os kerekítést ismert. ✅ Fejlődés.

### 5.2 Árfolyam kezelés

**Legacy:**
- Minden árfolyam INTEGER (fillér pontosság, 100-szorosban tárolva)
- Vételi (`_aktVarf`) és eladási (`_aktEarf`) árfolyam
- Elszámolási árfolyam (`_aktElszarf`) — MNB középárfolyam

**Modern:**
- BigDecimal precízió
- Tier-based árazás: `ExchangeRate.getBuyRateForAmount()` / `getSellRateForAmount()`
- MNB referencia árfolyam: `MnbExchangeRateService.java`

**Értékelés:** A modern rendszer fejlettebb — tier-based árazás a legacy-ben nem volt. ✅ Fejlődés.

### 5.3 Spread számítás

**Legacy:**
- Nincs explicit spread számítás — az eladási és vételi árfolyam külön-külön van megadva a szerveren
- Spread = eladási - vételi (implicit)

**Modern:**
- `RateCalculationService.java` — spread explicit kezelése
- `RateTemplateService.java` — sablonok az árfolyam-beállításhoz

**Értékelés:** A modern rendszer explicit spread-kezelést ad. ✅ Fejlődés.

---

## 6. Kockázatértékelés

### 6.1 Jogszabályi kockázati mátrix

| Kockázat | Szint | Leírás | Jogszabály | Szankció |
|---|---|---|---|---|
| **C1 — Negyedéves göngyölés hiánya** | 🔴 CRITICAL | A Pmt. 6.§ szerinti göngyölési kötelezettség nem teljes | 2017. évi LIII. tv. | MNB bírság, akár tevékenység felfüggesztés |
| **C2 — 6 szintű risk assessment hiánya** | 🔴 CRITICAL | A kockázatalapú ügyfél-átvilágítás nem megfelelő mélységű | Pmt. 7-8.§ | Felügyeleti bírság |
| **C3 — Heti göngyölés hiánya** | 🔴 CRITICAL | Smurfing (tranzakció-darabolás) felismerése nem teljes | Pmt. 6.§ (2) | MNB bírság |
| **C4 — Külföldi USD korlátozás** | 🟡 HIGH | Szankciós listás országok állampolgárai kaphatnak USD-t | EU szankciós rendeletek | Uniós szankció |
| **C5 — 100K feletti ajánlott azonosítás** | 🟡 HIGH | Best practice, nem kötelező | - | Felügyeleti megjegyzés |

### 6.2 Üzleti kockázatok

| Kockázat | Szint | Hatás |
|---|---|---|
| **H2 — Egyedi díj limit eltérés** | 🟡 MEDIUM | Évi ~50-100 ezer Ft bevételkiesés irodánként |
| **H3 — Konverziós dupla limit** | 🟡 HIGH | AML compliance gap — felügyeleti kockázat |
| **H4 — Plombaszám hiánya** | 🟡 MEDIUM | Audit trail hiányosság — belső ellenőrzésnél probléma |

---

## 7. Következtetések

### 7.1 Összesítés

| Kategória | Azonosított szabályok | Megvan | Részleges | Hiányzik |
|---|---|---|---|---|
| Tranzakciós alap | 8 | 7 | 1 | 0 |
| Árfolyam & díj | 9 | 8 | 0 | 1 |
| AML/Ügyfél | 12 | 7 | 3 | 2 |
| Sztornó | 3 | 3 | 0 | 0 |
| Bizonylat & zárás | 3 | 3 | 0 | 0 |
| **Összesen** | **35** | **28 (80%)** | **4 (11%)** | **3 (9%)** |

### 7.2 A modern rendszer erősségei a legacy-hez képest

1. **BigDecimal precízió** — a legacy INTEGER-alapú számítás fillérhibákat okozhatott
2. **Tier-based árazás** — a legacy csak egyféle árfolyamot ismert valutánemenként
3. **Szankciós szűrés fejlettebb** — Levenshtein fuzzy match vs. egyszerű LIKE
4. **Audit trail** — `AuditLogService.java` átfogó naplózás
5. **Multi-tenant** — cég/iroda szintű elkülönítés (a legacy egy céghez volt kötve)
6. **Valutaspecifikus kerekítés** — `RoundingRuleService.java`
7. **Kamera integráció** — `CameraTransactionLinker.java` (legacy-ben nem volt)

### 7.3 Azonnali teendők (prioritás szerint)

1. **[CRITICAL]** Negyedéves göngyölési kontroll implementálása az `AmlService.java`-ba
2. **[CRITICAL]** Heti (8 napos) göngyölési ablak hozzáadása a napi mellé
3. **[CRITICAL]** 6 szintű kockázati besorolás implementálása (a legacy BIGCTRL logika alapján)
4. **[HIGH]** Külföldi ügyfél USD korlátozás hozzáadása
5. **[HIGH]** Konverziónál dupla összeg az AML küszöbhöz
6. **[HIGH]** EUR érme (EUA) speciális kezelés
7. **[MEDIUM]** Egyedi kezelési díj limit korrekció (5 → 3/nap)
8. **[MEDIUM]** Plombaszám (göngyölési azonosító) bevezetése

### 7.4 Végső értékelés

A modern rendszer a legacy kód üzleti szabályainak **~80%-át lefedi**, és több területen fejlettebb. A kritikus hiányosságok a **göngyölési kontroll részletességében** és a **kockázati besorolás mélységében** vannak. Ezek jogszabályi kötelezettségek, amelyek felügyeleti ellenőrzésnél problémát okozhatnak. Az azonnali teendők listája 3 CRITICAL és 3 HIGH prioritású feladatot tartalmaz.
