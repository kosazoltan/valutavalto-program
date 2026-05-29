# Fejlesztési irány-audit — konkrét utasítás (Valutaváltó ERP)

> **Hatály:** minden AI coding agent (Claude / Codex / Gemini / Copilot) ezen a repón.
> **Precedence:** [AGENTS.md](AGENTS.md) > [AI_CONSTITUTION.md](AI_CONSTITUTION.md) > [CLAUDE.md](CLAUDE.md) > ez a fájl.
> Ez a dokumentum NEM gyengíti a fentieket; a hordozható elvi auditot fordítja le
> **konkrét, repo-specifikus** lépésekre, parancsokra és bizonyíték-forrásokra.
> **Cél:** tényalapú, korszerű, magas kódminőségű fejlesztés — hazugság-, halucináció-
> és lustaság-mentesen, felesleges tokenégetés nélkül.

---

## 0. Mielőtt bármihez hozzányúlsz (session-start)

1. Olvasd a kötelező sorrendet a [CLAUDE.md](CLAUDE.md) „SESSION-START" pontja szerint
   (`vault/elvi/vv-elvi-mirror.md` → `vault/feedback/_active_mandates.md` →
   [AI_CONSTITUTION.md](AI_CONSTITUTION.md) → [CLAUDE.md](CLAUDE.md) → legfrissebb `vault/sessions/`).
