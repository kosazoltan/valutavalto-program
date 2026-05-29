# 2026-05-29 — FK-batch merge + prod-deploy + telepítő

## Mind merge-elve a main-re (v2.27.50), prod-deploy ÉLES
A user explicit „mindent jóváhagyok" + autonómia-felhatalmazás után `--admin` merge:
- #898 ShipmentNewPage teszt-fix · #899 FK-04/E.2 backend védelem (elveszett #885 helyreállítás)
- #900 FK-04/C compute · #901 storage · #902 FK-04/E protection
- #903 NAPI FORGALOM Ft (hufAmount) · #904 v2.5.54 kozmetikák (#9/#11/#17) · #905 Excel cégcím
- #906 FK-04/C-E **UI-bekötés** (képletcellák + publish-védelem) · #907 ablak-cím flavor szerint

**Prod-verifikáció (SSH Hetzner, hetzner_ed25519):** a backend `service_version:2.27.50` ÉLESBEN FUT
(legfrissebb log 2026-05-29T03:50Z), folyamat aktív. Az auto-deploy működött.

## FK-005 — PROD-VERIFIKÁLT MEGOLDOTT (nincs kód-fix)
A #895 prod-log (`/opt/valutavalto/backend/logs/valuta-backend.json.log`) bizonyítja:
```
territoryFilter: effectiveRole=ertektar, branch.vaultTerritoryId=null → null
getAllStock: findByCompanyId returned 1200 cash_balance rows
getAllStock END (no territory): 1156 rows after activeBranch filter (was 1200)
```
A getAllStock **1156 sort ad vissza** (nem 0), 403 nélkül. A FOERTEKTAR/ERTEKTAR nincs scope-szűrve
(vaultTerritoryId=null). A 05-24/26-i 0 Ft-ot a #859/#894 region-scope deploy-ok javították.
→ **Nincs javítandó. Prod healthy.**

## VAULT_COUNTERPARTY — nincs teendő (helyes-by-design)
region_code=NULL + nincs cash_balance → eleve kimaradnak a készletből (user: „ne tartsanak").

## Telepítő (folyamatban)
- Penztar-Setup build első kísérlet FAILED: `electron-builder` Azure-aláírást várt; fix:
  `ALLOW_UNSIGNED_BUILD=1` (a DigiCert EV CS validáció pending → unsigned, mint 2.27.46-49).
- Kozponti-Munkaallomas-Setup: `kozponti-client` `npm run package:unsigned` (electron-builder --win).
- Eltavolito: `installer/build-cleanup.ps1`.
- 4-way verzió-sync: mind 2.27.50 (check-version-sync.mjs OK).

## Prod hozzáférés (rögzítve)
Hetzner primary 95.216.191.162, SSH kulcs `~/.ssh/hetzner_ed25519` (root), backend systemd
`valuta-backend` (java -jar /opt/valutavalto/backend, NEM docker), log: logback JSON fájl
`/opt/valutavalto/backend/logs/valuta-backend.json.log` (+ Loki/Promtail stack). journalctl ÜRES (fájl-appender).
