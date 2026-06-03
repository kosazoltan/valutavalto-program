# Modul: Igenyfelmeres es uzleti igenyek (Valuta)

<system_context>
## Rendszerkontextus és Háttér
Ez a dokumentum a Kósa-cégcsoport (Best Change valutapénztár) igényfelmérési interjúiban, valamint a folytatólagos kérdés-válasz jegyzetekben rögzített üzleti igényeket, fájdalompontokat és működési szabályokat tartalmazza, funkcionális követelményekké strukturálva.
A szervezet felépítése: ~180 fő munkavállaló, 62 fizikai valutapénztár, 8 régió és regionális értéktár. Követelmény a cégcsoport önálló tagjainak teljes körű adatszétválasztása (Valuta, Ékszer, Zálog).

### Szerepkörök (Roles)
| Szerep | Jogosultság / Feladatkör | RBAC érték |
|---|---|---|
| Pénztáros | Vétel/eladás/konverzió/foglaló rögzítése a kasszában, napi címletezés, napi nyitás/zárás végrehajtása. | TBD |
| Értéktáros | Pénzellátás szervezése, fiókok készletszintjének követése, banki ki- és beszállítások bonyolítása, értéktárosi jelszó megadása árfolyam-módosításokhoz. | TBD |
| Főértéktáros | Globális árfolyamok meghatározása és kiküldése a fiókoknak, elszámoló és átlagárfolyamok számítása, napi fixing. | TBD |
| Területi vezető | Régió személyi/tárgyi feltételeinek kezelése, sztornó és zárási jóváhagyások megadása. | TBD |
| Belsőellenőr | Belsőellenőri supervisori jelszó birtoklása (sztornók feloldása 3 darab felett, bizonylatok újranyomtatása). | TBD (Lásd: TBD-1) |
| Ügyvezető / Admin | Alaptőke szintek meghatározása, rendszerszintű globális paraméterek kezelése. | TBD |

### Hatókör (Scope)
#### IN
- Cégcsoport-szervezet fiók- és értéktár-struktúrája.
- Valutaváltási üzleti folyamatok: vétel, eladás, keresztváltás (konverzió), kezelési költségek elkülönítése.
- Bizonylatszámozási sémák és sztornó korlátozások (szerepkörök szerinti limitek).
- Pmt./AML szabályok: 300 000 Ft feletti és jogi személy 5 Ft-os azonosítási küszöbök, PEP nyilatkozatok, szankciós listák és forrásigazolási kötelezettség.
- Kedvezményes és egyedi árfolyamok, 2%-os jóváhagyási küszöb, elszámoló és átlagárfolyamok.
- Külső integrációk: online pénztárgép, banki napi/havi elszámolások, jutalékok, tranzakciós illeték.
- Foglalók kezelése, pénztárközi plombált szállítások, valuta-igények generálása.
- Integráció könyvelési szoftverekkel (RLB, Kulcs-Soft stb.) és banki felületekkel (Raiffeisen Elektra).

#### OUT
- Az Ékszer és Zálog cégek belső részletes folyamatai (kivéve a közös HR/személyzeti törzset).
- Technikai hálózati és infrastruktúra felmérés részletei.

### Technológiai verem (Tech Stack)
- Backend API réteg (`backend`)
- Pénztár kliens (`penztar-client`)
- Adminisztrációs és vezetői portál (`kozponti-client` és `arfolyam-keszito-client`)
- Kliensoldali offline SQLite adatbázisok a netkapcsolat nélküli működéshez (Vodafone 30 GB-os mobilnet-kapcsolatok miatt)
- Központi PostgreSQL adatbázisok (cégenként fizikailag vagy logikailag elválasztott instanciákban, NFR-02)
</system_context>

<functional_spec>
## Funkcionális követelmények (FR)

### FR-01: Napi zárás kikényszerítése kilépéskor
- **Leírás**: A rendszernek a munkanap végén, a tervezett zárási időpont előtt kb. 30 perccel a programból való kilépés megkísérlésekor erősen fel kell ajánlania a napi zárás elvégzését. Külön megerősítő művelet szükséges a zárás nélküli kilépéshez.
- **Forrás**: `kerdesek.docx` (665, 691)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Rendszeridő, zárás állapota.
- **Kimenet / Visszajelzés**: Figyelmeztető felugró ablak.
- **Validációk és Kényszerek**: Nincs.

