---
title: Központi irányítóközpont Electron app
date: 2026-05-12
status: implemented
version: 2.5.44
tags:
  - electron
  - kozponti-munkaallomas
  - legacy-modulok
  - installer
---

# Központi irányítóközpont Electron app

Felhasználói döntés: a legacy szerver mappában talált, központi/főértéktári/belső
ellenőri funkciókat nem a szerver asztalán futtatjuk. Egy külön helyi Electron
alkalmazás készült "Központi irányítóközpont" néven. Ez Google OAuth/JWT alapon
kommunikál a szerverrel, a szerver pedig megtartja az adatbázis, publikálás,
audit és jogosultsági döntések kontrollját.

## Elkészült kódszintű állapot

- Új Electron kliens: `kozponti-client`.
- Terméknév: `Valutavalto Kozponti Iranyitokozpont`.
- AppId: `com.bestchange.kozponti`.
- Renderer flavor: `VITE_APP_FLAVOR=central-workstation`.
- Fejlesztői port: `3020`.
- Alapértelmezett route: `/central-workstation`.
- App mode: `full`, mert ez a központi, vezetői és adminisztratív modulok helyi
  munkaállomása.
- Google OAuth, backend token login, secure token storage és API proxy a meglévő
  Electron minták szerint lett bekötve.

## Modulindító

Új oldal: `frontend-react/src/pages/central/CentralWorkstationPage.tsx`.

A felület nem legacy exe-ket futtat közvetlenül, hanem a modern modulokra mutató
irányítópult. A csoportosítás a `forrasok/SZERVER` audit és a DLL/EXE katalógus
alapján készült:

- Árfolyam és főértéktár: árfolyamkészítő, publikálás, országos készlet,
  értéktári leltár.
- Zárás és beérkezés: zárásfelügyelet, napi ellenőrző lista, beérkezett adatok,
  napi forgalom.
- MNB, bank és export: MNB jelentések, banki rendelések, banki tranzakció riport,
  könyvelési export.
- Audit/AML: compliance dashboard, szankciós lista, TRB/stornó audit, WU/ÁFA.
- Törzsadat és dolgozói admin: dolgozók, jutalék, irodák/körzetek,
  jogosultsági mátrix.
- Ügyfél/okmány/kommunikáció: ügyfél-ellenőrzés, dokumentumtár, rendőrségi
  megkeresések, körlevél.

## Build és ellenőrzés

Kötelező verziószabály rögzítve: új telepítő csak nagyobb verziószámmal készülhet.
A központi app és a kapcsolódó csomagok `2.5.42` verzióra lettek emelve.

Elkészült telepítő:

```text
D:\repo\valutavalto-program\kozponti-client\release\Kozponti-Iranyitokozpont-Setup-2.5.42.exe
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.42.exe
```

SHA256:

```text
421C0FC8B4211913D1E9F587E8FC736A4A8478C5519A5985CFD4F370B96A27EF
```

Futtatott ellenőrzések:

- `npm run package:kozponti`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`

Megjegyzés: a buildben maradt Vite chunk-size és ineffective dynamic import
figyelmeztetés, illetve Node `DEP0190` warning. Ezek nem állították meg a
csomagolást, de későbbi buildtisztítási feladatként kezelhetők.

## 2.5.43 fejlesztési lépés: zárás beérkezés felügyelet

Elkészült az első, árfolyamon túli központi legacy modul modernizálása:

- `zarasctrl.dll`
- `beerk.dll`
- `missctrl.dll`
- `daybook.fdb` hiányzó zárás logika

Új backend viselkedés:

- A `closing-control/status` válasz minden aktív irodát tartalmaz a kiválasztott
  napra.
- Ha még nincs `closing_control` sor, a backend nem hallgat, hanem
  `missingRecord=true` és számított `WARNING`/`CRITICAL` állapottal adja vissza.
- A lekérdezés és figyelmeztetésküldés cégen belül szűrt.

Új központi UI:

- `frontend-react/src/pages/central/ClosingControlPage.tsx`
- route: `/central/closing-control`
- menüpont: `Központ / Zárás beérkezés`
- központi launcher státusz: `ready`

Új telepítő:

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.43.exe
SHA256: 9D51AF39DA0F408CCB87553FB3B7A924315F5F8AED1483E5841AF888583AD5A9
```

Futtatott ellenőrzések:

- `npm run package:kozponti`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `cd backend; .\mvnw -Dtest=ClosingControlServiceTest test`

## 2.5.44 fejlesztési lépés: beérkezett adatok áttekintése

Elkészült a második, árfolyamon túli központi legacy modul modernizálása:

