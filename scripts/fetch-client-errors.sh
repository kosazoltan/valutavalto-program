#!/usr/bin/env bash
# =============================================================================
# fetch-client-errors.sh — kliens-oldali hibajelentések lekérdezése
# =============================================================================
# 2026-05-05 user-direktíva alapján: a v2.5.14+ Penztar.exe + NSIS Setup
# AUTOMATIKUSAN ide küldi a hibákat: POST /api/v1/diagnostics/error-report
# -> PostgreSQL `client_error_log` tábla.
#
# Ez a script SSH-zik Hetzner-re és lekéri az utolsó N hiba-jelentést
# tömbörített CSV/táblázat formában.
#
# Használat:
#   bash scripts/fetch-client-errors.sh           # utolsó 20
#   bash scripts/fetch-client-errors.sh 50        # utolsó 50
#   bash scripts/fetch-client-errors.sh 30 borsi  # utolsó 30 ahol user_identifier
#                                                  # tartalmazza a 'borsi' string-et
# =============================================================================

set -e

LIMIT="${1:-20}"
USER_FILTER="${2:-}"

SSH_KEY="$HOME/.ssh/hetzner_ed25519"
HETZNER_HOST="root@95.216.191.162"

# SQL kérés — kompakt, csak a fontos oszlopok
SQL_BASE="SELECT
    TO_CHAR(created_at, 'MM-DD HH24:MI:SS') as datum,
    LEFT(component, 18) as komponens,
    LEFT(version, 8) as ver,
    LEFT(COALESCE(user_identifier, '-'), 28) as felhasznalo,
    LEFT(error_message, 80) as hiba
FROM client_error_log"

if [ -n "$USER_FILTER" ]; then
    SQL_QUERY="$SQL_BASE WHERE user_identifier ILIKE '%$USER_FILTER%' ORDER BY created_at DESC LIMIT $LIMIT;"
else
    SQL_QUERY="$SQL_BASE ORDER BY created_at DESC LIMIT $LIMIT;"
fi

echo "============================================================"
echo "  Kliens hibajelentesek (utolso $LIMIT)"
if [ -n "$USER_FILTER" ]; then echo "  Szuro: user LIKE '%$USER_FILTER%'"; fi
echo "============================================================"
echo ""

ssh -i "$SSH_KEY" -o ConnectTimeout=10 "$HETZNER_HOST" \
    "sudo -u postgres psql -d valuta -c \"$SQL_QUERY\""

echo ""
echo "Reszletes lekerdezes (full stack-trace + context) egy hiba-ID-re:"
echo "  bash scripts/fetch-client-errors.sh detail <id>"