### FR-02: Bizonylatszámozás és prefixek szabálya
- **Leírás**: A bizonylatszámnak tartalmaznia kell a pénztár 3-jegyű azonosító kódját és egy folyamatos, kihagyásmentes sorszámot. A bizonylat típusát az alábbi betűprefixekkel kell jelölni:
  - V: Vétel
  - E: Eladás
  - F: Konverziós vétel
  - U: Konverziós eladás
  - FF: Pénztárközi átadás
  - UF: Pénztárközi átvétel
  - B: Kezelési díj/foglaló átvétel
  - K: Kezelési díj/foglaló átadás (kifizetés)
- **Forrás**: `kerdesek.docx` (666, 692-704)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Tranzakció típus, pénztár kód.
- **Kimenet / Visszajelzés**: Generált bizonylatszám.
- **Validációk és Kényszerek**: A sorszám folytonosságát (szekvenciáját) szigorúan ellenőrizni kell az adatbázisban.

### FR-03: Árfolyam-kedvezmény supervisori gate
- **Leírás**: Ha a megadott egyedi árfolyam a napi hivatalos árfolyamtáblától több mint 2%-kal tér el az ügyfél javára, a tranzakció rögzítését blokkolni kell. A feloldáshoz értéktárosi supervisori jelszó megadása szükséges (TBD-5).
- **Forrás**: `kerdesek.docx` (667, 705)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Tranzakciós árfolyam, hivatalos árfolyam, supervisor jelszó.
- **Kimenet / Visszajelzés**: Engedélyezett vagy elutasított váltás.
- **Validációk és Kényszerek**: A 2%-os határérték számítása automatikus.

### FR-04: Elszámoló árfolyam kezelése
- **Leírás**: A főértéktáros határozza meg a napi elszámoló árfolyamokat. A rendszernek a napi Forint-ellenérték elszámolást ezen az árfolyamon kell elvégeznie, míg a hónap utolsó napján az MNB hivatalos záróárfolyamával kell elszámolnia.
- **Forrás**: `kerdesek.docx` (706)
- **Prio**: Must
- **Csomag/Komponens**: `backend` / `arfolyam-keszito-client`
- **Bemenő adatok**: Főértéktár által beküldött elszámoló árfolyamok.
- **Kimenet / Visszajelzés**: Elszámolási jelentés.
- **Validációk és Kényszerek**: Nincs.

### FR-05: Átlagárfolyam kimutatás generálása
- **Leírás**: A főértéktáros számára biztosítani kell egy olyan riport-felületet, amely egy adott időszak tényleges vételi és eladási árfolyamaiból kiszámítja az átlagárfolyamokat valutánként.
- **Forrás**: `kerdesek.docx` (706, 800)
- **Prio**: Should
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Időszak (kezdő/vég dátum).
- **Kimenet / Visszajelzés**: Átlagárfolyam jelentés.
- **Validációk és Kényszerek**: Nincs.

### FR-06: Pénzkivét tiltása működési költségekre
- **Leírás**: A rendszernek fizikailag meg kell akadályoznia, hogy a valutaváltó szoftverből működési költségek (pl. irodaszer, rezsi) fedezésére pénzt vegyenek ki a kasszából. A pénzkivét ezen típusa szigorúan tiltott.
- **Forrás**: `kerdesek.docx` (669, 707)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Pénztári kiadás kategória.
- **Kimenet / Visszajelzés**: Hibaüzenet, művelet letiltása.
- **Validációk és Kényszerek**: Csak az engedélyezett pénztárközi vagy értéktári kiadások engedélyezettek.

### FR-07: Közszereplői (PEP) státusz rögzítése
- **Leírás**: Az ügyfél azonosításakor kötelezővé kell tenni a kiemelt közszereplői státusz kiválasztását egy törvényi listából. Az adatot fel kell tüntetni a kinyomtatott bizonylaton, amit az ügyfél aláírásával igazol.
- **Forrás**: `kerdesek.docx` (673, 711)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: PEP státusz kiválasztás (pl. "nem közszereplő", "közszereplő rokon").
- **Kimenet / Visszajelzés**: Mentett PEP snapshot a tranzakciónál.
- **Validációk és Kényszerek**: A nyilatkozat kitöltése nélkül a tranzakció nem könyvelhető.

