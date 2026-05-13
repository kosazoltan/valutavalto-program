# Valutavalto Pénzváltó ERP — Telepítési útmutató

> **Verzió:** v2.5.49
> **Dátum:** 2026-05-13
> **Cél:** A 3 új kliens-csomag (Pénztáros + Központi munkaállomás + RFM) telepítése a 4 funkcionális területen dolgozó kollégák gépeire.

## 0. ALAPELV — Nem-informatikus végfelhasználó

A kollégák **NEM informatikusok és NEM programozók**. Ez az útmutató úgy van megírva, hogy:
- ❌ Nincs parancssor
- ❌ Nincs registry-szerkesztés
- ❌ Nincs `.env` fájl-módosítás
- ✅ **Csak**: dupla-klikk, "Igen" gomb, "Tovább" gomb

## 1. Áttekintés — Melyik kollégának melyik telepítő kell?

| Kolléga típusa | Telepítő | appMode | Mit lát a programban |
|---|---|---|---|
| **Pénztáros** | `Penztar-Setup-2.5.49-20260513.exe` | `penztar` | Vétel/eladás + napi statisztika |
| **Értéktáros** | `Penztar-Setup-2.5.49-20260513.exe` | `ertektar` | Készletkezelés + napi zárás |
| **Főértéktáros (RFM)** | `Arfolyamkeszito-Setup-2.5.49.exe` | `rate-maker` | Árfolyamkészítés + publikálás |
| **Központi adminisztrátor** | `Kozponti-Iranyitokozpont-Setup-2.5.49.exe` | `full` | Teljes adminisztratív felület |

**Figyelem:** A pénztáros és értéktáros **ugyanazt** a telepítőt kapja — a SetupWizard kérdezi meg telepítéskor melyik módban induljon.

## 2. Telepítő-fájlok

A telepítők a központi gépen találhatók (a fejlesztőnél):
- `C:\Users\Kósa Zoltán\Downloads\Penztar-Setup-2.5.49-20260513.exe` (281 MB)
- `C:\Users\Kósa Zoltán\Downloads\Kozponti-Iranyitokozpont-Setup-2.5.49.exe` (98 MB)
- `C:\Users\Kósa Zoltán\Downloads\Arfolyamkeszito-Setup-2.5.49.exe` (98 MB)
- `C:\Users\Kósa Zoltán\Downloads\Penztar-Eltavolito-2.5.40-20260511.exe` (60 KB, közös eltávolító)

**Másolás a kolléga gépére:** USB pendrive, hálózati megosztás, e-mail csatolmány (281 MB miatt WeTransfer / OneDrive linkkel).

## 3. Telepítés — pénztáros + értéktáros (közös)

### 3.1. Régi verzió eltávolítása (ha már van telepítve)

**1. lépés:** Dupla-klikk a `Penztar-Eltavolito-2.5.40-20260511.exe` fájlra.
**2. lépés:** Windows UAC kérdés: **Igen** (admin jogosultság).
**3. lépés:** Adja meg a Windows admin jelszót (ha nem admin a felhasználó).
**4. lépés:** Az eltávolító automatikusan végigfut: ~30 másodperc.

⚠️ **Az eltávolító NEM törli** a következőket:
- Adatbázis (`%USERPROFILE%\AppData\Local\valuta-penztar-data`)
- Beállítások (`%APPDATA%\valuta-penztar-setup.json`)
- Bizonylatok

Ezek megőrződnek a következő telepítéshez.

### 3.2. Új verzió telepítése

**1. lépés:** Dupla-klikk a `Penztar-Setup-2.5.49-20260513.exe` fájlra.

**2. lépés:** Windows SmartScreen figyelmeztetés esetén:
- Kattints "More info" / "További információk"
- Kattints "Run anyway" / "Futtatás mindenképp"

**3. lépés:** Windows UAC kérdés: **Igen** (admin jogosultság).

**4. lépés:** Admin jelszó megadás (ha kéri).

**5. lépés:** Telepítő NSIS varázsló:
- Nyelv: **Magyar**
- Licencszerződés: **Elfogadom**
- Telepítési útvonal: **alapértelmezett** (`C:\Program Files\Valutavalto Penztar`) — NE módosítsd
- Telepítés gomb → ~2-3 perc

**6. lépés:** Telepítés vége: **Befejezés** gomb (a Setup Wizard automatikusan elindul).

### 3.3. SetupWizard (első indításkor)

A `Setup Wizard` 5 lépésben végigvezet:

#### 3.3.1. Iroda kiválasztása (1/5)
- Lista jelenik meg: `EBC Budapest`, `EBC Debrecen`, stb.
- Kattints a megfelelő irodára.
- **Tovább** gomb.

#### 3.3.2. Program típus (2/5)
- Választható: **Pénztár** (`penztar` mód) vagy **Értéktár** (`ertektar` mód)
- Kattints a megfelelőre.
- **Tovább** gomb.

#### 3.3.3. Szerver kapcsolat (3/5)
- Alapértelmezett URL: `https://excvaluta.com`
- **KÖTELEZŐ:** Kattints a **"Kapcsolat tesztelése"** gombra.
- Várd meg a zöld ✅ visszajelzést (`connectionTest.state=ok`).
- **Tovább** gomb (csak akkor aktív, ha a teszt sikeres).

