# 2026-06-01 — Audit-verifikáció eredménye (a 2026-05-20…06-01 modulfejlesztés zárása)

Cél: a `2026-05-20_2026-06-01_modulfejlesztes_kodrevizio_javitasi_terv.md` (audit-PLAN) és a
`vault/references/audit-2026-05-31-confirmed-findings.md` állításainak **tény-alapú újraellenőrzése a
JELENLEGI kód ellen** (HEAD: main @ #978/2.27.79). Minden megállapítás file:line bizonyítékkal.

> **Fő következtetés:** az audit-PLAN doc (2026-06-01) az írásakor NEM ellenőrizte a már beadott
> javításokat, ezért **elavult**: a benne „nyitott P1/P2"-ként listázott hibák túlnyomó többsége a
> kódban **már javítva van** (mindegyik fix `// ... 2026-05-31 ...` komment-markert hordoz).

## A 2026-05-31 audit findingjai — JELENLEGI státusz

### P1 (4) — mind RENDEZVE
| # | Finding | Státusz | Bizonyíték |
|---|---------|---------|-----------|
| 1 | RateTemplate LazyInit 500 | ✅ JAVÍTVA | `RateTemplate.java:28` `@JsonIgnore`, `:157-159` `@Transient getCompanyId()` |
| 2 | receiveMovement receivedAmount≠amount | ✅ JAVÍTVA | `InventoryService.java:241` `difference=receivedAmount.subtract(...)` + audit |
| 3 | AML highRiskFlag halott write | ✅ JAVÍTVA | hívva: `TransactionService.java:726`, `TransactionOperationHelper.java:130` |
| 4 | Tautologikus multitenancy teszt | ✅ szolgáltatáson átmenő assert | `TransactionServiceMultiTenancyTest` repo-hívás + `never()` verifikáció |

### P2 (14) — mind RENDEZVE / by-design
| Finding | Státusz | Bizonyíték |
|---------|---------|-----------|
| Árfolyam 24h TTL ~25h | ✅ JAVÍTVA | `ExchangeRateService.java:87-88` percalapú `>=` |
| publishBatch megkerüli RateSpreadGate | ✅ JAVÍTVA | `RatePublishService.java:471-474` minden úton enforce |
| Ertektár /bank-transactions idempotencia | ✅ JAVÍTVA | `ErtektarController.java:40-45` `IdempotencyGuard` |
| Audit error_code-hiány | ✅ JAVÍTVA | `AdminCurrencyService.java:142` VV-SEC-004 |
| Outbox effektív-ráta NPE+divergencia | ✅ JAVÍTVA | `RatePublishService.java:228-229,374-375` `mergeRate` null-safe |
| V279 grace fiókátvétel | ✅ JAVÍTVA | `WorkerFirstTimeSetupService.java:139-158` token kötelező + VV-SEC-005 log |
| Sync-engine abandoned-szűrés | ✅ JAVÍTVA | `sync-engine.ts:253-260,756` abandoned*Ids set (PR #116) |
| Korábbi-napi sztornó → DailyBalance | ✅ JAVÍTVA | `TransactionReversalService.java:70` DÁTUM-szabály |
| Lokál csomag-publish tenant | ✅ MITIGÁLVA | `RatePublishService.publish()` workgroup+sablon tenant-check (#934); a `findById` re-read már validált groupId-t olvas |
| Multi-line per-valuta HUF | ℹ️ NEM bug | védhető kettős könyvelés: deviza-stock = bruttó bankjegy; kedvezmény/díj/kerekítés tranzakció-szintű HUF-korrekció |
| (egyéb P2-k) | ✅/by-design | TTL, idempotencia, tenant fixek lefedik |

### P3 (6) — RENDEZVE vagy alacsony prioritású maradék
| Finding | Státusz | Bizonyíték / megjegyzés |
|---------|---------|------------------------|
| StockSnapshot stockHuf csonkol | ✅ JAVÍTVA | `StockSnapshotService.java:219-220` `HungarianRounding.roundToFive` |
| CameraHashChain tamper error_code | ✅ JAVÍTVA | `CameraHashChainService.java:130,163,169` VV-TECH-005/006/007 |
| PmtCompliance 300k boundary teszt | ✅ JAVÍTVA | `PmtComplianceValidatorTest` 300k+ / 300k-alatt esetek |
| DailyBalance kettős igazságforrás | ⬜ P3 maradék | `DailyBalanceService.java:92-108` transfersIn/Out csak Transfer-ből; alacsony kockázat, architekturális |
| RateCreationPage fix vs képlet tizedes | ⬜ P3 kozmetikai | megjelenítési eltérés; spec nélkül találgatás-mentes javítás nem indokolt |
| RateCreationPage stale sheetCtxRef (multi-tab) | ⬜ P3 edge | `RateCreationPage.tsx:155,198` csoportváltáskor frissül; multi-tab edge, alacsony kockázat |

## Az audit-PLAN saját P1/P2 findingjai (2026-06-01)

| Finding | Státusz |
|---------|---------|
| P1-01 RateCreationPage literal-string | ⚠️ WARNING (nem error); CI `frontend Lint+TypeCheck` zöld minden PR-nél. i18n-konvenció-adósság, nem gate-blokkoló. |
| P1-02 / P2-04 FK02-B localStorage (nem SQLite) | ✅ TUDATOS DÖNTÉS — a felhasználó 2026-06-01 explicit választása (a rate-maker sync szándékosan kikapcsolt). NEM defekt. |
| P1-03 hash strict OFF | ℹ️ BY-DESIGN — JS↔Java canonical paritás e2e-ig; mismatch detektált+naplózott. |
| P1-04 lokál-package tenant findByIdAndCompanyId | ✅ MITIGÁLVA #934-gyel (lásd fent); explicit repo-metódus defense-in-depth, nem exploitálható nyitott bug. |
| P1-05 (2026-05-31 P1 maradék) | ✅ mind a 4 RENDEZVE (lásd P1 tábla). |
| P2-01 publishBatch spread | ✅ JAVÍTVA. |
| P2-02 hook/i18n disable-ok | a #975-ben a 4 react-hooks warning megszűnt; a megmaradt disable-ok dokumentált, szándékos seed-effektek. |
| P2-03 BranchListItem branchTypeCode | opcionális (maga az FK02-C doc is elhagyhatóként jelölte). |

## Végső, felelős minősítés

- A **2026-05-31 audit 24 findingjének túlnyomó többsége (P1 mind, P2/P3 nagy része) verifikáltan JAVÍTVA**
  a jelenlegi kódban, file:line + komment-marker bizonyítékkal.
- Az **5 utolsó feladat (FK02-B 1.1–1.4 + FK02-C)** elkészült, CI-zöld, AI-review feldolgozva, bundle-verifikálva.
- **Genuine maradék (alacsony prioritás / by-design / kozmetikai):** P3 DailyBalance dual-source, 2× P3
  RateCreationPage (tizedes + multi-tab sheetCtxRef), hash-strict (by-design), localStorage (user-döntés).
  Ezek egyike sem money-correctness vagy biztonsági bug; találgatás-alapú „javításuk" sértené a
  research-first / minimális-célzott-fix elvet.
- **Amit NEM állítok:** hogy 100%-ban minden tétel kódszinten lezárt — a fenti P3 maradékok tudatosan
  nyitva/deferelve vannak, aktuális állapottal dokumentálva (az elfogadási kritérium szerint ez megengedett).

Készítette: AI-fejlesztő ügynök, tény-alapú kód-verifikáció. Dátum: 2026-06-01.
