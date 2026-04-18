---
type: analysis
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Felmérés Hang 003 — strukturált kézi kivonat"
load: on-demand
---

# Felmérés Hang 003 — Strukturált Kézi Kivonat

> Cél: a `Felmérés` Hang 003 anyagából kinyerhető üzleti és technikai tudás strukturált rögzítése.
> Primer transcript: `docs/knowledge/generated/asr-text/Hang_003_sd-aa6901b1ee.txt`
> Duplikált forrás: `docs/knowledge/generated/asr-text/Hang_003_sd-0d407b5ccd.txt`
> Megjegyzés: ez a hanganyag erősen zajos és részben hibás kódolású ASR-t eredményezett, ezért a dokumentum főként alacsony-közepes bizonyosságú, gap-orientált kivonat.

---

## S1 FORRAS_ES_BIZONYITEK

### Forrásartefaktok

- `Felmérés/Valuta/Cégcsoport felmérése/.../Hangfelvételek/Hang 003_sd.m4a`
- `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/.../Hangfelvételek/Hang 003_sd.m4a`
- `docs/knowledge/generated/asr-text/Hang_003_sd-aa6901b1ee.txt`
- `docs/valuta-knowledge.sqlite` → `artifact_text_extracts.extract_type = asr-transcript`

### Bizonyossági szintek

- `high`: csak kevés ilyen állítás van ebben a hangban
- `medium`: a téma felismerhető, de a pontos részletszabály zajos
- `low`: a téma látszik, de további forrás kell a megerősítéshez

### Fő témacsoportok

1. `Nagy összegű ügylet és forrásigazolás`
2. `Banki dokumentum elfogadhatósága`
3. `Árfolyam-kezelés internet nélkül`
4. `Supervisor-jelszavas beavatkozás`
5. `Nyomtatás és árfolyamváltozás nyoma`

---

## S2 FOLYAMAT

| Flow ID | Megfigyelt legacy folyamat | Bizonyosság | Tudástári értelmezés |
|---------|----------------------------|-------------|----------------------|
| `F003-SOF-01` | Nagy összegű ügyletnél a pénz eredetét vagy banki forrását igazolni kell | medium | A source-of-funds ellenőrzés operatív ügyintézéssel és dokumentumvizsgálattal történik |
| `F003-SOF-02` | Régi banki bizonylat elfogadhatósága kérdéses | medium | A dokumentumok érvényességére vagy frissességére külön döntési szabály van |
| `F003-SOF-03` | Telefonos vagy külső egyeztetés történik, ha a dokumentum megítélése bizonytalan | low | A folyamat nem teljesen automatizált, hanem operátori döntést és eszkalációt is tartalmaz |
| `F003-RATE-01` | Árfolyamokat normál esetben központi forrásból kapnak | medium | Van szerveres rate source-of-truth |
| `F003-RATE-02` | Ha nincs internet vagy kiesés van, kézi árfolyam-bevitel vagy override lehetséges | high | A rendszer támogat vészüzemi, manuális rate-kezelést |
| `F003-RATE-03` | Kézi beavatkozás supervisor-jelszóval vagy külön jogosultsággal jár | medium | A rate override érzékeny műveletként auditálandó |
| `F003-RATE-04` | Árfolyamváltozás után nyomtatás vagy papírnyom szükséges | medium | A rate governance nem pusztán adatfrissítés, hanem compliance-nyom is kell |

---

## S3 SZABALY

| Rule ID | Megfigyelt szabály | Bizonyosság | Megjegyzés |
|---------|--------------------|-------------|------------|
| `R-F003-SOF-DOC` | Nagy összegű ügyletnél banki vagy egyéb eredetigazolás szükséges | medium | A `50 000 EUR` példa erős jel, de a pontos küszöb nem ebből a hangból véglegesíthető |
| `R-F003-SOF-FRESHNESS` | A régi dokumentum nem biztos, hogy elfogadható | medium | A dokumentum frissessége döntési feltétel lehet |
| `R-F003-RATE-OVERRIDE` | Árfolyam kézi módosítása csak kontrollált módon történhet | high | Jogosultság és audit kell hozzá |
| `R-F003-RATE-PRINT` | Árfolyamváltozásnál nyomtatási vagy papír alapú nyom szükséges | medium | A rate change audit trail része lehet |
| `R-F003-OFFLINE-FALLBACK` | Internetkimaradás esetén is kell működő árfolyamkezelési út | high | Ez modernben explicit offline/contingency use case |

