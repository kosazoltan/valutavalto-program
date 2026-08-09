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
- `reports/sources.json` - complete, uncapped source path+sha256 list; the drift
  baseline used by `memory:stale-check`.

## Areas (active memory)

Every entry is tagged with zero or more product areas so knowledge can be loaded
for exactly the program area under development:

`ertektar penztar napzaras arfolyam cimletezes sync aml tenant riport database
installer deploy security frontend legacy`

Area assignment is deterministic (path match, or 2+ keyword hits) and defined by
`AREA_RULES` in `scripts/repo-memory.mjs`.

## Commands

```bash
npm run memory:build                                   # regenerate all layers
npm run memory:status                                  # layer + live service checks
npm run memory:sync                                    # build + Cognee/Obsidian push
npm run memory:areas                                   # area coverage counts
npm run memory:query -- "<terms>" --area sync --limit 8 # READ side (offline)
npm run memory:stale-check                             # exit 1 if bundle is stale
```

`memory:query` flags: `--area <a[,b]>`, `--limit N`, `--json` (machine-readable),
`--full` (longer excerpt read from the source file).

`memory:query` and `memory:stale-check` re-derive entries from the working tree,
so they never return knowledge that no longer exists in the repo.

## Mandatory usage

Reading stored area knowledge before non-trivial work and rebuilding the bundle
after it are both mandatory — see `AGENTS.md` section 2.1 and
`qmd/mandatory-memory-after-workflow.qmd`. `memory:stale-check` enforces the
write side and is wired into the pre-push gate.

`memory:build` always works offline from committed repo files plus the local
Obsidian vault. `memory:sync` also writes status about Cognee/Obsidian live
connectivity. Cognee/Obsidian failures are reported explicitly; the command does
not pretend remote ingestion succeeded if auth or a local plugin is missing.

## Memory Scope

- Short-term memory: current mandates, core rules, active feedback.
- Medium-term memory: recent session handoffs and episodic state.
- Operational memory: procedures, runbooks, lessons, CI/deploy workflows.
- Long-term memory: historical QMD/YAML, user manuals, legal/legacy references.

