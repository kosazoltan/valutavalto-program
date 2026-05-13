---
title: Beérkezett adatok központi modul
date: 2026-05-12
status: implemented
version: 2.5.44
tags:
  - kozponti-munkaallomas
  - beerkezett-adatok
  - legacy-modulok
  - installer
---

# Beérkezett adatok központi modul

Autonóm fejlesztési lépés a szerver legacy modul inventory alapján.

Legacy megfelelők:

- `beerk.dll`
- `datadisp.dll`
- `getdisp.dll`
- `daybook.fdb` napi adatcsomag/beküldés áttekintés

## Elkészült

- Új backend API:
  `GET /api/v1/central/received-data/status?date=YYYY-MM-DD`.
- A backend minden aktív irodát visszaad a kiválasztott napra.
- A válasz összefésüli:
  - aktív irodák,
  - `daily_report`,
  - `closing_control`.
- A hiányzó napi jelentés explicit státuszt kap, nem tűnik el üres rekordként.
- Új központi route: `/central/received-data`.
- Új menüpont: `Központ / Beérkezett adatok`.
- Új oldal: `frontend-react/src/pages/central/ReceivedDataOverviewPage.tsx`.
- Funkciók: dátum, keresés, státuszszűrés, CSV export, napi könyv drill-down.

## Telepítő

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.44.exe
SHA256: 0B273FAF1A8CE69870D0B9DD65C6EF59CBBE21B94997E94570B5022A1FD8F056
```

## Ellenőrzés

- `npm run package:kozponti`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `cd backend; .\mvnw "-Dtest=CentralReceivedDataServiceTest,ClosingControlServiceTest" test`
