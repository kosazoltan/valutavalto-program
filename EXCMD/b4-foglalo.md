# Modul: Foglaló (ügyfél-előleg) felvétele és visszafizetése

<system_context>
## Rendszerkontextus és Háttér
A pénztáros rögzíti a devizaügyletre vonatkozó ügyfél-foglalót (előleget), kinyomtatja a Foglaló átvételi bizonylatot, majd teljesítéskor vagy meghiúsuláskor a foglalót beszámítja vagy visszafizeti.

### Szerepkörök (Roles)
| Szerep | Jogosultság / Feladatkör | RBAC érték |
| --- | --- | --- |
| Pénztáros | Foglaló felvétele, bizonylat nyomtatás, visszafizetés rögzítése. A bizonylaton "penztaros" aláírással szerepel. | `ROLE_CASHIER` |
| Supervisor | Jogosult a 4. sztornótól kezdve a jóváhagyásra, valamint az 50M HUF feletti nagyértékű ügyletek engedélyezésére és a kétszeres visszafizetés jóváhagyására. | `ROLE_SUPERVISOR` |
| Ügyfél | Aláíróként jelenik meg a bizonylaton (nem rendszer-szereplő). | n/a |

### Hatókör (Scope)
#### IN
- Foglaló átvétele: ügyfél-azonosítás, rendelt összeg/deviza, árfolyam, foglaló összege, ügylet határideje, foglaló befizetésének napja.
- Foglaló átvételi bizonylat nyomtatása (két aláírás: pénztáros + ügyfél).
- Foglaló visszafizetése / rendezése: kifizetés bizonylatszáma, átvett foglaló összege, foglaló rendezés napja, beszámítás az aktuális napi árfolyamon.
- Tranzakció típusa: VÉTEL (a docx alapján: "FOGLALOT VETT FEL EGY PENZTAR", Tranz. tipusa: VETEL).
- Pénztár (kassza) azonosítóhoz kötés (docx: "Penztar: 105").
- AML/Pmt. küszöb-ellenőrzések: 50M HUF feletti pénzeszköz-forrás igazolási szabályok és banki bizonylatok (slips) életkori korlátai.

#### OUT
- A teljesítő (fő) devizaügylet maga (külön modul) — a kapcsolódási pontot a bizonylatszámok rögzítése biztosítja.
- Kétszeres visszafizetés jogi vitás rendezése (a rendszer csak a kifizetés bizonylatolását támogatja).

### Technológiai verem (Tech Stack)
- Pénztári kliensoldal (`penztar-client`)
- Helyi offline SQLite mirror támogatás az offline rögzítéshez és nyomtatáshoz
- Postgres adatbázis a központi adatok és a szinkronizáció számára
- ESC/POS alapú hőnyomtatás szalagformátumban
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-1: Kassza azonosító megadása
- **Leírás**: A foglaló felvételéhez kötelező megadni a tranzakciót rögzítő pénztár (kassza) azonosítót.
- **Forrás**: `Segédanyagok Valuta/Foglaló felvétele.docx` ("Penztar : 105")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Pénztár ID (kassza azonosító).
- **Kimenet / Visszajelzés**: Beviteli mező / Rendszer-snapshot.
- **Validációk és Kényszerek**: Az azonosítónak létező aktív pénztárhoz kell tartoznia.

### FR-2: Rendelés napjának rögzítése
- **Leírás**: A foglaló rögzítésekor meg kell adni a rendelés leadásának napját.
- **Forrás**: `Segédanyagok Valuta/Foglaló felvétele.docx` ("Rendeles napja: 2024.03.15")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Dátum.
- **Kimenet / Visszajelzés**: Rögzített rendelési dátum.
- **Validációk és Kényszerek**: Nem lehet jövőbeli dátum.

