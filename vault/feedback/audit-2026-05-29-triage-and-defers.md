# Kódaudit 2026-05-29 — tényalapú triage + javítások + dokumentált deferek

Forrás: külső GPT-5.3-Codex audit (F-001…F-010). Az AI-ügynök (Claude) tényalapon (kód-út+sor)
ellenőrizte mindet, és NEM alkalmazta vakon a javaslatokat. Az alábbi a végrehajtás állapota.

## Javítva (PR)
- **F-001** (Kritikus, auth takeover) — `#928`: admin setup-token kapu a bootstrap-lezárt utáni
  null-hash first-time-worker-setuphoz (V278 + token-service + admin endpoint + guard + wizard-mező).
  AI-review-fixek: multi-tenant IDOR, atomi consume, valódi lejárat. + **`#930`** átmeneti grace
  (V279) a folyamatban lévő (null-hash) kollégák kizárásának elkerülésére.
- **F-005** (Magas, Electron proxy SSRF) — `#929`: a 169.254/16 link-local (cloud-metadata
  169.254.169.254) blokk + http(s)-only; az RFC1918 LAN-backend megtartva (legitim use-case).
- **F-006** (Magas, Electron permission) — `#929`: non-media permission default-deny mind a 3 kliensen.
- **F-008** (default „1234") — F-001-be olvasztva (a setup-token + grace kiváltja a publikus null-hash
  utat; a default-jelszó-dokumentáció az installerben külön takarítható).
- **F-002** (Kritikus, Pmt. strict) — `PMT_STRICT_ENFORCEMENT` kód-default `false` → `true`. A WARN-only
  kompat-ablak (v2.5.59 kliensek) rég lejárt (jelenleg v2.27.x). A strict-ág CSAK feltételesen blokkol
  (300k+ ÉS hiányos PEP-minőség/actor-adat) — normál tranzakciót nem érint; a UI gyűjti a mezőket.
  Unit-teszt (null szerviz) → false marad; minden tranzakció/AML teszt zöld.

## Elavult / téves (NEM módosítva — a javaslat alkalmazása kárt okozna)
- **F-004.4 (stub controllerek)** — TÉVES: a POS/WU/szkenner „Stub" controllerek valós, RBAC-védett
  (`@PreAuthorize SUPERVISOR/MANAGER/ADMIN`) endpointok, valós service-delegációval (WU adapter-minta,
  `WU_PROVIDER_MODE`). `@Profile` gate kitörölné őket prodból → POS-fizetés/WU/szkenner törés.

## Dokumentált defer (valós, de óvatossági/függőségi okból most nem)
- **F-003** (AML 10M+ vezetői jóváhagyás) — DEFER: a kód maga dokumentálja
  (`TransactionService` ~742–747), hogy **nincs supervisor-jóváhagyó UI a Buy/Sell képernyőn**, és
  bekapcsolva MINDEN szerepkörre blokkol (nincs self-approval). A flip MOST minden 10M+ tranzakciót
  blokkolna befejezési út nélkül. Feltétel: előbb a supervisor-jóváhagyó UI/flow megépítése. Utána
  `AML_HIGH_VALUE_APPROVAL_ENFORCEMENT` prod-default `true`.
- **F-004 (RBAC egységes kikényszerítés)** — az audit TÚLOZ: 569 `@PreAuthorize` > 445 mutáló endpoint,
  a SecurityConfig role-gate-eli az érzékeny családokat. A valós hiány: nincs CI-kapu új mutáló
  endpointra `@PreAuthorize` nélkül → follow-up CI-scanner (külön).
- **F-009** (egységes EXE-aláírás) — DEFER: a termék SZÁNDÉKOSAN UNSIGNED a DigiCert EV CS cert
  kiadásáig (ismert, dokumentált — CLAUDE.md verzió-stratégia). Cert kiadás → mind
  `verifyUpdateCodeSignature=true` + CI-kapu az `ALLOW_UNSIGNED_BUILD`-re.
- **F-007** (installer pg_hba trust-ablak) — TODO (külön PR): post-install validáció (nincs `trust`
  sor) + hardening minden abort-úton.
- **F-010** (Electron sandbox 26200+) — DEFER/light: a sandbox-off a Win 11 Insider 26200+ kompat
  workaround; a default-flip break-kockázatos. Tervezett: audit-log + opt-in `ELECTRON_FORCE_SANDBOX`,
  nem default-flip (NULLADIK PRIORITÁS: ne törjük a működő terméket).

**Elv:** minden finding kód-tény ellen ellenőrizve; halucináció/vak-alkalmazás nélkül; a kárt okozó
javaslatok (F-004.4 gate, F-003 azonnali flip) elvetve/deferelve dokumentált indokkal.
