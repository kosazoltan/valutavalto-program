---
title: 2026-05-12 árfolyamkészítő telepítő build
date: 2026-05-12
status: completed
---

# 2026-05-12 árfolyamkészítő telepítő build

## Döntés

Az árfolyamkészítő kliensben történt változások telepítőértékűek:

- Google Desktop OAuth belépés bekerült a külön `rate-maker` Electron appba.
- A kezdő árfolyam/munkacsoport adatbetöltés a dedikált
  `/api/v1/local-rate-maker/bootstrap` végpontra került.
- A publikálás továbbra is a helyi csomagos, idempotens
  `/api/v1/local-rate-maker/packages/publish` szerződést használja.

## Build

Parancs:

```powershell
npm run package:arfolyam-keszito
```

Eredmény:

- Telepítő: `D:\repo\valutavalto-program\arfolyam-keszito-client\release\Arfolyamkeszito-Setup-2.5.41.exe`
- Készült: `2026-05-12 17:33:47 +02:00`
- Méret: `102501777` byte
- SHA256: `0890176841D8D1142C1FAED1FEC8E16366E43064E533AF6198061C7900134562`
- Letöltések mappába másolt példány:
  `C:\Users\Kósa Zoltán\Downloads\Arfolyamkeszito-Setup-2.5.41.exe`

## Megjegyzés

Ez az aktuális főértéktárosi helyi árfolyamkészítő telepítő. A szerver nem
árfolyamszerkesztőként működik, hanem hitelesített átvételi, validációs,
audit- és terítési pontként.

## Kötelező telepítő-szabály

Felhasználói utasítás, kötelező érvényű: minden jövőben elkészített telepítőt
mindig át kell másolni a gépen a Letöltések mappába is:
`C:\Users\Kósa Zoltán\Downloads`.

Ha ugyanazon a néven már van telepítő, nem szabad vakon elveszíteni a régi
példányt; vagy ellenőrizni kell az azonosságot hash-sel, vagy időbélyeges
fájlnévvel kell új példányt adni.