### FR-3: Rendelt összeg rögzítése devizában
- **Leírás**: Rögzíteni kell a megrendelt devizaösszeget és a devizanemet.
- **Forrás**: `Segédanyagok Valuta/Foglaló felvétele.docx` ("Rendelt osszeg: 10.000 EUR")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Devizaösszeg, devizanem kód.
- **Kimenet / Visszajelzés**: Megrendelt deviza tétel.
- **Validációk és Kényszerek**: Pozitív egész/tört érték, érvényes devizakód.

### FR-4: Árfolyam és egység rögzítése
- **Leírás**: Rögzíteni kell a megállapodott árfolyamot az egység feltüntetésével (pl. 100 EUR/Ft).
- **Forrás**: `Segédanyagok Valuta/Foglaló felvétele.docx` ("Arfolyam: 38500 (100 EUR/ Ft)")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Árfolyamérték, árfolyam-egység.
- **Kimenet / Visszajelzés**: Rögzített árfolyam paraméterek.
- **Validációk és Kényszerek**: Pozitív érték.

### FR-5: Tranzakció típusának beállítása (Vétel)
- **Leírás**: A foglaló felvételét rögzítő tranzakció típusának automatikusan "VÉTEL"-nek kell lennie.
- **Forrás**: `Segédanyagok Valuta/Foglaló felvétele.docx` ("Tranz. tipusa : VETEL", "FOGLALOT VETT FEL EGY PENZTAR")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Nincs (a rendszer automatikusan állítja be).
- **Kimenet / Visszajelzés**: Tranzakció típus jelölése.
- **Validációk és Kényszerek**: Konstans érték.

### FR-6: Bizonylat fejléc (FOGLALO ATVETELE)
- **Leírás**: A Foglaló átvételi bizonylat fejlécében a "FOGLALO ATVETELE" feliratnak kell szerepelnie.
- **Forrás**: `Foglaló bizonylatok.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Nincs (statikus sablonelem).
- **Kimenet / Visszajelzés**: Nyomtatott fejléc.
- **Validációk és Kényszerek**: Jól látható, hangsúlyos megjelenítés.

### FR-7: Ügyfél-azonosító adatok rögzítése és megjelenítése
- **Leírás**: A bizonylaton kötelező feltüntetni az ügyfél személyes adatait: ügyfél neve, anyja neve, szül. hely, szül. idő, okmánytípus, okmányszám, állampolgárság.
- **Forrás**: `Foglaló bizonylatok.jpg` ("Ugyfel neve: <NEV>", "Anyja neve: <ANYJA_NEVE>", "Szul-i hely: <SZUL_HELY>", "Szul-i ido: <SZUL_DATUM>", "Okmanytipus: SZIG", "Okmany szam: <OKMANY_SZAM>", "Allampolgar: MAGYAR")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: KYC profil adatok.
- **Kimenet / Visszajelzés**: Ügyféladatok blokk a bizonylaton.
- **Validációk és Kényszerek**: Okmányszám formátum-ellenőrzés, kötelező kitöltöttség.

### FR-8: Foglaló tranzakció részleteinek megjelenítése
- **Leírás**: A bizonylaton meg kell jeleníteni: a bizonylat számát, a rendelt (mért) összeget és a devizanemet, ennek Forint-értékét, az ügylet határidejét, a befizetett foglaló összegét (HUF) és a befizetés dátumát.
- **Forrás**: `Foglaló bizonylatok.jpg` ("Bizonylat szama: <BIZONYLAT_SZAM>", "...elt osszeg: 100.000 JPY", "ennek ft. erteke: 254.000 HUF", "Ugylet hatarideje: 2024.10.24", "Foglalo osszege: 12.700 HUF", "Foglalo befizetve: 2024.10.21")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Tranzakció adatai.
- **Kimenet / Visszajelzés**: Tranzakciós tételek.
- **Validációk és Kényszerek**: HUF összeg ezres csoportosítása.

### FR-9: Foglaló mértékének kalkulációja
- **Leírás**: A befizetendő foglaló összegének a rendelt devizaösszeg Forint-ellenértékének pontosan 5%-ának kell lennie.
- **Forrás**: `Foglaló bizonylatok.jpg` jogi szövege ("ot szazalekanak (5 %) megfelelo osszeget foglalokent")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Forint-ellenérték (Ft-érték).
- **Kimenet / Visszajelzés**: Ajánlott/kiszámított foglaló összege (HUF).
- **Validációk és Kényszerek**: Pontosan 5% kiszámítása (kerekítési szabályokat lásd: TBD-4).

### FR-10: Jogi tájékoztató szöveg nyomtatása
- **Leírás**: A bizonylaton meg kell jelennie a kötelező jogi szövegnek (megbízási szerződés tartalma, kétszeres visszafizetés kötelezettsége a megbízott hibája esetén, beszámítás módja, árfolyam tájékoztató jellege).
- **Forrás**: `Foglaló bizonylatok.jpg` jogi blokk
- **Prio**: S
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Nincs (statikus jogi szöveg).
- **Kimenet / Visszajelzés**: Jogi blokk a szalagon.
- **Validációk és Kényszerek**: Változatlan formában kell nyomtatni.

### FR-11: Aláírás-helyek nyomtatása (átvétel)
- **Leírás**: A foglaló átvételi bizonylat alján két aláírás-helyet kell biztosítani a pénztáros és az ügyfél számára.
- **Forrás**: `Foglaló bizonylatok.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Nincs.
- **Kimenet / Visszajelzés**: Nyomtatott vonalak és címkék ("penztaros", "ugyfel").
- **Validációk és Kényszerek**: Megfelelő térköz biztosítása az aláírásokhoz.

