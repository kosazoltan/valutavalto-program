# 2026-05-23 — Anti-Legacy modul-szintű mély-verifikáció + G27 TEÁOR (v2.26.24)

## Direktíva
User: a 109 VALUTA modul-MD + TRADE + ARFOLYAM (20 DFM-form) + camera alapján
**minden hiányzó funkciót autonóm implementálni**. Epistemológiai megkötés
(megőrzött): a **ground truth a tényleges kód**, NEM a származtatott modul-térkép —
verifikálni kell file:line bizonyítékkal, mielőtt bármit ténynek állítok.

## Mit csináltam
1. **G27 (PR #801, admin-merged `ea3cafc9d`)** — jogi-személy TEÁOR tevékenységi kód:
   `Customer.teaorCode` + V258 + DTO/mapper/service + `CustomerCreatePage` céges input.
   Ez volt az EGYETLEN valódi szoftver-hiány a 4 korábbi legacy gap-jelöltből.
2. **6 párhuzamos verifikáló ügynök** — mind a 110 modul-MD (109 VALUTA + TRADE) +
   20 ARFOLYAM DFM-form a jelenlegi kód ellen, file:line bizonyítékkal.

## Verifikációs eredmény (a tényleges kód ellen)
- **Túlnyomó lefedettség.** A legacy pénztári/zárási/ügyfél/AML/címletezés/transfer/
  fee/WU/árfolyam üzleti logika érdemben implementált (file:line bizonyítva).
- **Téves pozitívok megerősítve** (már kész, nem hiány):
  - G24 kártyás sztornó → `StornoService.executeOtpTerminalStorno` + `OtpTerminalProtocolService`
  - G25 LED futófény → `LedDisplayService` + `LedSerialPortDriver` (COM)
  - G26 okmány-szkennelés → `penztar-client/electron/scanner.ts`

## Új, VERIFIKÁLT valódi gap-ek (v2.26.25 sprintre)
| # | Gap | Modul | Konfidencia | Jelleg |
|---|---|---|---|---|
| N1 | Internet/nagyker árfolyamlap-karbantartás (a gomb `'Hamarosan elérhető'` stub) | ARFOLYAM TINTERNETTMKFORM | HIGH | FE rate-maker |
| N2 | TEÁOR referencia-tábla + typeahead picker (most szabad-szöveg) | TEAOR | HIGH | BE ref-tábla + FE |
| N3 | HUF/inaktív-valuta „nem választható" guard (legacy üzenet) | ELADAS/VASARLAS | MED | BE validáció |
| N4 | WU partner-cég (WUAFACEGEK) törzs CRUD | GETWCEG | MED | BE+FE (ha WU él) |
| N5 | METRO/TESCO elkülönített ÁFA-visszatérítő partner-flow (5/18/27%) | METRO/TESCO | MED | BE+FE |

**Szándékos scope-vágás (NEM implementálandó vakon):** TRADE termék-alrendszer
(CIKKTORZS cikktörzs, telefon-feltöltés, matrica-ÁFA-számla, HaviTradeControl) —
valutaváltó profil, csak `TransactionType` enum-stub (VIGNETTE/PHONE_TOPUP) maradt.
Üzleti döntés kell a revival-hoz; nem gyártunk hamis alrendszert.

## Release v2.26.24
- 4 UNSIGNED telepítő buildelve + Downloads-ba másolva (SHA-256 a CLAUDE.md horgonyban).
- Production bootstrap-status 200 (HEALTHY).

## Tanulság (megőrzendő)
A modul-térkép (`00-VALUTA-modul-terkep.md`) ✅/⛔ jelölései NEM megbízhatók önmagukban —
pl. FNYUJSAG ⛔-ként, holott a `LedDisplayService` már implementálta; TEAOR ❓, holott
a G27 kész. A verifikációt MINDIG a tényleges kód ellen kell futtatni.
