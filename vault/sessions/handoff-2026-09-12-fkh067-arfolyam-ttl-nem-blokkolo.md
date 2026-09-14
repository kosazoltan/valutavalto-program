# Handoff — FKH-067 (spec doc FKH-063): exchange-rate TTL made non-blocking

Date: 2026-09-12 · PR #1753 merged → main `b29c752e` · prod deploy verified

## What shipped

A stale exchange rate (720h TTL) no longer blocks the booking of transactions recorded on the
client AFTER `TTL_NONBLOCKING_CUTOFF`; everything recorded before it keeps the blocking rule.

- `penztar-client/electron/sync-engine.ts`: `clientCreatedAt` from the unchanged
  `pending_transactions.created_at` (new `toIsoInstant`, strict SQLite-shape + round-trip check).
- `ExchangeRateService.getCurrentRate(Long, Instant)` additive overload; single-arg overload keeps
  the blocking behaviour for ShipmentService / TransactionConversionService / ExchangeRateController.
- `STALE_RATE_TRANSACTION_COMMITTED` audit on every pass-through.
- V392: `transaction.client_created_at` + `TTL_NONBLOCKING_CUTOFF` seed (empty = fail-closed).
- `TTL_NONBLOCKING_CUTOFF` added to `PROTECTED_FINANCIAL_CONTROL_KEY_PREFIXES` → global row ADMIN-only.
- `packages/shared-api` openapi.json + openapi.d.ts extended with the new field.

## Prod state (verified 2026-09-12)

| Item | Evidence |
|---|---|
| V392 applied | `flyway_schema_history` version 392, success=t, installed_on 12:36:36 |
| Column | `transaction.client_created_at timestamp, is_nullable=YES` |
| New code in RUNNING jar | `grep -ac TTL_NONBLOCKING_CUTOFF`/`STALE_RATE_TRANSACTION_COMMITTED` = 2/2 in the extracted `ExchangeRateService.class` |
| Cutoff set | `2026-09-12T13:00:00Z`, global row, is_active=t, `updated_by=FKH-067_rollout` (guarded UPDATE: only fired on the empty value) |
| Company overrides | 0 |
| EUR rate age | 2183 h (>720) — the non-blocking branch is live-relevant |
| Stuck items | Not present in `transaction` (they never booked; they live in client pending rows) — unchanged by design (FR-5) |

## Release v2.28.113 (closed 2026-09-12)

PR #1754 (9-way bump, version-only) merged -> main `0df543d7`; prod `2.28.113`
(buildTime 13:18:51Z), health ok. Signed release run `34696274104` all jobs success.

| Artifact | Verification |
|---|---|
| Penztar-Setup-2.28.113-20260912.exe | sha256 OK, Authenticode **Valid** (CN=EXCLUSIVE BEST Change Zrt., EV) |
| Kozponti-Munkaallomas-Setup-2.28.113.exe | sha256 OK, Authenticode **Valid** |
| Penztar-Eltavolito-2.28.113-20260912.exe | sha256 OK, Authenticode **Valid** |
| valuta-backend-2.28.113.jar | sha256 OK |
| Manifest header | `# Git SHA: 0df543d7...` = the bump merge commit |
| `munkaallomas.yml` (Kozponti channel) | version 2.28.113, sha512 matches the downloaded exe byte-for-byte |
| `update-manifest.json` (Penztar channel) | version 2.28.113, rolloutPercent 100, sha256 matches |

Downloads copy: `C:\zk\Downloads\valutavalto-v2.28.113\`.

## Live behaviour confirmed (re-checked 2026-09-13 14:08 UTC)

The feature is not just deployed, it has EXECUTED in production on real transactions:

| Receipt | Branch | Date | Rate age | Client timestamp | Result |
|---|---|---|---|---|---|
| V035100001 (BUY, 100 EUR @ 345.00) | BR035 Szeged Tisza Sarok | 2026-09-12 14:13 | 2347 h | 2026-09-12T14:13:57Z | COMPLETED |
| E035100001 (SELL, 100 EUR @ 362.00) | BR035 Szeged Tisza Sarok | 2026-09-13 13:46 | 2371 h | 2026-09-13T13:46:32Z | COMPLETED |

- 2 `STALE_RATE_TRANSACTION_COMMITTED` audit rows, each naming the currency, the rate age and the
  client timestamp - FR-4 satisfied on live data.
- `transaction.client_created_at` populated on both rows (FR-1 end-to-end: the client really sends it).
- `journalctl` since the rollout: 2 pass-through warnings, **0** "Az árfolyam lejárt" blocking errors.
- BR035 is therefore already running 2.28.113; other branches are unverified (the `workstation` table
  has no version column - there is no server-side client-version inventory).

## Open / next

1. **Installation on the remaining workstations is still pending** - the installers exist and are signed, but
   the fix only takes effect on a machine once 2.28.113 is actually installed there (Penztar via the
   suite installer / update manifest, Kozponti via `munkaallomas.yml`). Do not report the defect as
   fixed at the counters until a workstation reports 2.28.113.
2. **Accepted design risk (user decision, 2026-09-12):** `clientCreatedAt` is unauthenticated client
   data; a forged post-cutoff timestamp could replay an old stuck item. Bounded by: no new capability
   for a normal caller, audit + persisted `client_created_at` make it detectable. A follow-up option
   is binding the exemption to a server-observed first-seen instant (IdempotencyRecord) — not taken.
3. Board/issue #1744 (3 pre-existing frontend test failures in the two non-required coverage checks)
   still open, unrelated.