### FR-12: Foglaló visszafizetési/rendezési bizonylat generálása
- **Leírás**: A foglaló visszafizetésekor vagy beszámításakor külön bizonylatot kell generálni "FOGLALO VISSZAFIZETESE" fejléccel, az eredeti ügyfél-adatok feltüntetésével.
- **Forrás**: `Foglaló bizonylatok.jpg` ("FOGLALO VISSZAFIZETESE")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Eredeti foglalási rekord, ügyféladatok.
- **Kimenet / Visszajelzés**: Visszafizetési bizonylat.
- **Validációk és Kényszerek**: Az ügyféladatoknak pontosan egyezniük kell az eredeti foglaláson szereplőkkel.

### FR-13: Visszafizetési adatok feltüntetése a bizonylaton
- **Leírás**: A visszafizetési bizonylaton fel kell tüntetni: a kifizetés bizonylatszámát, a foglaló eredeti átvételi dátumát, az eredeti foglaló bizonylatszámát, az átvett foglaló összegét és a rendezés (kifizetés) aktuális dátumát.
- **Forrás**: `Foglaló bizonylatok.jpg` ("Kifizetes bizonylata: <BIZONYLAT_SZAM>", "Foglalo atvetel napja: 2024.10.24", "Foglalo bizonylatszama: <BIZONYLAT_SZAM>", "Atvett foglalo osszege: 12.700", "Foglalo rendezes napja: 2024.10.24")
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Visszafizetési tranzakció részletei.
- **Kimenet / Visszajelzés**: Rendezési mezők a bizonylaton.
- **Validációk és Kényszerek**: Hivatkozott bizonylatszám validáció.

### FR-14: Visszafizetési bizonylat záró szövege és aláírása
- **Leírás**: Fel kell tüntetni a szöveget, hogy a foglaló a mai napon végrehajtott ügylet ellenértékébe beszámításra került, valamint biztosítani kell a két aláírás helyét (pénztáros és ügyfél).
- **Forrás**: `Foglaló bizonylatok.jpg`
- **Prio**: M
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Nincs.
- **Kimenet / Visszajelzés**: Záró nyilatkozatszöveg és aláírásmezők.
- **Validációk és Kényszerek**: Változatlan formátumú szöveg.

