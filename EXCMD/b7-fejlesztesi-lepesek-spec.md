# Modul: Fejlesztesi lepesek + rendszerfunkciok + adatmodell-szabalyok (Valuta)

<system_context>
## Rendszerkontextus és Háttér
Ez a modul leírja a tervezett valutaváltó-rendszer moduláris fejlesztési lépéseit (34 lépésből álló munkaterv), az alapvető rendszerfunkciókat (belépés, kilépés-védelem, 3 havi jelszócsere), valamint a PowerDesigner-alapú logikai adatmodellt és annak 11 üzleti szabályát.

### Szerepkörök (Roles)
| Szerep | Jogosultság / Feladatkör | RBAC érték |
|---|---|---|
| Felhasználó (általános) | Egyedi felhasználónév/jelszó alapú belépés, 3 havi kötelező jelszócsere, folyamat-lezárási kötelezettség kilépés előtt. | TBD (Lásd: TBD-19) |
| Pénztáros | Váltási tranzakciók végrehajtása, foglaló kezelése, pénztárközi mozgások és napi zárások/nyitások rögzítése. | TBD |
| Értéktáros / Főértéktáros | Árfolyamok karbantartása, kezelési díjak és jutalékok paraméterezése, valuta-igények elbírálása. | TBD |
| Belsőellenőr | Anonim bejelentések megtekintése, gyanús ügyletek felülvizsgálata, biztonsági logok lekérdezése. | TBD |
| Adminisztrátor | Felhasználók, jogosultságok, munkaállomások, saját cég és irodahierarchia kezelése. | TBD |

### Hatókör (Scope)
#### IN
- A 34 fejlesztési lépés / moduláris ütemterv (az adatbázistól az adat-replikációig).
- Alaprendszer funkciók: belépési biztonsági szűrők, kilépési folyamat-zárás védelem, jelszócsere ciklus.
- Logikai adatmodell entitáslistája és adattípus-doménjei.
- Az adatmodell 11 darab üzleti validációs szabálya.

#### OUT
- Az üzleti folyamatok és interjúk részletes tartalma (lásd `b7-igenyfelmeres-interjuk.md`).
- A meglévő fizikai üzemeltetési architektúra (lásd `b7-uzemeltetes-megbeszeles.md`).

### Technológiai verem (Tech Stack)
- Backend szerver és API réteg (`backend`)
- Kliensoldali webes dashboard (`frontend-react`)
- Pénztári lokális kliens (`penztar-client` / `arfolyam-keszito-client`)
- Központi szerverkezelő kliens (`kozponti-client`)
- PostgreSQL központi relációs adatbázis és SQLite offline kliensoldali mirror (outbox replikációval)
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-53: Adatbázis-tervezés lépése
- **Leírás**: Az adatbázis táblák és a táblák közötti relációk fizikai megvalósítása a megadott logikai modell alapján.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (949-951)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Logikai adatmodell leírása.
- **Kimenet / Visszajelzés**: Létrehozott SQL adatbázis séma.
- **Validációk és Kényszerek**: Az integritási szabályoknak le kell futniuk.

### FR-54: Autentikációs végpontok
- **Leírás**: Biztosítani kell a bejelentkezést, a munkamenet-token (JWT) kiadását és a jelszócsere végpontokat.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (955-959)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Felhasználónév, jelszó.
- **Kimenet / Visszajelzés**: Munkamenet token vagy hibaüzenet.
- **Validációk és Kényszerek**: Jelszó hashelés és titkosított átvitel kötelező.

### FR-55: Egyedi bejelentkezés és műveleti naplózás
- **Leírás**: Minden felhasználónak egyedi felhasználónévvel és jelszóval kell bejelentkeznie. Minden rendszerben végzett tevékenységet logolni kell az elkövető azonosítójával és időbélyeggel (NFR-14). A jelszó megosztása tiltott.
- **Forrás**: `Kósa Szervezés/Specifikációk/Névtelen dokumentum.docx` (1592-1593)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Felhasználói hitelesítő adatok.
- **Kimenet / Visszajelzés**: Bejelentkezés naplózása, belépés jóváhagyása.
- **Validációk és Kényszerek**: Nincs.

