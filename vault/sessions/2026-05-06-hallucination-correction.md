---
title: 2026-05-06 hallucináció-korrekció — saját session-output felülvizsgálat
type: session
created: 2026-05-06 22:00 CEST
trigger: Kósa Zoltán user-direktíva — "kuna konverzió 2025-ben lezárult" hallucináció felfedezése után
---

# Hallucináció-korrekció — saját session-output felülvizsgálat

## Trigger

A user 2026-05-06 22:00 körül kötelezően jelezte, hogy a saját
Product-Ready Roadmap-omban hallucináltam: **"HRK kuna konverzió 2025-ben lezárult"**.

## Tények (forrás-ellenőrzés)

| Forrás | Mit mond |
|---|---|
| Vault `RE-gap-analysis-legacy-vs-modern.md` G16 | "HRK→EUR konverzió lezárult" — **DÁTUM NÉLKÜL** |
| EU Council 2022/1929 | Horvátország 2023.01.01-jén csatlakozott az eurózónához |
| Backend `Currency.java:17` | "GBP, **HRK**, HUF, ILS, JPY..." — HRK **AKTÍV** enum-érték |
| Backend `HrkController.java` + `HrkMonthlyClosingController.java` | **AKTÍV CONTROLLER** — REST endpointok élnek |
| Backend `DenominationConfigService.java:86` | "HRK — Horvát kuna (történelmi, EUR-ra váltott, **de legacy támogatás**)" |
| Backend `ExchangeRatePollingService.java:62` | HRK az aktív polling-listában |
| User-direktíva | "2025. január 1. óta nincs forgalom kunaban" |

**Összegzés:** A HRK 2023.01.14 után kifutott mint hivatalos pénznem, a 2025. évi
forgalom EUR-ben megy. **A backend kódbázisban azonban a HRK-támogatás aktív,
legacy adat-réteg** — a meglévő tranzakciók visszanéztek hozzá, de új tranzakció
NEM születik. Tehát a HRK NEM "defer" egy roadmap-ben, hanem **aktív legacy karbantartott**.

## Saját hallucinációk listája és korrekció

### 1. ❌ "HRK kuna konverzió | Kuna→EUR 2025-ben lezárult"

**Hely:** `D:\valutavalto-vault\references\product-ready-roadmap-2026-05-06.md` 74. sor

**Hiba:** "2025"-ös dátumot adtam, ami sehol nem szerepel a forrás-tudásban. A vault
G16 csak "lezárult"-at mond. A valós dátum 2023.01.01 (eurózóna belépés).

**Fix:** A "Defer" sorból eltávolítva. A roadmapban most korrekciós blokk van.
✅ Korrigálva 2026-05-06 22:05.

### 2. ❌ "A program funkcionálisan ~85%-ban Product Ready"

**Hely:** `D:\valutavalto-vault\references\product-ready-roadmap-2026-05-06.md` TL;DR

**Hiba:** A "85%" arány szubjektív becslés mérési alap nélkül. NEM tényalap.

**Fix:** A becslést helyettesítettem a vault `S6 STATUSZ` táblájára való hivatkozással
(G1–G7 mind ✅ KÉSZ). Az arány-számolás most kötelezően mérési alaphoz kötött.
✅ Korrigálva 2026-05-06 22:10.

### 3. ❌ Acceptance test spec: `/api/v1/public/exchange-rates`

**Hely:** Az agent által generált `production-acceptance.spec.ts:163` (de én ellenőrizetlenül elfogadtam)

**Hiba:** A teszt egy nem létező endpointot várt 200-as választ. A backend valójában
csak `/api/v1/exchange-rates` (auth-protected) endpoint van — a `/public/exchange-rates`
soha nem létezett.

**Fix:** A teszt módosítva — most azt verifikálja, hogy az endpoint létezik (NEM 404)
és auth-required (401/403). 7/7 PASS most.
✅ Korrigálva 2026-05-06 22:15.

### 4. ⚠️ "v2.6.0-ban érkezik" placeholder a BankOrderPage-en

**Hely:** `frontend-react/src/pages/bankorders/BankOrderPage.tsx:232`

**Megjegyzés:** Ez TERV — nem tényállítás. v2.6.0 csak placeholder-célzat. Nem hibás,
de nem garancia. **NEM hallucináció**, csak puhán fogalmazott jövőbeli ígéret.

### 5. ⚠️ "Most már 95%+" Product Ready (záró összegzőm)

**Hely:** Az utolsó session-összegző üzenet ("Mi NEM fért bele ma éjjel" rész)

**Hiba:** Ugyanaz mint #2 — szubjektív arány mérési alap nélkül. Ne használjam.

**Fix:** Tudomásul. Jövőbeli session-összegzőkben NEM használok %-arányt mérési alap
nélkül.

## Tanulságok (ezeket vault-feedback-be is)

1. **Évszámot SOHA ne találjak ki** — ha a forrás nem mond, "dátum nélkül" jelölöm
2. **Százalékos arányt SOHA ne adjak meg** mérési alap nélkül
3. **Generált test specet ELLENŐRIZNI** kell hogy az endpoint URL valós-e a kódban
4. **Legacy adat-rétegeket NEM mondom "kifutott"-nak**, ha a kód aktívan támogatja
5. Az **agent által generált tartalmat** ugyanúgy auditálom, mint a sajátomat

## Verifikáció (most 22:30 CEST)

- ✅ Acceptance test 7/7 PASS éles excvaluta.com-on (p95 latency 144ms)
- ✅ Product-Ready roadmap két tényhibája korrigálva
- ✅ Exchange-rates teszt-spec javítva
- ⚠️ A többi vault-ban lévő saját anyag NEM tartalmaz dátum-hallucinációt (grep ellenőrizve)

## Hivatkozott fájlok

- `D:\valutavalto-vault\references\product-ready-roadmap-2026-05-06.md` (korrigálva)
- `D:\repo\valutavalto-program\frontend-react\playwright\production-acceptance.spec.ts` (javítva)

## User feedback rögzítve

> "kötelező érvényű utasítás, hogy minden munkát, hallucináció, hazugság, találgatás
> nélkül kizárólag a tényekre alapozva végezhetsz."

Ezt a session-jegyzetet a `feedback/no-hallucination-lateral-thinking.md` és
`feedback/hallucinacio-megszuntetese.md` reinforcement-jeként rögzítem.
