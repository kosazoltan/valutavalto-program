# 2026-05-09: Hibaüzenet humanizálás + teszt bővítés (PR #536 + #537)

## Kontextus
A felhasználó (Kósa Zoltán) jelentette, hogy a SetupWizard "Network Connection Error"-t ír a valódi hibaüzenetek helyett, és a teljes tesztrendszer átfogó auditját kérte.

## Elvégzett munka

### PR #536 — Szerepkör-hozzárendelés javítás (előző session-ből folytatva)
- **V195 Flyway migráció**: mind az 5 whitelisted worker (BALI, BORSI, KASZA, KOSA, FABULYA) megkapta mind a 14 kanonikus szerepkört
- **`resolveActiveRoleForSetup()`**: multi-role error eltávolítva, auto-select first selectable role
- Copilot 2 P2 (elfogadható), Sourcery 2 P2 (elfogadható), Codex rate limited
- ✅ CI zöld, merged to main

### PR #537 — Hibaüzenet humanizálás + tesztbővítés
**Frontend:**
- `humanizeRawMessage()` az `errorHandling.ts`-ben: Network Error, Failed to fetch, ECONNREFUSED, ENOTFOUND, ETIMEDOUT, SSL/CORS → magyar üzenetek
- `humanizeError()` exportálva közös util-ból (Copilot P2 feedback: duplikáció megszüntetve)
- SetupWizard.tsx: mind a 4 catch blokk `humanizeError(err)`-t használ (Copilot P2: web mód catch-ek is javítva)
- **errorHandling.test.ts**: 34 → 48 teszt (+14 új: network humanization, SSL/CORS, server passthrough, humanizeError unit)

**Backend:**
- **WorkerFirstTimeSetupServiceTest**: 10 → 20 teszt (+10 új: exact error message consistency — unknown company, unknown worker, inactive worker, password mismatch, role filtering, multi-role auto-select)

**Verzió:** 2.5.38 → 2.5.39 (4-way sync bump)

## Copilot feedback (PR #537) — JAVÍTVA
1. ✅ Duplikált `humanizeError()` → egységesítve `errorHandling.ts`-be
2. ✅ Web mód catch-ek nyers `err.message` → `humanizeError(err)`

## Teszteredmények
- Frontend: 684/684 PASS (46 fájl)
- Backend: 1239/1239 PASS
- CI: minden required check PASS

## Állapot
- **Main HEAD:** `47d0675a`
- **Production:** UP (bootstrap-status 200)
- **Open PRs:** 0
- **Stale remote branches:** 11 (cleanup szükséges)
- **Worktree:** CLEAN

## Következő teendők
- **P1:** BALI jelszava "TestJelszo123!"-re változott production-ban a tesztelés során — visszaállítás szükséges
- **P1:** Teljes tesztrendszer további bővítése — a user 200-300 tesztet vár flow-nként, jelenleg ~20/flow
- **P1:** LoginPage.tsx 248. sor — részben angol hibaüzenetek Electron IPC-ből (`result.code`, `result.message`)
- **P2:** Stale remote branch cleanup (11 db)
- **P2:** Teljes Jackson 3 migráció (39 fájl import-csere)
