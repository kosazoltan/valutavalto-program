---
type: analysis
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Felmérés Hang 002 — strukturált kézi kivonat"
load: on-demand
---

# Felmérés Hang 002 — Strukturált Kézi Kivonat

> Cél: a `Felmérés` hanganyagából olyan tudástári kivonat készítése, amely az ASR nyers szövegét üzleti és modernizációs szempontból használható szerkezetbe rendezi.
> Primer transcript: `docs/knowledge/generated/asr-text/Hang_002_sd-primary.txt`
> Duplikált forrás: `docs/knowledge/generated/asr-text/Hang_002_sd-kosa-duplicate.txt`
> Megjegyzés: a magyar ASR zajos, ezért ez a dokumentum bizonyíték-alapú értelmezés, nem szó szerinti jegyzőkönyv.

---

## S1 FORRAS_ES_BIZONYITEK

### Forrásartefaktok

- `Felmérés/Valuta/Cégcsoport felmérése/.../Hangfelvételek/Hang 002_sd.m4a`
- `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/.../Hangfelvételek/Hang 002_sd.m4a`
- `docs/knowledge/generated/asr-text/Hang_002_sd-primary.txt`
- `docs/valuta-knowledge.sqlite` → `artifact_text_extracts.extract_type = asr-transcript`

### Bizonyossági szintek

- `high`: ugyanaz a téma több külön részletben is visszatér
- `medium`: a téma jól felismerhető, de a pontos küszöb vagy szóhasználat zajos
- `low`: csak részleges ASR-bizonyíték van, ezért csak gapként szabad kezelni

### Fő témacsoportok

1. `Foglaló / valuta-megrendelés`
2. `NAV / bizonylat / kezelési költség`
3. `Ügyfél-azonosítás / AML / szankciós jellegű ellenőrzés`
4. `Készlet és értéktár-láthatóság`
5. `Szerveres mentés / jelentések / kamera-ellenőrzési kapcsolat`

---

## S2 FOLYAMAT

| Flow ID | Megfigyelt legacy folyamat | Bizonyosság | Tudástári értelmezés |
|---------|----------------------------|-------------|----------------------|
| `F002-RESERVE-01` | Az ügyfél bizonyos valutákra előre rendel, ehhez foglaló kapcsolódik | high | A rendszer külön kezeli a normál váltást és a foglalós/megrendeléses ügyletet |
| `F002-RESERVE-02` | A foglaló összege a fizetendő összeghez vagy százalékhoz kapcsolódik, és részben automatizált | high | Van beégetett vagy paraméterezett foglaló-számítási logika |
| `F002-RESERVE-03` | A foglaló felvétele után az ügylet a készletre és a későbbi átadásra is hat | high | A foglaló nem csak pénzügyi előleg, hanem készletlekötési esemény is |
| `F002-RESERVE-04` | Meghiúsult ügyletnél külön szabály van arra, mikor marad bent a foglaló | medium | A rendszernek kell kezelnie a visszajáró és bent maradó foglaló eseteket |
| `F002-HANDOVER-01` | Átvételnél bizonylat és adott esetben meghatalmazás szükséges | high | A foglalós ügylet lezárása jogosultsági és dokumentum-ellenőrzési pont |
| `F002-NAV-01` | A valutaváltás és a kezelési költség NAV/bizonylat oldalon külön logikát követ | high | A rendszerben a díj- és bizonylatkezelés nem olvasztható össze a fő váltási logikával |
| `F002-AML-01` | Bizonyos tranzakcióknál azonosítás kötelező, a gép nem enged tovább nélküle | high | A tranzakciós UI és a backend AML állapotgép szorosan össze van kötve |
| `F002-AML-02` | Teljes azonosítás és egyszerűbb azonosítás közti különbség látszik | medium | Többszintű KYC/AML döntési fa van a folyamatban |
| `F002-SERVER-01` | A rendszer szerverre ment és jelentésekből visszakereshető | high | Kell központi audit- és riporttárolás |
| `F002-CAMERA-01` | Kameraellenőrzés vagy kamera-felvétel említése összekapcsolódik utólagos ellenőrzéssel | medium | Az operatív ellenőrzésben a kamera nem különálló modul, hanem bizonyítási csatorna |

