# Nóra — Modern rendszer üzleti logika elemzés

Dátum: 2026-04-07
Scope: `D:\repo\valutavalto-program\`
Módszer: olvasásos, forráskód- és dokumentumalapú elemzés; backend + frontend + legacy gap összevetés.

---

## 1. Vezetői összkép

A modern rendszerben sok alapfolyamat valóban létezik és több kritikus üzleti terület már nem csak tervszinten van jelen: tranzakciók, napzárás, dekádjelentés, foglalás, átadások, Darius riport, kamera evidenciakezelés, offline queue, riportok.

Ugyanakkor üzleti szemmel a rendszer **nem tekinthető lezárt, teljesen konzisztens üzleti terméknek**. A fő probléma nem az, hogy „nincs semmi”, hanem az, hogy több fontos folyamat **félkész, részlegesen drótozott, vagy admin/riport szinten látszik késznek, de a végponti üzleti lezárás hiányzik**.

A legfontosabb mintázatok:
- több helyen van **UI-szintű késznek látszás**, miközben a tényleges üzleti működés még placeholder / mock / TODO jellegű;
- több kulcsfolyamatnál az **üzleti lezárás utolsó 10-20%-a hiányzik**;
- néhány helyen a modern rendszer még mindig **legacy örökséget hordoz változatlanul**, miközben a jelenlegi üzleti működés már más;
- a vezetői / operatív döntéstámogatás bizonyos képernyőkön **nem valós adatra támaszkodik**.

---

## 2. Ami üzletileg erős alapnak látszik

Pozitívumként rögzítem, hogy a kódbázis alapján az alábbi területek nem csak tervek:
- tranzakciós alaprendszer, árfolyamok, készletlogika;
- foglalás (`ReservationService`);
- dekádjelentés és dekádzárási trigger (`DecadeReportService`, `DailyClosingService`);
- átadás / transfer domain (`TransferService`);
- handover lap külön entitással és UI-val;
- kamera export / hash-chain / lokális Electron bridge;
- Darius napi riport domain objektumokkal és státuszkezeléssel;
- offline-first irány több Electron queue funkciónál.

Ez fontos, mert a hiányok többsége már nem „zöldmezős fejlesztés”, hanem **üzleti befejezés, szabálylezárás, és végponti konzisztencia** kérdése.

---

## 3. Fő üzleti logikai hiányosságok

### 3.1. A vezetői dashboard jelenleg nem üzleti igazságforrás

**Bizonyíték:** `frontend-react/src/pages/DashboardPage.tsx`

A dashboard oldalon a KPI-k és a „Legutóbbi tranzakciók” lista még mindig fix mock adatokból él:
- `mockStats`
- `mockRecentTransactions`
- komment: `Mock data - replace with API calls`

Ez üzletileg súlyosabb, mint egyszerű UI hiányosság, mert:
- a vezető / supervisor hamis napi képet lát;
- a „függő foglalók”, napi forgalom, aktív ügyfélszám nem valós működési adat;
- a rendszer késznek mutatja a döntéstámogató nézetet, de az nem auditálható üzleti adatforrás.

**Következmény:** a napi operatív irányítás, gyors ellenőrzés, és vezetői bizalom sérül.

**Értékelés:** P0/P1 határterület, mert nem mag-tranzakciós hiba, de üzleti irányítási kár nagy.

---

### 3.2. A Darius / Raiffeisen riport üzletileg csak „félútig kész”

**Bizonyítékok:**
- `backend/src/main/java/hu/puzzleir/valuta/service/DariusReportService.java`
- `docs/VALOS_ALLAPOT_JELENTES_2026-03-21.md`
- `frontend-react/src/pages/darius/DariusReportPage.tsx`

A Darius folyamatban megvan:
- státuszmodell;
- jóváhagyás;
- submit;
- retry;
- acknowledge;
- frontend oldal.

De a `submitToDarius()` jelenleg **managed outbox artifact**-ot ír fájlba, nem valódi teljes külső banki / partner transportot végez. A saját komment is ezt mondja, a valós állapotjelentés pedig külön rögzíti, hogy a teljes külső transport nincs lezárva.

Ez üzleti szemmel azt jelenti, hogy:
- a riport előállítás és adminisztratív életciklus megvan;
- a **„valóban eljutott a külső félhez és bizonyítottan feldolgozódott”** rész nincs teljesen lezárva.

**Következmény:** olyan funkció látszik késznek, amelynek a legfontosabb üzleti vége, a külső teljesülés bizonyítása, még nem teljes.

**Értékelés:** P0, ha ez kötelező partner-/banki riportolás; P1, ha átmeneti kézi folyamat pótolja.

---

### 3.3. A sztornó approval-flow nincs végigvezetve a UI-ban

**Bizonyíték:** `frontend-react/src/pages/stornos/StornoPage.tsx`

A `checkStorno()` ágban, ha `requiresApproval` igaz, ott marad a nyílt TODO:
- `// TODO: betölteni a pending approval-t`

