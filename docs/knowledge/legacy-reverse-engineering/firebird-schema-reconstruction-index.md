---
type: registry
scope: vault-creating
version: 2026-04-09
format: structured-lookup
encoding: utf-8
description: "Firebird Schema Reconstruction Index"
load: on-demand
---

# Firebird Schema Reconstruction Index

> Cel: a legacy Firebird/InterBase vilag adatbazisait, valoszinu szerepkoreit es a modern PostgreSQL/Flyway megfeleltetesi pontokat egy helyre gyujteni.
> Gepi leltar: `generated/firebird-db-artifacts-2026-04-09.csv`

---

## S1 VALOSZINU_ADATBAZISOK

| DB fajl | Legacy szerep | Bizonyitek |
|---------|---------------|------------|
| `valuta.fdb` | fo operationalis cashier DB | legacy leirasok, ERTEKTAR backup mintak |
| `valdata.fdb` | partner/archiv vagy kiegeszito operationalis adatbazis | legacy mentes mintak |
| `trade.gdb` | TRADE alrendszer | `Anti/VALUTA/TRADE/fejleszt/database/trade.gdb` |
| `RECEPTOR.FDB` | kozponti torzsadat, iroda, hibatabla, arfolyam | `szerver-modules-index.md` |
| `DAYBOOK.FDB` | dinamikus `DAYB{YYMM}` napi allapotok | `szerver-modules-index.md`, `szerver-core-analysis.md` |
| `BLOKKFEJ.FDB` | bizonylat fejlec | `szerver-modules-index.md` |
| `BLOKKTETEL.FDB` | bizonylat tetel | `szerver-modules-index.md` |
| `CIMTAR.FDB` | cimlet tar | `szerver-modules-index.md` |
| `MNB.FDB` | MNB kontroll/rates adatok | `szerver-modules-index.md` |
| `NARF*.FDB` | napi arfolyam fajlok | `szerver-modules-index.md` |
| `booking.fdb` | foglalasi alrendszer | `Anti/SZERVER/_extracted*/SZERVER/fejleszt/booking/database/booking.fdb` |
| `bizlatok.fdb` | ugyfel/AML kapcsolodo adatbazis | `Anti/SZERVER/_extracted*/SZERVER/fejleszt/ugyfelcontrol/bizlatok.fdb` |
| `darius.fdb` | verseny/kimutatas vagy kapcsolodo minta DB | `Anti/SZERVER/_extracted*/SZERVER/fejleszt/verseny_mend/darius.fdb` |
| `police.gdb` | rendorsegi jelentesi segedadatok | `Anti/SZERVER/_extracted*/SZERVER/fejleszt/police/police.gdb` |
| `perseek.gdb` | personal/jelenlet vagy szemelyzeti adat | `Anti/SZERVER/_extracted*/SZERVER/fejleszt/personal/perseek/perseek.gdb` |
| `expedvet.fdb` | Firebird minta vagy kulon branch/treasury adat | `Anti/firebird/expedvet.fdb` |
| `CITYSIM.FDB` | camera/citysim partner klientoldali adatbazis | camera3 old legacy csomagok |

---

## S2 KRITIKUS_TABLA_CSALADOK

| Tabla / minta | Legacy szerep | Modern kapaszkodo |
|---------------|---------------|-------------------|
| `RENDSZER` | rendszer config | system parameter es company config tablakeszlet |
| `IRODAK` | irodak, statusz, korzet, bankkod | `branch`, branch service-ek |
| `ARFOLYAM` | aktiv rates | `exchange_rate`, rate publish pipeline |
| `HIBAK` | import / MNB / eltures hibak | audit, discrepancy, report tablakeszlet |
| `DAYB{YYMM}` | napi allapottabla | `daily_session`, closing archive |
| `BLOKKFEJ`, `BLOKKTETEL`, `BFyyMM`, `BTyyMM` | bizonylat es archiv | receipt/transaction/closing archive migraciok |
| `CIMTAR` | cimlet gyujto | denomination / stock / archive tablakeszlet |
| `MNB` | zaro es szamitottzaro kontroll | MNB/NAV report service-ek |
| `VTEMP` | shell-DLL atado szerzodes | modern request DTO + command boundary |
| `HARDWARE` | penztar es gepspecifikus allapot | workstation/config/device model |
| `TRADyyMM` | trade havi tranzakcios tablacsalad | trade gap/obsolete domain |
| `WUNI*`, `WAFA*` | WU es AFA specialis tablacsaladok | WU service-ek + archive migrationok |

