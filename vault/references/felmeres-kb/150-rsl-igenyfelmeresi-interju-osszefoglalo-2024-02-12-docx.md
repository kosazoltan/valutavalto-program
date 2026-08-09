---
title: RSL Igényfelmérési interjú összefoglaló 2024.02.12_.docx
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/Igényfelmérési interjú/RSL Igényfelmérési interjú összefoglaló 2024.02.12_.docx
doc_type: word
---

# RSL Igényfelmérési interjú összefoglaló 2024.02.12_.docx

**Kategoria:** altalanos  |  **Tipus:** word  |  **Meret:** 840.0 KB
**Eredeti utvonal:** `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/Igényfelmérési interjú/RSL Igényfelmérési interjú összefoglaló 2024.02.12_.docx`

## Tartalom

Rate Software Licence Kft.
Igényfelmérési interjú 
2024. 02. 12. hétfő 13 óra
A cégcsoport feltérképezése
Cégcsoport összetételének azonosítása:
Azonosítani, amik a cégcsoport részét képezik. Ezek a cégek/vállalatok lehetnek közvetlenül vagy közvetetten összekapcsolva.
Szervezeti struktúra elemzése: 
Az összes azonosított vállalat szervezeti struktúrájának és kapcsolatainak elemzése. Ez magában foglalja a vállalatok közötti tulajdoni kapcsolatokat, irányítási struktúrát, döntéshozatali mechanizmusokat stb.
Pénzügyi elemzés: 
A cégcsoport pénzügyi adatainak áttekintése, beleértve a bevételeket, költségeket, nyereséget, adózást, valamint a pénzügyi állapotot és likviditást. Fontos azonosítani az esetleges pénzügyi kockázatokat és lehetőségeket.
Üzleti tevékenységek elemzése: 
Az összes vállalat üzleti tevékenységének részletes elemzése. Fontos megérteni, hogy milyen termékeket vagy szolgáltatásokat kínálnak, milyen piacokon működnek, és milyen versenyhelyzetben vannak, hogyan illeszkedik az informatikai rendszer a cégcsoport üzleti céljaihoz és folyamataihoz.
Szabályozási elemzés: 
A cégcsoportra vonatkozó összes jogi és szabályozási követelmény áttekintése. Ez magában foglalja az adózási követelményeket, iparági előírásokat, munkaügyi szabályokat és egyéb releváns jogszabályokat.
Kockázatok azonosítása: 
Az összes lehetséges kockázat feltérképezése, beleértve a pénzügyi, operatív, jogi, környezeti és más területeken jelentkező kockázatokat. Fontos megérteni, hogy mely tényezők veszélyeztethetik a cégcsoportot és annak üzleti életképességét.
Felhasználói igények és elvárások: 
Kérdezzük meg az informatikai rendszerrel kapcsolatos elvárásaikról és szükségleteikről, hogy milyen funkciókra van szükségük, hogy hatékonyan végezhessék a munkájukat.
Műszaki követelmények és infrastruktúra: 
Ismerjük meg az informatikai infrastruktúrát és a meglévő technológiai környezetet. Kérdezzük meg az IT-szakembereket az infrastrukturális követelményekről és a jelenlegi rendszer esetleges korlátairól.
Adatkezelés és biztonság: 
Beszéljünk az adatkezelési elvekről, a biztonsági követelményekről és az adatvédelmi előírásokról. Kérdezzük meg, hogy milyen adatokat kell kezelni és milyen biztonsági intézkedéseket kell bevezetni.
Integrációs és migrációs igények: 
Kérdezzük meg az esetleges rendszer integrációról és adat migrációról. Fontos megérteni, hogy az új rendszernek hogyan kell integrálódnia a meglévő rendszerekkel és hogyan lehet zökkenőmentesen migrálni az adatokat.
Stratégia kidolgozása: 
Az összegyűjtött információk alapján stratégia kidolgozása a cégcsoport számára, ami segít kihasználni a lehetőségeket és minimalizálni a kockázatokat. 
Általános információk
A megbeszélés résztvevői
A Rate Software Licence Kft. részéről: 
Uszta Karolina, Gazsi Bianka, Lublóváry Bence, Borbély Tamás, Szombati Tamás, Sáfrány Kristóf
Az ügyfél részéről:
Kardos Ildikó, Juhász Norbert
Bevezetés
Az egész cégcsoport szervezeti struktúrájának feltérképezésével kezdenénk, szeretnénk egy alapos és részletes szervezési tervezetet készíteni, amely tartalmazza a közös modulokat és elemeket. Célunk az, hogy előállítsunk egy alapvető tervet, amely felvázolja a projekt főbb vonalait. Ez segíteni fog abban, hogy azonnal azonosítsuk a nyitott kérdéseket, és több időt szánjunk azok megoldására. Ezzel a módszerrel a fejlesztés gyorsabb lehet, mivel csökkenthetjük a tervezési köröket és gyorsabban haladhatunk a megvalósítással.
Szervezeti struktúra
Külső alrendszerek: 
pl. banki információk, napi és Havi folyószámla kivonatok, Raiffeisen Elektra banki terminál adatok, szerver adatok
Raiffeisen minden cégnél az alap, de vannak cégek, ahol van más bank is. 
pl. Lisicza (borászat) MBH (később kapcsoljuk a rendszerhez), Zálog és mindenhol  a POS terminál OTP-s, de a fő bank itt is Raiffeisen.
Integrált rendszer a cégcsoport elnevezése, az egyes cégek elnevezése az alrendszerek: ékszer, zálog, Valuta. Ezeken belül lesznek megvalósított modulok: pénztár, zálog, beosztástervező, controlling főmodul (a controlling minden alrendszer része lesz..)
Önálló cégekről van szó, semmi adatot nem szabad összemosni, sem controlling rendszert. Külön minden cégre!
Vegyünk egy példát Ildikó szerint: 
Exclusive Best change: van egy controlling modul, van egy valuta modul, a valuta modul alatt lennének a pénzváltási tevékenység és az értéktár tevékenységének a dolgai, itt is bejön egy bank modul, de az egy elég bonyolult dolog, pl beszállításos számlák miatt. Lenne egy Controlling modul, amiben mindenféle háttér benne lenne, mivel regionálisan sokfele vannak, mindenhol vannak területi vezetők önálló kis gazdálkodással, saját pénztárral, saját ember állománnyal, humán dolgokat is ide lehetne beletenni. Központban minden lecsapódik, az összes szállítói számla, azok kiegyenlítése, költségkimutatások stb. 
Összemosni semmiképp nem lehet, mivel nincsen önállóan egy Controlling: a Valutának is egy controlling, az Ékszernek is egy controlling, stb. Lehet hogy vannak ugyanolyan  megvalósítású funkciók de pl.  a Valutához tartozó Controlling csak a Valutához tartozó adatokkal dolgozzon. Mindenki csak a sajátjához tartozó adatokat lássa, vegyítés semmiféleképpen nem jöhet szóba!
A Vezetői modult is ennek függvényében át kellene gondolni, átalakítani!
Könyvelés felé külső rendszer kapcsolódás: 
Minden egyes alrendszer önállóan kapcsolódik a könyveléséhez, ez ugyan azt a könyvelői kapcsolatot jelenti, van egy könyvelő iroda, ahol van 4 könyvelő, 1 hölgy csak a Valutával foglalkozik, 1 hölgy csak az Ékszert könyveli stb. és van egy főkönyvelő, aki mindenbe bele kell hogy lásson. Egymás munkájára rálátnak, ismerik.
Könyvelői szoftvert használnak aminek a neve: Kulcs-Soft.
(Somos Andi főkönyvelővel fogunk erről beszélni majd!)
Bankok felé kapcsolódási pont, minden cég önállóan kapcsolódik.
Elektra felületet használják nem a webes felületet: kolléga letölti a banki kivonatokat, ezt egy bizonyos nevű fájlba letölti, elküldi és a könyvelő program egy az egyben beolvassa a kivonatot, nincs kézi könyvelés. Adriana csomagot vették meg, remekül működik.
A POS terminál megvalósítása egy közös funkció,mindegyik cégnél lehet bankkártyával fizetni, mindegyik OTP-s.
Utólagos elszámolás van mindegyik cégben, OTP küldi minden hónapban a tételeket, a könyvelés beolvassa azt is a könyvelő programjába, havonta egyszer küld egy jutalék számlát amit elutalnak.
Valuta cég szervezeti felépítése
Itt 180 ember dolgozik, 62 db valutapénztár van szerte az országban, többnyire az ország délkeleti részén. Összesen 8 területet/régiót különböztetnek meg, mindnek van egy úgynevezett regionális központja: Pécs, Kaposvár, Szekszárd, Szeged, Kecskemét, Békéscsaba, Debrecen, Nyíregyháza. Ezekben a városokban működik egy-egy értéktár. Minden értéktár mellett X számú valuta pénztár működik, valahol 9 valahol csak 6. Minden régiónak van területi vezetője, az ő felelőssége a valutaváltáshoz szükséges személyi és tárgyi feltételeket biztosítani. Az értéktáros dolga a pénzellátás szervezése, ő hoz ki a bankból pénzt, viszi be a pénzt, ő figyeli a készleteket a valutás programban, hogy melyik pénzváltóban hogy fogy az euró, hogy fogy a dollár, kell-e valamilyen címlet. A Raiffeisen bank ügynökeként dolgoznak. Van az értékszállító küldönc aki hozza és viszi a pénzt.
Egyéb tevékenységek a valutás cégben: ??? kifizetés, áfa kifizetés, MoneyGram tevékenység, e kereskedelem(Autópálya matrica, telefonfeltöltés stb) stb … ezek kisebb volumenűek. Ezek alkotják gyakorlatilag a külön modulokat a Valuta alatt. (itt már meglévő rendszert használnak, hozzáférést biztosítanak nekünk)
Valutás programban mindenkinek külön kódja van. Mint dolgozó, ha a céghez érkezik ugyanaz a munkaügyis viszi fel, a munkaszerződést is ő készíti, de magát a jogosultságot a rendszerhez az ottani területi vezetője fogja kontrollálni.
Az ékszerház és a zálogos cég is foglalkozik egyébként valutaváltással is, tehát itt is szükséges a valutaváltás mint modul, bár nem abban a felépítésben, mint a Valutásban, akik csak azzal foglalkoznak. Mindegy hogy a Best Change-hez vagy az Ékszerházhoz tartozik, a modulnak teljesen ugyanolyannak kell lennie.
A pénzváltási tevékenység a jelenleg törvényes hatályok alapján egy bank ügynökeként végezhető, náluk ez a Raiffeisen bank. Napi elszámolási kötelezettségük van a bank felé. A valutás programban keletkezett minden egyes tranzakciót valami módon begyűjtik és azt a banknak le kell küldeni, erre van egy kolléga aki ezt csinálja. Minden nap megcsinálja az előző napi küldést. A beküldés a Darius felületén történik. Erre is van kolléga, aki ezt el tudja mondani. 
Havonta 1x számolnak el a bank felé, az egész havi adatforgalmat, összes pénzváltási tranzakciót, összes átadás, pénztár, értéktár stb adata be van olvasva , elküldik a banknak, 
ezt ellenőrzik, ezután kiszámolnak egy jutalékot, ezt nekik ki kell számlázni a bank felé.(ők számolják ki de a bank ellenőrzi)
Pénzváltási tevékenység során ügyfél odamegy az ablakhoz kér pl. 500 eurót: készül egy bizonylat magáról a valutaváltásról, amin rajta van az árfolyam, de lehet egyedi árfolyamos is.  Történik egy tranzakció és ezzel párhuzamosan kezelési költséget is fizet az ügyfél, ez 
egy másik tranzakció, a pénzt elkülönítve kell tárolni, külön kezelendő, külön elszámolandó a bank felé, ez egy másik bizonylat. A helyszínen 2 pénztárt kezel. Semmiképp nem lehet összemosni a két összeget.
Kérdések
Üzemeltetési szempontból számíthat: maga az adatbázisok, lehet egy fizikai szerveren / egy központi szerveren?
Nem kell, hogy legyen külön. 1 fizikai szerveren futó, logikailag elkülönített. A biztonság miatt külön szednék, mert ugye egyébként is külön cég.
Árfolyam kijelző: 
Ők kezelik, főértéktáros munkakörben dolgozó ember, az felelőssége és hatásköre az árfolyamokat megadni, a szerverről küldi ki. 62 valutapénztár, más árfolyamon dolgozik egy azonos városon belül 2 váltó, nem azonosak az árfolyamok. Az  árfolyam kijelző egy egyszerű monitor, ami össze van kötve a számítógéppel, a kolléganő pedig a főértéktárból egy gombnyomással az adott fiók számítógépére küldi az adatot.
Jelenleg 10 percenként frissül az árfolyam, mert egy nap többször is változhat. Ahol erős a konkurencia ott 5-10 perc, ahol kevésbé ott 15-20 perc. 
A hölgy egy szervert lát, ami közvetíti az adatot x időközönként frissül, mind a 62 végpontra rálát.  Ez 1 db valakitől megrendelt 1 db központi vezérlés: Fabulya Zsuzsa fogja ezeket elmondani nekünk, Ugyanazt a programot használják mindenhol.
Összeghatártól függően pénzmosási törvény: bizonyos összeg felett személyi, lakcímkártya, forrásigazolás honnan van ennyi pénze stb. 
Az ő rendszerük nem alkalmas most arra, hogy kiszűrje, hogy hamis-e vagy sem a személyi, de van amihez be kell szkennelni és tárolni a személyit. 
A szűrőfeltételek felépítésére van lehetőség (még nem kötelező nekik ez a szűrés/ellenőrzés) de felírhatjuk, hogy ezt is tudja a rendszer, de csak egy későbbi fázisban.) 
Nyilván nem szeretnének elesni emiatt egy üzlettől, csak azokat a tranzakciókat tagadják meg amit meg kell.
A Raiffeisennek nagyon jó szűrőrendszere van. Hagyjuk rájuk a szűrést amíg kötelezővé nem teszik.
A Bankok az MNB felügyelete alá tartoznak, ő a végpont.
Kell-e és szükséges hogy egy szkenner be tudja olvasni és az adott tranzakcióhoz és hozzá rendelje a fotót? Igen ez jelenleg is így van.
Ez egy állítható paraméter jegyzékben egy választható opció, de be kell olvassa a személyit a lakcímkártyát. Mert ezt adjuk le a Raiffeisennek a nap végén.
Közös funkcionalitás: Munkaszervezés/beosztáskezelés modul a többi cégnél is elvárás?
Igen.  Munkaórákban tudnak különbséget tenni.
Minden alrendszer önállóan fut, egy önálló szerveren önálló adatbázissal.
Az ékszer zálog ugyanaz, a valutás 8 értéktár (ott sokan dolgoznak), ott csak a saját alárendelt dolgozóikat látja az adott területi vezető. Hónap végén egyeztetik a jelenléti íveket, nem nekik kell kiszedni minden egyes területet, ez lekérhető a szerverről. 
Az automatizálás egyik legfontosabb funkciója, hogy a manuális feldolgozás redukáljuk.
Infrastruktúra: Internet? Mi a minimális sávszélesség?
Új kártyák, Vodafone-os adatkártya 30 gigás internet. Marcaliban van talán probléma, a többi helyen kiválóan működik. Ha megáll a Vodafone akkor a munka is megáll náluk. 
Offline esetén mi történik?
Migráció: Zálog/Valuta/Ékszernek, akiktől az adatokat el kell kérjük (fejlesztői adatok) ugyanaz a cég vagy más fejlesztette?
Az összes forráskódot szívesen odaadják, a programozó segít is nekünk. Fabulya Zsuzsa a kontakt. 
Egyéb
Látnunk kellene a Valuta működését, Zsuzsát kell keresnünk. Kecskeméten lehetne vele találkozni, hogy megmutasson nekünk mindent ami szükséges lehet a munkánkhoz.
Csütörtökön (február 15) 13 órakor folytatjuk, a további időpontokkal kapcsolatban keressük majd őket.
