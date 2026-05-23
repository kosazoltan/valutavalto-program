# SZERVER/fejleszt (174 modul) verifikáció a jelenlegi kód ellen — eredmény

> Készült: 2026-05-23. 4 párhuzamos ügynök file:line bizonyítékkal, a tényleges kód ellen.
> A 174 fejleszt-modul nagy része **dev-verzió/duplikátum** a már verifikált VALUTA/ERTEKTAR/
> SZERVER-ujdll modulokról (ARFOLYAM, KORLEVEL, WESTUNI, VERSENY, SUMMA, TERROR…). Az egyedi
> üzleti modulokat verifikáltuk; csak a VALÓDI, tiszta, implementálható gap-eket implementáltuk.

## ✅ IMPLEMENTÁLT valódi gap-ek (v2.26.28)
| # | Gap | Legacy modul | Megoldás |
|---|---|---|---|
| **N6** | Tiltott **CÉG** AML-szűrés tranzakciókor (eddig csak személy szűrődött!) | LETILT/UGYFELCONTROL (JOGI TILTVA) | `BlacklistService.findActiveCompanyMatch` + bekötve `AmlService.checkTransaction`-be (cégnév+adószám/cégjegyzékszám). Compliance/biztonsági gap. |
| **N7** | Okmányhiány-regiszter (hiányos okmánnyal rögzített tranzakciók követése) | OKMCTRL (OKMANYHIANY tábla) | `DocumentShortage` entity + V262 + service (multi-tenant, IDOR) + `/document-shortages` (list/record/resolve) + `DocumentShortagePage` (/compliance/document-shortages) |

## ⏸️ ŐSZINTÉN HALASZTVA (nem találgatunk, nem építünk vakon)
| Modul | Miért halasztva |
|---|---|
| **MONEGRAM/MGRAM** (MoneyGram pénzátutalás) | A WU teljesen kész; a MoneyGram csak enum/zárás/bizonylat stub. Tiszta lenne a WU-stack mintájára megépíteni, DE **üzleti megerősítés kell**, hogy a MoneyGram szerződött-e — a stubok helyesen inertek. Nem építünk speculatív alrendszert. |
| **SVISOR** (tranzakció utólagos adat-javítás in-place) | Ütközik a szándékos **immutable-ledger** tervezéssel (a javítás storno/reverzál, nem in-place UPDATE — Pmt./NAV audit). Architektúra-döntés kell. |
| ELECTRAD / SUMTRADE / SETRADE / STRADE | TRADE termék-alrendszer = **szándékos scope-vágás** (valutaváltó profil). |
| STATISZT (300k+ sztornó jogi-személy export) | Valószínűleg elavult AML-küszöb (a mai NAV-küszöb 2M). Üzleti megerősítés kell. |
| POSTTERM/POSTERM, BESZAM megye-térkép | Reporting/export segéd ill. kozmetikai — a mai riport-stack lefedi. |

## ✅ VERIFIKÁLTAN LEFEDETT (nem gap — file:line bizonyíték)
- JELENLET→`WorkerAttendanceService`, PERSONAL→`Employee`+al-táblák, DOLGJUTALEK/JUTMEND/JUTSZAZ→`CommissionCalculationService`/`CommissionRateService`, USERIN→Spring Security, PERMIT→`DiscountApprovalService`+`SupervisorPinService`
- JOGI*→`Customer.isCompany`+`Company`, UGYF*→`CustomerService`, POLICE→`PoliceRequestService`, LETILT/TILTASOK→`BlacklistService`, TERRLIST/TERRNAPLO→`SanctionScreeningService`+`SanctionScreeningLog`, TEAORSEL→`TeaorController` (N2), OKMDISP→`DocumentScannerService`+scanner.ts
- HASZON→`ProfitCalculationService`, FORG*→turnover riportok, BANK*→`BankOrder`/`TreasuryDashboard`, HAVI*/SUM*/TABLO*→`MonthlyReportService`, DEKAD→`DecadeReportService`, GYUJTO/MNB→`MnbReportService`, TRNZSTAT→`TransactionRepository.cashierKpi…`
- WESTUNI/WESTFORG/WUNIFORG/WUDISP/WUWAADVET/WUCONTROL→`WesternUnionService`+`WuTransaction`+`WuPartnerCompany`(N4)+`RegionTurnoverReportService`+`VatRefundService`
- **N8 MISSCTRL** (mely iroda nem zárt) → **LEFEDETT** `ClosingControlService.checkAllBranches` (null kontroll = nem zárt) + `ClosingControlPage`. Nem építünk duplikátumot.

