# Valutaváltó Program - Teljes Körű Rendszer

## 🏗️ Projekt Struktúra

```
valutavalto-program/
├── backend/                  # Spring Boot 3.2 + Java 21 REST API
├── frontend-flutter/         # Pénztáros kliens (Windows/Linux Desktop)
├── frontend-react/           # Admin UI (Értéktár, Fő értéktár, Compliance)
├── docker/                   # Docker Compose fájlok (pénztár gép)
├── scripts/                  # Automatizálási scriptek (backup, migráció)
├── database/                 # SQL schema, migrációk
│   └── migrations/
├── docs/                     # Dokumentáció, API specifikáció
└── .env.example              # Példa environment változók
```

---

## 🚀 Gyors Kezdés (Fejlesztőknek)

### **1. Előfeltételek**

- **Java 21** (Spring Boot backend)
- **Node.js 20+** (React admin UI, archíválás script)
- **Flutter 3.16+** (Desktop kliens)
- **PostgreSQL 16 kliens** (psql parancs - helyi fejlesztéshez)
- **Docker Desktop** (opcionális - pénztár gép szimuláció)

### **2. Klónozás és környezet setup**

```powershell
# Git repo klónozás
git clone https://github.com/kosazoltan/valutavalto-program.git
cd valutavalto-program

# Environment változók másolás
Copy-Item .env.example .env

# FONTOS: Szerkeszd a .env fájlt!
# - RENDER_DB_URL → Render Dashboard-ról másold
# - JWT_SECRET → Generálj erős random string-et
# - Többi változó egyelőre maradhat placeholder
notepad .env
```

### **3. Render PostgreSQL Connection String beszerzése**

1. Menj: https://dashboard.render.com
2. Válaszd: `valuta-production` database
3. Info tab → **Internal Database URL** másolása
4. Másold be a `.env` fájl `RENDER_DB_URL` változójába

**Példa:**
```
RENDER_DB_URL=postgresql://valuta_user:abc123xyz@dpg-ct4nq8l9q8jc739xxxxxx.frankfurt-postgres.render.com/valuta_production
```

---

## 📊 Adatbázis Setup

### **Schema import Render PostgreSQL-be**

```powershell
# PostgreSQL kliens telepítés (ha nincs még)
choco install postgresql16 --params '/Port:5433'

# Render adatbázis kapcsolat teszt
$env:RENDER_DB_URL = "postgresql://..."  # .env-ből másold
psql $env:RENDER_DB_URL -c "SELECT version();"

# Schema import (valuta_data.sql módosított verzió)
psql $env:RENDER_DB_URL -f database\migrations\001_initial_schema.sql

# pgcrypto extension engedélyezés (titkosításhoz)
psql $env:RENDER_DB_URL -c "CREATE EXTENSION IF NOT EXISTS pgcrypto;"
```

---

## 🏢 Architektúra Áttekintés

### **3-szintű Hierarchia:**

```
┌─────────────────────────────────────────────────────────────┐
│ FŐ ÉRTÉKTÁR (React Admin)                                   │
│ - Árfolyam készítés (konkurencia + bank árfolyam)          │
│ - Kedvezmény beállítás (pénztáranként)                     │
│ - 9‰ tranzakciós illeték (ezrelékes OR sávos)              │
└──────────────────────┬──────────────────────────────────────┘
                       ↓ (árfolyamok publikálás)
┌─────────────────────────────────────────────────────────────┐
│ ÉRTÉKTÁR (React Admin)                                       │
│ - Pénztárak ellátása (forint/valuta csomag)                │
│ - Bank kapcsolat (valuta ki/be, forint ki/be)              │
│ - Western Union, MoneyGram, Exclusive Cash                  │
└──────────────────────┬──────────────────────────────────────┘
                       ↓ (csomag küldés "úton lévő")
┌─────────────────────────────────────────────────────────────┐
│ PÉNZTÁR (Flutter Desktop + Lokális PostgreSQL)              │
│ - Tranzakció rögzítés (vásárlás/eladás)                    │
│ - Készlet monitorozás                                       │
│ - Auto-sync: 5-10 perc OR 10 tranzakció → Render           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ COMPLIANCE OFFICER (React Admin)                            │
│ - MNB AML/terror lista feltöltés (CSV/Excel)               │
│ - Ügyfél ellenőrzés tranzakció előtt                        │
└─────────────────────────────────────────────────────────────┘
```

### **Adatbázis Architektúra:**