Ez üzleti hiányosság, mert a sztornó nem csak technikai művelet, hanem tipikusan kontrollált, többszemes jóváhagyást igénylő folyamat. Ha a felület nem tudja visszatölteni a már folyamatban lévő approval állapotot, akkor:
- a felhasználó nem tudja biztosan, hol tart az ügy;
- az engedélyköteles sztornó operatív kezelése megszakadhat;
- nő a kézi egyeztetés és a félreértés veszélye.

**Következmény:** a sztornó folyamat állapotgépe backend oldalon részben létezhet, de a fronton nincs üzletileg lezárva.

**Értékelés:** P1.

---

### 3.4. A dolgozói jutalék export könyvelési oldalra nincs befejezve

**Bizonyíték:** `frontend-react/src/pages/commissions/WorkerCommissionPage.tsx`

A felületen van export gomb és accounting list hívás, de a kód közvetlenül tartalmazza:
- `// TODO: Implement CSV export`

Ez tipikus „látszólag kész” funkció. Üzletileg nem az számít, hogy lekéri-e a háttérből az adatot, hanem hogy:
- átadható-e a könyvelésnek / kontrollingnak;
- van-e letölthető, használható formátum;
- lezárt-e az adminisztratív kimenet.

**Következmény:** a jutalékszámítás lehet részben kész, de az üzleti továbbhasznosítás nincs lezárva.

**Értékelés:** P1.

---

### 3.5. A kamera visszajátszás böngészős üzleti használata hiányos

**Bizonyíték:** `frontend-react/src/pages/camera/CameraPlaybackPage.tsx`

A böngészős ágon a lekérdezés így épül:
- `branchId: '' // TODO: branch selector`

Vagyis a szerveroldali keresésnél a fiók/iroda kiválasztás hiányzik. Ez nem pusztán UX probléma, hanem üzleti használhatósági rés:
- több irodás cégnél a felvétel visszakeresés branch kontextus nélkül nem elégséges;
- incidens, reklamáció, audit, compliance helyzetben a keresés pontossága kulcskérdés;
- az Electron lokális ág és a központi / admin ág üzleti képessége eltér.

**Következmény:** a kamera funkció egyik legfontosabb üzleti célja, a gyors visszakereshetőség és auditálható bizonyítás, webes/admin működésben hiányos.

**Értékelés:** P1.

---

### 3.6. Az átadólap (handover sheet) külön modulja túl vékony üzleti kontrollal működik

**Bizonyítékok:**
- `backend/src/main/java/hu/puzzleir/valuta/controller/HandoverSheetController.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/HandoverSheetService.java`
- `frontend-react/src/pages/handover/HandoverSheetPage.tsx`

A handover sheet modul létezik, de a service alapján a maglogika nagyon vékony:
- `generate()` főként státuszt állít és ment;
- `print()` csak `PRINTED` státuszra vált;
- `complete()` csak `COMPLETED` státuszra vált;
- nincs látható üzleti validáció az átadás szereplőire, összegkonzisztenciára, nyomtatási előfeltételre, lezárási sorrendre;
- `getById()` a kódrészlet alapján nem ellenőrzi cég-/iroda-hozzáférést, csak ID szerinti lekérés van.

A frontend oldalon az „Új átadó lap” űrlapban sincs látható erős üzleti validáció:
- küldő/fogadó pénztár kiválasztás;
- dátum;
- de az üzleti mezők és lezárási kontroll minimálisnak látszanak.

Ez arra utal, hogy a domain jelen van, de az **átadólap mint szigorú üzleti és audit dokumentum** még nincs teljesen kidolgozva.

**Következmény:** a modul inkább admin státuszkezelésnek látszik, mint valódi, szigorúan kontrollált átadás-átvételi folyamatnak.

**Értékelés:** P1.

---

### 3.7. A closing wizard még részben örökölt, részben bizonytalan üzleti modellt hordoz

**Bizonyítékok:**
- `frontend-react/src/pages/closing/ClosingWizardPage.tsx`
- `backend/src/main/java/hu/puzzleir/valuta/service/DailyClosingService.java`
- `D:\openclaw\.openclaw\workspace\vault\03_creating\legacy-reverse-engineering\RE-gap-analysis-legacy-vs-modern.md`

