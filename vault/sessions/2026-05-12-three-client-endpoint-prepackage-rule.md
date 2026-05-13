---
title: Négy működési terület végpont-ellenőrzése telepítő előtt
date: 2026-05-12
status: completed
tags:
  - installer
  - endpoint-check
  - electron
  - release-rule
---

# Négy működési terület végpont-ellenőrzése telepítő előtt

Felhasználói kötelező utasítás:

- Minden új telepítő készítése előtt meg kell nézni, hogy a négy működési
  terület kommunikációs végpontjai és appMode beállításai szinkronban vannak-e.

Pontosított területek:

- pénztár,
- értéktár,
- RFM/árfolyamkészítő,
- központi.

Fontos értelmezés:

- Három telepíthető kliens van, de négy működési funkció.
- A pénztár és az értéktár jelenleg egy közös lokális kliensből működik,
  külön `penztar` és `ertektar` appMode-dal.

Megvalósítás:

- Új ellenőrző script:
  `scripts/check-four-area-alignment.mjs`
- A régi név kompatibilitási wrapperként megmaradt:
  `scripts/check-three-client-endpoints.mjs`
- Új root parancs:
  `npm run check:four-area-alignment`
- A három kliens `package` és `package:unsigned` scriptje automatikusan futtatja
  ezt az ellenőrzést a build/csomagolás előtt.

Az ellenőrzés vizsgálja:

- minden fő package verziója azonos-e,
- a production API végpont `https://excvaluta.com/api/v1`,
- a health végpont ebből következik-e,
- mindhárom Electron builder becsomagolja-e a `production-urls.json` fájlt,
- a három appId/productName/artifactName nem csúszott-e el,
- a pénztár setup-vezérelt `penztar` appMode átadása megmaradt-e,
- az értéktár setup-vezérelt `ertektar` appMode átadása megmaradt-e,
- az árfolyamkészítő fix `rate-maker` appMode-dal dolgozik-e,
- a központi irányítóközpont fix `full` appMode-dal dolgozik-e,
- a frontend build flavor nem keveredett-e össze.

Szabály:

- Ha ez a parancs hibát jelez, telepítő nem adható ki.
- Ha új telepítő készül, ez az ellenőrzés a verzióemelés és csomagolás előtti
  kötelező checklist része.