### FR-15: Rendelés-kapcsolat a Pénztári Adatlapon
- **Leírás**: A rögzített foglalónak és rendelésnek meg kell jelennie a Pénztári adatlapon az "UGYFELEK RENDELESE" vagy "KESZLET RENDELESE ERTEKTAR FELE" rovatokban.
- **Forrás**: `Extra tranzakciós díjak _ Foglaló _ Pénztári adatlap.jpg` (Pénztári adatlap "UGYFELEK RENDELESE", "KESZLET RENDELESE ERTEKTAR FELE")
- **Prio**: C
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Aktív napi rendelések státusza.
- **Kimenet / Visszajelzés**: Pénztári adatlap bejegyzés.
- **Validációk és Kényszerek**: Csak az adott napi lezáratlan vagy aznap rendezett rendelések/foglalók listázhatók.

### FR-16: Pmt. / AML Megfelelőség (50M HUF feletti korlát és Szlip Életkor)
- **Leírás**: A foglaló felvételekor és az alapul szolgáló devizaügyletnél a rendszernek érvényesítenie kell a Pmt. szabályokat:
  - Ha a tranzakció forint ellenértéke eléri vagy meghaladja az 50 millió HUF-ot, a pénzeszközök forrását kizárólag közjegyző vagy ügyvéd által ellenjegyzett "teljes bizonyító erejű magánokirattal" szabad igazolni. Két tanúval ellátott magánnyilatkozat elfogadása szigorúan tilos.
  - Ha az ügyfél banki kifizetési bizonylatot (szlipet) nyújt be a forrás igazolására, az nem lehet 3 évnél régebbi (a 3 évnél régebbi banki bizonylatokat a rendszernek automatikusan el kell utasítania).
- **Forrás**: `Hang 003_sd.m4a.txt` átirat 5-7., 30-36. sorok
- **Prio**: Magas
- **Csomag/Komponens**: `penztar-client` / backend
- **Bemenő adatok**: Forrásigazolás dokumentum adatai (kiállítás kelte, típusa, ellenjegyző)
- **Kimenet / Visszajelzés**: Engedélyezés vagy tiltás hibaüzenettel
- **Validációk és Kényszerek**: Ha az ellenérték >= 50M HUF, a magánokirat típusának megléte és érvényessége kötelező. Banki bizonylat esetén a kiállítási dátum és a tranzakció dátuma közötti különbség legfeljebb 3 év (1095 nap) lehet.
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma (SQLite és Postgres Tükör)

### Postgres és SQLite táblák:

#### 1. `foglalok`
A foglalók nyilvántartása és állapotkövetése.
- `id` (SERIAL / INTEGER PRIMARY KEY AUTOINCREMENT)
- `bizonylatszam` (VARCHAR(50) UNIQUE NOT NULL) -- Pl. B00312 prefixszel
- `penztar_id` (INTEGER NOT NULL)
- `rendeles_napja` (DATE NOT NULL)
- `rendelt_osszeg` (NUMERIC(15, 4) NOT NULL)
- `rendelt_devizanem` (VARCHAR(3) NOT NULL)
- `arfolyam` (NUMERIC(12, 4) NOT NULL)
- `arfolyam_egyseg` (INTEGER NOT NULL DEFAULT 1)
- `ft_ertek` (NUMERIC(15, 2) NOT NULL)
- `ugylet_hatarideje` (DATE NOT NULL)
- `foglalo_osszege_huf` (NUMERIC(15, 2) NOT NULL)
- `foglalo_befizetve_datum` (DATE NOT NULL)
- `statusz` (VARCHAR(20) NOT NULL DEFAULT 'AKTIV') -- AKTIV, RENDEZETT, SZTORNOZOTT
- `ugyfel_nev` (VARCHAR(100) NOT NULL)
- `ugyfel_anyja_neve` (VARCHAR(100) NOT NULL)
- `ugyfel_szul_hely` (VARCHAR(100) NOT NULL)
- `ugyfel_szul_ido` (DATE NOT NULL)
- `ugyfel_okmanytipus` (VARCHAR(20) NOT NULL)
- `ugyfel_okmanyszam` (VARCHAR(50) NOT NULL)
- `ugyfel_allampolgarsag` (VARCHAR(50) NOT NULL)
- `forras_dokumentum_tipus` (VARCHAR(50)) -- PL. 'MAGANOKIRAT', 'BANK_SZLIP'
- `forras_dokumentum_datum` (DATE)
- `forras_dokumentum_ellenor` (VARCHAR(100))

