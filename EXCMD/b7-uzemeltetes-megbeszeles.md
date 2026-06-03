# Modul: EXZ+EXV uzemeltetes es jelenlegi rendszer-architektura (Valuta)

<system_context>
## Rendszerkontextus és Háttér
Ez a specifikáció a jelenleg üzemelő valutaváltó rendszer (Delphi alapú kliens lokális Firebird adatbázissal és RackForest hostolt központi RDP szerverrel) üzemeltetési és hálózati architektúráját írja le, rögzítve az új rendszer megtervezéséhez szükséges "as-is" paramétereket, kliens-szerver folyamatokat, hibatűrési modelleket és NAV/bank/szankciós szinkronizációs határidőket.

### Szerepkörök (Roles)
| Szerep | Jogosultság / Feladatkör | RBAC érték |
|---|---|---|
| Pénztáros | Valutaváltási tranzakciók rögzítése, gép-hiba esetén kézi bizonylatok kiállítása, napi nyitó/záró címletezési adatok bevitele. | TBD |
| Főértéktáros | Központi árfolyamok menedzselése és leküldése a fiókoknak, tiltólisták karbantartása. | TBD |
| Területi vezető | Zárások engedélyezése a 30 perces időablakon túl, manuális ÁNYK adóhatósági lejelentések végrehajtása hiba esetén. | TBD |
| Belsőellenőr | Központi riportok, kasszaállapotok és címletezési adatok megtekintése. | TBD |
| Üzemeltető (Póka János) | Szoftver telepítése, lokális adatbázisok helyreállítása (C: mappa mentés-visszaállítás), új irodai kliensek seedelése üres adatbázissal. | TBD |

### Hatókör (Scope)
#### IN
- A jelenlegi as-is kliens-szerver architektúra (lokális Firebird adatbázisok + központi szerver).
- Árfolyamok és tiltólisták 5 perces polling alapú leküldése.
- Felfelé irányuló zárási adatok: napi tranzakciók, kasszaállapot, címletezési adatok és mentések.
- Offline vészhelyzeti üzemmód (kézi bizonylatolás, nyomtatott árfolyam-bizonylatok használata).
- NAV online kommunikáció, hálózati hibák kezelése, 24 órás határidők és az ÁNYK fallback eljárások.
- Hardveres integrációk: blokknyomtatók, párhuzamos port kihívások, Java-alapú kamerás biztonsági rendszer, NIS2 kiberbiztonsági követelmények.

#### OUT
- Új technológiai verem fizikai szintű architektúra tervei (pl. Kubernetes/Docker struktúrák).
- A banki és NAV adóhatósági szabályok részletes üzleti katalógusa (lásd `b7-igenyfelmeres-interjuk.md`).

### Technológiai verem (Tech Stack)
- Régi kliensoldali futtatókörnyezet (Delphi desktop kliensek, lokális Firebird DB-vel)
- RackForest Cloud RDP hostolt központi adatbázis és távoli elérés
- Helyi soros/párhuzamos portos nyomtató interfészek (LPT portok)
- Java alapú kamerarendszer integráció
- Új javasolt célarchitektúra: Web-alapú kliens (`frontend-react` és `penztar-client` Electron keretben) központi PostgreSQL adatbázissal és kliensoldali SQLite szinkron mirror-ral (FR-52)
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-37: 5 perces árfolyam-szinkronizáció
- **Leírás**: A kliensprogramnak 5 percenként automatikusan le kell kérdeznie a központi szervertől a friss árfolyamokat. Ha a lekérdezés meghiúsul (pl. hálózati hiba miatt), a rendszernek jeleznie kell a hibát a felületen, de tovább kell engednie a munkát a legutolsó sikeresen letöltött árfolyamokkal, miközben folyamatosan újrapróbálkozik a háttérben.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (572, 576)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Hálózati polling jel, API válasz.
- **Kimenet / Visszajelzés**: Frissített helyi árfolyamtábla / Kapcsolati figyelmeztetés.
- **Validációk és Kényszerek**: Az árfolyam-lekérdezés nem blokkolhatja a felületi szálat.

### FR-38: Irodánkénti egyedi árfolyamok
- **Leírás**: A rendszernek támogatnia kell, hogy a központi szerver minden fizikai irodához/géphez egyedi árfolyamtáblát küldhessen le a helyi versenyhelyzet függvényében. Minden irodai gép egy önálló kasszaként funkcionál saját lokális adatbázis tükörrel.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (573, 576)
- **Prio**: Must
- **Csomag/Komponens**: `kozponti-client` / `penztar-client`
- **Bemenő adatok**: Iroda azonosító, egyedi árfolyamtörzs.
- **Kimenet / Visszajelzés**: Kliensre letöltött iroda-specifikus árfolyamok.
- **Validációk és Kényszerek**: Nincs.

