---
title: Zárás beérkezés központi modul
date: 2026-05-12
status: implemented
version: 2.5.43
tags:
  - kozponti-munkaallomas
  - zaras
  - legacy-modulok
  - installer
---

# Zárás beérkezés központi modul

Autonóm fejlesztési lépés a szerver legacy modul inventory alapján.

Legacy megfelelők:

- `zarasctrl.dll`
- `beerk.dll`
- `missctrl.dll`
- `daybook.fdb` zárási állapot/missing-closing működés

## Elkészült

- Backend `ClosingControlService` minden aktív irodát visszaad a kiválasztott
  napra.
- Ha nincs `closing_control` rekord, a válaszban explicit `missingRecord=true`
  jelenik meg.
- Hiányzó múltbeli zárás: `CRITICAL`.
- Hiányzó mai/nem teljes zárás: `WARNING`.
- Teljes zárás: `NONE`.
- A lekérdezések és figyelmeztetések cégen belül szűrtek.
- A központi Electron app új route-ja: `/central/closing-control`.
- A központi irányítóközpont csempéje és a bal oldali menü is erre mutat.
- A naplókönyv oldal query paraméterből is fogad `branchId` és `date` értéket,
  hogy a központi monitorból konkrét iroda/nap kontextusra lehessen átlépni.

## Telepítő

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.43.exe
SHA256: 9D51AF39DA0F408CCB87553FB3B7A924315F5F8AED1483E5841AF888583AD5A9
```

## Ellenőrzés

- `npm run package:kozponti`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `cd backend; .\mvnw -Dtest=ClosingControlServiceTest test`