#### 2. `foglalo_visszafizetesek`
A visszafizetési/beszámítási adatok naplózása.
- `id` (SERIAL / INTEGER PRIMARY KEY AUTOINCREMENT)
- `kifizetes_bizonylatszama` (VARCHAR(50) UNIQUE NOT NULL) -- Pl. K00308 prefixszel
- `foglalo_id` (INTEGER REFERENCES foglalok(id) UNIQUE)
- `foglalo_atvetel_napja` (DATE NOT NULL)
- `atvett_foglalo_osszege` (NUMERIC(15, 2) NOT NULL)
- `foglalo_rendezes_napja` (DATE NOT NULL)
- `modja` (VARCHAR(20) NOT NULL) -- BESZAMITVA, KESZPENZ_VISSZA, KETSZERES_VISSZA

### Legacy adatbázis leképezés (Legacy Mappings)
- `FOGLALOK` (Legacy foglaló törzstábla: `DATUM`, `BIZONYLATSZAM`, `UGYFELSZAM`, `UGYFELTIPUS`, `RENDELVE`, `FOGLAL`)
- `FOGLALOKESZLET` (Legacy foglaló készlet követés)
- `UGYFEL` (Legacy ügyféltörzs tábla: `UGYFELSZAM`, `NEV`, `ANYJANEVE`, `SZULETESIHELY`, `SZULETESIIDO` stb.)
- `UTOLSOBLOKKOK` (Legutolsó sorszámok és ügyfél-azonosítók követése: `UTOLSOUGYFELSZAM` stb.)
- `ARFOLYAM`, `HARDWARE`, `PENZTAR`, `MEDIA`, `VTEMP`
</data_structure>

<integration_points>
## Integrációs Pontok és Belső Függőségek
- **KYC/Ügyfél-azonosítás**: Ügyféladatok betöltése és validációja a Pmt. szabályok és okmányok ellenőrzéséhez.
- **Tranzakciós modul (Vétel)**: A visszafizetéskor vagy beszámításkor létrejövő devizaügylet (Vétel) modulja. A foglaló beszámítása automatikusan a `foglalo_id` összekapcsolásával és levonásával történik a devizavétel rögzítésekor.
- **Pénztár készlet és napi elszámolás**: Befizetéskor a kassza HUF készletének növelése, kifizetéskor/beszámításkor a kassza HUF készletének kezelése.
- **Bizonylatszámozó szolgáltatás**: Bizonylatszámok kiadása a 'B' és 'K' sorszám-szekvenciák alapján.
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- Ellenőrizni az SQLite és Postgres migrációs szkriptek struktúráját a `foglalok` és `foglalo_visszafizetesek` táblák létrehozásához.
- A jogi szövegek statikus sablonjait integrálni a nyomtatási modulba.

### Fázis 2: Backend megvalósítás
- Létrehozni a foglaló felvételi API-t (tranzakciós kontextusban, 5%-os ellenőrzéssel és az 50M HUF feletti AML szabályok validációjával).
- Megvalósítani a visszafizetési és beszámítási logikát (beleértve a kétszeres visszafizetés bizonylatolását és jóváhagyását).
- Biztosítani a sorszám-generálás atomicitását offline üzemmódban is (kliensoldali SQLite).

