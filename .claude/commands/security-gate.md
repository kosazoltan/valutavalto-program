# /security-gate

Futtasd a kotelezo security gate-et es keszits evidence reportot.

## Command

```bash
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

## Required output

- Donto statusz: `GO` vagy `NO-GO` (`FAILED`/`BLOCKED` => `NO-GO`)
- `CRITICAL`/`HIGH` finding szam
- Riportok: `security-reports/latest/`