### FR-56: Kijelentkezés folyamat-zárás védelemmel
- **Leírás**: A kijelentkezéskor a rendszernek egyszeri megerősítést kell kérnie. Ha a felhasználónak lezáratlan folyamata van (pl. megnyitott tranzakció vagy zárás előkészítés), a rendszer köteles letiltani a kijelentkezést, és figyelmeztetést küldeni a teendőről ("vond vissza" vagy "hajtsd végre").
- **Forrás**: `Kósa Szervezés/Specifikációk/Névtelen dokumentum.docx` (1597-1598)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Kijelentkezési parancs.
- **Kimenet / Visszajelzés**: Kijelentkezés megerősítő / blokkoló figyelmeztető ablak.
- **Validációk és Kényszerek**: Lezáratlan folyamat esetén a kilépés fizikailag nem hajtható végre.

### FR-57: Kötelező időszakos jelszóváltoztatás
- **Leírás**: Biztosítani kell a jelszóváltoztatás lehetőségét a felhasználó által. Ezen felül 3 havonta belépéskor a rendszernek kötelező jelszócserét kell előírnia (NFR-13).
- **Forrás**: `Kósa Szervezés/Specifikációk/Névtelen dokumentum.docx` (1602)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Régi jelszó, új jelszó.
- **Kimenet / Visszajelzés**: Sikeres jelszócsere naplózása.
- **Validációk és Kényszerek**: Az új jelszó nem egyezhet meg az előző jelszavak listájával.

### FR-58: Rendszer Dashboard
- **Leírás**: Meg kell valósítani az alkalmazás főmenüjét, a cégcsoport logóját, a láblécet (verziószám kijelzés) és a kilépési opciókat tartalmazó Dashboard-ot.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (960-965)
- **Prio**: Should
- **Csomag/Komponens**: `frontend-react`
- **Bemenő adatok**: Jogosultsági maszk.
- **Kimenet / Visszajelzés**: Dashboard felület.
- **Validációk és Kényszerek**: Nincs.

### FR-59: Rendszerparaméterek karbantartása
- **Leírás**: Adminisztrációs felület a globális rendszerparaméterek listázására és szerkesztésére.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (966-969)
- **Prio**: Should
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Paraméter kulcs, érték.
- **Kimenet / Visszajelzés**: Mentett paraméter.
- **Validációk és Kényszerek**: Típusellenőrzés.

### FR-60: Jogosultságok kezelése (RBAC)
- **Leírás**: Felület a rendszerjogosultságok kezelésére: lista, új jog felvétele, szerkesztés, aktiválás, inaktiválás és törlés.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (970-976)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Jogosultság adatok.
- **Kimenet / Visszajelzés**: Frissített jogosultsági táblák.
- **Validációk és Kényszerek**: Nincs.

### FR-61: Felhasználók kezelése
- **Leírás**: Felhasználói fiókok kezelése: lista, új felhasználó rögzítése, szerkesztése, aktiválás, inaktiválás, archiválás és törlés.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (977-984)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Felhasználói fiók adatok.
- **Kimenet / Visszajelzés**: Frissített felhasználói tábla.
- **Validációk és Kényszerek**: E-mail cím formátum ellenőrzése.

### FR-62: HR és Munkavállaló modul
- **Leírás**: Munkavállalók nyilvántartása, fiókok felhasználókhoz rendelése, jutalékok listázása, jutalék kalkuláció és könyvelési lista-generálás.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (985-996)
- **Prio**: Should
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Munkavállalói adatok, jutalékráták.
- **Kimenet / Visszajelzés**: Jutalék elszámolási riport.
- **Validációk és Kényszerek**: Nincs.

### FR-63: Munkaállomás-kezelés
- **Leírás**: A fizikai munkaállomások (gépek) nyilvántartása és telephelyhez rendelése: lista, új, szerkesztés, aktiválás, archiválás, törlés.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (997-1004)
- **Prio**: Should
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Munkaállomás kód, telephely ID.
- **Kimenet / Visszajelzés**: Munkaállomás profil.
- **Validációk és Kényszerek**: A munkaállomás csak egy telephely tevékenységeihez tartozhat (üzleti szabály #8).

### FR-64: Szervezetek és saját cég struktúra
- **Leírás**: Fiókok és értéktárak hierarchikus nyilvántartása, saját cégadatok kezelése, szervezeti egység áthelyezések, aktiválások és bezárások.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1005-1021)
- **Prio**: Must
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Szervezeti hierarchia adatok.
- **Kimenet / Visszajelzés**: Szervezeti struktúra térkép.
- **Validációk és Kényszerek**: A cég TEAOR kódjának a hierarchia legalsó eleméből kell származnia (üzleti szabály #1).

### FR-65: Szervezeti szintű rendszerparaméterek
- **Leírás**: Szervezeti egység, devizanem vagy időtartam-függő rendszerparaméterek variánsainak kezelése.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1022-1035)
- **Prio**: Should
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Szervezet ID, paraméter kulcs.
- **Kimenet / Visszajelzés**: Szervezeti paraméter beállítás.
- **Validációk és Kényszerek**: Nincs.

