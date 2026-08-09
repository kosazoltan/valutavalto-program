---
title: RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx
type: long-term-legacy
source: felmeres-knowledge-base (recovered from git history)
category: altalanos
original_path: Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx
doc_type: word
---

# RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx

**Kategoria:** altalanos  |  **Tipus:** word  |  **Meret:** 295.0 KB
**Eredeti utvonal:** `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/RSL – EXZ + EXV üzemeltetési megbeszélés 2024. 03. 22_.docx`

## Tartalom

RSL – EXZ + EXV üzemeltetési megbeszélés
2024. 03. 22. 13 óra
Résztvevők:
RSL: B. Tamás, Sz. Tamás, Gábor, Bianka
EXZ+EXV: Póka János
2 téma: képbe kerülés, illetve a valuta és az értéktár környezet kialakítással kapcsolatos segítség
Külső merevlemezen kaptunk forrásokat, nincs benne leírás sajnos. Siófoki valutaváltóból megkaptuk a C meghajtóról a valuta könyvtárat. Firebird adott verzióját feltelepitette Tamás.
Mit kell adatbázishoz beállítani? Mit kell elindítani?
Nincsen leírásuk, csak annyi van leírva nekik, hogy a valuta.exe-t kell elindítani, parancsikonnak ki van téve nekik az asztalra.
Az adatbázisban csak akkor kell állítani, ha új pénztár nyílik. Akkor egy üres adatbázist szoktak csinálni az Anti bácsiék egy régiből. Minden a valuta könyvtárban van, minden onnan fut, mindent ott kezel.
A meglévő valutaváltóknál a környezettel kapcsolatban: jelenleg felállás, milyen környezet, milyen folyamat van? Ki mikor kezdeményezi a kommunikációt? A folyamatról lenne szükségünk pár szóban.
Jelenleg a valutaváltó központi szervere az árfolyamokat és a napi adatbázis mentéseket fogadja be, ezt a szoftvert is Anti bácsi írta meg. Minden kliensen 5 percenként indul egy kérés a szerver felé, lekérdezi az árfolyamokat. A tiltott ügyfelek nevű adatbázist is ugyanígy központilag vezérlik. A pénztában felvillan a pénztárosnak, ha olyan ügyfél áll ott, akit nem szabad kiszolgálni mert pl. a terrorista listán szerepel.
Fent a szerveren minden egyes pénztárnak saját egyedi árfolyamot tudnak leküldeni, amivel az a pénztár dolgozik. Ez a konkurenciák miatt érdekes téma, mert ahol a közelben van bármilyen más váltó, ott valamivel alacsonyabb árfolyamot szoktak használni, mint olyan helyen, ahol nincs a közelben konkurens valutaváltó.
A szerver helyileg hol van?
Jelenleg a RackForest-nél van. A szerver távoli asztali kapcsolattal csatlakozik, valószínűleg Delphiben megírt alkalmazás, saját adatbázis lokálisan. Jellemzően 1 ember állítja az összes árfolyamot, de valamikor a területi vezetők is beleszólnak. Van olyan pénztár, ahol 2 gép is van. Mindegyik gép egy önálló kasszagép. Központi szerveren beállításra kerül, valutaváltó helyenként a 2 önálló gép önállóan kezdeményezi a kapcsolatot. Gépenként van egy lokális adatbázis, amibe ezt letölti és amiben ez dolgozik.  A Raiffeisen felé kell változásokat jelenteni. Kliens gép megkérdezi önállóan az árfolyamot, ha nem sikerül akkor megjelenik, hogy nem sikerült és használja a jelenlegit. Folyamatosan újra próbálkozik (5 percenként). A központban van külön felület a rendszeren a tiltott listára.
Felfelé irányuló kommunikáció: nap zárás és nyitás megy felfele és a kassza állapotok. Van címletező a kliens gépeken, ezeknek a nyitás-zárását is felküldik, hogy lássák a területi vezetők és a belső ellenőrök, hogy egy-egy pénztárban mennyi pénz van a kasszában címletre rendezve. Pénz szállításkor és felfelé irányuló kommunikáció, vagy pénzt küldenek be a területi vezetőnek vagy a területi vezető küld nekik pénzt, amikor pénzt vételeznek ki és be akkor történik a kliensről a szerver irányába kommunikáció. Záráskor forgalmi adatot és adatbázis mentést is felküld. Gépenként/kliensenként történik egymástól függetlenül.
Mi van akkor, ha egy géppel gond van?
Van kézi bizonylat a pénztárakban az ilyen esetekre és van kinyomtatott árfolyamlista, azzal dolgoznak és ha rendbe jön a gép utólagosan fel rögzítik. Ha egy napon belül nem tud megtörténni olyan nincs, mert minden kliens küldi a NAV-nak az adatokat. A kinyomtatott árfolyam listát vagy egy pénzszállító viszi nyomtatottan, vagy a blokknyomtatóval kinyomtatják maguknak az árfolyamot. Belső szabályzat, hogy bizonyos időközönként árfolyam bizonylatot kell kinyomtatni és abból dolgoznak ilyen esetekben.
Adatbázis:
Most van egy Firebird adatbázis. Ez stabil a tapasztalataik alapján, hibajelenségekkel pl. hogy nem működik egy gép nem nagyon találkoztak (max Anti bácsinak lehet jelezték). Annyi, hogy nehéz a nyomtató interface-eket kezelni, mert nehéz párhuzamos portos kivezetésű PCEA kártyát beszerezni. Ha a géppel van a gond és újra kell rakni, akkor az előző napi mentést állítják helyre. C mappát rámásolják és működik tovább.
Ha záráskor nem sikerül kommunikálni: van egy időablak a pénztárzárás utáni 30 percig, utána csak területi vezető jóváhagyásával tudnak beküldeni zárást. 
A kliensnek kötelező kommunikálnia a NAV-val, ezt maga a delphis program végzi. A váltósoknak csak 2 programot szabad használni: a valutaváltásra a valutaváltó programot, ahol meg van pénzküldő MoneyGram vagy Western Union ott webes felületet használnak.
Van blokknyomtató mindegyik számítógéphez, minden tranzakcióról blokkot nyomtatnak amit megkap az ügyfél és maguknak lefűzik a valutaváltóban és lejelentik a NAV-nak a tranzakciót. Azonnal történik a lejelentése a bizonylatnak. Ha kézzel dolgoznak, 24 óra áll rendelkezésre, hogy az ÁNYK-n lejelentésre kerüljön. Ha ez nem sikerül akkor a területi vezető jelenti le az ÁNYK-nál.
Napközben is van kommunikációs igény: NAV felé, mivel azonnal le kell jelenteni → internetkapcsolat fontos.
Ha éppen akkor nincs net, de a gép működik: akkor gyűjti és ha újra lesz kapcsolat feltölti. Itt is a 24 órás határidő van érvényben, mert ha ez nem teljesül bírságot kapnak.
Jelenleg feltöltőkártyás internetet használnak, nagyon gyenge internet kapcsolattal.
Lejelentik: Dátumokat, összegeket, tétel(ek) megnevezése, vevő adatai névre szóló ÁFA-s számla esetén, időbélyeg stb  (XML kommunikáció) 
Tiltólista változást kapják csak meg. Honnan tudjuk mi változott? 
Globális információ, minden pénzváltónál ugyanolyannak kell lennie, bekerült egy név vagy kikerült egy név. Ez nem olyan mint, az árfolyam hogy kassza gépenként eltérő.
Bank felé változás jelentési kötelezettség?
Napzárás:
Kliensek tárolnak visszamenőleg a telepítéstől kezdve mindent. Pénztárhiány vagy hatósági megkeresés miatt kellenek ezek visszakereshetőek legyenek.
Webes megoldáson gondolkodtunk, böngészőben futó, központi szerverrel kommunikál. Zálog fiókoknál ez nem jelent problémát mert erősebb az internetkapcsolat. Hasonló megoldás, mint most, csak nem Delphiben megirt.
NAV API-ja milyen kommunikációs protokollt használ??
Erről van egy dokumentáció.
Nyomtatás minden pénztárban egyforma. Árfolyam kijelző monitor ugyanazon a gépen.
Párhuzamos port probléma a nyomtató típusa miatt van? Régi dolog, ezek a nyomtatók vannak ezt kell használni. 

