# Modul: Régi Delphi valutaprogram — Pénztárállás, bizonylat-szűrés, listák

<system_context>
## Rendszerkontextus és Háttér
Ez a specifikáció a régi valutaprogram kimutatásait és lekérdező felületeit tartalmazza, beleértve a pillanatnyi pénztárállás táblázatot, a bizonylat-szűrő panelt, az összesített pénztárforgalom időszak-választóját, valamint a "Különféle listák" és "Egyéb feladatok" menüstruktúráit.

### Szerepkörök (Roles)
| Szerep | Jogosultság / Feladatkör | RBAC érték |
|---|---|---|
| Pénztáros | Pillanatnyi pénztárállás megtekintése és nyomtatása, napi bizonylatok szűrése, alapvető riportok nyomtatása. | TBD |
| Vezető / Belsőellenőr | Összesített pénztárforgalmi kimutatások, statisztikai és időszaki listák lekérdezése. | TBD |
| Adminisztrátor | Rendszerbeállítások kezelése ("Egyéb feladatok"), pénztárgép-parancsok küldése, ügyféltörzs karbantartása. | TBD |

### Hatókör (Scope)
#### IN
- Pillanatnyi pénztárállás táblázat felépítése (oszlopok és sorok), valamint az alsó funkciógombok.
- Bizonylatok szűrése dialógus (rádiógombos opciók és a naptár/hónap kapcsolók).
- Összesített pénztárforgalom lekérdező ablakának felépítése (időszak-választás).
- "Különféle listák" menüpontok listája.
- "Egyéb feladatok" menü és annak pénztárgép almenüpontjai.

#### OUT
- A listák és riportok fizikai nyomtatási képe (PDF vagy papíralapú formátumok részletes elrendezése).
- A "Különféle beállítások" vagy a "Pénztárgép utasításai" mögötti részletes dialógusok és belső konfigurációs sémák.

### Technológiai verem (Tech Stack)
- Pénztári kliens (`penztar-client`)
- Helyi SQLite mirror az offline kimutatásokhoz és a helyben tárolt tranzakciókból végzett valós idejű készlet-aggregációhoz (offline pénztárállás lekérdezés)
- Hálózati POS integráció (OTP POS parancsok)
- Online Pénztárgép (AEE) soros/COM portos interfész
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-PA-01: Pillanatnyi pénztárállás táblázat felépítése
- **Leírás**: "A PILLANATNYI PÉNZTÁRÁLLÁS KIMUTATÁSA" felületen meg kell jeleníteni a pénztár egyenlegét az alábbi oszlopokkal rendelkező rácsban: VNEM, VALUTA NEVE, NYITÓ, BEVÉTEL, KIADÁS, KEZ-I DÍJ, ZÁRÓ.
- **Forrás**: `Pillanatnyi pénztárállás kimutatása.jpeg`, `Pillanatnyi pénztár állás kimutatása2 .jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Pénztár készlet aggregáció.
- **Kimenet / Visszajelzés**: Készletjelentő táblázat.
- **Validációk és Kényszerek**: Nincs.

### FR-PA-02: Pénztárállás valutái és alapértelmezett sorai
- **Leírás**: A táblázatban valutánként egy sort kell biztosítani. A rendszernek támogatnia és megfigyelten kezelnie kell legalább a következő valutákat:
  - BGN (BOLGAR LEVA)
  - CHF (SVAJCI FRANK)
  - CZK (CSEH KORONA)
  - EUR (EURO)
  - HUF (MAGYAR FORINT)
  - ILS (IZRAELI SEKEL)
  - PLN (LENGYEL ZLOTYI)
  - RON (ÚJ ROMÁN LEI)
  - RSD (SZERB DINAR)
  - TRY (TÖRÖK LÍRA)
  - USD (USA DOLLAR)
- **Forrás**: `Pillanatnyi pénztárállás kimutatása.jpeg`, `Pillanatnyi pénztár állás kimutatása2 .jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Valutatörzs adatok.
- **Kimenet / Visszajelzés**: Valutasorok a táblázatban.
- **Validációk és Kényszerek**: Nincs.