#### 3.3.4. Admin jelszó (4/5)
- Add meg a workspace admin jelszót (minimum 8 karakter).
- **Megerősítés** mezőbe ugyanaz.
- **Tovább** gomb.

#### 3.3.5. Telepítés (5/5)
- Összegzés képernyő: iroda, program típus, szerver URL, admin jelszó setting.
- **Telepítés** gomb → automatikus konfigurálás (~10 másodperc).
- **Befejezés** → a program elindul az új paraméterekkel.

### 3.4. Első bejelentkezés
1. Login képernyőn: workspace = `EBC`, worker code = pl. `BORSI`, jelszó = `1234` (alapértelmezett).
2. Bejelentkezés sikeres → főképernyő.
3. **Új VÉTEL** próbatranzakció:
   - Valuta: EUR, összeg: 100
   - Bizonylat formátum kell legyen: `V<3-jegyű-numerikus-kód>000001`
   - Például: `V001000001`, `V123000001` (a kód az iroda numerikus kódja)

## 4. Telepítés — Központi munkaállomás (új!)

A főértéktáros / központi adminisztrátor gépén kerül telepítésre.

**1. lépés:** Dupla-klikk a `Kozponti-Iranyitokozpont-Setup-2.5.49.exe` fájlra.

**2-5. lépés:** UAC, SmartScreen, NSIS varázsló — **ugyanúgy mint a pénztáros telepítőnél**, csak:
- Telepítési útvonal: `C:\Program Files\Valutavalto Kozponti Iranyitokozpont`
- A program ikonja: 🏢 (épület-szimbólum)

**6. lépés:** Indítás után **NINCS SetupWizard** — közvetlenül login képernyő (a központi modul mindig `full` módban indul).

**7. lépés:** Belépés a workspace admin fiókkal.

**8. lépés:** Megnyitja a `/central-workstation` oldalt:
- Heading: **"Központi irányítóközpont"**
- 4 modul-csoport: Pénztár áttekintés, Értéktár áttekintés, Árfolyam felügyelet, Riportok

## 5. Telepítés — RFM (árfolyamkészítő) kliens (új!)

A főértéktáros gépén kerül telepítésre (vagy a központi mellé).

**1. lépés:** Dupla-klikk az `Arfolyamkeszito-Setup-2.5.49.exe` fájlra.

**2-5. lépés:** UAC, SmartScreen, NSIS varázsló — **ugyanúgy**, csak:
- Telepítési útvonal: `C:\Program Files\Valutavalto Arfolyamkeszito`

**6. lépés:** Indítás után **NINCS SetupWizard** — közvetlenül login képernyő (RFM kliens mindig `rate-maker` módban indul).

**7. lépés:** Belépés főértéktárosi fiókkal.

**8. lépés:** Megnyitja a `/rates/creation` oldalt:
- Árfolyam-tábla szerkesztő
- Publikálás gomb (a központi DB-be küldés)

## 6. Hibaelhárítás

### "Windows SmartScreen blokkolta a futtatást"
- Megoldás: "More info" → "Run anyway"
- Oka: nem code-signed installer (development build)
- A 100%-os fix: production code signing (DigiCert KeyLocker) — későbbi sprint

### "A program nem indul el"
1. Dupla-klikk `C:\Users\Kósa Zoltán\Downloads\Penztar-Diagnosztika.zip` → kicsomag → `Diagnosztika futtatasa.cmd`
2. A diagnosztika riport `.txt` fájlt generál az asztalra
3. E-mail a `.txt`-t a fejlesztőnek: kosa.zoltan.ebc@gmail.com

### "Kapcsolat tesztelése HIBA"
1. Ellenőrizd a hálózati kapcsolatot: nyiss meg böngészőben `https://excvaluta.com` — kell HTTP 200 választ adjon
2. Ha a szerver fenn van, de a kapcsolat tesztelés mégis hibás: tűzfal / antivírus blokkolhatja a kapcsolatot
3. ESET / Norton / McAfee: add hozzá kivételhez a `C:\Program Files\Valutavalto Penztar\Valutavalto Penztar.exe`-t

## 7. Verifikáció a telepítés után

Mindhárom telepítő után ellenőrzendő:

| Kliens | Verifikáció |
|---|---|
| Pénztár | Új VÉTEL: bizonylat formátum `V<3-jegyű>000001` |
| Értéktár | Készlet listázás (Treasury menü) |
| Központi | `/central-workstation` heading "Központi irányítóközpont" |
| RFM | `/rates/creation` árfolyam-tábla szerkeszthető |

## 8. Hivatkozások

- Telepítő SHA-256 ellenőrzés: lásd `vault/sessions/2026-05-13-v2.5.49-release-ha-failover-runbook.md`
- Failover runbook (HA): `vault/operations/scaleway-failover-runbook.md`
- 4-installer architektúra: `~/.claude/projects/D--repo-valutavalto-program/memory/project_four_installers_architecture.md`
- Acceptance test script: `installer/tests/installer-validation-suite-v2.5.49.ps1`
