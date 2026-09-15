# FK-115: "Stornózott bizonylatok" fül — Beérkezett adatok (kozponti-client / backend)

## 1. Cél
A "Beérkezett adatok" oldalon egy negyedik fül készül, ami a legacy "A STORNÓ BIZONYLATOK KIJELZÉSE" képernyő mintájára, egy listában mutatja a sztornózott (visszavont) bizonylatokat — a mai rendszerben ez két, egymástól független forrás egyesítését igényli: a vétel/eladás (Tranzakció) és a pénztárak közötti átadás (Transfer) sztornóit.

## 2. Scope

### IN
- Tranzakció-oldali (vétel/eladás) sztornó-lekérdezés, dátum-tartományra és fiók-részhalmazra (FR-1).
- Átadás-oldali sztornó-lekérdezés, ugyanazokkal a szűrőkkel, az elutasított (soha el nem fogadott) tételek kizárásával (FR-2).
- Ft-érték kiszámítása több valutás átadásnál, az adott napi MNB-árfolyammal (FR-3).
- A két forrás egységes DTO-ba és listába rendezése (FR-4).
- Negyedik fül a felületen (FR-5).

### OUT
- **TILOS** a foglaló (Reservation) sztornóinak megjelenítése — más üzleti fogalom, a screenshot bizonylat-előtagjaival csak véletlenül egyezik.
- **TILOS** az elutasított (REJECTED státuszú, a fogadó fél által soha el nem fogadott) átadások megjelenítése — ez nem sztornó, a pénz soha nem került át.
- **TILOS** a PARTIAL_REFUND (részleges visszatérítés) tranzakciók megjelenítése — más üzleti fogalom, külön kérés tárgya, ha szükséges.
- **TILOS** a régi, 2026-08-01 előtti, indoklás nélküli törlési mechanizmus utólagos feltárása vagy pótlása a listában — ismert, visszamenőleg nem javítható adathiány.
- **TILOS** a meglévő fülek (Átadólap-egyeztetés, Készletek/címletek, Banki forgalmi adatok) tartalmának vagy viselkedésének módosítása.
- **TILOS** bármilyen regionális vagy más hozzáférés-korlátozás bevezetése — a család meglévő, cég-szintű viselkedését örökli.
- **TILOS** új route/menüpont létrehozása.
- **TILOS** automatikus lekérdezés betöltéskor — csak explicit gombnyomásra fut.

## 3. RBAC
Megegyezik a meglévő fülekkel: Főértéktáros, Belső ellenőr, Admin — **nem** a `TransactionController` szűkebb (Pénztáros/Felügyelő/Vezető/Admin) köre.

## 4. Funkcionális követelmények (FR)

