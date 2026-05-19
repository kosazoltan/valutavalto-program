# Third-party license notices

## HyperFormula (GPL v3)

A frontend-react bundle a [HyperFormula](https://hyperformula.handsontable.com)
v3.2.0 Excel-szerű cell-formula motort használja az Árfolyamkészítő (Rate-Maker)
Főlap-modulban.

**License:** GNU General Public License v3.0 (GPL v3)  
**Source:** https://github.com/handsontable/hyperformula

### Használati indoklás (user-direktíva 2026-05-19)

A Best Change Zrt. (Kósa Zoltán üzemeltetésében) belső használatra terjeszti
az Árfolyamkészítő alkalmazást a **SAJÁT alkalmazottainak** (főértéktárosok,
ügyvezetők, pénztárosok) gépeire. **NEM publikusan** értékesíti, **NEM
harmadik fél** vásárolja meg / terjeszti tovább.

A GPL v3 4. szakasz "Conveying Verbatim Copies" és 5. szakasz "Conveying
Modified Source Versions" kötelezettségei a *publikus terjesztésre*
vonatkoznak — a belső, alkalmazott-gépekre való telepítés a GPL nyilatkozat
1. szakasz "Source Code" + 6. szakasz "Non-Source Forms" felételei szerint
**nem kiváltja a forrás-publikálás kötelezettségét** (a felhasználó és a
licencjogosult ugyanaz a jogi entitás).

### Ha a jövőben publikus terjesztés válna szükségessé

Választás:

1. **Source-release** — A HyperFormula-t haszn\xC3\xA1l\xC3\xB3 frontend-react
   forr\xC3\xA1sk\xC3\xB3d (vagy a HyperFormula-related r\xE9sze)
   ny\xC3\xADltt\xE9 t\xE9tele GPL v3 alatt
2. **Commercial license** — https://hyperformula.handsontable.com/guide/license-key.html —
   $$ \xE9ves d\xEDj a Handsontable-t\xF5l, GPL k\xF6telez\xE9ts\xE9g elt\xFCnik
3. **Csere alternatívára** — saját mini-parser (~200 LOC, MIT) vagy
   `mathjs` (MIT, kisebb funkciókészlet)

### Megőrzendő tájékoztatás

A HyperFormula NOTICE / LICENSE fájljai a `node_modules/hyperformula/`
mappában a release-installerrel együtt szállítódnak. A felhasználók (Best
Change alkalmazottak) a GPL v3 4-6. szakaszok szerinti jogosultságokat
megkapják.

**Utolsó felülvizsgálat:** 2026-05-19 (Kósa Zoltán user-direktíva)