- `beerk.dll`
- `datadisp.dll`
- `getdisp.dll`
- `daybook.fdb` napi adatcsomag/beküldés áttekintés

Új backend:

- `CentralReceivedDataService`
- `CentralReceivedDataController`
- endpoint: `GET /api/v1/central/received-data/status?date=YYYY-MM-DD`
- DTO-k: `CentralReceivedDataOverviewDto`, `CentralReceivedDataRowDto`

Viselkedés:

- A kiválasztott napra minden aktív iroda megjelenik.
- Az API összefésüli az aktív irodákat, a napi jelentéseket és a
  záráskontrollt.
- Hiányzó napi jelentés nem tűnik el: explicit `MISSING`/`CRITICAL`/`WAITING`
  státuszt kap.
- A válasz összesítést ad: beérkezett, beküldött, hiányzó, warning/critical,
  tranzakciószám, vétel/eladás/díj/profit.

Új központi UI:

- `frontend-react/src/pages/central/ReceivedDataOverviewPage.tsx`
- route: `/central/received-data`
- menüpont: `Központ / Beérkezett adatok`
- központi launcher státusz: `ready`
- funkciók: dátumszűrés, keresés, státuszszűrés, CSV export, napi könyv drill-down.

Új telepítő:

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.44.exe
SHA256: 0B273FAF1A8CE69870D0B9DD65C6EF59CBBE21B94997E94570B5022A1FD8F056
```

Futtatott ellenőrzések:

- `npm run package:kozponti`
- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `cd backend; .\mvnw "-Dtest=CentralReceivedDataServiceTest,ClosingControlServiceTest" test`

## 2.5.45 fejlesztési lépés: központi sprint egyben

Elkészült a központi Electron programon belüli sprintnézet, amely az eddig
megalapított, szerver legacy auditból kijelölt központi funkciókat egy operatív
munkalistába helyezi.

Új központi UI:

- `frontend-react/src/pages/central/CentralSprintPage.tsx`
- route: `/central/sprint`
- menüpont: `Központ / Központi sprint`
- launcher csempe: `Sprint és irányítás / Központi sprint`

A sprintoldal tartalma:

- modul neve és munkaterülete,
- legacy DLL/EXE vagy adatforrás,
- modern célútvonal,
- sprintállapot: `kész`, `sprintben`, `következő`, `release`,
- prioritás: `P0`, `P1`, `P2`,
- üzleti kimenet.

Beemelt funkciócsoportok:

- központi Electron shell,
- Google OAuth vezetői belépés és szerepkör-szűrés,
- árfolyamkészítés és publikálás,
- zárás beérkezés,
- beérkezett adatok,
- MNB/bank/export,
- audit/AML/compliance,
- dolgozói és törzsadat admin,
- ügyfél, okmány, rendőrségi megkeresés és körlevél modulok.

Új telepítő:

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.45.exe
SHA256: A5588061B9E179A020B257861901B0E426D6FCCBE9CC7F9C385BE8E7B21CF613
```

Futtatott ellenőrzések:

- `npm --prefix frontend-react run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `npm run typecheck`
- `npm run package:kozponti`

## 2.5.47 fejlesztési lépés: három kliens funkcionális és telepítői összhangja

A Letöltések mappában eltérő verziójú és hiányos telepítők voltak. A kiadási
szabály szerint minden új telepítőnek nagyobb verziószámot kell kapnia, ezért
a teljes csomagkészlet `2.5.47` verzióra lett emelve.

Funkcionális összhangjavítás:

- A központi `full` appMode most a `teruleti_vezeto` és `biztonsagi_vezeto`
  szerepköröket is elfogadja, mert a központi helyi munkaállomásban nekik is
  dolgozniuk kell.
- A backend Google belépési validáció is ugyanígy számolja a módokat:
  `teruleti_vezeto` és `biztonsagi_vezeto` -> `kamera` + `full`.
- Az árfolyamkészítő továbbra is szűkített program: csak `foertektar`,
  `ugyvezeto`, illetve legacy `ADMIN` szerepkörrel használható.
- A központi menü `Országos készlet` pontja most ugyanarra a tényleges országos
  pénztári készletnézetre mutat, mint az irányítóközpont kártyája:
  `/cashier-stocks`.
- Az Electron setup típusdeklarációban a `full` appMode is szerepel, hogy a
  központi kliens és a típusok ne csússzanak szét.

Együttműködési modell:

- A pénztár kliens, az árfolyamkészítő és a központi irányítóközpont külön
  telepíthető asztali program.
- Mindhárom külön Windows app identity-t használ, ezért saját konfigurációval
  és token-tárolással fut.
- Mindhárom ugyanarra a központi szerver/API bázisra van kötve:
  `https://excvaluta.com/api/v1`.
