# Modul: Régi Delphi valutaprogram — Pénztárak közötti pénzmozgás

<system_context>
## Rendszerkontextus és Háttér
Ez a specifikáció a régi valutaprogram pénztárak, társpénztárak és értéktárak közötti pénzmozgásokért felelős modulját írja le (társpénztár-választó képernyők, pénztárak karbantartása, pénztárközi forgalom és átvétel almenük, szállítási űrlapok).

### Szerepkörök (Roles)
| Szerep | Jogosultság / Feladatkör | RBAC érték |
|---|---|---|
| Pénztáros | Társpénztár kiválasztása, szállítási/átadási űrlapok rögzítése, készlet átvétele/átadása. | TBD |
| Értéktáros / Főértéktáros | Értéktári készletek mozgatása, átvételek és visszavételek kezelése. | TBD |
| Adminisztrátor (pénztár-karbantartás) | Új pénztárak felvétele, meglévők adatainak módosítása, inaktívvá tétele/törlése. | TBD (Lásd: TBD-4) |

### Hatókör (Scope)
#### IN
- Társpénztár-választó dialógusok és az elérhető fiók/technikai pénztár kódok listája.
- Pénztárak karbantartása rács és a kapcsolódó karbantartó műveletek.
- "Pénztárak közötti pénzforgalom főmenüje" / "Pénztárak közötti forgalom főmenüje" almenük szerkezete.
- Szállítás pénztárak között űrlap (társpénztár, szállító, plomba, megjegyzés).
- "Pénz átvétele egy egységtől" almenü struktúrája.

#### OUT
- A könyvelés és tranzakció-végrehajtás konkrét számítási és elszámolási logikája.
- Kezelési díjak átadás-átvételi részletei (lásd `b5-kezeles-cimletezes-engedelyezes.md`).

### Technológiai verem (Tech Stack)
- Pénztári kliensoldal (`penztar-client`)
- Központi hálózati kliens (`kozponti-client`)
- Offline SQLite mirror a társpénztárak listájához és az átmeneti szállítások rögzítéséhez (outbox sync minta a szinkronizáláshoz)
- Postgres központi adatbázis a globális pénztártörzs tárolására
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-PM-01: Társpénztár-választó dialógus felépítése
- **Leírás**: Biztosítani kell egy "VÁLASSZA KI A TÁRSPÉNZTÁRT" című ablakot, amelyben listázva jelennek meg a társpénztárak. Oszlopok: SZÁM, MEGNEVEZÉS. Műveleti gombok: "EZT VÁLASZTOM", "NEM VÁLASZTOK", "ÚJ PÉNZTÁR FELVÉTELE".
- **Forrás**: `Pénztár választása.JPG`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`, `kozponti-client`
- **Bemenő adatok**: Társpénztár törzslista.
- **Kimenet / Visszajelzés**: Választott pénztár kódja és megnevezése.
- **Validációk és Kényszerek**: Nincs.

### FR-PM-02: Társpénztár-lista görgethetőség és kódok (1. rész)
- **Leírás**: A társpénztár-listának görgethetőnek kell lennie (NFR-PM-01), és tartalmaznia kell a numerikus és betűkódos azonosítókat. Megfigyelt és kötelezően kezelendő sorok:
  - "71 GYULA BELVAROS"
  - "50 DEBRECEN ÉRTÉKTÁR"
  - "63 NYÍREGYHÁZI ÉRTÉKTÁR"
  - "0074 TESCO BÉKÉSCSABA"
  - "FRB FORINT MOZGÁS RB"
  - "ERB FIXING VALUTA MOZGÁS RB"
  - "TRB EGYEDI KÖTÉS RB"
  - "76 TER. KÖZÖTTI MOZGÁS RB"
  - "JRB BÉKÉSCSABA BELVÁR"
  - "77 JUTALÉK BEFIZETÉS RB"
  - "MNB GYULA TESCO"
  - "MNB"
- **Forrás**: `Pénztár választása.JPG`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Pénztár adatbázis rekordok.
- **Kimenet / Visszajelzés**: Görgethető rács.
- **Validációk és Kényszerek**: A kódok egyediségét biztosítani kell.

### FR-PM-03: Társpénztár-lista kódok (2. rész)
- **Leírás**: A társpénztár-lista lapozott állapotában megjelenő további kötelező sorok:
  - "TH TÖBBLET-HIÁNY PÉNZTÁR"
  - "78 OROSHÁZA TESCO"
  - "79 SZARVAS TESCO"
  - "105 BÉKÉSCSABA BELVÁROS II."
  - "PRB POS ÁTVÉTEL BANKTÓL"
  - "143 (NEW) PÉCS PLAZA"
  - "WU UJ PÉNZTÁR"
  - "UL WU ELLÁTMÁNY"
  - "TV UTON LÉVŐ PÉNZTÁR"
  - "20 TÉVES KÖNYVELÉS"
  - "145 SZEGEDI ÉRTÉKTÁR"
  - "KAPOSVÁR ÉRTÉKTÁR"
- **Forrás**: `Pénztár választása 2..JPG`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Kiegészítő pénztár rekordok.
- **Kimenet / Visszajelzés**: Megjelenített sorok.
- **Validációk és Kényszerek**: Nincs.

### FR-PM-04: Szűkített társpénztár-lista
- **Leírás**: Speciális kontextusokban (pl. új pénztár felvételéhez kapcsolódóan) csak egy szűkített listát kell biztosítani, amely a következő elemeket tartalmazza: "75 BÉKÉSCSABA ÉRTÉKTÁR", "TH TÖBBLET-HIÁNY PÉNZTÁR", "1 FŐPÉNZTÁR".
- **Forrás**: `Társpénztár kiválasztása új pénztár felvétele.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Pénztártípus szerinti szűrés.
- **Kimenet / Visszajelzés**: Szűrt lista.
- **Validációk és Kényszerek**: Nincs.