### FR-08: Banki valuta-átvétel automatikus ellenoldali rögzítése
- **Leírás**: Ha a bankból valutát vesznek át, nem kell külön kézzel banki bizonylatot kiállítani; a rendszer a saját értéktári átvételi bizonylat (UF) ellenpárjaként automatikusan könyveli a banki tranzakciót.
- **Forrás**: `kerdesek.docx` (676, 714)
- **Prio**: Should
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Értéktári UF bizonylat.
- **Kimenet / Visszajelzés**: Generált ellenoldali banki tranzakció.
- **Validációk és Kényszerek**: Nincs.

### FR-09: Bizonylat újranyomtatás ellenőrzése
- **Leírás**: Korábban kiadott bizonylatot kizárólag belsőellenőri supervisori jelszó megadása után, az újranyomtatás okának kötelező szöveges beírásával engedélyezhet a rendszer.
- **Forrás**: `kerdesek.docx` (677, 715)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Bizonylatszám, supervisor jelszó, indoklás.
- **Kimenet / Visszajelzés**: Újraindított nyomtatás.
- **Validációk és Kényszerek**: A másolatokon a "MASOLAT" vagy "MASOLATI PELDANY" feliratnak kötelezően meg kell jelennie.

### FR-10: Kezelési költség és Valuta kasszák fizikai elkülönítése
- **Leírás**: A kezelési költségek Forint egyenlegét és a devizaváltási készlet (valuta kassza) egyenlegét a rendszernek teljesen különálló kasszaként kell kezelnie. A két kassza közötti közvetlen átvezetés szigorúan tilos.
- **Forrás**: `kerdesek.docx` (679, 717, 352)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Tranzakció könyvelés.
- **Kimenet / Visszajelzés**: Kasszaegyenlegek elkülönítése.
- **Validációk és Kényszerek**: Nincs.

### FR-11: Sztornó limitek és jóváhagyások
- **Leírás**: Minden pénztár jogosult helyben bizonylatot sztornózni az ok megadásával. Ha az adott napon a pénztárban a sztornózott tételek száma eléri a 3-at, a további sztornókat a rendszer blokkolja, és a feloldáshoz belsőellenőri jelszó szükséges.
- **Forrás**: `kerdesek.docx` (680, 718, 725)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Bizonylatszám, sztornó ok, belsőellenőri jelszó (3. felett).
- **Kimenet / Visszajelzés**: Sztornózott bizonylat státusz.
- **Validációk és Kényszerek**: Csak aznapi bizonylat sztornózható (FR-80).

### FR-12: Sztornó küldése az online pénztárgépre (NAV)
- **Leírás**: A sztornózás során nem kell külön kézzel megadni NAV-bizonylatszámot; a program automatikusan párosítja a korábbi tranzakcióhoz tartozó NAV nyugtaszámot, és kiküldi a sztornó parancsot az online pénztárgép felé.
- **Forrás**: `kerdesek.docx` (681, 719)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Sztornózott bizonylat rekordja.
- **Kimenet / Visszajelzés**: NAV pénztárgép sztornó bizonylat nyomtatása.
- **Validációk és Kényszerek**: Nincs.

### FR-13: Tranzakciós illeték automatikus kalkulációja
- **Leírás**: A rendszernek a váltási tranzakcióknál automatikusan ki kell számolnia a tranzakciós illetéket: 4,5 millió HUF váltási érték alatt a tranzakció értékének 4,5 ezreléke, míg 4,5 millió HUF felett fixen 20 000 HUF tételenként (NAV-felé bevallandó).
- **Forrás**: `kerdesek.docx` (683, 721)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Tranzakció összege (HUF-érték).
- **Kimenet / Visszajelzés**: Számított tranzakciós illeték.
- **Validációk és Kényszerek**: Nincs.

### FR-14: Pénztár nyitva/zárva állapotának követése szerveroldalon
- **Leírás**: Ha a szerveren egy pénztár állapota a tárgynapra "NEM ÜZEMEL" (zárva tart), a szerver nem várhatja el a napi zárási adatok megérkezését, és ki kell hagynia a napi zárási ellenőrző listából.
- **Forrás**: `kerdesek.docx` (684, 722, 791)
- **Prio**: Must
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Pénztár naptár és üzemelési státusz.
- **Kimenet / Visszajelzés**: Automatikus napi riport kihagyás.
- **Validációk és Kényszerek**: Nincs.

### FR-15: Pénztárközi mozgások online pénztárgépes lejelentése
- **Leírás**: A pénztár-pénztár vagy értéktár-pénztár közötti fizikai készletmozgások (FF és UF bizonylatok) adatait is kötelezően ki kell küldeni az online pénztárgép (NAV) felé.
- **Forrás**: `kerdesek.docx` (685, 723)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Készletmozgás bizonylat.
- **Kimenet / Visszajelzés**: Pénztárgép szalag nyomtatás.
- **Validációk és Kényszerek**: Nincs.