### FR-66: Címletek karbantartása
- **Leírás**: Valuta címletek (bankjegy/érme) nyilvántartása: lista, új címlet, szerkesztés, aktiválás, archiválás, törlés.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1036-1043)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Deviza kód, címlet érték.
- **Kimenet / Visszajelzés**: Címlettörzs frissülés.
- **Validációk és Kényszerek**: A címletezés devizanemének egyeznie kell az egyenleg vagy mozgás devizaneméhez tartozó címlettel (üzleti szabály #3).

### FR-67: Devizanemek karbantartása
- **Leírás**: Kezelt devizanemek nyilvántartása és beállítása: lista, új deviza, szerkesztés, aktiválás, archiválás és törlés.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1044-1051)
- **Prio**: Must
- **Csomag/Komponens**: `arfolyam-keszito-client`
- **Bemenő adatok**: Devizakód (ISO), megnevezés.
- **Kimenet / Visszajelzés**: Devizanem törzs.
- **Validációk és Kényszerek**: Egyedi ISO kódok.

### FR-68: Belső körlevelek és hirdetmények
- **Leírás**: Körlevelek és hirdetmények készítése, címzettek hozzárendelése (szervezeti egység/felhasználó/jogcsoport), csatolmányok kezelése, értesítések küldése és az olvasottság ("értettem" gomb leütése) visszakövetése.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1052-1061)
- **Prio**: Should
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Körlevél szöveg, címzett szűrő.
- **Kimenet / Visszajelzés**: Kliensoldalon felugró kötelezően elolvasandó értesítés.
- **Validációk és Kényszerek**: Az "értettem" megnyomásáig a körlevél nem tűnhet el.

### FR-69: Ügyfelek és meghatalmazottak nyilvántartása
- **Leírás**: Ügyfelek és meghatalmazottak adatlapjainak kezelése: lista, új rögzítés, szerkesztés, aktiválás, archiválás, törlés.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1062-1069)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: KYC ügyfélprofil adatok.
- **Kimenet / Visszajelzés**: Ügyfél rekord.
- **Validációk és Kényszerek**: Egy ügyfél kizárólag Természetes Személy VAGY Cég lehet (üzleti szabály #11). Egy személynek egy okmánytípusból egyszerre csak egy érvényes okmánya lehet (üzleti szabály #5).

### FR-70: Anonim bejelentések kezelése
- **Leírás**: Anonim bejelentések (pl. visszaélés-jelentő csatorna) kezelése: új bejelentés beküldése, lista, inaktiválás/lezárás.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1070-1074)
- **Prio**: Should
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Bejelentés szövege.
- **Kimenet / Visszajelzés**: Rögzített bejelentés a belső ellenőrzésnek.
- **Validációk és Kényszerek**: A beküldő személyét a rendszer nem azonosíthatja és nem naplózhatja.

### FR-71: Árfolyamok kezelése
- **Leírás**: Konkurens árfolyamok figyelése, banki/elszámoló árfolyamok lekérése és rögzítése, árfolyam-meghatározási workflow, valamint az árfolyamok automatizált frissítése.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1075-1090)
- **Prio**: Must
- **Csomag/Komponens**: `arfolyam-keszito-client`
- **Bemenő adatok**: Banki árfolyam API adatok, manuálisan megadott ráták (Lásd: TBD-23).
- **Kimenet / Visszajelzés**: Érvényes árfolyamtábla.
- **Validációk és Kényszerek**: Nincs.

### FR-72: Kezelési díjak és kedvezmények
- **Leírás**: Díjtípusok (pl. ezrelékes, sávos) nyilvántartása, díjmértékek megadása, adható díjkedvezmények rögzítése, valamint a szinkronizációt követő automatikus díjváltozási életbeléptetések.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1091-1117)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Díjmértékek (Lásd: TBD-22).
- **Kimenet / Visszajelzés**: Számított tranzakciós díjak.
- **Validációk és Kényszerek**: Nincs.