### FR-39: Központilag vezérelt tiltólistás szűrés
- **Leírás**: Biztosítani kell a terrorista és szankciós tiltólisták központi kezelését. A kliens oldalon az ügyfél adatainak beírásakor a rendszernek jeleznie kell a pénztárosnak, ha az ügyfél kiszolgálása tiltott.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (572)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Ügyfél azonosító adatok, tiltólista.
- **Kimenet / Visszajelzés**: Váltást blokkoló üzenet a kliensen.
- **Validációk és Kényszerek**: Nincs.

### FR-40: Delta alapú tiltólista frissítés
- **Leírás**: A tiltólista minden pénztárnál azonos tartalmú (globális). A hálózati terhelés minimalizálása érdekében a szinkronizáció során csak a változásokat (hozzáadott vagy törölt nevek) szabad leküldeni a kliensekre (delta szinkron).
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (591)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Tiltólista változásnapló.
- **Kimenet / Visszajelzés**: Szinkronizált lokális tiltólista mirror.
- **Validációk és Kényszerek**: Nincs.

### FR-41: Záráskori felfelé irányuló szinkronizáció
- **Leírás**: Napi zárás végrehajtásakor a kliensnek kötelezően fel kell töltenie a központi szerverre az aznapi forgalmi adatokat, a lokális adatbázis biztonsági mentését, a végső kasszaállapotot, valamint a részletes záró címletezési adatokat.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (577)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client` / `kozponti-client`
- **Bemenő adatok**: Zárási parancs, lokális tranzakció naplók.
- **Kimenet / Visszajelzés**: Sikeres zárás nyugtázása a szerverről.
- **Validációk és Kényszerek**: Sikertelen adatfeltöltés esetén a zárás nem tekinthető befejezettnek.

### FR-42: Pénzszállítások valós idejű kommunikációja
- **Leírás**: A pénztárból történő ki- és bevételezések (pl. értéktári szállítások) indításakor a kliensnek azonnal jeleznie kell a tranzakciót a szerver felé a területi vezető értesítése érdekében.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (577)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Pénzszállítási indítás bizonylata.
- **Kimenet / Visszajelzés**: Küldött státusz a vezetői irányítópulton.
- **Validációk és Kényszerek**: Nincs.

### FR-43: Hardveres gép-hiba vészhelyzeti protokoll
- **Leírás**: Hardveres vagy áramellátási hiba esetén a pénztárban engedélyezni kell a kézi bizonylatolást a nyomtatott árfolyamlistából dolgozva. A gép helyreállítása (üzembe helyezése) után biztosítani kell a kézi bizonylatok utólagos, tömeges rögzítésének lehetőségét a rendszerben.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (579-580)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Utólagosan beírt tranzakció adatok, eredeti kézi dátummal és bizonylatszámmal.
- **Kimenet / Visszajelzés**: Utólagosan rögzített tételek.
- **Validációk és Kényszerek**: Az utólagos rögzítés tényét és a kézi bizonylat számát kötelezően naplózni kell.

### FR-44: Napi hivatalos árfolyam-bizonylat nyomtatása
- **Leírás**: A belső szabályzatoknak megfelelően a rendszernek a napi nyitáskor (vagy meghatározott időközönként) fel kell ajánlania a hivatalos árfolyam-bizonylat fizikai kinyomtatását (szalagra vagy blokk formában), hogy gép-hiba esetén ebből a listából tudjanak dolgozni.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (580)
- **Prio**: Should
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Aktuális nyitó árfolyamok.
- **Kimenet / Visszajelzés**: Kinyomtatott fizikai árfolyamszalag.
- **Validációk és Kényszerek**: Nincs.

### FR-45: Közvetlen online NAV pénztárgép-lejelentés
- **Leírás**: Minden elvégzett tranzakcióról a kliensprogramnak azonnal és automatikusan blokkot kell nyomtatnia a fizikai online pénztárgépen keresztül, és ezzel egy időben be kell küldenie a tranzakció adatait az adóhatóság (NAV) felé.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (585-586)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Lezárt tranzakció adatai.
- **Kimenet / Visszajelzés**: Fizikai pénztárgép bizonylat, sikeres NAV beküldés státusz.
- **Validációk és Kényszerek**: Nincs.

### FR-46: Kézi lejelentés 24 órás határideje (ÁNYK)
- **Leírás**: Ha a fizikai pénztárgép meghibásodik vagy offline marad, és a tranzakció beküldése nem sikerül, a lejelentést kézzel kell végrehajtani a NAV ÁNYK nyomtatványkitöltő rendszerén keresztül legfeljebb 24 órán belül a bírságok elkerülése érdekében (területi vezetői feladat).
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (586, 588)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Manuális ÁNYK adatok.
- **Kimenet / Visszajelzés**: Kézi beküldés rögzített ténye a rendszerben.
- **Validációk és Kényszerek**: Nincs.

### FR-47: Offline tranzakció gyűjtés és utólagos NAV beküldés
- **Leírás**: Internethiba vagy hálózati kiesés esetén a kliensnek helyben (SQLite) kell gyűjtenie a tranzakciós adatokat és a NAV lejelentési állományokat. A hálózat helyreálltakor a rendszernek automatikusan el kell indítania az összes felgyülemlett adat feltöltését (a 24 órás határidőn belül).
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (588)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Kapcsolat helyreállása, lokális gyűjtő.
- **Kimenet / Visszajelzés**: Sikeres utólagos tranzakció-feltöltések.
- **Validációk és Kényszerek**: Nincs.

### FR-48: Napzárási 30 perces időablak korlátozás
- **Leírás**: A napi zárás végrehajtása után az irodai kliensnek 30 perc áll rendelkezésére, hogy a zárási adatokat beküldje a szerverre. A 30 perces időablak letelte után a beküldés zárolódik, és azt kizárólag a területi vezető jóváhagyó kódjával/jelszavával lehet feloldani.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (584)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Zárás időpontja, szinkronizáció időpontja.
- **Kimenet / Visszajelzés**: Zárolás feloldása / Jóváhagyás kérése.
- **Validációk és Kényszerek**: Az időablak számítása a zárás leütésétől indul.

### FR-49: NAV lejelentés kötelező mezői
- **Leírás**: A NAV-felé történő lejelentésben biztosítani kell az alábbi kötelező mezők átadását: dátum, tranzakciós összegek devizanemenként, tételek megnevezése, időbélyeg (XML formátum), valamint névre szóló ÁFA-s számla esetén a vevő részletes adatai.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (590)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Tranzakció adatok.
- **Kimenet / Visszajelzés**: Generált XML fájl.
- **Validációk és Kényszerek**: Nincs.

### FR-50: Visszamenőleges helyi adattárolás kötelezettsége
- **Leírás**: A kliens gépeknek a szoftver telepítésétől kezdve minden tranzakciót és eseményt visszamenőleg tárolniuk kell a lokális adatbázisban a pénztárhiányok felderítése és a hatósági megkeresések támogatása érdekében (NFR-10).
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (595)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Tranzakció mentés.
- **Kimenet / Visszajelzés**: Végtelenített helyi tranzakció napló.
- **Validációk és Kényszerek**: A helyi adatbázis tisztítása (purge) tiltott.

### FR-51: Címlet-szintű nyitás és zárás adatszolgáltatás
- **Leírás**: A kliensnek a napi nyitáskor és záráskor kötelezően megkövetelt címletezési adatokat el kell küldenie a központi szerverre, hogy a belső ellenőrök és területi vezetők valós időben láthassák a kassza címlet-összetételét.
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (577)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Címletezési mátrix.
- **Kimenet / Visszajelzés**: Szerveroldali címletjelentés.
- **Validációk és Kényszerek**: Nincs.

### FR-52: Web-alapú / Központi szerveres architektúra megfontolása
- **Leírás**: Meg kell vizsgálni a régi Delphi szoftver kiváltására egy modern webes, böngészőben futtatható vagy Electron-alapú kliensarchitektúra kialakítását, amely közvetlenül a központi adatbázis szerverrel kommunikál (Lásd: TBD-14).
- **Forrás**: `RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx` (596, 605-606)
- **Prio**: Could
- **Csomag/Komponens**: `backend` / `frontend-react`
- **Bemenő adatok**: Architektúra tervek.
- **Kimenet / Visszajelzés**: Architektúra elemzés.
- **Validációk és Kényszerek**: Az offline működést és a periféria-kezelést (pénztárgép, POS) ebben a modellben is biztosítani kell.
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma (SQLite és Postgres Tükör)

A helyi Firebird DB funkcióinak SQLite mirror-ba történő átültetéséhez javasolt sémák.

### Postgres és SQLite táblák:

#### 1. `nav_lejelentes_naplo`
A NAV felé küldött és gyűjtött lejelentések követésére.
- `id` (SERIAL / INTEGER PRIMARY KEY)
- `tranzakcio_id` (VARCHAR(50) UNIQUE NOT NULL)
- `bekuldes_ideje` (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
- `statusz` (VARCHAR(20) NOT NULL DEFAULT 'GYUJTENI') -- FIZIKAI_SIKER, OFFLINE_GYUJTOTT, KEZI_ANYK, HIBA
- `anyk_bizonylat_szam` (VARCHAR(50), Nullable) -- Csak ha kézzel jelentették be
- `xml_adat` (TEXT NOT NULL)
- `hiba_kod` (VARCHAR(20), Nullable)

#### 2. `kassza_zarasok`
A napi zárások és a 30 perces szinkronizációs ablak felügyelete.
- `id` (SERIAL / INTEGER PRIMARY KEY)
- `penztar_kod` (VARCHAR(10) NOT NULL)
- `zaras_datuma` (DATE NOT NULL)
- `zaras_ideje` (TIMESTAMP NOT NULL)
- `bekuldes_ideje` (TIMESTAMP, Nullable)
- `szallitasi_adatok` (TEXT) -- Címlet-szintű adatok JSON-ben
- `jovahagyott_kesleltetes` (BOOLEAN DEFAULT FALSE)
- `jovahagyas_szerzoje` (VARCHAR(50), Nullable) -- Területi vezető ID
</data_structure>

<integration_points>
## Integrációs Pontok és Belső Függőségek
- **Fizikai Online Pénztárgép (NAV)**: Közvetlen hardveres LPT/USB kapcsolat a nyugtanyomtatáshoz és az adóügyi adatok azonnali átadásához (FR-45).
- **NAV ÁNYK szoftver**: Kézi lejelentéshez XML fájlok generálása hálózati kimaradások esetére (FR-46).
- **Kamerás biztonsági szoftver**: Integráció a Java-alapú képrögzítő rendszerrel a tranzakciók vizuális naplózásához (Lásd: TBD-15).
- **Központi Replikációs Modul**: Biztosítja az SQLite táblák (pl. `nav_lejelentes_naplo`) szinkronizációját a központi PostgreSQL szerverrel (FR-41).
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- Kialakítani a kliensoldali SQLite és központi Postgres adatbázis sémáit a NAV naplózáshoz és a zárások követéséhez.
- Telepíteni a NIS2 biztonsági irányelveknek megfelelő VPN és hitelesítési környezeteket (NFR-11).

### Fázis 2: Backend megvalósítás
- Megvalósítani a 30 perces napzárási időkorlát backend-ellenőrzését és a területi vezetői feloldó API-t.
- Elkészíteni az automatikus delta alapú tiltólista szinkronizációs logikát.
- Megírni a NAV XML generátort az előírt kötelező mezőkkel.

### Fázis 3: Frontend megvalósítás
- Implementálni a `penztar-client` alkalmazásban a hálózati kapcsolatvesztés detektálását és az offline üzemmód vizuális jelzését.
- Megvalósítani a vészhelyzeti protokoll felületét (kézi bizonylatok tömeges utólagos rögzítő felülete).
- Elkészíteni a címletező és záró adatokat rögzítő modult.

### Fázis 4: Verifikáció
- Unit teszttel ellenőrizni, hogy a 30 perces napzárási ablak átlépése után a rendszer valóban elutasítja-e az automata beküldést.
- Szimulált net-kiesés során tesztelni, hogy a kliens SQLite táblája sikeresen gyűjti-e a NAV XML fájlokat, és a kapcsolat visszatérése után 24 órán belül megindul-e a feltöltés.
- Tesztelni a delta alapú tiltólista frissítést.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés / Kockázat | Hatás | Leírás |
|---|---|---|---|
| TBD-12 | Raiffeisen banki változás-jelentési adatok | Banki integráció | A bank felé küldendő napi tranzakció-változások és egyenleg-jelentések pontos köre nem ismert. |
| TBD-13 | NAV API részletes dokumentációja | NAV-integráció | A megbeszélésen említett NAV API specifikáció hiányzik a kapott repóból. |
| TBD-14 | Központi szerveres adatbázis megvalósíthatóság | Architektúra | A webes architektúra bevezetése esetén hogyan kezelhető a számlák lokális nyomtatása és a hálózati hiba alatti működés? |
| TBD-15 | Java-alapú kamerás program integrálása | Biztonságtechnika | Szükséges-e a Java kamerás szoftver közvetlen integrációja az új klienssel, vagy megmarad teljesen különálló alkalmazásként? |
| TBD-16 | Régi Firebird adatbázisok migrációs terve | Migráció | A meglévő irodai gépeken tárolt régi Firebird adatok migrálásának pontos forgatókönyve hiányzik. |
| TBD-17 | Blokknyomtató PCEA kártyák és LPT portok kiváltása | Hardver-támogatás | Hogyan kezelje az új kliens a régi párhuzamos portos nyomtatókat modern operációs rendszerek és USB átalakítók mellett? |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [ ] Minden funkcionális követelmény (FR-37-től FR-52-ig) tartalmazza a megfelelő forráshivatkozást.
- [ ] A 30 perces zárási időablak és a 24 órás NAV határidő rögzítésre került.
- [ ] A 6 darab TBD kockázat szerepel a TBD kockázati naplóban.
- [ ] Az offline működést és helyi SQLite tárolást megkövetelő szabályok (FR-47, FR-50) megőrzésre kerültek.
- [ ] Nincs új, a forrásokban nem szereplő hardver vagy technológia megkövetelve.
</verification_checklist>