### FR-PM-05: Pénztárak karbantartása képernyő felépítése
- **Leírás**: Meg kell jeleníteni a "PÉNZTÁRAK KARBANTARTÁSA" felületet az alábbi oszlopokkal rendelkező táblázatban: PÉNZTÁR (kód), PÉNZTÁR MEGNEVEZÉSE, PÉNZTÁR CIME, TELEFONSZÁM.
- **Forrás**: `Pénztárak karbantartása .jpeg`, `Pénztárak karbantartása 2.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Pénztártörzs lekérdezés.
- **Kimenet / Visszajelzés**: Karbantartó rács.
- **Validációk és Kényszerek**: Nincs.

### FR-PM-06: Pénztár-karbantartás kötelező sorai
- **Leírás**: A karbantartó felületen meg kell jeleníteni legalább a következő egységeket: "105 <FIOK_NEV> (<CIM>, 06XXXXXXXXX)", "75 ÉRTÉKTÁR", "TH TÖBBLET-HIÁNY PÉNZTÁR", "1 FŐPÉNZTÁR".
- **Forrás**: `Pénztárak karbantartása .jpeg`, `Pénztárak karbantartása 2.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Rendszer fiókadatai.
- **Kimenet / Visszajelzés**: Sorok a táblázatban.
- **Validációk és Kényszerek**: Nincs.

### FR-PM-07: Pénztár-karbantartás műveletek
- **Leírás**: Biztosítani kell az alábbi műveleti gombokat: "ADATOK MÓDOSÍTÁSA", "ÚJ PÉNZTÁR FELVÉTELE", "PÉNZTÁR TÖRLÉSE", "VISSZA A FŐMENÜRE".
- **Forrás**: `Pénztárak karbantartása .jpeg`, `Pénztárak karbantartása 2.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Kattintási események.
- **Kimenet / Visszajelzés**: Megfelelő karbantartó dialógusok.
- **Validációk és Kényszerek**: Csak supervisor/adminisztrátori szerepkörben engedélyezettek a módosító/törlő műveletek (NFR-PM-03, TBD-4).

### FR-PM-08: Pénztárak közötti pénzforgalom főmenüje
- **Leírás**: A főmenüből megnyitható "Pénztárak közötti pénzforgalom főmenüje" almenüben az alábbi választási lehetőségeket kell biztosítani: "Pénz átvétele egy egységtől", "Pénz átadása egy egységnek", "Kezelési díjak átadása-átvétele", "Horvát kuna beküldése" (TBD-5), "E-kereskedelem pénzforgalma" (TBD-5), "Vissza a valutaprogram főmenüjére".
- **Forrás**: `Pénztárak közötti pénzforgalom főmenüje.jpeg`, `Pénztárak közötti forgalom főmenüje.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Menüpont választás.
- **Kimenet / Visszajelzés**: Megfelelő alfolyamat indítása.
- **Validációk és Kényszerek**: Nincs.