| ID | Leírás | Forrás | Csomag | Acceptance |
|---|---|---|---|---|
| FR-1 | Tranzakció-oldali sztornó lekérdezés | FELTERKEPEZES_285 1. pont | backend | Adott: nincs meglévő lekérdezés, ami dátum-tartományra + tetszőleges fiók-részhalmazra adná vissza a tranzakció-sztornókat (REVERSAL típusú sorok, az eredeti tranzakcióval együtt). Amikor: új repository-metódus készül: `companyId + branchIds (opcionális lista, üres-IN sentinel mintával) + dateFrom/dateTo + transactionType=REVERSAL`, `JOIN FETCH originalTransaction` + `originalTransaction.lines` (`List`-alapú visszatérés, nem lapozott, a lapozás+kollekció-fetch ütközés elkerülésére). Akkor: minden REVERSAL-sorhoz visszakapjuk az eredeti és a sztornó bizonylat számát, dátumot/időt, a sztornózó dolgozó nevét, az indoklást (`reversal_reason`), és a valutánkénti sorokat (`currency, banknote_count, huf_value`) az eredeti tranzakcióból. |
| FR-2 | Átadás-oldali sztornó lekérdezés | FELTERKEPEZES_285 2/3. pont | backend | Adott: nincs meglévő lekérdezés, ami minden előtag-típusra és tetszőleges fiók-részhalmazra, dátum-tartományra adná vissza a visszavont átadásokat. Amikor: új repository-metódus készül a `Transfer` táblára: `companyId (from/to fiók cége alapján, nem a nullable company_id mezőből) + branchIds (opcionális, from ÉS to oldalra) + cancelled_at BETWEEN dateFrom/dateTo + is_cancelled=true + status <> REJECTED`; a "ki sztornózott" névfeloldás egy service-oldali batch `workerRepository.findAllById(ids)` + `Map<Long,String>` map-eléssel történik. Akkor: minden visszavont átadáshoz visszakapjuk a bizonylatszámot (`<eredeti>-SZ` jelöléssel), dátumot/időt, a sztornózó dolgozó nevét, az indoklást (`cancellation_reason`), és a valutánkénti sorokat (`transfer_lines`-ból). |
| FR-3 | Ft-érték több valutás átadásnál | Helga döntése, 2026-09-14 | backend | Adott: egyvalutás átadásnál a fej-szintű `huf_value` a teljes forint-értéket tartalmazza, de több valutás (multi-line) átadásnál ez a mező üres. Amikor: minden valuta-sorhoz az átadás napjához tartozó hivatalos MNB elszámoló árfolyamot használjuk (hétvégén/ünnepnapon a legutóbbi elérhető, pl. pénteki árfolyamot) — a FK-112/FK-114-ben már bevezetett `MnbExchangeRateService`/`MnbSettlementRateService` mechanizmussal, dátum szerinti visszafelé-kereséssel. Akkor: minden valuta-sorhoz megjelenik egy kiszámolt Ft-érték (devizaösszeg × az adott napi árfolyam); egyvalutás átadásnál a meglévő, tárolt `huf_value` marad az elsődleges forrás; ha egy adott devizára semmilyen forrásból nem található árfolyam, az a sor "nincs adat" jelzést kap, de ez nem dobja el a teljes választ. |
| FR-4 | Egységes lista, két forrásból | FELTERKEPEZES_285 5. pont | backend | Adott: a két forrás (Tranzakció-sztornó, Átadás-sztornó) különböző entitásokból jön. Amikor: egy közös, `type` diszkriminátoros (`SALE_PURCHASE` / `TRANSFER`) DTO-sorba kerülnek, a service-rétegben egyesítve, dátum/idő szerint csökkenő sorrendbe rendezve (a `HufDaybookService` meglévő egyesítési mintáját követve). Akkor: a lista minden sora egységesen tartalmazza: Iroda, Dátum, Idő, Bizonylatszám (egy sorban, az eredeti és a sztornó bizonylatszámmal együtt), Pénztáros/Értéktáros neve (a sztornózó), Indoklás; soronkénti drill-down: Valutanem, Összeg, Érték. |
| FR-5 | Negyedik fül a felületen | FELTERKEPEZES_284/285 minta | kozponti-client (frontend-react) | Adott: a "Beérkezett adatok" oldalon eddig legfeljebb három fül készül el. Amikor: egy negyedik fül ("Stornózott bizonylatok") kerül a `ReceivedDataOverviewPage.tsx`-re, saját `ReceivedStornoView.tsx` komponensben, a meglévő fülek mintáját követve (nem a közös API-barrelből importál, kézi "Lekérdezés" gombbal, nincs auto-betöltés). Akkor: a fül egy dátum-tól/-ig választót, egy "Vizsgált egység" választót (cég/terület/fiók, a FK-114 mintáját követve), egy listát (Iroda/Dátum/Idő/Bizonylatszám/Pénztáros/Indoklás oszlopokkal), és soronként kinyitható drill-down sorokat mutat (Valutanem/Összeg/Érték); a meglévő fülek tartalma és tesztjei változatlanok maradnak; a táblázat a meglévő alternáló sorszínezést használja (`.data-grid` osztály, FK-050 minta). |

## 5. Adatmodell-érintettség
Nincs új tábla/migráció.

## 6. Kockázatok / TBD
| # | Kérdés / kockázat |
|---|---|
| 1 | A `transfer.company_id` mező nullable és utólag backfill-elt — a tenant-szűrésnél a fiókok (from/to branch) cégét kell nézni, nem a `company_id` mezőt közvetlenül, hogy null-sorok se maradjanak ki a listából. |
| 2 | Nincs index a `transfer.is_cancelled`/`cancelled_at` oszlopokon — nagyobb dátum-tartományra lassabb lehet a lekérdezés; implementáció közben mérlegelendő egy új index. |
| 3 | Ez a fül a "Banki forgalmi adatok" fülhöz (FK-114) hasonlóan az MNB-árfolyam mechanizmusra épül — ha az FK-114 implementációja során ez a mechanizmus módosulna, itt is követnie kell. |

## 7. Végrehajtási utasítás
1. `cd D:\repo\valutavalto-program`, `git checkout -b feature/stornozott-bizonylatok-ful`
2. `git log --all --grep="FK-115"` + `git branch -a | grep -i fk115` — kollízió-ellenőrzés már megtörtént (2026-09-14, tiszta eredmény), de commit előtt ismételd meg.
3. Fázis 1: backend (FR-1 tranzakció-lekérdezés, FR-2 átadás-lekérdezés, FR-3 árfolyam-integráció, FR-4 egyesítés). Fázis 2: frontend (FR-5, negyedik fül).
4. DoD: lint, `mvn verify`, `npm run test`, code review, merge/push/deploy.

---
FR-ek száma: 5 db | Csomagok: backend, kozponti-client
