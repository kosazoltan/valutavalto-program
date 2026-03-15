# Sprint Teljes Leiras es Fuggetlen Audit Playbook

Datum: 2026-03-15
Scope: teljes nagy sprint osszefoglalo + masik nezopontu, szakszeru, vegigviheto teljes repo-ellenorzes

## 1. Dokumentum celja

Ez a dokumentum ket dolgot ad at:

1. Teljes sprint-narrativa: honnan indultunk, mit mihez hasonlitottunk, mi keszult el, mi maradt nyitva.
2. Fuggetlen audit-kezikonyv: hogyan lehet a teljes repot szakmailag ujraellenorizni masik nezopontbol, ugy hogy a technikai mukodesen tul az uzleti logika, megfeleloseg es szamviteli pontossag is bizonyitott legyen.

Ez nem csak statuszriport, hanem vegrehajtasi utmutato is.

## 2. Kiindulasi allapot (honnan indultunk)

### 2.1 Rendszer- es projektallapot a sprint elejen

- A kodbazis nagyreszt mukodokepes volt, de legacy parity szempontbol tobb kritikus nyitott pont maradt.
- A technikai gate-ek alapvonalon jellemzoen jok voltak (tesztek/lint), viszont parity-bizonyitek oldalrol hianyos volt a kep.
- A parity donteshez szukseges, osszerendezett dokumentacios csomag nem volt elegge vegigvezetve egyetlen vezetoi nezettol az implementacios bizonyitekokig.

### 2.2 Fobb kezdeti gap-ek

- Treasury aggregacio parity: branch-group es company aggregacio kodszintu bizonyiteka hianyos volt.
- Napi nyitokeszlet parity: nem volt egyertelmu, hogy a kovetkezo nap nyitasa automatikusan a legutobbi zarasbol kovetkezik-e.
- Security formalizmus: controller-szintu PreAuthorize lefedettseg nem volt 100%-ra auditolt allapotban.
- Parity igazolas: tobb teruleten a kod jelen volt, de UAT/hardver/business bizonyitek hianyzott.

### 2.3 Miert volt ez kritikus

- A build-zold allapot onmagaban nem bizonyit uzleti parity-t.
- A release-go donteshez nem eleg a technikai stabilitas; szukseges a bizonyithato uzleti helyesseg es megfeleloseg is.

## 3. Mit mihez hasonlitottunk (osszehasonlitasi keret)

A sprintben hasznalt osszehasonlitasi logika tobb retegu volt.

### 3.1 Legacy referencia vs uj rendszer

- Legacy viselkedes referencia: docs/LEGACY-FULL-AUDIT.md
- Legacy vs uj allapot kulonbsegek: docs/LEGACY-VS-NEW-COMPARISON.md
- API felszin referencia: docs/API-OVERVIEW.md
- Domain kovetelmenyek: valutavaltas, AML, napzaras, treasury, foglalo, riportok

### 3.2 Dokumentumok egymas kozti koherenciaja

- Checklist: docs/LEGACY_PARITY_CHECKLIST.md
- Evidence matrix: docs/LEGACY_PARITY_EVIDENCE_MATRIX.md
- P1 vegrehajtasi terv: docs/LEGACY_PARITY_P1_ACTION_PLAN.md
- Executive status: docs/LEGACY_PARITY_EXEC_STATUS.md

Cel: ugyanaz a valosag jelenjen meg technikai, vezetoi es auditnezetben is.

### 3.3 Kod vs teszt vs policy osszevetes

- Kodszintu implementacio ellenorzese (service/controller/DTO).
- Security policy osszevetes (public endpoint-ek vs kotelezo authentikacio).
- Celzott regressziok + teljes tesztkor osszevetese.

### 3.4 Mi szamitott bizonyiteknak

- Fordulas es tesztfutas PASS eredmeny.
- Kodsorokkal igazolt implementacio.
- Dokumentumba emelt, visszakeresheto statusz es gap-lista.

## 4. Sprint kronologia (mi tortent sorrendben)

### 4.1 Fazis A: parity keret letrehozasa

- Elkeszult a teljes checklist/evidence/action-plan/status dokumentumnegyes.
- Ez adta meg a vegrehajtas sorrendjet es a GO/NO-GO nyelvet.

