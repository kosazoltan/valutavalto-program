# Context7 MCP — API kulcs setup

> **2026-04-29:** A Context7 MCP server kvótát kifutott (`Monthly quota exceeded`).
> A felhasználó (Kósa Zoltán) saját Context7 API kulcsot vásárolt — `~/Downloads/ctx7 valuta.txt`-ből importálva.

## Hol van a kulcs

- **`D:\repo\valutavalto-program\.env.context7`** — repo gyökér (gitignore-olt, NEM commit)
- Formátum: `CONTEXT7_API_KEY=ctx7sk-...` (43 char)

## Hogyan használja a Claude Code

A Context7 MCP plugin a Claude Code plugin-config-jából olvas. A kulcsot a plugin-konfigurációba kell betölteni:

### Lehetőség 1: Plugin marketplace UI (ajánlott)

1. Claude Code-ban: `/plugins` parancs
2. Context7 plugin → "Configure" → API key beillesztés a `.env.context7`-ből
3. Plugin restart

### Lehetőség 2: Manuális env-vár export (CLI)

```powershell
$env:CONTEXT7_API_KEY = (Get-Content -Path 'D:\repo\valutavalto-program\.env.context7' -Raw |
                       Select-String -Pattern 'CONTEXT7_API_KEY=(.+)' |
                       ForEach-Object { $_.Matches[0].Groups[1].Value.Trim() })
# Aztán: claude code (új session)
```

### Lehetőség 3: Globális Claude config (ha a plugin támogatja)

Szerkesztés: `~/.claude/settings.json` → új `env` szekció a Context7 plugin-hez.
**Figyelem**: a `~/.claude/settings.json` **NEM** gitignore-olt (más projektek is használhatják), így ide csak akkor írj, ha a kulcs általános. Még inkább: **NEM teszünk kulcsot ide** — a Claude plugin-saját env-mechanizmust használjuk.

## Biztonsági szabályok

❌ **NE commit-old** a `.env.context7`-et a Git-be
❌ **NE oszd meg** a kulcsot a chat-ben, log-ban, AI-ügynökkel
✅ **Használat**: `Get-Content .env.context7` lokálisan, kulcsot env-vár-ba töltés
✅ **Cserélés**: ha kompromittálódott → új kulcs a Context7 dashboard-ról + .env.context7 update

## Használat a kódban (példa)

```typescript
// CSAK Node.js / Vite — NEM Electron renderer (security)
const apiKey = process.env.CONTEXT7_API_KEY  // build-time
// vagy import.meta.env.VITE_CONTEXT7_API_KEY (HA Vite + .env.local-ban van)
```

## Quota monitoring

- Dashboard: https://context7.com/dashboard
- Havi kvóta: kulcsfüggő (free tier limit / paid plan)
- Ha kvóta-túllépés → fallback: hivatalos doc-ok lokális cache-ből vagy direkt npm package olvasás
