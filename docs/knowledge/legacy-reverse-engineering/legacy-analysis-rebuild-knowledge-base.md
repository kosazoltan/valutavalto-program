---
type: registry
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Legacy Analysis and Rebuild Knowledge Base"
load: on-demand
---

# Legacy Analysis and Rebuild Knowledge Base

> Cel: a teljes kibontott legacy anyaghoz egy olyan agent-kompatibilis tudasbazis letrehozasa, amely egyszerre tartalmaz elemzest, referenciautakat es ujraepitesi tervet.

---

## S1 TUDASBAZIS_RETEGEK

Ez a tudasbazis 4 egyutt hasznalt retegre epul:

1. **Binaris inventory**
   - `legacy-binary-functional-index.md`
   - `generated/legacy-binary-inventory-2026-04-09.csv`
   - `legacy_binary_inventory` tabla a `docs/valuta-knowledge.sqlite` adatbazisban
2. **Legacy forraselemzes**
   - `antivaluta.GPT-5.4.md`
   - `szerver-modules-index.md`
   - `szerver-core-analysis.md`
   - `RE-egyestitett-osszes-csapat-elemzes.md`
3. **Gap es parity tudas**
   - `RE-gap-analysis-legacy-vs-modern.md`
   - `szerver-gap-vs-modern.md`
   - `docs/ANTI_LEGACY_PARITY_SPEC.md`
   - `docs/legacy-analysis/README.md`
4. **Ujraepitesi terv**
   - az alabbi workstream-ek es felbontasok
   - kesobb a `agent_knowledge_segments` tablan keresztul szegmentalt agent-hozzaferes

---

## S2 RENDSZERTERKEP

| Rendszerresz | Technologia | Legacy szerep | Modern cel |
|-------------|-------------|---------------|------------|
| `VALUTA` | Delphi 7 + DLL pluginok | penztaros desktop, napi workflow, nyomtatas, AML | Electron cashier + backend API + React admin |
| `SZERVER\fejleszt` | Delphi 7 | kozponti szerver, receptor, import, riport, MNB, kontroll | Spring Boot service-ek + scheduler + reporting |
| `SZERVER\ujdll` | Delphi DLL-k | ujabb/utolag hozzairt specialis modulok | kulon backend domain service-ek |
| `ERTEKTAR\etdll` | Delphi DLL-k | ertektari / treasury folyamatok | treasury modulok, handover, bank, stock |
| `ARFOLYAM` | Delphi EXE | arfolyam szerkesztes, export, szinkron | Rate management UI + scheduled sync |
| `camera2/camera3` | Java / JavaFX / Maven | kamera rogzitok, player, center, inspecter | kulon camera alrendszer vagy szolgaltatas |
| `firebird` | Firebird | legacy adatmotor | PostgreSQL + migracios import pipeline |

---

## S3 AGENT_HASZNALATI_MODELL

### Mit olvasson az ugynok eloszor?

1. **Topologia es binaris kep**
   - `legacy-binary-functional-index.md`
2. **Cashdesk / DLL architektura**
   - `antivaluta.GPT-5.4.md`
3. **SZERVER modulok**
   - `szerver-modules-index.md`
4. **Gap elemzes es parity**
   - `RE-gap-analysis-legacy-vs-modern.md`
   - `szerver-gap-vs-modern.md`
5. **Vegrehajtasi backlog**
   - `docs/legacy-analysis/README.md`
   - `docs/DEVELOPMENT-BACKLOG-2026-04.md`

### Mire valo a SQLite tudasreteg?

Nem beagyazott embedding-alapu vector store, hanem egy **agent-orientalt keresheto tudasadatbazis**, amely:

- strukturalt inventory tablakat tarol
- dokumentum-szinten visszakeresheto
- kesobb embedding oszloppal vagy kulso vector backenddel bovitheto

Jelenlegi tablakszint:

- `felmeres_docs`
- `legacy_binary_inventory`
- `agent_knowledge_segments`
- `source_artifacts`
- `artifact_dedup_groups`
- `artifact_dedup_members`
- `artifact_ingest_runs`
- `artifact_text_extracts`
- `topics`
- `artifact_topics`
- `segment_topics`
- `knowledge_coverage`
- `knowledge_gaps`
- `ingest_checkpoints`

Az audit-kepes schema reszletes leirasa:

- `docs/knowledge/knowledge-base-architecture.md`
- `docs/knowledge/knowledge-base-rollout.md`

---

## S4 MODERNIZACIOS_WORKSTREAM_EK

### W1 Cashdesk shell es tranzakcios DLL-lanc

**Legacy forrasok**