### FR-16: Banki pénzszállítások betűjelölése
- **Leírás**: A bankba történő készpénzszállításokat a fiókok közötti átadásokkal azonosan kell kezelni, külön betűjelöléses technikai pénztárak (ERB / TRB / FRB) célként való megjelölésével.
- **Forrás**: `kerdesek.docx` (729, 734)
- **Prio**: Should
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Szállítási cél.
- **Kimenet / Visszajelzés**: Transzfer bizonylat.
- **Validációk és Kényszerek**: Nincs.

### FR-17: Hamisgyanús bankjegyek TH pénztárba könyvelése
- **Leírás**: Az MNB technikai társpénztár kivezetésre került; a rendszerben talált hamisgyanús valutákat és forintokat a TH (Többlet-hiány) technikai pénztárba kell lekönyvelni.
- **Forrás**: `kerdesek.docx` (730, 735)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Hamisgyanús jegyzőkönyv adatok.
- **Kimenet / Visszajelzés**: TH egyenleg növekedés.
- **Validációk és Kényszerek**: Nincs.

### FR-18: Keresztváltás (Konverzió) kezelése
- **Leírás**: A devizák közötti keresztváltást (pl. EUR-ról USD-re váltás) a törvényi előírásoknak megfelelően két külön bizonylatként kell lekönyvelni: egy konverziós vételi (F prefix) és egy konverziós eladási (U prefix) tranzakcióként. A kezelési díjat mindkét bizonylaton el kell engedni. Sztornózás esetén mindkét bizonylatot sztornózni kell (2 db sztornó művelet).
- **Forrás**: `kerdesek.docx` (731, 737, 779)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Forrás deviza, cél deviza, összeg.
- **Kimenet / Visszajelzés**: F és U bizonylatok generálása.
- **Validációk és Kényszerek**: Nincs.

### FR-19: Anonim visszaélés-bejelentés biztonsága
- **Leírás**: A rendszerben elérhetővé tett névtelen bejelentő modulnak garantálnia kell, hogy a beküldő felhasználó személye semmilyen módon (IP cím, ID, időpont) ne legyen visszakereshető az adatbázisból. A végleges elküldés előtt a bejelentés a kilépéssel visszavonható legyen.
- **Forrás**: `kerdesek.docx` (739, 767, 783)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Bejelentés szöveges tartalma.
- **Kimenet / Visszajelzés**: Rögzített üzenet.
- **Validációk és Kényszerek**: Az adatbázisban a létrehozó mezőnek kötelezően üresnek/null-nak kell lennie.

### FR-20: AML azonosítási küszöbök és törlési tilalmak
- **Leírás**: A rendszernek kötelezően teljes KYC ügyfél-azonosítást kell kérnie:
  - 300 000 HUF váltási érték feletti természetes személyeknél,
  - jogi személyek (cégek) esetén 5 HUF váltási értéktől,
  - kiemelt közszereplők esetén (PEP) 5 HUF-tól.
  - Ha az ügyfél a rendszerben valaha 300 000 HUF feletti váltást hajtott végre, az adatlapját és az azonosító adatait biztonsági okokból tilos törölni a rendszerből.
- **Forrás**: `kerdesek.docx` (742, 790, 797-798)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Ügyfél okmányok, váltási összeg.
- **Kimenet / Visszajelzés**: Azonosított tranzakció.
- **Validációk és Kényszerek**: A határértékek átlépésekor a rendszer blokkolja a tranzakciót az adatok hiánytalan kitöltéséig.

### FR-21: Foglaló rögzítési és elszámolási szabályai
- **Leírás**: A foglaló felvételekor az ügylet teljesítési határideje alapértelmezésben a következő munkanap. Az 5 napnál hosszabb határidő megadása kizárólag supervisori jelszóval engedélyezhető. A foglaló kizárólag készpénzben fizethető be, és nem könyvelődik fel a központi szerverre a teljesítésig (helyi SQLite-ban marad, Lásd: TBD-9).
- **Forrás**: `kerdesek.docx` (754, 761, 774)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Foglaló határidő, összeg.
- **Kimenet / Visszajelzés**: Helyi foglaló bizonylat nyomtatása.
- **Validációk és Kényszerek**: Csak készpénzes HUF fizetési mód választható.

