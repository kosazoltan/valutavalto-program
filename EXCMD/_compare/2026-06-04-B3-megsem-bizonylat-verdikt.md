# B3 (b4-bizonylatok FR-15/16 — „MEGSEM" bizonylat) — verdikt: MOOT a modern architektúrában (category-C)

> EXCMD↔kód összevetés, 2026-06-04. Tényalapú, file:line bizonyítékkal. NEM implementálandó (architektúra-eltérés, nem bug).
>
> Helyesírási konvenció ebben a dokumentumban: a **„MEGSEM"** (ékezet nélkül, nagybetűvel) a legacy Delphi által a bizonylatra NYOMTATOTT literál felirat; a **„mégsem gomb"** (ékezettel, magyar szó) a megszakító UI-művelet. A kettő szándékosan eltérő alak.

## A spec (EXCMD/b4-bizonylatok.md FR-15/16)
- **FR-15:** ha egy tranzakciót a rögzítés közben vagy a nyomtatás előtt megszakítanak (mégsem gomb), a rendszer „MEGSEM BIZONYLAT"-ot generál a rögzített adatokkal + a megszakítás okával, **elkerülve a bizonylatszámok kiesését** (nagy, keresztben „MEGSEM" felirat).
- **FR-16:** a MEGSEM bizonylat másodpéldánya a napi elszámoláshoz.

## A megszakítás VALÓDI célja: a bizonylatszám-kiesés (gap) elkerülése
A legacy Delphi a bizonylatszámot KORÁN (a rögzítés közben) osztotta ki, ezért egy megszakítás „lyukat" hagyott a szigorú sorszám-sorozatban → ezt a lyukat töltötte ki egy MEGSEM-placeholder bizonylat.

## A modern architektúra ténye (verifikálva)
1. **A bizonylatszám SUBMIT-kor kerül kiosztásra, atomikusan**, NEM a rögzítés közben:
   - `penztar-client/electron/sqlite.ts` `savePendingTransactionV2` (`:1469`) a `generateStrictReceiptNumber`-t és a row-INSERT-et UGYANABBAN a `withTransaction` SQL-tranzakcióban futtatja (`sqlite.ts:51` wrapper → `:31` `runInTransaction` BEGIN/COMMIT/ROLLBACK; a wrap helye `:1491`). A `local_receipt_sequence` UPSERT increment-by-one (gapless), és INSERT-hibánál a ROLLBACK a sorszámot is visszagördíti — tehát a számkiosztás NEM „az INSERT előtt, külön" történik, hanem vele atomikusan.
   - A `saveAndSyncPendingBuySell` csak a tényleges submitkor hívja.
2. **A megszakítás (handleCancel) NEM fogyaszt számot:**
   - `frontend-react/src/pages/transactions/CashierTransactionPage.tsx:984` `handleCancel` CSAK form-reset (`setRows(üres)` + ref-tisztítás) — semmilyen bizonylatszám-kiosztás.
3. **Rögzítés UTÁNi megszakítás (van szám) = STORNO/REVERSAL**, ami a rendszerben létezik: `TransactionType.REVERSAL` + `ReceiptGeneratorService.generateStornoReceipt` (`ReceiptGeneratorService.java:130`; a REVERSAL/STORNO bizonylat-ág `:359`, hívás `:472`/`:491`).

## Verdikt
A legacy FR-15 „rögzítés közben VAGY a nyomtatás előtt" megszakítás a modern flow-ban HÁROM, eltérő esetre bomlik — a megszakítás NEM egyetlen „storno-only" eset (Codex P2 pontosítás):

