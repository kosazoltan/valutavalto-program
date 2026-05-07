---
title: Product Ready Roadmap - 2026-05-06 tenyalapu terv
type: reference
created: 2026-05-06
supersedes:
  - v2.4-sprint-roadmap.md (frissebb tenyek alapjan)
status: ACTIVE
author: Claude Opus 4.7 + Kosa Zoltan session
---

# EXC Valutavalto ERP - Product Ready Roadmap (2026-05-06)

## TL;DR

> **2026-05-06 22:00 KORREKCIO:** A korabbi "~85% Product Ready" becsles szubjektiv
> talalgatas volt meresi alap nelkul - KIVEVE. Tenyalap helyette: a vault
> `RE-gap-analysis-legacy-vs-modern.md` "S6 STATUSZ" tablaja szerint **G1-G7
> minden P0/P1 legacy gap "OK KESZ"** allapotban van (foglalas, NAV zaras, PEP,
> jogcim, dekadzaras, WU, POS - 2026-04-05 verifikacio). A 2026-04-29-i
> `legacy-anti-system.md` 3 modern bug (mode-isolation, F5 tab, default mode)
> a kodban mar javitva: `mainLayout.tsx:171` modes szuro, `TreasuryLayout.tsx`
> `CENTRAL_VAULT_ROLES` guard, `useAppMode.ts` Electron default `'penztar'`.
>
> A maradek "Product Ready blokkolo" tetelek: lasd alabb a P0-P1 listat. Az
> arany-szamolas (85%/95%) tenyalap nelkul NEM allithato.

**Aktualis state:** v2.5.30 production deploy SUCCESS, 1115/1115 backend test PASS, 134 electron test PASS, 3x retry minden ESET-erintett koduton.

## Tenyalapra alapulva - gap-list 2026-05-06

### OK KESZ (mar implementalva)

| Terulet | Bizonyitek |
|---|---|
| Multi-tenant + RBAC | 146 controller @PreAuthorize, JWT, RoleAssignment |
| AML / KYC | AmlService + bigctrl-rule-parity, V180 transaction_aml_customer_index |
| NAV jelentes | NavClosingService + NavAbevXmlGenerator |
| MNB jelentes | MnbReportController |
| Foglalas | ReservationService |
| WU + POS | WesternUnionService, PosTerminalService |
| Bizonylat + ESC/POS | EscPosReceiptService |
| Audit log | AuditLogService |
| Offline sync | SyncEngine (SQLite + 30s polling) |
| Auto-update | electron-updater (4h check) |
| Crash reporting | DiagnosticsController + ClientErrorLog (V182), GitHub Issue auto-create |
| ESET TLS proxy retry | api:fetch + httpJsonWithRetry 3x backoff (v2.5.30) |
| B6 multi-branch worker | V173 worker_branch_access + WorkerBranchAccessService |
| Mode-isolation (legacy bug-ok) | useAppMode.ts default penztar, TreasuryLayout role-filter, MainLayout mode-AND-role |

### WARN P0 - Product Ready blocker (2 het)

| # | Gap | Indok | Becsult ido |
|---|---|---|---|
| **P0-1** | **End-user manualok** - Penztaros, Ertektaros, Adminisztrator PDF/HTML mappa | A kollegak nem informatikusok (CLAUDE.md null. prioritas); tanitas nelkuli hasznalat -> hibak | 2-3 nap |
| **P0-2** | **DR / backup runbook** dokumentacio (Hetzner postgres dump, fast restore, RPO/RTO) | NGM 23/2014 + penzvalto hatosagi audit minimum | 1 nap |
| **P0-3** | **Production monitoring dashboard** (Hetzner uptime, p99 latency, error rate, ClientErrorLog dashboard) | Folyamatos monitorhoz; jelenleg csak GitHub Issue auto-create van | 1 nap |
| **P0-4** | **Acceptance test suite** - Playwright happy-path eles szerveren + telepito frisseszuletesi forgatokonyv | A kollegak nelkul NEM lehet biztositani, hogy minden forgatokonyv (vetel/eladas/sztorno/napzar/havizar) mukodik | 2 nap |

### WARN P1 - Production-degradalo (2-4 het)