```
┌─────────────────────────────────────────────────────────────┐
│ RENDER POSTGRESQL (Frankfurt - 1 GB RAM, 25 GB storage)    │
│ - Központi adatbázis (utolsó 12 hónap tranzakció)          │
│ - Logical Replication Publisher (árfolyamok, AML lista)    │
│ - $26.50/hó                                                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓ (Logical Replication)
┌─────────────────────────────────────────────────────────────┐
│ PÉNZTÁR GÉP - LOKÁLIS POSTGRESQL (Docker)                  │
│ - Subscriber (exchange_rates, prohibited_persons sync)     │
│ - Helyi tranzakciók írás (offline működés)                 │
│ - WAL archíválás → USB drive (BitLocker titkosítva)        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ↓ (Automatikus archíválás havonta)
┌─────────────────────────────────────────────────────────────┐
│ CLOUDFLARE R2 (180 GB archívum)                             │
│ - 7 év historikus tranzakciók (Parquet compressed)         │
│ - Régi bizonylatok PDF-ek                                  │
│ - $3/hó                                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔒 Biztonsági Rétegek

### **1. PostgreSQL mező-szintű titkosítás (pgcrypto)**
```sql
-- Személyi adat titkosítás AES-256-GCM
INSERT INTO client_person (name, id_card_number) VALUES (
  'Kovács János',
  pgp_sym_encrypt('123456AB', current_setting('app.encryption_key'), 'cipher-algo=aes256')
);
```

### **2. USB Drive titkosítás (BitLocker)**
- AES-256-XTS teljes meghajtó titkosítás
- Recovery key központi szerveren (széf)
- Automatikus unlock területi vezető jelszavával

### **3. WAL fájl titkosítás (GPG - opcionális)**
```bash
archive_command = 'gpg --encrypt --recipient backup@valuta.hu --output /backup/wal/%f.gpg %p'
```

### **4. TLS 1.3 hálózati kommunikáció**
- Render PostgreSQL SSL alapértelmezett
- Spring Boot → Render: TLS 1.3
- Flutter Desktop → Spring Boot: HTTPS

---

## 🔧 Fejlesztői Eszközök

### **Backend (Spring Boot)**
```powershell
cd backend
mvnw spring-boot:run
# API: http://localhost:8080
# Swagger UI: http://localhost:8080/swagger-ui.html
```

### **Frontend React (Admin)**
```powershell
cd frontend-react
npm install
npm run dev
# UI: http://localhost:3000
```

### **Frontend Flutter (Pénztár kliens)**
```powershell
cd frontend-flutter
flutter pub get
flutter run -d windows
```

---

## 📦 Docker (Pénztár gép szimuláció)

```powershell
cd docker
docker-compose -f docker-compose.cashier.yml up -d

# Ellenőrzés
docker ps
docker logs valuta-cashier-db

# Leállítás
docker-compose -f docker-compose.cashier.yml down
```

---

## 📋 Fejlesztési Roadmap

- [x] **Task 1-2**: Render PostgreSQL setup + Projekt struktúra
- [ ] **Task 3**: PostgreSQL schema import + pgcrypto
- [ ] **Task 4**: Spring Boot backend alapok (Auth, REST API)
- [ ] **Task 5**: Flutter Desktop pénztár kliens (Offline support)
- [ ] **Task 6**: React Admin UI (Árfolyam készítő)
- [ ] **Task 7**: PostgreSQL Logical Replication (Render → Pénztár)
- [ ] **Task 8**: USB Backup automatizálás (BitLocker + WAL)
- [ ] **Task 9**: Cloudflare R2 archíválás (12 hónap+ régi adat)
- [ ] **Task 10**: Kecskemét pilot teszt (1 értéktár + 3 pénztár)

---

## 🆘 Hibaelhárítás

### **Render PostgreSQL Connection Timeout**
```powershell
# Ellenőrzés: Render Dashboard → valuta-production → Info → Connection String friss?
psql $env:RENDER_DB_URL -c "SELECT 1;"

# Ha timeout: Ellenőrizd a Render Dashboard-on hogy "Suspended" státusz van-e (inaktivitás miatt)
```

### **psql command not found**
```powershell
# PostgreSQL 16 kliens telepítés
choco install postgresql16

# PATH ellenőrzés
$env:Path -split ';' | Select-String postgres
```

---

## 📞 Támogatás

- **Dokumentáció**: `docs/` mappa
- **API Specifikáció**: `docs/api-specification.md` (később)
- **Hibabejelentés**: GitHub Issues

---

## 📄 Licenc

Proprietary - Valuta Váltó Kft. © 2025