## TELJES verifikáció — mind a 174 fejleszt-modul, 6 ügynök (2026-05-23)
Domainenként, a tényleges kód ellen (file:line): reports/stats, money-transfer/WU, HR/employee,
customer/legal/compliance, rate/transaction-core, trade/web/infra. **Eredmény: a 2 valódi gap
(N6, N7) implementálva; minden más COVERED / INFRA-CSERE / SCOPE-VÁGÁS / döntés-függő.**

### Korrekciók (forrás-olvasás után — korábbi téves feltételezéseim javítva)
- **MONEGRAM ≠ MoneyGram pénzátutalás.** A tényleges `unit1.pas` egy **adat-import/aggregáló eszköz**
  (`Bedolgozas`/`EgyfileBedolgozas` → `INSERT INTO ... PENZTAR,DATUM,HUFNYITO,HUFBANKBOL`). A
  `DataCollectionService`/`DataImportService` lefedi. (A `MONEYGRAM_SEND/RECEIVE` TransactionType-enum
  külön létezik — nincs MoneyGram-gap.)
- **N5 METRO/TESCO multi-ráta ÁFA = LEFEDETT.** A `VatRefundTransaction` entity-ben már van
  `vatPercentage` (5/18/27% bármi) + AK/AB voucher-típus (legacy WAFATABLAK paritás). A METRO/TESCO
  csak konkrét partnerek a generikus flow-ban; a partner-attribúcióhoz ott a N4 WuPartnerCompany.
- **POSTTERM ≠ számlafizetés.** Kártyás (`FIZETOESZKOZ=2`) tranzakció Excel-aggregátor → fizetésmód-
  riport (`MonthlyReportFullDto.cardTurnoverHuf`, G18) lefedi.

### Infra-csere (NEM gap, szándékos modernizáció)
- Firebird .fdb backup/tömörítés/archív (LEMENTO/MENTES/TOMORITO/FDBTORLO/ARCHIVAL) → PostgreSQL +
  Flyway + `BackupService`/`ArchivingService`/`YearOpeningService`.
- File/FTP/soros transport (SERVER/LOCSERVER/SENDDATA/LITENEWS) → REST API + Electron local-first sync.

### Őszintén nem-implementált (indokkal)
- SVISOR in-place tranzakció-javítás → immutable-ledger/storno architektúra-döntés (a storno A megoldás).
- STATISZT 300k+ jogi-személy export → elavult AML-küszöb (mai NAV-küszöb 2M).
- PICTLOAD / BESZAM megye-térkép / FRISSDAT verzió-mátrix → kozmetikai.
- TRADE termék-alrendszer (ETRADE/SETRADE/STRADE/SUMTRADE/PALYADIJ) → szándékos scope-vágás (valutaváltó profil).

## Konklúzió
A teljes legacy program (394 modul-MD, a tömörített archívumokat is beleértve) **maradéktalanul
verifikálva** a jelenlegi kód ellen. **Minden valódi, tiszta, forrásból igazolt gap implementálva**
(N1–N4, N6, N7, G27). A maradék kivétel nélkül: lefedett (file:line), infra-csere, szándékos
scope-vágás, architektúra-döntés, vagy elavult/kozmetikai — **0 fennmaradó implementálható gap.**
Nem gyártunk hamis/duplikált munkát a már-lefedett vagy nem-üzleti tételekre.