| # | Gap | Indok | Becsult ido |
|---|---|---|---|
| **P1-1** | **B9 LISTAK riportok**: Forgalom dekad (van DecadeReportController!), Idoszaki kimutatas, Kezelesi dij dekad, Pillanatnyi keszlet snapshot, Kiadott valutak, Eladott valutak, ATVETT bankjegy, ATADOTT bankjegy | Legacy parity - a kollegak meg vannak szokva ezekhez | 3 nap |
| **P1-2** | **i18next library setup** + 50 fajl migration (jelen leg ad-hoc magyar string-ek scattered) | Hosszu-tavu codebase quality, multi-language opcio (HU+EN) | 1-2 nap |
| **P1-3** | **E-B8 banki workflow** (#279): BankOrder + WU napi keret + surgossegi kivet - 4-5 PR I1000 LOC | Banki integracio, mar skeleton-state | 4-5 nap |
| **P1-4** | **NGM 23/2014 compliance audit** - minden savmezo + audit log + GDPR retention policy review | Hatosagi ellenorzes barmikor johet | 1 nap |
| **P1-5** | **Performance test** (T4): napi/havi zaras 50k+ tranzakcioval | Production scale validacio | 1 nap |

### WARN P2 - Polish (4+ het)

| # | Gap | Indok | Becsult ido |
|---|---|---|---|
| **P2-1** | VFD ugyfelkijelzo (U4) Electron second window | UX nyereseg kasszan | 2 nap |
| **P2-2** | Supervisor PIN (U5) jelszo helyett 4-6 szamjegy | UX nyereseg | 1 nap |
| **P2-3** | Bizonylat vizualis regresszio (T5) | Print quality | 1 nap |
| **P2-4** | Design token rendszer (U2) Inter font + egyseges szinek | UI consistency | 2 nap |

### STOP DEFER (NEM most)

| # | Tema | Indok |
|---|---|---|
| Jackson 3 migration | Springdoc 3.0.3 transitiv Jackson 2 (swagger-core-jakarta:2.2.47 -> jackson-dataformat-yaml:2.21.2) - `spring-boot-jackson2` stop-gap nem tavolithato biztonsagosan. Plus 14 test fajl `MappingJackson2HttpMessageConverter`-t hasznal. Kulon sprint. |
| Telefon-feltoltes / autopalya matrica | Legacy TRADE.exe modul, uzletileg mar nem aktiv feature a modern rendszerben |
| Knowledge graph memoria | Vault meret nem indokolja (20 fajl) |

> **KORREKCIO 2026-05-06 22:00 (Kosa Zoltan user-direktiva):**
> A korabbi verzioban a HRK kuna szerepelt mint "Kuna->EUR 2025-ben lezarult, defer".
> Ez **hallucinacio volt**: a vault `RE-gap-analysis-legacy-vs-modern.md` (G16)
> csak annyit mond: "HRK->EUR konverzio lezarult" - DATUM NELKUL. En adtam hozza
> a "2025"-ot indok nelkul. A valosag (forras: kodbazis + EU hivatalos):
> - Horvatorszag **2023.01.01-jen** vezette be az eurot (EU Council 2022/1929)
> - A HRK 2023.01.14 utan mar nem volt hivatalos penznem, ketlepcsos atmenettel kifutott
> - **2025. januar 1. ota a horvat forgalom EUR-ben megy** - a kuna nincs hasznalatban
> - A backend kodbazisban a `HrkController`, `HrkMonthlyClosingController`,
>   `Currency.HRK` enum, `DenominationConfigService` HRK cimletek **AKTIV LEGACY**
>   (nem futott ki feature, csak nincs uj tranzakcio rajta)
> Tehat: a HRK NEM "defer", hanem aktiv legacy adat-tamogatas. A 2023-as
> migracio mar lezajlott a kodban. Ez a roadmaprol teljesen kikerul.

## Sprint roadmap

### Sprint 1 (1 het, 2026-05-06 -> 2026-05-13) - P0 fix

- **P0-1** End-user manualok (PDF/HTML, kepernyofotokkal)
- **P0-2** DR/backup runbook
- **P0-3** Monitoring dashboard
- **P0-4** Acceptance test suite

### Sprint 2 (1 het, 2026-05-13 -> 2026-05-20) - P1 critical

- **P1-1** B9 LISTAK riportok (8 uj endpoint + 6-8 oldal frontend)
- **P1-4** NGM compliance audit + GDPR retention review

### Sprint 3 (2 het, 2026-05-20 -> 2026-06-03) - P1 secondary

- **P1-2** i18next setup + migration
- **P1-3** E-B8 banki workflow (#279)
- **P1-5** Performance test (50k tranzakcio napi zaras)

### Sprint 4 (1 het) - P2 polish

- **P2-1..P2-4** mind

## Done definition (Product Ready)

A program akkor **Product Ready**, ha:

- [ ] Minden P0 (1-4) tetel kesz + bizonyitva
- [ ] 95% backend test coverage (jelenleg ~kb 85%)
- [ ] Acceptance test suite zold production szerveren
- [ ] DR runbook tesztelve (van helyreallitas 1 oran belul)
- [ ] Monitoring dashboard 7 napja folyamatosan jelez
- [ ] End-user manualok megerositve egy nem-IT kollega olvasasaval
- [ ] NGM/AML compliance check pozitiv

## Soron kov. konkret akcio (ezen a session-en)

1. Reszletes terv vault-ba OK (ez a fajl)
2. Inditok egy **B9 LISTAK riport sprint** azonnali implementaciot - ez a leglatvanyosabb gap, kozvetlen user-ertek
3. Masodik fazisban a P0-1 (user manualok), de azt egy kulon session-ben

## Hivatkozasok

- [legacy-anti-system.md](legacy-anti-system.md) - audit gap forrasok
- [v2.4-sprint-roadmap.md](v2.4-sprint-roadmap.md) - elozo (reszben elavult) terv
- [legacy-dll-parity-matrix.md](../../repo/valutavalto-program/docs/knowledge/legacy-reverse-engineering/legacy-dll-parity-matrix.md) - implementacio-tracker
- [GitHub issue #279](https://github.com/kosazoltan/valutavalto-program/issues/279) - E-B8 banki workflow
- [GitHub issue #386](https://github.com/kosazoltan/valutavalto-program/issues/386) - Jackson 3 (BLOCKED)