### FR-22: Új pénztárak felvétele és törlése
- **Leírás**: Biztosítani kell a társpénztárak listájának szerkesztését (új pénztár felvétele). A meglévő egységek inaktiválása vagy törlése kizárólag kiemelt supervisori jogosultsággal lehetséges.
- **Forrás**: `kerdesek.docx` (752)
- **Prio**: Should
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Pénztár törzsadatok.
- **Kimenet / Visszajelzés**: Frissített globális pénztár lista.
- **Validációk és Kényszerek**: Nincs.

### FR-23: Készleteltérések és visszapótlások könyvelése
- **Leírás**: Ha a fizikai készlet és a könyvelt egyenleg között eltérés van (pl. kevesebb/több Forint van a kasszában), az eltérést a TH (Többlet-hiány) pénztárral szemben kell lekönyvelni. A készlethiány fizikai visszapótlását (pl. Forint betét) a rendszernek az 1. számú főpénztárral szemben kell lekönyvelnie.
- **Forrás**: `kerdesek.docx` (759)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Eltérés összege.
- **Kimenet / Visszajelzés**: Eltérés bizonylat.
- **Validációk és Kényszerek**: Nincs.

### FR-24: Díjkedvezmények típusai és felülírásuk
- **Leírás**: A rendszernek támogatnia kell a százalékos és a sávos díjkedvezményeket. Lehetővé kell tenni a kezelési díj felezését (értéktári engedélyhez kötötten), bankkártyás fizetés esetén a kezelési díj eltörlését, valamint bármely egyedi egyeztetett díj megadását supervisori jóváhagyással.
- **Forrás**: `kerdesek.docx` (768, 793, 786)
- **Prio**: Should
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Kedvezmény típus, jóváhagyó kód.
- **Kimenet / Visszajelzés**: Csökkentett kezelési költség.
- **Validációk és Kényszerek**: Nincs.

### FR-25: Compliance szankciós lista folyamatos szinkronizációja
- **Leírás**: A rendszernek automatikusan le kell töltenie az új szankciós és tiltólistákat, és folyamatosan frissítenie kell a lokális klienseket. Ha a pénztáros olyan ügyfelet azonosít, aki szerepel a tiltólistán, a programnak azonnal le kell tiltania a váltást és ki kell léptetnie a pénztárost a tranzakcióból. Feloldás csak forrásigazolás bemutatása és supervisori jelszó után lehetséges.
- **Forrás**: `kerdesek.docx` (775, 784, 812)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Ügyfél név, okmányszám, szankciós adatbázis.
- **Kimenet / Visszajelzés**: Tranzakció azonnali blokkolása.
- **Validációk és Kényszerek**: Valós idejű szűrés a névbeírás során.

### FR-26: Plombaszám formátum szabálya
- **Leírás**: A szállítási bizonylatokon megadott plombaszámnak maximum 10 karakter hosszúságú, tetszőleges betű- és számkombinációnak kell lennie (pénzszállító biztonsági tasak azonosítója). Vonalkódos szkennelés nem támogatott.
- **Forrás**: `kerdesek.docx` (785)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: 10 karakteres plombaszám.
- **Kimenet / Visszajelzés**: Rögzített plombaszám.
- **Validációk és Kényszerek**: Karakterhossz validáció (max 10).

### FR-27: Bankkártyás POS tranzakciók kezelése
- **Leírás**: A bankkártyás fizetések kezelése során a rendszernek tudnia kell, hogy a kártyás fizetés extra +1 HUF díjat jelent a cég számára (technikai kerekítés miatt), és a banki POS tranzakciós költségeket tilos az ügyfélre áthárítani.
- **Forrás**: `kerdesek.docx` (786)
- **Prio**: Could
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Kártyás fizetés ténye.
- **Kimenet / Visszajelzés**: Könyvelt tranzakció.
- **Validációk és Kényszerek**: Nincs.

### FR-28: Banki valuta fixing folyamat
- **Leírás**: A főértéktáros számára egy olyan felületet kell biztosítani, ahol a ritkább devizák (pl. RON) napi banki értékesítéséhez (fixing) szükséges adatokat tudja leadni a bank felé tárgynap 11:00 óráig. Az árfolyamot 2 tizedes pontossággal kell kezelni, és a Forint ellenértéktől való eltérés tilos.
- **Forrás**: `kerdesek.docx` (788-789)
- **Prio**: Should
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Fixing mennyiség, árfolyam.
- **Kimenet / Visszajelzés**: Exportálható fixing adatállomány.
- **Validációk és Kényszerek**: 11:00 után a leadás nem lehetséges.

