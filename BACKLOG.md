# Valuta ERP - Backlog

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

---

## v2.3.0 (Sprint 8 candidate)

- C3 evnyito teljes automatizacio (Scheduled verzio bovebb logokkal)
- Cognee MCP live integracio (session memory auto-save)
- Obsidian vault sync
- Frontend: vault-stocktake UI finalizalas (cimlet nyomtatasi sablon)
- Penztar-client: stocktake offline queue UI