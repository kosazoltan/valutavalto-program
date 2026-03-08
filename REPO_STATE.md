# ğŸ“‹ REPO STATE â€” ValutavÃ¡ltÃ³ ERP
> UtoljÃ¡ra frissÃ­tve: 2026-03-08 | Commit: 9ea428b | Branch: main

## âš¡ GYORS Ã–SSZEFOGLALÃ“
- **Mi ez:** ValutavÃ¡ltÃ³ ERP modernizÃ¡ciÃ³ (Delphi 7 â†’ Java + React + Electron)
- **Stack:** Java 21 + Spring Boot 3.2 + PostgreSQL (Neon) / React 19 + TS + Electron
- **DB:** Neon PostgreSQL (ep-polished-morning-altxohe7, EU Central)
- **GitHub:** kosazoltan/valutavalto-program
- **CÃ©g:** Exclusive Best Change Zrt. (~90 iroda, 4 cÃ©g)
- **Ãllapot:** ~98% Delphi lefedettsÃ©g

## ğŸ“Š MÃ‰RET
| Elem | Darab |
|------|-------|
| Java fÃ¡jl | 876 |
| TSX fÃ¡jl (frontend) | 143 |
| TS fÃ¡jl (frontend+electron) | 3390 |
| Electron (pÃ©nztÃ¡r) | 2070 |
| SQL migration | 8 (Flyway V1-V41+) |
| Commit | 106 |

## ğŸ—ï¸ ARCHITEKTÃšRA
```
backend/                        frontend-react/
â”œâ”€â”€ src/main/java/             â”œâ”€â”€ src/
â”‚   â”œâ”€â”€ controller/ (106)      â”‚   â”œâ”€â”€ pages/
â”‚   â”œâ”€â”€ entity/ (146)          â”‚   â”œâ”€â”€ components/
â”‚   â”œâ”€â”€ service/ (124+)        â”‚   â”œâ”€â”€ services/
â”‚   â”œâ”€â”€ dto/                   â”‚   â””â”€â”€ types/
â”‚   â”œâ”€â”€ repository/            â”‚
â”‚   â””â”€â”€ config/                penztar-client/ (Electron)
database/                      â”œâ”€â”€ src/
â”œâ”€â”€ migrations/ (V1-V41)       â”‚   â”œâ”€â”€ renderer/
â””â”€â”€ *.sql                      â”‚   â””â”€â”€ main/
```

## ğŸ”‘ KRITIKUS PONTOK
1. **4 cÃ©g 1 rendszerben:** Best Change, Pannon VÃ¡ltÃ³, East Change, Expressz ZÃ¡log
2. **27 valutanem** + arany/ezÃ¼st
3. **MNB Ã¡rfolyam kÃ¶telezÅ‘** â€” tÃ¶rvÃ©nyi hivatkozÃ¡s szÃ¼ksÃ©ges
4. **ÃrfolyamvÃ¡ltozÃ¡snÃ¡l nyomtatÃ¡s KÃ–TELEZÅ** (tÃ¶rvÃ©nyi elÅ‘Ã­rÃ¡s)
5. **DekÃ¡d = NAPTÃRI nap** (1-10, 11-20, 21-hÃ³nap vÃ©ge), NEM nyitvatartÃ¡si
6. **KKTG pÃ©nztÃ¡r elkÃ¼lÃ¶nÃ­tÃ©s** â€” tÃ¶rvÃ©nyi kÃ¶telezettsÃ©g
7. **Dual package:** com.puzzleir + hu.puzzleir â€” figyelni import-okra
8. **Darius integrÃ¡ciÃ³ NEM KELL** â€” kÃ¼lsÅ‘ rendszer (Raiffeisen)
9. **Neon DB:** ddl-auto=update (SOHA NE create!)
10. **SecurityUtils:** getCurrentWorkerCode() (NINCS getCurrentUsername)