### FR-73: Jutalékok paraméterezése
- **Leírás**: Jutalékmértékek nyilvántartása és karbantartása: lista, új mérték rögzítése, szerkesztés, törlés.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1118-1123)
- **Prio**: Should
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Jutalék százalékos értékek.
- **Kimenet / Visszajelzés**: Jutalék profil.
- **Validációk és Kényszerek**: Nincs.

### FR-74: Tiltólisták (Compliance)
- **Leírás**: Szankciós, terrorista és PEP tiltólisták kezelése: új elem, szerkesztés, külső forrásból történő letöltés, aktiválás, valamint az automata szinkronizálás megvalósítása.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1124-1131)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Külső szankciós listafájlok.
- **Kimenet / Visszajelzés**: Szinkronizált lokális tiltólista.
- **Validációk és Kényszerek**: Csak érvényes formátumú adat tölthető be.

### FR-75: Váltási tranzakciók (Vétel, Eladás, Keresztváltás)
- **Leírás**: Váltási igények rögzítése, kötelező KYC/AML ellenőrzések lefutása, valamint a tranzakció végrehajtása (vétel, eladás, keresztváltás és összetett váltás).
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1132-1140)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Ügyfél azonosító, váltandó összeg, cél deviza.
- **Kimenet / Visszajelzés**: Lekönyvelt tranzakció, nyomtatott bizonylat.
- **Validációk és Kényszerek**: A tranzakció kizárólag nyitott pénztárban hajtható végre (üzleti szabály #9).

### FR-76: Foglaló rögzítése és automatikus lezárása
- **Leírás**: Foglaló felvétele, érvényesítése, visszafizetése vagy beszámítása. Ha az ügylet határideje lejár és a meghiúsulás az ügyfél hibájából történik, a rendszernek automatikusan le kell zárnia a foglalót (elszámolás a cég javára).
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1141-1146)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Foglaló adatok, lejárati határidő.
- **Kimenet / Visszajelzés**: Foglaló státusz frissülés (RENDEZETT/ELVESZETT).
- **Validációk és Kényszerek**: A foglaló összege a rendelt összeg 5%-a.

### FR-77: Valuta-igények kezelése
- **Leírás**: Készletadatok alapján irodai valuta-igények automatikus generálása, manuális igények rögzítése, valamint az igények teljesítése az értéktár felől.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1147-1151)
- **Prio**: Should
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Aktuális készletszintek, igényelt összegek.
- **Kimenet / Visszajelzés**: Valutaigénylő adatlap.
- **Validációk és Kényszerek**: Nincs.

### FR-78: Pénztárak közötti pénzmozgás és transzfer
- **Leírás**: Pénz átadása és átvétele a társpénztárak/értéktár között, transzfer korrekciók könyvelése, valamint a kezelési díjak fizikai átadás-átvétele.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1152-1157)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Forrás/Cél pénztár, szállítási adatok (plomba, szállító).
- **Kimenet / Visszajelzés**: Szállítási napló bejegyzés.
- **Validációk és Kényszerek**: Transzfer esetén a kiindulási és cél helyeknek kizárólagosnak kell lenniük (pl. nem lehet mindkettő bank vagy telephely, üzleti szabály #6).

### FR-79: Átadólap generálás és nyomtatás
- **Leírás**: Az értéktár felé történő készlet-átadásról átadólap ablakot kell biztosítani, amelyből az adatok legenerálhatóak és kinyomtathatóak.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1158-1162)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Átadott tételek összesítése.
- **Kimenet / Visszajelzés**: Nyomtatott átadólap.
- **Validációk és Kényszerek**: Nincs.

### FR-80: Bizonylatkezelés és NAV feladás
- **Leírás**: Kinyomtatott bizonylatok listázása, napi bizonylatok sztornózása, újranyomtatás kezdeményezése, valamint a hibás/offline tranzakciók utólagos NAV-feladásának megvalósítása.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1163-1168)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Bizonylat sorszám.
- **Kimenet / Visszajelzés**: Sztornó státusz / NAV szinkron nyugtázás.
- **Validációk és Kényszerek**: Csak aznapi bizonylat sztornózható.