### 4.2 Fazis B: security audit vegrehajtasa

- Controller audit lefutott.
- Kezdeti eredmeny: 124 controllerbol 11-ben nem volt explicit PreAuthorize.
- Controllerenkenti elemzes keszult: mi intentionalisan public, mi legyen vedett.

### 4.3 Fazis C: P1 technikai gap-ek kodszintu zarasa

- Treasury dashboard bovitve branch-group aggregacioval.
- Treasury dashboard bovitve company aggregacioval.
- Napi nyitokeszlet logika: elozo lezart nap zarokeszletet vigye at nyitokeszletnek.
- Hianyzo security annotaciok potlasa.

### 4.4 Fazis D: regressziojavitas a teljes tesztkor alapjan

- Elso teljes backend tesztkoron hiba jelent meg (AML null-path + rate approval teszt elteresek).
- Javitas tortent TransactionService-ben null-safe AML fallback-gel.
- Javitas tortent a kapcsolodo service tesztmockokban/assertokban.
- Ujrafuttatas utan a teljes backend tesztkor PASS.

### 4.5 Fazis E: vegso stabilizalas es dokumentacios szinkron

- Penztar-client gate-ek: test, typecheck, IPC contract PASS.
- Security audit vegso allapot: 124/124 controller lefedett explicit PreAuthorize annotacioval.
- Parity dokumentumok frissitve a valos implementacios allapotra.
- Commit es push megtortent main agra.

## 5. Mi keszult el konkretan

### 5.1 Keszult backend fejlesztesek

- Treasury branch-group summary implementacio.
- Treasury company summary implementacio.
- Nyitokeszlet carry-forward logika a napi session kezelesben.
- Security annotacios lefedettseg teljesre emelve.
- AML null-safe kezeles stabilizalva.

### 5.2 Keszult teszt- es minosegi munka

- Celzott regresszios csomag PASS.
- Teljes backend tesztkor PASS.
- Penztar-client test + typecheck + IPC contract PASS.

### 5.3 Keszult dokumentacios csomag

- docs/LEGACY_PARITY_CHECKLIST.md frissitve.
- docs/LEGACY_PARITY_EVIDENCE_MATRIX.md frissitve.
- docs/LEGACY_PARITY_P1_ACTION_PLAN.md frissitve.
- docs/LEGACY_PARITY_EXEC_STATUS.md frissitve.

## 6. Mi var befejezesre (nyitott elemek)

### 6.1 UAT es uzleti bizonyitek nyitott pontok

- Foglalo keszlet-elkulonites parity teljes UAT bizonyitasa.
- Dekad riport + napzaras teljes output parity bizonyitasa.
- Riportok mezoszintu es osszegszintu parity bizonyitasa.

### 6.2 Hardver/integracios bizonyitek nyitott pontok

- NAV valos E2E igazolas (nem placeholder/mock).
- Fizikai nyomtatas/POS/scanner valos uzemi parity bizonyitek.

### 6.3 Governance es tenancy nyitott pontok

- Teljes repo companyId-szures formalis, bizonyitekolt auditja.
- CORS/security hardening checklist teljes lezaro bizonyitekkal.

## 7. Aktualis allapot rovid minositese

- Technikai stabilitas: eros (teszt es gate szinten zold).
- Kodszintu parity zaras: jelentosen javult, P1 technikai resze nagyraszt lezart.
- Uzleti/hardver parity: feltetelesen nyitott, tovabbi bizonyitek kell.

Praktikus minosites: CONDITIONAL GO

## 8. Fuggetlen, masik nezopontu teljes repo-audit (reszletes playbook)

Ez a fejezet arra keszult, hogy egy masik csapat/masik AI-agent ugyanarra a repo-ra, uj szemmel, reprodukalhato modon fusson vegig.

### 8.1 Audit alapelvek

