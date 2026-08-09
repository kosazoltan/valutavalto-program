#!/usr/bin/env bash
# FKH-031 / V377 — Gate B verification against LIVE prod (Hetzner).
#
# Run AFTER the "Deploy to Hetzner" workflow completed for the release commit.
# Baseline it is checked against: .hermes/plans/FKH-031-gate-a-baseline.md
#
# Exit 0 = all four Gate B assertions hold. Non-zero = investigate, do NOT
# declare the release verified.
set -uo pipefail

SSH="ssh -o BatchMode=yes -o ConnectTimeout=15 -i /c/zk/.ssh/id_rsa root@95.216.191.162"
q() { $SSH "sudo -u postgres psql -d valuta -Atc \"$1\""; }

fail=0
chk() { # chk <label> <actual> <expected>
  if [ "$2" = "$3" ]; then
    printf 'OK    %-58s %s\n' "$1" "$2"
  else
    printf 'FAIL  %-58s got=%s want=%s\n' "$1" "$2" "$3"
    fail=$((fail+1))
  fi
}

echo "=== 1. V377 ran (flyway_schema_history) ==="
FW=$(q "SELECT success::text FROM flyway_schema_history WHERE version='377';")
chk "V377 present and success" "${FW:-MISSING}" "t"
q "SELECT 'installed_on=' || installed_on FROM flyway_schema_history WHERE version='377';"

echo
echo "=== 2. V377 actually WROTE (status + [FKH-031 V377] marker) ==="
# A fail-closed migration that DECLINED to write also records success=t, so the
# statuses and the notes marker are the real proof.
OUT=$(q "SELECT tr.status FROM transaction tr JOIN branch b ON b.id=tr.branch_id JOIN currency c ON c.id=tr.currency_id WHERE b.code='BR035' AND c.code='USD' AND tr.receipt_number='AA035100003';")
REV=$(q "SELECT tr.status FROM transaction tr JOIN branch b ON b.id=tr.branch_id JOIN currency c ON c.id=tr.currency_id WHERE b.code='BR035' AND c.code='USD' AND tr.receipt_number='AA035100004';")
chk "AA035100003 (TRANSFER_OUT, AT-000010)" "$OUT" "COMPLETED"
chk "AA035100004 (REVERSAL)" "$REV" "CANCELLED"

MARK=$(q "SELECT count(*)::text FROM transaction tr JOIN branch b ON b.id=tr.branch_id JOIN currency c ON c.id=tr.currency_id WHERE b.code='BR035' AND c.code='USD' AND tr.receipt_number IN ('AA035100003','AA035100004') AND tr.notes LIKE '%[FKH-031 V377]%';")
chk "rows carrying the [FKH-031 V377] notes marker" "$MARK" "2"

echo
echo "=== 3. NFR-1: cash_balance UNTOUCHED (Gate A values) ==="
B35=$(q "SELECT cb.current_balance::text FROM cash_balance cb JOIN branch b ON b.id=cb.branch_id JOIN currency c ON c.id=cb.currency_id WHERE b.code='BR035' AND c.code='USD';")
B20=$(q "SELECT cb.current_balance::text FROM cash_balance cb JOIN branch b ON b.id=cb.branch_id JOIN currency c ON c.id=cb.currency_id WHERE b.code='BR020' AND c.code='USD';")
chk "BR035 USD current_balance unchanged" "$B35" "3797.00"
chk "BR020 USD current_balance unchanged" "$B20" "1000.00"
echo "-- cash_balance updated_at (must NOT correlate with V377 installed_on):"
q "SELECT b.code || ' updated_at=' || cb.updated_at FROM cash_balance cb JOIN branch b ON b.id=cb.branch_id JOIN currency c ON c.id=cb.currency_id WHERE b.code IN ('BR035','BR020') AND c.code='USD' ORDER BY b.code;"

echo
echo "=== 4. FR-1: the 1000 USD outflow appears EXACTLY ONCE in turnover ==="
# COMPLETED + financial_effective is what the 36 JPQL turnover queries filter on.
CNT=$(q "SELECT count(*)::text FROM transaction tr JOIN branch b ON b.id=tr.branch_id JOIN currency c ON c.id=tr.currency_id WHERE b.code='BR035' AND c.code='USD' AND tr.status='COMPLETED' AND tr.financial_effective = TRUE AND tr.transaction_type='TRANSFER_OUT';")
chk "BR035 USD COMPLETED+fin.eff TRANSFER_OUT rows" "$CNT" "2"
echo "-- full BR035 USD picture after the correction:"
$SSH "sudo -u postgres psql -d valuta -c \"SELECT tr.receipt_number, tr.transaction_type, tr.status, tr.currency_amount, tr.reference_number FROM transaction tr JOIN branch b ON b.id=tr.branch_id JOIN currency c ON c.id=tr.currency_id WHERE b.code='BR035' AND c.code='USD' ORDER BY tr.created_at;\""

echo
if [ "$fail" -eq 0 ]; then
  echo "GATE B: PASS (all assertions hold)"
else
  echo "GATE B: FAIL — $fail assertion(s) violated. Do NOT declare the release verified."
fi
exit "$fail"