Kamerás program kapcsolódik a valuta váltós szoftverhez. JAVA-ban van megírva, ugyanaz a probléma a valutás rendszerrel is mint a kamerás programmal (JAVA-ban megvan írva, fel vannak telepítve és gyakorlatilag senki nem tud beleszólni ha abban bármilyen működési zavar keletkezik). A Kamerás program technológiai továbbvitele szóba kerülhet.
Idei évben megkapják a NIS2 rendeletet: a zálog és a valuta is kötelező jelleggel érintett ebben. Auditálás, penetrációs tesztek, ips modulos tűzfalaknak kell lennie, Logelemzéseket kell végrehajtani stb.
VPN 2 faktoros. 
A kliensek kommunikálnak közvetlenül a NAV-val (igy kötelező). A szerver is kommunikálhatna a NAV-val de ez csak akkor állná meg a helyét, ha olyan számlázó programot használnának, hogy az egész adatbázis fent van egy központi szerveren akkor onnan kell mennie a jelentésnek, mindig onnan kell mennie az XML-nek ahol a számla kiállítódik* és tárolódik (*ahol az adatbázis tárolódik ott jön létre a számla).
Járható út lenne, hogy mindent a központi szerveren tárolunk, még beszélünk róla.
Következő megbeszélés:
04.03 szerda 14 óra, környezeti téma halasztva erre a napra. 
Architekturális felépítésről rajz készítése leírással Valuta Zálog egyebek.
