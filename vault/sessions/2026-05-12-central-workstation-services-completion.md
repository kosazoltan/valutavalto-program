---
title: Központi Electron szolgáltatások befejezési kör
date: 2026-05-12
status: implemented
version: 2.5.46
tags:
  - kozponti-munkaallomas
  - legacy-modulok
  - szolgaltatasok
  - installer
---

# Központi Electron szolgáltatások befejezési kör

Felhasználói döntés: a központi Electronban kijelölt összes, korábban
megalapított szolgáltatást végig kell vinni, nem elég sprintlistába tenni.

## Készre húzott részek

- Napi ellenőrző lista:
  - backend DTO szerződéshez igazítva,
  - `{ checked, notes }` requesttel működik,
  - központi fiókválasztóval és fiókonkénti státusznézettel bővítve.
- Western Union:
  - központi fiókválasztóval működik,
  - nem `localStorage`-ból függ kizárólagosan.
- Körlevelek:
  - a valós backend endpointokra átírva,
  - a valós DTO mezőket használja,
  - létrehozás, lista, típus szerinti nézet, nyugtázás, archiválás működési
    útvonala egységesítve.
- Országos készlet:
  - a launcher route a tényleges országos pénztári készlet oldalra mutat:
    `/cashier-stocks`.
- Központi launcher:
  - minden kijelölt legacy modul `ready`.
- Központi sprint:
  - minden kijelölt tétel `kész`.

## Határ

Felelős állítás:

- UI/API/build szinten a központi Electron szolgáltatásai implementálva és
  becsomagolva vannak.

Nem állítható ebből automatikusan:

- hogy minden külső harmadik félhez kapcsolódó integráció éles üzemi
  környezetben bizonyított, mert ehhez szerveradat, jogosultság, credential,
  adapter és szolgáltatói elérés kell.

## Telepítő

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.46.exe
SHA256: A6F63CE77D8F6151ED34644D20615EB2B906ABEF6420F2399089504A80C62EE8
Méret: 102509901 byte
```

## Ellenőrzés

- `npm --prefix frontend-react run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `npm run typecheck`
- `npm run package:kozponti`
