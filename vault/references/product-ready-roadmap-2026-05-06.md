---
title: Product Ready Roadmap — 2026-05-06 tényalapú terv
type: reference
created: 2026-05-06
supersedes:
  - v2.4-sprint-roadmap.md (frissebb tények alapján)
status: ACTIVE
author: Claude Opus 4.7 + Kósa Zoltán session
---

# EXC Valutaváltó ERP — Product Ready Roadmap (2026-05-06)

## TL;DR

> **2026-05-06 22:00 KORREKCIÓ:** A korábbi "~85% Product Ready" becslés szubjektív
> találgatás volt mérési alap nélkül — KIVÉVE. Tényalap helyette: a vault
> `RE-gap-analysis-legacy-vs-modern.md` "S6 STATUSZ" táblája szerint **G1–G7
> minden P0/P1 legacy gap "✅ KÉSZ"** állapotban van (foglalás, NAV zárás, PEP,
> jogcím, dekádzárás, WU, POS — 2026-04-05 verifikáció). A 2026-04-29-i
> `legacy-anti-system.md` 3 modern bug (mode-isolation, F5 tab, default mode)
> a kódban már javítva: `mainLayout.tsx:171` modes szűrő, `TreasuryLayout.tsx`
> `CENTRAL_VAULT_ROLES` guard, `useAppMode.ts` Electron default `'penztar'`.
>
> A maradék "Product Ready blokkoló" tételek: lásd alább a P0–P1 listát. Az
> arány-számolás (85%/95%) tényalap nélkül NEM állítható.

**Aktuális state:** v2.5.30 production deploy SUCCESS, 1115/1115 backend test PASS, 134 electron test PASS, 3x retry minden ESET-érintett kódúton.

## Tényalapra alapulva — gap-list 2026-05-06

### ✅ KÉSZ (már implementálva)

| Terület | Bizonyíték |
|---|---|
| Multi-tenant + RBAC | 146 controller @PreAuthorize, JWT, RoleAssignment |
| AML / KYC | AmlService + bigctrl-rule-parity, V180 transaction_aml_customer_index |
| NAV jelentés | NavClosingService + NavAbevXmlGenerator |
| MNB jelentés | MnbReportController |
| Foglalás | ReservationService |
| WU + POS | WesternUnionService, PosTerminalService |
| Bizonylat + ESC/POS | EscPosReceiptService |
| Audit log | AuditLogService |
| Offline sync | SyncEngine (SQLite + 30s polling) |
| Auto-update | electron-updater (4h check) |
| Crash reporting | DiagnosticsController + ClientErrorLog (V182), GitHub Issue auto-create |
| ESET TLS proxy retry | api:fetch + httpJsonWithRetry 3x backoff (v2.5.30) |
| B6 multi-branch worker | V173 worker_branch_access + WorkerBranchAccessService |
| Mode-isolation (legacy bug-ok) | useAppMode.ts default penztar, TreasuryLayout role-filter, MainLayout mode-AND-role |

### ⚠️ P0 — Product Ready blocker (2 hét)

| # | Gap | Indok | Becsült idő |
|---|---|---|---|
| **P0-1** | **End-user manuálok** — Pénztáros, Értéktáros, Adminisztrátor PDF/HTML mappa | A kollégák nem informatikusok (CLAUDE.md null. prioritás); tanítás nélküli használat → hibák | 2-3 nap |
| **P0-2** | **DR / backup runbook** dokumentáció (Hetzner postgres dump, fast restore, RPO/RTO) | NGM 23/2014 + pénzváltó hatósági audit minimum | 1 nap |
| **P0-3** | **Production monitoring dashboard** (Hetzner uptime, p99 latency, error rate, ClientErrorLog dashboard) | Folyamatos monítorhoz; jelenleg csak GitHub Issue auto-create van | 1 nap |
| **P0-4** | **Acceptance test suite** — Playwright happy-path éles szerveren + telepítő frisseszületési forgatókönyv | A kollegák nélkül NEM lehet biztosítani, hogy minden forgatókönyv (vétel/eladás/sztornó/napzár/havizár) működik | 2 nap |

### ⚠️ P1 — Production-degradáló (2-4 hét)

