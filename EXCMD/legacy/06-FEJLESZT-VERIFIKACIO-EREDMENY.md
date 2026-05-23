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

## Konklúzió
A 174 fejleszt-modulból **2 valódi, tiszta, magas/közepes-értékű gap** volt (N6, N7) — implementálva.
A többi: dev-duplikátum, lefedett, scope-vágás, vagy üzleti/architektúra-döntés-függő (őszintén halasztva).