2. Production health-check (kötelező, mielőtt bármit „eltörtnek" nyilvánítasz):
   - `curl -s https://excvaluta.com/api/v1/auth/bootstrap-status` (≥200)
   - `curl -s "https://excvaluta.com/api/v1/public/branches?companyCode=EBC"` (non-empty)
3. Ha DOWN → előbb helyreállítás, csak utána fejlesztés.

---

## 1. Tényalapúság — bizonyíték minden állításhoz

- Minden állítás mellé: **fájlútvonal + sor + szó szerinti idézet**
  (pl. `backend/src/main/java/hu/puzzleir/valuta/service/RateService.java#L88`).
- „Kész", „működik", „javítva" csak **gépileg ellenőrzött** bizonyítékkal mondható ki.
- Repo-tény (kód, Flyway-migráció, `git log`, [AI_CONSTITUTION.md](AI_CONSTITUTION.md))
  **mindig erősebb**, mint az AI emlékezet. Konfliktusnál a repo nyer.
- Bizonyíték nélkül a státusz: **„nem igazolt"** — soha nem „kész".

## 2. Nulla halucináció — konkrét tilalmak

Soha ne találj ki: fájlnevet, entitás-/tábla-/oszlopnevet, Flyway-verziószámot
(`V{N}__*.sql`), `error_code`-ot (`VV-<KAT>-<3jegy>`), tesztnevet, CI-státuszt,
PR-számot vagy AML/Pmt. jogszabályi részletet.
- Entitásnév kétségnél: keresd ki `backend/src/main/java/hu/puzzleir/valuta/entity/`-ben.
- Hibakód kétségnél: nézd meg `packages/shared-logging/error-codes.yaml`-t — **új hibatípus
  esetén előbb ide kerül a kód** (`ai_fix_hint` + `user_impact`), csak utána a hívás.
- AML küszöb: 100k (SIMPLIFIED) / 300k (FULL) — ne emlékezetből idézd, ellenőrizd a kódban.

## 3. Nulla lustaság — futtass, mérj, igazolj

- Ne „feltételezem, hogy működik". Futtasd:
  - Backend: `cd backend && ./mvnw test`
  - Frontend: `cd frontend-react && npm test`
  - Kliens: `cd penztar-client && npm test`
- Részleges siker után **ne állj meg**, amíg van bizonyítható hiba, zajos diff,
  bukott teszt vagy nyitott validáció (lásd folyamatos root-cause hurok, §8).
- CI/AI-review-t **vissza kell olvasni** push után (§7) — passzív email-várás tilos.

## 4. Research-first — bizonyított root cause, minimális fix

Sorrend hibajavításnál / új modulnál:
1. **Forrás**: érintett kód + hivatalos doksi + releváns GitHub issue/discussion.
   Context7 / library-docs MCP kötelező, ha az adott technológia doksija elérhető rajta
   (kulcs: `D:\openclaw\.openclaw\.env` → `CONTEXT7_API_KEY`; titkot **soha** chatbe/commitba).
2. **Diagnózis**: bizonyított root cause (nem tünet).
3. **Minimális célzott javítás**: logikai blokk rendberakása, nem soronkénti toldozás.
4. **Ellenőrzés**: lint → typecheck → test → build → runtime.
- Próba-szerencse, ismételt találgatás **tilos**.

## 5. Alügynök-delegálás és párhuzamosítás

- Ha egy keresés/felfedezés nem biztos 1–2 lépésen belül → add **read-only alügynöknek**
  (Explore), és csak a tömör tény-eredményt hozd vissza (a fő kontextus maradjon olcsó).
- Független read-only vizsgálatokat futtass **párhuzamosan**.
- `semantic_search`-öt **ne** futtasd párhuzamosan; a többi olvasó eszközt igen.

## 6. Legolcsóbb elég jó eszköz

| Cél | Eszköz |
|---|---|
| Pontos szöveg/regex | `grep_search` (nem `cat`/`grep`/`rg` terminálban) |
| Fájlnév/útvonal-minta | `file_search` |
| Nagy összefüggő olvasás | `read_file` nagy tartományban, kevés hívással |
| Szimbólum-hivatkozások | nyelvi szerver (`vscode_listCodeUsages`) |
| Független műveletek | egy blokkban, párhuzamosan |

Windows: PowerShell-native parancsok (`Select-Object`, nem `head`/`tail`).

## 7. Magas kódminőség — repo-specifikus szabályok

- **Multi-tenant:** MINDEN lekérdezés `companyId`-ra szűr
  (`SecurityUtils.getCurrentCompanyId()`). Hiányzó szűrés = **IDOR**. Single-id load
  után tulajdonos-ellenőrzés (tenant-idegen → 404, id-enumeráció ellen).
- **OSIV=false:** ha mapper lazy asszociációt olvas a controller-rétegben →
  `LazyInitializationException` 500. Fix: `JOIN FETCH` a repo-query-ben VAGY
  `Hibernate.initialize(...)` a `@Transactional` metóduson belül.
- **Determinisztikus pénzügy (nincs float):** HUF 5 Ft-os kerekítés mindig
  (`roundHuf` / `HungarianRounding`; kliens: `roundFin`).
- **AML/Pmt.:** ellenőrzés tranzakció **előtt**; árfolyam 24h TTL — lejárt rátával nincs tranzakció.
- **Típusbiztonság:** backend Java 21 strict, frontend TS `strict`; határon **runtime-validáció** (Zod).
- **Idempotens sync:** Electron local-first SQLite + outbox; duplikátum-mentes újrajátszás.
- **Audit + log:** minden `LOG.error()`/`vvLogger.error()` kötelező `error_code`-dal;
  `audit_log` immutable (UPDATE/DELETE tiltott triggerrel).
- **Security/OWASP:** `@PreAuthorize` minden védett controlleren; CORS nem wildcard;
  titok soha kódba/logba/commitba; tiltólista a [AGENTS.md](AGENTS.md) 3. pontjában.
- **Over-engineering tilos:** csak a kért/szükséges változás — nincs spekulatív absztrakció,
  nincs nem kért docstring/komment/refaktor a nem érintett kódon.

## 8. Folyamatos root-cause hurok

`forrás → diagnózis → minimális fix → lint/typecheck/test/build/run → feedback-hibák javítása`
→ ismételd **teljes zöld állapotig**. Régi/scope-on kívüli hibát, amit közben találsz,
azonnal javíts (kivéve több-napos refaktor → GitHub issue + kód-komment).

## 9. Token-ökonómia

- Ne írd ugyanazt több helyre; egy forrás kézzel írt, a többi generált.
- **Ne nyiss tiszta könyvelő/state/kozmetika PR-t.** Fókusz a kritikus útra.
- Rövid státusz, konkrét következő lépés — felesleges ismétlés nélkül.

---

## Definition of Done (minden szelet)

- [ ] Tényleges követelmény megvalósítva (nem közelítés), bizonyítékkal (út + sor + idézet).
- [ ] Unit + integrációs teszt **zöld**; baseline nem csökken (teszt-skip/assertion-gyengítés tilos).
- [ ] Jogosultság (`@PreAuthorize` + `companyId`) + audit (`error_code`) + (ahol releváns)
      idempotens sync bizonyíték megvan.
- [ ] Lint/typecheck/build zöld; lokális CI-paritás lefutott.
- [ ] Push után CI + bot-review (Codex/Sourcery/Copilot) zöld, VAGY minden P0/P1/P2
      indokoltan lezárva a `vault/`-ban.
- [ ] Verzió-szinkron OK telepítő-buildnél (`node scripts/check-version-sync.mjs`).
- [ ] Állapot/ledger frissítés generált vagy minimális — nincs felesleges PR.

---

## Kötelező parancsok (szállítás előtt, sorrendben)

```bash
npm run agent:guard                  # zero-trust env/secret/decision guard
npm run self-check:before-lint       # four-area align + guard + CI-digest (report)
# ... lint / typecheck / test / build a megfelelő almappákban ...
npm run self-check:before-push       # pre-push quality gate
git push                             # CSAK feature branch-re, SOHA main-re
pwsh scripts/github-signal-check.ps1 <PR>   # CI + Codex + Sourcery + Dependabot + CodeQL + secret-scan
npm run ci:errors -- --pr <PR>       # automatikus CI-hiba digest
npm run self-check:before-merge      # guard + CI-digest fail-on-findings
# deploy előtt:
npm run self-check:before-deploy
pwsh scripts/security/run-security-gate.ps1  # FAILED/BLOCKED → deploy tiltott
```

Döntési pont (workflow-/biztonsági szabály változás) rögzítése:
`npm run agent:archive -- --summary "..."`.

---

## Önellenőrző hurok (minden szállítás előtt)

- **Tény-check:** van-e útvonal + sor + idézet minden állításhoz?
- **Halucináció-check:** minden fájlnév/szám/entitás/`error_code`/PR-szám/státusz valódi és ellenőrzött?
- **Lustaság-check:** lefutott test/build/lint és **visszaolvastad** a CI-t (§7)?
- **Minőség-check:** teljesül a Definition of Done?
- **Token-check:** legolcsóbb elég jó eszköz, felesleges PR nélkül?

Ha bármelyik check elbukik: **ne jelöld késznek** — javíts, vagy jelezd a blokkolót
**pontos hibaüzenettel** (kiragadott sor helyett a teljes hiba-blokk).
