---
type: legal-baseline
scope: repo-wide
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Hungarian legal baseline for money exchange, AML, sanctions, rounding and conversion"
load: on-demand
---

# Hungarian Money Exchange Legal Baseline

> Cel: a magyarorszagi valutavaltasi tevekenyseghez kapcsolodo kotelezo jogi baseline, AML/szankcios kovetelmenyek, kerekitesi szabalyok es arfolyam/konverzios kovetelmenyek egy helyen, agent-kompatibilis formaban.
> Modszertan: hivatalos vagy felugyeleti forrasokra tamaszkodo osszefoglalo, nem minosul jogi tanacsadasnak.
> Datum: 2026-04-09

---

## S1 FORRASKOR

### Elsodleges jogforrasok

1. `2013. evi CCXXXVII. torveny (Hpt.)`
   - NJT: `https://njt.hu/jogszabaly/2013-237-00-00.85`
   - Kulcspont: a penzvaltasi tevekenyseg fogalma, a penzvaltas kozvetitesenek keretei

2. `297/2001. (XII. 27.) Korm. rendelet a penzvaltasi tevekenysegrol`
   - NJT: `https://njt.hu/jogszabaly/2001-297-20-22`
   - Kulcspont: arfolyamjegyzek, bizonylatok, nyilvantartas, konverzios bizonylat, uzletszabalyzat

3. `2017. evi LIII. torveny (Pmt.)`
   - NJT: `https://njt.hu/jogszabaly/2017-53-00-00.3`
   - Kulcspont: ugyfel-atvilagitas, 300 000 Ft-os penzvaltasi kuszob, 8 eves megorzes, FIU-bejelentes

4. `2017. evi LII. torveny (Kit.)`
   - NJT: `https://njt.hu/jogszabaly/2017-52-00-00`
   - Kulcspont: penzugyi es vagyoni korlatozo intezkedesek, szankcios szures, bejelentes, felfuggesztes

5. `21/2017. (VIII. 3.) NGM rendelet`
   - NJT: `https://njt.hu/jogszabaly/2017-21-20-2X`
   - Kulcspont: a Pmt./Kit. szerinti belso szabalyzat kotelezo tartalmi elemei

6. `14/2025. (VI. 16.) MNB rendelet`
   - NJT: `https://njt.hu/jogszabaly/2025-14-20-2C`
   - Kulcspont: jelenlegi MNB-felugyelt szolgaltatok AML/szankcios reszletszabalyai, monitoring, szuro-, kepzesi es kontrollminimumok

7. `2008. evi III. torveny`
   - NJT: `https://njt.hu/jogszabaly/2008-3-00-00`
   - Kulcspont: 5 Ft-os keszpenzes kerekitesi szabaly

8. `10/2007. (X. 1.) MNB rendelet`
   - NJT: `https://njt.hu/jogszabaly/2007-10-20-2C`
   - Kulcspont: az 1 es 2 forintos ermek bevonasa

### Felugyeleti/operativ forrasok

9. `MNB - Mire figyeljunk penzvaltasnal?`
   - `https://www.mnb.hu/fogyasztovedelem/gondos-tervezes-gondtalan-nyaralas/mire-figyeljunk-penzvaltasnal`
   - Kulcspont: fogyasztovedelemi kozzeteteli es gyakorlati penzvaltasi elvarasok

10. `MNB - A hivatalos devizaarfolyamok megallapitasa es publikalsa`
    - `https://mnb.hu/statisztika/statisztikai-adatok-informaciok/adatok-idosorok/arfolyamok-lekerdezese/a-hivatalos-devizaarfolyamok-megallapitasa-es-publikalasa`
    - Kulcspont: hivatalos MNB-arfolyam kepzes modja

11. `MNB - Hazai jogszabalyok AML oldalon`
    - `https://www.mnb.hu/felugyelet/szabalyozas/penzmosas-ellen/kotelezo-es-iranyado-szabalyok/hazai-jogszabalyok`
    - Kulcspont: aktualis AML/szankcios jogforraslista, jelenlegi MNB rendeleti referencia

---

## S2 PENZVALTASI TEVEKENYSEG JOGI KERETE

### 1. Mi minosul penzvaltasnak?

A `Hpt.` szerint a penzvaltasi tevekenyseg:

- kulfoldi fizetoeszkoz adasvetele torvenyes fizetoeszkoz elleneben, valamint
- kulfoldi fizetesi eszkoz adasvetele kulfoldi fizetesi eszkoz elleneben.

Ez a definicio kiterjed:

- `HUF <-> valuta` ugyletre, valamint
- `valuta <-> masik valuta` konverziora is.

### 2. Ki vegezheti?

A repo-ban tarolt hivatalos es felugyeleti forrasok alapjan Magyarorszagon penzvaltast:

- hitelintezet vegezhet, illetve
- a hitelintezettel kotott megbizasi szerzodes alapjan mukodo, erre jogosult `kiemelt kozvetito` vegzi mint `penzvalto iroda`.

Ez gyakorlati rendszerkovetelmenyben azt jelenti, hogy:

1. a szereplok kozott kulon kell kezelni a `megbizo hitelintezetet` es a `penzvalto irodai telephelyt`,
2. a rendszernek tudnia kell, melyik szervezet neveben tortenik az ugylet,
3. a felhasznalo, telephely es szerzodeses statusz nem lehet szabad szoveges adat.

### 3. Milyen alapszabalyokat kell mukodes kozben teljesiteni?

A `297/2001. Korm. rendelet` alapjan a penzvalto:

- hitelintezettel kotott megbizasi szerzodes alapjan mukodik,
- uzletszabalyzattal rendelkezik,
- arfolyamjegyzeket vezet es 5 evig megorzi,
- az arfolyamjegyzeket jol lathato helyen kifuggeszti,
- penztarankenti nyilvantartast vezet,
- minden ugyletrol megfelelo bizonylatot allit ki.

---

## S3 ARFOLYAM, KONVERZIO, BIZONYLAT

### 1. Penzvaltoi arfolyamok

Az MNB fogyasztovedelmi forrasa szerint:

- a penzvaltok altal alkalmazott valutaarfolyamokra `nincs altalanos jogszabalyi tarifaszabaly`,
- az arfolyamot a piaci verseny, a helyszin es a szolgaltato sajat uzleti politikaja alakitja,
- kezelesi koltseg kulon is felszamithato.

Kovetkezmeny:

- a rendszernek nem szabad azt felteteleznie, hogy van egyetlen kotelezo `jogi` buy/sell rate,
- ugyanakkor a kozzeteteli, bizonylatolasi es parameterkezelesi szabalyok kotelezoek.

### 2. Arfolyamjegyzek kotelezo tartalma

A `297/2001. Korm. rendelet` alapjan az arfolyamjegyzeken fel kell tuntetni legalabb:

- a penznemet,
- a jegyzes egyseget,
- az elso oszlopban a valuta veteli arfolyamot,
- a masodik oszlopban a valuta eladasi arfolyamot,
- ha van kulon csekkafolyam, annak kulon oszlopait,
- az esetleges osszeghatart es az ettol eltero kedvezobb/elteto arfolyam logikajat.

Az arfolyamjegyzeket:

- attekinthetoen kell elkesziteni,
- jol lathato helyen kell kifuggeszteni,
- 5 evig meg kell orizni.

### 3. Kezelesi koltseg

Az MNB fogyasztovedelmi oldal szerint a kezelesi koltseg:

- jellemzoen a megvasarolt valuta forintban kifejezett ertekenek szazalekos/ezrelekes aranyahoz kotott,
- penzvaltonkent elterhet,
- kedvezmenyes savok es 0 koltseges konstrukciok is lehetnek.

Rendszerkovetelmeny:

- a fee nem lehet hardcoded,
- savos es penznem- vagy ugylet-tipus-fuggo fee-modell kell,
- a bizonylatban es riportban el kell kulonulnie a fo valtasitol.

### 4. Konverzio

A `297/2001. Korm. rendelet` kulon nevesiti a `konverzios bizonylatot` a kulfoldi fizetoeszkoz masik kulfoldi fizetoeszkozre torteno atvaltasakor.

Eloirasok:

- `valuta -> valuta` ugyletrol kulon `konverzios bizonylat` allithato ki,
- vagy egyuttesen alkalmazhato veteli + eladasi bizonylat, ha rajta van a `konverzio` megjegyzes,
- a ket bizonylat adattartalmanak meg kell egyeznie a konverzios bizonylat tartalmaval.