## ğŸ¯ FEJLESZTÃ‰SI ÃLLAPOT
### KÃ©sz (98%) âœ…
- Teljes ERP funkciÃ³k: napi nyitÃ¡s/zÃ¡rÃ¡s, tranzakciÃ³k, mÃ©rleg
- ÃrfolyamkezelÃ©s (MNBâ†’ECBâ†’CACHED fallback)
- FelhasznÃ¡lÃ³/jogosultsÃ¡g kezelÃ©s
- Riportok, nyomtatÃ¡s
- 245+ teszt

### HiÃ¡nyzÃ³ (~2%) âš ï¸
- KKTG pÃ©nztÃ¡r elkÃ¼lÃ¶nÃ­tÃ©s (12-16h)
- ÃtadÃ³lap bÅ‘vÃ­tÃ©s (4-8h)
- DekÃ¡d naptÃ¡ri logika (2-4h)
- SzÃ¡llÃ­tmÃ¡ny bÅ‘vÃ­tÃ©s (8-12h)
- ValidÃ¡ciÃ³ sprint (8-12h)
- **Ã–sszesen: 37-56 Ã³ra**

### NEM kell
- Western Union, Tesco/Metro (megszÅ±nt partnerek)
- OTP terminÃ¡l
- Darius integrÃ¡ciÃ³

## ğŸ“ PARANCSSOR
```bash
# Backend
cd backend && mvn compile        # Compile check
cd backend && mvn test           # Tesztek
cd backend && mvn spring-boot:run # FuttatÃ¡s

# Frontend
cd frontend-react && npm run dev # Dev
cd frontend-react && npm run build

# Electron
cd penztar-client && npm run dev
cd penztar-client && npm run build

# DB
# Flyway migration automatikus Spring Boot-ban
```

## ğŸ”„ UTOLSÃ“ SESSION MUNKÃJA
- Ãrfolyam provider fallback lÃ¡nc (MNBâ†’ECBâ†’CACHED)
- Sprint 4A-D: security hardening, kamera, Ã¡rfolyam-kezelÃ©s, teszt javÃ­tÃ¡sok
- Gmail integrÃ¡ciÃ³ Sprint 1+2 (kÃ¼lÃ¶n repo: gmail-client)
- Teljes audit: 3 batch + 2 kÃ¶r reaudit (134 fÃ¡jl, +5505 sor)

## ?? BEÉPÍTETT AI RENDSZER (17. törvény) — TERVEZETT
### Implementálandó (konzílium szükséges)
1. **Fõértéktáros AI Asszisztens**
   - Természetes nyelvû lekérdezés: "Mai EUR forgalom irodánként" › SQL › táblázat
   - Kimutatás/riport generálás tetszõleges adatkombinációból
   - Árfolyam javaslat: MNB + ECB + piaci trend › optimális eladási/vételi ár
   - Banki beszállítás/kiszállítás optimalizálás (készlet + árfolyam elemzés)

2. **Adaptív Import AI**
   - PDF/Excel/CSV feltöltés › AI értelmezi › megfelelõ DB tábla
   - Banki kivonatok automatikus feldolgozás
   - Szállítólevelek, bizonylatok import
   - Preview + jóváhagyás KÖTELEZÕ

3. **Napi Operatív AI**
   - Napi nyitás asszisztens (ellenõrzõlista, hiányzó adatok)
   - Eltérés detektálás (pénztár › mérleg › riport)
   - Audit támogatás (MNB/NAV megfelelõség ellenõrzés)

### Modell stratégia
- Haiku 4.5: Osztályozás, egyszerû SQL, routing
- Sonnet 4.6: Elemzés, javaslat, komplex lekérdezés, import

### Biztonsági korlátok
- Read-only SQL sandbox alapértelmezetten
- Mutáció › supervisor jóváhagyás
- Jogosultság: munkakör-alapú (pénztáros/supervisor/manager/admin)
- Audit trail: minden AI mûvelet naplózva