### FR-81: Zárási és nyitási folyamatok
- **Leírás**: Meg kell valósítani a napi zárás, a POS-terminál napi zárás, a 10 napos dekád-zárás, a havi zárás és a napi nyitás folyamatait.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1169-1175)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Címletezési adatok, záróegyenlegek.
- **Kimenet / Visszajelzés**: Zárási jelentés nyomtatása.
- **Validációk és Kényszerek**: A záróegyenlegnek meg kell egyeznie a könyvelt egyenleggel.

### FR-82: Járulék és jutalék számítás
- **Leírás**: A munkavállalói járulékok és jutalékok kiszámítása a megadott időszaki forgalmi adatok alapján.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1176-1178)
- **Prio**: Should
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Forgalmi adatok, jutaléktörzs.
- **Kimenet / Visszajelzés**: Számított jutalék összegek.
- **Validációk és Kényszerek**: Nincs.

### FR-83: Gyanús ügyletek bejelentése (AML)
- **Leírás**: Gyanús ügyletek és pénzmosási kísérletek bejelentése: új gyanús eset rögzítése, vezetői/ellenőri felülvizsgálat, és a hatósági feladás megvalósítása (Lásd: TBD-21).
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1179-1183)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Tranzakció ID, gyanú indoklása.
- **Kimenet / Visszajelzés**: Rögzített gyanús ügylet bejelentő.
- **Validációk és Kényszerek**: Az adatokat az ellenőr jóváhagyásáig zártan kell kezelni.

### FR-84: Rendszer listák és riportok
- **Leírás**: Meg kell jeleníteni és le kell tudni kérdezni a különböző riportokat: ügylet-, bizonylat-, díjösszesítő listák; havi készlet/forgalom/iroda kimutatások; kezelési költség és napi pénztár jelentések; gyanús ügyletek; bankkártyás tranzakciós díjak listája.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1184-1201)
- **Prio**: Must
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Szűrési feltételek (időszak, iroda, devizanem).
- **Kimenet / Visszajelzés**: Kimutatási rácsok és PDF exportok.
- **Validációk és Kényszerek**: Nincs.

### FR-85: Technikai és üzemeltetési funkciók
- **Leírás**: Az árfolyam-kijelző monitorok vezérlése; a pénztárszünetek kezelése és azok automatikus lezárása; a rendszer-, POS- és NAV-logok kezelése, kimásolása és archiválása; az üzleti adatok archiválása.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1202-1223)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client` / `backend`
- **Bemenő adatok**: Rendszeresemények, naplózási szintek.
- **Kimenet / Visszajelzés**: Archivált logfájlok, kijelző frissítés.
- **Validációk és Kényszerek**: A naplózás nem sértheti a PII adatkezelési szabályokat.

### FR-86: Adat-szinkronizációs és replikációs modul
- **Leírás**: A kliensoldali lokális SQLite adatbázisok és a központi Postgres adatbázis közötti szinkronizáció megvalósítása (offline működés támogatása).
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1224-1226)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Változás-naplók.
- **Kimenet / Visszajelzés**: Szinkronizált adatállapotok.
- **Validációk és Kényszerek**: Ütközéskezelés a tranzakciós adatoknál.

### FR-87: Periféria és Külső interfész modulok
- **Leírás**: A külső rendszerek illesztőprogramjai: árfolyam-kijelző monitor vezérlő, POS-terminál integráció, online pénztárgép (AEE) interface, központi dokumentumtár és az értesítés-kezelő modulok.
- **Forrás**: `Kósa Szervezés/Kósa cégcsoport fejlesztés lépései.docx` (1227-1233)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client` / `backend`
- **Bemenő adatok**: Hardver jelek és API hívások.
- **Kimenet / Visszajelzés**: Perifériák állapota.
- **Validációk és Kényszerek**: Nincs.

### FR-88: Korai replikáció és hírlevél modulok
- **Leírás**: Az adatok replikációja, a verziókövetés, valamint a belső hírlevél/hirdetmény küldési funkciók megvalósítása.
- **Forrás**: `Kósa Szervezés/Specifikációk/Névtelen dokumentum.docx` (1604-1608)
- **Prio**: Could
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Hírlevél szöveg.
- **Kimenet / Visszajelzés**: Kézbesített rendszerüzenetek.
- **Validációk és Kényszerek**: Nincs.