Ez a modern rendszerben azt jelenti, hogy:

1. a konverzio nem csak technikailag ket labu tranzakcio,
2. hanem kulon bizonyitasi tipussal rendelkezo ugylet,
3. es kulon receipt-template-re is szukseg lehet.

### 5. Hivatalos MNB arfolyam

Az MNB hivatalos devizaarfolyamai:

- munkanapokon 11:00-kor kerulnek megallapitasra,
- az EUR/HUF arfolyam 8 aktiv hazai bank jegyzeseibol, a legalacsonyabb es legmagasabb elhagyasaval kepzett sulyozatlan atlag,
- az USD/HUF es a tovabbi devizak keresztarfolyamos modszertan szerint kepzodnek.

Fontos kulonbseg:

- az `MNB hivatalos devizaarfolyam` nem azonos a `penzvalto sajat veteli/eladasi arfolyamaval`,
- a ketto kulon forras, kulon celra es kulon adattipuskent kezelendo.

---

## S4 AML, KYC, SZANKCIOS KOVETELMENYEK

### 1. Penzvalto AML statusza

A `Pmt.` kifejezetten nevesiti:

- a `penzugyi szolgaltatot`, valamint
- a `penzvalto irodat`

mint relevans AML-alanyokat.

Ez nem opcionis megfelelesi terulet, hanem core domain.

### 2. Kotelezo ugyfel-atvilagitas penzvaltasonal

A `Pmt. 21. §` alapjan:

- `300 000 Ft`-ot elero vagy azt meghalado osszegu penzvaltasnal
- a hitelintezet es a penzvalto iroda koteles az ugyfelet teljes koruen azonositani,
- a szemelyazonossag igazolo ellenorzeset elvegezni,
- valamint a 8-10. § szerinti tovabbi ugyfel-atvilagitasi intezkedeseket teljesiteni.

Kulcsszabaly:

- az egymassal tenylegesen osszefuggo tobb ugyletet ossze kell szamolni,
- ha az egyuttes ertek eleri a `300 000 Ft`-ot, az atvilagitast annal az ugyletnel kell vegrehajtani, amellyel a kuszob teljesul.

Ez kozvetlenul tamasztja ala a repo AML-domainjenek tranzakcio-osszekapcsolasi igenyet.

### 3. Ha az ugyfel-atvilagitas nem hajthato vegre

A `Pmt.` alapjan, ha a szolgaltato nem tudja elvegezni a kotelezo ugyfel-atvilagitast, akkor:

- meg kell tagadnia az ugyleti megbizas teljesiteset,
- vagy meg kell szuntetnie az uzleti kapcsolatot.

Modern kovetelmeny:

- az UI-ban es a backend orchestrationben is kell `cannot-complete-cdd -> refuse transaction` allapot.

### 4. Megorzes

A `Pmt.` alapjan:

- a szemelyes adatokat,
- a nem szemelyes, de az ugyleti kapcsolathoz tartozo adatokat,
- az okiratokat es masolataikat,
- a bejelentesi/felfuggesztesi iratokat

az uzleti kapcsolat megszunesetol vagy az ugyleti megbizas teljesitesetol szamitott `8 evig` meg kell orizni.

Kulonszabaly:

- a `3 600 000 Ft` erteket elero vagy meghalado keszpenzes ugyleti megbizasokat kulon is rogziteni kell,
- azokat is `8 evig` meg kell orizni.

### 5. Belső szabalyzat

A `Pmt. 65. §` alapjan minden szolgaltato koteles belso szabalyzatot kesziteni.

A `21/2017. NGM rendelet` szerint ennek kotelezo tartalma tobbek kozott:

- ugyfel-azonositas es kockazati besorolas rendje,
- folyamatos monitoring,
- egyszerusitett es fokozott atvilagitas esetei,
- mas szolgaltato altal vegzett atvilagitas elfogadasanak rendje,
- bejelentesi eljarasrend,
- adatkezeles, megorzes, vedelmi es munkatarsi vedelmi szabalyok,
- belso ellenorzo es informacios rendszer,
- speciális ugyfel-atvilagitas esetei,
- vagyon/penzeszkoz forrasara vonatkozo nyilatkozati rend.

### 6. Kijelolt szemely, FIU-bejelentes, titoktartas

A `Pmt.` alapjan:

- a szolgaltato kijelolt szemelyt jelol ki,
- a kijelolt szemely haladektalanul tovabbitja a bejelentest a penzugyi informacios egysegnek,
- a kijelolt szemely adatait 5 munkanapon belul be kell jelenteni,
- a bejelentes megtortente, tartalma es a bejelento szemelye titokban tartando.

### 7. Felfuggesztes

A `Pmt.` es a `Kit.` egyarant ismer felfuggesztesi logikat:

- AML-gyanu eseten a szolgaltato bizonyos ugyletet nem teljesit,
- a FIU/hatosag vizsgalati ablaka jellemzoen `4 munkanap`,
- ha nincs tovabbi hatosagi akadal yertesites, az ugylet a szabaly szerinti hatarido utan tovabblephet.

### 8. Szankcios/KIT kovetelmenyek

A `Kit.` szerint a szolgaltatonak:

- megfelelo szurorendszerrel kell rendelkeznie,
- a vagyoni es penzugyi korlatozo intezkedeseket haladektalanul es teljes koruen kell vegrehajtania,
- a talalatot, illetve a vagyon jelenletet haladektalanul jelentenie kell,
- meghatarozott esetekben az ugyletet nem teljesitheti a vizsgalati ido alatt.

### 9. Jelenlegi MNB-reszletszabalyok

Az MNB `hazai jogszabalyok` oldala szerint 2026-ban a relevans aktualis reszletszabaly a `14/2025. (VI. 16.) MNB rendelet`.

E rendelet alapjan kiemelt kovetelmenyek:

- folyamatos monitoring,
- belso kockazatertekeleshez kotott szuresi intenzitas,
- szokatlan ugyletre figyelmezteto jelzesek,
- automatikus vagy manualis AML-szures,
- szankcios szurorendszer,
- magas ugyfelszam folott kotelezo automatikus szankcios szures,
- belso eljarasrend a talalatok elemzesere es dokumentalasara,
- kepzes es vizsga uj es mar bent levo munkatarsaknak,
- egyes szurorendszer-leallasi esemenyek MNB-fele, ERA-n keresztuli haladektalan jelentese,
- vagyonforras-nyilatkozat kotelezo tartalmi elemei meghatarozott magas kockazatu esetekben.

---

## S5 KEREKITESI SZABALYOK

### 1. Mikor kell alkalmazni?

A `2008. evi III. torveny` szerint a szabaly:

- `forintban`,
- `keszpenzzel`,
- a `fizetendo vegosszegre`

alkalmazando, ha az nem `5 forintra` vagy annak egesz szamu tobbszorosere vegzodik.

Ez kifejezetten a `keszpenzben fizetendo vegosszegre` vonatkozik, nem az egyes tetelekre.

### 2. Pontos kerekitesi szabaly

- `0,01 - 2,49` -> lefele a legkozelebbi `0`
- `2,50 - 4,99` -> felfele a legkozelebbi `5`
- `5,01 - 7,49` -> lefele a legkozelebbi `5`
- `7,50 - 9,99` -> felfele a legkozelebbi `0`

### 3. Mit jelent ez rendszeroldalon?

1. A kerekites csak a `keszpenzes vegosszeg` fazisaban alkalmazando.
2. A tranzakcio belso szamitasait nem szabad tul koran 5 Ft-ra vagni.
3. A kerekitesi kulonbozet nem minosul vagyoni elonynek vagy hatranynak.
4. A torveny szerint a kulonbozet kulon bizonylatozasa nem kotelezo.

### 4. Kartya es nem keszpenzes fizetes

A `2008. evi III. torveny` szerint bankkartyas fizetesnel a szolgaltato csak akkor alkalmazhatja a kerekitesi szabalyokat, ha erre a fizeto szemely figyelmet kifejezetten felhivja.

Modern kovetelmeny:

- a rendszerben a `payment_method` befolyasolja, hogy kotelezo-e a kerekites,
- alapesetben a repo-ban hasznalt `roundHuf` logikat `cash-final-amount` kontextusban kell tekinteni kotelezonek.

---

## S6 MODERN RENDSZERKOVETKEZMENYEK

### 1. Domain szetvalasztas

A rendszerben kulon kell kezelni:

- `money exchange authorization context`
- `cashier transaction context`
- `rates context`
- `AML/KYC context`
- `sanctions screening context`
- `receipt and audit context`
- `cash rounding context`

