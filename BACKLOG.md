# Valuta ERP - Backlog

> ⚠️ **ELAVULT (2026-06-01):** Ez a backlog a **v2.2.2** (2026-04-23) állapotot tükrözi, miközben a
> production már **v2.27.74**-en van (50+ release azóta). Az alábbi P0/P1 itemek nagy része valószínűleg
> rég javítva — **kötelező egyenkénti research-first re-triage** (kód + git log) MIELŐTT bármelyiken
> dolgoznál; ne tételezd fel, hogy nyitott. Megjegyzés: a "Transfer complete 500" / "Target cash_balance
> lock timeout" / "Source kassza holdAmount race" gyanús gyökér-okait a 2026-06-01-i globális
> cash-balance lock-ordering deadlock-megelőzés (#947/#951/#952/#953, CashLockOrdering) érintheti —
> ha a transfer-complete 500 reprodukálható, ott kezdd. Új, aktuális ledger: GitHub issues + a
> `vault/sessions/` legfrissebb jegyzetei + `vault/feedback/_active_mandates.md`.

## v2.2.2 hotfix (pending)

### [P0] Transfer complete 500-as hiba (BR017 -> BR035)

**Detektalva:** 2026-04-23 v2.2.1 elesi teszt soran
**Modul:** ertektar/transfer workflow
**Endpoint:** `POST /api/v1/ertektar/transfers/{id}/complete`

**Tunet:**
```
HTTP 500 Internal Server Error
{"timestamp": "2026-04-23T11:34:55.259333394", "status": 500, 
 "error": "INTERNAL_ERROR", "message": "Belso szerverhiba tortent..."}
```

**Reprodukalas:**
1. Login: EBC/ADMIN/Admin1234! (BR017)
2. POST `/api/v1/ertektar/transfers` (sourceBranchCode=BR017, targetBranchCode=BR035, currency=EUR, amount=50)
3. POST `/api/v1/ertektar/transfers/{id}/supervisor-approve` -> OK (status=IN_PROGRESS)
4. POST `/api/v1/ertektar/transfers/{id}/complete` -> 500

**Allapot mentese:**
- Transfer #6 state=IN_PROGRESS (beragad)
- BR035 has_cash_balance=True (init-branch=0 uj rekord)
- BR017 EUR balance=1150 (elegendo)

**Eredmeny:** uzletmenet-kritikus, ertektari transfer workflow megszakad.
A GUI-bol esetleg mukodik (transaction boundary / state diff)?

**Debug lepesek (v2.2.2-nel):**
1. SSH Hetzner -> `journalctl -u valuta-backend.service -n 100`
2. Stacktrace analysis: VaultTransferService.complete()
3. Transakcios hatar: @Transactional rollbackFor
4. Possible root causes:
   - Source kassza holdAmount update race condition
   - Target cash_balance lock timeout
   - currency_id resolve hibaja (currencyCode -> id mapping)
   - Audit log concurrent insert

**Workaround v2.2.1-ben:**
- Manualis SQL update a Hetzner DB-n:
  ```sql
  UPDATE vault_transfer SET status='COMPLETED', 
    completed_at=NOW(), completed_by='ADMIN' 
  WHERE id=6;
  -- + cash_balance rekord update kezzel
  ```

**Javitasi prioritás:** v2.2.2 kumulalt hotfix-ben (kozos release a kovetkezo
Sourcery+Codex review javitasokkal).

**Related:** Issue #110 (cash_balance deployment gap) - mar regisztralt.

### [P0] Bank transaction create 500-as hiba (vaultTerritory pair)

**Detektalva:** 2026-04-23 v2.2.1 ertektari teszt soran
**Modul:** ertektar/bank-transactions
**Endpoint:** `POST /api/v1/ertektar/bank-transactions`

**Tunet:**
```
POST /api/v1/ertektar/bank-transactions
Body: {"transactionType":"BUY", "currencyCode":"EUR", "amount":1000, 
       "exchangeRate":395.5, "vaultTerritoryId":1, "bankName":"Raiffeisen"}
-> HTTP 500 "Belso szerverhiba tortent"
```

**Pre-check OK:**
- GET /api/v1/territories -> id=1 Fo Ertektar active=true (tehat van territory)
- JWT: ADMIN role EBC-ben

**Potencialis gyoker-ok (kozos a #6 Transfer complete-vel):**
- VaultBankTransactionService internal state handling (cash_balance update)
- Transaction boundary Hibernate ManyToOne proxy conflict
- V156/V158 vault_territory adat valami belso inkonzisztencia

**Javitasi irany (v2.2.2):**
- SSH Hetzner -> journalctl -u valuta-backend.service -n 200
- Stacktrace analysis VaultBankTransactionService.createBankTransaction()
- Ha ugyanaz mint #6 Transfer complete -> kozos fix

**Workaround v2.2.1-ben:**
- Frontend GUI-bol mukodhet (mas transaction boundary)
- Manualis SQL:
  ```sql
  INSERT INTO vault_bank_transaction(...) VALUES(...);
  ```

### [P0] Collection complete NEM tolja a keszletet

**Detektalva:** 2026-04-23 teljes ertektari API teszt
**Modul:** VaultCollectionService.updateStatus()
**Endpoint:** `PATCH /api/v1/ertektar/collections/{id}/status?status=COMPLETED`

**Tunet:**
- Collection #2 BR017 -> ertektar 500 EUR letrehozva + COMPLETED
- De: GET /inventory/stock (VAULT entity) -> 0 item
- Tehat a bekerult EUR NEM megjelenik a vault CurrencyStock-ban

**Kovetkezmeny:**
- Bank transaction SELL 500-at dob (nincs valuta a vault-ban)
- Bank transaction BUY 500-at dob (nincs HUF a vault-ban)
- Teljes ertektari cash-flow workflow megszakad

**Forras:** 
`backend/.../service/VaultCollectionService.java:70+` updateStatus() csak
`collection.setStatus(newStatus)` + `collection.setCompletedAt()`, de NEM
hivja a `CurrencyStock.receiveStock()`-ot.

**Javitasi irany (v2.2.2):**
```java
if (newStatus == VaultOperationStatus.COMPLETED) {
    // CurrencyStock frissites a vault_territory-ra
    VaultTerritory territory = getFirstActiveTerritory(companyId);
    CurrencyStock vaultStock = getOrCreateStock(companyId, "VAULT",
        territory.getId().toString(), collection.getCurrencyCode());
    vaultStock.receiveStock(collection.getAmount(), currentExchangeRate);
    currencyStockRepository.save(vaultStock);
    
    // Source branch cash_balance csokkentes (BranchCashBalance)
    // ...
}
```

### [P0] Distribution complete NEM tolja a keszletet (hasonlo)

**Ugyanaz mint a Collection-ben:**
- Distribution.items (target branches) NEM kap CurrencyStock delta-t
- BranchCashBalance nem frissul
- Csak a status valtozik

**Forras:** `VaultDistributionService.updateStatus()` ugyanaz a bug.

### [P1] GET /distribution list items=0 (lazy init)

**Tunet:**
- `GET /ertektar/distribution` -> items=[] (ures)
- DE: `POST` utani response-ban items van (3 tetel)

**Javitasi irany:**
- `DistributionRepository.findByCompanyId()` -> @Query("... LEFT JOIN FETCH d.items ...")

### [P2] Collection status enum APPROVED ertek nem letezik

**Tunet:**
- PATCH /collections/{id}/status?status=APPROVED -> 400 "Failed to convert 'status' with value: 'APPROVED'"

**Valid enum:** REQUESTED, IN_PROGRESS, COMPLETED, REJECTED (nincs APPROVED)

**Javitas:** vagy enum boviteve vagy docs frissiteni

### [P3] Rolling window audit threshold nem config param

**Tunet:**
- GET /aml/rolling-window-audit?thresholdHuf=100000 -> hasznalja ezt
- De: default 4.5M HUF (.env vagy SystemParameter-ben kene)

**Jo hir:** mukodik elesen, TESZT-001 ugyfel 393%-on van (393K HUF / 100K limit).



---

## v2.3.0 (Sprint 8 candidate)

- C3 evnyito teljes automatizacio (Scheduled verzio bovebb logokkal)
- Cognee MCP live integracio (session memory auto-save)
- Obsidian vault sync
- Frontend: vault-stocktake UI finalizalas (cimlet nyomtatasi sablon)
- Penztar-client: stocktake offline queue UI