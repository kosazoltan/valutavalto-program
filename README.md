# ValutavĂˇltĂł ERP v2.0

Modern valutavĂˇltĂł / pĂ©nzvĂˇltĂł ERP rendszer â€" Spring Boot + React + Electron desktop klienssel.

## Tech Stack

| Layer     | TechnolĂłgia                                                |
| --------- | ---------------------------------------------------------- |
| Backend   | **Java 21**, Spring Boot 3.2, Spring Security, Spring Data JPA |
| Frontend  | **React 19**, TypeScript 5.7, Tailwind CSS 3, Zustand 5   |
| Desktop   | **Electron 33**, Vite 6, electron-builder                  |
| AdatbĂˇzis | **PostgreSQL** (szerver), **SQLite** (offline kliens)      |
| TesztelĂ©s | JUnit 5, Mockito, Vitest 4, Testing Library                |
| Build     | Maven (backend), npm / Vite (frontend)                     |

## ArchitektĂşra

```
â"Śâ"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"    REST API     â"Śâ"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"
â"'   Electron Desktop   â"'â-"â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â-şâ"'   Spring Boot Backend â"'
â"'  React 19 + TS + TW  â"'                â"'  Java 21 + PostgreSQL â"'
â"'  SQLite offline sync  â"'                â"'  48 Flyway migrĂˇciĂł   â"'
â""â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"                â""â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"
         â"'                                         â"'
         â"'  Offline tĂˇmogatĂˇs                      â"'  TĂ¶bb iroda
         â"'  â† SQL.js (bĂ¶ngĂ©szĹ'be)                  â"'  â† Branch management
         â"'  â† Sync engine                          â"'  â† KĂ¶zponti admin
         â""â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"€â"
```