### FR-PM-09: Szállítás pénztárak között űrlap
- **Leírás**: Meg kell jeleníteni a szállítási űrlapot a következő kötelező mezőkkel: TÁRSPÉNZTÁR (kód + megnevezés), SZÁLLÍTÓ NEVE, PLOMBASZÁM, MEGJEGYZÉS; valamint a "KÖNYVELHETŐ" és "MÉGSEM" gombokat.
- **Forrás**: `Szállítás pénztárak között menü.jpeg`, `Pénztárak közötti szállításhoz.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Szállító neve, plomba azonosítója, megjegyzés szöveg (Lásd: TBD-2).
- **Kimenet / Visszajelzés**: Pénzátadási tranzakció elmentése és "TV" (Úton lévő) státusz beállítása a készleten.
- **Validációk és Kényszerek**: A szállítás nem könyvelhető, ha a Szállító neve vagy a Plombaszám mező üres (NFR-PM-02).

### FR-PM-10: Pénz átvétele egy egységtől almenü
- **Leírás**: A "Pénz átvétele egy egységtől" almenüpont kiválasztásakor az alábbi lehetőségeket kell nyújtani: "Pénz átvétele az értéktártól", "Teljes készlet visszavétele az értéktártól", "Horvát kuna beküldése", "E-kereskedelem pénzforgalma", "Vissza a valutaprogram főmenüjére". (Egy további inaktív/szürkített sor: "Kezelési díjak átadása-átvétele").
- **Forrás**: `Pénz átvétele egy egységtől menü .jpeg`, `Pénztárátvétele egy egységtől menü2.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Menüpont választás.
- **Kimenet / Visszajelzés**: Értéktári átvételi folyamat indítása.
- **Validációk és Kényszerek**: Nincs.

### FR-PM-11: Szállítási űrlap társpénztár előkitöltése
- **Leírás**: A szállítási űrlapnak automatikusan tartalmaznia kell a kiválasztott társpénztár azonosítóját és nevét, előre kitöltött, nem módosítható formában (pl. "TÁRSPÉNZTÁR: 75 BÉKÉSCSABA ÉRTÉKTÁR").
- **Forrás**: `Szállítás pénztárak között menü.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Korábban kiválasztott társpénztár rekord.
- **Kimenet / Visszajelzés**: Előre kitöltött mező a felületen.
- **Validációk és Kényszerek**: Az értéknek egyeznie kell a választó ablakban kiválasztottal.

### FR-PM-12: Karbantartó felület funkciógombjai és állapotsora
- **Leírás**: A "PÉNZTÁRAK KARBANTARTÁSA" ablak megnyitott állapotában is meg kell jeleníteni az alsó funkcióbillentyű sor parancsait (F1 ÁRFOLYAM ... Esc KILÉPÉS), valamint a kiegészítő információs blokkokat ("FUTÓFÉNY", "KÖRLEVELEK", "PÉNZTÁR SZÜNET", "NÉVTELEN BEJELENTÉS", "Napi stornózott bizonylat darab").
- **Forrás**: `Pénztárak karbantartása .jpeg`, `Pénztárak karbantartása 2.jpeg`
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`
- **Validációk és Kényszerek**: Nincs.

### FR-PM-13: Szállító és Plombaszám szigorú validációja
- **Leírás**: A pénztárak és értéktárak közötti szállításoknál (`TransferPage`, `ShipmentNewPage`) megadott szállító nevére és plombaszámára az alábbi validációs szabályok vonatkoznak:
  - **Szállító neve** (`carrierName` / `szallito`): kötelező mező, legfeljebb 128 karakter hosszú lehet.
  - **Plombaszám** (`sealNumber` / `plombaszam`): kötelező mező, legfeljebb 64 karakter hosszú lehet, és kizárólag alfanumerikus karaktereket (betűket, számokat), kötőjelet (`-`) és perjelet (`/`) tartalmazhat (mintázat: `^[A-Za-z0-9\-/]+$`).
  - Ezt a backend DTO szinten (`@NotBlank`, `@Size`, `@Pattern` annotációkkal), a DB szinten (`CHECK` constraint) és a frontend bevitelnél is ellenőrizni kell.
- **Forrás**: 2026-06-02 plomba audit
- **Prio**: Magas (P1)
- **Csomag/Komponens**: backend / penztar-client / frontend-react
- **Bemenő adatok**: Szállító neve és plombaszám
- **Kimenet / Visszajelzés**: Validáció lefutása, sikertelen bevitel esetén 400-as vagy kliensoldali hibaüzenet
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma (SQLite és Postgres Tükör)

### Postgres és SQLite táblák:

#### 1. `penztarak`
A szervezeti egységek és technikai gyűjtők táblája.
- `kod` (VARCHAR(10) PRIMARY KEY) -- Pl. '105', '75', 'TH', 'TV', 'FRB'
- `megnevezes` (VARCHAR(100) NOT NULL)
- `cim` (VARCHAR(200), Nullable)
- `telefonszam` (VARCHAR(50), Nullable)
- `tipus` (VARCHAR(20) NOT NULL DEFAULT 'FIZIKAI') -- FIZIKAI, ERTEKTAR, TECHNIKAI
- `aktiv` (BOOLEAN NOT NULL DEFAULT TRUE)

