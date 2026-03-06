# Valutaváltó ERP v2.0

Modern valutaváltó / pénzváltó ERP rendszer — Spring Boot + React + Electron desktop klienssel.

## Tech Stack

| Layer     | Technológia                                                |
| --------- | ---------------------------------------------------------- |
| Backend   | **Java 21**, Spring Boot 3.2, Spring Security, Spring Data JPA |
| Frontend  | **React 19**, TypeScript 5.7, Tailwind CSS 3, Zustand 5   |
| Desktop   | **Electron 33**, Vite 6, electron-builder                  |
| Adatbázis | **PostgreSQL** (szerver), **SQLite** (offline kliens)      |
| Tesztelés | JUnit 5, Mockito, Vitest 4, Testing Library                |
| Build     | Maven (backend), npm / Vite (frontend)                     |

## Architektúra

```
┌──────────────────────┐    REST API     ┌───────────────────────┐
│   Electron Desktop   │◄──────────────►│   Spring Boot Backend │
│  React 19 + TS + TW  │                │  Java 21 + PostgreSQL │
│  SQLite offline sync  │                │  35 Flyway migráció   │
└──────────────────────┘                └───────────────────────┘
         │                                         │
         │  Offline támogatás                      │  Több iroda
         │  ← SQL.js (böngészőbe)                  │  ← Branch management
         │  ← Sync engine                          │  ← Központi admin
         └─────────────────────────────────────────┘
```

**Főbb modulok:**
- 🏦 **Tranzakciók** — vétel, eladás, sztornó, kezelési díjak
- 📊 **Árfolyam-kezelés** — MNB, egyedi, kategóriás, spread-számítás
- 🔒 **AML** — pénzmosás elleni kontroll (NAV előírások, göngyölés)
- 🌙 **Napzárás** — 5 lépéses varázsló, címletezés, eltérés-kimutatás
- 🔄 **Irodaközi kereskedés** — deviza trade irodák között
- 👥 **Ügyfél-kezelés** — azonosítás, szankciós szűrés, PEP
- 📑 **Riportok** — napi, dekádos, havi, NAV, MNB jelentések
- 🖨️ **Nyomtatás** — bizonylatok, zárási riportok, sablonok
- ⚡ **Offline mód** — SQLite + sync engine Electron kliensben

## Quick Start

### Backend

```bash
cd backend

# Java 21 szükséges (pl. Eclipse Adoptium)
export JAVA_HOME="/path/to/jdk-21"

# Futtatás (dev profillal, beépített H2-vel)
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev

# Vagy: csak build
./mvnw clean package -DskipTests
```

### Frontend (dev mód)

```bash
cd penztar-client

npm install
npm run dev          # Vite dev server → http://localhost:5173
```

### Electron (desktop)

```bash
cd penztar-client

npm install
npm run electron:dev   # Electron + Vite HMR
npm run build          # Production build + Electron csomagolás
```

## API Endpointok (főbb)

| Metódus  | Endpoint                               | Leírás                              |
| -------- | -------------------------------------- | ----------------------------------- |
| `POST`   | `/api/auth/login`                      | Bejelentkezés                       |
| `POST`   | `/api/auth/logout`                     | Kijelentkezés                       |
| `GET`    | `/api/dashboard`                       | Dashboard adatok                    |
| `GET`    | `/api/currencies`                      | Valuták listája                     |
| `GET`    | `/api/exchange-rates`                  | Aktuális árfolyamok                 |
| `PUT`    | `/api/exchange-rates/{id}`             | Árfolyam módosítás                  |
| `POST`   | `/api/rate-approvals`                  | Árfolyam-jóváhagyás kérés          |
| `GET`    | `/api/rate-history`                    | Árfolyam előzmények                 |
| `POST`   | `/api/transactions/sell`               | Eladás                              |
| `POST`   | `/api/transactions/buy`                | Vétel                               |
| `GET`    | `/api/transactions`                    | Tranzakció lista                    |
| `GET`    | `/api/transactions/{id}`              | Tranzakció részletek                |
| `POST`   | `/api/storno/check`                    | Sztornó ellenőrzés                  |
| `POST`   | `/api/storno/execute`                  | Sztornó végrehajtás                 |
| `GET`    | `/api/customers`                       | Ügyfelek listája                    |
| `POST`   | `/api/customers`                       | Ügyfél létrehozás                   |
| `GET`    | `/api/aml/check`                       | AML ellenőrzés                      |
| `GET`    | `/api/aml/pending`                     | Függő AML bejelentések              |
| `POST`   | `/api/aml/report`                      | AML bejelentés                      |
| `POST`   | `/api/closing-wizard/start`            | Napzárás indítás                    |
| `GET`    | `/api/closing-wizard/{id}`             | Varázsló állapot                    |
| `POST`   | `/api/closing-wizard/{id}/navigate`    | Varázsló navigáció                  |
| `POST`   | `/api/closing-wizard/{id}/complete`    | Napzárás befejezés                  |
| `GET`    | `/api/cash-balance`                    | Kassza egyenleg                     |
| `GET`    | `/api/denominations`                   | Címlet készlet                      |
| `GET`    | `/api/daily-sessions`                  | Napi munkamenetek                   |
| `POST`   | `/api/daily-sessions/open`             | Munkamenet nyitás                   |
| `POST`   | `/api/daily-sessions/close`            | Munkamenet zárás                    |
| `GET`    | `/api/trades`                          | Irodaközi trade-ek                  |
| `POST`   | `/api/trades/propose`                  | Trade ajánlat                       |
| `POST`   | `/api/trades/{id}/accept`              | Trade elfogadás                     |
| `POST`   | `/api/trades/{id}/reject`              | Trade elutasítás                    |
| `GET`    | `/api/receipts/search`                 | Bizonylat keresés                   |
| `POST`   | `/api/receipts/{id}/print`             | Bizonylat nyomtatás                 |
| `GET`    | `/api/reports/daily`                   | Napi riport                         |
| `GET`    | `/api/reports/decade`                  | Dekádos riport                      |
| `GET`    | `/api/reports/monthly`                 | Havi riport                         |
| `GET`    | `/api/sanctions/screen`                | Szankciós szűrés                    |
| `GET`    | `/api/audit-log`                       | Audit napló                         |
| `GET`    | `/api/workers`                         | Dolgozók listája                    |
| `GET`    | `/api/branches`                        | Irodák listája                      |
| `GET`    | `/api/commissions`                     | Jutalék számítás                    |
| `GET`    | `/api/calculator/convert`              | Árfolyam kalkulátor                 |
| `GET`    | `/api/inventory`                       | Készlet kimutatás                   |
| `GET`    | `/api/health`                          | Health check                        |
| `POST`   | `/api/sync/push`                       | Offline szinkronizáció              |