A closing wizard fix listában szerepeltet:
- Western Union MTCN ellenőrzés;
- Western Union címletezés;
- E-kereskedelem címletezés;
- Egyéb címletezések (AXA/MoneyGram).

Ezzel két üzleti probléma van:
1. a wizard erősen legacy-szemléletű fix lépéslistát őriz;
2. nem látszik, hogy ezek **irodánként / cégenként / tényleges szolgáltatás-scope szerint dinamikusan aktiválódnak-e**.

Ha egy partner vagy szolgáltatás már nem releváns, de a napi zárásban még mindig kötelezően megjelenik, az:
- felesleges adminisztratív terhelés;
- félrevezető operatív folyamat;
- hibás lezárási tudatot adhat.

A backend oldalon a dekádzárás logikája korrektnek látszik, de a teljes zárási UX továbbra is erősen „örökölt lista” jellegű.

**Következmény:** a zárási folyamat üzleti testreszabhatósága és jelenkori valósága kérdéses.

**Értékelés:** P1.

---

### 3.8. A szinkronizációs „szükséges-e szinkron?” logika üzletileg túl egyszerű

**Bizonyíték:** `backend/src/main/java/hu/puzzleir/valuta/service/SynchronizationService.java`

A `shouldSync()` jelenleg lényegében azt nézi, hogy van-e ma tranzakció:
- ha van mai tranzakció, kell sync;
- különben nem.

Ez üzleti szinten túl egyszerű, mert a tényleges szinkronigény nem csak ettől függhet:
- van-e pending queue;
- van-e sikertelen korábbi feltöltés;
- van-e beérkező letöltendő adat;
- van-e függő handover/storno/transfer/bank transaction;
- van-e részleges offline üzem maradvány.

**Következmény:** a rendszer alulbecsülheti a szinkronigényt, tehát „nyugodtnak” látszó állapotban is maradhat üzleti teendő.

**Értékelés:** P1.

---

### 3.9. A compliance és export irány moduláris szinten is félkész

**Bizonyíték:** `frontend-react/src/features/README.md`

A feature-szintű dokumentáció explicit TODO-ként jelöli:
- `compliance/         # Megfelelőségi modul (TODO)`
- `export/             # Export modul (TODO)`

Ez azért fontos, mert a modern rendszer egyik valódi üzleti értéke épp a szabályozott megfelelőség és szabványos exportkimenetek lennének. Ha ezek még architekturális szinten is TODO-k, az azt jelzi, hogy:
- a rendszer magja elkészültebb, mint a köré épülő vállalati működési réteg;
- a compliance/export még nincs lezárt termékszintre hozva.

**Értékelés:** P1/P2, attól függően, mennyi meglévő funkció maradt a régi API-rétegben.

---

## 4. Legacy-összevetésből látszó üzleti kockázatok

### 4.1. A dekád logika jelen van, de a profit-számítás üzleti hitelesítése még érzékeny pont

**Bizonyítékok:**
- `backend/src/main/java/hu/puzzleir/valuta/service/DecadeReportService.java`
- `vault/03_creating/legacy-reverse-engineering/szerver-business-logic.md`

A legacy elemzés kifejezetten kiemeli a haszonképletet, és jelzi, hogy a modern oldalon ellenőrizendő az egyezés. A modern service már számol dekád profitot, de üzleti szemmel ez akkor tekinthető lezártnak, ha:
- a legacy képlettel egyezése bizonyított;
- a könyvelési / vezetői eredményszámokkal egyezik;
- devizanemenként és időszakosan validált.

**Megállapítás:** a funkció nem hiányzik, de a pénzügyi hitelesség szempontjából ez még különösen érzékeny terület.

---

### 4.2. Az átadási / transfer domain erősebb, mint a handover sheet domain

**Bizonyítékok:**
- `backend/src/main/java/hu/puzzleir/valuta/service/TransferService.java`
- `backend/src/main/java/hu/puzzleir/valuta/service/HandoverSheetService.java`

A `TransferService` üzleti mélysége láthatóan nagyobb:
- direction logika;
- státuszkezelés;
- célfiók kontroll;
- kasszaegyenleg-frissítés;
- tranzakciók létrehozása.

Ehhez képest a handover sheet külön modul túl egyszerű. Ez arra utal, hogy a rendszerben két rokon üzleti terület **eltérő érettségi szinten** áll.

**Üzleti veszély:** a felhasználó nem mindig világos, melyik a „jogi/operatív igazságforrás”: a transfer vagy a handover sheet.

---

## 5. Rejtett termékstratégiai probléma: több helyen késznek látszó, de nem lezárt admin funkciók

A legaggasztóbb mintázat nem egyetlen bug, hanem ez:

