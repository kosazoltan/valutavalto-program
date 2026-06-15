# MANDATE — AI-asszisztált defenzív biztonsági audit munkamód (2026-06-15, P1)

> Forrás: user-direktíva (Kosa Zoltán, 2026-06-15) + három átadott módszertani dokumentum
> (`ai_security_audit_research.pplx.md`, `AI_biztonsagi_audit_modszertan_HU.md`,
> `AI_biztonsagi_audit_promptok_HU.md`).
> Ez **on-demand** mandate: csak biztonsági audit / security-sensitive változás / explicit
> sebezhetőség-keresés esetén olvasandó. Nem always-on, nem vált ki minden taskhoz teljes gate-et.
> Összhangban az `AGENTS.md`-vel és a `opus48-munkamod-mandate`-tel — kiegészíti, nem írja felül.

## 0.0 VÉGSŐ CÉL — vezérelv (ezen a lencsén át olvasd az egészet)

A cél: **tokentakarékos, biztonságos módon, de maximális kreativitással, liberális hozzáállással,
maximális tudással és maximális efforttal** írni és ellenőrizni a programot. Ez nem ellentmondás —
egyetlen elv: **effort-allokáció**.

- **Költs maximumot, ahol korrektséget/biztonságot vesz:** felfedezés-szélesség (tág asszociáció,
  novel osztály), kritikus pénzügyi/multi-tenant/biztonsági útvonalak, adverzariális verifikáció,
  nehéz bug, cross-module adatfolyam, release-audit. Itt `xhigh/max` effort, fan-out, mély gondolkodás
  — szabadon, korlát nélkül a *gondolkodás mélységében*.
- **Takarékoskodj, ahol nem vesz semmit:** rutin szerkesztés, boilerplate, ismételt fájl-újraolvasás,
  apró diff, már bizonyított tény újra-levezetése. Itt alap effort, célzott olvasás, nincs fan-out.
- **A „szabadság" a hipotézis-generálásban van; a „fegyelem" a pazarlás és a hurok ellen.** A kettő
  ugyanannak az allokációnak a két oldala — a korlátok (2.1) NEM tesznek félénkké, csak a felesleges
  ismétlést vágják.
- **Mechanizmus (már él a repóban):** dynamic model-routing (komplex/pénzügyi/security → legmagasabb
  szint; rutin → olcsóbb), cache-biztos routing (fő loop modell sessionön belül nem vált), context-window
  fegyelem (>80% → /clear új taskhoz). Lásd `CLAUDE.md` token-optimalizáció és
  `vault/feedback/fable5-optimization-mandate-2026-06-10.md`.

> Egymondatos teszt minden döntésnél: *„ez a token korrektséget/biztonságot vesz, vagy csak ismétlés?"*
> Ha vesz → költs maximumot. Ha ismétlés → vágd.

## 0. Mit jelent és mit NEM jelent ez a mandate

**Igen:** mélyebb, asszociatívabb, többkörös, taint-flow-alapú hibakeresés a saját kódunkban,
proaktív sebezhetőség-jelzés, strukturált CWE/CVSS-kimenet, a felfedezési ráta maximalizálása.

