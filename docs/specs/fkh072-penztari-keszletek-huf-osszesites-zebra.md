# Modul: Értéktári felület – FKH-072: "Pénztári készletek" HUF-sor forgalom-összesítés + zebra-csíkozás

> **Feltérképező analízis alapja:** Feltérképezés #136 (Claude Code, kizárólag olvasott kódelemzés).
> **Előzmény:** élő teszt (2026-09-15) az FKH-068 (valuta-egységre váltás) után. A #136 tényszerűen tisztázta: a felhasználó által mutatott "Pénztári készletek" (Értéktár/Főértéktár menüből elérve) és a "Kassza / készlet" (Pénztár menüből elérve) **ugyanaz a komponens és route** (`CashierStocksPage.tsx`, `/cashier-stocks`), csak két különböző menücsoportból (Értéktár: "Pénztári készletek", Főértéktár: "Országos készlet") érhető el, más-más címkével. **Nincs külön oldal** — a korábbi feltevés, hogy ez egy másik fájl lenne, tévesnek bizonyult, ezt a #136 kifejezetten jelezte.

---

## Összefoglaló a fejlesztőnek

Az FKH-068 (valuta-egységre váltás) óta a "Pénztári készletek" táblázat HUF sorának "Forgalom vétel"/"Forgalom eladás" mezője mindig 0-t mutat, mert a forgalmi aggregáció devizánkénti (EUR, USD stb.), és nincs "HUF" nevű forgalmazott deviza. A felhasználó korábban (az FKH-068 előtti, HUF-egyenértékes megjelenítésnél) innen olvasta le az **összesített napi forint-forgalmat** — ez az igény most is fennáll, csak a HUF sorban külön kell megjeleníteni. A jó hír (Feltérképezés #136): **a forint-egyenérték adat már elérhető** ugyanabból az API-hívásból (`vault-daily`), amit az oldal ma is meghív — a komponens csak jelenleg eldobja. Nincs szükség új backend-végpontra vagy kliens oldali árfolyam-számításra. Emellett egy második, önálló igény: a táblázat sorai kapjanak váltakozó háttérszínt (zebra-csíkozás), a projektben már létező mintát (`InventoryPage.tsx` testvér-oldal) követve.

---

## 1. Cél

A "Pénztári készletek" táblázat HUF sora mutassa az összesített napi forint-forgalmat (az összes deviza forint-egyenértékének összegét, vétel és eladás külön), és a táblázat sorai legyenek váltakozó háttérszínűek a jobb olvashatóságért.

## 2. Scope

### IN
- **HUF sor forgalom-összesítés:** a HUF sor "Forgalom vétel" és "Forgalom eladás" mezője az adott branch (vagy "Körzet összesen" esetén az összes branch) aznapi, forintban kifejezett teljes vételi/eladási forgalmát mutassa — a `vault-daily` API-válaszban **már ma is elérhető** `buyHuf`/`sellHuf` (devizánkénti) vagy `totalBuy`/`totalSell` (branch-szintű) mezőkből, amelyeket a komponens jelenleg beolvas, de eldob.
- A HUF sor forgalom-mezőinek megjelenítése forintként (`roundHuf(...).toLocaleString('hu-HU')`), konzisztensen a "Kezelési díj" oszloppal — **nem** `formatCurrencyAmount`-tal (az kizárólag a devizás soroknál marad, FKH-068 szerint).
- **Zebra-csíkozás:** a táblázat sorai váltakozó háttérszínt kapnak, a projektben már bevett, testvér-oldali minta szerint (`idx % 2 === 1 ? 'bg-gray-50' : ''`, `InventoryPage.tsx` mintájára).

### OUT
- A devizás sorok (EUR, USD, stb.) "Forgalom vétel"/"Forgalom eladás" megjelenítése — ez FKH-068 szerint valuta-egységben marad, **nem** kerül vissza HUF-egyenértékre (regresszió-védelem).
- A "Készlet" oszlop HUF sora — ez már ma is helyesen mutatja a tényleges HUF-készletet, nem érintett.
- Az `InventoryPage.tsx` ("Értéktári készlet" oldal) — ez egy **másik**, önálló oldal, nem érintett ebben a kérésben.
- Új backend-végpont vagy módosítás — a szükséges adat már elérhető a meglévő `vault-daily` válaszból.
- A globális `.data-grid` CSS-osztályra való átállás — a meglévő testvér-oldali inline mintát követjük (indoklás: 9.2, Fázis 3), nem a `.data-grid`-et, hogy a táblázat meglévő egyedi cella-stílusai ne sérüljenek.

## 3. Szakterületi szereplők (RBAC mátrix)

Nem alkalmazandó — a kérés kizárólag megjelenítési logikát módosít, jogosultsági kör nem változik. (A route mindkét menücsoportból — Értéktár és Főértéktár — elérhető, ez már ma is így van, nem módosul.)

## 4. Funkcionális követelmények (FR)

| ID | Leírás | Forrás | Prioritás | Csomag | Acceptance (Given/When/Then) |
|---|---|---|---|---|---|
| FR-1 | A HUF sor "Forgalom vétel" mezője az adott branch aznapi teljes forint-vételi forgalmát mutatja | Interjú (2026-09-15) + Feltérképezés #136 | MUST | penztar-client | Adott: egy branch-en aznap 100 EUR + 50 USD vétel történt, összesen 45 000 Ft forint-egyenértékben. Amikor: megnyílik a "Pénztári készletek" oldal, a branch kiválasztva. Akkor: a HUF sor "Forgalom vétel" mezője 45 000 Ft-ot mutat. |
| FR-2 | A HUF sor "Forgalom eladás" mezője hasonlóan az eladási oldalra | Interjú (2026-09-15) + Feltérképezés #136 | MUST | penztar-client | Adott/Amikor: mint FR-1, eladási oldalra. Akkor: a HUF sor "Forgalom eladás" mezője a teljes forint-eladási forgalmat mutatja. |
| FR-3 | "Körzet összesen" nézetben a HUF sor az összes látható branch forint-forgalmát összesíti | Interjú (2026-09-15) + Feltérképezés #136 (branch-enkénti `vault-daily` hívások mintája) | MUST | penztar-client | Adott: két branch, mindkettőn volt forgalom. Amikor: "Körzet összesen" kiválasztva. Akkor: a HUF sor a két branch forint-forgalmának összegét mutatja. |
| FR-4 | A HUF sor forgalom-mezői forintként jelennek meg (`roundHuf` + `toLocaleString('hu-HU')`), nem valuta-egységként | Konzisztencia a Kezelési díj oszloppal (kód-tény, #136) | MUST | penztar-client | Adott: a HUF sor forgalma 45 000 Ft. Amikor: megjelenik. Akkor: "45 000" formátumban látszik, nem "45000,00 HUF" formázással. |
| FR-5 | A devizás sorok (EUR, USD stb.) Forgalom oszlopai változatlanul valuta-egységben jelennek meg (regresszió-védelem) | FKH-068 | MUST | penztar-client | Adott: a módosítás után egy EUR sor 100 EUR forgalommal. Amikor: megjelenik. Akkor: "100,00" EUR-ban, nem forintra átszámítva. |
| FR-6 | A táblázat sorai váltakozó háttérszínnel jelennek meg | Interjú (2026-09-15) | MUST | penztar-client | Adott: a táblázat több sort tartalmaz. Amikor: megjelenik. Akkor: a páratlan indexű sorok `bg-gray-50` háttérrel, a párosak háttér nélkül jelennek meg. |
| FR-7 | A zebra-csíkozás nem befolyásolja a meglévő hover- és szegély-stílusokat | Regresszió-védelem (kód-tény, #136: `border-b border-gray-100`) | MUST | penztar-client | Adott: a zebra bevezetve. Amikor: egérrel egy sor fölé visz. Akkor: a meglévő hover-viselkedés és az alsó szegély változatlanul működik. |

## 5. Nem-funkcionális követelmények (NFR)

| ID | Leírás | Mérhető kritérium |
|---|---|---|
| NFR-1 | HUF kerekítés | `roundHuf` (5 Ft-os kerekítés) minden HUF sor forgalom-értékén, a meglévő Kezelési díj oszloppal konzisztensen. |
| NFR-2 | Teljesítmény | Nincs új hálózati hívás — a szükséges adat a már meglévő `vault-daily` válaszból származik, csak a feldolgozás bővül. |
| NFR-3 | Lokalizáció | hu-HU, `toLocaleString('hu-HU')`, változatlan minta. |

## 6. Adatmodell-érintettség

- **Új tábla / mező szükséges: NEM.** A forint-egyenérték adat (`buyHuf`/`sellHuf` devizánként, illetve `totalBuy`/`totalSell` branch-szinten) **már ma is** benne van a `vault-daily` API-válaszban (`TurnoverReportDto`, backend `TurnoverService.java` már kitölti) — a frontend eddig egyszerűen nem olvasta ki.
- **Flyway migráció:** nincs szükség.
- **SQLite mirror:** nem érintett (nincs offline írási igény, csak megjelenítési logika).
- **Backend-módosítás:** **NEM szükséges** — a `TurnoverReportDto` és a `TurnoverService` már ma is szolgáltatja a kellő adatot.

## 6.b Biztonsági érintettség (security-standards.md hivatkozással)

- [ ] Új jogosultság / szerep — nincs (§2 nem érintett)
- [ ] PII / pénzügyi adat — a megjelenített adat már ma is elérhető ezen az oldalon (csak más bontásban), nincs új adatkör.
- [ ] Cross-tenant teszt szükséges — nem érintett, a meglévő `vault-daily` hívás tenant-szűrése változatlan.
- [ ] Új audit-esemény — nincs, tisztán megjelenítési változás.
- [ ] Secret / kulcs kezelést érint — nem.
- [ ] Offline szinkron biztonságát érinti — nem.
- [ ] Új végpont — nincs.

## 7. Függőségek

- `frontend-react/src/pages/inventory/CashierStocksPage.tsx` — kizárólagosan érintett fájl.
- `frontend-react/src/services/api/vault-turnover.ts` — a típusdefiníció már tartalmazza a szükséges mezőket (`buyHuf`, `sellHuf`, `totalBuy`, `totalSell`), nem kell bővíteni.
- Backend: nincs függőség, nincs módosítás.
- Zebra-minta forrása (referencia, nem módosítandó): `frontend-react/src/pages/inventory/InventoryPage.tsx:1386`.

## 8. Domain-szótár

| Fogalom | Magyarázat |
|---|---|
| HUF sor forgalom-összesítés | A "Pénztári készletek" táblázat HUF sorának Forgalom vétel/eladás mezője, amely az összes forgalmazott deviza aznapi forint-egyenértékének összegét mutatja, nem egy önálló "HUF mint forgalmazott deviza" sort. |

## 9. Végrehajtási utasítás az AI-fejlesztő ügynöknek

### 9.1. Előkészítés
1. `cd C:\repo\valutavalto-program`
2. `git pull`
3. `git checkout -b fix/penztari-keszletek-huf-osszesites-zebra`

### 9.2. Fázisok

**Fázis 1 – Adatmodell:** nincs szükséges lépés (a 6. szekció szerint).

**Fázis 2 – Backend API:** nincs szükséges lépés (a szükséges adat már szolgáltatva).

**Fázis 3 – Frontend** (kizárólag `CashierStocksPage.tsx`)

- **HUF-összesítés:**
  - A branch-enkénti `vault-daily` hívások feldolgozásánál (kb. 206-228. sor) a jelenleg eldobott `report.totalBuy` / `report.totalSell` (vagy alternatívaként a `byCurrency[].buyHuf`/`sellHuf` összegzése) mentésre kerüljön egy új, branch-enkénti map-be (pl. `hufTurnoverByBranch: Map<branchId, { totalBuy: number; totalSell: number }>`), a meglévő `turnoverByBranch` felépítés mintájára (kb. 230-259. sor).
  - A "Körzet összesen" aggregációnál (kb. 447-508. sor, összegzés kb. 474-487. sor) a HUF-hoz tartozó forgalmat **ne** a devizánkénti `turnoverByCurrency.get('HUF')`-ból vegye (ez mindig `undefined`, ld. #136 2. pont), hanem a fent bevezetett `hufTurnoverByBranch` map összes látható branch-ére összegzett `totalBuy`/`totalSell` értékéből.
  - Egyetlen branch kiválasztásakor (nem "Körzet összesen") a HUF sor forgalma az adott branch `hufTurnoverByBranch`-beli `totalBuy`/`totalSell` értéke legyen.
  - A `detailedRows` összeállításánál (kb. 492-508. sor) a `currencyCode === 'HUF'` sor `turnover` mezője a fenti, frissen számolt HUF-összesítésből jöjjön, nem a (mindig üres) `turnoverByCurrency.get('HUF')`-ból.
- **Megjelenítés (FR-4, FR-5):**
  - A Forgalom vétel/eladás cellák renderelésénél (kb. 757. és 767. sor) vezessünk be egy elágazást: ha `row.currencyCode === 'HUF'`, a cella `roundHuf(row.turnover.buyVolume /* ill. sellVolume */).toLocaleString('hu-HU')`-t használjon (a Kezelési díj oszloppal — 777. sor — konzisztensen); minden más devizánál a meglévő `formatCurrencyAmount(...)` hívás változatlan marad.
- **Zebra-csíkozás (FR-6, FR-7):**
  - A `detailedRows.map((row) => ...)` hívás (kb. 738. sor) egészüljön ki index-szel: `detailedRows.map((row, idx) => ...)`.
  - A sor `<tr>` elem `className`-je (kb. 742. sor) egészüljön ki: `` `${idx % 2 === 1 ? 'bg-gray-50' : ''} border-b border-gray-100` `` — a meglévő `border-b border-gray-100` osztály megtartásával, az `InventoryPage.tsx:1386` mintáját követve (indoklás: ugyanabban a mappában lévő testvér-oldal már ezt a mintát használja, és a jelenlegi táblázat egyedi cella-osztályait ez nem zavarja meg, szemben a globális `.data-grid` osztály bevezetésével, ami a teljes táblázat-stílust átalakítaná).

**Fázis 4 – Tesztek** (`CashierStocksPage.test.tsx`)
- HUF sor forint-összesítés, egyetlen branch esetén (FR-1, FR-2).
- HUF sor forint-összesítés, "Körzet összesen" esetén, több branch-csel (FR-3).
- HUF sor formázása `roundHuf` + `toLocaleString('hu-HU')` szerint, nem `formatCurrencyAmount`-tal (FR-4).
- Regresszió: devizás sorok (EUR, USD) továbbra is valuta-egységben jelennek meg (FR-5).
- Zebra-csíkozás: páratlan indexű sor `bg-gray-50` osztályt kap, páros nem (FR-6).
- Regresszió: a meglévő `border-b border-gray-100` osztály és hover-viselkedés megmarad (FR-7).

### 9.3. Pipeline (Definition of Done)
1. `lint` PASS (eslint)
2. `npm run test` (Vitest) PASS, coverage ≥80%
3. `gitleaks` secret-scan PASS (§4)
4. `grep -r "@Disabled\|@Ignore\|skip("` → 0 találat új kódon
5. Code review PR (1 reviewer)
6. `merge` → `push` → `deploy` → új telepítő generálása

## 10. Kockázatok / Nyitott kérdések (TBD)

Nincs nyitott TBD — minden kérdés lezárva a Feltérképezés #136 alapján:
- A HUF-összesítéshez szükséges adat forrása tisztázott (meglévő `vault-daily` válasz, nincs új végpont).
- A zebra-minta megválasztása (inline `idx % 2`, nem `.data-grid`) indokolt döntés (ld. 9.2, Fázis 3), a testvér-oldali konzisztencia és a minimális kockázat miatt.

## 11. Kapcsolódó modulok
- [x] Pénztári felület (kezdeményező)
- [x] Értéktári felület (a route mindkét menücsoportból — "Pénztári készletek" Értéktár, "Országos készlet" Főértéktár — elérhető, változatlanul)
- [ ] Árfolyamkészítő
- [ ] Központi kliens

## 12. Verifikációs checklist
- [x] Minden FR-hez van forrás-hivatkozás (Interjú / Feltérképezés #136)
- [x] Minden FR-hez Acceptance Given/When/Then
- [x] NFR-ek számszerűsítve, ahol értelmezhető
- [x] Nincs hallucináció — minden állítás a Feltérképezés #136 tényeire és a felhasználói interjúra épül
- [x] TBD-ek külön jelölve (0 db)
- [x] Adatmodell konkrét (nincs változás, indokolva)
- [x] Flyway migráció — nem szükséges (indokolva)
- [x] Pipeline + Definition of Done teljes
- [x] Nincs hard-coded secret (§4)
- [x] Regresszió-védelem explicit jelölve (FR-5, FR-7)

---
FR-ek száma: 7 db
TBD-ek száma: 0 db
Érintett csomagok: penztar-client (kizárólag frontend, backend-módosítás nem szükséges)
