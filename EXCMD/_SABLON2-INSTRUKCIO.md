<system_context>
# EXCMD konverter — közös instrukció (SABLON 2, valutaváltó)

## Kontextus
Minden konvertáló ügynök ELŐSZÖR ezt olvassa be. Minden EXCMD MD ezt a sémát követi. A projekt célja a Valutaváltó Repo (`D:\repo\valutavalto-program`) ERP-ben található dokumentumok és képek hű leírása AI-ügynök által végrehajtható formában.

## Technológiai Stack (Tech Stack)
- **Backend**: Java 21 + Spring Boot 4
- **Frontend**: React 19 + TS (frontend-react)
- **Kliens**: 3 Electron kliens (`penztar-client`, `kozponti-client`, `arfolyam-keszito-client`)
- **Adatbázis**: PostgreSQL + Flyway (szerver), SQLite offline mirror (kliens)

## Szerepkörök (Roles)
- Pénztáros
- Értéktáros
- Értéktáros helyettes
- Főértéktáros
- Főértéktáros helyettes
- Belsőellenőr
- Ügyvezető
- Admin
- Senior szoftverarchitekt (konvertáló szerep)

## Hatókör (Scope)
- **IN**: A megadott forrásfájl(ok) tartalmának konvertálása AI-ügynök által végrehajtható Markdown utasítássá (spec), hűen a forráshoz.
- **OUT**: A jelenlegi programhoz való hasonlítás (azt külön lépésben tesszük).
</system_context>

<functional_spec>
## Funkcionális Követelmények

### ### [FR-SAB-01] [Kötelező kimeneti séma betartása]
- **Leírás**: Minden EXCMD MD fájlnak szigorúan követnie kell a megadott XML-alapú szerkezeti tagelést.
- **Forrás**: _SABLON2-INSTRUKCIO.md
- **Prio**: Must
- **Csomag/Komponens**: spec-rewriter
- **Bemenő adatok**: Forrás specifikáció fájlok.
- **Kimenet / Visszajelzés**: XML tagekkel strukturált specifikáció.
- **Validációk és Kényszerek**: Az XML tagek helyes lezárása és felosztása kötelező.

### ### [FR-SAB-02] [Hard tiltások betartása]
- **Leírás**:
  - TILOS hallucinálni. Ami nincs a forrásban -> TBD.
  - TILOS a jelenlegi programból kiindulni vagy ahhoz hasonlítani.
  - TILOS "best practice" javaslatot a 4-8. szekcióban keverni.
  - TILOS a mögöttes cél (belső felderítés) átugrása (de a belső monológ NEM kerül a kimenetbe).
  - Ha egy képet/fájlt nem lehet értelmezni -> "nem olvasható/nem kinyerhető" + TBD.
- **Forrás**: _SABLON2-INSTRUKCIO.md
- **Prio**: Must
- **Csomag/Komponens**: spec-rewriter
- **Bemenő adatok**: N/A
- **Kimenet / Visszajelzés**: Halucinációmentes specifikáció dokumentum.
- **Validációk és Kényszerek**: Szigorú ellenőrzés a forrásadatokkal szemben.

### ### [FR-SAB-03] [Forrás-kinyerési útmutató követése]
- **Leírás**:
  - **Képek (jpg/jpeg/png)**: Közvetlen beolvasás és hű leírás (mezők, gombok, oszlopok, menük).
  - **Office fájlok (docx/xlsx/ods/odt/docm)**: Mivel Windows alatt az ékezetes argumentumok üresen térhetnek vissza, ideiglenes Python szkript (`tmp_extract.py`) használata javasolt unicode-safe módon, zipfile-al kinyerve a szöveget:
    - docx/odt: `word/document.xml` ill. `content.xml` XML strippeléssel.
    - xlsx: `xl/sharedStrings.xml` + `xl/worksheets/sheet*.xml`
    - ods: `content.xml`
    A szkriptet futtatás után törölni kell.
  - **Szöveges fájlok (txt/csv/md/html/rqm)**: Közvetlen beolvasás.
- **Forrás**: _SABLON2-INSTRUKCIO.md
- **Prio**: Must
- **Csomag/Komponens**: spec-rewriter
- **Bemenő adatok**: Nyers forrásfájlok.
- **Kimenet / Visszajelzés**: Kinyert szöveges információk.
- **Validációk és Kényszerek**: Kódolási hibák elkerülése, ideiglenes szkriptek törlése.

### ### [FR-SAB-04] [Elnevezési konvenciók betartása]
- **Leírás**: Az EXCMD MD fájlnév formátuma: `EXCMD/<batch>-<temacsoport-kebab>.md` (ASCII, kebab-case). Egy MD fájl egy logikai forrásdokumentumot vagy képernyő-csoportot fed le.
- **Forrás**: _SABLON2-INSTRUKCIO.md
- **Prio**: Must
- **Csomag/Komponens**: spec-rewriter
- **Bemenő adatok**: N/A
- **Kimenet / Visszajelzés**: Megfelelően elnevezett fájlok.
- **Validációk és Kényszerek**: Csak ASCII karakterek, kebab-case elnevezés.
</functional_spec>

<data_structure>
## Adatmodell és Séma javaslatok
Nincs közvetlen adatmodell érintettség. A specifikációk konvertálása során felmerülő adatmodelleket az egyedi modul-leírások tartalmazzák.
</data_structure>

<integration_points>
## Integrációs Pontok
Nincs külső integráció ebben a sablonban. A külső rendszereket (NAV, POS, bankok) az egyedi modul-specifikációk tartalmazzák.
</integration_points>

<execution_workflow>
## Végrehajtási workflow az AI-ügynöknek

### Phase 1: Előkészítés (Preparation)
- Olvasd be a forrásfájlokat a megfelelő eszközökkel (szükség esetén átmeneti Python kinyerő szkripttel).
- Határozd meg a modul célját, jogosultsági köreit és scope-ját.

### Phase 2: Backend (Backend)
- Tervezd meg a backend entitások és szolgáltatások struktúráját a forrás alapján (Postgres).

### Phase 3: Frontend/Client (Frontend/Client)
- Tervezd meg a kliens oldali felületeket és az offline SQLite szinkronizációt.

### Phase 4: Ellenőrzés (Verification)
- Ellenőrizd, hogy minden funkcionális követelményhez tartozik-e forrás-hivatkozás, és nincsenek-e hallucinált követelmények.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és kockázatok (TBD)
Nincsenek nyitott kérdések a sablonban.
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden FR-hez forrás-hivatkozás megadva
- [x] 0 hallucináció garantálva
- [x] Minden TBD pont jelölve
</verification_checklist>
