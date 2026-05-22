# Modul: Foglaló (ügyfél-előleg) felvétele és visszafizetése  (forrás: Kósa Tervezés és fejlesztés/Segédanyagok Valuta/Foglaló felvétele.docx; Bizonylatok/Foglaló bizonylatok.jpg; Bizonylatok/Extra tranzakciós díjak _ Foglaló _ Pénztári adatlap.jpg)

## 1. Cel
A pénztáros rögzít egy ügyfél-foglalót (előleget) egy jövőbeni nagy összegű devizaügyletre, kinyomtatja a Foglaló átvételi bizonylatot, majd teljesítéskor vagy meghiúsuláskor a foglalót beszámítja / visszafizeti.

## 2. Scope
### IN
- Foglaló átvétele: ügyfél-azonosítás, rendelt összeg/deviza, árfolyam, foglaló összege, ügylet határideje, foglaló befizetésének napja.
- Foglaló átvételi bizonylat nyomtatása (két aláírás: pénztáros + ügyfél).
- Foglaló visszafizetése / rendezése: kifizetés bizonylatszáma, átvett foglaló összege, foglaló rendezés napja, beszámítás az aktuális napi árfolyamon.
- Tranzakció típusa: VÉTEL (a docx alapján: "FOGLALOT VETT FEL EGY PENZTAR", Tranz. tipusa: VETEL).
- Pénztár (kassza) azonosítóhoz kötés (docx: "Penztar: 105").

### OUT
- A teljesítő (fő) devizaügylet maga (külön modul) — TBD a kapcsolódás módja.
- Sztornó folyamat részletei — a forrásban nem szerepel külön sztornó-bizonylat foglalóra. **TBD**.
- AML/Pmt. küszöb-ellenőrzés a foglalóra — a forrás nem mutatja. **TBD**.

## 3. Szakteruleti szereplok
| Szerep | Jogosultsag | RBAC ertek |
| --- | --- | --- |
| Pénztáros | Foglaló felvétele, bizonylat nyomtatás, visszafizetés rögzítés (a bizonylaton "penztaros" aláírás) | TBD |
| Ügyfél | Aláírás a bizonylaton (nem rendszer-szereplő) | n/a |
| Egyéb szerep (Értéktáros, Ügyvezető stb.) jogosultsága a forrásból nem derül ki | TBD | TBD |

