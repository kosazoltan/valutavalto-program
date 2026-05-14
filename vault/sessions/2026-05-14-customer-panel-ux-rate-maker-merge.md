# Session 2026-05-14 — Customer panel UX + rate-maker főlap merge

**Időszak:** 2026-05-14 13:45 — 14:10 CEST
**Branch-ek:** `feat/rate-maker-main-sheet` → main, `fix/customer-panel-validation-ux` → main
**PR-ek:** #581 (rate-maker főlap Phase 1 MVP), #584 (CustomerPanel UX)
**Autonóm mód:** felhasználói direktíva alapján

## Merged PR-ek

### PR #581 — Rate-maker Főlap (Phase 1 MVP)
- `MainRateSheetPage.tsx` 547 LOC új
- Iter-1..iter-7: Codex P1+P2 findings iteratív javítás
- Functional features:
  - 28 alapértelmezett valuta (EUR/USD/GBP/CHF főváluta + 24 kereszt-alapú)
  - A-I oszlopok: Elszámoló / OTP segéd / Segéd / Valuta / Gyenge multis vétel/eladás / Kereszt számolt / Kereszt forrás / Nagybani
  - Kereszt árfolyam képletes A oszlop (auto-derive G-ből)
  - Edit buffer pattern: parseFloat nem rontja a "3,5" típusú beírást
  - flushActiveCell sync return: saveLocally + dispatchToServer race-mentes
  - KILÉPÉS pending-buffer check + flush BEFORE confirm
  - CSOPORTOK KARBANTARTÁSA save-locally-success gate
- Codex iter-7: "Didn't find any major issues"
- Sourcery: weekly rate-limit (non-blocking per mandate)

### PR #584 — CustomerPanel UX javítás
- User-bejelentés: "100k HUF felett nem lehet ügyfelet regisztrálni / ügyfél nélkül nem ment"
- Root cause: `handleSaveManualCustomer` silent return invalid form-mal — semmilyen visszajelzés
- Fix:
  - `missingRequiredFields` memo per identification level (SIMPLIFIED: 4 mező, FULL: +2)
  - toast.warning konkrét mezőkkel a Save gomb kattintáskor
  - Állandóan látszó "Hiányzó mezők: ..." hint a Save gomb alatt
  - data-testid attribútumok 6 manual entry input-ra (Sourcery P3)
  - Inline hex `#94a3b8` → Tailwind `bg-slate-400` (Sourcery P3)
- 6 vitest teszt, 6/6 PASS
- Codex iter-1: "Didn't find any major issues. Delightful!"
- Codex iter-2: "Didn't find any major issues. Breezy!"
- Sourcery: 3 P3 high-level (2 addressed, 1 i18n deferred)
- Copilot: high-level overview, no findings

## Felhasználói kérés-elemzés (20 item)

### Már implementálva v2.5.50 main-ben (de NEM az általuk telepített v2.5.49-ben):
- **#5** Átadás összegek ezres elválasztóval — `thousandSeparator={true}` a TransferPage NumberInput-on
- **#6** Átadás "fogadás" funkció — `openReceiveModal` + `transferApi.receive` működik
- **#7** Átadás insufficient stock check — TransferPage line 195-209 `cashBalanceApi.list()` ellenőrzés
- **#8** Átadás fuvarozó név + plombaszám — `carrierName`, `sealNumber` field-ek
- **#9** Kezelési költség beállítás menüpont — `HandlingFeeConfigPage.tsx` BRACKET + PER_MILLE módokkal, `/handling-fee-config` route, "Kezelési költség beállítás" menü-bejegyzés
- **#12** SetupWizard EXZ → "Valuta Pénzváltó Rendszer" — hotfix #573 (cef87415, 2026-05-13 20:42, **AFTER** v2.5.49 build at 15:34!)

### Új PR-ek:
- **#19** Rate-maker főlap — PR #581 merged ✅
- **#2** CustomerPanel UX — PR #584 merged ✅

