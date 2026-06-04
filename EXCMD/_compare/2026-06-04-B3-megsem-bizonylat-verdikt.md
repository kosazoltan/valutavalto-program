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
2. **A NYOMTATÁS meghiúsul/megszakad, de a tranzakció MÁR rögzített és érvényes** → **ÚJRANYOMTATÁS a bizonylat-böngészőből**. Igaz (Codex P2 megfigyelés), hogy a `CashierTransactionPage` modal bezárása önmagában NEM nyomtat újra — csak a `receiptData`-t törli és „megtekintette nyomtatás nélkül" üzenetet ad (`CashierTransactionPage.tsx:1601` + `:1606`). A recovery viszont egy KÜLÖN képernyőn, a bizonylat-böngészőben létezik és működik: `ReceiptPage.tsx:129` `receiptApi.print(id)` → `POST /api/v1/receipts/{id}/print` (`ReceiptController.print` → `ReceiptService.print`), amely a synthesized bizonylatot is materializálja és (újra)nyomtatja. NEM storno, NEM MEGSEM: a tranzakció érvényes marad, csak a fizikai nyomtatás ismétlődik (a bizonylatszám a rekordhoz tartozik, nem vész el).
3. **A rögzített tranzakciót ténylegesen vissza KELL vonni** → **STORNO/REVERSAL** (`TransactionType.REVERSAL`, `ReceiptGeneratorService.generateStornoReceipt` — `ReceiptGeneratorService.java:130`), ami új storno-bizonylatszámot kap (nem hagy rést).

Egyik esetben sincs „kiosztott, de fel nem használt" szám (a legacy gap-forrás), mert a számkiosztás **atomikus a rögzítéssel** (kikényszerítve — lásd alább). **Category-C: doc↔modern-architektúra eltérés, NEM bug** — a MEGSEM a legacy korai-számkiosztás artefaktuma, amit a modern submit-kori gapless számozás + újranyomtatás + storno együtt kivált. A döntés (dokumentálás, NEM implementálás) indoka maga a category-C besorolás: a fenti három modern eset (handleCancel + bizonylat-böngésző újranyomtatás + STORNO/REVERSAL) együtt MÁR lefedi a legacy MEGSEM célját (a szám-kiesés elkerülését), így egy MEGSEM-placeholder redundáns feature lenne — nem hiányzó funkció, hanem tudatos architektúra-különbség. (Megjegyzés: a korábbi „mandátum mint forrás" megfogalmazás félrevezető volt — a `CLAUDE.md` nem tartalmaz ilyen explicit előírást; a tényleges indok a fenti, kódból verifikálható lefedettség.)

## Az atomicitás KIKÉNYSZERÍTVE (Codex #1035 review nyomán — fix #1036)
A Codex jogosan jelezte: a verdikt premisszája (a számkiosztás atomikus a rögzítéssel) eredetileg NEM állt fenn a kódban — a `generateStrictReceiptNumber` a `local_receipt_sequence`-t azonnal UPSERT-elte, de a row-INSERT KÜLÖN, tranzakció nélkül futott, így INSERT-hibánál a sorozat előrelépett szám-fogyasztás nélkül (rés). Ezt a **#1036 PR javította** (már a `main`-ben, commit `3b525f13`, és ebbe a branchbe is bemergelve): a `runInTransaction(db, fn)` mag (`penztar-client/electron/sqlite.ts:31`, `BEGIN`/`COMMIT`/`ROLLBACK`) és a `withTransaction` wrapper (`sqlite.ts:51`) a (sequence-UPSERT + row-INSERT)-et mind az **5** save-függvényben EGY SQL-tranzakcióba zárja (`sqlite.ts:1337`, `:1491`, `:1708`, `:1821`, `:2115`). Re-entry guard (`inTransaction` flag) véd a nested BEGIN ellen. Így a verdikt premisszája MOST MÁR tényszerűen áll a vizsgált fában is (tesztelve: valós INSERT-hiba → `last_seq` változatlan; `sqlite.test.ts` 22✓). A MEGSEM így továbbra is moot.

> Megjegyzés a review-eszköznek: ha a `rg "withTransaction|BEGIN|COMMIT|ROLLBACK" penztar-client/electron/sqlite.ts` korábban üres volt, az a `#1036` merge ELŐTTI fát vizsgálta. A frissített branchen a fenti sorokon megtalálható.

## Ha a jövőben mégis felmerülne
Egyetlen lehetséges residual: ha egy submit-kor kiosztott LOKÁLIS szám olyan tranzakcióhoz tartozik, amit a SZERVER utólag elutasít (pl. AML-blokk sync-kor) — ez NEM a FR-15 „mégsem rögzítés közben" esete, hanem lokális↔szerver rekonciliáció (külön téma); a lokális sorozat akkor is gapless marad (a szám ki van osztva), a szerver-oldali audit kezeli az elutasítást.
