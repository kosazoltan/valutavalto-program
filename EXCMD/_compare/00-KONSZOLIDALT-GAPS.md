# Konszolidált gap-backlog — EXCMD spec ↔ jelenlegi program

> **Készült:** 2026-05-22. Forrás: a 27 EXCMD spec (`EXCMD/b*.md`) szakaszonkénti összevetése a v2.26.18 kóddal (6 verifikációs ügynök, kód-bizonyítékkal). Részletek: `c1`–`c6` riportok ugyanitt.
>
> A program **érett**: a magfunkciók (Foglaló, WU, kez.ktg, ÁFA, e-ker, sztornó, napzárás, címletezés 7 stratégia, dekád/TRB, RB-mozgások, AML küszöbök, NAV/MNB, multi-tenant, audit) implementáltak. Az alábbiak a **verifikált, valós hiányok**.

## Státusz

| # | Gap | Forrás-spec | c-riport | Prio | Csomag | Státusz |
|---|---|---|---|---|---|---|
| G1 | Foglaló FE↔BE kontraktus-törés (UI nem működik: 404/400, üres lista) | b4-foglalo | c3 | **P0** | frontend + backend | nyitott |
| G2 | Sztornó eltérő (aktuális) árfolyamon — backend eldobja a customRate-et, mindig eredeti árral | b2-sztorno FR-10/12/16 | c2 | **P0** | backend + penztar-client | nyitott |
| G3 | NAV zárás-eltérés gate nincs bekötve a ClosingWizard-ba (csendben átmegy) | b2-zaras-ablak FR-4 | c2 | **P0** | frontend (backend kész) | nyitott |
| G4 | FATF többszintű ország-lista (1/a, 1/b, 2. csoport) — ország-alapú ellenőrzés + verziókövetés | b9-korlevelek FR (9.sz körlevél) | c5 | **P0** | backend + frontend | nyitott (lista-adat kell) |
| G5 | Szankció név-normalizálás Unicode-tolerant (NFD) | b8-terrorlista FR-6 | c6 | **P0** | backend | ✅ **KÉSZ** (e PR) |
| G6 | Szankció ENTITY (szervezet) import | b8-terrorlista FR-5 | c6 | **P0** | backend | ✅ **KÉSZ** (e PR) |
| G7 | RFM validáció iránya: eladási ≥ elszámoló ÉS vételi ≤ elszámoló | b1-arfolyamkeszito FR-RFM-25 | c1 | P1 | arfolyam-keszito-client | nyitott |
| G8 | Foglaló 5% letét-szabály (jelenleg a teljes Ft-érték a letét) | b4-foglalo FR-9 | c3 | P1 | backend | nyitott (üzleti megerősítés: fix 5%?) |
| G9 | Pillanatnyi pénztárállás egy-képernyős nézet (NYITÓ/BEVÉTEL/KIADÁS/KEZ-I DÍJ/ZÁRÓ valutánként) | b5-penztarallas FR-PA-01/04 | c4 | P1 | backend riport + frontend | nyitott |
| G10 | Zárás-típusválasztó (DECADE/MONTHLY/POS) a wizardban (FE hardcode 'DAILY') | b2-zaras-ablak FR-3/6 | c2 | P1 | frontend (backend kész) | nyitott |
| G11 | 10M feletti tranzakció kötelező engedélyező-blokk (jelenleg csak besorolás, nem blokkol) | b5-kezeles FR-KC-11 | c4 | P1 | backend + frontend | nyitott |
| G12 | Sztornó/zárás engedélykérelem aktív értesítés (jelenleg csak log) | b2-sztorno FR-7 | c2 | P1 | backend | nyitott |
| G13 | SanctionScreening szervezet-nevek EU-listából (ENTITY) + szankció-import bővítés | b8-terrorlista | c6 | P2 | backend | részben (UN ENTITY kész G6-ban) |
| G14 | Foglaló-bizonylat render (FOGLALO ATVETELE/VISSZAFIZETESE) + ügyfél-snapshot | b4-foglalo FR-6..14 | c3 | P2 | backend | nyitott |
| G15 | Bizonylat-szűrés bővítése (ügyfeles/átadási/átvételi + hó/nap kapcsoló) | b5-penztarallas FR-PA-05 | c4 | P2 | frontend | nyitott |
| G16 | Forgalmi grafikon (chart) a napi/havi forgalom oldalakon | b5-kezeles FR-KC-08 | c4 | P2 | frontend | nyitott |
| G17 | Havi tabló dedikált frontend oldal (backend MonthlyReportService kész) | b5 / b8 | c4/c6 | P2 | frontend | nyitott |
| G18 | Forgalmi riport KÉSZPÉNZES vs BANKKÁRTYÁS bontás | b8-forgalom FR-2 | c6 | P2 | backend + frontend | nyitott |
| G19 | Munkavállaló-törzs al-nyilvántartások (üzemorvosi, szabadság, gyerekek, okmányok 1:N, bizonyítványszámok) | b9-munkavallalo | c5 | P2 | backend + frontend | nyitott |
| G20 | Beállítás-képernyők (kijelzőszín, futófény, szkenner, IP, bankkártya-engedély, napi-jelentés-jelszó, adatküldés, reklám) | b6-beallitasok | c5 | P2 | backend + frontend | nyitott |
| G21 | Körlevél szerepkörönkénti visszaigazolás-bontás | b9-korlevelek FR-2 | c5 | P3 | backend | nyitott |
| G22 | RFM részletek: Raiffeisen ±10% sáv, EUA ×1.2, INTERNET oszlop, 54-csempe rács, ellenőrzés/mentés/szétküldés szétválasztás | b1-arfolyamkeszito | c1 | P2/P3 | arfolyam-keszito-client | nyitott |
| G23 | Körzet-szintű havi forgalmi/trend riport (vevők/eladók-szám, trend%) | b8-forgalom FR-13..15 | c6 | P3 | backend + frontend | nyitott |

## Scope-on kívül / üzleti input kell (NEM hallucinálunk fejlesztést)

- ERB/FRB/TRB/PRB technikai kötés-kódok külön TransactionType-ként (c4) — carrier/seal mezők már megvannak; üzleti döntés kell.
- Zálog (EXZ) anyagok (b10-zalog) — KÜLÖN termék.
- Hardver/hálózati felmérés (b10-hardver) — telepítés-tervezés, nem programfunkció.
- NGM havi export automatizálás + SAR webhook — kézbesítési cél/auth hiányzik.

## Implementálási sorrend (javaslat)

1. **P0 batch:** G5+G6 (✅ kész), G1 (Foglaló kontraktus), G2 (sztornó aktuális árfolyam), G3 (NAV gate bekötés). G4 (FATF) — lista-adat + üzleti definíció kell, külön ütem.
2. **P1 batch:** G7, G9, G10, G11, G12, G8 (üzleti megerősítés után).
3. **P2/P3 batch:** riport/UI-tételek (G14–G23).
4. **Záró:** lint + merge + push + deploy + új 4-way telepítő (a teljes batch után).
