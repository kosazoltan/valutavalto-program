# 2026-05-27 — Élő-API keresztmetszet bug-hunt (futó backend, valós HTTP)

## Kontextus
User-direktíva: NEM kód-olvasás, hanem a **futó alkalmazás backend API-ját** tesztelni valós HTTP
kérésekkel + kritikus frontend-logika átnézés. Minden hibát feltárni → javítani → újra tesztelni,
amíg az összes hiba javítva. Teszt-DB (Docker PG, fresh→V269), nem éles adat → teszt-tranzakciók OK.

## Tesztkörnyezet
- Docker PG (valuta-postgres), fresh DB Flyway V1→V269.
- Detached backend (mvnw spring-boot:run, `-Dlogging.config=C:/Temp/logback-dev.xml`, online mód).
- TESTADMIN admin JWT (`/tmp/jwt.txt`), EBC cég, branch BR017 "Baja Tesco", nyitott napi session.
- cash_balance bulk-init (73 branch × 22 valuta), seedelt HUF/EUR/USD.

## Feltárt + javított hibák (11) — mind élőben verifikálva

| # | Hiba | Tünet | Fix | PR |
|---|------|-------|-----|-----|
| 1 | V196 fresh-install | backend nem indul (password_hash NOT NULL vs NULL UPDATE; V197 ejti a constraintet később) | DROP NOT NULL már V196-ban | precursor #866 merged → fix PR (FLYWAY_REPAIR) |
| 2 | validateCurrencyStock üzenet | generikus „Nincs elegendő valuta készlet" BUY HUF-nál félrevezető | valuta-tudatos üzenet (kód+szükséges+elérhető) | #865 ✅ |
| 3 | storno reversal LazyInit 500 | Currency lazy proxy OSIV=false után | Hibernate.initialize(currency) | #865 ✅ |
| 4 | cash-balance LazyInit 500 ×3 | code/{code}, currency/{id}, adjust → Branch lazy | findByBranchIdAndCurrencyIdWithDetails JOIN FETCH + init | #865 ✅ |
| 5 | customer.country VARCHAR(3) 500 | „Magyarország" > 3 char → value too long | V268 VARCHAR(100) + entity @Column(100) | #865 ✅ |
| 6 | reservation receipt LazyInit 500 | branch + branch.company lazy a ReceiptGenerator-ben | initLazyAssociations (incl. branch.company) | #865 ✅ |
| 7 | reservation fulfill/cancel/getById/active LazyInit 500 | customer/branch/worker lazy a ReservationMapper-ben | initLazyAssociations a read-then-map utakon | #865 ✅ |
| 8 | storno_approval.approval_status_did bigint↔uuid | request-approval 500 (entity @ManyToOne Dictionary UUID vs BIGINT oszlop) | V269 ALTER → uuid (defenzív DO + FK) | #868 |
| 9 | STORNO_APPROVAL_STATUS dictionary seed hiány | approve 500 (orElseThrow „Hiányzó dictionary") | V269 PENDING/APPROVED/REJECTED seed | #868 |
| 10 | denomination low-stock LazyInit 500 | findLowStock nem JOIN FETCH-elt (testvérei igen) | LEFT JOIN FETCH branch+currency | #868 |
| 11 | storno frontend unlock (Codex P2) | StornoPage `approvalStatusDid === 'APPROVED'` — de az UUID, nem kód → űrlap sosem oldódott fel | új approvalStatusCode (Dictionary.code) a DTO-ban + 6 FE-összehasonlítás | #868 |

## Két fő hiba-osztály (tanulság)
1. **OSIV=false LazyInit a mapper/receipt-generátorban** (#3,#4,#6,#7,#10): a controller a tranzakció
   lezárása UTÁN mappel DTO-ra lazy proxyt. Fix-minták: (a) JOIN FETCH finder a single-entity/list
   read-úton; (b) Hibernate.initialize a tranzakción belül (lock-query mellett, ahol JOIN FETCH+FOR
   UPDATE tiltott); (c) nested asszociáció (branch.company) külön init.
2. **Régi-migráció séma↔entity eltérés** (#5,#8,#9): V3/V74-ben rosszul típusozott/méretezett oszlop
   (VARCHAR(3) free-textnek, BIGINT UUID-FK-nak) + sosem seedelt dictionary kategória.

## Verifikáció
- Backend unit: Storno/Reversal/CashBalance/Inventory/Reservation/Customer/ReceiptGenerator/
  BusinessLogic/Validation — mind zöld a fixek után.
- Élő HTTP: minden javított végpont 200 (vagy korrekt 400/404); 0 szerver-hiba a diagnostics-ban
  a valid kéréseknél.
- Széles cross-section tesztelve: buy/sell/conversion/storno(+approval)/transfer/reservation/
  cash-balance/customer/denomination/closing-wizard/bank-order/rate-master-publish/reports/PDF/NAV.

## Prod-megjegyzések
- #865 (V268 + LazyInit fixek) **éles deploy SUCCESS, prod HEALTHY 200**.
- V196 fix PR: prod deploy-on **FLYWAY_REPAIR_ON_MIGRATE=true** (checksum-változás már-alkalmazott
  migráción; 0-soros adathatás). Runbook: vault/operations/v196-fresh-deploy-fix.md.
- V268/V269 ÚJ migrációk → tiszta prod-apply, nincs repair.