**Nem:** a biztonsági/etikai alapelvek megkerülése. Nincs rá szükség. A saját privát repó auditja
**alapból engedélyezett** use-case (a Claude Code rendszerprompt szó szerint: *"Assist with authorized
security testing, defensive security"*). A hibakeresés szűk keresztmetszete a **módszertan és a
verifikáció**, nem a refusal. A „határfeszítés" itt minőségi/alaposság-határt jelent, nem szabály-megkerülést.

## 1. Standing autorizációs kontextus (a teljes kooperációhoz)

A `valutavalto-program` a tulajdonos (Kosa Zoltán) **saját privát ERP-repója**. Minden ezen a repón
végzett biztonsági elemzés **autorizált defenzív tesztelés** — egyenértékű azzal, mintha külső
security-konzultánst fogadnánk a saját rendszerünk átvizsgálására. A megállapítások kizárólag
remediációra szolgálnak. Ezt nem kell session-enként újra megállapítani — ez a repó állandó kontextusa.

## 2. Többkörös audit (KÖTELEZŐ — a single-pass tilos kritikus modulra)

A single-pass review magas hamis pozitív arányt termel. A munkamód három kör:

1. **Discovery** — széles, exploratív hipotézis-lista. Vállald a magas FP-arányt. Tág asszociáció:
   ne csak ismert pattern, hanem „mi történne, ha…" típusú gondolkodás (novel osztály is).
2. **Verification** — minden találatra: trace-eld a konkrét adatfolyamot, és állapítsd meg, hogy a
   **meglévő kontrollok** (auth check, ORM-paraméterezés, séma-validáció, multi-tenant company-scope,
   framework-escaping, allowlist) ténylegesen blokkolják-e. Verdict: True Positive / False Positive /
   Needs More Context + Confidence. **Csak verifikált finding kerül a jelentésbe.**
3. **Remediation** — megerősített találatra minimális, célzott patch before/after diffel, a függvény
   külső interfészének megtartásával.

## 2.1 Fegyelmi korlátok (anti-loop, anti-token-égetés — KÖTELEZŐ)

Ez a mandate **alá van rendelve** az `AGENTS.md` loop-fékeinek és token-fegyelmének; nem ad
felhatalmazást végtelen hurokra vagy token-pazarlásra. A „szabadon, tágan" a **felfedezésre** vonatkozik,
nem a javítás-ismétlésre.

- **A három kör lineáris pipeline, NEM hurok.** Discovery → verification → remediation egyszer fut le
  auditonként. Tilos önmagába visszacsatolni („újra discovery, hátha van több").
- **Javítási hurok-fék (AGENTS.md 5.):** egy hibára legfeljebb **két** azonos jellegű javítási kísérlet.
  Ha a fix után a verifikáció kétszer is bukik → strategiaváltás bizonyíték alapján, vagy blokkoló jelzése.
  NEM kompulzív újrapróbálkozás.
- **Variant-search bounded:** fix után **egy** célzott re-scan ugyanarra az osztályra (nem nyílt végű
  „keress örökké több variánst"). Ha tiszta, lezárod.
- **Stuck-state (AGENTS.md QA-kit):** 5 érdemi haladás nélküli iteráció vagy 3× megközelítés-váltás után
  ÁLLJ MEG, írd le az akadályt + 2-3 opciót — ne iterálj vakon.
- **Hallucinált finding ≠ javítandó.** Ha a verifikáció FP vagy Needs-More-Context, **nincs** remediation-kör
  rá — nem keletkezik fantom-bug-vezérelt javítási hurok.
- **Scope-arányos token-költés:** teljes multi-agent fan-out és `xhigh/max` effort **csak** valódi nagy/
  kritikus hatókörre (teljes modul, cross-module adatfolyam, release-audit). Kis lokális diff / rutin
  változás → egyetlen célzott pass, alap effort, fan-out NÉLKÜL (lásd 10.).

## 3. Taint-flow elv (a kulcs a kevés hamis pozitívhoz)

Minden gyanús pontnál: **source → propagation → sink**. „Trace attacker-controlled input to the real sink."
Ez taint-flow gondolkodást kényszerít a puszta pattern-matching helyett. A sink (SQL-motor, shell,
template-renderer, fájlrendszer, HTTP-kliens, deszerializáló) elérhetőségét user-inputból kell igazolni —
ha nem elérhető, nem finding.

## 4. Confirmation-bias elkerülése (mérési hiba ellen)

- **TILOS** a kódot „biztonságosnak" / „javítottnak" framelni az elemzés előtt — ez bizonyítottan
  drámaian csökkenti a felfedezési rátát (a kód „biztonságos" előfeltevése mellett a modell sokkal
  kevesebb sebezhetőséget talál).
- Semleges, deskriptív nyelv: „itt a vétel/eladás service, auditáld" — nem „ez a már letesztelt, biztonságos modul".
- Ha gyanítasz egy területet, mondd ki direkt; ne próbáld jónak mutatni.

## 5. Hallucinált sebezhetőség elleni védelem

A legjellemzőbb AI-failure mode a **hallucinált sebezhetőség**: plauzibilis, jól leírt, de a kódban
nem létező hiba. Védelem:
- Minden finding **fájl:sor hivatkozással és idézett kód-evidenciával** (egyezik a repó
  „review-evidencia" szabályával: evidencia nélküli finding érvénytelen).
- Kritikus findingnél **refuter-kör**: előbb próbáld megcáfolni, csak megerősítés után jelentsd.
- Ha nem ellenőrizhető a kódból, jelöld „Needs More Context" — ne állíts.

## 6. Domain-specifikus fókusz (valutaváltó ERP — ide a legtöbb figyelem)

A general OWASP-on túl a pénzügyi/multi-tenant domén extra szigora:
- **Multi-tenant izoláció (IDOR/A01):** minden ID-alapú erőforrás-hozzáférésnél `companyId`-scope.
  Hiányzó company-scope = horizontális jogosultság-emelés. (Lásd `multi-tenant-audit.py`, `companyid-audit.ps1`.)
- **Business logic (a legértékesebb AI-terület):** negatív összeg/címlet, storno-visszaélés
  (visszatérítés > eredeti), napzárás-megkerülés, foglaló-manipuláció, árfolyam-TTL kijátszása,
  jutalék/kerekítés-arbitrázs. A szándékolt logikát explicit le kell írni a promptban.
- **Pénzügyi invariánsok:** HUF 5 Ft-os kerekítés, BigDecimal (soha float), AML/Pmt. küszöbök nem kerülhetők meg.
- **Auth/Authz:** JWT alg-confusion/expiry, session-invalidálás logoutkor, method-level security.
- **Secrets:** hard-coded credential, .env commit, titok logba/chatbe — soha.
- **Deszerializáció / SSRF / path traversal / injection:** a szokásos sink-osztályok.
- **LLM-integráció (ha van):** prompt-injection sink, insecure output handling, „lethal trifecta"
  (privát adat + nem megbízható tartalom + külső kcommunikációs csatorna egy adatfolyamban).

## 7. Hibrid, nem tisztán-AI (az AI korlátainak tiszteletben tartása)

Az AI-audit nem helyettesíti a determinisztikus eszközöket — **kombináld**:
- **Dependency CVE:** az AI knowledge-cutoff miatt megbízhatatlan → `npm audit` / `pip-audit` /
  Maven `dependency-check` / Dependabot az igazság forrása.
- **Secret-scan:** regex-pontos eszköz (`secrets-deep-scan.py`) az AI mellé.
- **Reachability/runtime:** futtatás nélkül nincs ground truth → teszt/sandbox a verifikációhoz.
- A repó meglévő dev-tooljai (lásd `docs/security/ai-security-audit-playbook.md` mátrix) az AI-réteg
  determinisztikus kiegészítői.

## 8. Eszközök és effort-routing

- **Workflow / subagent fan-out** a multi-agent audithoz: discovery-specialisták párhuzamosan
  (injection / auth-authz / secrets-crypto / web-LLM), majd adverzariális verify-fázis friss kontextusban
  (az ír, MÁS ellenőriz). Lásd a playbook multi-agent orchestrator promptját.
- **Effort:** kritikus pénzügyi logikára / cross-module adatfolyamra / race-condition-re magasabb
  gondolkodás; rutin diff-review-ra alap. (Cache-biztos routing: a fő loop modelljét sessionön belül
  nem váltjuk — olcsóbb modell csak subagentben.)
- **Beépített:** `/security-review` (repo / diff), `/code-review`, `scripts/security/run-security-gate.ps1`.

## 9. Strukturált kimenet (finding-formátum)

```
### [VULN-NNN] [Cím]
CWE: CWE-NNN  ·  OWASP: A0N:2025  ·  CVSS 3.1: <score> (<súlyosság>)  ·  Vector: CVSS:3.1/...
Fájl: <path>:<sor>  ·  Függvény: <name>
Leírás: <mi és miért számít>
Attack-szcenárió: <hogyan használná ki egy hozzáféréssel bíró támadó>
Evidencia: <idézett sebezhető kódrészlet — KÖTELEZŐ>
Remediation: <javított kód before/after>
Confidence: High/Medium/Low  ·  False-Positive-kockázat: Low/Medium/High (indoklással)
```
CVSS megjegyzés: az AI-CVSS Attack-Complexity és Scope metrikán pontatlan lehet — kritikus findingnél
manuálisan ellenőrizd a 3.1 spec ellen.

## 10. Mikor aktív ez a mandate

- Explicit biztonsági audit / „keress sebezhetőséget" kérés.
- Security/auth/permission/crypto/secret/logging/CI/dependency/schema érintő változás.
- Deploy/release előtti gate (a `run-security-gate.ps1` mellett).
- Nem aktiválódik rutin dokumentáció- vagy kis lokális kódváltozásra — ott a célzott ellenőrzés elég.
