# Legacy Parity P1 Akcioterv

Frissitve: 2026-03-15

Celpont: a nyitott kritikus parity gap-ek lezarsa bizonyitekolhato, release-dontesre alkalmas formaban.

## 1. P1 feladatok es felelosok

| ID | Feladat | Felelos szerepkor | Pri | Allapot | Hatarido cel |
|---|---|---|---|---|---|
| P1-01 | BranchGroup (korzet) aggregacio bevezetese treasury dashboardba | Backend Lead | P1 | Kesz (kodszint) | T+3 nap |
| P1-02 | OwnCompany/Company (KFT) szintu aggregacio riport | Backend Lead | P1 | Kesz (kodszint) | T+4 nap |
| P1-03 | Nyitokeszlet automatikus atvitel E2E (zaro -> kov. napi nyito) | Backend Lead | P1 | Kesz (kodszint) | T+3 nap |
| P1-04 | Dekad riport parity verifikacio (formatum + osszeg + tranzakcioszam) | QA Lead + Product Owner | P1 | Nyitott | T+4 nap |
| P1-05 | Foglalo keszlet-elkulonites parity UAT | Backend Lead + QA Lead | P1 | Nyitott | T+4 nap |
| P1-06 | NAV integracio valodi adapterre valtas vagy formalis N/A dontes | Integration Lead + Product Owner | P1 | Nyitott | T+5 nap |
| P1-07 | `companyId` repo-szintu parity audit + riport | Security Lead | P1 | Nyitott | T+3 nap |
| P1-08 | `@PreAuthorize` lefedettsegi riport 100% igazolassal | Security Lead | P1 | Kesz (124/124) | T+2 nap |

## 2. Vgrehajtasi bontas

### P1-01/P1-02 Treasury aggregaciok
1. Query-k kiegeszitese a [backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java](backend/src/main/java/hu/puzzleir/valuta/service/TreasuryDashboardService.java#L25) service-ben.
2. DTO-k es endpoint-ek kiegeszitese branchGroup + ownCompany dimenziokkal.
3. Regresszios tesztek: inventory/treasury riportok.
4. Legacy kontroll osszehasonlito mintaadatokkal.

Acceptance:
- Branch, branchGroup, ownCompany szinten ugyanazt az aggregalt vegosszeget adja.
- Dokumentalt parity osszehasonlitas legalabb 3 nap mintaval.

### P1-03 Nyitokeszlet automatika
1. Napzaras vegi logikahoz explicit nyitokeszlet atvezetes.
2. Futtatasi teszt: zaro nap -> kovetkezo nap nyitas.
3. Hibautas teszt: reszleges sikertelenseg es rollback.

Acceptance:
- Kovetkezo napi nyito automatikusan megegyezik elozo napi zaroval.

### P1-04 Dekad parity
1. Dekad riport tartalmi validacio a [backend/src/main/java/hu/puzzleir/valuta/service/DecadeReportService.java](backend/src/main/java/hu/puzzleir/valuta/service/DecadeReportService.java#L41) alapjan.
2. UAT script: 3 dekad idoszak (1-10, 11-20, ho vege).
3. Legacy riport minta osszevetes.

Acceptance:
- Osszeg, tranzakcioszam, idoszakhatarok parity megfeleles.

### P1-05 Foglalo parity
1. Foglalo statusz es penzugyi kimenet ellenorzes a [backend/src/main/java/hu/puzzleir/valuta/entity/ReservationStatus.java](backend/src/main/java/hu/puzzleir/valuta/entity/ReservationStatus.java#L12) mappinggal.
2. Keszlet-elkulonites viselkedes UAT.
3. Lejarat + visszafizetesi edge-case futtatasa.

Acceptance:
- Legacy visszatipus logika es keszletviselkedes reprodukalhatoan egyezik.

### P1-06 NAV integracio dontes
1. Ha kotelezo: placeholder csere valodi adapterre a [backend/src/main/java/hu/puzzleir/valuta/service/NavIntegrationService.java](backend/src/main/java/hu/puzzleir/valuta/service/NavIntegrationService.java#L11) helyett.
2. Ha nem kotelezo: formalis N/A business dontes + compliance rogzites.

Acceptance:
- Valodi hardver E2E PASS vagy formalis N/A alairt dontes.

### P1-07/P1-08 Security parity audit
1. `companyId` szures szabalyos hasznalata repo-szinten ellenorizve.
2. `@PreAuthorize` coverage riport export.
3. Hianyok javitasa, ujrafuttatas.

Acceptance:
- 0 kritikus multi-tenant/security parity hiany.

## 3. Kockazatok

1. Hardver/NAV korabbi placeholder oroklese miatt integracios csuszas.
2. Legacy riport-formatumok nem teljesen dokumentaltak.
3. UAT mintadat-minoseg befolyasolhatja a parity dontest.

## 4. Exit kriterium

Az akcioterv akkor tekintheto teljesitettnek, ha:
1. minden P1 feladat `Kesz` allapotba kerul,
2. a [docs/LEGACY_PARITY_EVIDENCE_MATRIX.md](docs/LEGACY_PARITY_EVIDENCE_MATRIX.md) nyitott GAP listaja 0-ra csokken a kritikus pontokon,
3. a [docs/LEGACY_PARITY_EXEC_STATUS.md](docs/LEGACY_PARITY_EXEC_STATUS.md) allapota `GO`.