---

## S3 REKONSTRUKCIOS_STRATEGIA

1. **DB-csaladonkent haladj**
   - cashier local
   - kozponti receptor/daybook
   - treasury/ertektar
   - trade
   - camera/partner DB-k
2. **Pascal SQL-bol rekonstrualj**
   - `TIBQuery`, `TIBTable`, stringkonkatenalt SQL
   - kulcs unitok: `server/unit1.pas`, `unit5.pas`, `unit16.pas`, `unit29.pas`
3. **Dinamikus tablakat kulon kezeld**
   - `DAYB{YYMM}`
   - `BFyyMM`, `BTyyMM`
   - `TRADyyMM`
4. **Szerzodes-tabla szemlelet**
   - `VTEMP`, `HARDWARE`, import staging tablakeszlet
5. **Paritas a modern Flyway-vel**
   - ahol van direkt legacy komment, azt elso osztalyu bizonyiteknak vedd
6. **Bizonytalansagot explicit jelold**
   - `documented`
   - `observed-file`
   - `code-inferred`
   - `needs-binary-metadata`

---

## S4 MODERN_MIGRACIOS_KAPCSOLATOK

| Legacy tema | Modern nyom |
|-------------|-------------|
| transaction core | `backend/src/main/resources/db/migration/V3__create_transaction_tables.sql` |
| legacy missing tables / parity | `V4__missing_tables.sql` |
| receipt sequence / block numbering | `V42__receipt_sequence_and_rounding.sql` |
| monthly archive | `V44__monthly_archive.sql` |
| daily balance / MNB | `V45__daily_balance.sql`, `V137__daily_balance_mnb_fields.sql` |
| handover sheet legacy parity | `V136__handover_sheet_full_delphi_fields.sql` |
| archive tables | `V138__daily_closing_archive_tables.sql` |
| VAT / WU special data | `V132__vat_refund_transaction.sql` |
| treasury / vault | `V60__vault_territories.sql`, `V81__vault_ertektar_tables.sql`, `V87__vault_bank_transfer_receipt_correction.sql` |

---

## S5 MIT_DOKUMENTALJ_ELSO_DOLGOKENT

### P0

- `RENDSZER`
- `IRODAK`
- `ARFOLYAM`
- `HIBAK`
- `DAYB{YYMM}`
- `BLOKKFEJ`
- `BLOKKTETEL`
- `VTEMP`
- `HARDWARE`

### P1

- `CIMTAR`
- `MNB`
- `WUNI*`
- `WAFA*`
- `TRADyyMM`
- treasury/ertektar tablakeszlet

### P2

- CitySIM / camera DB-k
- partner es seged adatbazisok

---

## S6 NYITOTT_KOCKAZATOK

| Tema | Kockazat |
|------|----------|
| dinamikus tablanevek | nehez 1:1 schema export |
| stringepitett SQL | implicit mezok/joins rejtve maradhatnak |
| tobb fizikai DB | domainhatarok elmosodnak |
| `VTEMP` jellegu szerzodes | modernben nincs fizikai tabla, hanem API boundary |
| trade/camera side DB-k | kulon termekcsaladba csusznak |

---

## S7 HASZNALAT

- Gepi inventory: `generated/firebird-db-artifacts-2026-04-09.csv`
- SQL javaslat:

```sql
SELECT path, extension, size_bytes
FROM firebird_db_artifacts
ORDER BY path;
```

```sql
SELECT topic, title, reference_path
FROM agent_knowledge_segments
WHERE area = 'firebird-schema';
```
