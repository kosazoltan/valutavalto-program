# Pénztár Kliens — Architektúra Terv
**Dátum:** 2026-03-05
**Státusz:** AKTÍV FEJLESZTÉS

---

## 1. Áttekintés

Az eredeti Delphi 7 pénztár alkalmazás (ibvalto.exe + 123 DLL) modern Electron asztali alkalmazásra cserélése.

### Meglévő komponensek (NEM VÁLTOZNAK)
- **Backend:** Spring Boot 3.2 + Java 21 (332 fájl, 55 controller, ~200 endpoint)
- **Admin UI:** React + TypeScript + Vite + Tailwind (120 fájl, értéktár/compliance)
- **DB séma:** PostgreSQL 66 tábla (company, branch, worker, currency, exchange_rate, transaction, stb.)

### Új komponens
- **Pénztár kliens:** Electron + React + TypeScript + Vite
  - Fut: Windows 10/11 fióki gépeken
  - Offline: SQLite lokális gyorsítótár (better-sqlite3)
  - Online: REST API → Java backend (PostgreSQL)
  - Mód: konfigurálható (pénztár / értéktár)

---

## 2. Technológiai Stack

```
┌─────────────────────────────────────────────┐
│            ELECTRON SHELL                    │
│  ┌───────────────────────────────────────┐  │
│  │        React + TypeScript (Vite)      │  │
│  │  ┌────────────┐  ┌────────────────┐   │  │
│  │  │ Pénztár UI │  │  Értéktár UI   │   │  │
│  │  └────────────┘  └────────────────┘   │  │
│  │         ▼                ▼            │  │
│  │  ┌────────────────────────────────┐   │  │
│  │  │    API Service Layer           │   │  │
│  │  │  (REST → Spring Boot backend)  │   │  │
│  │  └────────────────────────────────┘   │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │  Main Process (Node.js)               │  │
│  │  - SQLite offline cache               │  │
│  │  - Sync engine                        │  │
│  │  - Receipt printer (ESC/POS)          │  │
│  │  - Auto-updater                       │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
           │
           ▼ REST API (HTTPS)
┌─────────────────────────────────────────────┐
│  Spring Boot 3.2 Backend (Java 21)          │
│  - 55 Controller, ~200 endpoint             │
│  - PostgreSQL (Render Frankfurt)             │
│  - JWT authentication                        │
│  - Business logic + AML/KYC                  │
└─────────────────────────────────────────────┘
```

---

## 3. Pénztár Kliens Képernyők (Delphi → Electron)

### Prioritás 1 — Core (napi munka)
| # | Képernyő | Delphi modul | Backend API | Méret |
|---|----------|-------------|-------------|-------|
| 1 | Bejelentkezés | PROSBE | POST /auth/login | Kicsi |
| 2 | Nap nyitás | NAPIKEZD | POST /daily-sessions/open | Közepes |
| 3 | **Deviza eladás** | ELADAS (134KB) | POST /transactions/sell | NAGY |
| 4 | **Deviza vásárlás** | VASARLAS (102KB) | POST /transactions/buy | NAGY |
| 5 | Ügyfél kezelés | UGYFEL (111KB) | GET/POST /customers | NAGY |
| 6 | Címletezés | CIMLET (33KB) | GET/PUT /denominations | Közepes |
| 7 | Készlet áttekintés | PILLKESZ (64KB) | GET /cash-balances | Közepes |
| 8 | Napzárás | NAPZAR (44KB) | POST /closing-wizard | NAGY |
| 9 | Bizonylat nyomtatás | BLOKNYOM (57KB) | GET /receipts/{id}/print | Közepes |

### Prioritás 2 — Kiegészítő
| # | Képernyő | Delphi modul | Backend API |
|---|----------|-------------|-------------|
| 10 | Stornó | STORNO (35KB) | POST /stornos |
| 11 | Átadás-átvétel | ATADVET (135KB) | POST /transfers |
| 12 | Foglalás | FOGLALO (81KB) | POST /reservations |
| 13 | Kezelési díj | KEZDIJ (31KB) | GET /fees |
| 14 | Körlevél | KORLEV (26KB) | GET /circulars |
| 15 | Árfolyam kijelzés | ARFDISP (43KB) | GET /exchange-rate-display |
| 16 | Napi jelentés | NAPIJEL (43KB) | GET /reports/daily |

### Prioritás 3 — Speciális
| # | Képernyő | Delphi modul | Backend API |
|---|----------|-------------|-------------|
| 17 | QR-kód | QRGENER (21KB) | POST /nav-integration/send-qr-code |
| 18 | NAV integráció | NAVZARO (25KB) | POST /nav-integration |
| 19 | Terrorizmus szűrés | TERROR (8KB) | GET /blacklist |
| 20 | Havi zárás | HAVIZAR (56KB) | POST /closing/monthly |
| 21 | HRK kezelés | HRKATADO (29KB) | POST /inventory/bank-* |

---

## 4. Projekt Struktúra