### 2. Kotelezo adattagok / flag-ek

Legalabb az alabbiaknak modellben kell megjelenniuk:

- megbizo hitelintezet / penzvalto iroda kapcsolat
- arfolyamjegyzek verzio es ervenyessege
- buy / sell / conversion ugylet-tipus
- fee / handling cost kulon adatkent
- AML atvilagitasi statusz
- linked transaction / structuring logika
- kijelolt szemely / escalation path
- szankcios szures eredmeny
- payment method
- pre-round total / rounded cash total

### 3. Receipt parity

A `297/2001. Korm. rendelet` miatt a receipt-engine-nek tudnia kell:

- veteli bizonylatot,
- eladasi bizonylatot,
- konverzios bizonylatot,
- valamint olyan ket-labu receipt outputot, amelyen a `konverzio` megjegyzes szerepel.

### 4. AML enforcement parity

A `Pmt.` alapjan minimum enforce-olando:

1. `>= 300 000 Ft` penzvaltas -> teljes azonositasi flow
2. tenylegesen osszefuggo ugyletek aggregalasa
3. CDD hianyaban tranzakcio elutasitasa
4. 8 eves adat- es okiratmegtartas
5. 3.6M+ keszpenzes ugyletek kulon rogzites
6. FIU-bejelentesi es felfuggesztesi workflow

### 5. Sanctions parity

A `Kit.` es az aktualis MNB rendeleti reszletszabalyok alapjan:

- folyamatos szankcios szures kell,
- nagy ugyfelszamnal automatikus szures kell,
- a talalatkezelesnek dokumentaltnak kell lennie,
- a szuresi logikat, tesztelest es felelossegi koroket belso eljarasrendben kell rogzitni.

### 6. Kerekitasi parity

Kotelezo elv:

- `cash total rounded to nearest 5 HUF` csak a vegosszeg szintjen,
- a conversion es rate szamitasok kozben preciz, nem lekerekitett belso ertekekkel kell dolgozni,
- a kerekites csak a fizetesi modtol es a vegosszegtol fugg.

---

## S7 NYITOTT KERDESEK / KUTATASI GAP-EK

| Gap ID | Kerdes | Statusz |
|--------|--------|---------|
| `LEGAL-GAP-01` | A jelenlegi AML rendeleti baseline implementaciojanal eleg-e a 2025-os MNB rendelet, vagy a repo egyes flow-in kifejezett 2026-os finomhangolas is kell? | nyitott |
| `LEGAL-GAP-02` | A repo legacy `conversion double-count AML` szabalya jogszabalyi vagy intezmenyi belso szabaly? | nyitott |
| `LEGAL-GAP-03` | A kezelesi koltseg NAV-szintu elszamolasi kovetelmenyehez kell-e tovabbi adojogi forrasmatrix? | nyitott |
| `LEGAL-GAP-04` | A penzvalto sajat arfolyam-jegyzesenek minden telephelyi UI-kotelezettsege teljesen lefedett-e a meglvo screenshotokkal? | nyitott |

---

## S8 AJANLOTT KOVETKEZO TUDASBAZIS-ELEMEK

1. `hungarian-money-exchange-law-matrix.md`
   - jogforras -> kotelezettseg -> rendszerkomponens -> teszt

2. `aml-sanctions-obligation-checklist.md`
   - Pmt./Kit./MNB rendelet kovetelmenyek operational checklistje

3. `rounding-and-conversion-parity-spec.md`
   - 5 Ft kerekites, conversion receipt, rate source, fee split reszletes parity specifikacioja

4. `legal-test-obligation-matrix.md`
   - mely jogi kotelezettseghez milyen backend/frontend/integration teszt kell

5. `hungarian-privacy-gdpr-baseline.md`
   - GDPR, Infotv., erintetti jogok, retention, controller/processor szerepkorok

6. `bestchange-company-public-baseline.md`
   - ceges publikus kondiciok, fiokfeed, branch topologia, partneri/public allitasok

7. `aml-sanctions-page-endpoint-checklist.md`
   - oldalankenti es endpointonkenti compliance checklist

8. `tax-accounting-fee-fx-receipt-layer.md`
   - fee, arfolyamkulonbozet, bizonylat, adougyi es szamviteli reteg
