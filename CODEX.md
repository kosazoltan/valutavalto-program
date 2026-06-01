# CODEX.md - Codex kiegeszites

Codex ebben a repoban az `AGENTS.md` rovid SSOT szerint dolgozik.

## Munkaszabaly

- Eloszor kodolj vagy javits a feladat celja szerint, ne indits automatikus
  teljes gate-ciklust.
- Celzott ellenorzes normal kodjavitasnal; teljes gate csak push/PR/deploy vagy
  magas kockazatu security/dependency/CI valtozasnal.
- Ha ugyanaz a hiba ket kor utan marad, ne valts kenszeresen modot: keszits
  minimal reprot vagy olvasd vissza a konkret forrast, majd celzottan javits.

## Deploy gate

Deploy/release elott futtatando:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/security/run-security-gate.ps1
```

`FAILED` vagy `BLOCKED` status eseten nincs deploy-ready allitas.