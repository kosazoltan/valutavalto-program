# Repo Multi-Layer Memory

This directory is the repository-local memory bundle for the Valutavalto ERP project.
It is generated from the active repo-local vault at `vault/` and committed project
sources. Secrets and full environment values must never be stored here.

## Layers

- `qmd/repo-memory.qmd` - human-readable Quarto/Markdown memory index.
- `yaml/index.yaml` - machine-readable short, medium, operational, and long-term memory.
- `cognee/knowledge-bundle.yaml` - Cognee-ready knowledge graph bundle.
- `obsidian/repo-memory-mirror.md` - Obsidian-compatible mirror document.
- `vector/vector-index.jsonl` - local deterministic keyword-hash vector index.
- `reports/manifest.json`, `reports/status.json`, `reports/sync.json` - verification output.

## Commands

```powershell
npm run memory:build
npm run memory:status
npm run memory:sync
```

`memory:build` always works offline from committed repo files plus the local
Obsidian vault. `memory:sync` also writes status about Cognee/Obsidian live
connectivity. Cognee/Obsidian failures are reported explicitly; the command does
not pretend remote ingestion succeeded if auth or a local plugin is missing.

## Memory Scope

- Short-term memory: current mandates, core rules, active feedback.
- Medium-term memory: recent session handoffs and episodic state.
- Operational memory: procedures, runbooks, lessons, CI/deploy workflows.
- Long-term memory: historical QMD/YAML, user manuals, legal/legacy references.

