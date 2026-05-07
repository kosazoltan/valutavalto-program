---
title: Folyamatos tesztelési protokoll (KÖTELEZŐ)
date: 2026-05-04
author: Kósa Zoltán
priority: critical
applyTo: all-ai-agents
status: active
hatalyba_lepes: 2026-05-04
---

# Folyamatos tesztelési protokoll — KÖTELEZŐ

> **2026-05-04 user-direktíva (Kósa Zoltán):**
>
> "Ez az utasítás kötelező érvényű utasítás minden mesterséges intelligencia
> ügynök számára. A repoban végzett fejlesztések során a fejlesztett programhoz
> kötelező folyamatosan teszteket készíteni, a teszteket futtatni, a tesztkészletet
> a program fejlődésével párhuzamosan bővíteni, és minden teszthibát
> haladéktalanul, root cause alapon javítani. Nincs becslés, nincs tippelés,
> nincs elhallgatott vagy figyelmen kívül hagyott teszthiba."

## A protokoll hatálya

Minden mesterséges intelligencia ügynök (Claude, OpenAI Codex, Cursor, Gemini,
Antigravity, GitHub Copilot CLI) **MINDEN fejlesztés, kódmódosítás, hibajavítás,
refaktor, új funkció, tesztírás, build, runtime ellenőrzés és
programfunkcionalitás-validálás során** kötelezően alkalmazni kell.

A fejlesztés nem tekinthető késznek addig, amíg a releváns tesztek el nem
készültek, le nem futottak, és minden ismert teszthiba javítva vagy objektív
blokkolóként dokumentálva nincs.

## A teljes protokoll szöveg

A teljes, gépileg betöltődő always-on rule-t lásd:
[`.cursor/rules/mandatory-continuous-testing-protocol.mdc`](D:\repo\valutavalto-program\.cursor\rules\mandatory-continuous-testing-protocol.mdc)

A CLAUDE.md projekt-szintű utasításokba is be van vezetve:
[`CLAUDE.md` "FOLYAMATOS TESZTELÉSI PROTOKOLL" szekció](D:\repo\valutavalto-program\CLAUDE.md)

## A 4 kötelező lépés (összefoglaló)

1. **Tesztkörnyezet azonosítása** a módosítás előtt — meglévő framework + konvenció.
2. **Célzott tesztek írása + futtatása** kódmódosítás közben:
   - Új funkció → pozitív + negatív esetek
   - Hibajavítás → regressziós teszt amely a hibát javítás előtt elkapná
   - Refaktor → külső viselkedés változatlan
   - UI / workflow → kritikus user-path Playwright/runtime
3. **Tesztcsomag folyamatos bővítése** — új modul/endpoint/parancs/állapot/adatformátum/hibakezelés → új teszt
4. **Tesztek újrafuttatása** minden lényeges módosítás után — szűk → közepes → teljes suite

## Tiltott tesztelési minták

- ❌ Tesztet **skip-elni, kikommentelni, törölni** azért, hogy zöld legyen
- ❌ Assertion **gyengítése** úgy, hogy ne védje a lényegi viselkedést
- ❌ Csak **manuális ránézésre / becslésre** "kész" jelölés futtatható logikára
- ❌ "Működik" állítás **releváns teszt vagy runtime ellenőrzés nélkül**
- ❌ Új funkció **teszt nélkül**, ha objektíven tesztelhető
- ❌ Teszteredmények **összemosása** (külön: sikeres / sikertelen / kihagyott / blokkolt)

## Teszthibák kötelező kezelése

- **Minden failing test** azonnali javítási kötelezettséget jelent
- **Először diagnosztizálni**: teszt? kód? környezet? külső szolgáltatás?
- **Jogos hiba** → **kód javítása**, NEM teszt törlése
- **Hibás/elavult teszt** → teszt javítása úgy, hogy továbbra is **valós viselkedést** védjen
- **Külső blokkoló** (rendszer, jog, env, szolgáltatás) → **pontos hibaok + következő lépés** dokumentálása

## Záró követelmény fejlesztés után

Tényszerű jelentés:

- ✅ milyen **új vagy módosított tesztek** készültek
- ✅ milyen **tesztparancsok** futottak le
- ✅ mely tesztek **sikeresek**
- ✅ volt-e **sikertelen / kihagyott / blokkolt** teszt
- ✅ milyen **hibákat javított** a teszteredmények alapján
- ✅ milyen **funkcionalitást fednek le** az új vagy bővült tesztek

## Konkrét tesztelési konvenciók ebben a repositoryban

### Backend (Java 21 + Spring Boot 4 + JUnit 5 + Mockito)
- `@ExtendWith(MockitoExtension.class)` + `@Mock` + `@InjectMocks`
- AssertJ assertion (`assertThat(...).isEqualTo(...)`)
- `ReflectionTestUtils.setField()` `@Value` injection mockolásához
- Konkrét test: `cd backend && ./mvnw -B test -Dtest=PasswordResetServiceTest`
- Teljes suite: `cd backend && ./mvnw -B test --no-transfer-progress` (1115+ teszt)

### Frontend-react (React 19 + TS + Vitest + Playwright)
- Vitest: `*.test.ts(x)` a `src/` alá, `vi.mock()` + `vi.hoisted()` (TDZ-bizonyos)
- `vi.stubGlobal('fetch', mockFetch)` + `afterEach: vi.unstubAllGlobals()` (NEM `global.fetch = ...`)
- Playwright: `e2e/*.spec.ts`, `page.route('**/api/v1/**', ...)` mock pattern
- Egy teszt: `npx vitest run src/services/api/client.test.ts`
- Teljes: `npm test` + `npm run test:e2e`

### Penztar-client (Electron + Vitest)
- `npx vitest run electron/__tests__/sync-engine.test.ts -t "P1.7"` (egy konkrét teszt-csoport)
- `npm run check:ipc` — IPC contract validation Electron Renderer ↔ Main között

### Production runtime smoke (Hetzner)
- `curl -s https://excvaluta.com/api/v1/auth/bootstrap-status` → 200 + `{"completed":true}`
- `curl -s "https://excvaluta.com/api/v1/public/branches?companyCode=EBC"` → 200 + non-empty
- SPA route smoke: `curl -s -o /dev/null -w "%{http_code}" "https://excvaluta.com/<route>"`

## Megsértés következménye

A protokoll figyelmen kívül hagyása **policy-violation** — a user-direktíva
explicit szövege szerint "nincs becslés, nincs tippelés, nincs elhallgatott vagy
figyelmen kívül hagyott teszthiba". Az AI ügynök TILOS hogy "kész"-nek jelölje
a fejlesztést, ha:

- bármelyik kötelező teszt **nem futott le** vagy **nem zöld**
- új funkció **teszt nélkül** marad (és tesztelhető)
- failing test van **dokumentálatlan blokkoló nélkül**

## Kapcsolódó vault dokumentumok

- [`session-closing-protocol-mandatory.md`](session-closing-protocol-mandatory.md) — 9-lépéses session zárás (a teszt-suite teljes újrafuttatás itt is kötelező)
- [`ai-review-mandate-zero-tolerance.md`](ai-review-mandate-zero-tolerance.md) — minden P0/P1/P2 review-finding kötelező javítás (ezek tipikusan teszt-coverage hiányt is jelölnek)
- [`hallucinacio-megszuntetese.md`](hallucinacio-megszuntetese.md) — research-first + Context7 + TDD (test-driven development)
- [`no-hallucination-lateral-thinking.md`](no-hallucination-lateral-thinking.md) — TILOS találgatás, csak fact-based döntés (a teszt eredmény TÉNY, az "működik" becslés)
