# B3 (b4-bizonylatok FR-15/16 — „MÉGSEM" bizonylat) — verdikt: MOOT a modern architektúrában (category-C)

> EXCMD↔kód összevetés, 2026-06-04. Tényalapú, file:line bizonyítékkal. NEM implementálandó (architektúra-eltérés, nem bug).

## A spec (EXCMD/b4-bizonylatok.md FR-15/16)
- **FR-15:** ha egy tranzakciót a rögzítés közben vagy a nyomtatás előtt megszakítanak (mégsem gomb), a rendszer „MEGSEM BIZONYLAT"-ot generál a rögzített adatokkal + a megszakítás okával, **elkerülve a bizonylatszámok kiesését** (nagy, keresztben „MEGSEM" felirat).
- **FR-16:** a MEGSEM bizonylat másodpéldánya a napi elszámoláshoz.

## A megszakítás VALÓDI célja: a bizonylatszám-kiesés (gap) elkerülése
A legacy Delphi a bizonylatszámot KORÁN (a rögzítés közben) osztotta ki, ezért egy megszakítás „lyukat" hagyott a szigorú sorszám-sorozatban → ezt a lyukat töltötte ki egy MEGSEM-placeholder bizonylat.

## A modern architektúra ténye (verifikálva)
1. **A bizonylatszám SUBMIT-kor kerül kiosztásra, atomikusan**, NEM a rögzítés közben:
   - `penztar-client/electron/sqlite.ts` `savePendingTransactionV2` → `generateStrictReceiptNumber` az INSERT részeként (a `local_receipt_sequence` UPSERT increment-by-one, gapless).
   - A `saveAndSyncPendingBuySell` csak a tényleges submitkor hívja.
2. **A megszakítás (handleCancel) NEM fogyaszt számot:**
   - `frontend-react/src/pages/transactions/CashierTransactionPage.tsx:984` `handleCancel` CSAK form-reset (`setRows(üres)` + ref-tisztítás) — semmilyen bizonylatszám-kiosztás.
3. **Rögzítés UTÁNi megszakítás (van szám) = STORNO/REVERSAL**, ami a rendszerben létezik (`TransactionType.REVERSAL`, `generateStornoReceipt`).

## Verdikt
A legacy FR-15 „rögzítés közben VAGY a nyomtatás előtt" megszakítás a modern flow-ban HÁROM, eltérő esetre bomlik — a megszakítás NEM egyetlen „storno-only" eset (Codex P2 pontosítás):

1. **Megszakítás rögzítés közben** (submit/számkiosztás ELŐTT, `handleCancel`) → nincs szám → **nincs kiesés** → MEGSEM-placeholder FELESLEGES.
2. **A NYOMTATÁS meghiúsul/megszakad, de a tranzakció MÁR rögzített és érvényes** → **ÚJRANYOMTATÁS** (`receiptApi.print` / a függő vázlat újra-nyomtatása) — NEM storno, NEM MEGSEM: a tranzakció érvényes marad, csak a fizikai nyomtatás ismétlődik. (A bizonylatszám nem vész el — a rekordhoz tartozik.)
3. **A rögzített tranzakciót ténylegesen vissza KELL vonni** → **STORNO/REVERSAL** (`TransactionType.REVERSAL`, `generateStornoReceipt`), ami új storno-bizonylatszámot kap (nem hagy rést).

Egyik esetben sincs „kiosztott, de fel nem használt" szám (a legacy gap-forrás), mert a számkiosztás atomikus a rögzítéssel. **Category-C: doc↔modern-architektúra eltérés, NEM bug** — a MEGSEM a legacy korai-számkiosztás artefaktuma, amit a modern submit-kori gapless számozás + újranyomtatás + storno együtt kivált. A mandátum szerint dokumentálva, NEM implementálva (felesleges feature elkerülése).

## Ha a jövőben mégis felmerülne
Egyetlen lehetséges residual: ha egy submit-kor kiosztott LOKÁLIS szám olyan tranzakcióhoz tartozik, amit a SZERVER utólag elutasít (pl. AML-blokk sync-kor) — ez NEM a FR-15 „mégsem rögzítés közben" esete, hanem lokális↔szerver rekonciliáció (külön téma); a lokális sorozat akkor is gapless marad (a szám ki van osztva), a szerver-oldali audit kezeli az elutasítást.
