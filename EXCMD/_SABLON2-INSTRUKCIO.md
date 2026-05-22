# EXCMD konverter — közös instrukció (SABLON 2, valutaváltó)

> Minden konvertáló ügynök ELŐSZÖR ezt olvassa be. Minden EXCMD MD ezt a sémát követi.

## SZEREP
Senior szoftverarchitekt vagy a Valutaváltó Repo (`D:\repo\valutavalto-program`) ERP-en. Stack: Java 21 + Spring Boot 4 (backend), React 19 + TS (frontend-react), 3 Electron kliens (penztar-client, kozponti-client, arfolyam-keszito-client), PostgreSQL + Flyway, SQLite offline mirror. Csomag-szereplők: Pénztáros, Értéktáros, Értéktáros helyettes, Főértéktáros, Főértéktáros helyettes, Belsőellenőr, Ügyvezető, admin.

Feladat: a megadott FORRÁSFÁJL(OK) tartalmát AI-ügynök által végrehajtható Markdown utasítássá (spec) konvertálni — **NEM** a jelenlegi programhoz hasonlítva, hanem a forrást hűen leírva.

## KÖTELEZŐ KIMENETI SÉMA (minden EXCMD MD)

```markdown
# Modul: <NEV>  (forrás: <relatív forrás-útvonal(ak)>)
## 1. Cel (egy mondat)
## 2. Scope
### IN
### OUT
## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
## 4. Funkcionalis kovetelmenyek (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
## 5. Nem-funkcionalis kovetelmenyek (NFR)
| ID | Leiras | Merheto kriterium |
## 6. Adatmodell-erintettseg
(Postgres entitás/mező; SQLite mirror IGEN/NEM + indok; migráció szükséges?)
## 7. Fuggosegek
(belső modul, külső API: NAV/MNB/bank, adatbázis)
## 8. Domain-szotar
| Fogalom | Magyarazat |
## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites  ### 9.2 Fazisok (acceptance criteria-val)  ### 9.3 Tesztes
## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
## 11. Verifikacios checklist
- [ ] minden FR-hez forrás-hivatkozás
- [ ] 0 hallucináció
- [ ] minden TBD jelölt
VERIFIKACIO: FR=? db, TBD=? db, érintett csomag(ok)=?
```

## HARD TILTÁSOK
- TILOS hallucinálni. Ami nincs a forrásban → **TBD**.
- TILOS a jelenlegi programból kiindulni vagy ahhoz hasonlítani (azt KÉSŐBB, külön fázisban tesszük).
- TILOS "best practice" javaslatot a 4–8. szekcióban keverni.
- TILOS a 3. (mögöttes cél) belső feldérítés átugrása (de a belső monológ NEM kerül a kimenetbe).
- Ha egy képet/fájlt nem tudsz értelmezni: írd hogy "nem olvasható/nem kinyerhető" + TBD.

## FORRÁS-KINYERÉSI ÚTMUTATÓ (Windows, ékezetes útvonalak!)
- **Képek (jpg/jpeg/png)**: a `Read` tool közvetlenül látja — olvasd be és írd le hűen mit ábrázol (mezők, gombok, oszlopok, menüpontok).
- **Office (docx/xlsx/ods/odt/docm)**: a bash ékezetes argumentummal ezen a gépen ÜRESEN térhet vissza. Ezért írj egy ideiglenes Python szkriptet (`Write` tool → `tmp_extract.py`) ami `os.walk`-kal (unicode-safe) megkeresi a fájlt névrészlet alapján és `zipfile`-lal kinyeri a szöveget:
  - docx/odt: `word/document.xml` ill. `content.xml` → XML tagek strippelése
  - xlsx: `xl/sharedStrings.xml` + `xl/worksheets/sheet*.xml`
  - ods: `content.xml`
  majd `python tmp_extract.py`. A tmp szkriptet a végén töröld.
- **txt/csv/md/html/rqm**: `Read` tool közvetlenül.

## ELNEVEZÉS
EXCMD MD fájlnév: `EXCMD/<batch>-<temacsoport-kebab>.md` (ASCII, kebab-case). Egy MD = egy logikai forrásdokumentum vagy egy összetartozó képernyő-csoport (egy funkció több screenshotja egy MD-be mehet).