### FR-89: SQLite szinkronizációs hibák perzisztenciája és kijelzése
- **Leírás**: Az Electron kliens és a backend közötti szinkronizáció diagnosztizálhatósága érdekében a lokális SQLite `pending_transactions` tábláját ki kell egészíteni `sync_error` (TEXT), `retry_count` (INTEGER) és `last_attempt_at` (TEXT) mezőkkel. Szinkronizációs hiba esetén a sync engine a backend által visszadobott üzleti/validációs hibát köteles ebbe a mezőbe menteni, a kasszás felületen pedig külön hibajelentő vagy szinkron-napló nézetben megjeleníteni a pénztáros számára.
- **Forrás**: 2026-06-02 tranzakciós audit 2. pont
- **Prio**: Magas (P1)
- **Csomag/Komponens**: penztar-client
- **Bemenő adatok**: Backend sync válasz státusza és hibaüzenete
- **Kimenet / Visszajelzés**: SQLite tábla frissítése és hiba megjelenítése a kliensen

### FR-90: Értéktári készlet (vault-stock) RBAC hozzáférés
- **Leírás**: A lokális értéktári kliens `Értéktári készlet` (`/inventory`) oldalát kiszolgáló backend API `/api/v1/inventory/vault-stock` hozzáférését engedélyezni kell az `ERTEKTAR` szerepkörnek is (a meglévő `SUPERVISOR`, `MANAGER`, `ADMIN`, `FOERTEKTAR`, `UGYVEZETO`, `IRODAVEZETO` mellett). A backend service-nek a kérést az aktuális company és a dolgozó saját branch-e/értéktára szerint kell szűrnie, megelőzve az országos adatszivárgást.
- **Forrás**: 2026-06-02 Google OAuth audit
- **Prio**: Magas (P0)
- **Csomag/Komponens**: backend / frontend-react
- **Bemenő adatok**: Felhasználói JWT
- **Kimenet / Visszajelzés**: 200 OK és szűrt készletadat, feloldva a korábbi 403 Access Denied hibát
</functional_spec>

<data_structure>
## Logikai Adatmodell és Üzleti Szabályok (c.docm alapján)

A rendszer 11 alapvető üzleti szabállyal rendelkezik, amelyeket az adatmodell tervezése és a backend validációk megvalósítása során szigorúan be kell tartani.

### A 11 Üzleti Szabály:
1. **TEAOR hierarchia**: A saját cég TEAOR kódját a szervezeti hierarchia legalsó szintjén elhelyezkedő egységekből kell származtatni.
2. **Cím-validitás**: A rögzített címek hierarchiájának koherensnek kell lennie (pl. a közterületnek léteznie kell a megadott településen, a megyének az adott országban).
3. **Címletezés devizaneme**: A címletezés során rögzített devizanemnek meg kell egyeznie az egyenleg vagy pénztári mozgás devizaneméhez tartozó címlet devizanemével.
4. **Pénztár munkaállomása**: Desktop üzemmód esetén a pénztárat kötelezően hozzá kell rendelni egy konkrét fizikai munkaállomáshoz.
5. **Okmány-érvényesség**: Egy adott természetes személynek egy okmánytípusból (pl. személyi igazolvány) egyszerre kizárólag egyetlen érvényes okmánya lehet rögzítve.
6. **Transzfer kizárólagosság**: Pénzszállítási transzfer rögzítésekor a kiindulási és a cél helyszínek kizárólagosak (pl. nem lehet a kiindulási és a cél egység is egyszerre bank, vagy egyszerre telephely).
7. **Megye-ország reláció**: A megyéknek logikailag és adatbázis-szinten is az adott országhoz kell kapcsolódniuk.
8. **Munkaállomás fiókja**: Egy munkaállomás kizárólag a hozzárendelt telephelyen engedélyezett tevékenységekhez használható.
9. **Nyitott pénztár szabály**: Pénztári tranzakciót és pénzmozgást kizárólag nyitott pénztári időszakban lehet lekönyvelni.
10. **Rule_10**: (A PowerDesigner exportban szereplő szabály, amelynek leírása nem szerepelt a forrásban, Lásd: TBD-18).
11. **Ügyféltípus kizárólagosság**: Egy ügyféladatbázis-rekord logikailag vagy természetes személyhez, vagy céghez kell hogy tartozzon (XOR kapcsolat).

