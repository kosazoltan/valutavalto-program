# Valutaváltó ERP v1.0.0

Modern valutaváltó / pénzváltó ERP rendszer — Spring Boot + React + Electron desktop klienssel.

## Alaptörvény — KOMPLEX ÖKOSZISZTÉMA

> **A Valutaváltó program egyetlen egységként működik.**
> TILOS csak a frontend-et, csak a backend-et vagy csak az Electron klienst külön megnyitni a normál működéshez.
> A dolgozók egy kattintással indítják az egész rendszert.

### Egységes indítás

```powershell
# Teljes stack (backend + frontend + Electron) egyben
powershell -ExecutionPolicy Bypass -File scripts\start-valuta-ecosystem.ps1

# Leállítás
powershell -ExecutionPolicy Bypass -File scripts\stop-valuta-ecosystem.ps1
```

### Mit indít el
1. **Helyi PostgreSQL** ellenőrzése (port 5432)
2. **Spring Boot backend** (port 8080)
3. **React webes admin** (port 3000) — főértéktár, audit, KPI, compliance
4. **Electron pénztáros kliens** — offline-képes GUI

A 3 komponens **együtt telepszik, együtt indul, együtt áll le**. Health check-ek biztosítják, hogy csak akkor tekinti készen a rendszert, amikor mindenki beszélget.

### Telepítő és Windows shortcut
A pénztáros munkaállomásokon egy **egyetlen asztali ikon** (Telepítő: `installer/build/Penztar-Setup-*.exe`) indítja az egész rendszert. Nincs külön "Backend.exe", "Frontend.exe" — a Telepítő egy szolgáltatást regisztrál (`ValutaEcosystem`) + egy Start menü shortcut.

### Debug célú részindítás (**CSAK FEJLESZTŐKNEK**)
Ha csak egy komponenst akarsz indítani (pl. Spring Boot backend tesztelésre):
```powershell
powershell -File scripts\start-valuta-ecosystem.ps1 -SkipElectron -SkipBackend
```
**Produkciós környezetben TILOS!**

---

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
┌──────────────────────────────────────────┐    REST API     ┌────────────────────────────┐
│    Electron Desktop    │─────────────────┼─┬    Spring Boot Backend ───┐
│  React 19 + TS + TW  │                │  Java 21 + PostgreSQL │
│  SQLite offline sync  │                │  56 Flyway migráció   │
└──────────────────────────────────────────┘                └────────────────────────────┘
         │                                         │
         │  Offline támogatás                      │  Több iroda
         │  ← SQL.js (böngészőbe)                  │  ← Branch management
         │  ← Sync engine                          │  ← Központi admin
         └─────────────────────────────────────────┘
```

**Főbb modulok:**
- 👥 **Dolgozói HR törzsadat** — 199 EBC munkatárs, személyi adatok, bér/adó, FEOR kódok, 9 szervezeti egység
- 👤 **Ügyfélkezelés bővítve** — személyi igazolvány + útlevél külön mezők, telefon, e-mail, 50 tesztügyfél
- 📦 **Tranzakciók** — vétel, eladás, sztornó, kezelési díjak
- 📊 **Árfolyam-kezelés** — MNB, egyedi, kategóriás, spread-számítás
- ⚖ **AML** — pénzmosás elleni kontroll (NAV előírások, göngyölés)
- 📆 **Napzárás** — 5 lépéses varázsló, címletezés, eltérés-kimutatás
- 📈 **Irodaközi kereskedés** — deviza trade irodák között
- 🙍 **Ügyfél-kezelés** — azonosítás, szankciós szűrés, PEP
- 📄 **Riportok** — napi, dekádos, havi, NAV, MNB jelentések
- 🖨️ **Nyomtatás** — bizonylatok, zárási riportok, sablonok
- ⚡ **Offline mód** — SQLite + sync engine Electron kliensben

## Pontos, aktuális értékek (2026-03-07):
- Flyway migrációk: **V1-V56 (56 db)**
- Backend kontrollerek: **113**
- Backend service-ek: **122**
- Entity-k: **165**
- Frontend oldalak: **51**
- Backend tesztek: **118 PASS** (JUnit 5)
- Frontend tesztek: 50 (vitest)
- Összesen: **168 teszt**
- TypeScript hibák: 0 ✅

## Docker + lokális teszt szekció
### Lokális fejlesztés Docker-rel
```bash
# PostgreSQL + pgAdmin indítás
docker-compose up -d

# Backend futtatás (test profillal, lokális DB)
cd backend
./mvnw spring-boot:run -Dspring-boot.run.profiles=test

# Frontend dev szerver
cd penztar-client
npm run dev
```

### MCP kovetelmenyek (Dockeres fejleszteshez)

- Lasd: [docs/MCP_DOCKER_REQUIREMENTS.md](docs/MCP_DOCKER_REQUIREMENTS.md)

## Projekt Struktúra

```
valutavalto-program/
├── backend/                      # Spring Boot backend
│   ├── src/main/java/            # Forráskód (113 controller, 122 service)
│   ├── src/main/resources/
│   └── db/migration/             # 56 Flyway migráció (V1-V56)
│   ├── src/test/java/            # JUnit tesztek
│   └── pom.xml                   # Maven konfig
├── penztar-client/               # React + Electron frontend
│   ├── src/
│   │   ├── pages/                # 51 oldal
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
└── database/                     # Extra migrációk
└── README.md                     # Ez a fájl
```

## Adatbázis

**Flyway migrációk:** V1-V56 (56 db)

## Tesztelés

### Backend (JUnit 5 + Mockito)

```bash
cd backend
./mvnw test
# Eredmény: 118 teszt, 0 hiba
```

**Teszt típusok:**
- Unit tesztek: service réteg (RateCalculation, Trade, Commission, Sanction, stb.)
- Integrációs tesztek: üzleti flow-k (Transaction, Closing, Trade, AML, Rate)
- Controller tesztek: REST API (@WebMvcTest)

### Frontend (Vitest 4 + Testing Library)

```bash
cd penztar-client
npx vitest run
# Eredmény: 50 teszt, 0 hiba
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

## UTF-8 hardening guardrail

- CI guardrail workflow: `.github/workflows/utf8-guardrail.yml`
- Opcionális pre-commit hook:

```bash
git config core.hooksPath .githooks
```

- Lokális ellenőrzés:

```bash
pwsh ./scripts/security/check-utf8-guardrail.ps1
```

- Diff alapú futtatás (PR/branch compare):

```bash
pwsh ./scripts/security/check-utf8-guardrail.ps1 -BaseRef <base-commit> -HeadRef HEAD
```

A check fail-el, ha nem UTF-8 dekódolható fájl vagy mojibake mintázat kerül a diffbe.

## Összesítő Statisztikák

| Metrika                  | Szám          |
| ------------------------ | ------------- |
| Backend kontrollerek     | 113           |
| Backend service-ek       | 122           |
| Flyway migrációk         | 56            |
| Frontend oldalak         | 51            |
| Frontend komponensek     | 9             |
| API modulok              | 14+           |
| Backend tesztek          | 118           |
| Frontend tesztek         | 50            |
| **Összes teszt**         | **168**       |
| TypeScript hibák         | 0             |

## Fejlesztők

Fejlesztette a PuzzleIR csapat — Junior AI (Claude Opus 4.6) koordinálásával.

## Licensz

MIT