**FĹ'bb modulok:**
- đźŹ¦ **TranzakciĂłk** â€" vĂ©tel, eladĂˇs, sztornĂł, kezelĂ©si dĂ­jak
- đź"Š **Ărfolyam-kezelĂ©s** â€" MNB, egyedi, kategĂłriĂˇs, spread-szĂˇmĂ­tĂˇs
- đź"' **AML** â€" pĂ©nzmosĂˇs elleni kontroll (NAV elĹ'Ă­rĂˇsok, gĂ¶ngyĂ¶lĂ©s)
- đźŚ™ **NapzĂˇrĂˇs** â€" 5 lĂ©pĂ©ses varĂˇzslĂł, cĂ­mletezĂ©s, eltĂ©rĂ©s-kimutatĂˇs
- đź"" **IrodakĂ¶zi kereskedĂ©s** â€" deviza trade irodĂˇk kĂ¶zĂ¶tt
- đź'Ą **ĂśgyfĂ©l-kezelĂ©s** â€" azonosĂ­tĂˇs, szankciĂłs szĹ±rĂ©s, PEP
- đź"' **Riportok** â€" napi, dekĂˇdos, havi, NAV, MNB jelentĂ©sek
- đź-¨ď¸Ź **NyomtatĂˇs** â€" bizonylatok, zĂˇrĂˇsi riportok, sablonok
- âšˇ **Offline mĂłd** â€" SQLite + sync engine Electron kliensben

## Quick Start

### Backend

```bash
cd backend

# Java 21 szĂĽksĂ©ges (pl. Eclipse Adoptium)
export JAVA_HOME="/path/to/jdk-21"

# FuttatĂˇs (dev profillal, beĂ©pĂ­tett H2-vel)
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# Vagy: csak build
./mvnw clean package -DskipTests
```

### Frontend (dev mĂłd)

```bash
cd penztar-client

npm install
npm run dev          # Vite dev server â†' http://localhost:5173
```

### Electron (desktop)

```bash
cd penztar-client

npm install
npm run electron:dev   # Electron + Vite HMR
npm run build          # Production build + Electron csomagolĂˇs
```

## API Endpointok (fĹ'bb)

| MetĂłdus  | Endpoint                               | LeĂ­rĂˇs                              |
| -------- | -------------------------------------- | ----------------------------------- |
| `POST`   | `/api/auth/login`                      | BejelentkezĂ©s                       |
| `POST`   | `/api/auth/logout`                     | KijelentkezĂ©s                       |
| `GET`    | `/api/dashboard`                       | Dashboard adatok                    |
| `GET`    | `/api/currencies`                      | ValutĂˇk listĂˇja                     |
| `GET`    | `/api/exchange-rates`                  | AktuĂˇlis Ăˇrfolyamok                 |
| `PUT`    | `/api/exchange-rates/{id}`             | Ărfolyam mĂłdosĂ­tĂˇs                  |
| `POST`   | `/api/rate-approvals`                  | Ărfolyam-jĂłvĂˇhagyĂˇs kĂ©rĂ©s          |
| `GET`    | `/api/rate-history`                    | Ărfolyam elĹ'zmĂ©nyek                 |
| `POST`   | `/api/transactions/sell`               | EladĂˇs                              |
| `POST`   | `/api/transactions/buy`                | VĂ©tel                               |
| `GET`    | `/api/transactions`                    | TranzakciĂł lista                    |
| `GET`    | `/api/transactions/{id}`              | TranzakciĂł rĂ©szletek                |
| `POST`   | `/api/storno/check`                    | SztornĂł ellenĹ'rzĂ©s                  |
| `POST`   | `/api/storno/execute`                  | SztornĂł vĂ©grehajtĂˇs                 |
| `GET`    | `/api/customers`                       | Ăśgyfelek listĂˇja                    |
| `POST`   | `/api/customers`                       | ĂśgyfĂ©l lĂ©trehozĂˇs                   |
| `GET`    | `/api/aml/check`                       | AML ellenĹ'rzĂ©s                      |
| `GET`    | `/api/aml/pending`                     | FĂĽggĹ' AML bejelentĂ©sek              |
| `POST`   | `/api/aml/report`                      | AML bejelentĂ©s                      |
| `POST`   | `/api/closing-wizard/start`            | NapzĂˇrĂˇs indĂ­tĂˇs                    |
| `GET`    | `/api/closing-wizard/{id}`             | VarĂˇzslĂł Ăˇllapot                    |
| `POST`   | `/api/closing-wizard/{id}/navigate`    | VarĂˇzslĂł navigĂˇciĂł                  |
| `POST`   | `/api/closing-wizard/{id}/complete`    | NapzĂˇrĂˇs befejezĂ©s                  |
| `GET`    | `/api/cash-balance`                    | Kassza egyenleg                     |
| `GET`    | `/api/denominations`                   | CĂ­mlet kĂ©szlet                      |
| `GET`    | `/api/daily-sessions`                  | Napi munkamenetek                   |
| `POST`   | `/api/daily-sessions/open`             | Munkamenet nyitĂˇs                   |
| `POST`   | `/api/daily-sessions/close`            | Munkamenet zĂˇrĂˇs                    |
| `GET`    | `/api/trades`                          | IrodakĂ¶zi trade-ek                  |
| `POST`   | `/api/trades/propose`                  | Trade ajĂˇnlat                       |
| `POST`   | `/api/trades/{id}/accept`              | Trade elfogadĂˇs                     |
| `POST`   | `/api/trades/{id}/reject`              | Trade elutasĂ­tĂˇs                    |
| `GET`    | `/api/receipts/search`                 | Bizonylat keresĂ©s                   |
| `POST`   | `/api/receipts/{id}/print`             | Bizonylat nyomtatĂˇs                 |
| `GET`    | `/api/reports/daily`                   | Napi riport                         |
| `GET`    | `/api/reports/decade`                  | DekĂˇdos riport                      |
| `GET`    | `/api/reports/monthly`                 | Havi riport                         |
| `GET`    | `/api/sanctions/screen`                | SzankciĂłs szĹ±rĂ©s                    |
| `GET`    | `/api/audit-log`                       | Audit naplĂł                         |
| `GET`    | `/api/workers`                         | DolgozĂłk listĂˇja                    |
| `GET`    | `/api/branches`                        | IrodĂˇk listĂˇja                      |
| `GET`    | `/api/commissions`                     | JutalĂ©k szĂˇmĂ­tĂˇs                    |
| `GET`    | `/api/calculator/convert`              | Ărfolyam kalkulĂˇtor                 |
| `GET`    | `/api/inventory`                       | KĂ©szlet kimutatĂˇs                   |
| `GET`    | `/api/health`                          | Health check                        |
| `POST`   | `/api/sync/push`                       | Offline szinkronizĂˇciĂł              |

> Ă-sszesen **99 REST controller** â€" teljes MNB/NAV integrĂˇciĂł, backup, licensz, nyomtatĂˇs.

## AdatbĂˇzis

- **48 Flyway migrĂˇciĂł** (V1â€"V35)
- FĹ'bb tĂˇblĂˇk: `transaction`, `currency`, `exchange_rate`, `cash_balance`, `customer`, `worker`, `branch`, `daily_session`, `closing_wizard`, `trade`, `audit_log`, `sanction_list`, `denomination`
- PostgreSQL (Ă©les), H2 (teszt)

## TesztelĂ©s

### Backend (JUnit 5 + Mockito)

```bash
cd backend
./mvnw test
# EredmĂ©ny: 131 teszt, 0 hiba
```

**Teszt tĂ­pusok:**
- Unit tesztek: service rĂ©teg (RateCalculation, Trade, Commission, Sanction, stb.)
- IntegrĂˇciĂłs tesztek: ĂĽzleti flow-k (Transaction, Closing, Trade, AML, Rate)
- Controller tesztek: REST API (@WebMvcTest)

### Frontend (Vitest 4 + Testing Library)

```bash
cd penztar-client
npx vitest run
# EredmĂ©ny: 50 teszt, 10 fĂˇjl, 0 hiba
```

**Teszt tĂ­pusok:**
- Komponens tesztek: ErrorBoundary, Toast rendszer
- Page tesztek: Login, Dashboard, MainMenu, Closing, Calculator, AuditLog, Trade
- API modul tesztek: 14 API modul importĂˇlhatĂłsĂˇg
- Hook tesztek: useToast

### TypeScript ellenĹ'rzĂ©s

```bash
cd penztar-client
npx tsc --noEmit
# EredmĂ©ny: 0 hiba
```

## Projekt StruktĂşra

```
valutavalto-program/
â"śâ"€â"€ backend/                      # Spring Boot backend
â"'   â"śâ"€â"€ src/main/java/            # ForrĂˇskĂłd (99 controller, 40+ service)
â"'   â"śâ"€â"€ src/main/resources/
â"'   â"'   â""â"€â"€ db/migration/         # 48 Flyway migrĂˇciĂł (V1-V48)
â"'   â"śâ"€â"€ src/test/java/            # JUnit tesztek
â"'   â""â"€â"€ pom.xml                   # Maven konfig
â"śâ"€â"€ penztar-client/               # React + Electron frontend
â"'   â"śâ"€â"€ src/
â"'   â"'   â"śâ"€â"€ pages/                # 42 oldal
â"'   â"'   â"śâ"€â"€ components/           # 9 kĂ¶zĂ¶s komponens
â"'   â"'   â"śâ"€â"€ api/                  # API kliensek
â"'   â"'   â"śâ"€â"€ stores/               # Zustand store-ok
â"'   â"'   â"śâ"€â"€ hooks/                # Custom React hook-ok
â"'   â"'   â""â"€â"€ test/                 # Teszt konfig & API tesztek
â"'   â"śâ"€â"€ electron/                 # Electron main process
â"'   â"'   â"śâ"€â"€ main.ts               # App belĂ©pĂ©si pont
â"'   â"'   â"śâ"€â"€ preload.ts            # IPC bridge
â"'   â"'   â"śâ"€â"€ printer.ts            # NyomtatĂˇs
â"'   â"'   â"śâ"€â"€ sqlite.ts             # Offline SQLite
â"'   â"'   â"śâ"€â"€ sync-engine.ts        # SzinkronizĂˇciĂł
â"'   â"'   â""â"€â"€ updater.ts            # Auto-update
â"'   â"śâ"€â"€ package.json
â"'   â"śâ"€â"€ tsconfig.json
â"'   â""â"€â"€ vitest.config.ts
â"śâ"€â"€ database/                     # Extra migrĂˇciĂłk
â""â"€â"€ README.md                     # Ez a fĂˇjl
```

## Ă-sszesĂ­tĹ' StatisztikĂˇk

| Metrika                  | SzĂˇm          |
| ------------------------ | ------------- |
| Backend kontrollerek     | 99            |
| Backend service-ek       | 40+           |
| Flyway migrĂˇciĂłk         | 35            |
| Frontend oldalak         | 42            |
| Frontend komponensek     | 9             |
| API modulok              | 14+           |
| Backend tesztek          | 131           |
| Frontend tesztek         | 50            |
| **Ă-sszes teszt**         | **181**       |
| TypeScript hibĂˇk         | 0             |

## Sprint 3 (2026-03-06) — Hiánypótlás

A teljes Delphi→Modern audit alapján az összes rövid és középtávú hiány pótolva:

| Modul | Leírás | Legacy |
|---|---|---|
| HandlingFeeService | Sávos + ezrelékes kezelési díj + auto kedvezmény | GetKezelesidij |
| SealNumber | Plomba szám generálás ({branch}-{date}-{seq}) | GETPLOMB |
| BreakPage | Szünet mód — teljes képernyős overlay, PIN, supervisor override | PAUSDISP |
| ConversionPage | Valuta→valuta konverzió, cross-rate | ARFVALT |
| DiscountThreshold | Automatikus kedvezmény/felár 500K+/10K- küszöbök | BIGARFVALT/KISARFVALT |
| DenominationCalculator | Címlet kalkulátor — greedy + készlet-figyelő | KELLCIM |
| CustomerType | Egyszerűsített ügyfél (300K Ft alatt) | KISUGYFEL |
| CircularType | 17 körlevél típus + célcsoport + prioritás + iktatószám | KORLEV DLL |
| HrkMonthlyClosing | HRK havi zárás — valutánkénti összesítés | HRKZARO |
| LED Driver | 19 driver típus absztrakció (RS-232/LAN/Virtual) | METRO/TRUELIGHT/TOPICA DLL-ek |
| WU/OTP/TWAIN Stub | Partner API placeholderek (501 Not Implemented) | WUNION, OTP terminal |

**Flyway migrációk:** V42-V48 (7 új)
**Unit tesztek:** +17 új teszt metódus (HandlingFee, Denomination, SealNumber)

## Fejlesztők

Fejlesztette a PuzzleIR csapat — Junior AI (Claude Opus 4.6) koordinálásával.

## Licensz

MIT

