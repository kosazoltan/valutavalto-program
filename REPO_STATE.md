# 📋 REPO STATE — Valutaváltó ERP
> Utoljára frissítve: 2026-03-08 | Commit: 9ea428b | Branch: main

## ⚡ GYORS ÖSSZEFOGLALÓ
- **Mi ez:** Valutaváltó ERP modernizáció (Delphi 7 → Java + React + Electron)
- **Stack:** Java 21 + Spring Boot 3.2 + PostgreSQL (Neon) / React 19 + TS + Electron
- **DB:** Neon PostgreSQL (ep-polished-morning-altxohe7, EU Central)
- **GitHub:** kosazoltan/valutavalto-program
- **Cég:** Exclusive Best Change Zrt. (~90 iroda, 4 cég)
- **Állapot:** ~98% Delphi lefedettség

## 📊 MÉRET
| Elem | Darab |
|------|-------|
| Java fájl | 876 |
| TSX fájl (frontend) | 143 |
| TS fájl (frontend+electron) | 3390 |
| Electron (pénztár) | 2070 |
| SQL migration | 8 (Flyway V1-V41+) |
| Commit | 106 |

## 🏗️ ARCHITEKTÚRA
```
backend/                        frontend-react/
├── src/main/java/             ├── src/
│   ├── controller/ (106)      │   ├── pages/
│   ├── entity/ (146)          │   ├── components/
│   ├── service/ (124+)        │   ├── services/
│   ├── dto/                   │   └── types/
│   ├── repository/            │
│   └── config/                penztar-client/ (Electron)
database/                      ├── src/
├── migrations/ (V1-V41)       │   ├── renderer/
└── *.sql                      │   └── main/
```

## 🔑 KRITIKUS PONTOK
1. **4 cég 1 rendszerben:** Best Change, Pannon Váltó, East Change, Expressz Zálog
2. **27 valutanem** + arany/ezüst
3. **MNB árfolyam kötelező** — törvényi hivatkozás szükséges
4. **Árfolyamváltozásnál nyomtatás KÖTELEZŐ** (törvényi előírás)
5. **Dekád = NAPTÁRI nap** (1-10, 11-20, 21-hónap vége), NEM nyitvatartási
6. **KKTG pénztár elkülönítés** — törvényi kötelezettség
7. **Dual package:** com.puzzleir + hu.puzzleir — figyelni import-okra
8. **Darius integráció NEM KELL** — külső rendszer (Raiffeisen)
9. **Neon DB:** ddl-auto=update (SOHA NE create!)
10. **SecurityUtils:** getCurrentWorkerCode() (NINCS getCurrentUsername)

## 🎯 FEJLESZTÉSI ÁLLAPOT
### Kész (98%) ✅
- Teljes ERP funkciók: napi nyitás/zárás, tranzakciók, mérleg
- Árfolyamkezelés (MNB→ECB→CACHED fallback)
- Felhasználó/jogosultság kezelés
- Riportok, nyomtatás
- 245+ teszt

### Hiányzó (~2%) ⚠️
- KKTG pénztár elkülönítés (12-16h)
- Átadólap bővítés (4-8h)
- Dekád naptári logika (2-4h)
- Szállítmány bővítés (8-12h)
- Validáció sprint (8-12h)
- **Összesen: 37-56 óra**

### NEM kell
- Western Union, Tesco/Metro (megszűnt partnerek)
- OTP terminál
- Darius integráció

## 📝 PARANCSSOR
```bash
# Backend
cd backend && mvn compile        # Compile check
cd backend && mvn test           # Tesztek
cd backend && mvn spring-boot:run # Futtatás

# Frontend
cd frontend-react && npm run dev # Dev
cd frontend-react && npm run build

# Electron
cd penztar-client && npm run dev
cd penztar-client && npm run build

# DB
# Flyway migration automatikus Spring Boot-ban
```

## 🔄 UTOLSÓ SESSION MUNKÁJA
- Árfolyam provider fallback lánc (MNB→ECB→CACHED)
- Sprint 4A-D: security hardening, kamera, árfolyam-kezelés, teszt javítások
- Gmail integráció Sprint 1+2 (külön repo: gmail-client)
- Teljes audit: 3 batch + 2 kör reaudit (134 fájl, +5505 sor)