- Nem egymással beszélnek közvetlenül; az adatáramlás közös szerveres:
  főértéktáros elkészíti és publikálja az árfolyamot, a pénztárak a szerveren
  keresztül olvassák be, a központi munkaállomás vezetői/ellenőrzési nézeteket
  kezel.

Elkészült telepítők:

```text
C:\Users\Kósa Zoltán\Downloads\Penztar-Setup-2.5.47.exe
SHA256: C602495CA8D9D38EDFB5DF9729AFC4F98539FB9257663DE4455B393F45CF5EBF

C:\Users\Kósa Zoltán\Downloads\Arfolyamkeszito-Setup-2.5.47.exe
SHA256: 4AFC802E045D07FA567F2518E4CE637750A692EF8476299E450E813325AB02FD

C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.47.exe
SHA256: 9D7CE24A47F06228C300E08D8C25AACEA475F3C1CF62B51CEDC54A49AF5B7862
```

Futtatott ellenőrzések:

- `npm run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `cd backend; .\mvnw '-Dtest=AppModeRoleConstantsTest,GoogleLoginServiceTest,RatePublishServiceTest' test`
- `npm --prefix penztar-client run package:unsigned`
- `npm run package:arfolyam-keszito`
- `npm run package:kozponti`

## 2.5.48 fejlesztési lépés: négy működési terület kapu és webes tartalék szerep

Felhasználói pontosítás:

- Nem három funkciót kell szinkronban tartani, hanem négy működési területet:
  pénztár, értéktár, RFM/árfolyamkészítő és központi.
- Három telepíthető kliens marad, de a pénztár és az értéktár egy közös lokális
  kliensből működik külön `penztar` és `ertektar` appMode-dal.

Megvalósítás:

- Új kötelező telepítő előtti kapu:
  `scripts/check-four-area-alignment.mjs`
- Új root parancs:
  `npm run check:four-area-alignment`
- A három kliens `package` és `package:unsigned` scriptje automatikusan futtatja
  ezt a kaput csomagolás előtt.
- A régi `check:three-client-endpoints` parancs kompatibilitási wrapperként
  megmaradt, de már a négyterületes ellenőrzést futtatja.
- A webes direkt szerverfelület tartalék szerepbe került UI-szinten:
  böngészős `full` módban a belépés és a `/` route a központi irányítóközpontba
  visz, és a layout figyelmeztető sávot mutat, hogy ez tartalék webes
  szerverfelület.

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
- Dev renderer smoke test:
  `http://127.0.0.1:3020/central/sprint` -> HTTP 200, protected login redirect,
  no page runtime errors.

## 2.5.46 fejlesztési lépés: központi szolgáltatások befejezési köre

A korábbi pontosítás után nem állítottuk felelőtlenül, hogy minden központi
szolgáltatás kész. Ebben a körben a maradék, sprintben/következő státuszú
központi modulok valós működési rései lettek lezárva.

Elkészült:

- `DailyChecklistPage` a tényleges backend DTO-ra lett igazítva.
- A checklist tétel frissítése most `{ checked, notes }` mezőkkel megy, így a
  backend ténylegesen kipipálja a pontokat.
- A napi checklist központi fiókválasztót és fiókonkénti státuszkártyákat kapott.
- `WesternUnionPage` központi fiókválasztót kapott, nem `localStorage`-ból
  próbál kizárólag branch-et olvasni.
- `CircularPage` újra lett kötve a valós backend endpointokra és DTO mezőkre.
- `Országos készlet` a központi launcherben a tényleges országos pénztári
  készletnézetre mutat: `/cashier-stocks`.
- A központi launcherben minden kijelölt legacy modul `ready`.
- A központi sprintnézetben minden kijelölt tétel `kész`.

Fontos értelmezés:

- A központi Electron szolgáltatásai alkalmazáson belül UI/API/build szinten
  implementálva és becsomagolva vannak.
- Külső éles integrációk tényleges üzemi bizonyítása továbbra is környezeti
  kérdés: szerveradat, jogosultság, credential, külső szolgáltató és adapter
  szükséges hozzá.

Új telepítő:

```text
C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.46.exe
SHA256: A6F63CE77D8F6151ED34644D20615EB2B906ABEF6420F2399089504A80C62EE8
```

Futtatott ellenőrzések:

- `npm --prefix frontend-react run typecheck`
- `npm --prefix frontend-react test -- appModeRoles menuGroups exchange-rates`
- `npm run typecheck`
- `npm run package:kozponti`
