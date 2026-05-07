---
title: Kötelező memóriaírás minden befejezett munkafolyamat után
created: 2026-05-07
type: feedback
priority: P0
status: active
source: user directive 2026-05-07 21:37 CEST
---

# Kötelező memóriaírás minden befejezett munkafolyamat után

Minden Valutaváltó munkafolyamat lezárásakor kötelező a memória frissítése.

Hatókör:
- Valutaváltó örökölt/Anti programhoz kapcsolódó elemzés
- feldolgozott bizonylatok / receipt / material receipt logika
- feldolgozott legacy anyagok, QMD/YAML/CSV/JSON artefaktumok
- backend, frontend, Electron, installer, DB, CI, PR, review és deploy munka

Kötelező rétegek:
- rövid távú: aktuális állapot, blokkolók, aktív direktívák
- középtávú: session handoff és friss workflow-eredmény
- operatív: reprodukálható parancsok, eljárások, recovery lépések
- hosszú távú: stabil projekt-tények, legacy parity, üzleti szabályok
- QMD/YAML/Cognee/vector/Obsidian mirror: `npm run memory:sync`

Tilos:
- feltételezést tényként menteni
- titkot, tokent, jelszót, env értéket menteni
- REST/Cognee/Obsidian sikernek mondani, ha csak fájl-bundle készült

Minimum záró parancsok:

```powershell
npm run memory:build
npm run memory:status
```

Külső sync cél esetén:

```powershell
npm run memory:sync
```
