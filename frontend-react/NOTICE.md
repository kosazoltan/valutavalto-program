# Third-party license notices

## HyperFormula (GPL v3) — ELTÁVOLÍTVA (2026-05-26)

A frontend-react bundle **2026-05-26 óta NEM használ HyperFormula-t**. Az Árfolyamkészítő
(Rate-Maker) Főlap-modul képlet-motorja egy **saját, belső implementáció**
(`src/pages/rates/mainSheetFormula.ts`, MIT-kompatibilis a repo licensze alatt) — ez a
korábbi NOTICE 3. opciója („Csere alternatívára — saját mini-parser") szerinti váltás.

Ezzel a HyperFormula GPL v3 kötelezettsége **megszűnt**: a bundle többé nem tartalmaz
GPL-licencelt third-party kódot a képlet-kezeléshez. A `hyperformula` npm-függőség a
`package.json`-ból eltávolítva.

> Korábbi állapot (v2.5.61–v2.27.20): a Főlap a HyperFormula v3.2.0 (GPL v3) Excel-szerű
> cell-formula motort használta, belső alkalmazotti terjesztéssel. A legacy `C*0,97` / `!FEUR`
> szintaxisra való átállás (user-spec 2026-05-26) a saját parserrel valósult meg.

**Utolsó felülvizsgálat:** 2026-05-26
