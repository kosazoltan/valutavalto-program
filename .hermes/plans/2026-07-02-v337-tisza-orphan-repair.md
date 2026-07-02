# Terv: V337 — TISZA árva-adatok rendezése (worker-átkötés + egyenleg-konszolidáció + függő szállítmány)

Dátum: 2026-07-02 · Orchestrator: Fable 5 · Coder: gpt-5.5 · Reviewer: glm-5.2
Branch: `fix/v337-tisza-orphan-data-repair`
Felhatalmazás: Kósa Zoltán 2026-07-02 — "Javítsd az adatokat, javaslat szerint!"
Diagnózis-alap: vault/sessions/2026-07-02-telephely-diag-eredmeny.md (élő Neon, run 28596040523)

## Kontextus (élő DB-ből verifikált tények)

- `TISZA` branch (`dd29ef03-c7cc-4fb8-9106-045991627a85`): **is_active=FALSE** (V244 deaktiválta mint
  a BR035 "Szeged Tisza Sarok" duplikátumát). Mégis:
  - **7 AKTÍV worker** branch_id-je mutat rá,
  - **cash_balance HUF = 4 985 000** (minden más valuta 0),
  - **1 SUBMITTED shipment_request** (SHR-20260529-0001, TISZA → Debrecen Értéktár, 2026-05-29).
- Precedens-migrációk: V247 (worker dedup + balance consolidation, nyers SQL), V282 (8 vault-account
  branch-átkötés), V334 (BR020 cash_balance takarítás, dinamikus feltétellel).

## Mapping-szabály (a javaslat, amit a user jóváhagyott)

Alapszabály: a TISZA = BR035 duplikátum (V244), tehát a TISZA-n ragadt worker alapértelmezetten
a **BR035**-re kerül. Kivétel: ahol a worker személyi duplikátum-rekordja MÁS régiót bizonyít
(a W1 szélesség-felmérésből):

| worker.code | Cél branch | Bizonyíték |
|---|---|---|
| BALI | **BR035** (Szeged Tisza Sarok) | hibajelentés: ott dolgozik; TISZA=BR035 duplikátum |
| BORSI | **BR035** | szegedi, nincs más régiós duplikátuma |
| KASZA | **BR035** | szegedi, nincs más régiós duplikátuma |
| KOSA | **BR035** | szegedi, nincs más régiós duplikátuma |
| FABULYA | **BR076** (Békéscsaba Belváros) | W-S036 "Fabulya Zsuzsanna" duplikátum BR076-on |
| G_KISS_KORNEL | **BR150** (Kaposvár Dorottya Ház) | W-S094 "Kiss Kornél" duplikátum BR150-en |
| G_KOSZTYU_CSABA | **BR057** (Nyíregyháza Tesco) | W-S104 "Kosztyu Csaba" duplikátum BR057-en |

## A V337 migráció követelményei

Fájl: `backend/src/main/resources/db/migration/V337__tisza_orphan_workers_balance_and_shipment_repair.sql`

**A) Worker-átkötés (7 db):**
- `UPDATE worker SET branch_id = (SELECT id FROM branch WHERE code='<CÉL>')
   WHERE code='<WORKER>' AND branch_id = (SELECT id FROM branch WHERE code='TISZA' AND is_active=FALSE);`
- KÓD-alapú lookup (SOHA nem hardcode-olt UUID — a Neon és a lokális DB UUID-jei eltérhetnek!).
- Idempotens: a WHERE branch_id=TISZA feltétel miatt második futásra ROW_COUNT=0.
- RAISE NOTICE worker-enként a javított sorok számával (V326/V332 minta).

**B) Cash-balance konszolidáció (V247 precedens):**
- A TISZA HUF-egyenlegét ADD hozzá a BR035 HUF-egyenlegéhez (UPDATE ... SET current_balance =
  current_balance + tisza_huf), majd a TISZA HUF sorát nullázd (current_balance=0).
