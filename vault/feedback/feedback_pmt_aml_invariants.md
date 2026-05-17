# B.1 — Pmt. (AML) invariáns mandate

**Hatály:** always, P0
**Forrás:** `claude-code-korrekcios-mandate-2026-05-17.md` 1.1 szakasz
**Jogszabály:** 2017. évi LIII. tv. (pénzmosás és a terrorizmus finanszírozása megelőzéséről és megakadályozásáról)

## Tartalom

A Pmt. küszöbértékei **backend-szinten enforced** invariánsok (jelenleg `AmlService.java` konstansokként, jövőben `@Value`-ként — lásd "Implementációs hivatkozás" lent). Soha NEM szabad:

1. A **100 000 HUF** identifikáció-küszöböt frontend-only validációvá gyengíteni.
2. A **300 000 HUF** PEP + saját-név küszöböt opcionálissá tenni.
3. A **napi aggregáció** szabályt (1 ügyfél / 1 nap > 100k HUF → visszamenőleges identification) kikapcsolni.
4. A **sanction-list** ellenőrzést cache-only módban végrehajtani backend revalidáció nélkül.
5. A **SAR** (suspicious activity report) flag-et automatikus → manuálissá tenni.

## Kötelező regressziós tesztek

```
backend/.../AmlThresholdTest.java
backend/.../PepDeclarationTest.java
backend/.../SanctionListEnforcementTest.java
backend/.../DailyAggregationTest.java
backend/.../SarAutoFlagTest.java
```

## Escalation

Ha bármelyik P0/P1 finding ezt a területet érinti, **automatikus escalation a felhasználónak (Kósa Zoltán) a merge ELŐTT**, NEM után.

## 9-fázisú zárási protokoll 9. lépésében

> "Pmt. invariáns sértetlen — `AmlThresholdTest` + 4 további zöld."

## Implementációs hivatkozás (jelen állapot vs. cél)

**Jelenlegi állapot (2026-05-17, audit findings alapján):**
- A backend `AmlService.java`-ban a küszöbök **konstansok** (`SIMPLIFIED_IDENTIFICATION_LIMIT = 100000`, `IDENTIFICATION_LIMIT = ...`), NEM `@Value` config.
- A frontend csak UI-hint, a backend mindig revalidál — **ez már teljesül**.

**Cél (jövő iteráció):**
- A konstansokat `@Value`-vé alakítani (`aml.identification.threshold=100000`, `aml.pep.threshold=300000`) hogy env-szinten override-olható legyen test scenarios + jövőbeli jogszabály-változás miatt.
- **Status:** PARTIAL — a backend-szintű enforcement IMPLEMENTED, a config-szintű paraméterizálás MISSING.

A jelen mandate **NEM** a `@Value` migrációt kéri P0-ként — a hard-coded konstans backend-szinten enforced, ami megfelel a Pmt. követelménynek. A `@Value` migráció P2 (kényelmi javítás), külön PR-ben.
