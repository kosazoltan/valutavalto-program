# Valutavalto Penztar v2.3.5 - Telepitesi Utmutato

**Build datum:** 2026-04-27
**Verzio:** 2.3.5
**Git commit:** `70753093`

## Telepito fajlok

| Fajl | Meret | Cel |
|------|-------|-----|
| `Penztar-Setup-2.3.5-20260427.exe` | 276 MB | **Foegysegetlen telepito** - tartalmazza a teljes rendszert (PostgreSQL 17.5 + backend + frontend + Electron klienst + Windows szolgaltatasokat) |
| `Penztar-Eltavolito-2.3.5-20260427.exe` | 60 KB | Standalone Eltavolito - **csak akkor szukseges**, ha a regi telepites annyira serult, hogy a Setup auto-cleanup fazisa fennakad rajta |

## SHA256 ellenorzes

```powershell
Get-FileHash Penztar-Setup-2.3.5-20260427.exe -Algorithm SHA256
# Kell: 9D79DEEDC030FC6FA4B2F438571F8D481E753EB5494C46F79D268A47329DD25D

Get-FileHash Penztar-Eltavolito-2.3.5-20260427.exe -Algorithm SHA256
# Kell: 53683D9D48732CD4FBF9B7C2D590469A298460B24708D365193050B569D6B029
```

## Telepitesi lepesek

### Tiszta telepites (uj gepre)

1. **Zard be** a Penztar alkalmazast (ha fut).
2. **Jobb klikk** a `Penztar-Setup-2.3.5-20260427.exe` fajlra -> **"Futtatas rendszergazdakent"**.
3. Kovesd a varazslo lepeseit (Kovetkezo -> Kovetkezo -> Telepites).
4. Az elso indulaskor jon a **4 lepeses beallito varazslo**:
   - Iroda valasztas
   - Szerver URL (`https://api.excvaluta.com/api/v1` mar elore kitoltve)
   - Kapcsolat tesztelese (KOTELEZO!)
   - Admin jelszo + telepites
5. Belepes a bootstrap admin credential-okkel (lasd 1Password vagy secure vault).

### Frissites (regi verziorol)

> **FONTOS: Az adatbazis es a konfiguracio MEGORIZVE marad!** Ezt a v2.3.0 PR #222 garantalja - upgrade-mode flag.

1. Zard be a Penztar alkalmazast.
2. Futtasd rendszergazdakent: `Penztar-Setup-2.3.5-20260427.exe`.
3. A telepito automatikusan eszleli a regi verziot, frissiti a programot, **megorzi az adatbazist**.
4. Indithatod az alkalmazast.

### Hibas/serult telepites tisztitasa

1. Futtasd **rendszergazdakent**: `Penztar-Eltavolito-2.3.5-20260427.exe`.
2. Vard meg az "KESZ! A regi telepites teljesen eltavolitva" uzenetet.
3. Indits ujra a gepet (biztos, ami biztos).
4. Utana futtasd a `Penztar-Setup-2.3.5-20260427.exe`-t rendszergazdakent.

> **FIGYELEM**: Az Eltavolito a teljes `C:\ProgramData\BestChange` mappat torli, **beleertve az adatbazist**. Ha az adatbazist meg akarod orizni, csinald meg a `dump`-ot elotte! (`pg_dump` parancs - lasd `docs/UPDATE_WINDOWS.md`.)

## Eredmeny telepites utan

| Komponens | Hely |
|-----------|------|
| Program Files | `C:\Program Files\Valutavalto Penztar\` (Electron kliens + uninstaller) |
| Adatok + PostgreSQL | `C:\ProgramData\BestChange\` (pgsql data, backend JAR, JRE, NSSM) |
| `BestChange-PostgreSQL` Windows szolgaltatas | port 54320, NSSM, random scram-sha-256 jelszo |
| `BestChange-Backend` Windows szolgaltatas | port 8080, NSSM, generated JWT secret |
| Windows tuzfal | localhost-ra (127.0.0.1) korlatozva, 8080 + 54320 port |
| Asztali ikon | "Valutavalto Penztar" |

## Telepito felepitese

**1 fajlba van csomagolva minden szukseges komponens:**

- PostgreSQL 17.5 silent installer (~150 MB, SHA-256 verifikalt)
- Backend JAR (Spring Boot 3.5.13, Java 21, jlink-elt custom JRE ~50 MB)
- Frontend (Vite + React) + Electron Desktop kliens
- NSSM Windows service manager
- VC++ Redistributable
- Cleanup logika (regi BestChange szolgaltatasok eltavolitasa)

## Biztonsag

- Minden bundled dependency **SHA-256 checksum**-mal validalt build-idoben (PG, NSSM, VC++).
- `pg_hba.conf` `scram-sha-256` auth-ra van hardenelve (postgres superuser is random jelszot kap).
- A `C:\ProgramData\BestChange\config\` mappa ACL-jei explicit korlatozva (csak SYSTEM + Administrators + service user).
- `.env` a Penztar kliens oldalon `0o600` jogokkal + atomic rename.
- A Windows tuzfal a 8080 + 54320 portot `remoteip=127.0.0.1`-re korlatozza.
- **Nincs bekocsmazott credential** a telepito EXE-ben (minden secret telepiteskor generalodik).

## Tovabbi referenciak

**Foglalkozas-specifikus utak:**

| Cel | Doksi |
|-----|-------|
| Vegfelhasznaloi telepites | [`docs/INSTALL_WINDOWS.md`](../../docs/INSTALL_WINDOWS.md) |
| Frissites regi verziorol | [`docs/UPDATE_WINDOWS.md`](../../docs/UPDATE_WINDOWS.md) |
| Build folyamat (fejleszto) | [`docs/BUILD_WINDOWS.md`](../../docs/BUILD_WINDOWS.md) |
| Biztonsagi ellenorzolista | [`docs/SECURITY_INSTALLER_CHECKLIST.md`](../../docs/SECURITY_INSTALLER_CHECKLIST.md) |
| Installer doksi index | [`docs/INSTALLER_DOCS_INDEX.md`](../../docs/INSTALLER_DOCS_INDEX.md) |
| Installer belso struktura | [`installer/README.md`](../../installer/README.md) |
| Verzio-tortenet | [`CHANGELOG.md`](../../CHANGELOG.md) |
