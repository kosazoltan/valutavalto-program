# Security Baseline V3 - risk-based

Verzio: 3.1
Datum: 2026-06-01

Ez a baseline deploy/release es security-sensitive valtozasokra vonatkozik. Nem
automatikus teljes gate normal lokalis szerkesztesekre.

## Mikor kell teljes gate

- deploy vagy release dontes elott;
- auth, permission, crypto, secret, logging, dependency, CI, container vagy DB
  schema valtozasnal;
- explicit security audit keresnel;
- ha celzott ellenorzes high/critical biztonsagi kockazatot jelez.

## Mikor eleg celzott ellenorzes

- kis, lokalis kod- vagy dokumentacios valtozas;
- nincs dependency/security/auth/CI/deploy erintettseg;
- a kockazat bizonyithato celzott teszttel, linttel, typecheckkel vagy diff
  review-val.

## Full gate command

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

Evidence: `security-reports/latest/`.

`FAILED` vagy `BLOCKED` status eseten nincs deploy-ready allitas.

## Minimum security checks

- hard-coded secret scan;
- dependency high/critical audit, ha dependency valtozott vagy release keszul;
- SAST mintak: SQL/command injection, unsafe eval/deserialization, path traversal;
- Electron veszelyes API-k, ha Electron reteg erintett;
- auth/JWT/session tesztek, ha auth reteg erintett.

## Reporting

Rovid riport eleg: parancs, status, report path, blocker vagy maradek kockazat.