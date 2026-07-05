#!/usr/bin/env bash
# ============================================================================
# Szinkron-replikáció auto-degradáció guard — a HETZNER primary-n fut.
#
# A szinkron replikáció (synchronous_commit=on + synchronous_standby_names) NULLA
# adatvesztést ad: a Hetzner addig nem ACK-ol egy commitot, amíg a Scaleway standby
# meg nem erositette. DE ha a standby/WireGuard leáll, a commitok BLOKKOLNÁNAK ->
# a Hetzner irhatatlan lenne (pénztárak nem tudnak rögziteni).
#
# Ez a guard feloldja a csapdát: ha a szinkron standby >~20s-ig nem elérhető,
# AUTOMATIKUSAN async-ra degradál (synchronous_standby_names='') -> a Hetzner
# írható marad. Amikor a standby visszajön, AUTOMATIKUSAN vissza sync-re -> RPO=0
# helyreáll. Mindkettoről e-mail + journal log.
#
# 2026-06-05 — a max-biztonság (5-rétegű) csomag 3. rétege.
# ============================================================================
set -uo pipefail

STANDBY_NAME="scaleway_standby"
DOWN_CYCLES=2                 # ennyi egymás utáni hiányzó ellenőrzés után degradál
INTERVAL=10                   # másodperc / ciklus  (~20s a degradációhoz)
STATE_FILE=/run/sync-guard.missing
SMTP_PASS_FILE=/opt/valutavalto/deploy/hetzner/monitoring/secrets/smtp_app_password
SMTP_USER="noraautomatizalas@gmail.com"
RCPT="kosa.zoltan.ebc@gmail.com"

psqlq() { timeout 8 sudo -u postgres psql -tAc "$1" 2>/dev/null; }

notify() {
  local subj="$1" body="$2"
  logger -t sync-guard "$subj" 2>/dev/null || true
  [ -f "$SMTP_PASS_FILE" ] || return 0
  local pass; pass="$(cat "$SMTP_PASS_FILE")"
  printf 'From: %s\nTo: %s\nSubject: %s\nContent-Type: text/plain; charset=UTF-8\n\n%s\n' \
    "$SMTP_USER" "$RCPT" "$subj" "$body" | \
    timeout 20 curl -s --ssl-reqd --url smtp://smtp.gmail.com:587 \
      --user "$SMTP_USER:$pass" --mail-from "$SMTP_USER" --mail-rcpt "$RCPT" \
      --upload-file - >/dev/null 2>&1 || true
}

missing=0
[ -f "$STATE_FILE" ] && missing="$(cat "$STATE_FILE" 2>/dev/null || echo 0)"

while true; do
  connected="$(psqlq "SELECT count(*) FROM pg_stat_replication WHERE application_name='${STANDBY_NAME}';")"
  mode="$(psqlq "SHOW synchronous_standby_names;")"
  connected="${connected:-0}"

  if [ "$connected" = "0" ]; then
    missing=$(( missing + 1 ))
    if [ "$missing" -ge "$DOWN_CYCLES" ] && [ -n "$mode" ]; then
      psqlq "ALTER SYSTEM SET synchronous_standby_names='';" >/dev/null
      psqlq "SELECT pg_reload_conf();" >/dev/null
      notify "[excvaluta HA] DEGRADALT async-ra — szinkron standby leallt" \
        "A Scaleway szinkron standby kb. $(( missing * INTERVAL ))s-ig NEM elerheto. A Hetzner most ASYNC modban ir (irhato marad, de a standby visszateresig kis RPO-ablak van). Visszatereskor automatikusan vissza sync-re."
    fi
  else
    if [ -z "$mode" ]; then
      psqlq "ALTER SYSTEM SET synchronous_standby_names='${STANDBY_NAME}';" >/dev/null
      psqlq "SELECT pg_reload_conf();" >/dev/null
      notify "[excvaluta HA] VISSZAALLT sync-re — standby ujra elerheto" \
        "A Scaleway szinkron standby ujracsatlakozott. A Hetzner most SZINKRON modban ir -> RPO=0 helyreallt."
    fi
    missing=0
  fi

  echo "$missing" > "$STATE_FILE"
  sleep "$INTERVAL"
done
