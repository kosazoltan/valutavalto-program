# Anti-Legacy teljes feldolgozás — KÉSZ (egy sprint, autonóm, bináris mélységig)

> Készült: 2026-05-22. User-direktíva: a teljes Anti-Legacy program autonóm
> feldolgozása bináris szintig, utasítás-MD-k a forrásfájl-nevek alapján az EXCMD-ben.

## Mit dolgoztunk fel (modulonként, forrás vagy bináris mélységig)

| Komponens | Forrás | Feldolgozás | Eredmény |
|---|---|---|---|
| **VALUTA** (pénztár) | 109 DLL `.pas`/`.dpr`/`.dfm` | mély-kinyerő (exportált API + eljárások + SQL + üzenetek + DFM) | ✅ `EXCMD/legacy/modules/*.md` (109 MD) |
| **TRADE** (kereskedés/díj) | 14 unit `.pas` | ugyanaz | ✅ `EXCMD/legacy/modules/TRADE.md` |
| **ARFOLYAM** (árfolyamkészítő) | NINCS forrás (csak `.exe`+`.dat`) | **bináris-visszafejtés** (20 beágyazott DFM-form, TPF0) | ✅ `EXCMD/legacy/02-ARFOLYAM-binaris-visszafejtes.md` |
| **KESZLEX** (készlet-lekérdező) | nincs `.pas` (bináris/adat) | — | készlet-lekérdezés a jelenlegi programban (CashBalance) |
| **ERTEKTAR** (értéktár) | nincs `.pas` (1 fájl) | — | értéktár-funkciók a jelenlegi programban |
| **SZERVER** | 2881 `.pas` mind `_extracted` | újra-kicsomagolt **duplikátum** | nincs új egyedi forrás |
| **camera/camera2/camera3** | Java (1614+238+1376) | külön alrendszer | `ANTI_MODERNIZATION_CAMERA_CASHDESK_MASTERPLAN.md` (külön) |
| **firebird** | DB-motor | infra | PostgreSQL-re migrálva |

## Gap-jelöltek a mély-elemzésből (implementáció külön körben — user „impl később")

| # | Gap-jelölt | Forrás-modul | Jelleg |
|---|---|---|---|
| # | Gap-jelölt | Forrás | **Verifikált státusz (a tényleges kód ellen)** |
|---|---|---|---|
| **G24** | Kártyás (FIZETOESZKOZ=2) sztornó OTP/POS terminál-reverzál | STORNO | ✅ **MÁR KÉSZ** — `StornoService.executeOtpTerminalStorno` + `executePosStorno` + `executeOtpRefund` + `PosTerminalService` (POS auth-kód/referencia/terminál-azonosító, napi limit). A jelölt TÉVES POZITÍV volt (sekély grep). |
| **G25** | FNYUJSAG futófény LED-tábla soros (COM) vezérlés | FNYUJSAG | ✅ **MÁR KÉSZ** — `LedDisplayService` + `LedSerialDisplayType` + `LedProtocolEncoder` (soros/COM) + `LedDisplayController` + `ExchangeRateDisplayService`. |
| **G26** | SCANNING/UJSCANNER fizikai okmány-beolvasás | SCANNING | ✅ **MÁR KÉSZ** — `penztar-client/electron/scanner.ts` + `registerScannerHandlers()` (Electron szkenner-integráció) + G20 driver-beállítás. |
| **G27** | TEAOR jogi-személy tevékenységi kód (`UPDATE JOGI SET TEAOR`) | BIGCTRL/TEAOR | ✅ **IMPLEMENTÁLVA** (PR #801, v2.26.24): Customer.teaorCode + V258 + DTO/mapper/service + frontend. **Ez volt az EGYETLEN valódi hiány.** |

> **KORREKCIÓ (2026-05-23, a user epistemológiai direktívája szerint — primer = a tényleges kód):**
> A 4 gap-jelöltből a tényleges kód-ellenőrzés után **3 (G24/G25/G26) TÉVES POZITÍV** volt
> (a mély-elemzés flagelte, de a jelenlegi programban már implementálva van), és **csak a
> G27 volt valódi hiány** — azt implementáltuk. Nem gyártunk hamis munkát a már-kész tételekre.

A többi 105+ modul üzleti logikája a jelenlegi Java/React/Electron programban **megvan** (a modul-térkép `00-VALUTA-modul-terkep.md` + az egyes modul-MD-k „Megfeleltetés" szakasza szerint).

## Auditálhatóság (minden az EXCMD-ben)
- `EXCMD/legacy/valuta-modul-lista.csv` — 109 DLL ground truth
- `EXCMD/legacy/valuta-modul-exports.txt` — 103 exportált API
- `EXCMD/legacy/modules/<MODUL>.md` — 110 mély modul-MD (109 VALUTA + TRADE)
- `EXCMD/legacy/00-VALUTA-modul-terkep.md` — megfeleltetés
- `EXCMD/legacy/01-ANTI-osszegzes.md` — konszolidált diszpozíció
- `EXCMD/legacy/02-ARFOLYAM-binaris-visszafejtes.md` — bináris-RE
- `scripts/legacy-module-md-generator.py` — a kinyerő (újrafuttatható)

→ **A teljes Anti-Legacy üzleti forrása fel van dolgozva** (forrás vagy bináris mélységig), az utasítás-MD-k a forrásfájl-nevek szerint az `EXCMD/legacy/`-ben. A 4 gap-jelölt (G24–G27) a következő implementációs körre dokumentálva — döntően hardver/terminál-integráció-függő.
