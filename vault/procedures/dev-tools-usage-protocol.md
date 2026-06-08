# Dev-tools használati protokoll

Frissítve: 2026-06-08  
Scriptek helye: `scripts/dev-tools/` (44 eszköz)

---

## Mikor mit futtatok — trigger-mátrix

### Backend Java változás

```powershell
# Ki hívja a módosított osztályt?
python scripts/dev-tools/blast-radius.py <OsztályNév>

# @Transactional megvan-e a write metodusokon?
python scripts/dev-tools/transaction-audit.py

# companyId szűrés minden lekérdezésben?
python scripts/dev-tools/multi-tenant-audit.py

# TS kliensek is törnek-e?
.\scripts\dev-tools\typecheck-all.ps1
```

**Új endpoint esetén:**
```powershell
python scripts/dev-tools/endpoint-audit.py --missing-only
```

**Repository/@Query változásakor:**
```powershell
python scripts/dev-tools/jpql-perf-scan.py
python scripts/dev-tools/n-plus-one-scan.py
```

**@Scheduled módosításakor:**
```powershell
python scripts/dev-tools/scheduled-task-audit.py
```

---

### Flyway migráció hozzáadásakor (KÖTELEZŐ)

```powershell
python scripts/dev-tools/flyway-validate.py
python scripts/dev-tools/flyway-content-audit.py --last 3
python scripts/dev-tools/sql-index-gap.py
python scripts/dev-tools/migration-next-version.py
```

---

### TypeScript / React változás

```powershell
.\scripts\dev-tools\typecheck-all.ps1 -Module <modul>
python scripts/dev-tools/ts-antipattern-scan.py
python scripts/dev-tools/console-log-scan.py
```

**Új komponens:**
```powershell
python scripts/dev-tools/missing-test-files.py --module <modul>
python scripts/dev-tools/react-complexity-scan.py --module <modul>
```

**Electron fájl:**
```powershell
python scripts/dev-tools/electron-security-scan.py
```

---

### Push / PR előtt (MINDIG)

```powershell
.\scripts\dev-tools\pre-push-gate.ps1           # 10 ellenőrzés
.\scripts\dev-tools\branch-hygiene.ps1
.\scripts\dev-tools\git-diff-impact.ps1
python scripts/dev-tools/secrets-deep-scan.py
```

Gyors iterációkor: `pre-push-gate.ps1 -Fast`

---

### Hibakeresés

```powershell
python scripts/dev-tools/blast-radius.py <szimbólum>
python scripts/dev-tools/exception-audit.py
python scripts/dev-tools/layer-violation-scan.py
python scripts/dev-tools/transaction-audit.py
```

---

### PR review / kódellenőrzés

```powershell
python scripts/dev-tools/layer-violation-scan.py
python scripts/dev-tools/multi-tenant-audit.py
python scripts/dev-tools/magic-values-scan.py
python scripts/dev-tools/duplicate-block-scan.py
python scripts/dev-tools/dto-entity-sync.py
python scripts/dev-tools/mapper-audit.py
```

---

### Tesztek futtatása után

```powershell
python scripts/dev-tools/junit-report-parse.py
python scripts/dev-tools/test-timing-analyze.py
python scripts/dev-tools/test-smell-scan.py
python scripts/dev-tools/test-coverage-gap.py --java-only
```

---

### Teljesítmény-vizsgálat

```powershell
python scripts/dev-tools/jpql-perf-scan.py
python scripts/dev-tools/n-plus-one-scan.py
python scripts/dev-tools/god-class-scan.py
python scripts/dev-tools/complexity-scan.py
```

---

### Kiadás / release előtt

```powershell
python scripts/dev-tools/changelog-gen.py --from <előző-tag>
python scripts/dev-tools/api-surface-report.py
.\scripts\dev-tools\bundle-size-check.ps1
python scripts/dev-tools/build-warning-scan.py
```

---

### Biztonsági audit

```powershell
python scripts/dev-tools/secrets-deep-scan.py
python scripts/dev-tools/electron-security-scan.py
python scripts/dev-tools/endpoint-audit.py
```

