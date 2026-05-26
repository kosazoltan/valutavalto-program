# Árfolyamkészítő Főlap (0-s lap) — legacy képletezés (design)

**Dátum:** 2026-05-26
**Forrás-spec:** `arfolyamkeszito_fejlesztesi_keresek.md` (Kósa Zoltán)
**Érintett modul:** `frontend-react/src/pages/rates/MainRateSheetPage.tsx` (rate-maker Főlap, 0-s lap)

## Cél

A Főlap A–F érték-celláiba a régi programból ismert **legacy képlet-szintaxis** írható legyen,
hogy az összefüggő árfolyamokat ne kelljen kézzel újraszámolni. A jelenlegi (v2.5.61)
Excel-szerű HyperFormula `=A1*1.02` szintaxist **lecseréljük** a legacy nyelvre.

## Döntések (user-jóváhagyott, 2026-05-26)

1. **Lecserélés**: a `=A1` Excel/HyperFormula szintaxis helyett a legacy `C*0,97` / `!FEUR` nyelv.
   A HyperFormula függőség kivezetése (ha máshol nem használt).
2. **Képlet-oszlopok**: A (settlement), B (otp), C (helper), E (weakMultiBuy), F (weakMultiSell).
   D = ISO-kód (védett címke, nem érték); G/H = kereszt-auto (változatlan); I/Nagybani már NEM
   képletezhető (a spec „A–F"-et kér).
3. **Kereszt-hivatkozás azonosítója = valutakód** (`!FEUR` → az EUR sor F oszlopa).

## Szintaxis

- **Saját sor oszlop-hivatkozás**: oszlopbetű (A/B/C/E/F) → az aktuális valuta sorának adott oszlopa.
  Pl. `C*0,97`.
- **Kereszt-valuta**: `!<OSZLOP><VALUTAKÓD>` → másik valuta sorának oszlopa. Pl. `!FEUR`.
- **Műveletek**: `+ - * /` és zárójel (eltérő prioritásnál kötelező).
- **Tizedeselválasztó**: magyar vessző (`0,97`), de a pont is elfogadott (tolerancia).
- **Nincs `=` prefix** (a legacy nem használt).

## Auto / kézi / képlet feloldás (cella-állapot)

- Üres cella → **auto** (a számított/alapérték).
- Tiszta szám → **kézi** felülírás (a beírt érték).
- Képlet → a képlet **eredménye**, és **auto-recompute**, ha a hivatkozott érték változik.

(A meglévő `mainSheetRules.ts` A-oszlop auto/kézi logikáját az érték-cellákra általánosítjuk.)

## Architektúra

### Új pure modul: `frontend-react/src/pages/rates/mainSheetFormula.ts`
- `isFormula(input): boolean` — szám-vs-képlet detektálás (`^-?\d+([.,]\d+)?$` → érték).
- `parseNumber(token): number` — magyar tizedesvessző → szám.
- `extractDependencies(formula): FormulaRef[]` — a hivatkozott cellák (`{ currency?: string, col: ColLetter }`).
- `evaluateFormula(formula, ctx): { value: number } | { error: string }` — recursive-descent
  kiértékelés; `ctx` = `{ self: ColValues, byCurrency: Map<string, ColValues> }`.
- `ColLetter = 'A'|'B'|'C'|'E'|'F'`, `ColValues = Record<ColLetter, number>`.
- Hibás hivatkozás / ismeretlen valuta / 0-osztás / szintaxis-hiba → `{ error }` (nem dob).

### Ciklus-védelem
- A teljes lap újraszámítása iteratív: minden képlet-cellát kiértékelünk, ismételve, amíg
  stabilizálódik VAGY elérjük a max-iterációt (cella-szám). Ha egy cella a max után sem stabil →
  körhivatkozás → a cella `#KÖR` hibajelzést kap (nem fagy).

### `MainRateSheetPage.tsx`
- HyperFormula import + `hfRef` + `buildEmpty`/`setSheetContent`/`calculateFormula` **törlése**.
- `formulas: Record<\`${rowIdx}.${col}\`, string>` marad (localStorage, kulcs változatlan).
- Recompute-effekt: `rows` + `formulas` változáskor → a custom evaluator a teljes lapra,
  a kiszámolt értékek a render-be (és a publish-payloadba) kerülnek.
- Oszlopbetű → mező map a referencia-feloldáshoz.

### Lebegő ablak (floating tooltip)
- **Szerkesztés közben**: az `editBuffer` (beírt képlet/érték) lebegő dobozban a cella mellett.
- **Hover**: ha a cellához tartozik képlet → a képlet-string; ha kézi érték → „Kézi érték";
  ha auto → „Automatikus érték". Egy könnyű, pozícionált tooltip-komponens.

### Dokumentáció
- A meglévő `showHelp` panel bővítése a legacy szintaxis rövid útmutatójával (oszlop-ref,
  `!` kereszt-ref, műveletek, tizedesvessző, példák).

## Tesztek (`mainSheetFormula.test.ts`)
- `isFormula`: szám (vessző/pont) vs képlet.
- Saját-sor ref: `C*0,97`.
- Kereszt-ref: `!FEUR`.
- Műveletek + zárójel prioritás: `(A+B)*0,5`.
- Magyar tizedesvessző parse.
- Ismeretlen valuta / oszlop / 0-osztás → error (nem dob).
- Ciklus-detektálás.
- `extractDependencies` helyessége.

## Scope-on kívül (spec szerint)
- `#CCA` munkacsoport-közi hivatkozás (külön, munkacsoport-fejlesztés).
- G/H kereszt-logika módosítása.
- I/Nagybani képletezése.
- A munkacsoport-lapok képletezése (később, a 0-s lap az első).

## Kliens-hatás
A Főlap a rate-maker (kozponti-client rate-maker flavor + arfolyam-keszito) **csomagolt
frontendje** → a változás **telepítő-rebuildet** igényel a kézbesítéshez (nem szerver-served).
