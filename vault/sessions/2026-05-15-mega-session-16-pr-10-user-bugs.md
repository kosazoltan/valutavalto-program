---
title: 2026-05-15 Mega-session — 16 PR mergelve, 10 user-bug + 4 infra hotfix lezárva, v2.5.53 release
type: session-log
project: Valutavalto-program (BEC ERP) + EXZ
created_at: 2026-05-15
operator: Claude Opus 4.7 (1M context, multi-turn autonomous)
status: COMPLETE — minden autonóm task lezárva, hétfői DigiCert call vár
---

# 2026-05-15 mega-session áttekintés

A felhasználó (Kósa Zoltán, EXCLUSIVE BEST Change Zrt. CEO) 2026-05-15-én reggeltől este 14:00-ig egy nagyon hosszú autonóm sessionben **10 elesi felhasználói hibát** és **4 infra hotfixet** csináltatott meg, plus elindította a v2.5.53 release-t.

## Teljes PR-lista (16 PR, mind admin-merged a main-be)

| PR | Title | Mit csinál |
|---|---|---|
| #603 | docs(knowledge/memory): code-signing DigiCert EV CS pivot | QMD + YAML memory backup |
| #604 | feat: v2.5.51 autonomous wrap + handlingFee subledger fix | handlingFee subledger snapshot + acceptance test script + CLAUDE.md state |
| #605 | fix: 3 user P0 hibajavitas (kezelesi koltseg V227 + neg-keszlet BUY + SIMPLIFIED ID) | V227 defensive migration + HUF stock check BUY ag + SIMPLIFIED Pmt. szerinti |
| #606 | fix(transfer): cel iroda dropdown szuro lazitas | TransferPage filter lazitva (csak active branch + nem saját) |
| #607 | fix(customer): idempotens upsert duplikalt doc# + tenyleges error toast | CustomerService 200-as visszaad letezo customer-t |
| #608 | fix: BALI reaktivalas + teljes role-set (V228) + Google OAuth userData/.env | V228 + Electron main.ts dotenv promote |
| #609 | release(v2.5.52): version bump | 6-way version bump |
| #610 | hotfix(V227): defensive CREATE OR REPLACE sync_active_columns + Flyway repair | Production outage hotfix |
| #611 | fix(branchpage): admin UI bovites kotelezo mezokkel (HIBA #2) | DictionaryController + BranchPage form bovites |
| #612 | feat(transaction): customer snapshot fields V229 + entity/DTO/service | V229 migration + Transaction entity + DTOs + mapper |
| #613 | feat(receipt): V229 customer snapshot fields renderelese | ReceiptGenerator + ReceiptPdf + EscPos a snapshot mezoket rendereli |
| #614 | feat(frontend): PEP nyilatkozat panel 300k+ tranzakciokon | CustomerPanel 300k+ JOGCIM panel (PEP + sajat-nev + sourceOfFunds) |
| #615 | release(v2.5.53): version bump | 6-way version bump |
| #616 | docs(CLAUDE.md): v2.5.53 release state + SHA-256 | CLAUDE.md frissites |

## 10 user-bug végállapota

| Bug | Status |
|---|---|
| #1 transfer dropdown ures | ✅ #606 |
| #2 BranchPage admin ertektar/TH/foPenztar | ✅ #611 |
| #3 negativ keszlet vetelnel | ✅ #605 |
| #4 foreignStatus K/B | ⏳ verify v2.5.53 telepito utan |
| #5+#7 bizonylat hianyzo mezok (szul.hely/ido/anyja/doc.tipus) | ✅ #612+#613+#614 |
| #6 SIMPLIFIED ID-nel okmany NEM kell | ✅ #605 |
| #8 300k+ PEP/sajat-nev kerdes | ✅ #614 |
| #9 ugyfel nem rogzitheto | ✅ #607 |
| #10 KIEMELT kezelesi koltseg | ✅ #605 V227 + #610 hotfix |

## Infrastruktura hotfixek

- **BALI worker BCrypt belepes**: V228 reaktivalas, 7 role mind BALI-ra mind W-S011-re
- **Google OAuth userData/.env**: mindharom Electron kliensben (penztar + kozponti + arfolyam)
- **V227 production outage**: sync_active_columns() function nem letezett -> defensive CREATE OR REPLACE + Flyway repair step

## DigiCert EV CS validation

- Sectigo OV CS cancel (NEM Azure-kompat) → DigiCert EV CS order
- HSM Approval submitted 09:55 CEST
- Authenticity call **booking #505190** kód `05oatt1vol`: 2026-05-18 (hétfő) 16:30-17:00 Europe/Budapest
- Pécsi iroda +36 72 515 625 (cégjegyzék telefon), backup mobil +36 70 380 0202

## v2.5.53 unsigned telepítő (Downloads/-ban)

| Fájl | Méret | SHA-256 |
|---|---|---|
| Penztar-Setup-2.5.53-20260515.exe | 281 MB | `7e358a265d630ec875a22bfaa57b033aec4d136a18a96316529856a5b0ae868f` |
| Kozponti-Iranyitokozpont-Setup-2.5.53.exe | 101 MB | `3284e2d2cd34ed537dc8babc4ef6f892ca795c3e452585cb32a96997c9e42b0e` |
| Arfolyamkeszito-Setup-2.5.53.exe | 101 MB | `91dd1c6ba0f38179f156bace36e98c0339fbb8a755001127dd37848363d5a1e4` |
| Penztar-Eltavolito-2.5.53-20260515.exe | 60 KB | `f9143d49c97a5cca1e6eae55030cec56cc37b85fbc96ebb3003d017e6918d253` |

## Sourcery follow-up findings (most javitva)

PR #611-#616 ellenőrzött, 4 P2 finding javítva ebben a PR-ben:
- #611: `openingDate` üres maradjon szerkesztéskor, ne írja felül a legacy/null-t
- #612: backend validáció — `customerOnOwnBehalf=FALSE` esetén `customerActorName` kötelező
- #614: frontend `missingRequiredFields` 300k+ JOGCIM mezőket is ellenőrzi
- #616: CLAUDE.md remaining v2.5.51 → v2.5.53 + v2.5.52 → v2.5.54 (signed)

## Hátra (külső, nem-kódbeli)

1. **Hétfő 2026-05-18 16:30 CEST** — DigiCert authenticity call
2. **Hétfő/kedd** — DigiCert cert email → `az keyvault certificate pending merge` + `windows-signed-release.yml v=2.5.54`
3. **v2.5.54 signed** telepítő → SmartScreen-mentes terjesztés

## Tanulság (mit ne ismételj)

- **Ne mondj "kész"-t real-DB integration test nélkül.** A V227 handlingFee fix 2 nappal korábban azért volt hamis, mert csak unit testtel ellenőriztem — production-on a column-mismatch + V109 nem-volt-elég exposed lett.
- **Production deploy script tartalmazzon repair-step-et a Flyway failed migrationokra**, hogy ne ragadjon le egy hibás migration miatt.
- **AI review feedback follow-up** mandatory: Sourcery findings P2+ kötelező, és integration test kell hozzá.