---

## Tool-lista (44 db)

| Script | Mit csinál | Mikor |
|--------|-----------|-------|
| `blast-radius.py` | Ki hívja a módosított szimbólumot | Minden Java változás |
| `transaction-audit.py` | @Transactional hiány write metódusokon | Backend változás |
| `multi-tenant-audit.py` | companyId szűrés hiány | Backend változás |
| `typecheck-all.ps1` | Mind a 4 TS-projekt | Mindig |
| `flyway-validate.py` | Migráció névkonvenció, dup verzió | Flyway változás |
| `flyway-content-audit.py` | DROP/TRUNCATE/DELETE veszélyes SQL | Flyway változás |
| `sql-index-gap.py` | FK→INDEX rés, CASCADE veszély | Flyway változás |
| `migration-next-version.py` | Következő V-szám, konflikt | Új migráció előtt |
| `endpoint-audit.py` | @PreAuthorize hiány | Új endpoint |
| `n-plus-one-scan.py` | @OneToMany @BatchSize hiány | JPA változás |
| `jpql-perf-scan.py` | LEADING LIKE, findAll limit nélkül | Query változás |
| `layer-violation-scan.py` | Controller→Repository bypass | PR review |
| `exception-audit.py` | Üres catch, broad Exception | Bug debug |
| `magic-values-scan.py` | Nyers HTTP-kód, Thread.sleep | Review |
| `duplicate-block-scan.py` | Ismétlődő kódblokkok | Review |
| `complexity-scan.py` | >50 soros metódus, >500 soros fájl | Review |
| `god-class-scan.py` | >20 metódus, >15 mező | Review |
| `scheduled-task-audit.py` | @Scheduled try-catch hiány | Scheduler változás |
| `dto-entity-sync.py` | Entity↔DTO mező rés | DTO változás |
| `mapper-audit.py` | MapStruct ignore-ok | Mapper változás |
| `ts-antipattern-scan.py` | any, @ts-ignore, non-null | TS változás |
| `console-log-scan.py` | console.log production kódban | TS változás |
| `import-cycle-detect.py` | Körkörös TS import-ciklus | TS refactor |
| `electron-security-scan.py` | nodeIntegration, contextIsolation | Electron változás |
| `react-complexity-scan.py` | useState>5, useEffect>3, props>7 | Új komponens |
| `missing-test-files.py` | Tesztfájl nélküli komponensek | Fejlesztés |
| `junit-report-parse.py` | Surefire XML riport | Maven test után |
| `test-smell-scan.py` | Üres teszt, nincs assert | Tesztelés |
| `test-coverage-gap.py` | Teszteletlen Service/Controller | Tesztelés |
| `test-timing-analyze.py` | Leglassabb JUnit tesztek | Maven test után |
| `coverage-report-parse.py` | Vitest coverage JSON | Frontend test után |
| `openapi-spec-audit.py` | OpenAPI YAML hiányos 401/403/500 | API doc |
| `build-warning-scan.py` | @Deprecated, @SuppressWarnings | Review |
| `secrets-deep-scan.py` | 30+ titok-minta | Push előtt |
| `changelog-gen.py` | Conventional Commits CHANGELOG | Release |
| `git-diff-impact.ps1` | Változtatás → érintett modulok | Push előtt |
| `branch-hygiene.ps1` | Branch-név, stale ágak, conflict | Push előtt |
| `bundle-size-check.ps1` | Vite dist/ chunk-méretek | Release |
| `api-surface-report.py` | Teljes REST API felszín | Release/doc |
| `dead-code-scan.py` | Nem hivatkozott exports/public | Refactor |
| `todo-harvest.ps1` | TODO/FIXME/HACK gyűjtő | Review |
| `dep-map.py` | Import/dependency-fa | Architektúra |
| `test-summary.ps1` | Maven+Vitest összefoglaló | CI |
| `pre-push-gate.ps1` | 10+ ellenőrzés orchestrátora | Push előtt |

---

## Gyors parancs: összes tool listázása

```powershell
ls scripts/dev-tools/ | Select-Object Name
```