### Adattípus-domének:
- `bankszamlaszam`: VARCHAR(32)
- `belso_id`: BIGINT / INT64
- `bizonylatszam`: VARCHAR(64)
- `hosszu_nev`: VARCHAR(256)
- `igen_nem`: BOOLEAN
- `szazalek`: NUMERIC(5, 2)
- `arfolyam`: NUMERIC(12, 4)
- `osszeg`: NUMERIC(15, 2)
</data_structure>

<integration_points>
## Integrációs Pontok és Belső Függőségek
- **NAV Online Pénztárgép API**: Kapcsolat az online pénztárgéppel a bizonylatok beküldésére és a zárási/nyitási utasításokra (FR-80, FR-87).
- **OTP POS Terminál API**: A bankkártyás fizetések tranzakciós kezelésére és napi zárására (FR-81, FR-87).
- **Banki Árfolyam API**: Automatikus középárfolyam és elszámoló árfolyam adatok lekérése a kijelölt bankoktól (FR-71).
- **Kliens Szinkronizációs Szolgáltatás**: Az SQLite és Postgres adatbázisok közötti replikációért felelős modul (FR-86).
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- A logikai adatmodell (c.docm) alapján elkészíteni a PostgreSQL táblázatokat, biztosítva a domének és az egyedi azonosítók (internal_id) struktúráját.
- Beállítani az SQLite sémákat a kliensoldali `penztar-client` offline tárolásához.

### Fázis 2: Backend megvalósítás
- Megírni a 11 üzleti szabály validációs logikáját a backend szervizekben (pl. ügyfél XOR validáció, cím-hierarchia validáció).
- Elkészíteni az autentikációs, jelszócserés (3 havi szabály) és jogosultság-kezelési API végpontokat.
- Kialakítani az adat-replikációs és outbox naplózó modulokat.

### Fázis 3: Frontend / Kliens megvalósítás
- Megvalósítani a dashboard-ot és a 34 lépésből álló funkcionális képernyőket (HR kezelő, árfolyam-szerkesztő, bizonylat-sztornó, zárások).
- Lekódolni az Electron alapú kliensen a kijelentkezési szűrőt (lezáratlan folyamatok ellenőrzése).

### Fázis 4: Verifikáció
- Unit tesztek segítségével verifikálni a 11 üzleti szabály helyes működését (pl. hibás cím rögzítésekor dob-e hibát).
- Tesztelni a 3 havi kötelező jelszócsere prompt aktiválódását.
- Offline szinkronizáció (replikáció) működésének tesztelése hálózati kimaradás szimulálásával.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés / Kockázat | Hatás | Leírás |
|---|---|---|---|
| TBD-18 | Rule_10 üzleti szabály leírása | Adatmodell validáció | A c.docm adatmodell exportban szerepel a szabály, de a leírása hiányzik. Mit kell validálnia ennek a szabálynak? |
| TBD-19 | Szerepkörök kódértékei és jogai | Biztonság, RBAC | A forrás nem tartalmazza az egyes szerepkörökhöz (Pénztáros, Supervisor) tartozó pontos elemi jogosultság kódokat. |
| TBD-20 | Névtelen dokumentum üres pontjai | Fejlesztési scope | A dokumentum több pontja (verziókezelés, hírlevél, munkatárs adatok) üres fejlécként maradt meg. Ezeket meg kell-e valósítani? |
| TBD-21 | Pénzmosás elleni (AML) bejelentés | Compliance | A gyanús esetek bejelentésének pontos adattartalma és a hatósági beküldés technikai specifikációja nem ismert. |
| TBD-22 | Díjmértékek és kedvezmények modellje | Üzleti logika | A c.docm-ben szereplő díjtáblázatok fej/tétel struktúrájának részletes oszloplistája nem tisztázott. |
| TBD-23 | Konkurens árfolyamok felhasználása | Üzleti logika | Hogyan történik a konkurens árfolyamok betöltése (manuálisan vagy külső web-scraping útján), és hogyan befolyásolja a saját árfolyamokat? |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [ ] Minden funkcionális követelmény (FR-53-tól FR-88-ig) rendelkezik dokumentum-alapú forráshivatkozással.
- [ ] A 11 darab adatmodell-üzleti szabály pontosan rögzítésre került az adatstruktúra szekcióban.
- [ ] A 6 darab TBD kockázat dokumentált a TBD logban.
- [ ] A 3 havi kötelező jelszócsere szabály (NFR-13) bekerült a specifikációba.
- [ ] Nem lettek önkényesen új funkciók kitalálva a munkaterv 34 lépésén felül.
</verification_checklist>