### FR-PA-03: Záró egyenleg kalkuláció és formázás
- **Leírás**: A ZÁRÓ oszlop értékét a Nyitó + Bevétel - Kiadás (± Kezelési díj) képlettel kell kiszámítani. A HUF sort zöld színnel kell kiemelni, a devizasorok Záró értékeit pedig piros színnel kell formázni (Lásd: TBD-2).
- **Forrás**: `Pillanatnyi pénztárállás kimutatása.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Tranzakciós összesítések.
- **Kimenet / Visszajelzés**: Kiszámított záró készletérték.
- **Validációk és Kényszerek**: Ha a forgalom üres (pl. bevételek/kiadások hiánya), a záró értéknek meg kell egyeznie a nyitó értékkel.

### FR-PA-04: Pénztárállás funkciógombjai
- **Leírás**: A pénztárállás táblázat alján biztosítani kell az alábbi gombokat: "PILLANATNYI ÁLLÁS KINYOMTATÁSA", "KEZELÉSI DÍJ NYOMTATÁSA", "VISSZA A FŐMENÜRE (Escape)".
- **Forrás**: `Pillanatnyi pénztárállás kimutatása.jpeg`, `Pillanatnyi pénztár állás kimutatása2 .jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Kattintás vagy Escape billentyű leütése.
- **Kimenet / Visszajelzés**: Hőnyomtatás elindítása vagy visszalépés.
- **Validációk és Kényszerek**: Nincs.

### FR-PA-05: Bizonylatok szűrése dialógus
- **Leírás**: A "BIZONYLATOK SZŰRÉSE" dialógusban rádiógombos formában (egyszerre csak egy opció engedélyezésével, NFR-PA-02) kell felkínálni a szűrési lehetőségeket:
  - "Szűrés kikapcsolva"
  - "Csak ügyfeles bizonylatok"
  - "Csak vételi bizonylatok"
  - "Csak eladási bizonylatok"
  - "Csak konverziós bizonylatok"
  - "Csak pénz-átadási bizonylatok"
  - "Csak pénz átvételi bizonylatok"
  - "Csak stornózott bizonylatok"
  - Valamint egy "Vissza" gomb.
- **Forrás**: `Bizonylatok szűrése.jpeg`, `Bizonylatok szűrése2.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Szűrési feltétel kiválasztása.
- **Kimenet / Visszajelzés**: Frissített szűrt bizonylat-lista.
- **Validációk és Kényszerek**: Egyszerre kizárólag egy rádiógomb lehet aktív.

### FR-PA-06: Bizonylat szűrés idő-kapcsolói
- **Leírás**: A bizonylat-szűrő ablak alsó részén el kell helyezni egy választókapcsolót: "A HÓNAP ÖSSZES BIZONYLATA" vagy "CSAK A VÁLASZTOTT NAP".
- **Forrás**: `Bizonylatok szűrése.jpeg`, `Bizonylatok szűrése2.jpeg`
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Kiválasztott időintervallum mód.
- **Kimenet / Visszajelzés**: Bizonylatlista szűrése idő szerint.
- **Validációk és Kényszerek**: A napi szűrésnél a pénztár naptárjából kell kiválasztani a célnapot.

### FR-PA-07: Bizonylat szűrő ablak szerkezete
- **Leírás**: A bizonylatok szűrése ablak bal oldalán a bizonylatok listáját kell megjeleníteni oszlopfejlécekkel (Blokkfejek, DÁTUM, BIB, BLOKK kódok). A jobb oldalon az ügyfél-adat panelt, a "NAV NYUGTA" jelölőt és a bizonylatszámot (pl. "1948/00001") kell megjeleníteni.
- **Forrás**: `Bizonylatok szűrése.jpeg`, `Bizonylatok szűrése2.jpeg`
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Bizonylat részletes adatok.
- **Kimenet / Visszajelzés**: Bizonylat részletező adatlap.
- **Validációk és Kényszerek**: Nincs.

### FR-PA-08: Összesített pénztárforgalom időszak-választó
- **Leírás**: Az "ÖSSZESITETT PÉNZTÁRFORGALOM" ablakban meg kell jeleníteni az időszak megadására szolgáló felületet:
  - Cím: "ADJA MEG A KÉRT IDŐSZAKOT"
  - Legördülő mezők: ÉV (pl. 2024), HÓNAP (pl. MÁRCIUS)
  - Intervallum mezők: naptól (pl. 1) - napig (pl. 31)
  - Műveleti gombok: "IDŐSZAK RENDBEN", "CSAK A MAI NAP", "MÉGSEM".
- **Forrás**: `Összesített pénztárforgalom lekérdező menü.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Év, Hónap, Kezdőnap, Zárónap.
- **Kimenet / Visszajelzés**: Kiválasztott időszak átadása a jelentés-generátornak.
- **Validációk és Kényszerek**: A végnap nem lehet kisebb a kezdőnapnál. Alapértelmezésben a teljes hónap van kijelölve (NFR-PA-03).