### FR-29: Napi banki tranzakciós riport szűrése
- **Leírás**: A Raiffeisen felé küldendő napi Darius export jelentésbe kizárólag a 300 000 HUF feletti, teljes körűen azonosított tranzakciókat szabad beemelni.
- **Forrás**: `kerdesek.docx` (790)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Napi tranzakciós napló.
- **Kimenet / Visszajelzés**: Darius XML/CSV jelentésfájl.
- **Validációk és Kényszerek**: Az azonosítatlan kis összegű tételeket ki kell szűrni.

### FR-30: NAV pénztárgép XML adatstruktúra
- **Leírás**: A fizikai online pénztárgép felé kiküldendő XML struktúrának tartalmaznia kell: váltás valutaneme, váltott deviza összeg, alkalmazott árfolyam, felszámított kezelési költség, kifizetendő Forint érték, deviza-státusz, tranzakció dátuma és időpontja, valamint a pénztár neve és címe.
- **Forrás**: `kerdesek.docx` (762, 590)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Lezárt váltási tranzakció adatai.
- **Kimenet / Visszajelzés**: XML adatfolyam a pénztárgép felé.
- **Validációk és Kényszerek**: Megfelelés a hatályos NAV XML sémának.

### FR-31: Tab-füles munkavállaló adatlap
- **Leírás**: A központi HR felületen a munkavállalók adatait tab-füles elrendezésben kell megjeleníteni a meglévő Zálog modul adatmezőinek sémájával konzisztensen.
- **Forrás**: `RSL 2. Igényfelmérési interjú összefoglaló 2024.02.15_.docx` (132-136)
- **Prio**: Should
- **Csomag/Komponens**: `kozponti-client`
- **Bemenő adatok**: Alkalmazott törzsadatok.
- **Kimenet / Visszajelzés**: HR adatlap.
- **Validációk és Kényszerek**: Nincs.

### FR-32: RLB könyvelési feladás kerekítéspontossága
- **Leírás**: Az RLB könyvelési szoftver felé történő automatikus feladásnak a készletnyilvántartóból és bevételekből kell készülnie. Biztosítani kell a fillér-pontos egyezést a könyvelés felé, az eltérés szigorúan tilos.
- **Forrás**: `RSL 2. Igényfelmérési interjú összefoglaló 2024.02.15_.docx` (149-155)
- **Prio**: Should
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Könyvelési napló tételek.
- **Kimenet / Visszajelzés**: RLB import fájl.
- **Validációk és Kényszerek**: Kerekítési hiba miatti eltérés nem engedélyezett.

### FR-33: Teljes adat-elkülönítés a cégek között
- **Leírás**: Biztosítani kell az Ékszer, Zálog és Valuta cégek közötti teljes fizikai vagy logikai adat-elkülönítést. A controlling adatoknak és tranzakciós naplóknak különálló adatbázisokban kell lenniük, adatok összemosása szigorúan tilos.
- **Forrás**: `RSL Igényfelmérési interjú összefoglaló 2024.02.12_.docx` (316-321, 358)
- **Prio**: Must
- **Csomag/Komponens**: `backend`
- **Bemenő adatok**: Adatbázis konfiguráció.
- **Kimenet / Visszajelzés**: Elkülönített adatbázis táblák.
- **Validációk és Kényszerek**: Megfelelés a multi-tenant adatvédelmi elveknek.

### FR-34: Pénztár-specifikus árfolyamok kijelzése
- **Leírás**: Lehetővé kell tenni, hogy a főértéktár a fiókok számára egyedileg határozza meg a megjelenített árfolyamokat. A kiküldött adatoknak 5-20 percen belül frissülniük kell a fizikai kijelzőkön.
- **Forrás**: `RSL Igényfelmérési interjú összefoglaló 2024.02.12_.docx` (361-364)
- **Prio**: Must
- **Csomag/Komponens**: `kozponti-client` / `penztar-client`
- **Bemenő adatok**: Fiók egyedi árfolyamtáblája.
- **Kimenet / Visszajelzés**: Kijelző frissítése a fiókban.
- **Validációk és Kényszerek**: Nincs.

