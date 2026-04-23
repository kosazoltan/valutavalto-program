# AI_CONTRACT.md - Kemény tiltások + plafonok minden AI coding agentnek

> **Hatály:** Minden Anthropic + OpenAI + Gemini coding agent (AGENTS.md szerint)
> **Jelleg:** HARD LIMITS. Ha barmelyik pont megserul, az agent NEM minositheti a feladatot keszkent. Humán review kotelezo.

## 1. PR meret plafon

- **Max 300 LOC** (hozzaadas + torolt) per PR
- **Max 5 fajl** per PR
- **Ha tobb:** bontani kell kisebb PR-ekbe. Ez NEM ajanlas, ez kovetelmeny.

Kivetel: generated files (lockfile, snapshot.json), csak ha egyertelműen dokumentalt.

## 2. Teszt-integritas TILTASOK

- TILOS bukó tesztet kikommentelni
- TILOS `@Disabled` / `skip` / `xfail` indok nelkul
- TILOS coverage-kuszob csokkentese a gate atlepese erdekeben
- TILOS CI config gyengitese (required check torles, fail-on severity emelese)
- TILOS CI environment modositas az uzleti kod PR-jevel egy commitban

Bukó teszt eseten ELSO FELTETELEZES: az implementacio hibas (nem a teszt).

## 3. Git hygiene TILTASOK

- TILOS `git push origin main` (vagy barmely vedett branch-re)
- TILOS `git push --force` vedett ag-ra
- TILOS `--no-verify` flag git commit/push eseten
- TILOS `--no-gpg-sign` (ha a repo required signed commits-et hasznal)
- TILOS branch protection / ruleset gyengitese uzleti PR-ben

## 4. Security KRITIKUS tiltasok

Az alabbiak BARMELYIKE a kodban -> commit TILTVA + human review kotelezo:

- hard-coded secret (.env, API key, JWT titok, DB password)
- SQL string-konkat user inputbol
- `eval`, `Function`, `unsafe deserialization`
- `shell=True` / shell string-konkat user inputbol
- `Runtime.exec(String)` (Java) / `subprocess.Popen(shell=True)`
- path traversal lehetoseg (`../`, user-path filesystem API-ban validacio nelkul)
- nema `catch(Exception e){}` (Java) / `except: pass` (Python) - legalabb log
- hamis mock adat production valaszkent
- nem ellenorzott uj csomag (registry + license + Dependabot + dependency-review nelkul)

## 5. GitHub Actions hardening KOTELEZO

- Top-level `permissions: contents: read` (vagy `read-all`)
- Iras csak job-szinten, indokoltan
- Third-party action CSAK teljes commit SHA-val (nem `@v1`, nem `@main`)
- `pull_request_target` + fork checkout TILOS (kiveve explicit security-approved workflow)
- Untrusted context (`github.event.pull_request.title`, `github.event.issue.body`) env-en keresztul, NEM kozvetlenul `run:` scriptben

## 6. Lockfile / registry / hash integritas KOTELEZO

- npm: `npm ci` (NEM `npm install`)
- pnpm: `pnpm install --frozen-lockfile`
- Python: `pip install --require-hashes`
- Lockfile nelkuli dependency modositas -> BLOCK
- Lockfile/manifest elteres -> BLOCK
- HTTP registry VAGY ismeretlen registry host -> BLOCK

## 7. Deploy artifact kotelezo bizonyitas

Release/deploy elott kotelezo:

- SBOM generalt (SPDX vagy CycloneDX)
- Artifact attestation (`gh attestation verify`)
- Container scan high/critical nelkul (ha image deploy)
- Image alairva (ha image deploy)
- Production environment required reviewer approval
- Release artifact SHA = checks zold SHA

## 8. AI review jelzes kezeles

- Codex/Sourcery/Dependabot/CodeQL jelzes NEM tanacs, KOTELEZO input
- Minden jelzesre 3 opcio:
  - javitani
  - bizonyitékkal false positive-nak jelolni (WHY)
  - human joavahagyast kerni dismiss elott
- `@codex dismiss` / `@sourcery-ai dismiss` AGENT altal TILOS (csak human)

## 9. Hamis 'kész' allapot TILTAS

- "Tudtommal mukodik" -> TILOS
- "Szerintem kesz" -> TILOS
- "Ralatasom szerint" -> TILOS
- "Valoszinuleg" -> TILOS
- "Majd a CI kiszuri" -> TILOS (elobb lokalisan)
- "Sikeres a forditas" != deploy-ready
- Minden allapot GEPILEG BIZONYITOTT legyen

## 10. Eltereshez BLOCKED allapot

Ha barmelyik kovetelmeny nem teljesitheto, az agent valasza:
`
BLOCKED: <mi nem teljesitheto, miert, mi a kovetkezo lepes>
`
Nem lehet 'kész' deklaracio.

## 11. Modellfuggetlen hataly

Ez a szerzodes vonatkozik mindenre:
- Minden Claude model (Opus, Sonnet, Haiku, jovobeli)
- Minden OpenAI (GPT, Codex, o-series, ChatGPT agent)
- Minden Google Gemini (Code Assist, CLI, Jules)
- Minden vendor tool mode, function calling, MCP, CLI integracio

Modell-nev alapjan NINCS mentesseg.