### Mit nem szabad még kemény szabályként állítani?

- a forrásigazolás pontos elfogadási időtartamát
- a nagy összegű ügylet konkrét thresholdját
- azt, hogy a rate override minden csatornán pontosan ugyanígy működik

---

## S4 UI

### Megfigyelt vagy erősen valószínűsíthető UI elemek

- forrásigazolási vagy dokumentumellenőrzési döntési pont
- árfolyam-beállító vagy árfolyam-override képernyő
- supervisor-jelszó kérő dialógus
- nyomtatási / bizonylati visszaigazolás rate változás után
- állapotjelzés internet- vagy szerverelérési hiba esetére

### UI parity következmény

Az új rendszerben kell külön:

1. `source-of-funds review` állapot
2. `rate override` vészági felület
3. `supervisor authorization` lépés
4. `rate change evidence` nyomtatási vagy audit nézet

---

## S5 ADAT

| Adatkör | Mit sugall a hanganyag | Modern modell-következmény |
|---------|------------------------|----------------------------|
| `source_of_funds_document` | banki vagy nyilatkozati dokumentum szerepe van | dokumentum típusa, kelte, ellenőrzési státusz |
| `document_validity` | a dokumentum frissessége számít | érvényességi szabály vagy review flag |
| `rate_override` | kézi árfolyam megadható | override ok, jóváhagyó, időpont, előző/új érték |
| `rate_source_state` | szerveres és kézi rate forrás is létezik | source-of-truth + fallback state |
| `print_evidence` | rate változást nyomtatott nyom kíséri | audit dokumentum vagy print event |

### Valószínű legacy támaszpontok

- `ARFOLYAM` modulok
- rate editor / szerveres rate sync
- AML és source-of-funds dokumentumlogika
- nyomtatási és audit modulok

---

## S6 GAP

| Gap ID | Nyitott kérdés | Miért fontos |
|--------|----------------|--------------|
| `G-F003-01` | Mi a forrásigazolás pontos küszöbe és elfogadható dokumentumlistája? | compliance és operációs pontosság |
| `G-F003-02` | Milyen időkorlát után számít túl réginek a banki bizonylat? | AML/source-of-funds parity |
| `G-F003-03` | Pontosan mely szereplő hagyhat jóvá kézi árfolyamot? | jogosultsági modell |
| `G-F003-04` | Milyen árfolyamváltozásnál kötelező a nyomtatás vagy papír alapú nyom? | audit és rate governance |
| `G-F003-05` | Az offline rate út hogyan kapcsolódik a modern multi-tenant működéshez? | branch scope és adatkonzisztencia |

### Következő bizonyítékforrások

1. `firebird-schema-reconstruction-index.md`
2. `aml-bigctrl-rule-parity.md`
3. `legacy-analysis-rebuild-knowledge-base.md`
4. `ARFOLYAM` legacy források
5. rate- és nyomtatáskapcsolódó `Felmérés` dokumentumok

---

## S7 MODERN_REBUILD_IMPLICATION

1. A modern rendszerben kell explicit `source-of-funds review` workflow a magas kockázatú ügyletekhez.
2. A rate domainnek támogatnia kell a `primary source + offline fallback + supervisor override` modellt.
3. A kézi árfolyam-beavatkozásokat külön audit eseményként kell tárolni.
4. A dokumentum-elfogadási logika nem maradhat informális operátori tudás, hanem szabálymotorba vagy ellenőrzési checklistbe kell kerüljön.
5. A nyomtatási bizonyítékot a modern audit trailben digitális eseményként is rögzíteni kell.

### Ajánlott backlog-elemek

- `Source-of-funds document policy parity`
- `Rate override authorization flow`
- `Offline rate fallback design`
- `Rate change print evidence parity`

---

## S8 ROVID_AGENT_UTMUTATO

Ha egy ügynök a `forrásigazolás`, `offline árfolyam` vagy `supervisor rate override` témát vizsgálja, ezt a dokumentumot együtt érdemes olvasni az alábbiakkal:

- `aml-bigctrl-rule-parity.md`
- `legacy-analysis-rebuild-knowledge-base.md`
- `firebird-schema-reconstruction-index.md`
- `szerver-business-logic.md`
