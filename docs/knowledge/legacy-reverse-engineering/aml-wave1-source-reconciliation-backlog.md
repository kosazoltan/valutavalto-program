---
type: reconciliation-backlog
scope: aml-wave1
version: 2026-04-11
format: structured-lookup
encoding: utf-8
description: "Single source reconciliation backlog for AML wave 1 closure, residual gaps, and stale-status cleanup"
load: on-demand
---

# AML Wave 1 Source Reconciliation Backlog

> Cel: az AML wave 1 allapotat egyetlen, forras-sorrenddel ellatott closure backlogba huzni, hogy a parity matrixok, gap dokumentumok es session memory ne adjanak egymasnak ellentmondo statuszt.

---

## S1 SCOPE

Ez a dokumentum csak az alabbi temakat huzza ossze:

- AML / BIGCTRL / KYC / sanctions wave 1 parity
- WU AML caller-chain parity
- residualis nyitott AML gap-ek
- stale vagy felreolvashato statuszok tisztazasa

Ez a dokumentum nem zarja le helyettuk:

- teljes tranzakcios / fee / rounding / storno parity wave
- teljes multi-tenant repo-audit
- hardware / NAV / printer E2E parity
- osszes compliance backlog tetel implementaciojat

---

## S2 AUTHORITATIVE_SOURCE_STACK

Frissessegi sorrend es olvasasi szabaly:

| Prioritas | Forras | Szerep | Dontesi szabaly |
|-----------|--------|--------|-----------------|
| `1` | `antivaluta.GPT-5.4.md` §18 | session handoff es kovetkezo lepes | wave1 lezart, de `R-conversion-double` nyitott |
| `2` | `docs/knowledge/memory/2026-04-11-aml-wave1-session.md` | torteneti session memory | a 2026-04-11-es wave1 bizonyitekcsomag allapota |
| `3` | `docs/knowledge/legacy-reverse-engineering/aml-bigctrl-rule-parity.md` | rule-level parity source of truth | BIGCTRL szabalyok statusza itt dolog el |
| `4` | `docs/LEGACY_PARITY_EVIDENCE_MATRIX.md` | kod + futtatas bizonyitek matrix | session- vagy futtatas-szintu bizonyitekokat rogzit, de nem overwrite-olja a rule-statuszt |
| `5` | `security-reports/latest/gate-status.json` | aktualis gate-allapot | deploy/release donteshez mindig ez az iranyado, nem a korabbi session memory |
| `6` | `docs/knowledge/compliance-backlog-by-repo-symbol.md` | implementacios backlog | nem wave1 closure statusz, hanem kovetkezo fejlesztesi sor |
| `7` | `docs/knowledge/hungarian-money-exchange-legal-baseline.md` | jogi baseline | jogi nyitott kerdeseket tart fenn akkor is, ha kodszinten valami reszben megvan |
| `8` | `docs/knowledge/legacy-reverse-engineering/legacy-dll-parity-matrix.md` | DLL-szintu mapping | masodlagos, es BIGCTRL esetben a rule-level matrixra kell visszahivatkoznia |

Szabaly:

- session memory es evidence matrix torteneti bizonyitek
- `latest` security report az aktualis deploy-gate
- BIGCTRL rule-statuszhoz az `aml-bigctrl-rule-parity.md` az elso szamu referencia

---

## S3 RECONCILIATION_MATRIX

| Forras | Aktualis allitas | Reconciled verdict | Teendo |
|--------|------------------|--------------------|--------|
| `antivaluta.GPT-5.4.md` | AML wave 1 lezart, csak `R-conversion-double` nyitott | `KEEP_BUT_REFRESH` | a handoffot technikai bizonyitekkel frissiteni kell: a parity mar teszttel igazolt, a jogi minosites kulon nyitott |
| `2026-04-11-aml-wave1-session.md` | wave1 closed, gate passed | `KEEP_WITH_SCOPE` | a `gate passed` allitas 2026-04-11-es session bizonyitek, nem orok statusz |
| `LEGACY_PARITY_EVIDENCE_MATRIX.md` | AML wave 1 regression PASS, gate PASS | `KEEP_WITH_FRESHNESS_RULE` | a PASS sor torteneti; aktualis gate-hez mindig friss report kell |
| `aml-bigctrl-rule-parity.md` | a BIGCTRL szabalyok, koztuk `R-conversion-double`, mar dedikalt teszttel bizonyitottak | `PRIMARY` | ehhez kell igazitani a DLL-level es handoff megfogalmazast |
| `legacy-dll-parity-matrix.md` | `bigctrl.dll` partial, "negyedeves / 8 napos / 6 szintu AML logika nem teljesen 1:1" | `SUPERSEDED_IN_PART` | szoveget frissiteni kell: ezek a szabalyok mar bizonyitottak, residual gap a conversion-double |
| `compliance-backlog-by-repo-symbol.md` | `CB-004`, `CB-005`, `CB-018` meg nyitott | `DEFERRED_BACKLOG` | kulon backlog, nem wave1 closure-statusz |
| `hungarian-money-exchange-legal-baseline.md` | `LEGAL-GAP-02` nyitott | `OPEN_LEGAL_TRACK` | `R-conversion-double` jogi minositeset kulon is nyitva tartja |
| `security-reports/latest/gate-status.json` | `FAILED` a `mandatory_db_preflight` miatt | `CURRENT_RUNTIME_TRUTH` | deploy blokkolt, ameddig friss gate nem `PASSED` |

