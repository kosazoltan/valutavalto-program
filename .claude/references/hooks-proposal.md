# Hook Javaslatok — CSAK JAVASLAT, NEM AKTÍV

> **FIGYELMEZTETÉS:** Ez a fájl kizárólag javaslat jellegű dokumentáció.
> A forrás MegaPrompt 21. szekciója expliciten tiltja a veszélyes hookok automatikus aktiválását.
> A `settings.json` és `settings.local.json` fájlokat ez a bootstrap NEM módosítja.
> Hookok aktiválásához emberi jóváhagyás és tudatos konfigurálás szükséges.

---

## 21. szekció — Javasolt Hook Logika

A bootstrap ne aktiváljon veszélyes hookot automatikusan. Csak javaslatot tegyen.

### 1. PreToolUse / file edit guard
- blokkolja frozen test fájlok módosítását implementációs fázisban
- blokkolja `.env` és secret fájlok olvasását/kiírását

### 2. PostToolUse / formatting
- format csak production fájlokra
- ne formázza át az egész repót feladat ürügyén

### 3. Stop / validation reminder
- figyelmeztet, ha nincs validation result

### Példa JSON (policy: example-only — NEM aktivált, NEM éles konfiguráció)

```json
{
  "policy": "example-only",
  "guards": [
    {
      "name": "block-frozen-test-edits",
      "paths": [
        "tests/**",
        "__tests__/**",
        "**/*.test.*",
        "**/*.spec.*",
        "fixtures/**",
        "snapshots/**"
      ],
      "phase": "implementation",
      "action": "block"
    },
    {
      "name": "block-secret-output",
      "paths": [
        ".env",
        ".env.*",
        "**/secrets/**"
      ],
      "action": "block-or-redact"
    }
  ]
}
```

---

## 22. szekció — CI/CD Integráció összefoglalás

A rendszer célja, hogy az agent ne csak lokálisan „mondja", hanem CI-ben is bizonyítsa a változtatásokat.

### Ajánlott CI kapuk sorrendben

1. install
2. lint
3. typecheck
4. unit tests
5. integration tests, ha vannak
6. build
7. security scan, ha projektben már van
8. migration dry-run, ha DB érintett
9. artifact build
10. deploy csak jóváhagyás után

### GitHub Actions alapminta

```yaml
name: validation

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node
        if: hashFiles('package.json') != ''
        uses: actions/setup-node@v4
        with:
          node-version: '20'
      - name: Install
        if: hashFiles('package.json') != ''
        run: |
          if [ -f pnpm-lock.yaml ]; then corepack enable && pnpm install --frozen-lockfile; fi
          if [ -f package-lock.json ]; then npm ci; fi
          if [ -f yarn.lock ]; then corepack enable && yarn install --immutable; fi
      - name: Lint
        if: hashFiles('package.json') != ''
        run: npm run lint --if-present
      - name: Typecheck
        if: hashFiles('package.json') != ''
        run: npm run typecheck --if-present
      - name: Test
        if: hashFiles('package.json') != ''
        run: npm test --if-present
      - name: Build
        if: hashFiles('package.json') != ''
        run: npm run build --if-present
```

Opus szabály:
- nem gyengítheti ezt a workflow-t azért, hogy zöld legyen
- ha CI változik, futtassa/ellenőrizze a `ci-cd-gate` skillt

---

## 23. szekció — VPS Deployment Szabályok összefoglalás

VPS-en nincs kísérletezés éles adattal.

### Kötelező deployment terv

```text
TARGET:
CURRENT VERSION:
NEW VERSION:
FILES CHANGED:
DATABASE IMPACT:
ENV IMPACT:
BACKUP PLAN:
ROLLBACK PLAN:
COMMANDS:
HEALTH CHECK:
LOG CHECK:
HUMAN APPROVAL:
```

### Tiltott VPS műveletek jóváhagyás nélkül

- `rm -rf`
- adatbázis törlés
- adatbázis felülírás
- production `.env` átírása
- migráció futtatása
- konténer volume törlése
- tűzfal módosítása
- SSH kulcs módosítása
- backup törlése

Lásd részletesen: `.claude/references/vps-deployment-safety.md`
