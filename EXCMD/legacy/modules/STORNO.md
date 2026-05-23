# Legacy modul mély-elemzés: STORNO (sztornó)

> Forrás: `Anti/VALUTA/DLL/STORNO/MAKEDLL/` (Unit2.pas 34 972 karakter, primer forrás).
> Mélység: exportált API + tényleges üzleti logika + DB-műveletek + DFM + megfeleltetés.

## 1. Exportált API (a `.dpr` library `exports` clause-ából)
- **`stornorutin`** (stdcall) — a sztornó fő belépési pontja (a IBVALTO kliens hívja).
- Külső DLL-hívások (más modulok exportált rutinjai): `regeneralorutin` (REGEN — készlet-újragenerálás), `blokknyomtatas` (BLOKNYOM — bizonylat-nyomtatás), `supervisorjelszo` (SUPER — felügyelői jelszó).

## 2. Tényleges folyamat (Unit2.pas eljárásaiból)
Form: `TSTORNOFORM` — bizonylat-rács (`BizonylatRacs`) + indok-mező (`IndokEdit`) + Igen/Nem/Stornó/Mégsem gombok + kilépő-timer.
1. `BizLista` — sztornózható bizonylatok listázása a rácsba.
2. `BizonylatRacsDblClick` / `StornoGombClick` — a kiválasztott bizonylat sztornója.
3. `supervisorjelszo` — felügyelői jelszó-ellenőrzés a sztornóhoz.
4. **OTP kártya-terminál sztornó** (ha az eredeti kártyás fizetés volt): QRPARAMS + VTEMP (OTPFUNCTYPE) → a kártya-tranzakció visszafordítása a terminálon. Hiba esetén: **„SIKERTELEN OTP-STORNÓ! Stornó nem lehetséges"** → a sztornó MEGHIÚSUL.
5. `regeneralorutin` — a készlet/címlet visszavezetése.
6. `blokknyomtatas` — sztornó-bizonylat nyomtatása.

## 3. Érintett DB-táblák/mezők (a SQL-ekből)
- `BLOKKFEJ` (bizonylat-fej) `WHERE BIZONYLATSZAM=…` — az eredeti bizonylat.
- `BLOKKTETEL` (bizonylat-tétel) `WHERE (FIZETOESZKOZ=2) AND (STORNO=1)` — **FIZETOESZKOZ=2 = bankkártya**, **STORNO=1 = sztornózott** tételek.
- `UGYFEL`, `JOGISZEMELY` `WHERE UGYFELSZAM=…` — ügyfél/jogi személy.
- `QRPARAMS` (VALUTANEM, BANKJEGY, NUMBER) + `VTEMP` (BIZONYLATSZAM, FIZETENDO, OTPFUNCTYPE) — OTP-terminál kommunikáció.
- `PENZTAR`, `HARDWARE` — pénztár/hardver konfiguráció.

## 4. Megfeleltetés a jelenlegi programmal
| Legacy STORNO elem | Jelenlegi program |
|---|---|
| `stornorutin` alap-sztornó + indok + supervisor-jelszó | ✅ `StornoService` (G2) — sztornó aktuális árfolyammal, supervisor-jóváhagyás (G12 AFTER_COMMIT értesítés) |
| készlet-visszavezetés (`regeneralorutin`) | ✅ `TransactionReversalService` készlet-visszaírás |
| sztornó-bizonylat (`blokknyomtatas`) | ✅ `ReceiptGeneratorService.generateStornoReceipt` |
| `STORNO=1` flag a tételen | ✅ `TransactionStatus.REVERSED` |
| **OTP kártya-terminál sztornó (FIZETOESZKOZ=2)** | ⛔ **GAP-JELÖLT (G24?)** — a jelenlegi `StornoService` NEM fordítja vissza a kártya-tranzakciót a POS/OTP terminálon; csak a tranzakciót jelöli sztornózottnak. A legacy szerint kártyás fizetésnél a terminál-reversal KÖTELEZŐ, különben a sztornó meghiúsul. |

## 5. Gap-jelölt (későbbi implementáció — a user „impl később" döntése szerint)
**G24 (jelölt): kártyás (FIZETOESZKOZ=2) tranzakció sztornójánál POS/OTP terminál-reversal.**
- A jelenlegi `StornoService` nem hív POS-reverzálást kártyás eredetinél.
- Legacy viselkedés: terminál-reversal sikertelen → sztornó tiltva („SIKERTELEN OTP-STORNÓ").
- Jelleg: PSP/terminál-integráció-függő (hardver + bank-protokoll). Feature-flag + tényleges POS-reverzál endpoint kell. Futó-app + terminál verifikáció.
- **Megjegyzés:** ellenőrizni, hogy a jelenlegi POS-fizetés (TransactionService posResult) tartalmaz-e reverzál-ágat; ha nem, ez valódi compliance-gap a kártyás sztornónál.