```
valutavalto-program/
├── backend/                     # [MEGVAN] Spring Boot 3.2
├── frontend-react/              # [MEGVAN] Admin UI (React)
├── database/                    # [MEGVAN] PostgreSQL séma
├── penztar-client/              # [ÚJ] Electron pénztár kliens
│   ├── electron/
│   │   ├── main.ts             # Electron main process
│   │   ├── preload.ts          # Bridge renderer ↔ main
│   │   ├── sqlite.ts           # SQLite offline DB
│   │   ├── sync.ts             # Szinkronizáció engine
│   │   └── printer.ts          # ESC/POS nyomtató
│   ├── src/
│   │   ├── App.tsx
│   │   ├── main.tsx
│   │   ├── api/
│   │   │   ├── client.ts       # Axios HTTP kliens
│   │   │   ├── auth.ts         # JWT kezelés
│   │   │   ├── transactions.ts # Eladás/vásárlás API
│   │   │   ├── customers.ts    # Ügyfél API
│   │   │   ├── rates.ts        # Árfolyam API
│   │   │   ├── cash.ts         # Készlet API
│   │   │   ├── sessions.ts     # Napi nyitás/zárás
│   │   │   └── sync.ts         # Offline szinkron
│   │   ├── pages/
│   │   │   ├── LoginPage.tsx
│   │   │   ├── MainMenu.tsx
│   │   │   ├── SellPage.tsx       # Deviza eladás
│   │   │   ├── BuyPage.tsx        # Deviza vásárlás
│   │   │   ├── CustomerPage.tsx   # Ügyfél kezelés
│   │   │   ├── DenomPage.tsx      # Címletezés
│   │   │   ├── StockPage.tsx      # Készlet
│   │   │   ├── ClosingPage.tsx    # Napzárás
│   │   │   ├── TransferPage.tsx   # Átadás-átvétel
│   │   │   ├── StornoPage.tsx     # Stornó
│   │   │   └── SettingsPage.tsx   # Beállítások
│   │   ├── components/
│   │   │   ├── CurrencySelector.tsx
│   │   │   ├── AmountInput.tsx
│   │   │   ├── CustomerSearch.tsx
│   │   │   ├── DenomGrid.tsx
│   │   │   ├── RateDisplay.tsx
│   │   │   ├── Receipt.tsx
│   │   │   └── HotkeyBar.tsx
│   │   ├── stores/
│   │   │   ├── authStore.ts
│   │   │   ├── rateStore.ts
│   │   │   ├── cashStore.ts
│   │   │   └── sessionStore.ts
│   │   └── utils/
│   │       ├── rounding.ts      # Magyar kerekítés (0-2→le, 3-7→5, 8-9→10)
│   │       ├── receipt.ts       # Bizonylat szám generálás
│   │       └── validation.ts    # AML limitek
│   ├── package.json
│   ├── electron-builder.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   └── index.html
├── forrasok/                    # [REFERENCIA] Eredeti Delphi 7 forrás
└── docs/                        # Dokumentáció
```

---

## 5. Offline Stratégia

```
ONLINE mód (normál):
  Minden API hívás → Spring Boot backend → PostgreSQL
  SQLite = cache (gyorsabb UX)

OFFLINE mód (internet kiesés):
  API hívás FAIL → SQLite lokálisan tárolja a tranzakciót
  Státusz: "PENDING_SYNC"
  Amikor internet visszajön → Sync engine elküldi a backend-nek
  
Mindig lokálisan cachelt adatok:
  - Árfolyamok (utolsó frissítés + timestamp)
  - Valutanemek + címletek
  - Ügyféltörzs (kereséshez)
  - Nyitó készlet
```

---

## 6. Magyar Kerekítés (HUF)

A Delphi ATADVET modulból:
```
0-2  → lefelé kerekít (pl. 1001-1002 → 1000)
3-7  → 5-re kerekít (pl. 1003-1007 → 1005)
8-9  → felfelé 10-re kerekít (pl. 1008-1009 → 1010)
```

---

## 7. 27 Valutanem (hardcoded a Delphi-ben, DB-ből jön az újban)

AUD, BAM, BGN, BRL, CAD, CHF, CNY, CZK, DKK, EUR, GBP, HRK, HUF, ILS, JPY, MXN, NOK, NZD, PLN, RON, RSD, RUB, SEK, THB, TRY, UAH, USD

---

## 8. Bizonylat Számozás

A Delphi UTOLSOBLOKKOK táblából:
- Eladás: `E-YYMMDD-XXXX`
- Vásárlás: `V-YYMMDD-XXXX`
- Átadás: `A-YYMMDD-XXXX`
- Stornó: `S-YYMMDD-XXXX`

---

## 9. Cégek (Multi-tenant)

| Kód | Pénztár | Cégnév | Adószám |
|-----|---------|--------|---------|
| <151 | Best Change | EXCLUSIVE BEST CHANGE ZRT | 32313332-2-02 |
| ≥151 | Expressz | EXPRESSZ ÉKSZERHÁZ ÉS MINIBANK KFT | 14040535-2-02 |
