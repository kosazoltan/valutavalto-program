#!/usr/bin/env bash
# Sprint roadmap - Session memory auto-save (Cognee + Obsidian)
# 
# Futtatas: session zaraskor a CLAUDE.md "Minden session vegen" utan.
# Paraméterek:
#   $1 - session YAML file path (pl. docs/knowledge/memory/2026-04-23-session-name.yaml)
#
# Elofeltetel:
#   - mcp-cognee + mcp-obsidian container fut (docker compose --profile knowledge-mcp)
#   - .env-ben a COGNEE_LLM_API_KEY es OBSIDIAN_API_KEY beallitva
#
# Exit codes:
#   0: minden siker
#   1: Cognee sync hiba (warning, Obsidian megy tovabb)
#   2: Obsidian sync hiba (warning, Cognee megy tovabb)
#   3: mindket hiba

set -uo pipefail

SESSION_FILE="${1:-}"
if [[ -z "$SESSION_FILE" || ! -f "$SESSION_FILE" ]]; then
    echo "Hasznalat: $0 <session-memory-yaml-file>"
    echo "Pelda: $0 docs/knowledge/memory/2026-04-23-session-end-of-sprint.yaml"
    exit 1
fi

SESSION_NAME=$(basename "$SESSION_FILE" .yaml)
echo "[session-save] $SESSION_FILE ($SESSION_NAME)"

# 1. Cognee sync
COGNEE_URL="${COGNEE_URL:-http://localhost:8820}"
if curl -s -f "$COGNEE_URL/health" >/dev/null 2>&1; then
    echo "[session-save] Cognee: ingestion..."
    # Cognee MCP server nem standard HTTP API-t kinal, inkabb MCP protokollt.
    # Egyszerubb: kozvetlenul Python cognee CLI-t hivunk, ha van.
    if command -v cognee >/dev/null 2>&1; then
        cognee add-file "$SESSION_FILE" --metadata "session=$SESSION_NAME,type=handoff,date=$(date +%Y-%m-%d)" \
            && echo "[session-save] Cognee: OK" \
            || { echo "[session-save] Cognee: HIBA"; COGNEE_ERR=1; }
    else
        echo "[session-save] Cognee CLI nincs telepitve (pip install cognee), skip"
    fi
else
    echo "[session-save] Cognee: nem fut a $COGNEE_URL-en, skip"
fi

# 2. Obsidian sync
OBSIDIAN_HOST="${OBSIDIAN_HOST:-localhost}"
OBSIDIAN_PORT="${OBSIDIAN_PORT:-27124}"
OBSIDIAN_PROTOCOL="${OBSIDIAN_PROTOCOL:-https}"
OBSIDIAN_API_KEY="${OBSIDIAN_API_KEY:-}"

if [[ -n "$OBSIDIAN_API_KEY" ]]; then
    OBSIDIAN_URL="${OBSIDIAN_PROTOCOL}://${OBSIDIAN_HOST}:${OBSIDIAN_PORT}"
    # Pingelj
    if curl -s -f -k -H "Authorization: Bearer $OBSIDIAN_API_KEY" "$OBSIDIAN_URL/" >/dev/null 2>&1; then
        OBSIDIAN_PATH="Sessions/${SESSION_NAME}.md"
        # Konvertálás: YAML + qmd body merge
        QMD_FILE="${SESSION_FILE%.yaml}.qmd"
        if [[ -f "$QMD_FILE" ]]; then
            CONTENT=$(cat "$QMD_FILE")
        else
            CONTENT="---
$(cat "$SESSION_FILE")
---
"
        fi
        # PUT a vault-ba
        echo "[session-save] Obsidian: PUT $OBSIDIAN_PATH"
        HTTP_CODE=$(curl -s -o /tmp/obs-resp.txt -w "%{http_code}" -k -X PUT \
            -H "Authorization: Bearer $OBSIDIAN_API_KEY" \
            -H "Content-Type: text/markdown" \
            --data-binary "$CONTENT" \
            "$OBSIDIAN_URL/vault/$OBSIDIAN_PATH" || echo "000")
        if [[ "$HTTP_CODE" == "204" || "$HTTP_CODE" == "200" ]]; then
            echo "[session-save] Obsidian: OK (HTTP $HTTP_CODE)"
        else
            echo "[session-save] Obsidian: HIBA (HTTP $HTTP_CODE)"
            cat /tmp/obs-resp.txt
            OBSIDIAN_ERR=2
        fi
    else
        echo "[session-save] Obsidian: nem fut a $OBSIDIAN_URL-en, skip"
    fi
else
    echo "[session-save] Obsidian: OBSIDIAN_API_KEY nincs beallitva, skip"
fi

# Exit code aggregacio
exit $(( ${COGNEE_ERR:-0} + ${OBSIDIAN_ERR:-0} ))