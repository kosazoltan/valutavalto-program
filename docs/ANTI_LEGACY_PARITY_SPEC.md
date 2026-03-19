# Anti Legacy Functional Spec And Parity

## Cel

Ez a dokumentum a `Anti/` legacy referencia-program viselkedesebol keszult belso funkcionalis specifikacio, valamint a jelenlegi rendszerhez kepesti parity-ertekeles.

Nem marketing leiras. A cel az, hogy a legacy rendszer valodi uzemi logikajat modulonkent szetbontsuk, es kimondjuk, hogy a mai rendszerben mi van:

- tenylegesen megvalositva
- reszben megvalositva
- hianyzik vagy nincs osszekotve

## Forrasok

### Legacy referenciak

- `Anti/VALUTA/IBVALTO/Unit18.pas`
- `Anti/VALUTA/IBVALTO/Unit3.pas`
- `Anti/VALUTA/DLL/NAPZAR/MAKEDLL/Unit2.pas`
- `Anti/VALUTA/DLL/VASARLAS/MAKEDLL/Unit2.pas`
- `Anti/VALUTA/DLL/ELADAS/MAKEDLL/Unit2.pas`
- `Anti/VALUTA/DLL/ATADVET/MAKEDLL/Unit2.pas`
- `Anti/VALUTA/DLL/ATADOLAP/MAKEDLL/unit2.pas`
- `Anti/VALUTA/DLL/GETARF/MAKEDLL/Unit2.pas`
- `Anti/SZERVER/fejleszt/*`
- `Anti/SZERVER/ujdll/*`

### Jelenlegi rendszerben ellenorzott fo pontok

- `backend/src/main/java/hu/puzzleir/valuta/service/TransactionService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/AmlService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/StornoService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/TransferService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/VaultTransferService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/DailySessionService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/SessionOpenService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/ClosingWizardService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/RateCreationService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/ExchangeRatePollingService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/EveningClosingService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/MnbReportService.java`
- `frontend-react/src/pages/transactions/CashierTransactionPage.tsx`
- `frontend-react/src/pages/transactions/ConversionPage.tsx`
- `frontend-react/src/pages/stornos/StornoPage.tsx`
- `frontend-react/src/pages/transfers/TransferPage.tsx`
- `frontend-react/src/pages/treasury/MovementManager.tsx`
- `frontend-react/src/pages/treasury/BankTransactions.tsx`
- `frontend-react/src/pages/handover/HandoverSheetPage.tsx`
- `frontend-react/src/pages/closing/ClosingWizardPage.tsx`
- `frontend-react/src/utils/electronTransactions.ts`
- `penztar-client/electron/sqlite.ts`
- `penztar-client/electron/sync-engine.ts`

## Korrigalt napzaras-megallapitas

Korabban az a kovetkeztetes szuletett, hogy a napzaras a mostani rendszerben gyengebb vagy csak leptetos wizard-szintu. Ez igy onmagaban pontatlan.

A tenyleges helyzet:

1. A jelenlegi backendben van egy valodi, legacy-ihletesu napzarasi szolgaltatas:
   - `DailyClosingService.startDailyClosing()` 9 technikai ellenorzesi lepest futtat, majd ha minden PASS, meghivja az archivast, session-zarast, POS-zarast, esti adatkuldeset es dekadriportot.
2. Ugyanakkor a jelenlegi penztarosi UI ezt a szolgaltatast nem hasznalja.
3. A jelenlegi `ClosingWizardPage` csak a wizard objektumot inditja el, majd `navigate()` hivasokkal leptet, vegul `complete()`-et hiv.
4. A `ClosingWizardService.navigate()` jelenleg csak a `currentStep` mezot allitja, nem hajt vegre napzarasi ellenorzest.
5. A `ClosingWizardService.complete()` csak azt ellenorzi, hogy minden wizard-lepes `completed=true`, de ezt a mostani UI nem a valos step-endpointokon keresztul allitja elo.
6. A repo-ban levo `DailyClosingService` jelenleg definicio szerint letezik, de felhasznalasi helye a production kodban nem talalhato; a referenciakereses alapjan gyakorlatilag csak tesztbol hivatkozik ra.

Kovetkeztetes:

