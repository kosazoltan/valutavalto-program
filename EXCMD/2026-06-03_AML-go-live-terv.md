# 2026-06-03 — AML/CFT GO-LIVE implementációs terv (EBC ZRT pénzmosási szabályzat alapján)

Forrás (kiolvasva, tényalapú): EBC ZRT „PÉNZMOSÁS- ÉS TERRORIZMUSFINANSZÍROZÁS-MEGELŐZÉSI
SZABÁLYZAT" (14/2025. (VI. 16.) MNB rendelet + Pmt. 2017. LIII. + Kit. 2017. LII. + 21/2017. NGM),
hatályos 2026-05-25, valamint a „Belső kockázatértékelés" és az MNB-segédlet (2025-01-01).

> **Cél:** a compliance-flag-ek élesítése (a user direktívája: „élesítsd teljesen") + a hiányzó
> kód-bekötések, KIZÁRÓLAG a szabályzat tényei alapján. A core AML-flow változások compliance-
> kritikusak → gondos, tesztelt, hívónként verifikált bevezetés (NEM menet-végi rohanás).

## ✅ KÉSZ (ebben a körben)

- **50M Ft forrás-igazolás GO-LIVE** (#1017): a pénztáros felület gyűjti a forrás-dokumentum típusát
  (közjegyző/ügyvéd magánokirat / max. 3 éves banki szlip; két tanú TILOS) + dátumát ≥50M Ft-nál;
  V291 migráció élesíti az `AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT` flag-et. (Szabályzat V.2.5 b), V.2.8.)

## A szabályzat kód-releváns szabályai → kód-helyek (követő munka)

### 1) FATF magas-kockázatú harmadik ország tier-akció a kassza-flow-ban — [L, compliance-kritikus]
**Szabály (V.2.6 c)/d), V.2.7 d), IX/X):** a `FatfCountryRiskService` (LIST_VERSION FZS-9/2024) kész:
TIER_1A (ellenintézkedés — pl. KNDK/Irán), TIER_1B (fokozott átvilágítás), TIER_2 (fokozott monitoring).
DE az `AmlService.checkTransaction(huf, custId, name, docNo, currency)` szignatúra NEM kap országot,
így a tier sosem dől el a tranzakciónál (`AmlService.java:92`). A `CustomerPanel` sem hívja a `screen`-t.
**Teendő:**
- `AmlService.checkTransaction` bővítése `nationality`/`countryCode` paraméterrel; MINDEN hívó frissítése
  (`TransactionService` single buy/sell `:286-288`, multi-line `helper.performAmlCheck`, `TransactionConversionService`, `TransactionOperationHelper`).
- Tier→akció: TIER_1A → vezetői jóváhagyás KÖTELEZŐ (V.2.6 c); TIER_1B → EDD + SOF bekérés;
  **≥5.000.000 Ft** magas-kockázatú harmadik ország → megerősített eljárás + vezetői jóváhagyás (V.2.6 d / V.2.7 d).
- Flag mögött (`AML_FATF_TIER_ENFORCEMENT`, default false → seed true a bekötés + UI után).
- FE: `CustomerPanel` jelenítse meg a tier-badge-et (a `SanctionPage`-en már van minta).

### 2) SOF/SOW 10M Ft / 7 nap kumulált trigger — [M]
**Szabály (V.2.8 A.1):** ha ugyanazon ügyfél 7 naptári napon belüli összesített forgalma (küldés+fogadás)
≥10.000.000 Ft, ÉS ≥2 különböző küldőtől/kedvezményezett felé → kötelező SOF dokumentált bekérés.
**Teendő:** `TransactionRepository` 7-napos kumulált összeg + distinct-küldő/kedvezményezett lekérdezés
ügyfélre; ha trigger → a forrás-dokumentum bekérés kötelező (a meglévő `sourceOfFundsBlockReason`-höz
hasonló gate, de a tágabb elfogadható doc-listával: jövedelemigazolás/NAV/bankszámlakivonat/adásvételi/
öröklési/ajándékozási/vállalkozói/nyugdíj — V.2.8 B.2). Flag mögött.

