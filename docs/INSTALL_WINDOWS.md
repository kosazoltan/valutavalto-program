# Telepítés Windows-ra — Valutaváltó Pénztár

> **Cél:** Ez a dokumentum a **végfelhasználói** (irodai gép) telepítési útmutató. A pénztáros / iroda dolgozók ezt kapják meg.
>
> **Ki készíti a telepítőt:** lásd [`BUILD_WINDOWS.md`](BUILD_WINDOWS.md).
>
> **Frissítés régi verzióról:** lásd [`UPDATE_WINDOWS.md`](UPDATE_WINDOWS.md).
>
> **Adott verzió SHA256 hashek:** lásd `dist/release/install-notes.md` (a kapott telepítő mellé csomagolva).

## Tartalom

1. [Mit kapsz](#1-mit-kapsz)
2. [Előfeltételek a céges gépen](#2-előfeltételek-a-céges-gépen)
3. [Telepítés (clean install)](#3-telepítés-clean-install)
4. [Első indítás — Setup Wizard](#4-első-indítás--setup-wizard)
5. [Mit telepít a Setup](#5-mit-telepít-a-setup)
6. [Hibás telepítés tisztítása](#6-hibás-telepítés-tisztítása)
7. [SHA-256 ellenőrzés](#7-sha-256-ellenőrzés)
8. [Tipikus telepítési hibák](#8-tipikus-telepítési-hibák)
9. [Támogatás](#9-támogatás)

---

## 1. Mit kapsz

Két EXE fájlt:

| Fájl | Méret | Mire kell |
|------|-------|-----------|
| `Penztar-Setup-X.Y.Z-YYYYMMDD.exe` | ~276 MB | **Fő telepítő** — ezt futtasd először. |
| `Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe` | ~60 KB | **Csak akkor**, ha a Setup hibaüzenettel megáll egy nagyon sérült régi telepítésen. |

És opcionálisan a release dokumentumokat:
- `install-notes.md` — verzió-konkrét megjegyzések, SHA-256 hashek
- `build-info.json` — build metaadatok (verzió, dátum, hashek)

> **Fontos:** A `Penztar-Setup-*.exe` MÁR TARTALMAZ auto-cleanup logikát. Az Eltávolítóra **csak végszükségben** van szükség.

## 2. Előfeltételek a céges gépen

| Követelmény | Minimum |
|-------------|---------|
| OS | Windows 10 vagy 11 (x64) |
| RAM | 4 GB (8 GB ajánlott) |
| Szabad lemez | 1.5 GB (PostgreSQL + JRE + frontend) |
| Jogosultság | **Helyi adminisztrátor** (a Setup futtatásához) |
| Internet | csak első indítás Server Connection Test-hez (a backend lokálisan telepítve!) |

> **NEM** kell előre telepíteni: PostgreSQL-t, Java-t, Node-ot, semmi egyebet. A Setup mindent magával hoz.

## 3. Telepítés (clean install)

> **Ha már van régi Pénztár telepítve a gépen:** lásd [`UPDATE_WINDOWS.md`](UPDATE_WINDOWS.md). Frissítéskor az adatbázis **megőrződik**.

### 3.1 Előkészület

1. **Zárd be** a Pénztár alkalmazást, ha fut.
2. **Készíts backup-ot**, ha van bármi adat amit meg akarsz őrizni — részletes útmutató backup parancsokkal: [`UPDATE_WINDOWS.md` § 2](UPDATE_WINDOWS.md#2-mielőtt-frissítesz--backup).

### 3.2 Telepítés

1. **Jobb klikk** a `Penztar-Setup-X.Y.Z-YYYYMMDD.exe` fájlra → **„Futtatás rendszergazdaként"**.
2. Engedélyezd a UAC promptot.
3. Kövesd a varázslót (**Következő → Következő → Telepítés**).
4. Várd meg a telepítés végét (5-15 perc, gép sebességtől függően).

> **Ha a Setup hibaüzenettel megáll** (pl. „BestChange-PostgreSQL service cannot be removed"):
> - Lásd [§6 Hibás telepítés tisztítása](#6-hibás-telepítés-tisztítása).

## 4. Első indítás — Setup Wizard

A telepítés után az **„Valutavalto Penztar"** asztali ikon megjelenik. Indítsd el → **4 lépéses Setup Wizard** jön be:

### Lépés 1: Iroda kiválasztása

Válaszd ki a saját irodádat a legördülő listából (Pécs, Szekszárd, stb.).

### Lépés 2: Szerver URL

A mező már elő van töltve a központi VPS címmel:

```
https://api.excvaluta.com/api/v1
```

> **NE módosítsd**, kivéve ha a IT-támogatás kifejezetten más címet ad meg (pl. tesztkörnyezet).

### Lépés 3: Kapcsolat tesztelése (KÖTELEZŐ!)

Kattints a **„Kapcsolat tesztelése"** gombra. Csak akkor menj tovább, ha **zöld pipa** jelenik meg.

Ha hibát ír:
- Ellenőrizd az internetkapcsolatot
- Hívd az IT-támogatást (a központi backend lehet, hogy nem elérhető)

### Lépés 4: Admin jelszó + telepítés

1. Add meg az **admin jelszót** (ezzel fogsz először belépni). Erős jelszó kötelező:
   - Min 12 karakter
   - Kis-, nagybetű, szám, speciális karakter
2. Kattints a **„Telepítés"** gombra.
3. Az alkalmazás magától elindul, és belép a fő képernyőbe.

> **Bootstrap admin credentials:** Ha a központi „bootstrap admin" credential-okkal kell belépni (pl. első telepítés egy új irodában), kérd el az IT-vezetéstől (1Password / secure vault). **Soha ne emaileld vagy chat-eld!**

## 5. Mit telepít a Setup

| Komponens | Hely |
|-----------|------|
| Program Files | `C:\Program Files\Valutavalto Penztar\` (Electron kliens + uninstaller) |
| Adatok + PostgreSQL | `C:\ProgramData\BestChange\` (pgsql data, backend JAR, JRE, NSSM) |
| `BestChange-PostgreSQL` Windows szolgáltatás | port 54320, NSSM-mel, random `scram-sha-256` jelszó |
| `BestChange-Backend` Windows szolgáltatás | port 8080, NSSM-mel, generated JWT secret + encryption key |
| Windows tűzfal | localhost (127.0.0.1), 8080 + 54320 port |
| Asztali ikon | „Valutavalto Penztar" |
| Start Menu | „Valutavalto Penztar" mappa az uninstaller link-kel |

A két Windows szolgáltatás (`BestChange-PostgreSQL` és `BestChange-Backend`) **automatikusan elindul** a Windows boot-kor — nem kell minden nap újra telepíteni.

## 6. Hibás telepítés tisztítása

> **VIGYÁZAT:** Az `Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe` **TÖRLI a `C:\ProgramData\BestChange` mappát, beleértve az adatbázist!** Ha az adatbázist meg akarod őrizni, készíts backup-ot előtte: [`UPDATE_WINDOWS.md` § 2](UPDATE_WINDOWS.md#2-mielőtt-frissítesz--backup).

### Mikor használd

Csak akkor, ha a `Penztar-Setup-X.Y.Z-YYYYMMDD.exe` futtatása ezzel megáll:
- „BestChange-PostgreSQL service cannot be removed"
- „BestChange-Backend service cannot be removed"
- Visszamaradt fájlok blokkolják a telepítést

### Lépések

1. Futtasd **rendszergazdaként** (jobb klikk → „Futtatás rendszergazdaként"): `Penztar-Eltavolito-X.Y.Z-YYYYMMDD.exe`
2. Várd meg az **„KESZ! A regi telepites teljesen eltavolitva"** üzenetet.
3. Indítsd újra a gépet.
4. Utána futtasd újra a `Penztar-Setup-X.Y.Z-YYYYMMDD.exe`-t rendszergazdaként.

## 7. SHA-256 ellenőrzés

Mielőtt futtatod a Setup-ot, ellenőrizd, hogy a fájl nem lett megrongálva / módosítva:

```powershell
Get-FileHash Penztar-Setup-X.Y.Z-YYYYMMDD.exe -Algorithm SHA256
```

A kapott hash-t hasonlítsd össze a `dist/release/install-notes.md` (vagy a `*.sha256` fájlok) tartalmával. **Ha eltér → NE FUTTASD, és értesítsd az IT-támogatást!**

## 8. Tipikus telepítési hibák

### 8.1 „This app has been blocked by your system administrator"

**Ok:** Windows SmartScreen / AppLocker / GPO blokk.

**Javítás:**
- Jobb klikk a EXE-re → **„Tulajdonságok"** → alul **„Feloldás"** checkbox → OK.
- Vagy IT-támogatáson keresztül: signed installer kell (lásd `BUILD_WINDOWS.md` jövőbeli code-signing fejezet).

### 8.2 „Setup cannot create directory C:\ProgramData\BestChange"

**Ok:** Nincs adminisztrátor jog.

**Javítás:** Bezárod a Setup-ot, jobb klikk a EXE-re → **„Futtatás rendszergazdaként"**.

### 8.3 Setup Wizard „Connection Test" fail (Lépés 3)

**Ok:** Nincs internet, vagy a központi backend (api.excvaluta.com) nem elérhető.

**Javítás:**
- Ellenőrizd: `ping api.excvaluta.com`
- Ha nem ping-el: hívd az IT-támogatást, vagy várj és próbáld újra később.
- A Setup Wizard-ban **„Mégse"** és újraindítás később.

### 8.4 „Port 8080 already in use"

**Ok:** Más alkalmazás (pl. Tomcat, IIS, Docker) használja a 8080-as portot.

**Javítás:**
```powershell
netstat -ano | findstr ":8080"
# Találd meg a PID-et, állítsd le az alkalmazást, vagy konzultálj IT-támogatással
```

### 8.5 „Port 54320 already in use"

**Ok:** Másik PostgreSQL telepítés foglalja a portot.

**Javítás:** Ne futtass párhuzamosan más PG telepítést. Lásd [§6](#6-hibás-telepítés-tisztítása) Eltávolítóval.

### 8.6 Az alkalmazás nem indul el az asztalról

**Ok:** A backend service nem futott el.

**Diagnosztika:**
```powershell
Get-Service -Name "BestChange-*" | Format-Table Name, Status, StartType
```

Ha bármelyik `Stopped`:
```powershell
# Adminisztrátorként:
Start-Service BestChange-PostgreSQL
Start-Sleep -Seconds 5
Start-Service BestChange-Backend
```

Ha továbbra sem indul → IT-támogatás (logok: `C:\ProgramData\BestChange\logs\`).

## 9. Támogatás

- **IT-vezetés:** lásd intranet
- **Telepítési hiba:** csatold a `C:\ProgramData\BestChange\logs\`-ből az utolsó 24 óra log-jait
- **Adatbázis-vesztés:** lásd [`UPDATE_WINDOWS.md` → backup szekció](UPDATE_WINDOWS.md#backup-restore)
- **Biztonsági aggály:** lásd [`SECURITY_INSTALLER_CHECKLIST.md`](SECURITY_INSTALLER_CHECKLIST.md)