- a backendben a napzaras logikai magja reszben mar meg van irva
- a penztarosi UI altal hasznalt napzarasi folyamat jelenleg nincs teljesen raakasztva erre a magra
- ezert a napzaras parity allapota nem `hianyzik`, hanem `reszben megvan, de nincs vegig integralva`

## Legacy rendszer mukodesi specifikacio

### 1. Foutvonal: a legacy nem monolit kepernyo, hanem DLL-lanc

Az `IBVALTO` fo alkalmazas csak a kezelofelulet es a menu. A valos uzemi logika nagy resze kulso DLL-ekben fut:

- penztari tranzakciok: `VASARLAS`, `ELADAS`
- konverzio: `IBVALTO/Unit3.pas`, ami egymas utan hivja a veteli es eladasi DLL-t
- napzaras: `NAPZAR`
- cimletezes es kontroll: `CIMLCTRL`, `CIMLMENU`, `CIMLNYOM`
- ugyfel- es AML-szeru ellenorzes: `BIGCTRL`, `UGYFEL`, `CHECKLST`
- atadas-atvetel: `ATADVET`
- atadolap/file kezeles: `ATADOLAP`
- arfolyam letoltes es frissites: `GETARF`

Az alkalmazas allapotat a legacy rendszer erosen kozos adatbazis-tabla es atmeneti tabla kozpontu modon vezeti:

- `HARDWARE`
- `VTEMP`
- `BLOKKFEJ`
- `BLOKKTETEL`
- kulon napi/havi gyujto tablaksorok

### 2. Penzarnyitas es napi allapot

Legacy logika:

- a napi allapotot a `HARDWARE.MEGNYITOTTNAP` tartja
- a lezart napot a `HARDWARE.LEZARTNAP` tartja
- tobb modul mindig a `HARDWARE` tablabol olvassa ki, hogy melyik nap van nyitva
- a tranzakcios DLL-ek a napi datumot es a penztaros azonositot is innen vagy kapcsolodo allapotbol veszik

Ebből uzleti szinten az kovetkezik, hogy a rendszerben a nap megnyitasa es a napi munka nem puha UI-allapot, hanem globalis uzemallapot.

### 3. Vetel es eladas

Legacy vetel/eladas jellemzok:

- a kepernyok erosen cimlet-orientaltak
- kulon limitkezeles van
- kulon ugyfelazonositas fut
- kulon kisugyfel-lekerdezes fut
- a tranzakcio kozben BIGCTRL fut a limit- es ugyfelvizsgalathoz
- a tranzakcios lapok tobb helyen kozvetlenul irnak a `VTEMP` es kapcsolodo tablakba
- a napi datum, ugyfelszam, ugyfeltipus, nevtabla, megbizott, limit stb. mind a tranzakcios allapot resze

Uzleti jelentese:

- a tranzakcio nem pusztan `osszeg + valuta + rate`
- a rendszer minden komolyabb ugyletet ugyfel-, limit-, nap- es ellenorzes-kontextusban kezel
- a cimletezes es a papir/bizonylat a tranzakcio integralt resze

### 4. Konverzio

Legacy konverzio logika:

- nem onallo uj elszamolasi modell
- a `Unit3.pas` elobb meghivja a `vasarlasrutin`-t, utana az `eladasrutin`-t
- a ket lepest a `VTEMP` kozos koztes allapot es a `GetFizetendo()` kapcsolja ossze

Uzleti jelentese:

- a konverzio ket valodi penzmuvelet egymas utan
- a legacy rendszer szemeben ez nem roviditett shortcut, hanem szabalyos vetel + eladas kombinacio

### 5. Sztorno

Legacy szellemiseg:

- napi sztorno-limit van
- bizonyos mennyiseg folott supervisor vagy kulon jovahagyas kell
- a sztorno nem egyszeru torles, hanem valodi ellentranzakcio

### 6. Napzaras

Legacy napzaras tobb retegbol all:

1. az `IBVALTO` felulet meghivja a `napzarrutin` DLL-t
2. a `NAPZAR` modul ellenorzi a napi allapotot (`MEGNYITOTTNAP`, `LEZARTNAP`)
3. lefuttat kulon kontrollokat
4. osszeszamolja a napi forgalmat
5. beolvassa a zaro allapotokat
6. meghatarozza a nyitot a kovetkezo logikai lepesekhez
7. havi/napi gyujto tablakba masol
8. frissiti a globalis napallapotot

