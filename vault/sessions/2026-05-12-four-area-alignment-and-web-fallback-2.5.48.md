---
title: Four-area alignment and web fallback hardening 2.5.48
date: 2026-05-12
status: completed
tags:
  - installer
  - electron
  - app-mode
  - web-fallback
  - release-rule
---

# Négy működési terület és webes tartalék mód, 2.5.48

Felhasználói pontosítás:

- A telepítő előtti ellenőrzésnek nem három funkciót, hanem négy működési
  területet kell összhangban tartania:
  pénztár, értéktár, RFM/árfolyamkészítő és központi.

Fontos értelmezés:

- Három telepíthető kliens van.
- Négy működési funkció van.
- A pénztár és az értéktár jelenleg egy közös lokális kliensből fut, külön
  `penztar` és `ertektar` appMode-dal.

Megvalósított kapu:

- `scripts/check-four-area-alignment.mjs`
- `npm run check:four-area-alignment`
- A három telepíthető kliens csomagolása előtt automatikusan lefut.
- A régi `check-three-client-endpoints.mjs` wrapperként maradt meg.

Ellenőrzött területek:

- pénztár: `penztar`, `/cashier`
- értéktár: `ertektar`, `/treasury`
- RFM/árfolyamkészítő: `rate-maker`, `/rates/creation`
- központi: `full`, `/central-workstation`

Webes tartalék mód:

- A direkt böngészős szerverfelület nem elsődleges munkafelület.
- Böngészős `full` módban a gyökérútvonal és a belépés utáni alapútvonal a
  központi irányítóközpont: `/central-workstation`.
- A `MainLayout` tartalék webes szerverfelület figyelmeztető sávot mutat, ha a
  rendszer nem Electronban, hanem böngészőben fut.

Elkészült telepítők:

```text
C:\Users\Kósa Zoltán\Downloads\Penztar-Setup-2.5.48.exe
SHA256: 53C8BA6887772D3699D66F9A9152AF03CDF819C6DA2A3D5C93EBBD1CB54AD430

C:\Users\Kósa Zoltán\Downloads\Arfolyamkeszito-Setup-2.5.48.exe
SHA256: 8178408E46C60915EE49DD85C1A3ADA0888403D0C19AF2BEC99BC6947D9617E7

C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.48.exe
SHA256: DC2A03659EC09A9BC197B44241284F4F443BF9A94E0AD8460CB96995CC712714
```

Futtatott ellenőrzések:

- `npm run check:four-area-alignment`
- `npm run check:three-client-endpoints`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates useAppMode`
- `npm --prefix penztar-client run package:unsigned`
- `npm run package:arfolyam-keszito`
- `npm run package:kozponti`
