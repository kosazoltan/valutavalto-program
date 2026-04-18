---
type: analysis
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Felmérés Hang 005 — strukturált kézi kivonat"
load: on-demand
---

# Felmérés Hang 005 — Strukturált Kézi Kivonat

> Cél: a `Felmérés` Hang 005 anyagából kinyerhető technikai, integrációs és környezeti tudás strukturált rögzítése.
> Primer transcript: `docs/knowledge/generated/asr-text/Hang_005_sd-568ae5c985.txt`
> Duplikált forrás: `docs/knowledge/generated/asr-text/Hang_005_sd-5b8ce36059.txt`
> Megjegyzés: ez a hang kevésbé szabálygazdag, inkább rendszerkörnyezeti és migrációs szempontból értékes.

---

## S1 FORRAS_ES_BIZONYITEK

### Forrásartefaktok

- `Felmérés/Valuta/Cégcsoport felmérése/.../Hangfelvételek/Hang 005_sd.m4a`
- `Felmérés/Valuta/Kósa Szervezés/Cégcsoport felmérése/.../Hangfelvételek/Hang 005_sd.m4a`
- `docs/knowledge/generated/asr-text/Hang_005_sd-568ae5c985.txt`
- `docs/valuta-knowledge.sqlite` → `artifact_text_extracts.extract_type = asr-transcript`

### Fő témacsoportok

1. `Több program együttélése`
2. `Kamera program és kapcsolódó forrás`
3. `Jelenlegi rendszerhez való csatlakozás elvárása`
4. `Új pénztár nyitásának függőségei`
5. `Készlet- és havi zárás környezeti kockázatai`

---

## S2 FOLYAMAT

| Flow ID | Megfigyelt legacy folyamat | Bizonyosság | Tudástári értelmezés |
|---------|----------------------------|-------------|----------------------|
| `F005-ENV-01` | Több külön program együtt szolgálja ki a napi működést | high | A legacy rendszer ökoszisztéma, nem egyetlen monolit UI |
| `F005-ENV-02` | Van szerver, ellenőrző program és külön kamera program is | high | Több bounded context és sidecar alkalmazás létezik |
| `F005-MIG-01` | Elvárás, hogy az új rendszer a meglévő működéshez tudjon csatlakozni | high | A modernizáció nem greenfield, hanem folyamatfolytonossági projekt |
| `F005-MIG-02` | Új pénztár nyitása speciális technikai és üzleti kockázat | medium | A provisioning / onboarding külön use case |
| `F005-CAM-01` | A kamera program külön említett komponens, forrással vagy külön felelőssel | high | Kamera alrendszer külön migrációs sávot igényel |
| `F005-STOCK-01` | Készlet- és havizárási hibák közvetlen működési zavarokat okozhatnak | medium | A zárási állapotok technikai stabilitása kritikus |
| `F005-COEX-01` | Régi és új komponensek átmeneti együttélése vagy csatlakozása szükséges lehet | medium | Cutover helyett fokozatos integráció életszerű |

---

## S3 SZABALY

| Rule ID | Megfigyelt szabály | Bizonyosság | Megjegyzés |
|---------|--------------------|-------------|------------|
| `R-F005-COMPAT` | Az új rendszernek meg kell őriznie a már működő folyamatképességeket | high | Erős backward-compatibility elvárás |
| `R-F005-CAMERA-SEPARATE` | A kamera nem sima mellékfunkció, hanem külön komponens | high | Saját integrációs és üzemeltetési igény |
| `R-F005-NEW-BRANCH-RISK` | Új pénztár/iroda nyitásánál a rendszerhiány különösen fájdalmas | medium | Provisioning és cutover folyamat kulcsfontosságú |
| `R-F005-INCREMENTAL` | A migrációt a meglévő ökoszisztéma figyelembevételével kell végezni | medium | Big bang átállás kockázatos |

---

## S4 UI

### Megfigyelt vagy erősen valószínűsíthető UI elemek