---

## S3 SZABALY

| Rule ID | Megfigyelt szabály | Bizonyosság | Megjegyzés |
|---------|--------------------|-------------|------------|
| `R-F002-FOGLALO-PERCENT` | A foglaló összege százalékos logikával képződik | high | A transcript alapján automatizált százalékszámítás látszik, de a pontos százalék paraméterként kezelendő |
| `R-F002-FOGLALO-FORFEIT` | Ügyfélhibás meghiúsulásnál a foglaló bent maradhat | high | Ezt explicit üzleti szabályként kell modellezni |
| `R-F002-FOGLALO-DOC` | A foglaló felvételéhez és kiadásához bizonylatbizonyíték tartozik | high | Dokumentum- és jogosultság-ellenőrzéssel együtt értelmezendő |
| `R-F002-POWER-OF-ATTORNEY` | Nem azonos személy átvételekor meghatalmazás kell | high | A modern rendszerben külön átvevő/jogcím mezők szükségesek |
| `R-F002-NAV-SPLIT` | A kezelési költség NAV/bizonylat oldalon külön kezelendő a váltástól | high | Díj, adólogika és fő tranzakció külön eseményként kezelendő |
| `R-F002-ID-BLOCK` | Azonosítás nélkül a rendszer bizonyos esetekben nem enged továbblépni | high | Frontend guard + backend enforcement kell |
| `R-F002-FULL-ID` | Van teljes azonosítási ág, nem csak minimális ügyféladat-rögzítés | medium | A pontos thresholdokat más forrásból kell megerősíteni |
| `R-F002-SANCTION-LIST` | Szankciós vagy tiltó lista jellegű ellenőrzés megjelenik | medium | Össze kell vetni az `aml-bigctrl-rule-parity.md` tartalmával |
| `R-F002-REPORTABLE-EVENT` | Bizonyos eseményekről külön jelentés készül vagy jelenthető | medium | Audit/reporting domainben külön eseménytípusokat igényel |

### Mit nem szabad még kemény szabályként állítani?

- a pontos AML küszöbértékeket csak ebből a hangból
- a foglaló pontos százalékát hardcoded szabályként
- az `1000 EUR`, `3000`, `50 000` jellegű számokat végleges compliance-thresholdként

Ezeket csak más legacy forrásokkal, AML parity anyagokkal vagy kód/DB bizonyítékkal együtt szabad véglegesíteni.

---

## S4 UI

### Megfigyelt vagy erősen valószínűsíthető UI elemek

- foglaló felvételi képernyő vagy modal
- megrendelt valuta / kívánt dátum / határidő mező
- foglaló összeg vagy százalék mező automatikus kitöltéssel
- ügyfélazonosítási állapot a tranzakció közben
- bizonylat- és NAV-sorszám láthatóság
- készlet- és értéktárinformáció megjelenítése
- olyan állapot, ahol a rendszer jelzi, hogy azonosítás nélkül nem lehet továbbmenni
- külön figyelmeztetés meghatalmazásos átvételre

### UI parity következmény

Az új felület nem lehet csak egyszerű `buy/sell` űrlap. Kell külön:

1. `reservation / foglaló` workflow
2. `identity required` állapotjelzés
3. `document evidence` blokk
4. `inventory visibility` nézet
5. `supervisor / exception` kezelési pont

---

## S5 ADAT

### Új vagy megerősített domain-adatok

| Adatkör | Mit sugall a hanganyag | Modern modell-következmény |
|---------|------------------------|----------------------------|
| `reservation` | külön foglalós ügyletcsalád van | `Reservation` vagy `ReservedTrade` aggregate |
| `reservation_deposit` | a foglaló összege és szabálya külön adat | foglaló összeg, deviza, HUF-érték, számítási mód |
| `reservation_deadline` | az ügylet határidőhöz kötött | lejárat és státuszkezelés kell |
| `pickup_authority` | nem mindig ugyanaz veszi át, mint aki rendelte | átvevő személy, meghatalmazás, ellenőrzési státusz |
| `aml_identification_state` | az azonosítás szintje tranzakcióközben változik | explicit AML/KYC state a tranzakcióban |
| `report_event` | jelentési események vannak | audit event / compliance event tárolás |
| `inventory_projection` | foglaló és készlet összefügg | készletlekötés vagy várható készletmozgás modell kell |
| `document_evidence` | bizonylat, NAV, meghatalmazás összekapcsolódik | dokumentum- és evidence-referencia kell |

