#!/usr/bin/env bash
# ============================================================================
# Backblaze B2 nightly backup - pg_dump + rclone + systemd timer
# ============================================================================
# Futtatas elotti lepesek:
#   1. Hozz letre B2 bucket-et: https://secure.backblaze.com/b2_buckets.htm
#      Bucket nev: valuta-backup
#      Privat, lifecycle: 14 nap utan a nem-current verziok torlese
#      (a bucket-oldali lifecycle a Backblaze DASHBOARD-on allithato; a lenti
#       RETENTION_DAYS csak a LOKALIS /var/backups/valuta retenciot vezerli)
#   2. Hozz letre application key-t (bucket-specific!):
#      - Scope: "Only specific buckets" -> valuta-backup
#      - Permissions: listBuckets, listFiles, readFiles, writeFiles, deleteFiles
#      - Jegyezd fel: keyID + applicationKey
#   3. SSH-val lepj a Hetzner VPS-re es expotald:
#      export B2_KEY_ID=...
#      export B2_APP_KEY=...
#      bash install-b2-backup.sh
# ============================================================================

set -euo pipefail

if [[ -z "${B2_KEY_ID:-}" || -z "${B2_APP_KEY:-}" ]]; then
    echo "HIBA: B2_KEY_ID es B2_APP_KEY kornyezeti valtozokat be kell allitani."
    echo "  export B2_KEY_ID=...; export B2_APP_KEY=...; bash $0"
    exit 1
fi

B2_BUCKET="${B2_BUCKET:-valuta-backup}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/valuta}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "=== rclone telepites ==="
if ! command -v rclone >/dev/null; then
    curl -fsSL https://rclone.org/install.sh | bash
fi
rclone version | head -2

log "=== rclone config ==="
mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf <<CFGEOF
[b2]
type = b2
account = $B2_KEY_ID
key = $B2_APP_KEY
hard_delete = true
CFGEOF
chmod 600 /root/.config/rclone/rclone.conf

log "=== rclone kapcsolat teszt ==="
rclone lsd "b2:$B2_BUCKET" >/dev/null && log "OK - bucket elerheto" || {
    echo "HIBA: B2 bucket nem elerheto. Ellenorizd a key+bucket-et."
    exit 1
}

log "=== Backup script telepites ==="
mkdir -p "$BACKUP_DIR"
cat > /usr/local/bin/valuta-db-backup.sh <<BSEOF
#!/usr/bin/env bash
# Napi pg_dump + feltoltes B2-re + lokalis retention
set -euo pipefail

BACKUP_DIR="$BACKUP_DIR"
B2_BUCKET="$B2_BUCKET"
TS=\$(date +%Y%m%d-%H%M%S)
FILE="\$BACKUP_DIR/valuta-\$TS.sql.gz"

# pg_dump + tombfor
sudo -u postgres pg_dump -Fp valuta | gzip -9 > "\$FILE"
SIZE=\$(du -h "\$FILE" | cut -f1)
echo "[backup] \$FILE (\$SIZE)"

# Lokalis retention ELOSZOR fut (2026-08-09 javitas).
# Korabban a feltoltes utan allt, es 'set -euo pipefail' mellett egy bukott
# 'rclone copy' (pl. 403 storage_cap_exceeded) megolte a scriptet, mielott a
# retention lefutott volna -> a lokalis dumpok korlatlanul gyultek (79 db 30 napnal
# regebbi fajl, 530 MB), tehat egy TAVOLI kvotahiba egy LOKALIS lemez-szivargast
# okozott. A retention nem fugg a feltoltestol, ezert elore kerul.
find "\$BACKUP_DIR" -name "valuta-*.sql.gz" -mtime +$RETENTION_DAYS -delete

# B2-re feltoltes. Best-effort a lokalis mentes vedelmeben (ugyanaz a minta, mint
# lent az 'rclone size'-nal): a feltoltes bukasa NEM ervenytelenitheti a mar
# elkeszult lokalis dumpot, de a service-nek BUKNIA kell, hogy a hiba lathato
# maradjon -> UPLOAD_FAILED flag, es a script vegen nem-nulla exit.
UPLOAD_FAILED=0
rclone copy "\$FILE" "b2:\$B2_BUCKET/db/" --progress --log-level INFO || UPLOAD_FAILED=1
if [ "\$UPLOAD_FAILED" = "1" ]; then
  echo "[backup] FIGYELEM: a B2 feltoltes NEM sikerult — a lokalis dump (\$FILE) megvan, az off-site masolat HIANYZIK."
fi

# Egeszseg-ellenorzes: a bucket-ben levo friss file melyeke?
# Best-effort: ez CSAK naplozas, egy listazasi hiba nem buktathatja a mentest.
LATEST=\$(rclone lsl "b2:\$B2_BUCKET/db/" 2>/dev/null | sort -k 2 | tail -1) || LATEST="n/a (rclone lsl hiba)"
echo "[backup] Legfrissebb B2-ben: \$LATEST"

# Bucket osszmeret naplozasa - korai figyelmeztetes, ha a tarhasznalat no.
# (A Backblaze "Daily Storage Cap" fiok-szintu; ez a sor a sajat bucketunk meretet adja.)
# Best-effort (Codex P2): set -euo pipefail mellett az rclone size atmeneti hibaja NEM
# buktathatja el a mar sikeresen feltoltott backupot -> || fallback a hibas systemd-statusz ellen.
BUCKET_SIZE=\$(rclone size "b2:\$B2_BUCKET" 2>/dev/null | tr '\n' ' ') || BUCKET_SIZE="n/a (rclone size hiba)"
echo "[backup] B2 bucket (\$B2_BUCKET) ossz: \$BUCKET_SIZE"

# A lokalis mentes es a retention ekkorra mar lefutott; ha az off-site masolat
# hianyzik, a service BUKJON, hogy a systemd/monitoring jelezze.
if [ "\$UPLOAD_FAILED" = "1" ]; then
  echo "[backup] HIBA: off-site (B2) masolat nem keszult el."
  exit 1
fi
BSEOF
chmod +x /usr/local/bin/valuta-db-backup.sh

log "=== systemd service + timer ==="
cat > /etc/systemd/system/valuta-backup.service <<'SVCEOF'
[Unit]
Description=Valuta DB backup to Backblaze B2
After=network-online.target postgresql.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/valuta-db-backup.sh
StandardOutput=journal
StandardError=journal
SVCEOF

cat > /etc/systemd/system/valuta-backup.timer <<'TIMEREOF'
[Unit]
Description=Daily Valuta DB backup (03:30 UTC)
Requires=valuta-backup.service

[Timer]
OnCalendar=*-*-* 03:30:00 UTC
Persistent=true
RandomizedDelaySec=5min

[Install]
WantedBy=timers.target
TIMEREOF

systemctl daemon-reload
systemctl enable --now valuta-backup.timer

log "=== Verifikacio ==="
systemctl list-timers valuta-backup.timer --no-pager

log "=== Test futas (nem ronja el a retention-t) ==="
systemctl start valuta-backup.service
sleep 2
journalctl -u valuta-backup.service -n 20 --no-pager

log "=== KESZ ==="
log "Napi backup: $BACKUP_DIR-ben + b2:$B2_BUCKET/db/"
log "Logok:       journalctl -u valuta-backup.service -f"
log "Kovi futas:  systemctl list-timers valuta-backup.timer"
