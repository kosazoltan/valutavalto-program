# Session: PP-09 SQLite roundFin teljes lefedés — v2.26.36

**Dátum:** 2026-05-24  
**Verzió:** v2.26.36  
**PR:** #821 (admin-merged, squash, `0a1630c62`)  
**Trigger:** antivaluta_audit_2026_05_24.md PP-09 finding (OUTSTANDING a PP-16 lezárása után)

---

## Feladat

A v2.26.33-as PP-09 fix (roundFin a `savePendingTransactionV2` és `savePendingConversionV2`-ban) hiányos volt:
3 INSERT funkció + 2 legacy funkció még mindig nyers floating-point értékeket írt az SQLite outbox-ba.

SQLite `REAL` kolumna + IEEE 754 double → pl. `0.30000000000000004` tárolódik `0.3` helyett.
Offline sync → backend fogadja → bizonylaton helytelen összeg.

---

## Implementáció (2 commit, 1 fájl: `penztar-client/electron/sqlite.ts`)

### Commit 1 (40d6c5ee) — Initial PP-09 fix

**Séma:** REAL → TEXT (5 tábla) — VISSZAVONVA a 2. commitban!

**roundFin pótlás (3 funkció):**
- `savePendingBankTransaction`: `roundFin(amount, 8)` / `roundFin(exchangeRate, 10)` / `roundFin(hufAmount, 2)`
- `savePendingStorno`: `roundFinOrNull(foreignAmount, 8)` / `roundFin(hufAmount, 2)` / `roundFinOrNull(exchangeRate, 10)` / `roundFinOrNull(customExchangeRate, 10)`
- `savePendingTransfer`: `roundFin(amount, 8)` / `roundFinOrNull(hufValue, 2)`

### Commit 2 (ef469f8f) — AI review fix (Codex P1 + Copilot)

**Codex P1:** TEXT sémaváltás → `getPendingBankTransactions()` string-et ad vissza → `tx.exchangeRate?.toFixed(2)` frontend crash (új DB-n). Fix: REAL séma visszaállítva.

**Copilot finding:** Legacy `savePendingTransaction` és `savePendingConversion` még roundFin nélkül. Fix: mindkét legacy INSERT-be `roundFin`/`roundFinOrNull` helper + roundFin értékek.

**Copilot false positive (dismissed):** 3 new comment mondta "oszlopok TEXT-ek" — de azok már REAL-ra vissza lettek állítva. REAL kolumnánál Number visszatérés helyes.

---

## Érintett funkciók (összes, PP-09 után)

| Funkció | roundFin? | Mikor pótolva |
|---|---|---|
| `savePendingTransactionV2` | ✅ | v2.26.33 (PP-09 eredeti fix) |
| `savePendingConversionV2` | ✅ | v2.26.33 (PP-09 eredeti fix) |
| `savePendingTransaction` (legacy) | ✅ | v2.26.36 (ez a PR) |
| `savePendingConversion` (legacy) | ✅ | v2.26.36 (ez a PR) |
| `savePendingBankTransaction` | ✅ | v2.26.36 (ez a PR) |
| `savePendingStorno` | ✅ | v2.26.36 (ez a PR) |
| `savePendingTransfer` | ✅ | v2.26.36 (ez a PR) |

---

## roundFin paraméterek (iparági konvenció)

| Mező típusa | Decimals |
|---|---|
| Valuta összeg (foreignAmount, fromAmount, amount) | 8 |
| HUF összeg (hufAmount, hufValue, calculatedHufAmount) | 2 |
| Árfolyam (rate, exchangeRate, conversionRate) | 10 |
| Kerekített HUF (roundedHufAmount) | 0 |
| Kezelési díj (handlingFee) | 0 |
| Árengedmény % (discountPercent) | 4 |
| Kalkulált célvaluta összeg (calculatedToAmount) | 8 |

---

## CI gate eredmény

- Backend Build + Test: ✅ PASS
- penztar-client Test + Lint + TypeCheck + IPC Contract: ✅ PASS
- frontend-react Lint + TypeCheck: ✅ PASS
- CodeQL (java-kotlin + actions + javascript-typescript): ✅ PASS
- GitLeaks + Trivy + npm audit: ✅ PASS
- Sourcery: rate limit (nem finding)
- Codex: 👍 (első commit-on P1 finding → 2. commitban javítva)
- Copilot: 3 finding a 2. commiton → mind false positive (REAL kolumna + Number helyes)

---

## Build stratégia

**Electron-natív réteg érintett** (sqlite.ts) → **4-WAY TELEPÍTŐ-BUILD SZÜKSÉGES** (v2.26.36).
Build parancs: `powershell -ExecutionPolicy Bypass -File installer\build-installer.ps1 -SkipDownloads`

## Production

- Backend: nem érintett (Electron-only change → Hetzner auto-deploy nem fut)
- `curl https://excvaluta.com/api/v1/auth/bootstrap-status` → **200 OK**
- `curl https://excvaluta.com/api/v1/public/branches?companyCode=EBC` → **73 iroda**

---

## Tanulság

A PP-09 fix "hiányos volt" megállapítás pontos: az eredeti fix (v2.26.33) csak az V2-es INSERT path-okat fedte le. A legacy path-ok hosszú ideig unused lehetnek, de biztonsági szempontból minden INSERT-nél kötelező a roundFin.

**Kulcsdöntés:** séma marad REAL (nem TEXT). Indok: REAL→TEXT váltás a downstream frontend `.toFixed()` hívásokat törte volna (Codex P1). A floating-point zaj megelőzésére roundFin INSERT előtt elegendő.
