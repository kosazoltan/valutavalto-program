# Blast-Radius Helper Scripts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 4 lokális helper scriptet a `scripts/dev-tools/` mappában, amelyek API-hívás nélkül adnak tömör feedback-et a blast-radius ellenőrzéshez és teszteléshez.

**Architecture:** Minden script helyben fut (rg/Python/npm/mvn), max 50 soros output, exit code 0=zöld/1=hiba. Nincs hálózati hívás. A scriptek egymástól függetlenek.

**Tech Stack:** Python 3.14 (blast-radius.py, dep-map.py), PowerShell 7+ (typecheck-all.ps1, test-summary.ps1), ripgrep (rg.exe)

---

## File Structure

```
scripts/dev-tools/
├── blast-radius.py       # rg-alapú szimbólum-kereső (Java+TS+TSX)
├── typecheck-all.ps1     # 4 TS projekt párhuzamos typecheck + summary
├── test-summary.ps1      # backend Maven + frontend Vitest tömör összefoglaló
└── dep-map.py            # import/dependency-fa 2 szint + reverse deps
```

---

## Task 1: blast-radius.py

**Files:**
- Create: `scripts/dev-tools/blast-radius.py`

Szimbólum (osztálynév, metódus, endpoint, DTO-mező) összes előfordulása a repóban, modulonként csoportosítva. `rg`-t használ (gyors), automatikusan kizárja `node_modules`, `.git`, `target`, `dist`. Max 50 sor output.

- [ ] **Implementálás**
- [ ] **Kézi ellenőrzés:** `python scripts/dev-tools/blast-radius.py TransferDto` → ≥1 találat, modulonként csoportosítva

---

## Task 2: typecheck-all.ps1

**Files:**
- Create: `scripts/dev-tools/typecheck-all.ps1`

Mind a 4 TS projekt (`frontend-react`, `penztar-client`, `kozponti-client`, `arfolyam-keszito-client`) typecheckelése. Párhuzamos futás PowerShell job-okkal. Output: `✅ PASS` / `❌ FAIL (N errors)` + eltelt idő. Ha valamelyik sikertelen: exit 1.

- [ ] **Implementálás**
- [ ] **Kézi ellenőrzés:** `.\scripts\dev-tools\typecheck-all.ps1` → mind a 4 sor megjelenik, zöld BUILD esetén exit 0

---

## Task 3: test-summary.ps1

**Files:**
- Create: `scripts/dev-tools/test-summary.ps1`

Backend Maven (`.\mvnw.cmd test -q`) + `frontend-react` Vitest + `penztar-client` Vitest futtatása, tömör `PASS/FAIL + teszt szám` summary. Flag-ek: `-BackendOnly`, `-FrontendOnly`. Ha valamelyik sikertelen: megmutatja az első 10 hibasor-t, exit 1.

- [ ] **Implementálás**
- [ ] **Kézi ellenőrzés:** `.\scripts\dev-tools\test-summary.ps1 -FrontendOnly` → gyors futás, 2 sor summary

---

## Task 4: dep-map.py

**Files:**
- Create: `scripts/dev-tools/dep-map.py`

Adott fájl import-fájának megjelenítése 2 szint mélységig (TS/TSX: ES import; Java: import statement), plusz ki importálja ezt a fájlt (reverse dep). `node_modules` és `target` kizárva. Max 50 sor output.

- [ ] **Implementálás**
- [ ] **Kézi ellenőrzés:** `python scripts/dev-tools/dep-map.py frontend-react/src/hooks/useTransaction.ts` → DEPENDS ON + IMPORTED BY listák
