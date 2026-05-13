---
title: Helyi árfolyamkészítő publikálási eljárás
date: 2026-05-12
status: active
trigger: "Árfolyamkészítő, főértéktáros, árfolyam publikálás, pénztári automatikus beolvasás"
---

# Helyi árfolyamkészítő publikálási eljárás

## Cél

A főértéktáros helyi alkalmazásban készíti el az árfolyamot. A szerver csak
átveszi, ellenőrzi, auditálja, élesíti és kiküldi a pénztáraknak.

## Lépések

1. Főértéktáros elindítja a telepített Electron árfolyamkészítőt:
   `arfolyam-keszito-client/release/Arfolyamkeszito-Setup-2.5.41.exe`
2. Az alkalmazás `rate-maker` app módban, Google Desktop OAuth-fal jelentkeztet
   be. Beléphet: `foertektar`, `ugyvezeto`, `ADMIN`.
3. Helyi kliens bootstrap:
   `GET /api/v1/local-rate-maker/bootstrap`
4. Helyi árfolyamcsomag összeállítása:
   `clientPackageId`, `clientDeviceId`, `clientVersion`, `groupId`, `rates`
5. Helyi kliens validáció és hash:
   Electron GUI-ban a rate-maker build, CLI-ben `buildRatePackage()`
6. Publikálás:
   `POST /api/v1/local-rate-maker/packages/publish`
   kötelező `Idempotency-Key` fejléccel
7. Szerver validáció:
   jogosultság, tenant, munkacsoport, árfolyamértékek, ismételt csomag
8. Szerver élesítés:
   `RateTemplate` -> `RatePublishService` -> `exchange_rate`
9. Terítés:
   `SyncOutboxEvent RATE_PUBLISHED`
10. Pénztár automatikus beolvasás:
   `/exchange-rates/pos-current` polling és lokális `cached_rates`

## Ellenőrzés

- Backend célzott teszt:
  `cd backend && .\mvnw.cmd "-Dtest=RatePublishServiceTest,ExchangeRateServiceTest" test`
- Helyi kliens típusellenőrzés:
  `npm --prefix arfolyam-keszito-client run typecheck`
- Frontend típusellenőrzés:
  `npm --prefix frontend-react run typecheck`
- Telepítő build:
  `npm run package:arfolyam-keszito`
- Frontend bootstrap regressziós teszt:
  `npm --prefix frontend-react test -- exchange-rates`

## Tiltott visszacsúszás

Ne legyen elsődleges működés az, hogy a főértéktáros szerveroldali admin UI-ban
készíti az árfolyamot. A szerveres UI legfeljebb monitor, fallback vagy
üzemeltetési felület lehet; az üzleti alapfolyamat a helyi kliens.