1. **Megszakítás rögzítés közben** (submit/számkiosztás ELŐTT, `handleCancel`) → nincs szám → **nincs kiesés** → MEGSEM-placeholder FELESLEGES.
2. **A NYOMTATÁS meghiúsul/megszakad, de a tranzakció MÁR rögzített és érvényes**. A KULCS: a **bizonylatszám sosem vész el** (a számkiosztás atomikus a rögzítéssel — ld. lent), ezért ez **NEM MEGSEM/szám-gap eset**. A fizikai újranyomtatás viszont két alesetre bomlik (Codex P2-k, mindkettő helyes és kódból igazolt):
   - **Offline / még NEM szinkronizált** bizonylat: a függő vázlat fizikailag újranyomtatható a bizonylat-böngészőből: `ReceiptPage.tsx:228` „Vázlat nyomtatás" → `ReceiptPreviewModal` (`variant="draft"`) `onPrint` (`:315`/`:320`) → `localQueue.ts:195` `printPendingReceiptDraft` → `:202` `window.electronAPI.printReceipt` → IPC `print-receipt` (`penztar-client/electron/main.ts:337`) → `printReceipt()` ESC-POS/serial. ✅ **működik.**
   - **Online / MÁR szinkronizált** bizonylat: a `getPendingReceiptDrafts` a `getPendingTransactions`/`getPendingConversions` `WHERE synced = 0` szűrőjére épül (`penztar-client/electron/sqlite.ts:1624`/`:1932`), így egy `synced=1` rekord **NEM jelenik meg** a vázlat-listában; a szerver-oldali Print-gomb (`ReceiptService.print`) pedig csak az `isPrinted` flaget állítja, ESC-POS-t nem küld. ⚠️ **Ez egy VALÓS, jelenleg NYITOTT fizikai-újranyomtatás-hiányosság az online-synced esetre** (ld. „Nyitott follow-up"). **De NEM a MEGSEM tárgya:** a legacy MEGSEM szám-gap-placeholder volt (nem újranyomtató), a szám itt sem vész el → a verdiktet nem érinti.
3. **A rögzített tranzakciót ténylegesen vissza KELL vonni** → **STORNO/REVERSAL** (`TransactionType.REVERSAL`, `ReceiptGeneratorService.generateStornoReceipt` — `ReceiptGeneratorService.java:130`), ami új storno-bizonylatszámot kap (nem hagy rést).

A verdikt MAGJA: egyik esetben sincs „kiosztott, de fel nem használt" szám (a legacy gap-forrás), mert a számkiosztás **atomikus a rögzítéssel** (kikényszerítve — lásd alább). A legacy MEGSEM PONTOSAN ezt a szám-kiesést hivatott elkerülni; a modern submit-kori gapless számozás ezt a célt strukturálisan kiváltja → **a MEGSEM mint szám-gap-placeholder MOOT (category-C: architektúra-eltérés, NEM bug).** A döntés (dokumentálás, NEM implementálás) indoka maga ez: a szám-kiesés (a MEGSEM egyetlen feladata) az atomikus számozással lehetetlen, így a MEGSEM-placeholder redundáns lenne.

> **Fontos elhatárolás (Codex P2 nyomán):** a fenti 2. aleset online-synced fizikai-újranyomtatás-hiányossága **NEM** a MEGSEM hatóköre és **NEM** dől el ezzel a verdikttel — az egy önálló, valós operatív hiányosság (ld. lent), amit külön kezelünk. A MEGSEM-moot megállapítás kizárólag a szám-kiesésre vonatkozik. (Megjegyzés: a korábbi „mandátum mint forrás" megfogalmazás félrevezető volt — a `CLAUDE.md` nem tartalmaz ilyet; a tényleges indok a fenti, kódból verifikálható atomicitás.)

## Az atomicitás KIKÉNYSZERÍTVE (Codex #1035 review nyomán — fix #1036)
A Codex jogosan jelezte: a verdikt premisszája (a számkiosztás atomikus a rögzítéssel) eredetileg NEM állt fenn a kódban — a `generateStrictReceiptNumber` a `local_receipt_sequence`-t azonnal UPSERT-elte, de a row-INSERT KÜLÖN, tranzakció nélkül futott, így INSERT-hibánál a sorozat előrelépett szám-fogyasztás nélkül (rés). Ezt a **#1036 PR javította** (már a `main`-ben, commit `3b525f13`, és ebbe a branchbe is bemergelve): a `runInTransaction(db, fn)` mag (`penztar-client/electron/sqlite.ts:31`, `BEGIN`/`COMMIT`/`ROLLBACK`) és a `withTransaction` wrapper (`sqlite.ts:51`) a (sequence-UPSERT + row-INSERT)-et mind az **5** save-függvényben EGY SQL-tranzakcióba zárja (`sqlite.ts:1337`, `:1491`, `:1708`, `:1821`, `:2115`). Re-entry guard (`inTransaction` flag) véd a nested BEGIN ellen. Így a verdikt premisszája MOST MÁR tényszerűen áll a vizsgált fában is (tesztelve: valós INSERT-hiba → `last_seq` változatlan; `sqlite.test.ts` 22✓). A MEGSEM így továbbra is moot.

> Megjegyzés a review-eszköznek: ha a `rg "withTransaction|BEGIN|COMMIT|ROLLBACK" penztar-client/electron/sqlite.ts` korábban üres volt, az a `#1036` merge ELŐTTI fát vizsgálta. A frissített branchen a fenti sorokon megtalálható.

## Follow-up — LEZÁRVA (#1035/#1039): online-synced bizonylat fizikai ESC/POS újranyomtatása

**LEZÁRVA (a verdikt utáni körben, #1035/#1039).** A synced=1 bizonylatok fizikai ESC/POS-újranyomtatása megvalósult: `getReprintableTransactions/Conversions/Stornos` (sqlite.ts, `WHERE synced=1`) + `get-reprintable-*` IPC (preload.ts) + ReceiptPage `reprintable` lista (1-kattintásos ESC/POS "Újranyomtatás" gomb, ReceiptPreviewModal reprint-variant). Az alábbi (eredeti) leírás történeti.

Codex P2 (helyes, kódból igazolt) feltárt egy valós, a MEGSEM-től FÜGGETLEN hiányosságot: ha egy bizonylat MÁR szinkronizált (`synced=1`) és a fizikai nyomtatás meghiúsul, jelenleg nincs tiszta fizikai-újranyomtatási út:
- a vázlat-böngésző csak `synced=0` rekordot listáz (`sqlite.ts:1624`/`:1932`), a synced rekord eltűnik;
- a szerver Print-gomb (`ReceiptService.print`) csak az `isPrinted`/materializálást végzi, ESC-POS-t nem küld.

**Javasolt follow-up** (külön increment, nem ehhez a verdikt-dochoz): a synced bizonylat ESC-POS újranyomtatása — pl. a szerver-oldali bizonylatadatból a renderer az Electron `print-receipt` IPC-n keresztül újra kinyomtatja (a `ReceiptPreviewModal`-t a `variant="receipt"` ágon a tényleges ESC-POS úthoz kötve), vagy a `getPendingReceiptDrafts` a már-synced, de még nem nyomtatott rekordokat is felkínálja újranyomtatásra. Ez NEM blokkolja a MEGSEM-verdiktet (a szám nem vész el), de valós operatív igény.

## Ha a jövőben mégis felmerülne
Egyetlen lehetséges residual: ha egy submit-kor kiosztott LOKÁLIS szám olyan tranzakcióhoz tartozik, amit a SZERVER utólag elutasít (pl. AML-blokk sync-kor) — ez NEM a FR-15 „mégsem rögzítés közben" esete, hanem lokális↔szerver rekonciliáció (külön téma); a lokális sorozat akkor is gapless marad (a szám ki van osztva), a szerver-oldali audit kezeli az elutasítást.
