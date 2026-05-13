---
title: 2026-05-12 helyi árfolyamkészítő architektúra
date: 2026-05-12
status: completed
---

# 2026-05-12 helyi árfolyamkészítő architektúra

## Döntés

A főértéktárosi árfolyamkészítés iránya módosult: nem a szerveren nyitott
szerkesztőként fut, hanem külön, helyileg telepíthető árfolyamkészítő
alkalmazásban. A szerver hitelesített átvevő, validáló, auditáló és terítő
központ.

## Megvalósított változások

- Új backend API:
  - `GET /api/v1/local-rate-maker/bootstrap`
  - `POST /api/v1/local-rate-maker/packages/publish`
- Új DTO-k:
  - `LocalRateMakerBootstrapDto`
  - `LocalRatePackageDto`
  - `LocalRatePublishResponseDto`
- A publikálás idempotens `IdempotencyGuard` használattal.
- `rate_publication` auditmezők:
  - `source`
  - `client_package_id`
  - `client_package_hash`
  - `client_version`
  - `client_device_id`
- Új Flyway migráció:
  - `V205__rate_publication_local_rate_maker_audit.sql`
- A JWT activeRole canonical szerepei Spring role-ként is authority-ba kerülnek:
  `foertektar -> ROLE_FOERTEKTAR`, `ugyvezeto -> ROLE_UGYVEZETO`, stb.
- A publikálásnál az irodaspecifikus árfolyam már nem deaktiválja a globális
  fallback árfolyamot.
- Külön helyi kliens kommunikációs csomag:
  - `arfolyam-keszito-client`
- Külön telepíthető Electron GUI:
  - `arfolyam-keszito-client/electron/main.ts`
  - `arfolyam-keszito-client/electron/preload.ts`
  - `arfolyam-keszito-client/electron/api-proxy.ts`
  - `arfolyam-keszito-client/electron-builder.json`
- A GUI-ban a Google Desktop OAuth engedélyezett:
  - `auth:google-oauth-flow`
  - `auth:google-oauth-flow-with-backend`
  - backend login `appMode=rate-maker`
- A GUI kezdő adatbetöltése a dedikált helyi árfolyamkészítő bootstrap végpont:
  - `GET /api/v1/local-rate-maker/bootstrap`
- Új app mód:
  - `rate-maker`
  - belépés: `foertektar`, `ugyvezeto`, `ADMIN`
- CLI:
  - `node dist-core/cli.js bootstrap`
  - `node dist-core/cli.js publish <rates.json>`

## Tesztek

- `npm --prefix arfolyam-keszito-client run typecheck` sikeres.
- `npm --prefix arfolyam-keszito-client run build` sikeres.
- `npm --prefix arfolyam-keszito-client run package:unsigned` sikeres.
- `npm run package:arfolyam-keszito` sikeres, telepítő:
  `arfolyam-keszito-client/release/Arfolyamkeszito-Setup-2.5.41.exe`
- `npm --prefix frontend-react run typecheck` sikeres.
- `npm --prefix frontend-react test -- exchange-rates` sikeres, 1/1 teszt.
- `npm --prefix frontend-react test -- appModeRoles.test.ts --run` sikeres, 8/8 teszt.
- `cd backend && .\mvnw.cmd "-Dtest=AppModeRoleConstantsTest,RatePublishServiceTest,ExchangeRateServiceTest" test` sikeres, 24/24 teszt.
- `npm run typecheck` sikeres.

## Dokumentáció

- `docs/architecture/local-rate-maker-architecture.md`
- `vault/feedback/local-rate-maker-architecture-decision.md`
- `vault/procedures/local-rate-maker-publication.md`

## Eredmény

Az árfolyamkészítő már telepíthető helyi Electron alkalmazásként épül. A
főértéktáros helyben rögzít, a szerver hitelesít, auditál, élesít és terít, a
pénztárak pedig a meglévő automatikus árfolyam-szinkronon olvasnak be.

2026-05-12 későbbi pontosítás: a helyi főértéktárosi app nem jelszavas
vezetői appként maradt, hanem megkapta ugyanazt a Google Desktop OAuth alapú
vezetői belépési utat, amelyet a pénztár kliensben már termelési irányként
használunk.
