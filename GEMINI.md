# GEMINI.md - Google Gemini platformspecifikus kiegeszites

Hatály: Google Gemini, Gemini Code Assist, Gemini CLI, Jules es minden jovobeli Gemini-alapu coding agent.

PRIORITAS: AGENTS.md a modellfuggetlen igazsagforras. Ez a fajl CSAK kiegeszitheti, NEM gyengitheti a kapukat.

## Gemini CLI / Code Assist specifikus

- Config: .gemini/settings.json
- Tool hasznalat: Gemini CLI a projekt AGENTS.md-et olvassa

## Hook alternativak

Gemini-ben nincs natív hook rendszer, de:
- Pre-commit hook -> scripts/pre-push-quality-gate.ps1
- GitHub Actions required check CI szinten kenyszerit

## Kotelezo viselkedes

1. Olvasd AGENTS.md + AI_CONTRACT.md + REVIEW.md
2. Futtasd scripts/pre-push-quality-gate.ps1 MINDEN push elott
3. Push utan scripts/github-signal-check.ps1 <PR_NUM>
4. AI review feedback javitas (Codex, Sourcery)
5. Zaro self-review a AGENTS.md 4. pont szerint

## Kivetelek: NINCS. Modellneutral hataly.