- A TISZA cash_balance sorait NE töröld (audit-nyom marad, a branch inaktív, sehol nem jelenik meg
  — az FK-036/V334 aktív-branch szűrése amúgy is kizárja).
- CSAK akkor fusson, ha a TISZA-n TÉNYLEG nem-nulla az egyenleg (idempotencia).
- FIGYELEM: 5 Ft-os kerekítési invariáns nem sérülhet — a 4 985 000 egész, sima összeadás.

**C) Függő szállítmány (SHR-20260529-0001):**
- `UPDATE shipment_request SET status='CANCELLED' ...` a TISZA-forrású, SUBMITTED státuszú kérésre
  (kód-alapú from_branch lookup, request_number-re szűrve).
- INDOK-mező/notes: ha van notes/cancel_reason oszlop, írd bele:
  'V337: inaktív TISZA branch árva függő kérése — adminisztratív lezárás'. Ha nincs ilyen oszlop,
  csak a státusz vált + RAISE NOTICE.
- FONTOS: NE hívj készlet-visszapótló logikát SQL-ből — a diagnosztika szerint ez a kérés május 29-i,
  a készletkönyvelés (d499a650) JÚNIUS 30-i, tehát ehhez a kéréshez NEM tartozik OUT-könyvelés,
  nincs mit visszapótolni. Ezt kommentben dokumentáld a migrációban.
- A 6 db BR035→Szeged Értéktár SUBMITTED kérés NEM érintett (azok élők, nem árvák) — ne nyúlj hozzájuk.

**D) Keretek:**
- Egyetlen DO $$ blokk, RAISE NOTICE összesítőkkel (V332 stílus).
- company-szűrés: minden lookup a TISZA branch company_id-ján belül (multi-tenant invariáns).
- A fájl fejlécében: teljes kontextus-komment (gyökérok, felhatalmazás, mapping-bizonyítékok).

## Teszt (TDD)

Fájl: `backend/src/test/java/hu/puzzleir/valuta/migration/V337TiszaOrphanRepairMigrationTest.java`
- TestContainers Flyway integrációs teszt (keresd a meglévő mintát: CurrencyMigrationTest vagy
  hasonló migration-teszt a repóban — kövesd azt a szerkezetet).
- Asserts a teljes lánc lefutása után:
  1. Nincs aktív worker inaktív branchen (általános invariáns-assert!):
     `SELECT count(*) FROM worker w JOIN branch b ON b.id=w.branch_id
      WHERE w.is_active AND NOT b.is_active` == 0
  2. BALI/BORSI/KASZA/KOSA → BR035; FABULYA → BR076; G_KISS_KORNEL → BR150; G_KOSZTYU_CSABA → BR057
  3. TISZA HUF cash_balance = 0
  4. Nincs SUBMITTED shipment_request inaktív from-branch-csel.
- Ha a teszt-DB seedje nem tartalmazza a TISZA-állapotot (a V244 után a seed-lánc már deaktiválta,
  a workerek a lokális lánc szerint lehet hogy nem is a TISZA-n vannak): a teszt akkor is érvényes —
  az 1-es és 4-es INVARIANS-assert a lényeg; a 2-es assertek legyenek feltételesek (ha létezik az
  adott worker-kód a teszt-DB-ben). Ezt kommentben indokold.

## Verifikáció (a coder futtassa)
- `cd backend && ./mvnw -q test -Dtest=V337TiszaOrphanRepairMigrationTest` → PASS
- `./mvnw -q test -Dtest='*Migration*Test'` → a többi migráció-teszt sem törik
- Flyway-lánc: V337 a legmagasabb, nincs verzió-ütközés (`ls db/migration | sort -V | tail -1`)

## Nem-célok
- A 6 élő BR035→BR020 SUBMITTED kérés bármilyen módosítása.
- A TISZA branch törlése vagy reaktiválása. A duplikált worker-rekordok (W-S011 stb.) kezelése.
- Backend Java-kód módosítása.
