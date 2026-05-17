# Aktív mandate-szabályok (utolsó frissítés: 2026-05-17)

> **SESSION-START kötelező olvasmány #1.** Minden új AI session-kezdéskor ELŐSZÖR ezt az indexet olvassa be az ügynök, NEM az egyes mandate-fájlokat. Az index → mandate-fájl irány a navigáció.

> **MIKOR KÉTELY VAN:** a repo-tény (kód, Flyway-migráció, AI_CONSTITUTION.md, CLAUDE.md) **erősebb** mint az AI emlékezet.

---

## Korábbi alap-mandate (CLAUDE.md + vault/feedback/)

| # | Mandate | Forrás | Hatály | P-szint |
|---|---|---|---|---|
| C.1 | Nem-informatikus végfelhasználó alapelv | CLAUDE.md (2026-05-05) | always | P0 |
| C.2 | Folyamatos tesztelési protokoll | CLAUDE.md (2026-05-04) | always | P0 |
| C.3 | AI Review Zero-Tolerance Mandate (v2.3.18+) | CLAUDE.md (2026-04-29) | always | P0 |
| C.4 | Auto-pull AI reviews (NEM email-másolás) | **auto-memory:** `~/.claude/projects/<hash>/memory/feedback_auto_pull_reviews_no_email_copy.md` (2026-05-16) | always | P0 |
| C.5 | Titkos kulcsok kezelése | `vault/feedback/titok-kezeles-mandatory.md` + **auto-memory:** `feedback_titok_kezeles_mandatory.md` (2026-05-16) | always | P0 |
| C.6 | Push = commit + merge + branch delete (v2) | CLAUDE.md (2026-04-23) | always | P1 |
| C.7 | Memóriahasználati és tudáskarbantartási protokoll | CLAUDE.md (2026-05-04) | always | P1 |
| C.8 | Security gate (always-on) | `mandatory-security-gate.mdc` | always | P0 |
| C.9 | Session-zárási protokoll (9 fázis) | CLAUDE.md (2026-05-04) | always | P0 |
| C.10 | Lint CI + Codex + Sourcery + Copilot minden PR-en | CLAUDE.md (2026-05-03) | always | P0 |
| C.11 | Manuális Codex review trigger | `feedback_manual_codex_trigger_mandatory.md` | always | P1 |
| C.12 | AI review query metodológia (6 endpoint) | `feedback_ai_review_query_methodology.md` | always | P1 |
| C.13 | Production-first fejlesztés | CLAUDE.md | always | P0 |
| C.14 | Komplex ökoszisztéma megnyitás (4 komponens együtt) | CLAUDE.md | always | P1 |
| C.15 | 4 telepítő architektúra | `project_four_installers_architecture.md` | always | P1 |
| C.16 | Local-first architektúra | `reference_local_first_architecture.md` | always | P0 |
| C.17 | Telepítő build merge után kötelező | `feedback_mandatory_installer_build_after_changes.md` | always | P1 |
| C.18 | ESET retry pattern | `feedback_eset_retry_pattern.md` | always | P1 |
| C.19 | Hallucinációs kör megszüntetése (Context7 + iparági std) | CLAUDE.md (2026-04-29) | always | P0 |
| C.20 | AI_CONTRACT.md (300 LOC + 5 fájl plafon) | `AI_CONTRACT.md` | always | P1 |

## ÚJ üzleti / szabályozási mandate (2026-05-17 Perplexity korrekciós doksi)

| # | Mandate | Fájl | Hatály | P-szint |
|---|---|---|---|---|
| **B.1** | Pmt. (AML) invariáns | `feedback_pmt_aml_invariants.md` | always | **P0** |
| **B.2** | Pénzügyi adatintegritás (`készlet=SUM(tx)` stb.) | `feedback_financial_invariants.md` | always | **P0** |
| **B.3** | Multi-tenant izoláció (company_id) | `feedback_multitenant_isolation.md` | always | **P0** |
| **B.4** | Local-first + offline + outbox garancia | `feedback_offline_outbox.md` | always | **P0** |
| **B.5** | Szabályozási kimenetek határidő (MNB 14:30) | `feedback_regulatory_deadlines.md` | always | **P0** |
| **B.6** | Sztornó szabály invariáns | `feedback_reversal_rules.md` | always | **P0** |
| **B.7** | Code-signing függő release | `feedback_release_signing.md` | 2026-05-21-ig | **P0** |
| **B.8** | Production-first vs. TDD reconciliation | `feedback_prodfirst_vs_tdd.md` | always | P1 |
| **B.9** | Önminősítés-ellenőrzés (vakfolt + mandate checklist session végén) | `feedback_self_review_audit.md` | always | P1 |

## ÚJ AI ügynök doctrine (2026-05-17)

| # | Mandate | Fájl | Hatály | P-szint |
|---|---|---|---|---|
| **D.1** | AI ügynök Push/CI/Deploy/Merge doctrine (10 fázis) | `ai-agent-push-ci-doctrine-2026-05-17.md` | always | P0 |

## v2 ÚJ mandate (EXZ-tanulságok átültetése, 2026-05-17)

| # | Mandate | Fájl | Hatály | P-szint |
|---|---|---|---|---|
| **E.1** | ELVI-MÓD szétválasztás (VV-ELVI erősebb mint VV-MÓD) | `claude-code-valutavalto-korrekcios-mandate-2026-05-17-v2.md` 1. | always | P0 |
| **E.2** | ELVI-compliance gate (PR-leírás 16-pontos checklist) | v2 3. | always | P0 |
| **E.3** | VV-ELVI tükör memóriafájl session-start | `vault/elvi/vv-elvi-mirror.md` | always | P0 |
| **E.4** | Kanonikus TransactionStatus + RateStatus enum | v2 5.1, 5.2 | always | P0 |
| **E.5** | Állapotgép-megkerülés tilalom (no raw UPDATE) | v2 5.3 | always | P0 |
| **E.6** | Tiltott minták debt-scan workflow | `.github/workflows/business-invariant-guard.yml` | always | P0 |
| **E.7** | Capability map fenntartás | `docs/CAPABILITIES.md` | always | P1 |
| **E.8** | `business-review-required` címke + üzleti approve | v2 8. | always | P0 |
| **E.9** | "AI review NEM garantál üzleti helyességet" záró figyelmeztetés | v2 9. | always | P1 |
| **E.10** | Mérnöki vs. üzleti product-ready különválasztás | v2 10. | always | P1 |

---

## Index-karbantartás

- **Új mandate hozzáadása** → ezt az indexet kötelezően frissíteni (P0).
- **Hatályon kívül helyezés** → "Hatály" oszlopban dátum + külön szakaszba mozgatás (lentebb).
- **Mandate-konfliktus** → szigorúbbat követni + reportolni a felhasználónak.

## Hatályon kívül helyezett mandate

(Üres — minden fenti mandate jelenleg aktív.)

---

## Kontrollkérdések — sikermérés

A `claude-code-korrekcios-mandate-2026-05-17.md` 5. szakasza 3 kontrollkérdést ad. A válaszok a `vault/sessions/2026-05-17-business-mandate-load.md`-ben szerepelnek. Ha a Claude Code nem tudja válaszolni, a betöltési sorrend nem stimmel.

## Heti meta-review

Vasárnap (Drill 1 után) jelentés a felhasználónak az aktív mandate-k betartási arányáról az elmúlt 7 napban. Forrás: `vault/sessions/YYYY-MM-DD-*.md` checklist-fájlok aggregátuma.
