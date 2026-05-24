# Session: Backdoor Audit PP-13/PP-14/PP-15 — v2.26.34

**Dátum:** 2026-05-24  
**Verzió:** v2.26.34  
**PR:** [#817](https://github.com/kosazoltan/valutavalto-program/pull/817)  
**Branch:** `fix/pp13-pp14-pp15-backdoor-audit`  
**Merge commit:** `48e5c7d25` (squash merge → main)  
**Audit forrás:** `antivaluta_backdoor_audit.md` (PP-13, PP-14, PP-15)

---

## Findings és fix-ek

### PP-13 (CRITICAL) — SetupGoogleIdentificationService bootstrap guard
**Probléma:** `identify()` endpoint nyilvánosan elérhető maradt bootstrap után → támadó saját Google Subject-jét köthette bármely worker email-hez.  
**Fix:** `AdminBootstrapService` injektálva → `if (adminBootstrapService.isBootstrapAlreadyCompleted())` guard az `identify()` legelején, a `verifyIdentity()` hívás előtt.  
**File:** `SetupGoogleIdentificationService.java`  
**Teszt:** `SetupGoogleIdentificationServiceTest.java` (2 teszt)

### PP-14 (HIGH) — AdminBootstrapService company enumeration
**Probléma:** `companyRepository.findByCode()` a `alreadyCompleted` check előtt futott → valid/invalid cégkód különbség response timing-ból kiszivárgoott.  
**Fix:** `if (alreadyCompleted) { throw... }` blokk ELŐRE hozva a `normalize(dto.getCompanyCode())` hívás elé.  
**File:** `AdminBootstrapService.java`  
**Teszt:** `AdminBootstrapServiceTest.java` (meglévő teszt frissítve: `verify(companyRepository, never()).findByCode(anyString())`)

### PP-15 (MEDIUM) — WorkerService name-based login fallback
**Probléma:** `resolveWorkerForLogin()` egy 4-lépéses loop-ban a `findByCompanyId()` bulk fetch után a worker nevét is egyeztette — bejelentkezés teljes névvel (`"Kósa Zoltán"`) is működött.  
**Fix:** A 22 soros name-fallback blokk eltávolítva → 4 soros implementáció: csak `findByCompanyIdAndCode` + `findByCompanyIdAndCodeIgnoreCase` (Optional chain).  
**File:** `WorkerService.java`  
**Teszt:** `WorkerServiceLoginTest.java` (új PP-15 teszt: `login_byFullName_rejected_noNameFallback`)

---

## AI Review (Copilot) — 4 finding, mind kezelve

| # | Súlyosság | Finding | Kezelés |
|---|---|---|---|
| #1 | P2 | AI_CONTRACT.md 5-file limit (6 fájl) | Dokumentált exemption PR comment-ben (atomic security patch, nem bontható) |
| #2 | P2 | AdminBootstrapService komment sorrendje félrevezető | Javítva follow-up commitban |
| #3 | P2 | Bootstrap flag logika duplikálva | Fix: `AdminBootstrapService` injektálva, `isBootstrapAlreadyCompleted()` delegate |
| #4 | P3 | Unused Worker objektum a PP-15 tesztben | Eltávolítva follow-up commitban |

Sourcery: rate-limited (weekly 2.5M diff char limit elérve).

---

## CI Gate eredmény
Minden required check ✅ PASS:
- Backend Build + Test
- frontend-react Lint + TypeCheck
- penztar-client Test + Lint + TypeCheck + IPC Contract
- GitHub Dependency Review
- GitLeaks Secret Scan
- Trivy Backend SCA
- UTF-8 Guardrail
- npm audit
- Analyze (java-kotlin/javascript-typescript/actions)
- CodeQL

---

## Tesztszám
- **Helyi:** 1632/1632 ✅ (volt 1633 — PP-13 3 teszből 2 lett a refactor során)
- **CI Backend Build + Test:** PASS

---

## Build stratégia
Backend-only változás → **NINCS telepítő-build** szükséges.  
A fix server-served (Hetzner auto-deploy a merge után).  
Production: HTTP 200 HEALTHY ✅

---

## Tanulságok

1. **Dependency injection az elegáns megoldás** — a `SystemParameterRepository` közvetlen injektálása `SetupGoogleIdentificationService`-be code smell volt (logika duplikáció). Az `AdminBootstrapService.isBootstrapAlreadyCompleted()` meglévő publikus metódus alkalmazása 1 sorban elvégezte a munkát.

2. **A `normalizeCode()` ≠ `normalizeLoginCode()`** — `normalizeCode("Kosa Zoltan")` = `"KOSA ZOLTAN"` (szóköz megmarad), `normalizeLoginCode("Kosa Zoltan")` = `"KOSAZOLTAN"` (NFD + nem-alfanumerikus karakterek kihagyva). A PP-15 tesztnél a `findByCompanyIdAndCode` mockjában `"KOSA ZOLTAN"` a helyes argumentum.

3. **Mockito checked exception kezelése** — `doThrow(new CheckedException()).when(mock).method()` szintaxis szükséges (nem `when(...).thenThrow(...)`) ha a mock metódus checked exception-t dob, különben Java compiler "unreported exception" hibát ad.