1. Evidence-first: csak visszakeresheto bizonyitek szamit.
2. Ketfuggetlen nezet: white-box (kod+teszt) es black-box (uzleti scenariok) kulon fusson.
3. Oracle-alapu dontes: elore definialt elvart kimenet nelkul nincs PASS.
4. Reprodukcio: minden futtatast commit hash + datum + kornyezet adatokkal rogzitsetek.
5. Elkulonitett szerepkorok: fejleszto ne minositse onmaga sajat munkajat vegso auditori minositessel.

### 8.2 Audit szerepkorok

- Audit Lead: teljes menetrend, kritikus kockazatok, vegso minosites.
- Business Owner: uzleti szabalyok es parity elfogadas.
- Compliance Lead: AML, audit trail, jogosultsag, megfeleles.
- Technical Reviewer: kodminoseg, architektura, tenancy, tranzakcios pontossag.
- E2E Operator: valos futtatasi scenariok, hardver/integracio tesztek.

### 8.3 Elokeszites (D-1)

1. Rgzitsd az ellenorizendo commit hash-t es brancht.
2. Keszits kornyezet-leltart: Java, Node, npm, Docker, DB verzio.
3. Fagyaszd be a bemeneti adatcsomagot (seed + referencia tesztadat).
4. Definiald az audit scope-ot:
   - In-scope: backend, frontend-react, penztar-client, migraciok, docs parity
   - Out-of-scope: csak formalis N/A dontessel
5. Hozz letre audit mappat:
   - audit/YYYY-MM-DD/
   - logs/
   - evidence/
   - reports/

### 8.4 0. lepes - Baseline allapotrogzites

Kotelezo bizonyitek:

- git status
- git rev-parse HEAD
- git rev-list --left-right --count HEAD...origin/main
- docker compose ps
- alkalmazas health endpoint valasz

Elfogadasi kriterium:

- tiszta worktree vagy dokumentalt elteres
- egyertelmu commit azonosito
- futtathato szolgaltatasi alapallapot

### 8.5 1. lepes - Statikus minosegi gate

Futtasd kulon:

- backend: teljes tesztkor
- frontend-react: lint + build + test (ha van)
- penztar-client: test + typecheck + check:ipc

Kotelezo bizonyitek:

- parancs
- exit code
- osszegzo output

Elfogadasi kriterium:

- minden gate PASS
- ha barmi FAIL, az audit allapot automatikusan CONDITIONAL marad

### 8.6 2. lepes - Security es tenancy audit (white-box)

Vizsgalandok:

1. Controller security:
   - minden controller rendelkezik explicit PreAuthorize deklaracioval
   - intentionalis public endpoint-ek listaja dokumentalt
2. Tenancy:
   - minden company-szenzitiv query companyId szuresen megy at
   - cross-company adathozzaferesre negativ teszt fut
3. CORS/JWT/policy:
   - wildcard CORS ne maradjon production policy-ben
   - auth bypass mintak ne jelenjenek meg

Kotelezo bizonyitek:

- controller coverage riport
- tenancy grep + kodreview jegyzek
- legalabb 5 negativ API teszt eredmeny

Elfogadasi kriterium:

- 0 kritikus security finding
- tenancy bypass 0 darab

### 8.7 3. lepes - Uzleti logika audit (black-box + oracle)

Hozz letre uzleti oracle tablazatot modulonkent.

Kotelezo modulok:

1. Veteleladas/sztorno
2. AML kuszobok (napi, 90 nap, 365 nap, heti gyujtes, eves 8M)
3. Napnyitas/napzaras/dekad/havi zaras
4. Treasury osszesites (branch, branch-group, company)
5. Foglalo eletciklus
6. Arfolyam alkalmazas + ervenyessegi idozites

Minden modulra:

- Input adat
- Elvart kimenet (legacy vagy jogi szabaly alapjan)
- Teny kimenet (uj rendszerbol)
- Diff
- PASS/FAIL

Elfogadasi kriterium:

- kritikus modulokban 0 blokkolo elteres
- minden eltereshez kockazati besorolas es dontes

### 8.8 4. lepes - Szamviteli es numerikus pontossag audit

Fokusz: penzmozgasi egyenlegek, kerekites, zarokeszlet.

Ellenorzesek:

1. Napi egyenlet:
   opening + in - out +/- correction = closing
