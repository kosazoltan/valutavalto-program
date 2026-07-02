# Diagnózis-jelentés: VW0001 / TISZA telephely-azonosító (Neon élő DB, 2026-07-02)

Forrás: `penztari-keszlet-telephely-diag.yml` run 28596040523 (7 SELECT + 4 szélesség-felmérő, read-only).

## 1. A hibajelentés fő hipotézise MEGDŐLT

**A VW0001 worker RENDBEN van:** `branch_id → BR020 (Szeged Értéktár)`, `vault_territory_id=4 (Szeged)`,
role `ertektar` (primary). NEM a régi TISZA-ra mutat — a V282-jellegű adatjavításra e fióknál NINCS szükség.

**A "VW0001 mindenre 0-t lát" tünet valódi gyökéroka a W2/W3 szélesség-felmérésből:**
- **MIND a 65+10 aktív, nem-vault pénztár `vault_territory_id`-je NULL** (region-enként: 0 van_vt_id).
- A régi `getAllStock` territory-szűrője így ÜRES metszetet adott minden értéktárosnak.
- **Ez pontosan az FK-051 (d74a1cba, PR #1264) gyökéroka, amit a region-scope javítás már megoldott** —
  a v2.28.24+ backendben a VW0001 már helyes értéket lát. A v2.28.25 deployjal élesben is megszűnik.

## 2. A VALÓDI, még nyitott adathiba: 7 aktív worker az INAKTÍV TISZA branchen

A TISZA (`dd29ef03…`, is_active=FALSE — a V244 deaktiválta) branchre mutat 7 AKTÍV worker:

| Worker | Név | Megjegyzés / gyanított helyes branch |
|---|---|---|
| BALI | Bali Henrietta (SUPERVISOR, 8 role) | → BR035 Szeged Tisza Sarok (a hibajelentés szerint ott dolgozik) |
| BORSI | Borsi Tamas | → BR035? (Szeged) |
| FABULYA | Fabulya Zsuzsa | → BR076? (Békéscsaba Belváros — a W-S036 duplikátuma ott van!) |
| KASZA | Kasza Helga | → ? (Szeged) |
| KOSA | Kosa Zoltan | → ? |
| G_KISS_KORNEL | Kiss Kornel (Google-login) | → Kaposvár! (W-S094 duplikátum: BR150) |
| G_KOSZTYU_CSABA | Kosztyu Csaba (Google-login) | → Nyíregyháza! (W-S104 duplikátum: BR057) |

FONTOS: a mapping NEM egyértelmű (Kiss Kornel/Kosztyu Csaba nem is szegediek!) —
a V282-mintájú javító migrációhoz ÜZLETI MEGERŐSÍTÉS kell worker-enként.

## 3. Beragadt pénz + függő tranzakciók a TISZA-n (üzleti döntést igényel)

- TISZA `cash_balance`: **HUF 4 985 000** (+ csupa 0 sor) — inaktív branchen beragadt egyenleg.
- 7 SUBMITTED shipment_request: 1 db TISZA→Debrecen Értéktár (2026-05-29) + 6 db BR035→Szeged Értéktár
  (06-17…06-30 — ezek a BR035-ról mennek, myük rendben, csak függőben).
- A TISZA-forrású SHR-20260529-0001 lezárása/sztornója + a 4,985M HUF átvezetése → üzleti döntés.

## 4. Következő lépések (javaslat)

1. **Nincs teendő** a VW0001-gyel (rendben van) és a Pénztári készletek 0-hibával (FK-051 már javította).
2. **Worker-átkötő adatjavító migráció (V337)** — CSAK a user által megerősített mapping után.
3. **TISZA HUF-egyenleg + SHR-20260529-0001 rendezése** — üzleti döntés (sztornó vs. átvezetés).
4. A BALI login "helyes értéket látott" jelenség konzisztens: BALI `penztar` primary role-ja
   a saját (választott) pénztár nézetét adta, nem territory-szűrőt.
