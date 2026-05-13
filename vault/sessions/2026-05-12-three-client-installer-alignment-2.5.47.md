---
title: Three client installer and function alignment 2.5.47
date: 2026-05-12
status: completed
tags:
  - installer
  - electron
  - central-workstation
  - rate-maker
  - cashier
  - google-oauth
---

# Három kliens összhangba hozása, 2.5.47

Kiinduló probléma:

- A Letöltések mappában csak részleges telepítőcsomag volt.
- A központi irányítóközpont `2.5.46`, az árfolyamkészítő `2.5.41`, a pénztár
  pedig régebbi/eltérő nevű csomagként volt jelen.
- A felhasználói szabály szerint minden új telepítőnek magasabb verziószámot
  kell kapnia és a Letöltések mappába kell kerülnie.

Eldöntött működés:

- Három külön telepíthető Electron program marad:
  pénztár kliens, árfolyamkészítő, központi irányítóközpont.
- Ezek nem közvetlenül egymással beszélnek, hanem a központi szerveren/API-n
  keresztül működnek együtt.
- A főértéktáros helyi árfolyamkészítőben készíti az árfolyamot, majd publikálja
  a szerverre.
- A pénztárak a szerverről olvassák be az aktuális publikált árfolyamot.
- A központi irányítóközpont vezetői, ellenőrzési és főértéktári modulokat ad.

Kijavított funkcionális eltérések:

- `frontend-react/src/utils/appModeRoles.ts`: a `full` mód elfogadja a
  `teruleti_vezeto` és `biztonsagi_vezeto` szerepkört.
- `backend/src/main/java/hu/puzzleir/valuta/util/AppModeRoleConstants.java`:
  a backend is `kamera` + `full` módot számol ezekre a vezetői role-okra.
- `backend/src/test/java/hu/puzzleir/valuta/service/GoogleLoginServiceTest.java`:
  a Google belépési tesztek az új központi munkaállomás szabályt rögzítik.
- `frontend-react/src/layouts/menuGroups.ts`: a központi menü `Országos készlet`
  pontja `/cashier-stocks` útvonalra mutat.
- `frontend-react/src/types/electron.d.ts`: az Electron setup appMode típusba
  bekerült a `full`.

Elkészült Downloads telepítők:

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

Felelős állítás:

- Kódszinten és buildszinten a három kliens egységes `2.5.47` verzión van,
  ugyanarra a production API-ra épül, és szerepkör/appMode szűrése össze van
  hangolva.
- Az éles üzemi adatáramlás végső bizonyítása továbbra is telepített
  környezetben, valós Google jogosultsággal, szerverrel és fiókadatokkal
  végezhető el.
