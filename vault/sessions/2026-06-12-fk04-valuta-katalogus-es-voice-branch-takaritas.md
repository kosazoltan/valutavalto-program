# 2026-06-12 — FK04 valuta-katalógus dinamikus betöltés + voice-assistant branch-takarítás

## Elvégzett munka

### 0) Repo-szinkron korrekció (kritikus tanulság)
- A session-eleji „lokál = remote, szinkronban" jelentés **hamis** volt: a `git fetch` háttérben
  futott, az ahead/behind számítás a fetch-ELŐTTI stale ref-et látta. Valójában a lokál main
  **203 committal** volt lemaradva (v2.27.64 → v2.27.99, max migráció V280 → V316).
- Fast-forward pull után az FK04 tényfeltárást teljesen újrafuttattam a friss HEAD-en.
- Memóriába rögzítve: `feedback-sync-check-after-fetch-completes.md`.

### 1) Voice-assistant: 4 mergeletlen branch → törölve (nem volt mit implementálni)
- `feat/voice-assistant-phase5..8-*-2026-05-18` — a #663/#664/#665 CLOSED PR-ok headjei.
- Verifikálva: a teljes tartalmuk a main-en él a **#672–675 merged cherry-pick PR-okon** át
  (post-merge fixekkel: #679–692; prod rollout v2.5.57). A „branch-only" fájlok (ReceiptSearch*)
  a main-ről szándékosan törölt halott kód feltámasztásai lettek volna (d2981e60).
- Művelet: `git push origin --delete` mind a 4-re; a commitok a GitHub closed-PR refekben
  visszanyerhetők. Mandátum C.6 (nincs ácsorgó feature branch) teljesül.

### 2) FK04 backend — PR #1096 (MERGED 2026-06-12T09:53Z)
- **V317**: kanonikus currency display_order (HUF=0, EUR=1 … RUB=14, **EUA=15**, TRY=16 … NZD=22);
  az EUA=RUB=17 duplikáció (V298×V271) ÉS a doksi által nem látott V3-maradvány ütközések
  (BGN=12↔MXN, DKK=17↔RUB, HRK=18↔THB) felszámolása — nem-kanonikus kódok 100+ tartományba.
- **V318**: `UNIQUE (display_order)` — a tábla GLOBÁLIS (nincs company_id, V3:10–25; TBD-2 így
  dőlt el), schema-kvalifikált idempotencia-guarddal (conrelid).
- **AdminCurrencyService**: display_order előszűrés → 409 + `VV-VALID-003`; null sorrend → max+1;
  `saveAndFlush` + DataIntegrityViolationException → 409 (konkurens eset, Codex P2 fix).
- **error-codes.yaml**: VV-VALID-003 bejegyzés — Codex P2 alapján GENERIKUS (a RateWorkgroupService
  FK02-D sorszám/kód-duplikációja is ezt használja); total_codes 47.
- Tesztek: AdminCurrencyServiceTest +3, CurrencyMigrationFk04IT (RsdIT-minta) — 11/11 zöld JDK21-gyel.

### 3) FK04 frontend — PR #1097
- **useCurrencyCatalog hook** (FR-1/NFR-3): `GET /currencies/all` → aktív ∪ EUA, HUF nélkül,
  displayOrder-rendben; CROSS_BASE_MAP = a régi DEFAULT_CURRENCIES crossBase 1:1 (TBD-1 a
  tényleges kódból, NEM a doksi vázlatából — abban BGN tévesen szerepelt).
- **MainRateSheetPage** (FR-2/FR-3): DEFAULT_CURRENCIES törölve; sorlista-tagság+sorrend a
  katalógusból (buildRowsFromCatalog), cache csak értékeket ad; REMOVED_CURRENCIES marad TODO-val.
- **RateCreationPage** (FR-4/TBD-4): MAIN_SHEET_CURRENCY_ORDER törölve; rendezés az overview-item
  displayOrder mezőjéből (sortByDisplayOrder) — az EUA-t a backend a lista végére fűzi, a kliens
  teszi a 15. helyre. Kanonikus 22-elem paritás a régi konstanssal elemről elemre igazolva.
- **CurrencyManagerModal** (FR-8): default sorrend max+1; gomb disabled amíg a lista tölt.

### 4) Review-ciklusok eredményei (zero-tolerance: minden finding javítva)
- **Codex (#1096)**: 2 P2 → javítva (konkurencia 409; VV-VALID-003 generikus).
- **Copilot (#1097)**: 2 finding → javítva (EUA nem kerülhet az offline inaktív-szűrőlistába,
  különben offline eltűnne; sorrend-input 0-érték NaN-checkkel).
- **Saját subagent self-review (2 kör, mindkét PR)**: backend „merge-kész" + V318 schema-guard P1
  javítva; frontend **P0**: a Főlap képlet-kulcsai rowIdx-alapúak voltak → katalógus-vezérelt
  listában sor-eltolódásnál a képletek némán rossz valutára kerültek volna. **Javítva**: kulcs =
  `${valutakód}.${col}` + legacy-migráció a row-cache alapján (+7 teszt). (A törékenység a main-ről
  öröklött volt, a FK04 felerősítette.)
- **Adverzáriális verifikációs workflow (4 lencse)**:
  - V317 SQL: **tiszta** (nem refutált, high confidence).
  - Effect-lifecycle: **P1** — a `dirty`-védelem stale closure-t olvasott (fetch közbeni edit-et a
    válasz felülírta + perzisztálta; main-ről öröklött minta) → **dirtyRef** + végső guard a 2.
    fetch után; dirty alatt tagság-frissítés (a „Főlap frissült" toast ne hazudjon); offline ágak
    dirty-guardja. Hook: futásonkénti cancelled flag (out-of-order reload, last-requested-wins, +1 teszt).
  - Formula-migráció: első verifier API-hibára elhalt → pótló agent: **mind az 5 állítás igazolva**.
  - Paritás: kanonikus sorrend + CROSS_BASE_MAP igazolva; modal stale-prefill P2 javítva.
- Suite-állapot: frontend **116 fájl / 1316 teszt zöld**, tsc tiszta, eslint 0 error.

## Defer-döntések (dokumentált, nem javított)
- Backend P2: Integer-overflow guard a max+1 kiosztásnál — ~2 mrd valutát igényelne; nem reális.
- Backend P2: writeAudit-hiba szimulációs teszt — a VV-SEC-004 best-effort catch pre-existing,
  szándékos design (business op > audit completeness), FK04-en kívüli.
- Frontend P2: offline módban a sorlista az utolsó ismert (cache-elt) állapot — inherens offline
  korlát; az NFR-5 (inaktív-szűrés offline) teljesül, tartós offline-badge látható.
- Rendezési árnyalat: ≥2 AKTÍV nem-kanonikus valuta esetén a 100+ tartomány id-sorrendje eltérhet
  a régi ABC-tail-től — ma minden nem-kanonikus inaktív, gyakorlati eltérés nincs (komment a
  currencyDisplayOrder.ts-ben).

## Blast-radius megjegyzés
A display_order globális törzs-mező: a pénztári/készlet felületek sorrendje is a kanonikus
(EUR, USD elöl) sorrendre vált ABC-ről — az FK04 NFR-4 explicit követelménye. A V298-cal a main-en
élt egy rejtett hiba is: az EUA-t az FR-HL-04 inaktív-szűrő a Főlapról is levette; a katalógus-alapú
betöltés ezt megjavítja (EUA explicit katalógus-tag).

## Telepítő-döntés
`git diff` szerint CSAK `backend/**` + `frontend-react/**` (+ packages/shared-logging yaml) változott,
`*/electron/**` nem → **NINCS telepítő-build** (PATCH-szintű merge + auto-deploy).

## Mandátum-önellenőrzés (B.9)
- Research-first: doksi-állítások repo-ténnyel ütköztetve (V299/V300 foglalt → V317/V318;
  RUB=17 nem 14; tábla globális; TestContainers helyett H2+sanity minta). ✓
- Folyamatos tesztelés: minden fázisban célzott teszt + teljes suite újrafuttatás. ✓
- Zero-tolerance AI-review: 100% finding javítva vagy dokumentált defer. ✓
- 2 kör merge előtt: CI + AI gate + 2× saját subagent + adverzáriális workflow. ✓
- Hibás állítást tettem a session elején (szinkron-állapot) — korrigálva + memória-szabály. ⚠→✓
