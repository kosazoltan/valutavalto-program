# Session: antivaluta_audit.md PP-08+PP-09 lezárás — v2.26.33

**Dátum:** 2026-05-24  
**PR:** #816 (admin-merged, squash)  
**Commit:** `5140b45f0`  
**Verzió:** v2.26.33  
**Production:** HEALTHY 200

---

## Elvégzett munka

### PP-08 — Auth Failure Spam in Offline Sync (`sync-engine.ts`)

**Root cause:** `bootstrapAuthSession()` null visszatérési értéke esetén (401/403, hiányzó credentials, hálózati hiba) a `runSync` a siker-ágon haladt tovább, `consecutiveFailures` 0-ra reset-elődött → végtelen 30s-es újrapróbálkozás, auth spam.

**Fix:**
- `authFailed` boolean flag a bootstrap eredményétől
- Ha `authFailed === true`:
  - HA failover rotáció (primary→fallback_primary→fallback_secondary→primary) az authFailed blokkban — mert `bootstrapAuthSession` hálózati hibákat elnyel és null-t ad vissza, így a catch-ág HA-logikája nem fut le
  - `consecutiveFailures += 1`
  - Ha `consecutiveFailures >= 3`: exponenciális backoff (`30_000 * 2^(failures-3)`, max `maxBackoffMs`)
  - Korai `return` — a siker-ág (consecutiveFailures reset) nem fut le

### PP-09 — Floating-Point Precision in SQLite (`sqlite.ts`)

**Root cause:** JS aritmetika eredménye (pl. `0.30000000000000004`) REAL (IEEE 754 double) oszlopba mentve → determinizmus-hiány, audit-eltérés.

**Fix:**
- `roundFin(v, decimals)` helper: `Number(v.toFixed(decimals))`
- `roundFinOrNull(v, decimals)` helper: `v === null ? null : roundFin(v, decimals)`
- Alkalmazva mind az INSERT értékekre, mind a `saveLocalAuditEvent` payload-ban:
  - `savePendingTransactionV2`: foreignAmount(8), hufAmount(2), roundedHufAmount(0), rate(10), handlingFee(0|null), discountPercent(4|null)
  - `savePendingConversionV2`: fromAmount(8), calculatedHufAmount(2), calculatedToAmount(8), conversionRate(10), handlingFee(0|null)

---

## AI Review eredmények (PR #816)

**Codex P1** — HA failover bypass: a `bootstrapAuthSession()` ALL exception-t elnyel és null-t ad vissza, ezért az authFailed korai return bypass-olná a catch-ágbeli HA rotációt. **Fix:** explicit HA rotáció az authFailed blokkban (copy of catch-block pattern).

**Copilot P2 × 4:**
1. package.json version-sync hiány (frontend-react 2.26.32 maradt) → fix: frontend-react bumped 2.26.33-ra 2. kör commitban
2. Comment "nem veszít precízióból" pontatlan → fix: "determinisztikus DB-tartalom, nem a teljes IEEE 754 pontosság megőrzése"
3. Audit payload nyers `input.*` értékek → fix: roundFin/roundFinOrNull alkalmazva audit payloadban is
4. roundFinOrNull inkonsistencia (undefined engedett, roundFin nem hívva) → fix: unified `(v: number | null, decimals: number): number | null => v === null ? null : roundFin(v, decimals)`

**Minden finding az aktuális squash-commit-ban javítva van.** (A review az `758fde828c` közbülső commitet nézte — stale.)

---

## 4-way Installer szet v2.26.33 (UNSIGNED)

| Fájl | Méret | SHA-256 |
|---|---|---|
| `Penztar-Setup-2.26.33-20260524.exe` | 283.84 MB | `A0EBF8A9A8669E1CDB3937F7A8563CA85BCCFCB80165774D6E9587FD8880C86A` |
| `Kozponti-Iranyitokozpont-Setup-2.26.33.exe` | 101.06 MB | `D9BC17AD584F2B6366AD550739A282B70C9D91AD995E56304F857ACECE457F17` |
| `Arfolyamkeszito-Setup-2.26.33.exe` | 101.06 MB | `7F8A6B2D909F8ED7F00CB4CF1B74780AA8A52203DB79EF5B597078E88039E28A` |
| `Penztar-Eltavolito-2.26.20-20260522.exe` | 59.43 KB | `5D84BE6AA024D9543B5B13F9E846255A6E05F700D8AE4750067E97539B5BDFB4` (verzió-független) |

**SmartScreen:** UNSIGNED — „További információ" → „Futtatás mindenképp"

---

## Teljes antivaluta_audit.md PP-sorozat állapota

| Finding | Severity | Lezárva | PR/Commit |
|---|---|---|---|
| PP-01 BranchController auth | CRITICAL | ✅ | PR #813 |
| PP-02 Cross-tenant IDOR | CRITICAL | ✅ | PR #813 |
| PP-03 AML cross-tenant | HIGH | ✅ | PR #813 |
| PP-04 CORS regex | HIGH | ✅ | PR #813 |
| PP-05 In-memory scope leak | HIGH | ✅ | PR #813 |
| PP-06 Race condition quota | HIGH | ✅ | PR #813 |
| PP-07 Double-storno race | HIGH | ✅ | PR #813 |
| PP-08 Auth spam | HIGH | ✅ | PR #816 |
| PP-09 Float precision | MEDIUM | ✅ | PR #816 |
| PP-10 OS path compat | LOW | ✅ | PR #813 |
| PP-11 Trigger DELETE crash | CRITICAL | ✅ | V263 migration |
| PP-12 License feature parse | CRITICAL | ✅ | LicenseService.java |

**12/12 finding lezárva. Audit COMPLETE.**
