# Anti / ARFOLYAM (árfolyamkészítő) — bináris-visszafejtésből nyert tudás

> Készült: 2026-05-22. Az ARFOLYAM modulnak **nincs forráskódja** az Anti-ban
> (csak `Arfolyam.exe` 1.17 MB bináris + `arfdata.dat` adat). A tudást a **binárisból
> visszafejtve** nyertük (Delphi beágyazott DFM form-ok + struktúra), NEM találgatva.

## Módszer
- `Arfolyam.exe` (Delphi 7) beágyazott form-jai a `TPF0` szignatúrából kinyerve (20 form).
- A DFM komponens-struktúra a form-régiókból (hosszelőtagos stringek) parse-olva.
- `arfdata.dat`: tiszta bináris (nincs beágyazott string/valutakód) → Delphi typed-file
  rekordok, a valuta-identitás **pozíció szerint** (a b1-spec D-oszlop sorrendje). A
  rekord-layout a hiányzó forrásban lenne; a nyers számértékeket NEM dekódoljuk
  (találgatás lenne, + napi adat, nem követelmény).

## Visszafejtett form-ok (Arfolyam.exe, 20 db) → megfeleltetés

| Legacy form (binárisból) | Funkció | Jelenlegi program / b1-spec |
|---|---|---|
| **TALAPLAP** | 0-s alaplap (A–I oszlopok: elszámoló/OTP/segéd/multi-vétel-eladás/kereszt) | ✅ MainRateSheetPage (b1 ÁR001) — háttér-image + rács |
| **TCSOPORTDISPLAY** | csoport lap (54 munkacsoport, J–S oszlopok, kedvezményhatárok) | ⚠️ G22 sub-scope — a számítási mag (rfmRules) kész, a 54-csempe rács-UI hátra |
| **TLIMITALLITOFORM** | kedvezményhatár-állító (alsó/középső/felső + saját hatáskör) | ⚠️ G22 sub-scope (R/S képlet rfmRules-ban kész) |
| **TINTERNETTMKFORM** | INTERNET (nagyker/internet) árfolyam-oszlop karbantartás | ⚠️ G22 sub-scope (INTERNET oszlop) |
| **THOVAMASOLJAK** | „hová másoljak" — kitöltési segítség (függvény-másolás cellák közt) | ⚠️ G22 sub-scope (FR-RFM-23 kitöltési segítség) |
| **TGETFUGGVENY** | „aktuális függvény" megjelenítés | ⚠️ G22 sub-scope (FR-RFM-22) |
| **TADATSZETKULDES** | árfolyam szétküldése a fiókokba/szerverre | ✅ MainRateSheetPage publish (diff-alapú, G7 irány-gate) |
| **TADATBETOLTES** | árfolyam-adat betöltés | ✅ szerver-szinkron (exchangeRateMasterApi) |
| **TARFDATAIRAS** | arfdata.dat írása | ⚙️ a jelenlegi rendszerben DB (exchange_rate_master) |
| **TIRODANEVLISTA** | csoporthoz tartozó irodák listája | ⚠️ G22 sub-scope (FR-RFM-21) |
| **TZOLDMENU** | „zöld rendszer" főmenü | ✅ a jelenlegi RFM-kliens menü |
| **TLoginDialog / TPasswordDialog** | bejelentkezés + jelszó | ✅ auth (JWT) |
| **TMUNKAFORM / TNYOMTATOFORM / THELPFORM / TNMShow / TINTERNETBONGESZO / TForm1** | munka/nyomtatás/súgó/böngésző segéd-formok | ⚙️ UI/segéd |

## Verifikált eredmény (ARFOLYAM)

A binárisból visszafejtett RFM-struktúra **pontosan egyezik** a Felmérés `b1-arfolyamkeszito` spec-kel, amit már feldolgoztunk:
- ✅ **TALAPLAP / TADATSZETKULDES** → MainRateSheetPage + publish (G7 árfolyam-irány gate).
- ✅ **számítási mag** (EUA ×1.2, Raiffeisen ±10%, R/S P+0,25, kereszt) → `rfmRules.ts` (G22).
- ⚠️ **TCSOPORTDISPLAY (54-csempe csoport-rács) + TLIMITALLITOFORM + TINTERNETTMKFORM + THOVAMASOLJAK + TGETFUGGVENY + TIRODANEVLISTA** → ez a **G22 ismert UI sub-scope** (futó-app/Electron verifikációt igénylő rács-UI; a mögöttes számítás kész + tesztelt).

→ A bináris-visszafejtés **nem tárt fel új, eddig ismeretlen üzleti logikát** az ARFOLYAM-ban; megerősítette a b1-spec + G7/G22 hatókörét, és pontosította, hogy a hátralévő rész a csoport-lap (ÁR002) teljes UI-ja.

## Megjegyzés a teljes bináris-visszafejtéshez
A módszer (TPF0 form-kinyerés + DFM-parse) működik bármely Delphi `.exe`/`.dll`-re.
A **VALUTA** modul 109 DLL-jének viszont MEGVAN a forrása (`.pas` + `.dpr` exports —
lásd `valuta-modul-exports.txt`), ezért azokat NEM kell visszafejteni: a forrás
pontosabb, mint a bináris. Bináris-RE csak a forrás nélküli ARFOLYAM-hoz kellett.