## 4. Funkcionalis kovetelmenyef (FR)
| ID | Leiras | Forrás-hivatkozas | Prio | Csomag |
| --- | --- | --- | --- | --- |
| FR-1 | A foglaló felvételhez kötelező megadni a pénztár (kassza) azonosítót | docx: "Penztar : 105" | M | penztar-client |
| FR-2 | Rögzíteni kell a rendelés napját | docx: "Rendeles napja: 2024.03.15" | M | penztar-client |
| FR-3 | Rögzíteni kell a rendelt összeget devizában | docx: "Rendelt osszeg: 10.000 EUR" | M | penztar-client |
| FR-4 | Rögzíteni kell az árfolyamot (egységfeltüntetéssel) | docx: "Arfolyam: 38500 (100 EUR/ Ft)" | M | penztar-client |
| FR-5 | A tranzakció típusa VÉTEL | docx: "Tranz. tipusa : VETEL" | M | penztar-client |
| FR-6 | A Foglaló átvételi bizonylat fejléce: "FOGLALO ATVETELE" | foglalo.jpg | M | penztar-client |
| FR-7 | A foglaló átvételi bizonylaton az ügyfél-azonosító adatok: ügyfél neve, anyja neve, szül. hely, szül. idő, okmánytípus, okmány szám, állampolgárság | foglalo.jpg ("Ugyfel neve: MOCSKONYI JUDIT", "Anyja neve: BALOGI JUDIT", "Szul-i hely: SZEGED", "Szul-i ido: 1966.04.11", "Okmanytipus: SZIG", "Okmany szam: 1044625E", "Allampolgar: MAGYAR") | M | penztar-client |
| FR-8 | A bizonylaton: bizonylat száma, rendelt (mért) összeg + devizanem, ennek Ft-értéke, ügylet határideje, foglaló összege (HUF), foglaló befizetve dátum | foglalo.jpg ("Bizonylat szama: B00312", "...elt osszeg: 100.000 JPY", "ennek ft. erteke: 254.000 HUF", "Ugylet hatarideje: 2024.10.24", "Foglalo osszege: 12.700 HUF", "Foglalo befizetve: 2024.10.21") | M | penztar-client |
| FR-9 | A foglaló összege a megbízási összeg 5%-a | foglalo.jpg jogi szöveg: "ot szazalekanak (5 %) megfelelo osszeget foglalokent" | M | penztar-client |
| FR-10 | A bizonylaton kötelező jogi/tájékoztató szöveg (megbízási szerződés, foglaló jogi természete, kétszeres visszafizetés ha a Megbízott hibájából hiúsul meg, beszámítás a fizetendő összegbe, árfolyam tájékoztató jellegű, az aktuális árfolyam a kifizetés napján kerül meghatározásra) | foglalo.jpg jogi blokk | S | penztar-client |
| FR-11 | A foglaló átvételi bizonylaton két aláírás-hely: penztaros + ugyfel | foglalo.jpg | M | penztar-client |
| FR-12 | Foglaló visszafizetése/rendezése külön bizonylat: fejléc "FOGLALO VISSZAFIZETESE", ugyanazok az ügyfél-adatok | foglalo.jpg ("FOGLALO VISSZAFIZETESE") | M | penztar-client |
| FR-13 | A visszafizetési bizonylaton: kifizetés bizonylatszáma, foglaló átvétel napja, foglaló bizonylatszáma, átvett foglaló összege, foglaló rendezés napja | foglalo.jpg ("Kifizetes bizonylata: K00308", "Foglalo atvetel napja: 2024.10.24", "Foglalo bizonylatszama: B00312", "Atvett foglalo osszege: 12.700", "Foglalo rendezes napja: 2024.10.24") | M | penztar-client |
| FR-14 | A visszafizetési bizonylaton záró szöveg: a foglaló a mai napon végrehajtott ügylet ellenértékébe beszámításra kerül + két aláírás (penztaros + ugyfel) | foglalo.jpg | M | penztar-client |
| FR-15 | A foglaló-rekord az ügyfél-rendeléshez/keszlet-rendeléshez kapcsolódik (az "UGYFELEK RENDELESE" / "KESZLET RENDELESE ERTEKTAR FELE" rovat a Pénztári adatlapon is megjelenik) | extra_dij.jpg (Pénztári adatlap "UGYFELEK RENDELESE", "KESZLET RENDELESE ERTEKTAR FELE") | C | penztar-client |

## 5. Nem-funkcionalis kovetelmenyef (NFR)
| ID | Leiras | Merheto kriterium |
| --- | --- | --- |
| NFR-1 | A bizonylatok hőnyomtatóra (keskeny szalag) nyomtathatók | A foglalo.jpg keskeny szalag-formátum; szövegtörés a szalagszélességhez |
| NFR-2 | A bizonylat tartalma a jogszerűség miatt szöveghűen, módosíthatatlanul nyomtatandó | A jogi szöveg fix sablon (foglalo.jpg) |
| NFR-3 | A foglaló és a teljesítő ügylet összepárosítható (bizonylatszám-hivatkozás B00312 ↔ K00308) | A visszafizetési bizonylat hivatkozik a foglaló bizonylatszámára |