Ez nem pusztan reportkeszites, hanem napi archivacio + kontroll + allapotvaltas.

### 7. Atadas-atvetel es ertektar

Legacy `ATADVET` es `ATADOLAP` logika:

- kulon rutint kap az atadas-atvetel
- kulon kezeli a penztar es ertektar kozti mozgasokat
- van teljes keszlet atvetel (`EverythingTake`)
- van ertektari teljes atvetel es penztari teljes atvetel
- kulon `KeszletControl` fut
- kulon `CimletNyomtatas` fut
- az atadolap fajl alapu munkakonyvtarban el (`c:\valuta\atadolap`), archivummal
- a rendszer kiolvassa a beerkezett lapfajlokat, archivba mozgatja oket, es lokalis/remote file szinten is dolgozik

Uzleti jelentese:

- a treasury funkcio a legacyben nem csak transfer-record
- hanem file-alapu atadolap-keringes + teljes keszlet-atadas + cimletszintu kezeles + ellenorzes

### 8. Arfolyam letoltes es arfolyamterjesztes

Legacy `GETARF` logika:

- internet-ellenorzes van
- FTP kapcsolat epul
- arfolyamfajlokat keres (`NR*.DAT`, `RM*.ARF`)
- MNB frissites kulon rutin
- valtozas-detektalas kulon rutin
- kulon log uzenet megy, ha valtozott vagy nem valtozott az arfolyam
- a legacy rendszerben a terjesztes erosen fajl- es FTP-alapu

Uzleti jelentese:

- az arfolyamkeszites nem csak kezi rogzites
- van kulso forras, letoltes, valtozasfelismeres es tovabbitas

### 9. Ellenorzo rutinok / AML-jellegu kontrollok

Legacy `BIGCTRL` es kapcsolodo modulok:

- ugyfeltipus
- ugyfelszam
- napi/heti/eves aggregalt kontrollok
- limitkezeles
- kisugyfel kulon ut
- terror/szankcioszeru ellenorzesi logika kulon modulokkal
- a tranzakcios DLL-ek a kontrolldontest bemenetkent atadják a BIGCTRL fele

Uzleti jelentese:

- az ellenorzes a legacyben a tranzakcio resze, nem utolagos admin riport

### 10. Legacy szerver-oldali mukodes

Az `Anti/SZERVER` fa alapjan a legacy szerver nem egyetlen szolgaltatas, hanem sok kulon folyamat:

- arfolyam
- adatgyujtes
- import
- terror
- ugyfelcontrol
- western / wucontrol
- kezdij
- mnbgyujto
- zarasctrl
- tranzakcios es forgalmi osszesito modulok

Ez a kep azt mutatja, hogy a regi uzem kulon hatterfolyamatokra bontotta:

- napi gyujtest
- adatkuldest
- arfolyamkarbantartast
- ellenorzo folyamatokat
- partnermodulokat

## Jelenlegi rendszer parity-ertekeles

### A. Penzttar / penztari alapfolyamatok

#### Ami megvan

- buy/sell backend oldalon szerveresen ujraszamolt tranzakciokent fut
- van kulon konverzio futas
- van kulon sztorno-szolgaltatas es jovahagyasi logika
- Electron alatt a kritikus penzmozgasi folyamatok local-first queue-n keresztul is tudnak menni

#### Ami reszleges

- a legacy UI-ban sokkal gazdagabb a cimlet-, limit-, ugyfel- es kezelesi allapot
- a mostani penztaros UI funkcionalisan kepes vegrehajtani a fo muveleteket, de nem ugyanazzal a legacy-melyseggel
- a konverzio a legacyben explicit vetel+eladas lanc; a mostani backendben onallo szolgaltatasi muveletkent is kezelheto

#### Statusz

`RESZBEN MEGVALOSITVA`

Fo ok:

- az uzleti mag megvan
- a legacy reszletessegu tranzakcios allapotgep es cimlet-/ugyfelkezeles nincs teljes melysegben reprodukalva a penztarosi feluleten

### B. Napnyitas

#### Ami megvan

- kulon napi nyitas a `DailySessionService.openDay()` es `SessionOpenService.openSession()` oldalon
- ellenorzi a nyitott elozo sessiont
- atviszi a nyitoegyenlegeket

#### Statusz

`MEGVALOSITVA`

Megjegyzes:

- a modern megoldas adatmodellben mas, mint a legacy `HARDWARE`, de uzletileg a napi allapot kezeles megvan

### C. Napzaras

#### Ami megvan

- van egyszeru napi session-zaras a `DailySessionService.closeDay()` oldalon
- van kulon `ClosingWizardService` a legacy 16 lepeses struktura modellezesere
- van kulon `DailyClosingService`, ami 9 technikai lepeses belso ellenorzesi lancot futtat, majd:
  - arfolyam snapshot
  - session zaras
  - napi merleg
  - POS napi zaaras
  - esti kozponti sync
  - archivacio
  - AML napi reset
  - dekadriport

#### Ami hianyzik vagy nincs vegig integralva

- a jelenlegi penztaros UI nem a `DailyClosingService` valodi vegrehajto logikajat futtatja
- a `ClosingWizardPage` jelenleg a wizard-lepeseket `navigate()`-tel lepteti
- a step-specifikus backend endpointok (`validate-transactions`, `denominations`, `differences`, `report`, `finalize`) leteznek, de a mostani UI nincs rajuk teljesen felkotve
- a `DailyClosingService` production oldali felhasznalasa a repo-ban nem lathato

#### Statusz

`RESZBEN MEGVALOSITVA, NINCS VEGIG OSSZEKOTVE`

Ez a legfontosabb korrekcio az elozo megallapitashoz kepest.

### D. Atadas-atvetel / ertektar

#### Ami megvan

- iroda kozti transfer backend oldalon mukodik
- van fogadas, elutasitas, torles
- van negativ keszlet vedelme a forras oldalon
- van kulon `VaultTransferService` supervisor-kuszobbel es WAC kezelessel
- van banki tranzakcio oldal
- van handover sheet oldal
- Electron local-first queue a treasury muveletekhez is megvan

#### Ami reszleges vagy hianyzik a legacyhez kepest

- a legacy `ATADVET` teljes keszlet-atvetelt, ertektari teljes atvetelt, penztari teljes atvetelt, keszletkontrollt es cimletnyomtatast is tartalmazott
- a legacy `ATADOLAP` fajlrendszeres atadolap tarolast, archivumot, beerkezo lapbeolvasast es remote/local fajlkezelesi kort hasznalt
- a mai `HandoverSheetService` lenyegesen egyszerubb: generate / print / complete statuszvaltassal
- a treasury UI-ban a business core megvan, de a legacy operativ melyseg nincs teljesen visszaepitve

#### Statusz

`RESZBEN MEGVALOSITVA`

### E. Arfolyamkeszites es terjesztes

#### Ami megvan

- van `RateCreationService` workgroup, limit, overview es group publish logikaval
- van `RateCreationController` a kezi elokesziteshez es publikaciohoz
- van `ExchangeRatePollingService` MNB/ECB HTTP pollinggal, fallback lancgal es idozitett futassal
- van `ExchangeRatePollingController` manualis triggerrel es status endpointtal
- van `MnbReportService` es `MnbReportController` napi/havi riporttal, validacioval es submit logikaval

#### Ami reszleges a legacyhez kepest

- a legacy rendszer fajl- es FTP-alapu arfolyamkuldest hasznalt, explicit valtozasfelismeressel es rate-file allomanyokkal
- a mai rendszer modernebb es jobb architekturaju, de nem ugyanazt a binaris/file alapu operacios modellt viszi tovabb
- a `RateCreationService` reszben a jelenlegi exchange rate allapotbol epitkezik; a legacy oldalon kulon letolto es kioszto kor explicit volt

#### Statusz

`UZLETILEG MEGVALOSITVA, TECHNIKAILAG MODERNIZALT`

Itt nem klasszikus hiany van, hanem szandekos technologiai atalakitas.

### F. Ellenorzo rutinok / AML / ugyfelkontroll

#### Ami megvan

- a `TransactionService` az `AmlService.checkTransaction()`-t hivja
- az `AmlService` kezeli a 300k, 1.5M, eves, heti, negyedeves, napi gyanu logikat
- van szankcios screening
- van customer osszesitesi es riport logika
- a `StornoService` napi limitet es supervisor jovahagyast is kezel

#### Ami reszleges

- a legacy kontrolldontes es a tranzakcios UI sokkal szorosabban volt egybeepitve a teljes ugyfel- es limit-kepernyovel
- a mai rendszerben a backend kontroll eros, de a legacy kepernyos operativ rutinok nem egy az egyben elnek tovabb

