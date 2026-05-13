# Helyi főértéktárosi árfolyamkészítő architektúra

Állapot: elfogadott irány, 2026-05-12.

## Döntés

Az árfolyamot nem a szerveren kell szerkeszteni. A főértéktáros külön,
helyileg telepített árfolyamkészítő alkalmazásban állítja össze az
árfolyamcsomagot. A szerver szerepe:

- hitelesített átvétel,
- szerveroldali validáció,
- idempotens publikálás,
- audit trail,
- `exchange_rate` éles törzs frissítése,
- outbox/WebSocket alapú terítés,
- pénztári automatikus lekérés kiszolgálása.

Ez közelebb áll az örökölt `Arfolyam.exe` működéshez: helyi árfolyamkészítés,
központi kiküldés, pénztári automatikus beolvasás. A modern rendszerben a
bináris `ARFDATA/ujdata` fájlok helyét validált JSON csomag, idempotencia,
auditmezők és szerveroldali multi-tenant ellenőrzés veszi át.

## Új szerződés

Helyi árfolyamkészítő kliens:

- `GET /api/v1/local-rate-maker/bootstrap`
- `POST /api/v1/local-rate-maker/packages/publish`

A publikálás kötelezően `Idempotency-Key` fejléccel történik. A csomag
tartalmazza:

- `clientPackageId`
- `clientDeviceId`
- `clientVersion`
- `createdAt`
- `groupId`
- `clientPackageHash`
- árfolyamsorok

A szerver saját `serverPackageHash` értéket is képez és auditál. A pénztáraknak
nem kell új protokoll: továbbra is az aktuális árfolyamot olvassák:

- `GET /api/v1/exchange-rates/pos-current`

## Telepíthető kliens

2026-05-12-től az `arfolyam-keszito-client` már nem csak kommunikációs mag,
hanem külön Electron alkalmazás is.

- App mód: `rate-maker`
- Build flavor: `VITE_APP_FLAVOR=rate-maker`
- Elsődleges képernyő: `/rates/creation`
- Szerverkommunikáció: Electron main-process API proxy
- Belépés: Google Desktop OAuth RFC 8252/PKCE flow Electron main processből,
  majd backend `/auth/google-login` hívás `appMode=rate-maker` értékkel.
- Token tárolás: Electron `safeStorage` / Windows DPAPI
- Windows telepítő: `arfolyam-keszito-client/release/Arfolyamkeszito-Setup-2.5.41.exe`
- Bootstrap: a GUI közvetlenül a `GET /api/v1/local-rate-maker/bootstrap`
  végpontból tölti az árfolyam áttekintést és munkacsoportokat.
- Publikálási út: `POST /api/v1/local-rate-maker/packages/publish`

A normál szerveres web UI-ban az árfolyamkészítés nem elsődleges írási út. A
rate-maker build helyi csomagot képez (`clientPackageId`, `clientDeviceId`,
`clientVersion`, `clientPackageHash`) és idempotens publikálással küldi be.

## Biztonsági elvek

- Csak `FOERTEKTAR`, `UGYVEZETO`, `ADMIN` publikálhat helyi árfolyamcsomagot.
- A főértéktárosi/vezetői belépés Google email + dolgozói törzs alapján történik;
  pénztári jelszavas belépés ettől függetlenül megmaradhat a pénztár appban.
- A JWT activeRole canonical szerepei Spring `ROLE_*` authority-ként is
  megjelennek.
- Azonos `clientPackageId` cégszinten csak egyszer fogadható el.
- Retry esetén az idempotencia payload-hash-hez kötött.
- A szerver nem deaktivál globális fallback árfolyamot egy irodaspecifikus
  publikálás miatt.
- Az irodaspecifikus árfolyam elsőbbséget élvez a globális fallbackkel szemben.

## Érintett fő komponensek

- Backend API: `LocalRateMakerController`
- Backend DTO-k: `dto/ratemaker/*`
- Publikálás: `RateCreationService`, `RatePublishService`
- Audit: `RatePublication`
- DB migráció: `V205__rate_publication_local_rate_maker_audit.sql`
- Helyi kliens kommunikációs mag: `arfolyam-keszito-client`
- Helyi kliens Electron shell: `arfolyam-keszito-client/electron/*`
- Helyi kliens CLI: `arfolyam-keszito-client/src/cli.ts`
- Frontend app mód: `frontend-react/src/types/appMode.ts`
- Pénztári beolvasás: `penztar-client/electron/sync-engine.ts`
