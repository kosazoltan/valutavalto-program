# MCP integration - Cognee + Obsidian Vault (Sprint roadmap)

## Attekintes

A Sprint roadmap P2 feladatai a session memory automatikus mentese Cognee + Obsidian integraciora. Ez a dokumentum leirja a setup + hasznalati mintat.

A jelenlegi rendszer a `docs/knowledge/memory/*.yaml` es `*.qmd` fajlokba mentodik manualisan (session vegen). Ez a setup ezt kiegeszíti:

- **Cognee MCP** - AI memory graph (knowledge engine)  
- **Obsidian MCP** - markdown vault sync (human-readable jegyzeted)

## 1. Cognee MCP setup

### Kotelezo elofeltetel

- `.env` fajlban:
  ```
  COGNEE_LLM_PROVIDER=openai           # vagy anthropic, gemini
  COGNEE_LLM_API_KEY=sk-proj-XXX       # LLM API kulcs (ha mar nincs)
  COGNEE_LLM_MODEL=gpt-4o-mini         # ajanlott default
  ```

### Indítas

```bash
docker compose -f docker-compose.yml -f docker-compose.mcp.yml --profile knowledge-mcp up -d mcp-cognee
```

A Cognee container initial install-kor automatikusan:
- `pip install cognee` telepit
- SQLite alapu storage-et inicializal: `.cognee/cognee.db`
- MCP server elindul: `http://localhost:8820/mcp`

### Claude Code integracio

A `.mcp.json` root-ban registralva van a `cognee` server. A Claude Code automatikusan betolti mikor indul.

Hasznalat session-ben:
- `cognee.add_content(text="...", metadata={...})` - uj tudas felvetel
- `cognee.search(query="vault stocktake")` - semantic search
- `cognee.graph()` - knowledge graph visualization

Auto-save a session zaraskor:
- A CLAUDE.md "Minden session végén" szakasz elóirja
- Ha `mcp-cognee` fut, a session-memory YAML-t + MD-t Cognee-be is lookpush-olni kell

## 2. Obsidian Vault MCP setup

### Kotelezo elofeltetel

1. **Obsidian telepites**: https://obsidian.md (Windows installer)
2. **Vault letrehozas**: pl. `D:\Obsidian\Valuta-ERP`
3. **Local REST API plugin installalas**:
   - Obsidian → Settings → Community plugins → Browse
   - `Local REST API` plugin install + enable
   - Settings → Local REST API → API key generate + save
4. **HTTPS cert trust**: a plugin self-signed tanusítvanyt hasznal

### `.env` fajl

```
OBSIDIAN_API_KEY=<a-plugin-altal-generalt-kulcs>
OBSIDIAN_HOST=host.docker.internal   # Docker Desktop-on belulr a host-ra mutat
OBSIDIAN_PORT=27124                   # https (default)
OBSIDIAN_PROTOCOL=https
```

### Indítas

```bash
docker compose -f docker-compose.yml -f docker-compose.mcp.yml --profile knowledge-mcp up -d mcp-obsidian
```

### Hasznalat

A `.mcp.json`-ban registralt `obsidian` server felkinalja:
- `obsidian.get_note(path)` - jegyzet tartalom
- `obsidian.put_note(path, content)` - jegyzet irasa/modositasa
- `obsidian.search(query)` - teljesszoveges kereses
- `obsidian.list_files(folder)` - konyvtar tartalom

Auto-sync a session zaraskor:
- Session memory YAML -> `Sessions/YYYY-MM-DD-session-name.md` a vault-ba
- Legacy dokumentaciok (`docs/knowledge/*`) -> `Knowledge/` mappa
- Compliance riportok -> `Compliance/` mappa

## 3. Session memory auto-save workflow

A CLAUDE.md-ben leirt session-end workflow kiegeszul ezzel:

```bash
# Manualis session zaraskor (jelenleg)
cat > docs/knowledge/memory/$(date +%Y-%m-%d)-session-name.yaml <<YAML
session: ...
YAML

# Automatikus (ha Cognee + Obsidian fut)
# 1. Cognee MCP: knowledge ingestion
#    mcp-cognee tool: add_content(file="docs/knowledge/memory/....yaml", metadata={...})
#
# 2. Obsidian MCP: markdown mirror
#    mcp-obsidian tool: put_note(path="Sessions/....md", content=...)
```

## 4. Priorizalas a roadmap-ban

| Feladat | Status | Prio | Becslés |
|---------|--------|------|---------|
| docker-compose.mcp.yml profile | KESZ | - | - |
| .mcp.json config | KESZ | - | - |
| Cognee Container live indítas | TODO | P2 | 30 min (env + container) |
| Obsidian vault + plugin setup | TODO | P2 | 15 min (user feladat) |
| Auto-save script (Bash) | TODO | P3 | 2 ora |
| Session handoff generator integracio | TODO | P3 | 4 ora |

## 5. Troubleshooting

### mcp-cognee keszíti a `.cognee/` mappat, de SQLite hibaval esik el

Jelentse a `.cognee/` permission-jet: `chmod -R 777 .cognee/` (WSL2 vagy Linux host).
Windows-on Docker Desktop vol-mount automatikusan kezeli.

### mcp-obsidian nem talalja a `host.docker.internal` ho-ot

Linux host-on (nem Docker Desktop): a `extra_hosts` az `docker-compose.mcp.yml`-ben megold problem.
Valdhatoan: `docker compose exec mcp-obsidian ping host.docker.internal`.

### OBSIDIAN_API_KEY helyette TLS tanusitvany hiba

Az Obsidian plugin self-signed cert-et hasznal. Az MCP server a `--insecure` flag-gel kell futni, vagy szurjd be a plugin Cert File-at a container trust-store-jaba.