### FR-35: Okmányszkennelés és Raiffeisen megfelelőség
- **Leírás**: Biztosítani kell a személyazonosító igazolvány és lakcímkártya beolvasását és a tranzakcióhoz történő csatolását a Raiffeisen audit megfelelőség érdekében.
- **Forrás**: `RSL Igényfelmérési interjú összefoglaló 2024.02.12_.docx` (374-375)
- **Prio**: Should
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Szkennelt dokumentum képek.
- **Kimenet / Visszajelzés**: Tranzakcióhoz kapcsolt PDF/kép.
- **Validációk és Kényszerek**: Biztonságos tárolás.

### FR-36: Offline működési korlátozások
- **Leírás**: Hálózati hiba esetén a kliensnek 5 percenként meg kell kísérelnie az árfolyamok frissítését. Tartós offline mód esetén a legutolsó érvényes árfolyamtáblával kell dolgozni, és az egyedi árfolyamok sávos kedvezményes kalkulációját le kell tiltani (csak fix kézi árfolyam adható meg).
- **Forrás**: `RSL 2. Igényfelmérési interjú összefoglaló 2024.02.15_.docx` (576); `kerdesek.docx` (756)
- **Prio**: Must
- **Csomag/Komponens**: `penztar-client`
- **Bemenő adatok**: Hálózati státusz, legutóbbi lokális árfolyamok.
- **Kimenet / Visszajelzés**: Offline váltási üzemmód.
- **Validációk és Kényszerek**: Offline módban a tranzakciókat a helyi SQLite-ban kell tárolni a szinkronizáció visszaállásáig.
</functional_spec>

<data_structure>
## Javasolt Adatmodell és Séma (SQLite és Postgres Tükör)

A lokális offline működés (Vodafone mobilnet szakadozás, NFR-06) és a Pmt. szankciós listák miatt a kliensoldali SQLite mirror-ban az alábbi táblák kötelezőek.

### SQLite és Postgres táblák:

#### 1. `ugyfelek`
Az azonosított természetes és jogi személyek.
- `id` (SERIAL / INTEGER PRIMARY KEY)
- `tipus` (VARCHAR(20) NOT NULL) -- MAGAN, CEG
- `nev` (VARCHAR(100) NOT NULL)
- `okmany_tipus` (VARCHAR(50))
- `okmany_szam` (VARCHAR(50) UNIQUE)
- `pep_statusz` (VARCHAR(50) NOT NULL DEFAULT 'NEM_KOZSZERELO')
- `utolso_valtas_ertek_huf` (NUMERIC(15, 2))
- `torolheto` (BOOLEAN DEFAULT TRUE) -- Ha valaha váltott 300 e Ft felett, akkor FALSE (FR-20)

#### 2. `szankcios_lista`
Szinkronizált tiltólista a helyi szűréshez.
- `id` (SERIAL / INTEGER PRIMARY KEY)
- `nev` (VARCHAR(100) NOT NULL)
- `szuletesi_datum` (DATE, Nullable)
- `allampolgarsag` (VARCHAR(50), Nullable)
- `statusz` (VARCHAR(20) DEFAULT 'AKTIV')

#### 3. `foglalok_ideiglenes` (Kizárólag SQLite)
A foglalók lokális tárolására, amelyek nem kerülnek fel a szerverre a teljesítésig.
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `ugyfel_id` (INTEGER)
- `osszeg_deviza` (NUMERIC(15, 2))
- `devizanem` (VARCHAR(3))
- `foglalo_huf` (NUMERIC(15, 2))
- `hatarido` (DATE)
- `fizetve` (BOOLEAN DEFAULT FALSE)
</data_structure>

<integration_points>
## Integrációs Pontok és Belső Függőségek
- **Raiffeisen Darius & Elektra**: Napi tranzakciós adatok feladása a Darius interfészen keresztül (Darius XML export, FR-29).
- **Online Pénztárgép (NAV)**: XML nyugta- és pénzmozgás adatok küldése az online pénztárgép felé (FR-30).
- **Könyvelő rendszerek (RLB, Kulcs-Soft)**: Automatikus havi feladások készítése a készlet- és forgalmi adatokról (FR-32).
- **OTP POS bankkártya terminál**: Bankkártyás fizetési tranzakciók szinkronizálása.
</integration_points>

<execution_workflow>
## Végrehajtási folyamat az AI Agent számára

### Fázis 1: Előkészítés
- Létrehozni a szankciós listák adatbázis sémáit és a lokális SQLite táblákat (pl. ideiglenes foglalók táblája).
- Beállítani a 1920x1080-as minimális képernyő-felbontás frontend korlátait (NFR-01).

