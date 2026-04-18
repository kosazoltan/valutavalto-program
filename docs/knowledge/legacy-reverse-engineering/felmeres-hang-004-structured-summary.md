---
type: analysis
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Felmérés Hang 004 — strukturált kézi kivonat"
load: on-demand
---

# Felmérés Hang 004 — Strukturált Kézi Kivonat

> Cél: a `Felmérés` Hang 004 anyagából kinyerhető treasury, készlet, zárás és foglaló tudás strukturált rögzítése.
> Primer transcript: `docs/knowledge/generated/asr-text/Hang_004_sd-a0fd0433d3.txt`
> Duplikált forrás: `docs/knowledge/generated/asr-text/Hang_004_sd-kosa-duplicate.txt`
> Megjegyzés: az ASR zajos, de a fő folyamatok jól felismerhetők; ez a hang jelentős operációs tudást tartalmaz.

---

## S1 FORRAS_ES_BIZONYITEK

### Forrásartefaktok

- `Felmérés/Valuta/Cégcsoport felmérése/.../Hangfelvételek/Hang 004_sd.m4a`
- `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/.../Hangfelvételek/Hang 004_sd.m4a`
- `docs/knowledge/generated/asr-text/Hang_004_sd-a0fd0433d3.txt`
- `docs/valuta-knowledge.sqlite` → `artifact_text_extracts.extract_type = asr-transcript`

### Fő témacsoportok

1. `Készletláthatóság és pénztári döntéstámogatás`
2. `Foglaló és megrendelés alacsony készletű valutákra`
3. `Forgalomösszesítő / időszaki nyomtatás`
4. `Címletezés és zárás előfeltétele`
5. `Napzárás / havizárás / készletborulás`
6. `Értéktáros / szerveres jelentés és beküldés`

---

## S2 FOLYAMAT

| Flow ID | Megfigyelt legacy folyamat | Bizonyosság | Tudástári értelmezés |
|---------|----------------------------|-------------|----------------------|
| `F004-STOCK-01` | A pénztáros külön nézetből látja, mely valutából mennyi készlet van | high | Van döntéstámogató készlet-összesítő nézet |
| `F004-STOCK-02` | Nagy összegű vagy ritka valutaigénynél a készlet alapján kell dönteni | high | A tranzakció és a treasury/készlet nem választható szét |
| `F004-RESERVE-01` | Kevés készletű vagy nem tartott valutáknál foglaló/megrendelés indul | high | A foglaló az ellátási lánc része, nem csak pénzügyi előleg |
| `F004-REPORT-01` | Forgalomösszesítő és időszaki nyomtatás van napi, tetszőleges napos vagy zárási célra | high | A riport nem csak admin célú, hanem napi operációt támogat |
| `F004-DENO-01` | Címletezés nélkül bizonyos zárási folyamat nem engedhető végig | high | A denomination check blokkoló workflow-előfeltétel |
| `F004-CLOSE-01` | Napzárás és havizárás erősen összefügg a készlet konzisztenciájával | high | A zárási állapotgép kritikus és sérülékeny terület |
| `F004-CLOSE-02` | Elmaradt havizárás készletborulást vagy állapotromlást okozhat | high | Hónapváltásnál szigorú állapotőrzés kell |
| `F004-TREASURY-01` | Az értéktáros szerveres nézetből látja az adott pénztár forint- és valutaállományát | high | Van központi treasury dashboard-jellegű funkció |
| `F004-TREASURY-02` | A pénztár beküldheti, milyen valutát vagy egyéb erőforrást kér másnapra | high | Készletigény / replenishment folyamat létezik |
| `F004-NAV-01` | Bizonyos nagy tételeknél a pénztáros hibája NAV vagy kezelési költség oldalon is látható | medium | Operatív eltérések compliance és treasury oldalon is megjelennek |

---

## S3 SZABALY

| Rule ID | Megfigyelt szabály | Bizonyosság | Megjegyzés |
|---------|--------------------|-------------|------------|
| `R-F004-RESERVE-LOWSTOCK` | Alacsony készletű vagy nem tartott valutáknál foglaló szükséges lehet | high | Szorosan kapcsolódik a beszerzéshez és készletelosztáshoz |
| `R-F004-DENO-BLOCK` | Ha a címletezés nincs rendben, a zárás nem mehet végig | high | Blokkoló validáció |
| `R-F004-HOZARAS-REQUIRED` | A havizárás elmulasztása készlet- és állapotproblémát okoz | high | Hónapváltásnál kötelező kontroll |
| `R-F004-REPORT-SCOPE` | A forgalomösszesítő riport dátumtartományhoz és zárási célhoz kötött | medium | Riportok nem teljesen szabadon kombinálhatók |
| `R-F004-HUF-FEE` | A kezelési költség forint oldalon külön jelenik meg | high | Kapcsolódik a korábbi NAV/kezelési költség megfigyelésekhez |
| `R-F004-REQUEST-NEXTDAY` | A pénztár másnapi valutakérést vagy anyagigényt küldhet | high | Van explicit replenishment kérés |