### FR-PA-09: Különféle listák menüje
- **Leírás**: Biztosítani kell a "KÜLÖNFÉLE LISTÁK" menüt a következő pontokkal:
  - "KIADOTT BIZONYLATOK LISTÁI"
  - "PÉNZFORGALOM A PÉNZTÁRAK FELÉ"
  - "TRB FORGALMI LISTÁK" (Lásd: TBD-4)
  - "ELADÁSI - VÉTELI STATISZTIKA"
  - "HAVI TABLÓK ÁTTEKINTÉSE" (szürkített/inaktív, Lásd: TBD-3)
  - "PILLANATNYI KÉSZLETEK" (szürkített/inaktív, Lásd: TBD-3)
  - "HAVI KEDVEZMÉNYEK LISTÁJA" (szürkített/inaktív, Lásd: TBD-3)
  - "DEKÁD VAGY NAPIZÁRÁS KÖNYVELÉSE"
  - "KEZELÉSI DÍJAK LISTÁJA"
  - Valamint a "MÉGSEM" kilépő gombot.
- **Forrás**: `Különféle listák menü .jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Menüpont választás.
- **Kimenet / Visszajelzés**: Megfelelő riport képernyő.
- **Validációk és Kényszerek**: Az inaktív pontok nem kattinthatóak.

### FR-PA-10: Egyéb feladatok menü (1. állapot)
- **Leírás**: Biztosítani kell az "EGYÉB FELADATOK" adminisztrációs menüt az alábbi tételekkel: "KÜLÖNFÉLE BEÁLLÍTÁSOK", "PÉNZTÁRGÉP UTASÍTÁSAI", "OTP POS TERMINÁL PARANCSOK", "ADATLAPOK KEZELÉSE", "ÜGYFÉL KARBANTARTAS", "KILÉPÉS AZ EGYÉB FELADATOKBÓL".
- **Forrás**: `Egyéb feladatok menü.jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Menüpont választás.
- **Kimenet / Visszajelzés**: Rendszerbeállítások vagy almenük megnyitása.
- **Validációk és Kényszerek**: Megnyitásához adminisztrátori vagy supervisor jogosultság szükséges.

### FR-PA-11: Egyéb feladatok - Pénztárgép almenü (2. állapot)
- **Leírás**: Az "EGYÉB FELADATOK" menüben a Pénztárgép opció kiválasztásakor az alábbi almenü tételeket kell megjeleníteni:
  - "KÜLÖNFÉLE BEÁLLÍTÁSOK"
  - "PÉNZTÁRGÉP VALUTÁINAK TÖRLÉSE"
  - "VALUTÁK BETÖLTÉSE A PÉNZTÁRGÉPBE"
  - "NAPNYITÁS A PÉNZTÁRGÉPEN"
  - "NAPZÁRÁS A PÉNZTÁRGÉPEN"
  - "PÉNZTÁRGÉP COM-PORTJÁNAK ÁLLITÁSA"
  - "KILÉPÉS AZ EGYÉB FELADATOKBÓL"