2. Tranzakcios sorok osszege = bizonylat vegosszeg
3. HUF kerekitesi szabaly kovetkezetes alkalmazasa
4. Treasury aggregaciok osszege minden szinten visszaellenorizheto
5. Storno visszaforditasi hatasa teljesen kompenzalja az eredeti tranzakciot

Minta:

- legalabb 30 kontrolleset deviatio nelkul
- legalabb 5 szandekos hiba-injekcio (rossz input), korrekt hiba-valasszal

Elfogadasi kriterium:

- nincs nevtelen penzugyi elteres
- minden elteresre gyokok es javitasi terv van

### 8.9 5. lepes - Compliance audit (jogi/mukodesi)

Ellenorizendo:

1. AML folyamat triggerelese megfelelo kuszoboknal
2. Ugyfelazonositas kotelezo pontjai tenylegesen ervenyesulnek
3. Audit trail visszakeresheto, idobelyegzett, szerepkorhoz kotott
4. Jogosultsagi szintek valoban kulonboznek (admin/iroda/penztaros)
5. Kotelezo riportok es mezok hianytalanok

Elfogadasi kriterium:

- 0 compliance-critical hiany
- jogi kotelezettseghez tartozo mezok hianya 0

### 8.10 6. lepes - Integracios es hardver audit

Ha in-scope:

1. NAV valos endpoint/adapter E2E
2. POS terminal kommunikacio
3. Nyomtatas valos eszkozon
4. Scanner inputok edge-case kezelese

Ha out-of-scope:

- formalis N/A dontes, indoklassal, owner-jovahagyassal

Elfogadasi kriterium:

- in-scope esetben minden kritikus E2E PASS
- out-of-scope esetben dokumentalt es jovahagyott N/A

### 8.11 7. lepes - Offline/szinkron es helyreallitas audit

Forgatokonyvek:

1. Kapcsolatvesztes tranzakcio kozben
2. Keseses replay
3. Duplicate event bejovetel
4. Conflict resolution ket oldali modositasnal
5. Visszaallas reconnect utan

Elfogadasi kriterium:

- adatvesztes 0
- duplikacio 0
- determinisztikus vegallapot

### 8.12 8. lepes - Legacy parity delta audit

Minden nyitott parity pontra:

- bizonyitek link
- statusz (DONE / PARTIAL / OPEN / N/A)
- uzleti hatas
- celhatarido
- felelos

Kulon figyelem:

- Foglalo keszlet-elkulonites
- Dekad output parity
- Riport mezoszintu egyezes
- Treasury osszesito parity valos adatokkal

### 8.13 9. lepes - Kockazati osztalyozas

Kotelezo skala:

- Sev-1: release blocker
- Sev-2: kritikus, de workaroundgal atmenetileg kezelheto
- Sev-3: kozepes
- Sev-4: alacsony

Minden findinghoz:

- reprodukcio
- vart/teny eredmeny
- erintett komponens
- javitasi javaslat
- tulajdonos
- hatarido

### 8.14 10. lepes - Vegso minositesi modell

Javasolt dontesi logika:

1. GO:
   - 0 Sev-1
   - 0 compliance-critical
   - minden kotelezo gate PASS
   - uzleti owner jovahagyas
2. CONDITIONAL GO:
   - nincs Sev-1, de maradt Sev-2 vagy nyitott UAT bizonyitek
   - idozitett action plan kotelezo
3. NO-GO:
   - barmely Sev-1
   - barmely jogi megfelelesi blokkolo hiany
   - tenancy/security bypass

## 9. Ellenorzesi futtatasi sorrend (konkret, napi menetrend)

### Nap 1 - Technikai alap es security

1. Baseline allapotrogzites
2. Teljes quality gate futtatas
3. Security + tenancy white-box audit
4. Elso finding lista

### Nap 2 - Uzleti es numerikus pontossag

1. Black-box uzleti scenariok oracle szerint
2. Szamviteli/egyenleg pontossagi ellenorzes
3. Compliance ellenorzes
4. Elteresek osztalyozasa

### Nap 3 - Integracio, offline, parity delta

1. Hardver/integracio vagy formalis N/A
2. Offline/szinkron stressz scenariok
3. Legacy parity delta zaras
4. GO/CONDITIONAL GO/NO-GO dontes