### Fázis 2: Backend megvalósítás
- Megvalósítani a 300 000 HUF feletti AML azonosítási és a 10 milliós tranzakció-jóváhagyási logikákat.
- Elkészíteni az RLB és Darius XML generátorokat, garantálva a fillér-pontos kerekítést.
- Kialakítani a névtelen bejelentő backend-szolgáltatást (mentéskor a bejelentő adatainak kötelező eldobásával).

### Fázis 3: Frontend megvalósítás
- Megvalósítani a keresztváltás kétbizonylatos felületét (FR-18).
- Lekódolni az okmányszkennelő integrációt.
- Elkészíteni a 2%-os jóváhagyási küszöbhöz tartozó supervisor jelszó-felugró panelt.

### Fázis 4: Verifikáció és Tesztelés
- Tesztelni az offline fallbacks-et: hálózati kapcsolat megszakítása esetén az árfolyam lekérdezés leáll-e, és engedi-e a manuális rögzítést a legutolsó lokális árfolyamon.
- Ellenőrizni, hogy a tiltólistás ügyfél rögzítésekor a rendszer valóban megszakítja-e a váltási folyamatot.
- Validálni a 300 ezer HUF feletti ügyfelek törlésének tilalmát.
</execution_workflow>

<tbd_log>
## Nyitott kérdések és Kockázatok (TBD)
| # | Kérdés / Kockázat | Hatás | Leírás |
|---|---|---|---|
| TBD-1 | Belsőellenőri supervisori jelszavak | Biztonság | A bizonylat újranyomtatásához és a 3. sztornó feletti műveletekhez szükséges jelszavak kiosztásának szabályai nem ismertek. |
| TBD-2 | "Maradék Forint" mező | Készletvezetés | Az igényfelmérés során az ügyfél nem tudta megválaszolni a "maradék Forint" mező pontos üzleti jelentését. |
| TBD-3 | Pénztári nyitó adatok mezői | Zárás / Nyitás | Nem tisztázott, hogy az ügyfél melyik menüpont alatt várja a napi nyitó forgalmi adatok részletezését. |
| TBD-4 | Jutalék mező a kezelési költség riportban | Üzleti riportok | Nem tisztázott, hogyan kapcsolódik a jutalék a kezelési költségek napi jelentéséhez. |
| TBD-5 | Engedélyező kódok generálási algoritmusa | Biztonság | A kedvezmények jóváhagyásához használt supervisor kódok generálási algoritmusa külön jelszavas e-mailben van, nem része a forrásnak. |
| TBD-6 | Fiscat NAV-protokoll "11"-es kód | NAV-integráció | A Fiscat pénztárgép leírásából hiányzik a "11"-es hibakód definíciója. |
| TBD-7 | Alaptőke nyilvántartás a valutarendszerben | Controlling | Kell-e a valutarendszernek az alaptőkét nyilvántartania, vagy az továbbra is kizárólag Excelben marad? |
| TBD-8 | Havi forgalom trendszámítás képlete | Riportok | Hogyan számolandó a havi forgalmi trendek százalékos értéke? |
| TBD-9 | Foglaló könyvelése és NAV-feladása | Jogi megfelelés | A foglaló könyvelési és adózási lejelentési kötelezettsége tisztázásra vár a könyvelők felől. |
| TBD-10 | Prior Kft. pénztárgép napzárási paraméterei | NAV-integráció | A Prior Kft. online pénztárgép napzárási paraméterei (PLU, Exchange státuszok) a gyártó válaszára várnak. |
| TBD-11 | Bank felé történő változás-jelentések | Banki integráció | A Raiffeisen felé küldendő napi/időszaki változás-riportok pontos mezőszerkezete nem tisztázott. |
</tbd_log>

<verification_checklist>
## Verifikációs Checklist
- [ ] Minden funkcionális követelmény (FR-01-től FR-36-ig) rendelkezik legalább egy dokumentált forráshivatkozással.
- [ ] A 11 darab TBD kérdés bekerült a TBD kockázati naplóba.
- [ ] A 300 000 HUF feletti és jogi személy 5 HUF feletti AML azonosítási határértékek rögzítve lettek (FR-20).
- [ ] A kétbizonylatos keresztváltási (konverziós) szabály pontosan megőrzésre került (FR-18).
- [ ] Nem lett új, a forrásinterjúkban nem szereplő funkció vagy külső integráció kitalálva.
</verification_checklist>