1. a felület megmutat egy funkciót,
2. az API gyakran létezik,
3. az alap domain is megvan,
4. de a végső üzleti output hiányzik.

Erre konkrét példák:
- dashboard: valós KPI helyett mock;
- jutalék: export gomb van, CSV nincs;
- sztornó: approval szükséges, de pending approval betöltés TODO;
- kamera playback: webes branch selector TODO;
- Darius: submit van, de valódi külső transport teljes bizonyítása nincs lezárva.

Ez termékvezetési szempontból azt jelzi, hogy a projekt sok helyen **a „látható készültséget” előbb érte el, mint a tényleges üzleti zártságot**.

---

## 6. Prioritási sorrend üzleti szemmel

### P0 – azonnal lezárandó
1. **Dashboard valós adatforrásra kötése**
   - mert jelenleg hamis operatív képet ad.
2. **Darius / Raiffeisen teljes külső teljesülés bizonyítása**
   - ha kötelező partneri/banki funkció.
3. **Closing wizard scope-valósítás felülvizsgálata**
   - a ténylegesen élő szolgáltatásokra és cégekre szabva.

### P1 – következő körben lezárandó
4. **Sztornó approval-flow UI befejezése**
5. **Jutalék export tényleges könyvelési kimenettel**
6. **Camera playback branch-szintű admin keresés befejezése**
7. **Handover sheet üzleti validációk és státusz-sorrend megerősítése**
8. **Szinkronigény logika kibővítése valódi pending/failed állapotokkal**

### P2 – termékérettségi javítás
9. **Compliance/export modulok tényleges moduláris lezárása**
10. **Transfer vs handover sheet szerepek egyértelműsítése**
11. **Dekád profit üzleti validáció dokumentált lezárása**

---

## 7. Rövid végkövetkeztetés

A modern valutaváltó rendszer **nem üres és nem ál-rendszer**: valódi üzleti magja már erős. De jelenlegi állapotában több fontos területen még **„üzletileg félkész”**:
- vagy a külső teljesülés hiányzik,
- vagy a vezetői/operatív nézet nem valós,
- vagy a folyamat utolsó kontroll-lépése nincs bekötve,
- vagy a legacy modell maradványai még torzítják a mai működést.

Az én önálló megítélésem szerint a projekt legnagyobb kockázata most már nem az alapfunkciók hiánya, hanem a **hamis készültségérzet**. A következő fejlesztési szakasz fókusza ezért nem új modulok nyitása, hanem a meglévő üzleti folyamatok **végigzárása, bizonyítása és letisztítása** kell legyen.

---

## 8. Bizonyítékjegyzék

Főbb olvasott források:
- `D:\repo\valutavalto-program\REPO_STATE.md`
- `D:\repo\valutavalto-program\docs\VALOS_ALLAPOT_JELENTES_2026-03-21.md`
- `D:\repo\valutavalto-program\backend\src\main\java\hu\puzzleir\valuta\service\DariusReportService.java`
- `D:\repo\valutavalto-program\backend\src\main\java\hu\puzzleir\valuta\service\SynchronizationService.java`
- `D:\repo\valutavalto-program\backend\src\main\java\hu\puzzleir\valuta\service\HandoverSheetService.java`
- `D:\repo\valutavalto-program\backend\src\main\java\hu\puzzleir\valuta\service\TransferService.java`
- `D:\repo\valutavalto-program\backend\src\main\java\hu\puzzleir\valuta\service\DecadeReportService.java`
- `D:\repo\valutavalto-program\backend\src\main\java\hu\puzzleir\valuta\service\DailyClosingService.java`
- `D:\repo\valutavalto-program\frontend-react\src\pages\DashboardPage.tsx`
- `D:\repo\valutavalto-program\frontend-react\src\pages\camera\CameraPlaybackPage.tsx`
- `D:\repo\valutavalto-program\frontend-react\src\pages\commissions\WorkerCommissionPage.tsx`
- `D:\repo\valutavalto-program\frontend-react\src\pages\stornos\StornoPage.tsx`
- `D:\repo\valutavalto-program\frontend-react\src\pages\handover\HandoverSheetPage.tsx`
- `D:\repo\valutavalto-program\frontend-react\src\pages\closing\ClosingWizardPage.tsx`
- `D:\repo\valutavalto-program\frontend-react\src\features\README.md`
- `D:\openclaw\.openclaw\workspace\vault\03_creating\legacy-reverse-engineering\RE-gap-analysis-legacy-vs-modern.md`
- `D:\openclaw\.openclaw\workspace\vault\03_creating\legacy-reverse-engineering\szerver-business-logic.md`