- külön valutás program
- külön ellenőrző/riportáló program
- külön kamera program
- új pénztár indulásához szükséges konfigurációs vagy törzsadat-beállító felületek
- havi/készlet állapotokat visszajelző operációs nézetek

### UI parity következmény

Az új rendszerben érdemes különválasztani:

1. `cashdesk operational UI`
2. `admin / control / reporting UI`
3. `camera configuration and playback UI`
4. `branch/workstation provisioning UI`

---

## S5 ADAT

| Adatkör | Mit sugall a hanganyag | Modern modell-következmény |
|---------|------------------------|----------------------------|
| `system_components` | több alkalmazásból áll a működés | explicit system map / integration map |
| `camera_component` | kamera külön kezelendő | camera subsystem entity/config model |
| `branch_provisioning` | új pénztár nyitása konfiguráció-érzékeny | provisioning workflow és setup state |
| `integration_dependency` | új rendszernek meglévő folyamatokhoz kell igazodnia | migration dependency registry |
| `operational_issue_log` | készlet- vagy zárási hibák működési incidensekhez vezetnek | incident/audit és readiness check modell |

### Valószínű legacy támaszpontok

- `camera-subsystem-knowledge-base.md`
- `szerver-business-logic.md`
- workstation / branch setup logika
- legacy packaging és sidecar utility-k

---

## S6 GAP

| Gap ID | Nyitott kérdés | Miért fontos |
|--------|----------------|--------------|
| `G-F005-01` | Pontosan mely programok képezik a napi működés minimális készletét? | migrációs scope és dependency map |
| `G-F005-02` | A kamera milyen adatokat vagy eseményeket oszt meg a valutás folyamattal? | bounded context határok |
| `G-F005-03` | Új pénztár nyitásához milyen konfigurációk, törzsadatok és jogosultságok kellenek? | onboarding és rollout |
| `G-F005-04` | Mely régi komponensek maradhatnak átmenetileg és melyeket kell első körben lecserélni? | cutover stratégia |
| `G-F005-05` | Az ellenőrző program milyen riportokat és validációkat fed le? | admin/control parity |

### Következő bizonyítékforrások

1. `camera-subsystem-knowledge-base.md`
2. `camera-endpoint-test-gap-list.md`
3. `legacy-analysis-rebuild-knowledge-base.md`
4. branch/workstation kapcsolódó `Felmérés` dokumentumok
5. `Anti` oldal utility és setup komponensei

---

## S7 MODERN_REBUILD_IMPLICATION

1. A modern rendszer tervezésénél külön kell választani az `operational cashdesk`, `control/reporting` és `camera` kontextusokat.
2. A pénztárnyitás és új iroda/workstation bevezetés külön rollout-flow legyen, nem ad hoc konfigurációs lista.
3. Az új megoldásnak átmeneti integrációs réteget kell biztosítania a legacy környezethez.
4. A kamera alrendszert külön bounded contextként kell kezelni, saját API-val, konfigurációval és tesztstratégiával.
5. A migrációs tervnek dependency-map alapú sorrendet kell követnie, különben az új pénztárnyitás és napi működés sérülékeny marad.

### Ajánlott backlog-elemek

- `Branch/workstation provisioning flow parity`
- `Legacy sidecar dependency inventory`
- `Camera integration boundary definition`
- `Incremental cutover plan for cashier environment`
- `Control/reporting app parity mapping`

---

## S8 ROVID_AGENT_UTMUTATO

Ha egy ügynök a `kamera`, `integrációs függőségek`, `új pénztár nyitás` vagy `legacy ökoszisztéma` témát vizsgálja, ezt a dokumentumot együtt érdemes olvasni az alábbiakkal:

- `camera-subsystem-knowledge-base.md`
- `camera-endpoint-test-gap-list.md`
- `legacy-analysis-rebuild-knowledge-base.md`
- `szerver-business-logic.md`