---

## S4 WHAT_WAVE1_ACTUALLY_CLOSED

Wave1-ben lezart, caller-chain bizonyitekkal tamasztott elemek:

1. `AmlService.checkTransaction(..., currencyCode)` be van kotve a klasszikus tranzakcios hivaslancba.
2. `R-type--1` foreign USD blokk bizonyitott tranzakcios, WU es controller szinten.
3. WU AML mar nem csak `SEND` / `RECEIVE`, hanem `IC_IN` / `IC_OUT` utakon is aktiv.
4. WU AML fail-closed, ha AML-alap osszeg nem szamithato.
5. Aktiv blacklist talalat blokkolja a tranzakciot.
6. A sanctions screening prioritasa regresszios teszttel bizonyitott a blacklist follow-up elott.
7. A BIGCTRL negyedeves / 8 napos / tipus 4-5-6 szabalyok rule-level bizonyiteka mar megvan.

Wave1-ben nem lezart vagy nem ebbe a csomagba tartozo elemek:

1. `R-conversion-double` jogi minositese
2. teljes tranzakcios / fee / rounding / storno parity wave
3. `companyId` teljes formalis repo-audit
4. hardware / NAV / printer E2E parity

---

## S5 SINGLE_OPEN_P0_REGISTER

| Unified ID | Kapcsolodo ID-k | Tema | Allapot | Kovetkezo bizonyitek |
|------------|-----------------|------|---------|----------------------|
| `AML-P0-01` | `R-conversion-double`, `CB-004`, `LEGAL-GAP-02` | konverzional a legacy AML kuszob HUF-bazisa dupla ertekkel szamol-e, es ez jogszabalyi vagy belso intezmenyi szabaly-e | `TECH_PROVEN_LEGAL_OPEN` | `TransactionConversionServiceTest` + kulon legal classification note |

Dontesi szabaly ehhez a row-hoz:

- ha a jogi baseline szerint ez csak belso intezmenyi szabaly, akkor azt explicit policykent kell rogizteni
- ha jogi kotelezettseg, akkor rule-level parityt es caller-chain tesztet is hozza kell rendelni

---

## S6 AML_RELATED_CB_CROSSWALK

| Backlog ID | Temakor | Wave1 viszony | Megjegyzes |
|------------|---------|---------------|------------|
| `CB-004` | conversion AML parity | `TECH_PROVEN` | a technikai parity teszttel bizonyitott, a jogi minosites kulon nyitott |
| `CB-005` | sanctions auditability | `NEXT_WAVE` | wave1 a prioritas/szuresi viselkedest zarta, nem a teljes audit-log modellt |
| `CB-018` | AML audit completeness | `NEXT_WAVE` | wave1 a kritikus enforcementet zarta, teljes audit mezokitoltessel nem egyenlo |
| `CB-001` | source of funds parity | `OUT_OF_WAVE1_SCOPE` | tranzakcios parity wave resze |
| `CB-002` | cashier parity | `OUT_OF_WAVE1_SCOPE` | frontend/cashier AML bekotes kulon hullam |

---

## S7 GATE_AND_FRESHNESS_NOTE

2026-04-11 ket kulon allitas letezik, es ezeket kulon kell kezelni:

- a wave1 session memory szerint a session vegi gate `PASSED`
- a mostani friss `security-reports/latest/gate-status.json` szerint a gate `FAILED`

Aktualis ismert hiba:

- `mandatory_db_preflight`
- ok: `psql` nem eri el a lokalis PostgreSQL-t `localhost:5432`
- kovetkezmeny: deploy/release donteshez a gate jelenleg blokkolt

Ez nem torli a 2026-04-11-es wave1 session torteneti bizonyitekait, de tilos belole aktualis release-allapotot levezetni.

---

## S8 REQUIRED_DOC_CLEANUPS

1. `legacy-dll-parity-matrix.md`
   - `bigctrl.dll` megjegyzeset igazitsuk a rule-level matrixhoz
   - a fo residual gap mar ne a quarterly / 8-day / type 4-6 legyen, hanem `R-conversion-double`

2. `LEGACY_PARITY_EVIDENCE_MATRIX.md`
   - ha uj deploy-dontes keszul, ne a korabbi PASS sort hasznaljuk egyeduli forraskent

3. `compliance-backlog-by-repo-symbol.md`
   - AML tetelnel wave-besorolas vagy cross-reference hasznos lenne, hogy ne tunjon ugy, mintha a wave1 allitasaival utkoznek

---

## S9 NEXT_EXECUTION_QUEUE

Sorrend:

1. `reconcile-sources` - e dokumentum letrehozasa es a stale BIGCTRL statuszok igazgatas
2. `R-conversion-double` - jogi minosites veglegesitese es handoff frissitese
3. `close-wave1-transactions` - fee / rounding / storno / conversion parity hullam

Rovid szabaly:

- ne hozzunk uj closure summaryt, amig a fenti source stacket nem ugyanazokkal a verdict-ekkel idezzuk
- deploy elott mindig uj security gate futas kell