- **Forrás**: `Egyéb feladatok menü(1).jpeg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Almenüpont választás.
- **Kimenet / Visszajelzés**: Parancs kiküldése a fizikai pénztárgép (AEE) felé (Lásd: TBD-5).
- **Validációk és Kényszerek**: Sikertelen pénztárgép kapcsolat esetén hibaüzenet megjelenítése.

- **Validációk és Kényszerek**: Nincs.

### FR-PA-13: Üres értéktár kártya valutái (FK-007)
- **Leírás**: Az Országos készlet oldalon (`/cashier-stocks`) a területi értéktárak kártyáin akkor is meg kell jeleníteni mind a 22 aktív valutát 0 egyenleggel, ha az adott értéktárhoz nincs egyetlen készletsor sem az `/inventory/stock` válaszában.
  - Ha a készletválaszban nincs adat az értéktárra, a frontendnek a központi `/currencies` végpont aktív valutái alapján (kizárva az olyan inaktív devizákat, mint a `TST`, `DKK`, `NOK`, `SEK`, `HRK`, `BGN`, `RCH`) 0 egyenlegű valutatételeket kell injektálnia.
  - Ezzel elkerülhető a hibás `0 valuta` felirat a kártyákon, amit az üresen injektált értéktár-kártyák okoznának.
- **Forrás**: FK-007 audit
- **Prio**: Magas (P1)
- **Csomag/Komponens**: frontend-react
- **Bemenő adatok**: Aktív valuták listája és iroda metaadatok
- **Kimenet / Visszajelzés**: 22 valutasoros értéktár kártya 0-s egyenlegekkel

### FR-PA-14: BR105 iroda láthatósága
- **Leírás**: A `BR105` (Békéscsaba Belváros 2) fiók országos készletben történő helyes megjelenítéséhez és területi csoportosításához a `region` és `region_code` mezők megléte kötelező. Ezt a `V250__branch_sync_br105...sql` migráció biztosítja. Bármilyen további adatmódosítás előtt adatdiagnosztikai lekérdezéssel kell igazolni az adatbázis állapotát, a `vault_territory_id` mező vak pótlása tilos.
- **Forrás**: FK-007 audit BR105 pontja
- **Prio**: Közepes (P2)
- **Csomag/Komponens**: backend / db
- **Bemenő adatok**: Adatbázis diagnosztika
- **Kimenet / Visszajelzés**: Helyes területi besorolás
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma (SQLite és Postgres Tükör)

A lekérdezések nem igényelnek új táblákat, a meglévő bizonylat és tranzakciós táblákból aggregálódnak.

### Szűrési és Lekérdezési sémák:

#### 1. `bizonylat_szures_preferenciak` (SQLite)
A helyi bizonylatkereső felület szűrési preferenciáinak lokális mentésére.
- `id` (INTEGER PRIMARY KEY)
- `alkalmazott_id` (VARCHAR(50))
- `aktualis_szuro` (VARCHAR(50)) -- PL: 'MINDEN', 'UGYFELES', 'VETEL', 'ELADAS', 'KONVERZIO', 'SZTORNO'
- `ido_tartomany` (VARCHAR(20)) -- PL: 'HONAP', 'NAP'
</data_structure>

<integration_points>
## Integrációs Pontok és Belső Függőségek
- **Online Pénztárgép (AEE)**: A pénztárgép nyitási, zárási, valuta-törlési és betöltési parancsainak kezelése a COM porton keresztül (FR-PA-11).
- **OTP POS Terminál**: POS terminál parancsok végrehajtása (FR-PA-10).
- **NAV API / Offline naplózó**: A bizonylat listánál jelzett NAV nyugta adatok lekérdezése (FR-PA-07).
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- Előkészíteni a pillanatnyi pénztárállás táblázatos megjelenítésének felületi sablonját (zöld HUF és piros devizasorok).
- Megtervezni a bizonylatszűrő rádiógombos űrlapot.

### Fázis 2: Backend megvalósítás
- Megírni a valutánkénti készlet-aggregációs logikát (Nyitó + Bevételek - Kiadások) napra és időszakra.
- Kialakítani a bizonylatok szűrésére szolgáló adatbázis-lekérdező API-t a különböző típus-szűrők támogatásával (ügyfeles, vételi, eladási stb.).

### Fázis 3: Frontend megvalósítás
- A `penztar-client` felületén elkészíteni a Pillanatnyi Pénztárállás, Bizonylatok szűrése és az Összesített pénztárforgalom ablakait.
- Lekötni az Escape gombot a visszalépéshez és az F1-F12 billentyűzet-parancsokat.
- Megvalósítani a pénztárgép (COM port) parancsküldő frontend gombjait az Egyéb feladatok almenüben.

### Fázis 4: Verifikáció és Tesztelés
- Unit tesztekkel ellenőrizni, hogy a Záró összeg számítása a különböző tranzakciós történetekkel matematikailag konzisztens-e.
- Ellenőrizni, hogy a rádiógombos bizonylat-szűrés valóban a megfelelő alhalmazt adja-e vissza.
- Verifikálni az inaktív/szürkített menüpontok működésképtelenségét.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| ID | Kérdés / Kockázat | Hatás | Leírás |
|---|---|---|---|
| TBD-1 | Pénztárállás forgalmi oszlopok kitöltöttsége | Adatmegjelenítés | Mikor és hogyan frissülnek a bevételek és kiadások oszlopai a pillanatnyi pénztárállásban? (A képen ezek üresek). |
| TBD-2 | Piros-zöld színkódolás logikája | Felhasználói felület | Miért zöld a HUF sor és miért piros az összes többi deviza a záró egyenlegnél? (Egyszerű vizuális elkülönítés vagy limit átlépés jele?). |
| TBD-3 | Szürkített listaelemek aktiválása | Hatókör | Mi az oka annak, hogy a Havi tablók, Pillanatnyi készletek és a Kedvezmények listája le van tiltva a képen? Mikor válnak elérhetővé? |
| TBD-4 | TRB forgalmi listák jelentése | Üzleti riportok | Mit jelent a TRB rövidítés ebben a kontextusban, és milyen egyedi adatokat tartalmaz a TRB forgalmi jelentés? |
| TBD-5 | Pénztárgép és POS kommunikáció | Hardver-integráció | Milyen konkrét protokollon és COM-port driveren keresztül kommunikál a rendszer a fizikai online pénztárgéppel és az OTP POS terminállal? |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [ ] Minden funkcionális követelményhez (FR-PA-01-től FR-PA-12-ig) hozzá van rendelve a megfelelő képi forrás-dokumentum.
- [ ] A 11 db alapvető valuta (BGN, CHF, CZK, EUR, HUF stb.) rögzítésre került.
- [ ] Az 5 darab TBD kérdés pontosan dokumentálva van a TBD logban.
- [ ] A rádiógombos bizonylat-szűrés kizárólagossági szabálya (NFR-PA-02) megőrzésre került.
- [ ] Nem lettek önkényesen új funkciók kitalálva a menük leírásában.
</verification_checklist>
