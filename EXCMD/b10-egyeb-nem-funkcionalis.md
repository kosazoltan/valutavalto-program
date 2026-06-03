# Modul: Egyéb nem-funkcionális források (szótárak, beosztás, licenc, infra, chat-zaj)

<system_context>
## Rendszerkontextus és Cél
A funkcionális követelményt NEM hordozó segédanyagok (referencia-szótárak, munkabeosztás, licenc-árak, infra-screenshotok, chat-screenshot zaj) katalogizálása scope-OUT státusszal.

## Szerepkörök (Roles)
| Szerep | Jogosultság | RBAC érték |
|---|---|---|
| Nem alkalmazható | n/a (OUT) | n/a (OUT) |

## Hatókör (Scope)
### IN
- Az egyes fájlok kategória-szintű leírása + indoklás, miért OUT.

### OUT
- **Teljes modul OUT.** Egyik forrás sem programfunkció-specifikáció.
  - Szótár = fordítási/terminológiai referencia.
  - Beosztás = HR-szervezési dokumentum.
  - Licenc = historikus beszerzési adat.
  - Infra-kép = üzemeltetési háttérinformáció.
  - Messenger képek = chat-zaj.

## Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-INF-01 | A "Szerver szolgáltatások" screenshot szerver-oldali üzemeltetési referencia | TBD: a kép tartalma nincs részletesen értelmezve; csak ha üzemeltetés kéri |
| NFR-LIC-01 | A régi rendszer Delphi-alapú volt (licenc-árak Delphi 12 Pro/Enterprise/Architect) — az új stack Java/Electron | TBD: csak kontextus; nincs licenc-követelmény az új termékre |
</system_context>

<functional_spec>
## Funkcionális Követelmények
*Ebből a modulból nem származnak funkcionális követelmények. Minden katalogizált elem a hatókörön kívül esik (Scope: OUT).*
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma
- Nincs hatással az adatmodellre vagy az adatbázis sémára.
- SQLite mirror: Nem szükséges.
- Migráció: Nem szükséges.
</data_structure>

<integration_points>
## Integrációs Pontok és Végpontok
- Nincs alkalmazás-szintű integrációs vagy végponti függőség.
- A jogi és nyelvészeti szótárak PDF fájljai külső hivatkozásként használhatóak a terminológiához.
</integration_points>

<execution_workflow>
## AI Ügynök Végrehajtási Folyamat

### Phase 1 (Preparation)
1. Rögzítsd a scope-OUT státuszt.
2. Nincs szükség kódváltoztatásra vagy adatbázis migrációra.

### Phase 2 (Backend)
- Nincs backend fejlesztési feladat.

### Phase 3 (Frontend/Client)
- Nincs frontend fejlesztési feladat.

### Phase 4 (Verification)
- Győződj meg róla, hogy ezek a historikus / háttér fájlok nem kerülnek beépítésre a fejlesztési workflow-ba.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés | Miért fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A Messenger-screenshotok tartalmaznak-e követelményt? | Zajnak feltételezve | Ha igen, egyenkénti olvasás és elemzés szükséges külön kérésre. |
| 2 | "Szerver szolgáltatások" kép releváns-e az új infra-hoz? | Telepítési környezet | Csak üzemeltetési összevetésre használható, ha szükséges. |
| 3 | `Névtelen táblázat.xlsx` feltöltődik-e tartalommal? | Hiányok listája | Újra-katalogizálás és elemzés szükséges, ha a jövőben érdemi adat kerül bele. |
| 4 | Beosztás/nyitvatartás befolyásolja-e a program logikát? | Üzleti logika | Pl. napi nyitás/zárás időablakok - jelenleg nem funkcionális HR dokumentumnak tekintve (üzleti megerősítés szükséges). |
</tbd_log>

<verification_checklist>
## Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás megadva (nincs FR - OUT státusz rögzítve).
- [x] Nincsenek kitalált vagy hallucinált követelmények (a fájlnevek és minimális kinyert tartalom alapján).
- [x] Minden TBD és kockázat pontosan megjelölésre került az eredeti fájl alapján.
- [x] Az összesítő verifikáció pontosan megmaradt: FR=0 db, TBD=4 db, érintett csomagok=NINCS (OUT).
</verification_checklist>
