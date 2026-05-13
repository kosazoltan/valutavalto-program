---
title: Telepítők kötelező kimenete és verziózása
date: 2026-05-12
status: active
trigger: "telepítő, installer, setup exe, csomagolás, package"
---

# Telepítők kötelező kimenete és verziózása

Felhasználói kötelező utasítás: minden elkészített telepítőt mindig át kell
másolni a felhasználó Letöltések mappájába is.

Felhasználói kötelező utasítás: minden új telepítőnek nagyobb verziószámot
kell kapnia, mint az előző elkészített telepítőnek. Telepítő build előtt a
releváns package-verziót és a lockfile-t is emelni kell. Ha közös frontend
kerül becsomagolásra, annak verzióját is hozzá kell igazítani, hogy a telepítő
és a becsomagolt alkalmazás azonos verziót mutasson.

Felhasználói kötelező utasítás: minden új telepítő elkészítése előtt ellenőrizni
kell, hogy a négy működési terület kommunikációs végpontjai és appMode
beállításai szinkronban vannak-e:

- pénztár,
- értéktár,
- RFM/árfolyamkészítő,
- központi irányítóközpont.

Kötelező parancs:

```text
npm run check:four-area-alignment
```

A három telepíthető kliens `package` és `package:unsigned` scriptje ezt
automatikusan futtatja a csomagolás előtt. Fontos: a pénztár és az értéktár
jelenleg egy közös lokális kliensben él külön `penztar` és `ertektar`
appMode-dal, ezért az ellenőrzés négy funkciót vizsgál, nem csak három `.exe`-t.
Ha az ellenőrzés hibát jelez, tilos telepítőt kiadni.

Kötelező célmappa:

```text
C:\Users\Kósa Zoltán\Downloads
```

Eljárás:

1. A build előtt ellenőrizni kell az aktuális verziót.
2. Le kell futtatni a négy terület végpont/appMode ellenőrzését.
3. Az új telepítő verziója csak nagyobb lehet az előzőnél.
4. A telepítőt a build saját release/output mappájában kell elkészíteni.
5. A kész `.exe` telepítőt át kell másolni a Downloads mappába.
6. A Downloads példány SHA256 hashét ellenőrizni kell az eredetihez képest.
7. A végső válaszban a Downloads útvonalat, verziót és hash-t kell megadni.
8. Ha azonos nevű telepítő már létezik, nem szabad vakon régi példányt
   elveszíteni; hash-azonosság esetén rendben, különben időbélyeges fájlnév
   használható.
9. Ha tévesen alacsonyabb verziójú próbakimenet készült ugyanabban a körben,
   azt nem szabad végleges telepítőként átadni; új verzióval újra kell buildelni.
