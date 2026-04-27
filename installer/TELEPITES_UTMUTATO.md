# Penztar Telepites / Frissites — Felhasznaloi Utmutato (v2.3.0)

**Egyetlen fajl. Egyetlen kattintas. Minden szinten kezeli.**

## A lenyeg egy mondatban

Dupla klikk a `Penztar-Setup-X.Y.Z.exe`-re, es a telepito mindent elintez —
**akar elso telepites, akar frissites, akar gyari reset**.

## 3 forgato

### 1. SZUZ TELEPITES (nincs elozo verzio)

**Kit erint:** uj szamitogep vagy sose volt Penztar telepitve.

**Mit csinal a user:**
1. Dupla klikk `Penztar-Setup-X.Y.Z.exe`
2. Rendszergazda megerositese ([Igen])
3. Telepito fut (~3-5 perc) — minden szukseges runtime bekerul
4. Befejezeskor SetupWizard nyilik
5. Wizard lepesek: iroda / program tipus / szerver / dolgozo + uj jelszo
6. Belepesi oldal — kesz!

### 2. FRISSITES (ajanlott — automatikus adat-megorzessel)

**Kit erint:** mar van regebbi Penztar telepites ugyanezen a gepen.

**Mit csinal a user:**
1. Dupla klikk `Penztar-Setup-X.Y.Z.exe`
2. Rendszergazda megerositese
3. **Dialog jelenik meg:**

   > Mar van egy telepitett Penztar verzio. Mit szeretnel tenni?
   >
   > **IGEN = FRISSITES (ajanlott)**
   >   Az adatbazis es a beallitasok MEGMARADNAK.
   >   Csak a program reszei frissulnek.
   >
   > **NEM = GYARI RESET (teljes wipe)**
   >   MINDEN adat TOROLVE lesz.
   >   Szuzen indul, mintha elso telepites lenne.
   >
   > **MEGSE = Telepites megszakitasa**

4. Klikk **[Igen]** (default) → Frissites
5. Telepito:
   - Silent mode-ban eltavolitja a regi verziot (~30 sec)
   - **DB + config + dolgozo + tranzakciok MEGMARADNAK**
   - Telepiti az uj verziot
   - Frissites kesz — a user beleptet az uj verzioba a *regi* jelszavaval.

### 3. GYARI RESET (tiszta ujratelepites)

**Kit erint:** aki teljesen zero allapotrol akar indulni (pl. teszt VM, eladas elott).

**Mit csinal a user:**
1. Dupla klikk `Penztar-Setup-X.Y.Z.exe`
2. Rendszergazda megerositese
3. A Dialog-ban klikk **[Nem]** → Gyari reset

4. **Megerosito dialog:**

   > FIGYELEM! Gyari reset kivalasztva.
   >
   > MINDEN adat TOROLVE lesz:
   >   - Teljes adatbazis (tranzakciok, ugyfelek, arfolyam)
   >   - Konfiguracio (dolgozo, szerver URL, jelszavak)
   >   - Setup wizard beallitasok
   >
   > Ez VISSZAFORDITHATATLAN! Biztosan folytatod?

5. Klikk **[Igen]** → Teljes wipe + telepites + SetupWizard ujra

## CI / Enterprise / Automatizalt telepites

Silent mode-ban (`/S` flag):

```powershell
# Szuz telepites / auto-upgrade (default)
Penztar-Setup-X.Y.Z.exe /S

# Gyari reset + silent
Penztar-Setup-X.Y.Z.exe /S /WIPE=1
```

## FAQ

### Q: Miert van mas `Penztar-Eltavolito.exe`?
A: Advanced users / enterprise kornyezetben hasznalhato manualis eltavolitasra.
Atlag felhasznalonak NEM kell, mert a `Penztar-Setup.exe` mindent kezel.
Ha megis futtatjak, egy figyelmezteto dialog kerdi meg a megerositest.

### Q: Mi tortenik ha megszakitom a telepites kozepen?
A: A telepito rollback-el (visszaallit). A regi verzio maradni fog.
Legroszabb eseten ismet fut, es a `.onInit` folytatja ott ahol volt.

### Q: Tanarak szoktak-e az adatot menteni a frissites elott?
A: A `PRESERVE_DATA=1` flag a `C:\ProgramData\BestChange` mappat MEGTARTJA.
Ezen belul van a PostgreSQL adatbazis + minden user config.
De biztonsagi okokbol a fontos adatokat a felho Backend a Hetzner-en tart,
igy gep-szintu hiba eseten is visszaallithato.

### Q: Offline mod?
A: A SetupWizard-ban ki lehet valasztani. Ha offline, az embedded PostgreSQL
lokalisan tarolja a tranzakciokat, es a halozat visszaterte utan sync-el
a Hetzner-re.

### Q: Melyik a production URL?
A: `https://excvaluta.com/api/v1` — a telepito ezt is auto-detektalja.
Ha localhost:8080-at mutat (regi bug a 2.2.x-ben), az uj 2.3.0+ auto-javitja
az elso inditaskor.

## Dependencies

A telepito **ONTELJES** — nem kell kulon telepitesek:
- Electron runtime (~180 MB)
- JRE 21 (~50 MB)
- PostgreSQL 17 embedded (~40 MB)
- Backend Spring Boot JAR (~60 MB)
- VC++ 2015-2022 Redistributable (auto, ~25 MB ha hianyzik)

**Teljes meret: ~270 MB**

## Megjegyzesek

- **Adminisztrator jogosultsag kell** a telepiteshez (services, registry)
- **Windows 11 Pro 64-bit** a tamogatot platform
- **Halozat:** SetupWizard tesztel automatikusan a `https://excvaluta.com` backend elereset
- **Jelszo:** A wizard-ban beallitott uj jelszo MENTODIK a szerver oldali DB-be.
  Google OAuth vagy "Elfelejtett jelszo" flow is mukodik (5 EBC email whitelist).

## Dokumentum verzio

- **v1.0 (2026-04-24):** v2.3.0 release — egysegest auto-upgrade + wipe mode
- Kerdesek: kosa.zoltan.ebc@gmail.com (ugyvezeto, admin)