### Valószínű legacy támaszpontok

- `FOGLALO.DAT` család
- bizonylat/NAV kapcsolódó modulok
- AML/BIGCTRL/TERROR jellegű logika
- készlet / értéktár / szerveres jelentés modulok

---

## S6 GAP

| Gap ID | Nyitott kérdés | Miért fontos |
|--------|----------------|--------------|
| `G-F002-01` | Mi a foglaló pontos számítási szabálya: fix %, paraméter, vagy devizánként eltérő? | pénzügyi és jogi parity |
| `G-F002-02` | Milyen eseményeknél marad bent a foglaló és mikor jár vissza? | ügyféljogi és készletelszámolási hatás |
| `G-F002-03` | Mi a pontos NAV/bizonylat elágazás a kezelési költségre? | számlázási és adózási pontosság |
| `G-F002-04` | Mi a teljes azonosítás és egyszerű azonosítás pontos threshold-rendszere? | AML megfelelőség |
| `G-F002-05` | A szankciós lista és blacklist ellenőrzés hogyan kapcsolódik ehhez a folyamathoz? | compliance és blokkoló szabályok |
| `G-F002-06` | A kameraellenőrzés csak utólagos audit, vagy folyamatközi operációs bizonyíték is? | kamera bounded context és audit kapcsolat |
| `G-F002-07` | A foglaló milyen konkrét adattárolóban él a legacyben: DAT, DB, vagy vegyesen? | import és migrációs terv |

### Következő bizonyítékforrások a gap-ekhez

1. `dat-format-sheets.md`
2. `szerver-dat-import-knowledge-base.md`
3. `aml-bigctrl-rule-parity.md`
4. `firebird-table-to-modern-entity-matrix.md`
5. `Felmérés` dokumentumok és screenshotok a foglaló/NAV folyamatról

---

## S7 MODERN_REBUILD_IMPLICATION

### Fő következmények

1. A `foglaló` nem lehet mellékfunkció, külön bounded context vagy legalább külön aggregate kell neki.
2. A `reservation` folyamatnak készletre ható, auditálható és dokumentumhoz kötött eseményláncként kell működnie.
3. Az AML-ellenőrzést nem elég backendben futtatni, a frontendnek is explicit állapotokat kell mutatnia: `azonosítás kell`, `teljes azonosítás kell`, `blokkolt`.
4. A NAV/bizonylat logika miatt a díjak, adózási címkék és bizonylattípusok külön domain réteget igényelnek.
5. A szerveres jelentés és kameraellenőrzés miatt a modern rendszerben az audit trailnek tranzakció-, dokumentum- és eseményszinten is visszakövethetőnek kell lennie.
6. A foglaló átvételi ág miatt a jogosultsági modellt ki kell terjeszteni `megrendelő`, `átvevő`, `meghatalmazott`, `pénztáros`, `supervisor` szerepkörökre vagy állapotokra.

### Ajánlott backlog-elemek

- `Reservation deposit rule parity`
- `Reservation pickup authorization flow`
- `Handling fee vs NAV receipt split parity`
- `Reservation inventory reservation model`
- `Manual domain extraction for Hang 004`
- `Cross-check Hang 002 claims against FOGLALO / AML / NAV artifacts`

---

## S8 ROVID_AGENT_UTMUTATO

Ha egy ügynök a `foglaló` vagy `azonosítás` témát vizsgálja, ezt a dokumentumot együtt érdemes olvasni az alábbiakkal:

- `aml-bigctrl-rule-parity.md`
- `dat-format-sheets.md`
- `szerver-dat-import-knowledge-base.md`
- `firebird-table-to-modern-entity-matrix.md`
- `legacy-analysis-rebuild-knowledge-base.md`
