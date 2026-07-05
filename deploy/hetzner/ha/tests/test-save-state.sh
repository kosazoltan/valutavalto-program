#!/usr/bin/env bash
# Unit tests for save_state() in primary-watchdog.sh (regression: exit-code 1 on happy path).
set -u
SCRIPT="$(dirname "$0")/../primary-watchdog.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAILS=0

# Extract only the save_state function (do NOT source the whole script — it would run main).
sed -n '/^save_state() {/,/^}/p' "$SCRIPT" > "$TMP/fn.sh"
grep -q 'save_state() {' "$TMP/fn.sh" || { echo "FATAL: save_state not extracted"; exit 1; }
# shellcheck disable=SC1091
source "$TMP/fn.sh"

check() { # $1=name $2=expected_rc $3=actual_rc $4=expected_content(printf-escaped) $5=file
  local ok=1
  [ "$3" -eq "$2" ] || ok=0
  if [ -n "$4" ]; then
    [ "$(printf "$4")" = "$(cat "$5" 2>/dev/null)" ] || ok=0
  fi
  if [ "$ok" = 1 ]; then echo "PASS: $1"; else
    echo "FAIL: $1 (rc=$3 expected=$2; content=$(cat "$5" 2>/dev/null | tr '\n' '|'))"
    FAILS=$((FAILS+1))
  fi
}

# T1: happy path — all zero -> rc 0, file exactly "0\n"
STATE_FILE="$TMP/s1"; fails=0 alerted=0 promoted=0 failback_notified=0
save_state; check "T1 happy path rc=0, content '0'" 0 $? '0\n' "$STATE_FILE"

# T2: failback_notified set -> rc 0, both lines present
STATE_FILE="$TMP/s2"; fails=0 alerted=0 promoted=0 failback_notified=1720000000
save_state; check "T2 failback line kept" 0 $? '0\nfailback_notified=1720000000\n' "$STATE_FILE"

# T3: all flags set -> rc 0, full 4-line format byte-identical to pre-fix
STATE_FILE="$TMP/s3"; fails=7 alerted=1 promoted=1 failback_notified=1720000000
save_state; check "T3 full flag matrix" 0 $? \
  '7\nalerted=1\npromoted=1\nfailback_notified=1720000000\n' "$STATE_FILE"

# T4: unopenable path -> rc NON-zero (I/O error must propagate, not be masked)
STATE_FILE="$TMP/no-such-dir/state"; fails=0 alerted=0 promoted=0 failback_notified=0
if save_state 2>/dev/null; then echo "FAIL: T4 I/O error swallowed (rc=0)"; FAILS=$((FAILS+1));
else echo "PASS: T4 I/O error propagates"; fi

[ "$FAILS" -eq 0 ] && { echo "ALL PASS"; exit 0; } || { echo "$FAILS test(s) FAILED"; exit 1; }
