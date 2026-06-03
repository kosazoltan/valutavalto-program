# Modul: EXPRESSZ ZÁLOG (zálogos külön termék) — forrás-katalógus

<system_context>
## Rendszerkontextus és Cél
A zálogos (zálogház) rendszerhez tartozó banki import-, ügyfeles jelentés- és készletjelentés-formátumok katalogizálása annak rögzítésére, hogy ezek **KÜLÖN termékhez** (EXPRESSZ ZÁLOG/EXZ) tartoznak, NEM a valutaváltóhoz.

## Szerepkörök (Roles)
| Szerep | Jogosultság | RBAC érték |
|---|---|---|
| Nem alkalmazható | n/a (külön termék, OUT) | n/a (OUT) |

## Hatókör (Scope)
### IN
- A zálogos forrásfájlok formátum-szintű leírása (mit tartalmaznak).

### OUT
- **Teljes modul OUT a valutaváltó ERP szempontjából** — külön zálog-termék. A valutaváltó (EXV) és a zálog (EXZ) két elkülönült rendszer.
- Tilos a zálog-funkciót a valutaváltó programba beemelni hallucinációval.

## Nem-funkcionális követelmények (NFR)
| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-ZAL-01 | A banki import / ügyfeles jelentés CSV szerkezete a hatósági (Pmt./NAV ügyfeles) jelentés formátumához hasonlít — ez a valuta-oldalon már létező igény is. | TBD: üzleti döntés, hogy a valuta-oldal NAV/ügyfeles exportja ezt a mezőstruktúrát kövesse-e (kapcsolat: meglevő NAV-riport, de NEM e modulból). |
</system_context>

<functional_spec>
## Funkcionális Követelmények
*Ebből a modulból nem származnak a valutaváltó rendszerre vonatkozó funkcionális követelmények. Minden katalogizált elem a hatókörön kívül esik (Scope: OUT).*
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma
- Nincs hatással a valutaváltó Postgres/SQLite sémájára (OUT).
- SQLite mirror: Nem szükséges.
- Migráció: Nem szükséges.
</data_structure>

<integration_points>
## Integrációs Pontok és Végpontok
- Nincs belső valutaváltó-modul függőség.
- Külső: a zálogos forrásokban hivatkozott banki/hatósági import (pl. FRB/ERB/RB bank-kódok).
</integration_points>

<execution_workflow>
## AI Ügynök Végrehajtási Folyamat

### Phase 1 (Preparation)
1. Rögzítsd a scope-OUT státuszt.
2. A zálogos fájlok elkülönítése a valutaváltó kódállományától.

### Phase 2 (Backend)
- Nincs backend fejlesztési feladat a valutaváltó programban.

### Phase 3 (Frontend/Client)
- Nincs frontend fejlesztési feladat a valutaváltó programban.

### Phase 4 (Verification)
- Győződj meg róla, hogy a zálog és valuta modulok közötti funkcionális határok egyértelműek és nem történt nem kívánt átfedés.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés | Miért fontos | Mit kell tudni |
|---|---|---|---|
| 1 | A zálog-termék egyáltalán része-e a megbízásnak? | Hatókör pontosítása | A teljes mappa OUT, ha a zálog modul nem része a projektnek (Kósa üzleti döntése). |
| 2 | Az ügyfeles/banki CSV mezőstruktúra átvehető-e a valuta NAV-exporthoz? | Hatósági paritás | Csak ha igen → külön EXV-feladat, NEM ebből a zálog modulból levezetve. |
| 3 | `P91.TXT` valuta vagy zálog? | Besorolás tisztázása | Bizonylat-export jellegű. Bár a zálogos mappában volt, tartalma valutás tranzakcióknak tűnik. |
| 4 | `zalog_requirment.rqm` 135 objektumának részletes tartalma | Ha a zálog specifikáció szükséges | PowerDesigner export szükséges a részletes XML elemzéshez. |
</tbd_log>

<verification_checklist>
## Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás megadva (nincs EXV-FR - OUT státusz rögzítve).
- [x] Nincsenek kitalált vagy hallucinált követelmények (a zálogos specifikációs fájlok alapján).
- [x] Minden TBD és kockázat pontosan megjelölésre került az eredeti fájl alapján.
- [x] Az összesítő verifikáció pontosan megmaradt: FR=0 db, TBD=4 db, érintett csomagok=NINCS (OUT).
</verification_checklist>
