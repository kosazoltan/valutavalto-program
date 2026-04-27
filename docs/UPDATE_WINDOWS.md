# Frissítés Windows-on — Valutaváltó Pénztár

> **Cél:** Régi Pénztár verzióról új verzióra frissítés. **Az adatbázis és konfiguráció megőrződik** (PR #222 óta, v2.3.0+).
>
> **Új telepítés (clean):** lásd [`INSTALL_WINDOWS.md`](INSTALL_WINDOWS.md).
>
> **Hibás verzió tisztítása:** lásd [`INSTALL_WINDOWS.md` § 6](INSTALL_WINDOWS.md#6-hibás-telepítés-tisztítása).

## Tartalom

1. [Áttekintés](#1-áttekintés)
2. [Mielőtt frissítesz — backup](#2-mielőtt-frissítesz--backup)
3. [Frissítési folyamat](#3-frissítési-folyamat)
4. [Mit őriz meg a frissítés](#4-mit-őriz-meg-a-frissítés)
5. [Mit frissít a Setup](#5-mit-frissít-a-setup)
6. [Backup / Restore](#6-backup--restore)
7. [Rollback (visszaállás régi verzióra)](#7-rollback-visszaállás-régi-verzióra)
8. [Tipikus frissítési hibák](#8-tipikus-frissítési-hibák)

---

## 1. Áttekintés

A frissítés ugyanazzal a `Penztar-Setup-X.Y.Z-YYYYMMDD.exe` fájllal történik, mint a clean install. A telepítő **automatikusan érzékeli** a meglévő telepítést, és **upgrade módba** vált:

- Az adatbázis (`C:\ProgramData\BestChange\pgsql\data\`) **NEM törlődik**
- A konfiguráció (`C:\ProgramData\BestChange\config\`) **NEM törlődik**
- A backend JAR, custom JRE, frontend, Electron kliens **frissül**
- A Windows szolgáltatások (`BestChange-PostgreSQL`, `BestChange-Backend`) **újratelepülnek**, de a PostgreSQL data dir megmarad

Forrás: PR #222 (v2.3.0) — `$UPGRADE_MODE` flag a `Penztar-Setup.nsi .onInit`-ben + `SetRegView 64` lookup a `Wow6432Node` redirect handlinghez.

## 2. Mielőtt frissítesz — backup

> **MINDIG csinálj backup-ot frissítés előtt**, még akkor is, ha a Setup elvileg megőrzi az adatokat. A backup 5 percbe telik, az adatvesztés viszont napokba kerülhet helyreállítani.

### 2.1 Egyszerű DB dump (ajánlott)

```powershell
$backupDir = "$env:USERPROFILE\Desktop\valuta-backup-$(Get-Date -Format yyyyMMdd-HHmm)"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

# Postgres dump
& "C:\ProgramData\BestChange\pgsql\bin\pg_dump.exe" `
    -U postgres -p 54320 -d valutavalto `
    -f "$backupDir\valutavalto.sql"

# Konfiguráció
Copy-Item "C:\ProgramData\BestChange\config\*.env" "$backupDir\" -Force

Write-Host "Backup elkeszult: $backupDir"
Get-ChildItem $backupDir | Select-Object Name, Length
```

### 2.2 Kérdezd a postgres jelszót

A `pg_dump.exe` jelszót kér. A jelszó a `C:\ProgramData\BestChange\config\.pg-postgres-password` fájlban van (csak a `BestChange-Backend` service user fér hozzá — admin PowerShell-ből olvasható):

```powershell
# Adminisztrátorként:
Get-Content "C:\ProgramData\BestChange\config\.pg-postgres-password"
```

### 2.3 Teljes folder backup (paranoia mode)

```powershell
$backupDir = "$env:USERPROFILE\Desktop\valuta-fullbackup-$(Get-Date -Format yyyyMMdd-HHmm)"

# Állítsd le a service-eket, hogy konzisztens legyen a snapshot
Stop-Service BestChange-Backend
Stop-Service BestChange-PostgreSQL

# Másold a teljes ProgramData mappát
Copy-Item "C:\ProgramData\BestChange" -Destination $backupDir -Recurse -Force

# Indítsd vissza
Start-Service BestChange-PostgreSQL
Start-Sleep -Seconds 5
Start-Service BestChange-Backend
```

> **Vigyázat:** A teljes backup 1-5 GB lehet (PG data + JAR + JRE).

## 3. Frissítési folyamat

### 3.1 Előkészület

1. **Zárd be** a Pénztár alkalmazást (ne csak minimalizáld).
2. **Csinálj backup-ot** ([§2](#2-mielőtt-frissítesz--backup)).
3. **Ellenőrizd** a régi verziót:
   - Pénztár alkalmazás **„Súgó → Verzióinformáció"**, vagy
   - `(Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Penztar-Setup").DisplayVersion`

### 3.2 Frissítés

1. **Jobb klikk** az új `Penztar-Setup-X.Y.Z-YYYYMMDD.exe` fájlra → **„Futtatás rendszergazdaként"**.
2. UAC engedélyezés.
3. A telepítő **felismeri a régi telepítést**, és „Frissítés" módba vált:
   - „Megtalalva: Valutavalto Penztar v2.3.x"
   - „A meglévő adatbázist és konfigurációt megőrzöm"
4. Kövesd a varázslót (**Következő → Telepítés**).
5. A telepítés végén az alkalmazás **automatikusan elindul**.

> **NEM kell** újra végigfutnia a Setup Wizard-on (iroda választás, szerver URL, admin jelszó) — ezek a régi konfigurációból átkerülnek.

### 3.3 Frissítés után — verifikáció

```powershell
# Ellenőrizd, hogy a service-ek futnak:
Get-Service -Name "BestChange-*" | Format-Table Name, Status, StartType

# Ellenőrizd a backend egészségét:
curl.exe -s http://127.0.0.1:8080/actuator/health

# Ellenőrizd a verziót:
(Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Penztar-Setup").DisplayVersion
```

Indítsd el a Pénztárt → ellenőrizd, hogy ugyanazok a tranzakciók látszanak, mint a frissítés előtt.

## 4. Mit őriz meg a frissítés

| Komponens | Megőrizve? | Hely |
|-----------|------------|------|
| PostgreSQL adatbázis (összes tranzakció, user, irodai adat) | **IGEN** | `C:\ProgramData\BestChange\pgsql\data\` |
| `.env` konfiguráció (DB jelszó, JWT secret, encryption key) | **IGEN** | `C:\ProgramData\BestChange\config\.env` |
| Postgres superuser jelszó | **IGEN** | `C:\ProgramData\BestChange\config\.pg-postgres-password` |
| Iroda kiválasztás, szerver URL | **IGEN** | `%APPDATA%\Valutavalto Penztar\config.json` |
| Custom napló-mappák | **IGEN** | `C:\ProgramData\BestChange\logs\` (nem törlődik) |

## 5. Mit frissít a Setup

| Komponens | Frissítve |
|-----------|-----------|
| Backend JAR (`valuta-backend.jar`) | **IGEN** |
| Custom JRE (`C:\ProgramData\BestChange\jre\`) | **IGEN** |
| Frontend (Vite assets) | **IGEN** |
| Electron desktop kliens | **IGEN** |
| `BestChange-PostgreSQL` szolgáltatás | **IGEN** (újratelepítés, de a data dir megmarad) |
| `BestChange-Backend` szolgáltatás | **IGEN** (új JAR-ral) |
| Tűzfal-szabályok | **IGEN** (re-create) |
| NSSM service manager | **IGEN** (új verzió, ha változott) |
| PostgreSQL bináris (`pgsql\bin\`) | **NEM** (csak fő verzió-váltáskor — pl. PG 17 → 18 — manuálisan) |

## 6. Backup / Restore

### 6.1 Restore egy korábbi `pg_dump`-ból

> **Ezt csak akkor csináld, ha az adatok elveszettnek tűnnek.** A frissítés normál esetben az adatokat megőrzi.

```powershell
# 1. Állítsd le a backend service-t, hogy ne írjon közben:
Stop-Service BestChange-Backend

# 2. Drop és re-create az adatbázist:
& "C:\ProgramData\BestChange\pgsql\bin\psql.exe" `
    -U postgres -p 54320 -d postgres `
    -c "DROP DATABASE IF EXISTS valutavalto;"

& "C:\ProgramData\BestChange\pgsql\bin\psql.exe" `
    -U postgres -p 54320 -d postgres `
    -c "CREATE DATABASE valutavalto OWNER valuta_user;"

# 3. Restore a dump-ból:
& "C:\ProgramData\BestChange\pgsql\bin\psql.exe" `
    -U postgres -p 54320 -d valutavalto `
    -f "$env:USERPROFILE\Desktop\valuta-backup-XXXXXXXX\valutavalto.sql"

# 4. Indítsd vissza a backend-et:
Start-Service BestChange-Backend
```

### 6.2 Restore a teljes folder backup-ból (paranoia mode)

```powershell
# 1. Állítsd le a service-eket:
Stop-Service BestChange-Backend
Stop-Service BestChange-PostgreSQL

# 2. Töröld a sérült telepítés data-ját:
Remove-Item "C:\ProgramData\BestChange\pgsql\data" -Recurse -Force
Remove-Item "C:\ProgramData\BestChange\config\.env" -Force

# 3. Másold vissza a backup-ból:
Copy-Item "$env:USERPROFILE\Desktop\valuta-fullbackup-XXXXXXXX\pgsql\data" `
          "C:\ProgramData\BestChange\pgsql\data" -Recurse -Force

Copy-Item "$env:USERPROFILE\Desktop\valuta-fullbackup-XXXXXXXX\config\.env" `
          "C:\ProgramData\BestChange\config\.env" -Force

# 4. Indítsd vissza:
Start-Service BestChange-PostgreSQL
Start-Sleep -Seconds 5
Start-Service BestChange-Backend
```

## 7. Rollback (visszaállás régi verzióra)

> **Nehéz.** A `Penztar-Setup-X.Y.Z-YYYYMMDD.exe` nem tud visszafrissíteni. Rollback = uninstall + clean install + DB restore.

### Lépések

1. **Backup most** (akkor is, ha az új verzió hibás): [§2](#2-mielőtt-frissítesz--backup).
2. Standalone Eltávolító: `Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe` (lásd [`INSTALL_WINDOWS.md` §6](INSTALL_WINDOWS.md#6-hibás-telepítés-tisztítása)).
3. **Indítsd újra** a gépet.
4. Telepítsd a régi verziót: `Penztar-Setup-{régi_verzió}-YYYYMMDD.exe`.
5. Restore a backup-ból: [§6.1](#61-restore-egy-korábbi-pg_dump-ból).

## 8. Tipikus frissítési hibák

### 8.1 „BestChange-PostgreSQL service cannot be stopped"

**Ok:** Más alkalmazás használja az adatbázist (pl. nyitva maradt egy psql kliens).

**Javítás:**
```powershell
Get-Process -Name "psql","pgAdmin*" -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Service BestChange-Backend
Stop-Service BestChange-PostgreSQL
# Most futtasd a Setup-ot újra
```

### 8.2 „Cannot remove file in use" (frissítés közben)

**Ok:** A Pénztár alkalmazás vagy a backend service még fut.

**Javítás:**
```powershell
Get-Process -Name "Valutavalto*","java" -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Service BestChange-Backend
Stop-Service BestChange-PostgreSQL
# Most futtasd a Setup-ot újra
```

### 8.3 Frissítés után az alkalmazás üres adatbázist mutat

**Ok:** Hiba a frissítési logikában (PR #222 előtt v2.3.0-tól megelőzve, de elméletileg lehetséges egy szélsőséges esetben).

**Javítás:**
1. Állítsd le a service-eket.
2. Restore a backup-ból ([§6](#6-backup--restore)).
3. **Jelentsd a hibát az IT-támogatásnak** — log fájlok: `C:\ProgramData\BestChange\logs\`.

### 8.4 Frissítés után más a port (pl. 8081)

**Ok:** Az új verzió manuálisan változtatott porton fut (nagy ritkaság). Az `.env` fájlban felülírható.

**Javítás:**
```powershell
# Ellenőrizd a backend portját:
notepad "C:\ProgramData\BestChange\config\.env"
# Keresd a PORT= sort, állítsd vissza 8080-ra
Restart-Service BestChange-Backend
```

### 8.5 Frissítés után a régi adatbázis korrupt

**Ok:** Ritkán előfordul, ha a frissítés közben áramszünet, kemény reboot történik.

**Javítás:**
1. Állítsd le a service-eket.
2. Restore a backup-ból ([§6](#6-backup--restore)).
3. Ne csinálj frissítést áramszünetes környezetben.

## Kapcsolódó dokumentumok

- [`INSTALL_WINDOWS.md`](INSTALL_WINDOWS.md) — clean install
- [`BUILD_WINDOWS.md`](BUILD_WINDOWS.md) — build folyamat
- [`SECURITY_INSTALLER_CHECKLIST.md`](SECURITY_INSTALLER_CHECKLIST.md) — biztonsági ellenőrzőlista
- [`CHANGELOG.md`](../CHANGELOG.md) — verzió-történet (v2.3.0 PR #222 az UPGRADE_MODE bevezetése)