### Server-side investigation szükséges (kód-szintű fix nem azonnal lehetséges):
- **#11, #13, #14** Google login fail (Bali, Fabulya): backend error message "Google bejelentkezés sikertelen" = `GoogleIdTokenService.verify()` failure
  - Lehetséges okok: `google.client.id` env var, token expired, email_verified=false, hosted domain mismatch, V203 BALI/W-S011 dedup nem futott le production-on
  - V222 (hotfix #573) NEM volt a v2.5.49 installer-ben — Bali roles túl-permissive maradt
  - W-S011 worker subject-binding állapota production-on bizonytalan

### Substantial follow-up sprints:
- **#1** Devizastátusz per-ITEM CashierTransactionPage (jelenleg legacy TransactionPage-en per-transaction)
- **#3** Átadás menü relevant terület filter
- **#4** TH (többlet-hiány) regiszter + belső ellenőr password
- **#10** Sávos árfolyamkedvezmény pénztárosi sáv 400k Ft napi 5x (részben kész #564/#565/#579)
- **#19 Phase 2** Rate-maker backend persistence + reactív munkacsoport data flow

### Nem feature-bug (UX/role config):
- **#15, #16, #17** Pénztároskód belépés OK — működő flow
- **#18** Szerepkör választó sok role-t mutat — config kérdés, NEM bug (user kifejtette)

## Local-first mandate dokumentumok

A vault dokumentumok be lettek mergelve (PR #584 első commit, `docs(local-first)`):
- `vault/feedback/local-first-mandatory-directive.md` (user-direktíva 2026-05-14)
- `vault/references/local-first-architecture-mandate.md` (arch + 12 teszt)
- `docs/knowledge/memory/2026-05-14-local-first-architecture-mandate.{qmd,yaml}`

A `packages/local-first-core` modul + 3-client integráció már main-en van (#582, #583, prev session).

## Telepítő helyzet

**A user a Penztar-Setup-2.5.49-20260513.exe-t telepítette** (build: 2026-05-13 15:34).
**Hotfix #573 (cef87415) merged 2026-05-13 20:42** — 5+ órával AZ INSTALLER UTÁN.

**v2.5.50 installer EXISTÁL** (`%USERPROFILE%\Downloads\`, build: 2026-05-14 5:41-5:51):
- `Penztar-Setup-2.5.50-20260514.exe` (281 MB)
- `Penztar-Eltavolito-2.5.50-20260514.exe`
- `Kozponti-Iranyitokozpont-Setup-2.5.50.exe`
- `Arfolyamkeszito-Setup-2.5.50.exe`

**A v2.5.50 installerek a #573 hotfixet TARTALMAZZÁK** (SetupWizard text + V222 role cleanup).

**A v2.5.50 NEM tartalmazza** a most mergelt:
- #581 rate-maker főlap
- #584 customer panel UX
- (PR #582+#583 local-first infra a prev session-ben, már main-en)

→ **Javasolt:** v2.5.51 installer rebuild a most main-en lévő összes változással.

## Session-záró ellenőrzések

- ✅ Lokális tsc → 0 error
- ✅ Lokális eslint → 0 error (1 pre-existing literal warning)
- ✅ Lokális vitest → 6/6 PASS (CustomerPanel.test.tsx)
- ✅ CI mind a 2 PR-en (11-15/15 pass, 0 fail)
- ✅ Codex review mind a 2 PR-en mind az iter-en "no major issues"
- ✅ Sourcery: P3 high-level addressed (2/3) vagy deferred (1/3 i18n)
- ✅ Copilot: no findings
- ✅ Admin merge --squash --delete-branch mindkét PR
- ✅ Main HEAD: `714c03a4` (#584) majd `faf77c3b` (#581) — mindkettő production-ready
- ✅ Hetzner production deploy: automatikus, bootstrap-status várhatóan 200

## Megválaszolatlan kérdések (user-direktívát igényel)

1. v2.5.51 installer build szükséges? (most main-en van: #581 + #584 ami v2.5.50-ben nincs)
2. AML fail-closed → local-first degraded mode konvertálás biztonsági trade-off — user-engedély szükséges
3. #1 devizastátusz per-row implementáció scope/prioritás?
4. #11 Google login Fabulya: server-side investigation kell (env var, log) — admin közreműködés