### 3) Vezetői jóváhagyás workflow (Pmt. 14/A. § (4), V.2.6) — [L]
**Szabály:** írásos felsővezetői jóváhagyás KÖTELEZŐ: a) PEP; b) megerősített eljárás alatti új megbízás;
c) magas-kockázatú harmadik ország; d) ≥5M Ft stratégiai-hiányosságú ország; e) trust; f) átláthatatlan/
stróman; g) Pmt. 30.§(1) bejelentett ügyfél 1 éven belül. Jóváhagyók: Kósa Zoltán ügyvezető (elsődleges),
Fabulya Zsuzsa belső ellenőr (helyettes). Az engedélyező NEVE rögzítendő a tranzakción; megőrzés 8 év.
**Teendő:** `TransactionApproval` entity + migráció (a b3-engedelyezes FR-AUTH-01..06 is ezt kéri) +
supervisor-jóváhagyó UI + a `performAmlCheck` gate, ami a fenti esetekben jóváhagyást kér (a `StornoApproval`
4-szem-elv mintájára). Összevonható a b3 ApprovalItems/engedélykérő-adatlappal.

### 4) Megerősített eljárás (enhanced) követés — [M]
**Szabály (V.2.7):** a) ≥50M Ft egyedi → 1 évig; b) ≥100M Ft havi készpénzforgalom → 1 évig; c) Pmt.30.§(1)
bejelentett → 1 évig; d) ≥5M magas-kockázatú harmadik ország; e) stróman; f) pass-through (24-72h); g)
profil-kiugrás. Az ügylet-elemzés 30 munkanapon belül írásban, megőrzés 8 év.
**Teendő:** `enhanced_due_diligence` állapot az ügyfélen (1-éves ablakok), a meglévő `customer.highRiskFlag`
bővítése; a havi 100M kumulált + profil-kiugrás detektálás (a `AmlService.checkAllThresholds` bővítése).

### 5) Szankció-szűrés finomhangolás — [S, ELLENŐRIZNI a szabályzat ellen]
A `b8-terrorlista` SPEC ALIAS=0.9/PARTIAL=0.8 pontszámot ír, a kód 0.5/0.7-et használ
(`SanctionScreeningService.java:42-43`). **A változtatás compliance-érzékeny (auto-block arány)** —
a PM-szabályzat X. fejezete (szűrő-monitoring) a konkrét küszöböt nem rögzíti, ezért a 0.9/0.8-ra
állítás CSAK akkor, ha a b8-spec az autoritatív; egyébként üzleti megerősítés (megfelelési vezető).
A stale-küszöb (kód 7 nap vs b8-spec 30 nap) szintén üzleti döntés (a 7 szigorúbb).

### 6) Western Union pénzátutalás-kísérő adatok (V.5) — [M, ha a WU-modul éles]
**Szabály (Pmt., 2015/847 EU rendelet):** a pénzátutalást kísérő adatok (küldő/kedvezményezett) teljes
köre. A `WesternUnionPage` megvan; a kísérő-adat teljesség és a hiányos-adat-blokk ellenőrizendő.

## Bevezetési sorrend (compliance-biztos)
1. ✅ 50M forrás-igazolás (#1017) — kész.
2. FATF tier-bekötés (1) — szignatúra-bővítés + hívók + tier-akció + teszt, flag mögött → seed true.
3. Vezetői jóváhagyás workflow (3) — a FATF/PEP/5M esetekhez (a b3 engedély-adatlappal közös).
4. SOF 10M/7nap (2) + enhanced követés (4).
5. Szankció-pontszám (5) — megfelelési vezetői megerősítés után.

> Minden lépés: feature-flag mögött vezetjük be, teljes test-suite + adverzariális self-review,
> majd a flag élesítése migrációval — a jelenlegi `AML_SOURCE_OF_FUNDS_50M_ENFORCEMENT` mintát követve.