> Összesen **99 REST controller** — teljes MNB/NAV integráció, backup, licensz, nyomtatás.

## Adatbázis

- **35 Flyway migráció** (V1–V35)
- Főbb táblák: `transaction`, `currency`, `exchange_rate`, `cash_balance`, `customer`, `worker`, `branch`, `daily_session`, `closing_wizard`, `trade`, `audit_log`, `sanction_list`, `denomination`
- PostgreSQL (éles), H2 (teszt)

## Tesztelés

### Backend (JUnit 5 + Mockito)

```bash
cd backend
./mvnw test
# Eredmény: 131 teszt, 0 hiba
```

**Teszt típusok:**
- Unit tesztek: service réteg (RateCalculation, Trade, Commission, Sanction, stb.)
- Integrációs tesztek: üzleti flow-k (Transaction, Closing, Trade, AML, Rate)
- Controller tesztek: REST API (@WebMvcTest)

### Frontend (Vitest 4 + Testing Library)

```bash
cd penztar-client
npx vitest run
# Eredmény: 50 teszt, 10 fájl, 0 hiba
```

**Teszt típusok:**
- Komponens tesztek: ErrorBoundary, Toast rendszer
- Page tesztek: Login, Dashboard, MainMenu, Closing, Calculator, AuditLog, Trade
- API modul tesztek: 14 API modul importálhatóság
- Hook tesztek: useToast

### TypeScript ellenőrzés

```bash
cd penztar-client
npx tsc --noEmit
# Eredmény: 0 hiba
```

## Projekt Struktúra

```
valutavalto-program/
├── backend/                      # Spring Boot backend
│   ├── src/main/java/            # Forráskód (99 controller, 40+ service)
│   ├── src/main/resources/
│   │   └── db/migration/         # 35 Flyway migráció (V1-V35)
│   ├── src/test/java/            # JUnit tesztek
│   └── pom.xml                   # Maven konfig
├── penztar-client/               # React + Electron frontend
│   ├── src/
│   │   ├── pages/                # 42 oldal
│   │   ├── components/           # 9 közös komponens
│   │   ├── api/                  # API kliensek
│   │   ├── stores/               # Zustand store-ok
│   │   ├── hooks/                # Custom React hook-ok
│   │   └── test/                 # Teszt konfig & API tesztek
│   ├── electron/                 # Electron main process
│   │   ├── main.ts               # App belépési pont
│   │   ├── preload.ts            # IPC bridge
│   │   ├── printer.ts            # Nyomtatás
│   │   ├── sqlite.ts             # Offline SQLite
│   │   ├── sync-engine.ts        # Szinkronizáció
│   │   └── updater.ts            # Auto-update
│   ├── package.json
│   ├── tsconfig.json
│   └── vitest.config.ts
├── database/                     # Extra migrációk
└── README.md                     # Ez a fájl
```

## Összesítő Statisztikák

| Metrika                  | Szám          |
| ------------------------ | ------------- |
| Backend kontrollerek     | 99            |
| Backend service-ek       | 40+           |
| Flyway migrációk         | 35            |
| Frontend oldalak         | 42            |
| Frontend komponensek     | 9             |
| API modulok              | 14+           |
| Backend tesztek          | 131           |
| Frontend tesztek         | 50            |
| **Összes teszt**         | **181**       |
| TypeScript hibák         | 0             |

## Fejlesztők

Fejlesztette a PuzzleIR csapat.

## Licensz

MIT
