# 📋 REPO STATE — Valutaváltó ERP
> Utoljára frissítve: 2026-03-08 | Commit: 9ea428b | Branch: main

## ⚡ GYORS ÖSSZEFOGLALÓ
- **Mi ez:** Valutaváltó ERP modernizáció (Delphi 7 → Java + React + Electron)
- **Stack:** Java 21 + Spring Boot 3.2 + PostgreSQL (Neon) / React 19 + TS + Electron
- **DB:** Neon PostgreSQL (ep-polished-morning-altxohe7, EU Central)
- **GitHub:** kosazoltan/valutavalto-program
- **Cég:** Exclusive Best Change Zrt. (~90 iroda, 4 cég)
- **Állapot:** Részben kész; több modul működik, de kritikus P0 területeken még vannak nyitott tételek (lásd docs/VALOS_ALLAPOT_JELENTES_2026-03-21.md)

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
8. **Darius/Raiffeisen scope:** üzleti döntés szerint kötelező napi riport modul, de a külső transport jelenleg részben kész (outbox artifact + státuszok, teljes adapter/E2E még nyitott)
9. **Neon DB:** ddl-auto=update (SOHA NE create!)
10. **SecurityUtils:** getCurrentWorkerCode() (NINCS getCurrentUsername)

## 🎯 FEJLESZTÉSI ÁLLAPOT
### Bizonyítottan működő fő elemek ✅
- Napi nyitás/zárás, tranzakciók, mérleg főfolyamatok
- Árfolyamkezelés (MNB→ECB→CACHED fallback)
- Felhasználó/jogosultság kezelés
- Riportok, nyomtatás
- 245+ teszt (historikus állapot, nem teljes regressziós garancia)

### Nyitott / részben kész elemek ⚠️
- KKTG pénztár elkülönítés
- Átadólap bővítés
- Dekád naptári logika
- Szállítmány bővítés
- Validáció sprint
- Darius külső transport + végponttól-végpontig üzleti bizonyítás
- Kamera evidence E2E bizonyítás (titkosítás/hash/transport lánc)

### Scope-ból kivett / nem cél
- Western Union, Tesco/Metro (megszűnt partnerek)
- OTP terminál

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

## ?? BE�P�TETT AI RENDSZER (17. t�rv�ny) � TERVEZETT
### Implement�land� (konz�lium sz�ks�ges)
1. **F��rt�kt�ros AI Asszisztens**
   - Term�szetes nyelv� lek�rdez�s: "Mai EUR forgalom irod�nk�nt" � SQL � t�bl�zat
   - Kimutat�s/riport gener�l�s tetsz�leges adatkombin�ci�b�l
   - �rfolyam javaslat: MNB + ECB + piaci trend � optim�lis elad�si/v�teli �r
   - Banki besz�ll�t�s/kisz�ll�t�s optimaliz�l�s (k�szlet + �rfolyam elemz�s)

2. **Adapt�v Import AI**
   - PDF/Excel/CSV felt�lt�s � AI �rtelmezi � megfelel� DB t�bla
   - Banki kivonatok automatikus feldolgoz�s
   - Sz�ll�t�levelek, bizonylatok import
   - Preview + j�v�hagy�s K�TELEZ�

3. **Napi Operat�v AI**
   - Napi nyit�s asszisztens (ellen�rz�lista, hi�nyz� adatok)
   - Elt�r�s detekt�l�s (p�nzt�r � m�rleg � riport)
   - Audit t�mogat�s (MNB/NAV megfelel�s�g ellen�rz�s)

### Modell strat�gia
- Haiku 4.5: Oszt�lyoz�s, egyszer� SQL, routing
- Sonnet 4.6: Elemz�s, javaslat, komplex lek�rdez�s, import

### Biztons�gi korl�tok
- Read-only SQL sandbox alap�rtelmezetten
- Mut�ci� � supervisor j�v�hagy�s
- Jogosults�g: munkak�r-alap� (p�nzt�ros/supervisor/manager/admin)
- Audit trail: minden AI m�velet napl�zva