## 6. Adatmodell-erintettseg
- Postgres: új/érintett entitás `Foglalo` (deposit/előleg). Mezők a forrásból: penztar_id, rendeles_napja, rendelt_osszeg, rendelt_devizanem, arfolyam, arfolyam_egyseg, ft_ertek, ugylet_hatarideje, foglalo_osszege_huf, foglalo_befizetve, bizonylat_szama, tranz_tipus(VETEL), ugyfel-snapshot (nev, anyja_neve, szul_hely, szul_ido, okmanytipus, okmany_szam, allampolgarsag).
- Visszafizetés-rekord mezők: kifizetes_bizonylatszama, foglalo_atvetel_napja, foglalo_bizonylatszama (FK), atvett_foglalo_osszege, foglalo_rendezes_napja.
- SQLite mirror: **IGEN** — a foglaló a pénztáros Electron kliensen helyben rögzül és nyomtat (offline-képes pénztár). Indok: a forrás pénztári bizonylat, lokálisan generált.
- Migráció szükséges: **IGEN** (új tábla(k) + bizonylatszám-szekvenciák B##### és K#####). Pontos oszloptípusok/constraint-ek **TBD**.

## 7. Fuggosegek
- Árfolyam-forrás: a foglaló-bizonylaton az árfolyam a felvételkor rögzül, de "Az aktualis arfolyam a kifizetes napjan kerul meghatarozasra" → kapcsolat a napi árfolyam-modullal. Konkrét MNB/bank API a forrásban nem szerepel → **TBD**.
- Belső modul: ügyfél-azonosítás (KYC) modul; a teljesítő devizaügylet (VÉTEL) modul.
- Bizonylatszám-generálás (B/K prefix) modul.

## 8. Domain-szotar
| Fogalom | Magyarazat |
| --- | --- |
| Foglaló | Ügyfél által befizetett előleg egy jövőbeni devizaügyletre; a megbízási összeg 5%-a (forrás). |
| Foglaló átvétele | A foglaló felvétele + bizonylat ("FOGLALO ATVETELE"). |
| Foglaló visszafizetése | A foglaló rendezése: beszámítás az ügylet ellenértékébe vagy visszafizetés ("FOGLALO VISSZAFIZETESE"). |
| Ügylet határideje | A jövőbeni devizaügylet teljesítési határideje. |
| Megbízott | "Exclusive Change" — a pénzváltó (bizonylat jogi szövege). |
| Rendelt összeg | Az ügyfél által megrendelt deviza mennyisége. |

## 9. Vegrehajtasi utasitas az AI-ugynoknek
### 9.1 Elokeszites
- Olvasd be a forrás 2 képét + a docx-et; ne hasonlíts a meglévő programhoz.
- Tisztázd a TBD-ket (lásd 10.) a termékgazdával felvétel/sztornó/AML kérdésekben.

### 9.2 Fazisok
1. **Adatmodell + migráció** — Foglaló + Visszafizetés entitás, bizonylatszám-szekvencia. AC: migráció lefut, entitásokon a 6. szekció minden mezője szerepel.
2. **Felvétel-folyamat (VÉTEL)** — pénztár, rendelés napja, rendelt összeg+deviza, árfolyam, foglaló 5% kalkuláció, ügyfél-azonosítás. AC: új foglaló rögzül, foglaló_osszege = round(ft_ertek*0.05) — a kerekítési szabály **TBD**.
3. **Bizonylat-nyomtatás (átvétel)** — fejléc + ügyfél-adatok + tételek + jogi szöveg + 2 aláírás. AC: a foglalo.jpg minden mezője megjelenik.
4. **Visszafizetés/rendezés** — kifizetés bizonylat, beszámítás, "FOGLALO VISSZAFIZETESE" bizonylat. AC: hivatkozik a foglaló bizonylatszámára (B→K).

### 9.3 Tesztes
- Unit: 5% foglaló-kalkuláció, ft_ertek számítás árfolyam+egység alapján.
- Integráció: felvétel→bizonylat→visszafizetés teljes út, bizonylatszám-párosítás.
- Bizonylat-render snapshot teszt a foglalo.jpg mezőkre.

## 10. Kockazatok / Nyitott kerdesek (TBD)
| # | Kerdes | Miert fontos | Mit kell tudni |
| --- | --- | --- | --- |
| TBD-1 | Hogyan kapcsolódik a foglaló a teljesítő devizaügylethez? | Beszámítás + bizonylat-hivatkozás | Foglaló→ügylet párosítás üzleti szabálya |
| TBD-2 | Van-e foglaló-sztornó és milyen bizonylattal? | Hibás felvétel javítása | A forrásban nincs sztornó-bizonylat |
| TBD-3 | A foglaló összegére van-e AML/Pmt. küszöb/azonosítási kötelezettség? | Megfelelőség | A forrás csak az ügyfél-adatokat mutatja |
| TBD-4 | A foglaló 5%-a milyen kerekítéssel (5 Ft HUF kerekítés?) számolódik? | Pontos összeg | A forrás konkrét kerekítést nem mutat |
| TBD-5 | RBAC: mely szerepek vehetnek fel/fizethetnek vissza foglalót? | Jogosultság | Forrás csak "penztaros" aláírást mutat |
| TBD-6 | Kétszeres visszafizetés (Megbízott hibája) automatizálva van-e? | Jogi kötelezettség | Forrás jogi szövegben szerepel, folyamat nem |
| TBD-7 | Bizonylatszám-formátum (B00312 / K00308) szekvencia-szabálya | Egyediség | Prefix + 5 jegy látható, generálás módja nem |

## 11. Verifikacios checklist
- [x] minden FR-hez forrás-hivatkozás
- [x] 0 hallucináció (csak forrásban látható adat)
- [x] minden TBD jelölt
VERIFIKACIO: FR=15 db, TBD=7 db, érintett csomag(ok)=penztar-client (+ Postgres/Flyway migráció, SQLite mirror)
