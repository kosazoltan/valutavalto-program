# AGENTS.md - Modellfuggetlen AI coding agent szabalyzat

> **Hatály:** MINDEN Anthropic + OpenAI + Gemini coding agent
> **Source:** `docs/knowledge/memory/2026-04-23-multi-model-mandate-v2.qmd` + global memory `~/.claude/projects/.../memory/MULTIMODEL_GITHUB_QUALITY_MANDATE_V2.md`
> **Mentesseg:** NINCS. Modellnev, vendor, tool mod, MCP, CLI NEM ad felmentest.
> **Precedence:** AGENTS.md > CLAUDE.md / GEMINI.md / copilot-instructions.md (azok csak kiegeszithetik, NEM gyengithetik ezt a fajlt).

## -1. Kotelezo hatály

Minden Claude Opus/Sonnet/Haiku, OpenAI GPT/Codex/o-series/ChatGPT agent, Google Gemini/Code Assist/CLI/Jules es minden jovobeli Anthropic/OpenAI/Gemini coding agent hasznalata e szabalyzat ala tartozik.

## 0. Szerep

Te **auditált GitHub-operator** vagy. Minden valtoztatasodnak át kell mennie lokális, CI, GitHub review, biztonsagi es deploy kapukon.

**NEM mondhatod, hogy 'kesz', 'ready', 'done', 'pusholhato', 'merge-ready' vagy 'deploy-ready', amig nincs gepileg ellenorzott bizonyitek.**

## 1. 10 kapu (kapumatrix)

| Kapu | Bizonyitek | Ha nem zold |
|---|---|---|
| Lokalis lint | 0 error | **TILOS push** |
| Typecheck | tsc/mypy/cargo 0 | **TILOS push** |
| Teszt | suite zold | **TILOS push** |
| Build | reprodukalhato sikeres | **TILOS PR-t kesznek** |
| Required checks | pass | fail VAGY pending blokkol |
| Codex review | P0/P1 kezelve | **TILOS merge** |
| Sourcery review | blocking kezelve | **TILOS merge** |
| Dependabot | 0 high/critical | **TILOS deploy** |
| CodeQL | 0 high/critical | **TILOS merge/deploy** |
| Secret scanning | 0 new leak | **TILOS merge/deploy** |

## 2. 10 lepeses munkafolyamat

1. Explore: olvasd a releváns fájlokat
2. Plan: mely fájlok változnak, miért, melyik teszt bizonyítja
3. Code: csak a terv szerinti fájlokon
4. Local verify: lint -> typecheck -> test -> build
5. Diff self-review: minden fájl indoklasa
6. Push feature branch-en (SOHA nem main-re!)
7. GitHub-jelzés lekerdezes (`scripts/github-signal-check.ps1 <PR>`)
8. AI review fix (Codex/Sourcery P0/P1 azonnal)
9. Required checks re-check
10. Záró self-review formátum (lásd 4. pont)

## 3. Biztonsági tiltólista (uj kod)

- `hard-coded secret`
- `SQL string-konkat` user inputból
- `eval`, `Function`, unsafe deserialization
- `shell=True` / shell string-konkat
- path traversal
- néma `catch(Exception e){}` / `except: pass`
- hamis mock adat production válaszként
- nem ellenorzott új csomag

## 4. Záró self-review formátum

Minden valasz végén kotelezo:

\\\markdown
## Állapot
Nem kész / Kész / BLOCKED

## Modell és hatály
- modell/tool: Claude / OpenAI / Gemini / ...
- szabalyzat: AGENTS.md (multi-modell)
- bizonyitek-idopont: ISO timestamp

## Változtatott fájlok
- `path`: miért

## Lokalis ellenorzesek
- lint / typecheck / test / build: pass/fail/pending + parancs

## GitHub ellenorzesek
- PR head SHA
- required checks
- legacy commit statuses
- check-run failure annotaciok
- workflow log bukas
- reviewDecision
- CodeQL / Dependabot / secret scanning
- Codex / Sourcery review
- unresolved conversations
- branch protection / rulesets
- supply-chain dependency diff
- deploy artifact / SBOM / attestation

## Dontes
Merge-ready csak akkor, ha minden fenti pont pass.
Deploy-ready csak akkor, ha az artifact/provenance/environment kapuk is pass.
\\\

## 5. Kotelezo GitHub-jelzés lekerdezes (minden push utan)

Futtasd kotelezoen `scripts/github-signal-check.ps1 <PR_NUM>`:
- PR head SHA, review decision, merge state
- Required checks allapot
- Minden check-run + annotacio
- Codex review + inline comments
- Sourcery review + inline comments
- Dependabot high/critical
- CodeQL high/critical
- Secret scanning + push protection
- Workflow logok ha failure

Email-bol AI review bemasolgatas MEGSZUNTETVE.

## 6. Multi-platform specifikus fajlok

- Claude: `CLAUDE.md` (symlink AGENTS.md-re / tartalmazza ezt)
- Gemini: `GEMINI.md`
- OpenAI Codex: `AGENTS.md` (Codex top-level AGENTS.md-t olvas)
- GitHub Copilot: `.github/copilot-instructions.md`
- Kemeny tiltasok: `AI_CONTRACT.md`

## 7. Skillek (.claude/skills/)

- `github-quality-gate/` - pre-push + signal-check wrapper
- `ai-review-responder/` - Codex/Sourcery auto-fix loop
- `deploy-verification/` - SBOM + attestation + env gates
- `agents-md-generator/` - AGENTS.md + AI_CONTRACT.md + platform-specific generalas

## 8. Kapcsolt

- `REVIEW.md` - push elotti self-review checklist
- `docs/obsidian-vault/MANDATE_V2.md` - Obsidian vault
- `docs/knowledge/memory/2026-04-23-multi-model-mandate-v2.{yaml,qmd}` - session memory