### Fázis 3: Frontend megvalósítás
- Elkészíteni az Electron alapú `penztar-client` felületén a foglaló űrlapot (ügyféladatok + rendelési adatok + AML okmány adatok).
- Megvalósítani a hőnyomtató-specifikus rendering sablonokat a foglaló és visszafizetési bizonylathoz a monospace betűtípus szerint.

### Fázis 4: Verifikáció
- Unit tesztekkel verifikálni a 5%-os kalkulációt és a HUF kerekítést.
- Unit tesztekkel verifikálni az 50M HUF feletti magánokirat kötelezettséget, valamint a banki bizonylatok 3 éves korlátját.
- End-to-end teszt futtatása: Foglaló felvétele → Bizonylat generálása → Visszafizetés/Rendezés bizonylat generálása → Tranzakciós kapcsolat ellenőrzése.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| ID | Kérdés / Kockázat | Hatás | Leírás |
| --- | --- | --- | --- |
| TBD-1 | Foglaló kapcsolódása a fő ügylethez | Adatmodell, Üzleti logika | **LEZÁRVA**: A deviza vétel tranzakció rögzítésekor a rendszer lekéri a megadott foglaló bizonylatszám alapján az aktív foglalót, és automatikusan beszámítja (levonja) a fizetendő HUF összegből. |
| TBD-2 | Foglaló sztornózhatósága | Működési szabályok | **LEZÁRVA**: Igen, a foglaló bizonylatok sztornózhatók az általános sztornó szabályok szerint (Supervisor jóváhagyással a 4. sztornótól, külön stornó bizonylat generálásával). |
| TBD-3 | AML/Pmt. összeghatár ellenőrzés | Megfelelőség | **LEZÁRVA**: Igen, a Pmt. szerint 50M HUF felett kizárólag közjegyző vagy ügyvéd által ellenjegyzett teljes bizonyító erejű magánokirat fogadható el a pénzeszközök forrásaként (tanúk kizárva). A banki kifizetési bizonylatok (slips) életkora legfeljebb 3 év lehet. |
| TBD-4 | HUF kerekítési szabályok | Pénzügyi elszámolás | **LEZÁRVA**: A kiszámított 5%-os foglaló összeget és a készpénzes kifizetést a hatályos MNB kerekítési szabályok szerint 5 Ft-ra kell kerekíteni. |
| TBD-5 | Jogosultsági körök (RBAC) | Biztonság | **LEZÁRVA**: Rögzítés és visszafizetés: `ROLE_CASHIER` (Pénztáros). Kétszeres visszafizetés és 50M HUF feletti engedélyek: `ROLE_SUPERVISOR` (Supervisor). |
| TBD-6 | Kétszeres visszafizetés kezelése | Üzleti folyamat | **LEZÁRVA**: Megvalósítandó a "FOGLALO KETSZERES VISSZAFIZETESE" típusú bizonylat és a hozzá tartozó kifizetési tranzakció, amely Supervisor jelszavas jóváhagyást igényel. |
| TBD-7 | Bizonylatszám formátum szabályok | Rendszer-sorszámozás | **LEZÁRVA**: Átvételi bizonylat: `B` prefix + 6 számjegy (pl. `B000756`), kifizetési/visszafizetési bizonylat: `K` prefix + 6 számjegy (pl. `K000756`). Az offline SQLite helyben osztja ki, majd szinkronizál. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [x] Minden megnevezett követelmény (FR-1-től FR-16-ig) mögött szerepel a forrás-dokumentum vagy átirat hivatkozása.
- [x] A 7 darab TBD kockázat feloldásra és rögzítésre került a megfelelő szekcióban.
- [x] Nem lettek új üzleti szabályok vagy számítási logikák hallucinálva, minden adat a megerősített tényeken alapul.
- [x] A SQLite mirror és Postgres közötti adatmodell szinkronizáció rögzítve van.
</verification_checklist>