---

## S4 UI

### Megfigyelt vagy erősen valószínűsíthető UI elemek

- készletösszesítő képernyő
- forgalomösszesítő nyomtatási nézet
- foglaló / megrendelés kezdeményezése alacsony készlet esetén
- napzárás és havizárás végrehajtási képernyő
- címletezés-beállítás és címletezés-ellenőrzés
- értéktárosi összesítő nézet
- másnapi valuta- vagy eszközigény beküldési felület

### UI parity következmény

Az új felületben külön kezelendő:

1. `cashdesk stock insight`
2. `reservation from low stock`
3. `denomination validation`
4. `daily/monthly closing state`
5. `treasury request / replenishment`

---

## S5 ADAT

| Adatkör | Mit sugall a hanganyag | Modern modell-következmény |
|---------|------------------------|----------------------------|
| `branch_stock_snapshot` | a pénztár szintű készletet külön nézet mutatja | branch/currency stock snapshot |
| `closing_denominations` | a záráshoz címletezés kell | denomination state a closinghoz kötve |
| `period_turnover_report` | időszaki forgalomösszesítő nyomtatható | riportparaméterek, date-range, branch scope |
| `monthly_closing_state` | a havizárás külön státusz és előfeltétel | monthly close entity/state |
| `treasury_request` | másnapi valutakérés vagy egyéb igény beküldhető | replenishment request aggregate |
| `treasury_visibility` | az értéktáros központilag látja a készleteket | treasury dashboard read model |

### Valószínű legacy támaszpontok

- `ERTEKTAR` és készletmodulok
- `FOGLALO.DAT`
- forgalomösszesítő és zárási riportok
- szerveres összesítő / igénybeküldő logika

---

## S6 GAP

| Gap ID | Nyitott kérdés | Miért fontos |
|--------|----------------|--------------|
| `G-F004-01` | Mi a pontos kapcsolat a foglaló és a készletlekötés között? | treasury és reservation parity |
| `G-F004-02` | Milyen pontos szabályok blokkolják a zárást címletezési hiba esetén? | closing correctness |
| `G-F004-03` | A havizárás milyen technikai úton borítja a készletet, ha elmarad? | migráció és regresszióvédelem |
| `G-F004-04` | A másnapi valutakérés milyen státuszokon megy át az értéktár felé? | replenishment workflow |
| `G-F004-05` | Mely riportok szolgálnak csak operációs célra és melyek auditbizonyítékok? | riport-újratervezés |

### Következő bizonyítékforrások

1. `firebird-table-to-modern-entity-matrix.md`
2. `dat-format-sheets.md`
3. `szerver-dat-import-knowledge-base.md`
4. `legacy-dll-parity-matrix.md`
5. treasury és closing kapcsolódó screenshotok a `Felmérés` anyagból

---

## S7 MODERN_REBUILD_IMPLICATION

1. A modern készletkezeléshez külön `stock insight` és `treasury request` képesség kell, nem elég a tranzakciós nézet.
2. A `reservation`, `stock reservation` és `replenishment` eseményeket ugyanabba a készletdomainbe kell bekötni.
3. A `denomination` nem opcionális mellékadat, hanem a zárási állapotgép része.
4. A napzárás és havizárás külön, mégis egymásra épülő workflow legyen erős validációval.
5. Az értéktárosi nézetet read modelként érdemes külön felépíteni, mert több pénztár összesítését és következő napi igényeit kezeli.

### Ajánlott backlog-elemek

- `Monthly closing parity guardrails`
- `Denomination blocking validation parity`
- `Treasury replenishment request model`
- `Reservation-to-stock linkage parity`
- `Closing report scope parity`

---

## S8 ROVID_AGENT_UTMUTATO

Ha egy ügynök a `készlet`, `zárás`, `értéktár` vagy `foglaló-készlet kapcsolat` témát vizsgálja, ezt a dokumentumot együtt érdemes olvasni az alábbiakkal:

- `firebird-table-to-modern-entity-matrix.md`
- `legacy-dll-parity-matrix.md`
- `dat-format-sheets.md`
- `legacy-analysis-rebuild-knowledge-base.md`
- `szerver-business-logic.md`