#### Statusz

`NAGYRESZT MEGVALOSITVA`

### G. Szerver mukodes

#### Ami megvan

- modern Spring backend controller- es service-strukturaval
- scheduled arfolyam polling
- esti adatcsomag-keszites es REST kuldes (`EveningClosingService`)
- MNB riportkeszites, validacio, submit
- closing control, monthly closing, decade report, archive, POS zaaras, health endpointok

#### Ami reszleges vagy nyitott

- a legacy `SZERVER` fa sok kulon mikro-feladatot tartalmazott modulonként szetbontva; ennek teljes funkcionalis parity-je ebben a korben nem igazolhato sorrol sorra minden almappaban
- a jelenlegi rendszerben a szerver-oldali felelossegek nagy resze mar letezik, de az osszes legacy kismodulet (pl. egyes partneri vagy specialis import folyamatok) parity-je tovabbi melyolvasast igenyelne

#### Statusz

`RESZBEN IGAZOLT, MAG FOLYAMATOK MEGVANNAK`

## Tomor parity matrix

| Terulet | Allapot | Megjegyzes |
| --- | --- | --- |
| Penztari vetel/eladas | Reszben megvalositva | Core megvan, legacy UI-melyseg nincs teljesen visszaepitve |
| Konverzio | Reszben megvalositva | Mukodik, de legacyben explicit vetel+eladas lanc |
| Sztorno | Nagyreszt megvalositva | Supervisor es reversal logika megvan |
| Napnyitas | Megvalositva | Session/opening balance logika megvan |
| Napzaras | Reszben megvalositva | Backend mag megvan, UI nincs vegig rakotve |
| Atadas-atvetel | Reszben megvalositva | Transfer core megvan, legacy teljes keszlet/file workflow hianyos |
| Ertektar | Reszben megvalositva | Vault transfer megvan, de legacy operativ reszletesseg nem teljes |
| Atadolap | Reszben megvalositva | Modern handover sheet sokkal egyszerubb |
| Arfolyamkeszites | Uzletileg megvalositva | Modern polling + publish van |
| Arfolyamterjesztes | Technologiailag atalakitva | FTP/file helyett HTTP + DB + outbox/WebSocket |
| Ellenorzo rutinok | Nagyreszt megvalositva | AML/sanction/rolling logika eros |
| Szerver magfolyamatok | Reszben igazolt | Polling, esti sync, riport, archive megvan |

## Vegso itelet

### Mi mondhato biztosan

1. A mostani rendszer nem ures vaz. A penzmozgasok, AML, local-first offline mentes, transfer, rate management es tobb reporting/backend folyamat tenylegesen el.
2. A legacy rendszerhez kepest a legnagyobb elteres nem a buy/sell magban, hanem az operativ penztari melysegben es a napzarasi UI-integracioban van.
3. A napzarasrol a helyes allitas ez:
   - a backendben jelentosen tobb logika van, mint amit a jelenlegi UI hasznal
   - a teljes legacy parity a napzarasnal jelenleg nincs lezart allapotban
4. Az ertektar/atadas-atvetel teruleten van modern alap, de a legacy teljes keszlet-, cimlet- es fajlforgalmi rutinjaihez kepest meg van hiany.

### Mi nem mondhato ki jelenleg felelosen

Nem mondhato ki, hogy a legacy referencia-program penztar + ertektar + arfolyam + ellenorzo rutin + szerver funkcionalitasa `teljesen` le van fedve a jelenlegi rendszerben.

Ezert a jelenlegi allapotban az alábbi muveletsor nem indokolt automatizmusbol:

- merge
- push
- `kesz` allapot deklaralasa legacy parity szempontbol

## Javasolt kovetkezo fejlesztesi sorrend

1. A `ClosingWizardPage` kotese a valodi napzarasi backendhez.
2. A `DailyClosingService` production controller/API bekotese.
3. Treasury parity bovites:
   - teljes keszlet-atadas
   - keszletkontroll
   - cimletnyomtatas / cimletszintu zarasi workflow
   - handover file/archive szemantika, ha uzletileg meg mindig kell
4. Legacy-specifikus partnermodulok atnezese a `SZERVER` fa alapjan kulon korben.
