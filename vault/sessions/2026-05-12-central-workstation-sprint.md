---
title: Központi irányítóközpont sprint
date: 2026-05-12
status: implemented
version: 2.5.45
tags:
  - kozponti-munkaallomas
  - sprint
  - legacy-modulok
  - installer
---

# Központi irányítóközpont sprint

Autonóm fejlesztési lépés: az eddig megalapított központi funkciók egy sprintben
kerültek be a központi Electron programba.

## Elkészült

- Új oldal: `frontend-react/src/pages/central/CentralSprintPage.tsx`.
- Új route: `/central/sprint`.
- Új menüpont: `Központ / Központi sprint`.
- Új csempe a központi launcherben:
  `Sprint és irányítás / Központi sprint`.
- Verzióemelés: `2.5.44` -> `2.5.45`.

## Sprinttartalom

A sprintoldal minden tételnél rögzíti:

- munkaterület,
- modern modulnév,
- legacy forrás,
- cél route,
- sprintállapot,
- prioritás,
- üzleti kimenet.

Beemelt funkciócsoportok:

- központi Electron munkaállomás,
- Google OAuth auto-detection vezetői belépés,
- jogosultsági mátrix,
- árfolyamkészítés,
- árfolyam publikálás,
- országos készlet,
- értéktári leltár,
- zárás beérkezés,
- beérkezett adatok,
- napi ellenőrző lista,
- napi forgalom,
- MNB jelentések,
- banki rendelések,
- banki tranzakció riport,
- könyvelés export,
- compliance dashboard,
- szankciós lista,
- TRB/stornó audit,
- WU/ÁFA ellenőrzés,
- dolgozói nyilvántartás,
- jutalék beállítás,
- irodák és körzetek,
- ügyfél-ellenőrzés,
- dokumentumtár,
- rendőrségi megkeresések,
- körlevél,
- telepítő és verziófegyelem.

## Telepítő

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.45.exe
SHA256: A5588061B9E179A020B257861901B0E426D6FCCBE9CC7F9C385BE8E7B21CF613
Méret: 102509033 byte
```

## Ellenőrzés

- `npm --prefix frontend-react run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `npm run typecheck`
- `npm run package:kozponti`
- Dev renderer smoke test:
  `http://127.0.0.1:3020/central/sprint` -> HTTP 200, protected login redirect,
  no page runtime errors.