## 10. Konkret bizonyitekcsomag, amit az auditornak le kell adnia

Minimum atadando:

1. Audit executive summary (1-2 oldal)
2. Teljes finding register (CSV vagy MD)
3. Modulonkenti PASS/FAIL matrix
4. Security/tenancy coverage riport
5. Numerikus egyezosegi riportok
6. UAT bizonyitekcsomag (kepernyokep/log/export)
7. GO/NO-GO javaslat es indoklas

## 11. Hogyan futtasd ezt vegig Claude Code-dal (reszletes utasitas)

Az alabbi modszert hasznald, ha egy fuggetlen AI-auditot akarsz:

### 11.1 Elso prompt (keretadas)

Adj egy konkret, kotelezo strukturat:

- Cel: teljes repo fuggetlen audit, nem javitas, hanem bizonyitek-alapu minosites
- Fokusz: mukodes, uzleti logika, compliance, pontossag
- Elvart outputok:
  1. audit terv
  2. futtatott parancsok eredmenye
  3. finding register
  4. vegso minosites

### 11.2 Masodik prompt (evidence-only szabalyozas)

Kerd ki explicit:

- Minden allitashoz bizonyitekfajl es sorhivatkozas
- Feltetelezeseket kulon blokkban
- Nyitott kerdeseket kulon blokkban

### 11.3 Harmadik prompt (parity-oracle)

Add meg referenciakent:

- docs/LEGACY-FULL-AUDIT.md
- docs/LEGACY-VS-NEW-COMPARISON.md
- docs/LEGACY_PARITY_CHECKLIST.md
- docs/LEGACY_PARITY_EVIDENCE_MATRIX.md

Es kerd, hogy modulonkent diffelje:

- vart legacy viselkedes
- jelenlegi implementacio
- bizonyitek allapot

### 11.4 Negyedik prompt (GO/NO-GO dontes)

Kerd, hogy a vegso riportban kotelezo legyen:

1. Sev szerinti finding lista
2. release blocker lista
3. feltetelesen vallalhato kockazatok
4. pontos javitasi sorrend tulajdonossal es hataridovel

### 11.5 Claude Code CLI teljesen autonom futtatasi parancs

Ha azt akarod, hogy CLI-ben induljon, es onnantol ne kerdezzen, hanem vegigvigye a feladatot, hasznald a non-interactive + permission bypass mintat.

Parancs (PowerShell, minta):

```powershell
Set-Location "d:\repo\valutavalto-program"

$prompt = @"
Teljes, fuggetlen repo-auditot futtass le autonom modban.
Ne kerdezz vissza, ne kerj megerositest, ne allj meg elemzesnel.
Haladj vegig a mukodes, uzleti logika, compliance, pontossag ellenorzesen,
es a vegere add le a finding registert, PASS/FAIL matrixot es GO/NO-GO minositest.
"@

claude -p $prompt --dangerously-skip-permissions
```

Ha a helyi Claude CLI build mas kapcsoloval dolgozik, ellenorizd elotte:

```powershell
claude --help
```

Elvart mukodes:

- A `--dangerously-skip-permissions` kapcsolo miatt nem ker megerositest minden lepesnel.
- A promptban adott "Ne kerdezz vissza" utasitas miatt vegrehajtas-fokuszban marad.
- A teljes audit outputot egy futasban adja vissza (ha a prompt pontosan definiált).

## 12. Sprint utani ajanlott kovetkezo lepesek

1. Futtassatok le a fenti 3 napos fuggetlen auditot valos UAT csapattal.
2. Zartok le minden nyitott parity pontot bizonyitek-alapon, ne csak kod-alapon.
3. Keszitsetek vegso executive GO/NO-GO dokumentumot az audit output alapjan.

## 13. Zaro megjegyzes

Ez a sprint technikailag nagy elorelepes volt: a kritikus P1 kodszintu gap-ek jelentos resze bezarult, a minosegi gate-ek stabilak.
Teljes uzleti parity-nek akkor nevezheto a rendszer, ha a nyitott UAT/hardver/compliance bizonyitekok is formalisan lezarulnak.

