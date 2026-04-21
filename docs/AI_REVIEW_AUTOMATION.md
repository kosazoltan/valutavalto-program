# AI Review Auto-Fix Automatizacio

Teljesen automatikus pipeline, ami a Sourcery AI + ChatGPT Codex Connector
review-it azonnal javitja Claude Code GitHub Action-nel.

## Mukodes (teljes automatizacio)

```
PR nyit / push
       v
Sourcery AI review + ChatGPT Codex review
       v
pull_request_review event (submitted)
       v
.github/workflows/ai-review-auto-fix.yml trigger
       v
Claude Code Action (@anthropics/claude-code-action@v1)
       v
- gh api lekeri a review-t
- elemzi P1/P2/P3 szerint
- javit + commit-ol a feature branch-re
- push -> CI re-trigger
       v
Loop ismetlodik amig a reviewer "looks great!"-ot ad
```

## Egyszeri setup lepesek (user feladat)

### 1. Anthropic API key

1. Menj ide: https://console.anthropic.com/settings/keys
2. "Create Key" -> add nevet: `github-actions-auto-fix`
3. Masold a kulcsot (csak egyszer lathato!)

### 2. GitHub secret

1. Repo: https://github.com/kosazoltan/valutavalto-program/settings/secrets/actions
2. "New repository secret"
3. Name: `ANTHROPIC_API_KEY`
4. Secret: az elozo kulcs
5. Add secret

### 3. Claude GitHub App telepitese

1. Menj ide: https://github.com/apps/claude
2. "Install" gomb
3. Valaszd a `valutavalto-program` repo-t (vagy all repos)
4. Grant permissions

### 4. Verifikacio

1. Commit ez a workflow a main-re (mar megvan: `.github/workflows/ai-review-auto-fix.yml`)
2. Nyiss egy uj PR-t barmilyen valtoztatassal
3. Var ~2-3 percet: Sourcery review erkezik
4. Claude workflow automatikusan trigger-el (GitHub Actions tab-on lathato)

## Koltseg

| Erőforras | Mennyi | Koltseg |
|---|---|---|
| Claude API tokens | ~100-500k / fix | ~$0.50-$3 |
| GitHub Actions perc | ~5-10 perc / fix | ~$0.01-$0.02 (public: free) |
| Osszes havi (20 PR) | ~10-60M token | ~$10-$60 |

**Limitek** a `claude-code-action@v1` beallitasaiban:
- `--max-turns 5` (max 5 iteracio agent-nek)
- `timeout-minutes: 15` (CI job timeout)
- `cancel-in-progress: false` (concurrent guard)

## Biztonsag

- A workflow **csak** a `sourcery-ai[bot]` + `chatgpt-codex-connector[bot]` user-ekre
  triggerel (nem enged barmilyen user-nek kod-valtoztatast).
- A Claude ugyfel **csak** a PR feature branch-ere push-ol, nem a main-re.
- `permissions:` blokk minimum jogosultsaggal: contents+pulls+issues write,
  semmi actions:write / packages:write nincs.
- A `timeout-minutes: 15` megakadalyozza a runaway loop-ot.
- A `concurrency` group biztositja, hogy egyszerre csak 1 fix fut per-PR.

## Hibakezeles

Ha a workflow fail-el:
- **notify-failure job** automatikusan kommentel a PR-en linkel a logra
- Te manualisan javitod + push-olsz
- Kovetkezo review-kor megprobaljia ujra

## Kizaras (opt-out)

Egy PR automatikus fix-elesebol:
- Nyiss draft PR-t
- Vagy `[skip-ai-fix]` jelzest a PR title-ben (TODO: ezt a filter-t meg hozza kell adni)

## Kapcsolodo fajlok

- `.github/workflows/ai-review-auto-fix.yml` — a tenyleges workflow
- `CLAUDE.md` — "Kotelezo AI code review workflow" szekcio (manualis resolut backup)

## Linkek

- Claude Code Action docs: https://code.claude.com/docs/en/github-actions
- GitHub repo: https://github.com/anthropics/claude-code-action
- Security guide: https://github.com/anthropics/claude-code-action/blob/main/docs/security.md
- Anthropic API console: https://console.anthropic.com
- Claude GitHub App: https://github.com/apps/claude