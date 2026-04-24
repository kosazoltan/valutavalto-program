# Knowledge MCP setup - Cognee + Obsidian

> Cel: `scripts/session-memory-auto-save.ps1` eles futtatasa (session handoff automatikus Cognee + Obsidian sync).
> Diagnosztika script: `pwsh scripts/setup-knowledge-mcp.ps1`

## 1. Cognee backend

### 1.A Ha mar fut egy Cognee konteneres peldany (elsorangu valasztas)

A Docker-en mar futhat egy `cognee-backend` konteneres Cognee instance (valoszinusitheto masik projektbol). Ha elerheto `http://localhost:8098/health` (HTTP 200 + `{"status":"ready"}`), akkor **hasznaljuk azt**:

```powershell
# .env-hez hozzaadni (gitignore-os, soha ne commit-oljuk):
$env:COGNEE_URL = "http://localhost:8098"
```

A mar futo backend sajat OpenAI kulcsot hasznal (`LLM_API_KEY`), tehat nem kell `COGNEE_LLM_API_KEY` env var.

### 1.B Uj mcp-cognee konteneres peldany indul

Ha mar nem fut Cognee, a `docker-compose.mcp.yml` `--profile knowledge-mcp` indit egy friss `mcp-cognee`-t a supergateway-en keresztul:

```powershell
# .env-hez (git-ignore-os!):
$env:COGNEE_LLM_PROVIDER = "openai"
$env:COGNEE_LLM_MODEL = "gpt-4o-mini"
$env:COGNEE_LLM_API_KEY = "sk-..."   # OpenAI project-level key, https://platform.openai.com/api-keys
$env:COGNEE_URL = "http://localhost:8820"
```

Majd:

```powershell
docker compose -f docker-compose.yml -f docker-compose.mcp.yml --profile knowledge-mcp up -d
```

### 1.C Cognee CLI (opcionalis)

A `session-memory-auto-save.ps1` a `cognee add-file` CLI-t hasznalja. Ha nincs telepitve, a script WARN-nel skip-eli:

```powershell
pip install cognee
# utana: cognee --version
```

## 2. Obsidian Local REST API plugin

### 2.A Plugin install (UI-s lepes, NEM automatikus)

1. Obsidian megnyitasa
2. **Settings** (bal also fogaskerek)
3. **Community plugins** > **Browse**
4. Keres: `Local REST API` (szerzo: *coddingtonbear*)
5. **Install** > **Enable**

### 2.B API key export

1. **Settings** > **Local REST API** (bal oldal, plugin szekcio)
2. **API key** szekcio > **Copy**
3. Env var beallitas:

```powershell
$env:OBSIDIAN_API_KEY = "<plugin oldal szerint masolt key>"
```

Opcionalis finomhangolas (default-tol elteroen):

```powershell
$env:OBSIDIAN_HOST = "localhost"      # vagy kulon IP, ha masik gep
$env:OBSIDIAN_PORT = "27124"          # https default, 27123 = http
$env:OBSIDIAN_PROTOCOL = "https"      # alap
```

### 2.C Self-signed cert

Az Obsidian Local REST API self-signed TLS-tet hasznal. A `session-memory-auto-save.ps1` alapbol kikeruli a cert ellenorzest (`-StrictCertCheck` nelkul). Csak akkor legyen `$true`, ha sajat CA-t teltelepitettel.

## 3. Teszt

```powershell
# 1. Diagnosztika - megnezi mi kesz, mi hianyzik
pwsh scripts/setup-knowledge-mcp.ps1

# 2. Dry-run - a mai session YAML alapjan mit csinalna
pwsh scripts/session-memory-auto-save.ps1 -DryRun

# 3. Eles futtatas - a mai session YAML szinkronizalasa
pwsh scripts/session-memory-auto-save.ps1
```

Sikerkriterium:
- Cognee: `[OK]` cognee-backend / mcp-cognee elerheto + vagy a CLI fut, vagy a REST API
- Obsidian: `[OK]` 27124 port valaszol (vagy 401 API key nelkul, az is jel hogy fut)
- Env: `$env:COGNEE_URL` (pl. `http://localhost:8098`) + `$env:OBSIDIAN_API_KEY`

## 4. Troubleshooting

### "Cognee nem fut http://localhost:8820"

- `docker ps | grep cognee` - ha van `cognee-backend` 8098-on, allits be `$env:COGNEE_URL=http://localhost:8098`
- Ha nincs semmi: `docker compose --profile knowledge-mcp up -d`

### "OBSIDIAN_API_KEY nincs beallitva"

- Obsidian -> Settings -> Local REST API -> API key -> Copy
- PowerShell-ben `$env:OBSIDIAN_API_KEY = "..."` (session-szintu)
- Permanens: Windows > Environment Variables > User variables

### "Obsidian nem fut localhost:27124"

- Obsidian desktop app futtatas szukseges
- Plugin aktivalva: Settings > Community plugins > Local REST API "ON"
- Tuzfal: a plugin a localhoston hallgat, de tuzfalszabaly akadalyozhatja

### OpenAI API key expose warning

Ha a `cognee-backend` env-valtoazoi tartalmazzak az `LLM_API_KEY`-t, es `docker inspect`-el lathato, az nem biztonsagi resz (local-only container), de ne commit-old a `.env`-be vagy public repo-ba. Rotate rendszeresen a https://platform.openai.com/api-keys oldalon.

## 5. Aktualis status (generalt)

A `pwsh scripts/setup-knowledge-mcp.ps1` meg lista szerint:

```
[1/5] Docker Engine           - ellenoriz
[2/5] Cognee backend          - localhost:8098 / 8820 / $env:COGNEE_URL
[3/5] Cognee CLI (opcionalis) - pip install cognee
[4/5] Obsidian Local REST API - 27124 / 27123
[5/5] Env var-ok              - COGNEE_LLM_API_KEY, OBSIDIAN_API_KEY
```

## 6. Ha minden kesz

A `scripts/session-memory-auto-save.ps1` utan:
- Cognee: a session YAML-t `cognee add-file` ingest-eli (knowledge graph-ba)
- Obsidian: `PUT /vault/Sessions/<session-name>.md` tarolja a QMD-t

Ezutan minden session-zarasnal a kovetkezo elhangzik:
- `.remember/remember.md` frissul (manualis, keszoltunk)
- `docs/knowledge/memory/*.yaml + .qmd` keszul (manualis, keszoltunk)
- `pwsh scripts/session-memory-auto-save.ps1` autoinditja a ket sync-et