- `Anti\VALUTA\IBVALTO\`
- `Anti\VALUTA\DLL\`
- fo kulcsmodulok: `vasarlas`, `eladas`, `storno`, `napzar`, `havizar`, `cimlet`, `bigctrl`, `terror`, `prosbe`, `proski`

**Mit kell tudnia az agentnek?**

- a fo UI shell csak orchestrator
- a tenyleges uzleti logika a DLL-ekbe van szeletelve
- a napi workflow sok kis, modal jellegu reszfolyamatbol all

**Ujraepitesi terv**

1. rekonstrualni a cashdesk use case katalogust DLL-klaszterenkent
2. minden DLL-hez modern backend service + Electron screen mappinget kesziteni
3. a nyomtatas/ESC-POS es hardware bridge kulon adapter retegbe keruljon
4. AML, supervisor es rounding szabalyokat kozponti domain service-ekbe kell emelni

### W2 SZERVER receptor, import, adatgyujtes, riport

**Legacy forrasok**

- `Anti\SZERVER\fejleszt\server\`
- `Anti\SZERVER\fejleszt\recptor\`
- `Anti\SZERVER\fejleszt\arfolyam\`
- `Anti\SZERVER\fejleszt\senddata\`

**Mit kell tudnia az agentnek?**

- a napi zaro allapotok es irodankenti daybook-logika kulcsterulet
- a `.DAT` import es a kozponti Firebird gyujtes a legacy egyik magja
- sok riport es kontroll nem a penztarban, hanem a szerveroldalon el

**Ujraepitesi terv**

1. kulon ingest pipeline a legacy fajlformatumokhoz
2. branch/daybook/allapotmodell explicit domain modelkent
3. riportok es MNB/Metro/Tesco/WU jellegu specialis gyujtesek kulon scheduled job-kent
4. audit es hibatabla-koncepcio strukturalt es visszajatszhato modon

### W3 Ertektar es treasury parity

**Legacy forrasok**

- `Anti\ERTEKTAR\etdll\`
- kapcsolodo `VALUTA` atadas-atvetel es keszlet modulok

**Mit kell tudnia az agentnek?**

- a treasury nem egyszeru admin lista, hanem sajat workflow-csalad
- banki, atadasi, keszlet- es zarasi folyamatok kulon bizonyitekot igenyelnek

**Ujraepitesi terv**

1. vault transfer, stock, bank, handover use case-ek kulon bontasa
2. receipt es material movement dokumentumok parity ellenorzese
3. treasury dashboard ne csak UI legyen, hanem allapotgep is

### W4 Arfolyam es compliance rates

**Legacy forrasok**

- `Anti\ARFOLYAM\`
- `Anti\SZERVER\fejleszt\arfolyam\`
- `getarf`, `arfreg`, `arftmk`, `mnb*`

**Mit kell tudnia az agentnek?**

- tobb helyen van rate logika: penztar, szerver, standalone szerkeszto
- MNB, napi fajlok, exportok es ellenorzesek kulon retegek

**Ujraepitesi terv**

1. egyseges rate domain model
2. source-of-truth + effective-date + branch/company scope
3. scheduler + approval workflow + parity riportok

### W5 Kamera es megfigyelo alrendszer

**Legacy forrasok**

- `Anti\camera2\camera\pom.xml`
- `Anti\camera3\old\`
- csomagolt `CameraSetup`, `ExclusivePlayer`, MariaDB runtime

**Mit kell tudnia az agentnek?**

- ez egy kulon termekcsalad
- van rogzites, center, config, inspecter, player, export
- kulon adatbazis/runtime csomagolassal jon

**Ujraepitesi terv**

1. kamera platformot kulon bounded contextkent kezelni
2. archivumformatumok, retention, export, player use case-eket leválasztani
3. backend/core + desktop/player + admin konfiguracio szetvalasztasa

### W6 Adatmodell, migracio, parity evidence

**Legacy forrasok**

- Firebird `.FDB` vilag
- forraskodbol rekonstrualt tablamezok
- parity spec-ek es gap listak

**Ujraepitesi terv**

1. legacy tabla- es rekordszintu mapping
2. minimalis import pipeline az archiv adatokhoz
3. parity evidence matrix minden kritikus workflowra
4. regression pack az AML, napzaras, cimlet, WU, nyomtatas, ertektar teruletekre

---

## S5 PRIORITASI_SORREND

| Prioritas | Targy | Miert elol? |
|----------|-------|-------------|
| P0 | `IBVALTO` + fo tranzakcios DLL-ek | ez adja a napi penztaros mukodes magjat |
| P0 | `server` + `recptor` + `arfolyam` | ezek nelkul nincs kozponti adatgyujtes es rates governance |
| P0 | `bigctrl` / AML / customer kontroll | compliance es jogszabalyi kockazat |
| P1 | `ERTEKTAR` + atadas/atvetel + stock | treasury parity es keszletbiztonsag |
| P1 | blokkok/nyomtatvanyok | bizonyiteki es jogszabalyi kotottseg |
| P2 | kamera platform | kulon bounded context, nagy technologiai elteres |
| P2 | partnerintegraciok (Metro, Tesco, MoneyGram, WU melyseg) | uzletfuggo, de sok resz specialis |

---

## S6 KOVETKEZO_TUDASBAZIS_ELEMEK

Ez a dokumentum a kezdeti agent-kompatibilis tudasbazis gerince. A kovetkezo termeszetes bovitesek:

1. DLL-szintu parity matrix (`legacy module -> modern service/page/test`)
2. SZERVER fajlformatum-es import katalogus (`.DAT`, exportok, visszakuldesek)
3. Firebird schema reconstruction index
4. Kamera bounded-context kulon tudastar
5. kritikus workflow tesztkatalogus AML/napzaras/nyomtatas/treasury szerint

---

## S7 REFERENCIA_UTAK

- `docs/knowledge/legacy-reverse-engineering/legacy-binary-functional-index.md`
- `docs/knowledge/legacy-reverse-engineering/szerver-modules-index.md`
- `docs/knowledge/legacy-reverse-engineering/szerver-core-analysis.md`
- `docs/knowledge/legacy-reverse-engineering/szerver-gap-vs-modern.md`
- `docs/knowledge/legacy-reverse-engineering/RE-egyestitett-osszes-csapat-elemzes.md`
- `antivaluta.GPT-5.4.md`
- `docs/ANTI_LEGACY_PARITY_SPEC.md`
- `docs/legacy-analysis/README.md`