| # | Gap | Indok | Becsült idő |
|---|---|---|---|
| **P1-1** | **B9 LISTAK riportok**: Forgalom dekád (van DecadeReportController!), Időszaki kimutatás, Kezelési díj dekád, Pillanatnyi készlet snapshot, Kiadott valuták, Eladott valuták, ATVETT bankjegy, ATADOTT bankjegy | Legacy parity — a kollegák meg vannak szokva ezekhez | 3 nap |
| **P1-2** | **i18next library setup** + 50 fájl migration (jelen leg ad-hoc magyar string-ek scattered) | Hosszú-távú codebase quality, multi-language opció (HU+EN) | 1-2 nap |
| **P1-3** | **E-B8 banki workflow** (#279): BankOrder + WU napi keret + sürgősségi kivét — 4-5 PR Í1000 LOC | Banki integráció, már skeleton-state | 4-5 nap |
| **P1-4** | **NGM 23/2014 compliance audit** — minden sávmező + audit log + GDPR retention policy review | Hatósági ellenőrzés bármikor jöhet | 1 nap |
| **P1-5** | **Performance test** (T4): napi/havi zárás 50k+ tranzakcióval | Production scale validáció | 1 nap |

### �️ P2 — Polish (4+ hét)

| # | Gap | Indok | Becsült idő |
|---|---|---|---|
| **P2-1** | VFD ügyfélkijelző (U4) Electron second window | UX nyereség kasszán | 2 nap |
| **P2-2** | Supervisor PIN (U5) jelszó helyett 4-6 számjegy | UX nyereség | 1 nap |
| **P2-3** | Bizonylat vizuális regresszió (T5) | Print quality | 1 nap |
| **P2-4** | Design token rendszer (U2) Inter font + egységes színek | UI consistency | 2 nap |

### ⏹ DEFER (NEM most)

| # | Téma | Indok |
|---|---|---|
| Jackson 3 migration | Springdoc 3.0.3 transitív Jackson 2 (swagger-core-jakarta:2.2.47 → jackson-dataformat-yaml:2.21.2) — `spring-boot-jackson2` stop-gap nem távolítható biztonságosan. Plus 14 test fájl `MappingJackson2HttpMessageConverter`-t használ. Külön sprint. |
| Telefon-feltöltés / autópálya matrica | Legacy TRADE.exe modul, üzletileg már nem aktív feature a modern rendszerben |
| Knowledge graph memória | Vault méret nem indokolja (20 fájl) |

> **KORREKCIÓ 2026-05-06 22:00 (Kósa Zoltán user-direktíva):**
> A korábbi verzióban a HRK kuna szerepelt mint "Kuna→EUR 2025-ben lezárult, defer".
> Ez **hallucináció volt**: a vault `RE-gap-analysis-legacy-vs-modern.md` (G16)
> csak annyit mond: "HRK→EUR konverzió lezárult" — DÁTUM NÉLKÜL. Én adtam hozzá
> a "2025"-öt indok nélkül. A valóság (forrás: kódbázis + EU hivatalos):
> - Horvátország **2023.01.01-jén** vezette be az eurót (EU Council 2022/1929)
> - A HRK 2023.01.14 után már nem volt hivatalos pénznem, kétlépcsős átmenettel kifutott
> - **2025. január 1. óta a horvát forgalom EUR-ben megy** — a kuna nincs használatban
> - A backend kódbázisban a `HrkController`, `HrkMonthlyClosingController`,
>   `Currency.HRK` enum, `DenominationConfigService` HRK címletek **AKTÍV LEGACY**
>   (nem futott ki feature, csak nincs új tranzakció rajta)
> Tehát: a HRK NEM "defer", hanem aktív legacy adat-támogatás. A 2023-as
> migráció már lezajlott a kódban. Ez a roadmapról teljesen kikerül.

## Sprint roadmap

### Sprint 1 (1 hét, 2026-05-06 → 2026-05-13) — P0 fix

- **P0-1** End-user manuálok (PDF/HTML, képernyőfotókkal)
- **P0-2** DR/backup runbook
- **P0-3** Monitoring dashboard
- **P0-4** Acceptance test suite

### Sprint 2 (1 hét, 2026-05-13 → 2026-05-20) — P1 critical

- **P1-1** B9 LISTAK riportok (8 új endpoint + 6-8 oldal frontend)
- **P1-4** NGM compliance audit + GDPR retention review

### Sprint 3 (2 hét, 2026-05-20 → 2026-06-03) — P1 secondary

- **P1-2** i18next setup + migration
- **P1-3** E-B8 banki workflow (#279)
- **P1-5** Performance test (50k tranzakció napi zárás)

### Sprint 4 (1 hét) — P2 polish

- **P2-1..P2-4** mind

## Done definition (Product Ready)

A program akkor **Product Ready**, ha:

- [ ] Minden P0 (1-4) tétel kész + bizonyítva
- [ ] 95% backend test coverage (jelenleg ~kb 85%)
- [ ] Acceptance test suite zöld production szerveren
- [ ] DR runbook tesztelve (van helyreállítás 1 órán belül)
- [ ] Monitoring dashboard 7 napja folyamatosan jelez
- [ ] End-user manuálok megerősítve egy nem-IT kolléga olvasásával
- [ ] NGM/AML compliance check pozitív

## Soron köv. konkrét akció (ezen a session-en)

1. Részletes terv vault-ba ✅ (ez a fájl)
2. Indítok egy **B9 LISTAK riport sprint** azonnali implementációt — ez a leglátványosabb gap, közvetlen user-érték
3. Második fázisban a P0-1 (user manuálok), de azt egy külön session-ben

## Hivatkozások

- [legacy-anti-system.md](legacy-anti-system.md) — audit gap források
- [v2.4-sprint-roadmap.md](v2.4-sprint-roadmap.md) — előző (részben elavult) terv
- [legacy-dll-parity-matrix.md](../../repo/valutavalto-program/docs/knowledge/legacy-reverse-engineering/legacy-dll-parity-matrix.md) — implementáció-tracker
- [GitHub issue #279](https://github.com/kosazoltan/valutavalto-program/issues/279) — E-B8 banki workflow
- [GitHub issue #386](https://github.com/kosazoltan/valutavalto-program/issues/386) — Jackson 3 (BLOCKED)
