# Agent Permanent Intelligence Archive

This directory stores compact, hash-chained agent decision records for the
valutavalto repo.

Use:

```powershell
npm run agent:archive -- --summary "What changed and why" --type decision --status completed
```

Rules:

- Do not write secrets, tokens, full environment values, or private user data.
- Store only decision summaries, changed file paths, and verification commands.
- The `decision-log.jsonl` chain is append-only. If a correction is needed,
  append a new corrective record instead of editing old records.