#### 2. `penztarkozi_szallitasok`
A szállítások és átadás-átvételek követése.
- `id` (SERIAL / INTEGER PRIMARY KEY)
- `bizonylatszam` (VARCHAR(50) UNIQUE NOT NULL) -- Pl. FF prefixszel
- `forras_penztar` (VARCHAR(10) NOT NULL REFERENCES penztarak(kod))
- `cel_penztar` (VARCHAR(10) NOT NULL REFERENCES penztarak(kod))
- `szallito_neve` (VARCHAR(100) NOT NULL)
- `plombaszam` (VARCHAR(50) NOT NULL)
- `megjegyzes` (TEXT, Nullable)
- `statusz` (VARCHAR(20) NOT NULL DEFAULT 'UTON') -- UTON (TV), ATVEVE, VISSZAUTASITVA
- `inditas_ideje` (TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)
- `fogadas_ideje` (TIMESTAMP, Nullable)
</data_structure>

<integration_points>
## Integrációs Pontok és Belső Függőségek
- **Főmenü navigáció**: A főmenü "PÉNZTÁRAK KÖZÖTTI ÁTADÁS - ÁTVÉTEL" parancsának kezelése (FR-PM-08, FR-PM-10).
- **Készletkezelő modul**: Pénz átadásakor a forráskassza egyenlegének csökkentése és úton lévő (TV) státuszba helyezése; átvétel lekönyvelésekor a célkassza egyenlegének növelése.
- **Supervisor jóváhagyás**: A pénztártörzs karbantartásához és törléséhez szükséges adminisztratív jogosultság ellenőrző szolgáltatás (FR-PM-07).
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- Elkészíteni a kezdeti adatbázis-migrációs szkriptet, amely seedeli a `penztarak` táblát a specifikációban található 25 db megfigyelt kóddal és megnevezéssel.
- Létrehozni a szállítási űrlap drótvázát.

### Fázis 2: Backend megvalósítás
- Megírni a pénztárközi szállítás indításának (átadás) és lezárásának (átvétel) API logikáját.
- Biztosítani az atomi tranzakció-kezelést a készlet levonásakor és hozzáadásakor.
- Implementálni a helyi SQLite szinkronizációs mechanizmust (outbox pattern) az offline rögzített szállítások beküldésére.

### Fázis 3: Frontend megvalósítás
- Megvalósítani a társpénztár-választó és a karbantartó rács felületét.
- Integrálni a billentyűzet-alapú navigációt a listákban.
- Megírni a szállítási űrlap kötelező mezőinek frontend-szintű validációját (KÖNYVELHETŐ gomb engedélyezése).

### Fázis 4: Verifikáció és Tesztelés
- E2E teszttel ellenőrizni a folyamatot: Pénztár kiválasztása → Szállítás rögzítése plomba számmal → Átadás elmentése ("TV" státuszú készlet létrejötte) → Célpénztár oldali átvétel jóváhagyása.
- Validálni, hogy nem-adminisztrátor felhasználó nem tudja elérni a pénztár-törlési és módosítási funkciókat.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| ID | Kérdés / Kockázat | Hatás | Leírás |
|---|---|---|---|
| TBD-1 | Menüelnevezés duplikációja | Felhasználói felület | A "Pénztárak közötti pénzforgalom főmenüje" és a "Pénztárak közötti forgalom főmenüje" feliratok azonos menüket takarnak-e, vagy van eltérés a funkcióikban? |
| TBD-2 | Szállítási űrlap mezőinek validálása | Adatminőség | **RESOLVED**: A szállító neve max 128 karakter. A plombaszám max 64 karakter és szigorúan alfanumerikus + kötőjel + perjel (`^[A-Za-z0-9\-/]+$`). |
| TBD-3 | Technikai és egyéb speciális pénztárak szerepe | Üzleti logika | A listában látható speciális technikai kódok (pl. 20 Téves könyvelés, JRB Jutalék befizetés stb.) pontos használati és elszámolási szabályai tisztázandóak. |
| TBD-4 | Karbantartási funkciók jogosultsága (RBAC) | Biztonság | Ki vehet fel, törölhet vagy módosíthat társpénztárat? Szükséges-e supervisor jelszavas feloldás? |
| TBD-5 | Kuna (HRK) és e-kereskedelmi mozgások | Hatókör | Aktív funkció-e még a Horvát kuna beküldése (tekintve, hogy a HRK kivezetésre került) és az e-kereskedelmi forgalom? |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [ ] Minden funkcionális követelmény (FR-PM-01-től FR-PM-12-ig) rendelkezik képi forrás-hivatkozással.
- [ ] A 25 db egyedi társpénztár/technikai kód és név rögzítésre került.
- [ ] A 5 darab TBD nyitott kérdés pontosan dokumentálva van a kockázati naplóban.
- [ ] Nem lettek önkényesen új mezők vagy ellenőrzési logikák bevezetve.
- [ ] A kötelező plombaszám és szállítónév kitöltési szabály (NFR-PM-02) megőrzésre került.
</verification_checklist>
