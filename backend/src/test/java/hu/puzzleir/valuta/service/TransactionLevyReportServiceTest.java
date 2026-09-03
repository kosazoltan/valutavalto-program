package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.levy.TransactionLevyReportDto;
import hu.puzzleir.valuta.dto.levy.TypeGroupDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.TransactionLevyRateHistory;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.TransactionLevyRateHistoryRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.groups.Tuple.tuple;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.ArgumentMatchers.isNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-099 B-sorozat — riport use case (WU1 RED → WU4 GREEN).
 *
 * <p>A fixture-k {@code Object[]} sorok, pontosan a
 * {@code findTransactionLevySourceRows} vetületi sorrendjében:
 * (date, branchId, branchCode, branchName, type, hufAmount,
 * conversionGroupId, financialEffective, customerId, status). A status
 * oszlop a round-2 D19 parent-status projekciója (FR-16 csoport-szint).</p>
 *
 * <p>Megj.: a query-predikátumok (WU-kizárás, REVERSED-kizárás, konverzió
 * dupla-adóztatás elleni őrzés) valós PostgreSQL-en a
 * {@code TransactionLevySourceRowsPostgresIT} P-esetei alatt futnak; itt a
 * service-fold logikája és az RBAC/audit/validáció van pinelve.</p>
 */
@ExtendWith(MockitoExtension.class)
class TransactionLevyReportServiceTest {

    private static final UUID COMPANY_ID = UUID.fromString("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
    private static final UUID BRANCH_ID_001 = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa1");
    private static final UUID BRANCH_ID_002 = UUID.fromString("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaa2");
    private static final UUID FOREIGN_BRANCH_ID = UUID.fromString("cccccccc-cccc-cccc-cccc-cccccccccccc");
    private static final LocalDate D1 = LocalDate.of(2026, 8, 3);
    private static final LocalDate D2 = LocalDate.of(2026, 8, 4);
    private static final LocalDate FROM = LocalDate.of(2026, 8, 1);
    private static final LocalDate TO = LocalDate.of(2026, 8, 31);

    @Mock private TransactionRepository transactionRepository;
    @Mock private TransactionLevyRateHistoryRepository rateHistoryRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private AuditLogService auditLogService;
    @Mock private DictionaryRepository dictionaryRepository;

    private TransactionLevyReportService service;

    @BeforeEach
    void setUp() {
        service = new TransactionLevyReportService(
                transactionRepository, rateHistoryRepository, branchRepository, auditLogService,
                dictionaryRepository);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    // ============================ FIXTURE-HELPEREK ============================

    private static Object[] row(LocalDate date, UUID branchId, String branchCode, String branchName,
                                TransactionType type, String hufAmount, UUID conversionGroupId,
                                boolean financialEffective, String customerId, TransactionStatus status) {
        return new Object[]{date, branchId, branchCode, branchName, type,
                new BigDecimal(hufAmount), conversionGroupId, financialEffective, customerId, status};
    }

    private static Object[] buyRow(LocalDate date, String hufAmount, String customerId) {
        return row(date, BRANCH_ID_001, "001", "Fo utca", TransactionType.BUY,
                hufAmount, null, true, customerId, TransactionStatus.COMPLETED);
    }

    private static Object[] sellRow(LocalDate date, String hufAmount, String customerId) {
        return row(date, BRANCH_ID_001, "001", "Fo utca", TransactionType.SELL,
                hufAmount, null, true, customerId, TransactionStatus.COMPLETED);
    }

    /** V384 seed: 0.45% / 20000 mindket komponensre, flag TRUE. */
    private static TransactionLevyRateHistory seedRate() {
        return rateRow(LocalDate.of(2013, 1, 1), "0.450", "20000.00", true);
    }

    private static TransactionLevyRateHistory rateRow(
            LocalDate from, String ratePercent, String cap, boolean singleSide) {
        return TransactionLevyRateHistory.builder()
                .companyId(COMPANY_ID)
                .effectiveFrom(from)
                .baseRatePercent(new BigDecimal(ratePercent))
                .baseRateCapHuf(new BigDecimal(cap))
                .supplementRatePercent(new BigDecimal(ratePercent))
                .supplementRateCapHuf(new BigDecimal(cap))
                .conversionSingleSideFlag(singleSide)
                .createdBy("V384")
                .build();
    }

    private void authenticate(String role) {
        UsernamePasswordAuthenticationToken token = new UsernamePasswordAuthenticationToken(
                "WK099", "n/a", List.of(new SimpleGrantedAuthority("ROLE_" + role)));
        token.setDetails(new WorkerAuthenticationDetails(42L, COMPANY_ID, null, role));
        SecurityContextHolder.getContext().setAuthentication(token);
    }

    private void stubRates(TransactionLevyRateHistory... rates) {
        when(rateHistoryRepository.findByCompanyIdOrderByEffectiveFromDesc(COMPANY_ID))
                .thenReturn(List.of(rates));
    }

    private void stubRows(Object[]... rows) {
        when(transactionRepository.findTransactionLevySourceRows(
                eq(COMPANY_ID), any(), any(), any(), any()))
                .thenReturn(List.of(rows));
    }

    private static void assertZeroGroup(TypeGroupDto group) {
        assertThat(group.getNormalBaseLevy()).isEqualByComparingTo("0");
        assertThat(group.getNormalSupplementLevy()).isEqualByComparingTo("0");
        assertThat(group.getAboveThresholdCount()).isZero();
        assertThat(group.getAboveThresholdBaseLevy()).isEqualByComparingTo("0");
        assertThat(group.getAboveThresholdSupplementLevy()).isEqualByComparingTo("0");
    }

    // ============================ B1–B3: alap számok ============================

    @Test
    @DisplayName("B1/FR-2/3: onallo BUY 3M → buy.normalBase/Supplement 13500, levyTotal 27000")
    void b1_standaloneBuyThreeMillion() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(buyRow(D1, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).hasSize(1);
        TransactionLevyReportDto.Row r = report.getRows().get(0);
        assertThat(r.getDate()).isEqualTo(D1);
        assertThat(r.getBranchCode()).isEqualTo("001");
        assertThat(r.getBuy().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(r.getBuy().getNormalSupplementLevy()).isEqualByComparingTo("13500");
        assertThat(r.getBuy().getAboveThresholdCount()).isZero();
        assertThat(r.getLevyTotal()).isEqualByComparingTo("27000");
        assertThat(r.getLargeBaseHuf()).isEqualByComparingTo("0");
        assertZeroGroup(r.getSell());
        assertZeroGroup(r.getConversion());
    }

    @Test
    @DisplayName("B2/FR-9/10: onallo BUY 5M → aboveThreshold 1, 20000+20000, Nagy-alap 5M, Tranz.dij 40000")
    void b2_standaloneBuyFiveMillionAboveThreshold() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(buyRow(D1, "5000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        TransactionLevyReportDto.Row r = report.getRows().get(0);
        assertThat(r.getBuy().getAboveThresholdCount()).isEqualTo(1);
        assertThat(r.getBuy().getNormalBaseLevy()).isEqualByComparingTo("0");
        assertThat(r.getBuy().getAboveThresholdBaseLevy()).isEqualByComparingTo("20000");
        assertThat(r.getBuy().getAboveThresholdSupplementLevy()).isEqualByComparingTo("20000");
        assertThat(r.getLargeBaseHuf()).isEqualByComparingTo("5000000");
        // FR-10: a Tranz.díj CSAK a hat illeték-komponens — a Nagy-alap NEM illeték.
        assertThat(r.getLevyTotal()).isEqualByComparingTo("40000");
    }

    @Test
    @DisplayName("B3/FR-4: onallo SELL 3M → a számok a sell-csoportba kerülnek, buy nulla")
    void b3_standaloneSellLandsInSellGroup() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(sellRow(D1, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        TransactionLevyReportDto.Row r = report.getRows().get(0);
        assertThat(r.getSell().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(r.getSell().getNormalSupplementLevy()).isEqualByComparingTo("13500");
        assertThat(r.getLevyTotal()).isEqualByComparingTo("27000");
        assertZeroGroup(r.getBuy());
        assertZeroGroup(r.getConversion());
    }

    // ============================ B4–B6: konverzió (a fő csapda) ============================

    private static final UUID GROUP_G1 = UUID.fromString("dddddddd-dddd-dddd-dddd-dddddddddddd");

    private static Object[] conversionParentRow() {
        return row(D1, BRANCH_ID_001, "001", "Fo utca", TransactionType.CONVERSION,
                "3000000", GROUP_G1, false, "C3", TransactionStatus.COMPLETED);
    }

    private static Object[] convBuyChildRow() {
        return row(D1, BRANCH_ID_001, "001", "Fo utca", TransactionType.BUY,
                "3000000", GROUP_G1, true, "C3", TransactionStatus.COMPLETED);
    }

    private static Object[] convSellChildRow() {
        return row(D1, BRANCH_ID_001, "001", "Fo utca", TransactionType.SELL,
                "2990000", GROUP_G1, true, "C3", TransactionStatus.COMPLETED);
    }

    /** D18/D19: sztornózott parent — REVERSED státuszú CONVERSION sor (a childok COMPLETED-ek maradnak). */
    private static Object[] reversedConversionParentRow() {
        return row(D1, BRANCH_ID_001, "001", "Fo utca", TransactionType.CONVERSION,
                "3000000", GROUP_G1, false, "C3", TransactionStatus.REVERSED);
    }

    /** B30/D18 szélesség: CANCELLED parent — a szabály „nem COMPLETED", nem „REVERSED". */
    private static Object[] cancelledConversionParentRow() {
        return row(D1, BRANCH_ID_001, "001", "Fo utca", TransactionType.CONVERSION,
                "3000000", GROUP_G1, false, "C3", TransactionStatus.CANCELLED);
    }

    @Test
    @DisplayName("B4/FR-5: konverzió EGYSZER adózik — parent+2 child → Konverzió 27000, Vétel/Eladás 0")
    void b4_conversionGroupLeviedOnce() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(conversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).hasSize(1);
        TransactionLevyReportDto.Row r = report.getRows().get(0);
        assertThat(r.getConversion().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(r.getConversion().getNormalSupplementLevy()).isEqualByComparingTo("13500");
        assertZeroGroup(r.getBuy());
        assertZeroGroup(r.getSell());
        assertThat(r.getLevyTotal()).isEqualByComparingTo("27000");
    }

    @Test
    @DisplayName("B5/D21 legacy: NINCS parent sor egyáltalán (nem sztornózott) — a convBuy hufAmount az alap")
    void b5_conversionFallbackToConvBuyWhenParentMissing() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        TransactionLevyReportDto.Row r = report.getRows().get(0);
        assertThat(r.getConversion().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(r.getConversion().getNormalSupplementLevy()).isEqualByComparingTo("13500");
        assertZeroGroup(r.getBuy());
        assertZeroGroup(r.getSell());
        assertThat(r.getLevyTotal()).isEqualByComparingTo("27000");
    }

    @Test
    @DisplayName("B6/D6: flag FALSE — convBuy a Vételbe, convSell az Eladásba, Konverzió nulla")
    void b6_flagFalseSplitsLegsIntoBuyAndSell() {
        authenticate("FOERTEKTAR");
        stubRates(rateRow(LocalDate.of(2013, 1, 1), "0.450", "20000.00", false));
        stubRows(conversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        TransactionLevyReportDto.Row r = report.getRows().get(0);
        // convBuy 3 000 000 → 13 500 + 13 500 a Vétel csoportban
        assertThat(r.getBuy().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(r.getBuy().getNormalSupplementLevy()).isEqualByComparingTo("13500");
        // convSell 2 990 000 × 0.45% = 13 455 → 13 455 + 13 455 az Eladásban
        assertThat(r.getSell().getNormalBaseLevy()).isEqualByComparingTo("13455");
        assertThat(r.getSell().getNormalSupplementLevy()).isEqualByComparingTo("13455");
        assertZeroGroup(r.getConversion());
        assertThat(r.getLevyTotal()).isEqualByComparingTo("53910");
    }

    // ============================ B27–B32: FR-16 csoport-szint (round-2 D18/D19/D20) ============================

    @Test
    @DisplayName("B27/FR-16/D18: sztornózott parent (REVERSED) + COMPLETED childok → EGÉSZ csoport 0 illeték, "
            + "üres rows/appliedRates (flag TRUE)")
    void b27_reversedParentYieldsZeroLevyFlagTrue() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(reversedConversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        // A konverzió-napra nem keletkezik sor: a csoport 0-t ad, önálló tétel nincs.
        assertThat(report.getRows()).isEmpty();
        TransactionLevyReportDto.Row totals = report.getTotals();
        assertThat(totals.getLevyTotal()).isEqualByComparingTo("0");
        assertThat(totals.getLargeBaseHuf()).isEqualByComparingTo("0");
        assertZeroGroup(totals.getConversion());
        assertZeroGroup(totals.getBuy());
        assertZeroGroup(totals.getSell());
        // D22: sztornózott csoport nem növeli az appliedRates-t (ráta-feloldás előtt tér vissza).
        assertThat(report.getAppliedRates()).isEmpty();
        // A havi panel érintetlen (konverzió eleve nem ad hozzá — B13).
        assertThat(report.getMonthlySummary().getBuyCount()).isZero();
        assertThat(report.getMonthlySummary().getSellCount()).isZero();
        assertThat(report.getMonthlySummary().getCustomerCount()).isZero();
    }

    @Test
    @DisplayName("B28/FR-16/D18 flag FALSE alatt: sztornózott csoport → Vétel ÉS Eladás is 0, "
            + "a D6 láb-split NEM futhat le")
    void b28_reversedParentYieldsZeroLevyFlagFalse() {
        authenticate("FOERTEKTAR");
        stubRates(rateRow(LocalDate.of(2013, 1, 1), "0.450", "20000.00", false));
        stubRows(reversedConversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).isEmpty();
        TransactionLevyReportDto.Row totals = report.getTotals();
        assertThat(totals.getLevyTotal()).isEqualByComparingTo("0");
        assertZeroGroup(totals.getBuy());
        assertZeroGroup(totals.getSell());
        assertZeroGroup(totals.getConversion());
        assertThat(report.getAppliedRates()).isEmpty();
    }

    @Test
    @DisplayName("B29/D20 jó fele: COMPLETED parent + childok → változatlan B4 eredmény (Konverzió 27000)")
    void b29_completedParentUnchanged() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(conversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).hasSize(1);
        TransactionLevyReportDto.Row r = report.getRows().get(0);
        assertThat(r.getConversion().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(r.getConversion().getNormalSupplementLevy()).isEqualByComparingTo("13500");
        assertZeroGroup(r.getBuy());
        assertZeroGroup(r.getSell());
        assertThat(r.getLevyTotal()).isEqualByComparingTo("27000");
    }

    @Test
    @DisplayName("B30/D18 szélesség: CANCELLED parent → szintén 0 — a szabály „nem COMPLETED\", nem „REVERSED\"")
    void b30_cancelledParentYieldsZeroLevy() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(cancelledConversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).isEmpty();
        assertThat(report.getTotals().getLevyTotal()).isEqualByComparingTo("0");
        assertZeroGroup(report.getTotals().getConversion());
        assertThat(report.getAppliedRates()).isEmpty();
    }

    @Test
    @DisplayName("B31/D18+vegyes nap: sztornózott csoport MELLETT önálló BUY érintetlenül illetékezik")
    void b31_voidedGroupBesideStandaloneBuy() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(reversedConversionParentRow(), convBuyChildRow(), convSellChildRow(),
                buyRow(D1, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).hasSize(1);
        TransactionLevyReportDto.Row r = report.getRows().get(0);
        assertThat(r.getBuy().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(r.getBuy().getNormalSupplementLevy()).isEqualByComparingTo("13500");
        assertZeroGroup(r.getConversion());
        assertZeroGroup(r.getSell());
        assertThat(r.getLevyTotal()).isEqualByComparingTo("27000");
    }

    @Test
    @DisplayName("B32/D22: sztornózott csoport + NINCS hatályos ráta → NEM D7 400, hanem üres riport")
    void b32_voidedGroupNeedsNoRate() {
        authenticate("FOERTEKTAR");
        stubRates();
        stubRows(reversedConversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).isEmpty();
        assertThat(report.getTotals().getLevyTotal()).isEqualByComparingTo("0");
        assertThat(report.getAppliedRates()).isEmpty();
    }

    // ============================ B33–B35: D1 sorrend-szerződés (round-3) ============================

    @Test
    @DisplayName("B33/D1 (FK-101 FR-1): vegyes branch+date fixture → branchCode ASC az elsődleges, "
            + "date ASC a másodlagos rendezési kulcs")
    void b33_rowsAreBranchCodeAscendingThenDateAscending() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // FK-101 FR-1: the row order contract is branchCode ASC primary, date ASC
        // secondary. Mixed standalone rows (D1,002), (D2,001), (D1,001) must come
        // out as [("001",D1), ("001",D2), ("002",D1)]. The HEAD comparator is
        // date-first, so this test is RED until the keys are swapped.
        stubRows(
                row(D1, BRANCH_ID_002, "002", "Meldek", TransactionType.BUY,
                        "3000000", null, true, "C2", TransactionStatus.COMPLETED),
                buyRow(D2, "3000000", "C1"),
                buyRow(D1, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).hasSize(3);
        assertThat(report.getRows())
                .as("B33/FK-101 FR-1: branchCode ASC primary, date ASC secondary")
                .extracting(TransactionLevyReportDto.Row::getBranchCode,
                        TransactionLevyReportDto.Row::getDate)
                .containsExactly(tuple("001", D1), tuple("001", D2), tuple("002", D1));
    }

    @Test
    @DisplayName("B34/D1: azonos nap, branchCode-fordulás (önálló 002 előbb a foldban) → branchCode ASC [001, 002]")
    void b34_rowsAreBranchCodeAscendingWithinSameDate() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // DB-rend: konverzió D1-001 előbb, önálló D1-002 utána; a service mégis az
        // önállót (002) szúrja be a rowsByKey-ba előbb.
        stubRows(conversionParentRow(), convBuyChildRow(), convSellChildRow(),
                row(D1, BRANCH_ID_002, "002", "Meldek", TransactionType.SELL,
                        "3000000", null, true, "C2", TransactionStatus.COMPLETED));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).hasSize(2);
        assertThat(report.getRows())
                .as("B34/D1: azonos napon branchCode ASC — 001 a konverzióval előbb")
                .extracting(TransactionLevyReportDto.Row::getBranchCode)
                .containsExactly("001", "002");
    }

    @Test
    @DisplayName("B35/D1 invariáns: a rendezés SEMMIT nem változtat a pénzügyi értékeken "
            + "(totals/levyTotal/largeBaseHuf azonos)")
    void b35_sortIsBehaviorPreservingForFinancialValues() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(conversionParentRow(), convBuyChildRow(), convSellChildRow(),
                buyRow(D2, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        // Konverzió 27 000 + önálló BUY 27 000 = 54 000 — beszúrási sorrendtől függetlenül.
        assertThat(report.getTotals().getLevyTotal()).isEqualByComparingTo("54000");
        assertThat(report.getTotals().getLargeBaseHuf()).isEqualByComparingTo("0");
        assertThat(report.getTotals().getConversion().getNormalBaseLevy())
                .isEqualByComparingTo("13500");
        assertThat(report.getTotals().getConversion().getNormalSupplementLevy())
                .isEqualByComparingTo("13500");
        assertThat(report.getTotals().getBuy().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(report.getTotals().getBuy().getNormalSupplementLevy()).isEqualByComparingTo("13500");
        assertThat(report.getTotals().getSell().getNormalBaseLevy()).isEqualByComparingTo("0");
    }

    // ============================ B7–B8: query-szintű kizárások (mock-oldal) ============================

    @Test
    @DisplayName("B7/FR-15: WU/MG sorok a query-predikátum miatt be sem jönnek — a riport azonos B1-gyel")
    void b7_westernUnionAndMoneygramExcludedAtQueryLevel() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // A query kizárja a WESTERN_UNION_* / MONEYGRAM_* / VIGNETTE sorokat — a service-hez
        // ezért CSAK a B1 BUY sor érkezik meg (a predikátumot a Postgres IT P3 pineli valós DB-n).
        stubRows(buyRow(D1, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        verify(transactionRepository, times(1)).findTransactionLevySourceRows(
                eq(COMPANY_ID), isNull(), eq(FROM), eq(TO), isNull());
        assertThat(report.getRows()).hasSize(1);
        assertThat(report.getRows().get(0).getBuy().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(report.getRows().get(0).getLevyTotal()).isEqualByComparingTo("27000");
    }

    @Test
    @DisplayName("B8/FR-16: REVERSED tranzakció a query status-szűrője miatt nem ad sort")
    void b8_reversedExcludedAtQueryLevel() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // A REVERSED sort a `status = COMPLETED` predikátum kizárja (a Postgres IT P4 pineli);
        // a service üres forrás-készletet kap.
        stubRows();

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        verify(transactionRepository).findTransactionLevySourceRows(
                eq(COMPANY_ID), isNull(), eq(FROM), eq(TO), isNull());
        assertThat(report.getRows()).isEmpty();
        assertThat(report.getTotals().getLevyTotal()).isEqualByComparingTo("0");
    }

    // ============================ B9: ÖSSZESEN sor ============================

    @Test
    @DisplayName("B9/FR-11: két pénztár-nap → totals komponensenkénti összeg, branch-mezők null-ok")
    void b9_totalsRowIsComponentwiseSumWithNullBranchFields() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(
                buyRow(D1, "3000000", "C1"),
                row(D2, BRANCH_ID_002, "002", "Meldek", TransactionType.SELL,
                        "5000000", null, true, "C2", TransactionStatus.COMPLETED));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).hasSize(2);
        TransactionLevyReportDto.Row totals = report.getTotals();
        assertThat(totals.getBuy().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(totals.getSell().getAboveThresholdBaseLevy()).isEqualByComparingTo("20000");
        assertThat(totals.getSell().getAboveThresholdSupplementLevy()).isEqualByComparingTo("20000");
        assertThat(totals.getLargeBaseHuf()).isEqualByComparingTo("5000000");
        assertThat(totals.getLevyTotal()).isEqualByComparingTo("67000");
        assertThat(totals.getDate()).isNull();
        assertThat(totals.getBranchId()).isNull();
        assertThat(totals.getBranchCode()).isNull();
        assertThat(totals.getBranchName()).isNull();
    }

    // ============================ B10–B13: havi panel ============================

    @Test
    @DisplayName("B10/FR-12: buyCount/sellCount = tranzakció-darabszám; customerCount = distinct nem-üres")
    void b10_monthlyPanelCounts() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(
                buyRow(D1, "1000000", "C1"),
                buyRow(D1, "1000000", "C1"),
                sellRow(D1, "1000000", "C2"),
                // anonym tranzakció: customerId = '' (NEM null) — nem számít ügyfélnek
                sellRow(D1, "1000000", ""));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getMonthlySummary().getBuyCount()).isEqualTo(2);
        assertThat(report.getMonthlySummary().getSellCount()).isEqualTo(2);
        assertThat(report.getMonthlySummary().getCustomerCount()).isEqualTo(2);
        // FK-102 FR-1: additive transaction count (conversion never reaches this
        // fixture, so it equals buyCount + sellCount).
        assertThat(report.getMonthlySummary().getTotalCount()).isEqualTo(4);
    }

    @Test
    @DisplayName("B11/FR-13: küszöb alatti HUF-forgalom vétel/eladás")
    void b11_belowThresholdTurnover() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(buyRow(D1, "3000000", "C1"), sellRow(D1, "1000000", "C2"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getMonthlySummary().getBelowThresholdBuyHuf()).isEqualByComparingTo("3000000");
        assertThat(report.getMonthlySummary().getBelowThresholdSellHuf()).isEqualByComparingTo("1000000");
        assertThat(report.getMonthlySummary().getAboveThresholdBuyHuf()).isEqualByComparingTo("0");
        assertThat(report.getMonthlySummary().getAboveThresholdSellHuf()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("B12/FR-14: küszöb feletti HUF-forgalom vétel/eladás")
    void b12_aboveThresholdTurnover() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(buyRow(D1, "5000000", "C1"), sellRow(D1, "4444445", "C2"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getMonthlySummary().getAboveThresholdBuyHuf()).isEqualByComparingTo("5000000");
        assertThat(report.getMonthlySummary().getAboveThresholdSellHuf()).isEqualByComparingTo("4444445");
        assertThat(report.getMonthlySummary().getBelowThresholdBuyHuf()).isEqualByComparingTo("0");
        assertThat(report.getMonthlySummary().getBelowThresholdSellHuf()).isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("B13/FR-13: a konverzió semmit nem ad a havi panelhez (TBD-3 OUT)")
    void b13_conversionContributesNothingToMonthlyPanel() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(
                buyRow(D1, "3000000", "C1"),
                sellRow(D1, "1000000", "C2"),
                conversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getMonthlySummary().getBuyCount()).isEqualTo(1);
        assertThat(report.getMonthlySummary().getSellCount()).isEqualTo(1);
        assertThat(report.getMonthlySummary().getCustomerCount()).isEqualTo(2);
        assertThat(report.getMonthlySummary().getBelowThresholdBuyHuf()).isEqualByComparingTo("3000000");
        assertThat(report.getMonthlySummary().getBelowThresholdSellHuf()).isEqualByComparingTo("1000000");
        assertThat(report.getMonthlySummary().getAboveThresholdBuyHuf()).isEqualByComparingTo("0");
        assertThat(report.getMonthlySummary().getAboveThresholdSellHuf()).isEqualByComparingTo("0");
    }

    // ============================ B47: FK-101 FR-2 — combined monthly turnovers ============================
    // NOTE: the plan labels this test "B36", but B36..B40 are already taken by
    // FK-100 FR-3 tests in this file (b36_emptyMonthPopulatesCoveringRate etc.).
    // Numbered B47 instead — the coverage is exactly the plan's "B36" spec.

    @Test
    @DisplayName("B47/FK-101 FR-2: B11 fixture → belowThresholdTotalHuf = buy+sell, aboveThresholdTotalHuf = 0")
    void b47_belowThresholdTotalIsBuyPlusSell() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // B11 fixture: buy 3 000 000 (below) + sell 1 000 000 (below).
        stubRows(buyRow(D1, "3000000", "C1"), sellRow(D1, "1000000", "C2"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getMonthlySummary().getBelowThresholdTotalHuf())
                .isEqualByComparingTo("4000000");
        assertThat(report.getMonthlySummary().getAboveThresholdTotalHuf())
                .isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("B47/FK-101 FR-2: B12 fixture → aboveThresholdTotalHuf = buy+sell, belowThresholdTotalHuf = 0")
    void b47_aboveThresholdTotalIsBuyPlusSell() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // B12 fixture: buy 5 000 000 (above) + sell 4 444 445 (above).
        stubRows(buyRow(D1, "5000000", "C1"), sellRow(D1, "4444445", "C2"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getMonthlySummary().getAboveThresholdTotalHuf())
                .isEqualByComparingTo("9444445");
        assertThat(report.getMonthlySummary().getBelowThresholdTotalHuf())
                .isEqualByComparingTo("0");
    }

    @Test
    @DisplayName("B47/FK-101 FR-2: B13 fixture + conversion → totals unchanged (conversion excluded)")
    void b47_conversionExcludedFromTotals() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // B13 fixture: standalone buy 3 000 000 + sell 1 000 000 plus a full
        // conversion group — conversion contributes nothing to the monthly panel.
        stubRows(
                buyRow(D1, "3000000", "C1"),
                sellRow(D1, "1000000", "C2"),
                conversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getMonthlySummary().getBelowThresholdTotalHuf())
                .isEqualByComparingTo("4000000");
        assertThat(report.getMonthlySummary().getAboveThresholdTotalHuf())
                .isEqualByComparingTo("0");
    }

    // ============================ B48: FK-102 FR-1 — additive totalCount ============================

    @Test
    @DisplayName("B48/FK-102 FR-1: totalCount = buyCount + sellCount (additive transaction count)")
    void b48_totalCountIsBuyPlusSell() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // B11 fixture: one BUY + one SELL row.
        stubRows(buyRow(D1, "3000000", "C1"), sellRow(D1, "1000000", "C2"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getMonthlySummary().getTotalCount()).isEqualTo(2);
        assertThat(report.getMonthlySummary().getTotalCount())
                .isEqualTo(report.getMonthlySummary().getBuyCount()
                        + report.getMonthlySummary().getSellCount());
    }

    @Test
    @DisplayName("B48/FK-102 FR-1: conversion group contributes nothing to totalCount")
    void b48_conversionExcludedFromTotalCount() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // B13 fixture: standalone buy + sell plus a full conversion group.
        stubRows(
                buyRow(D1, "3000000", "C1"),
                sellRow(D1, "1000000", "C2"),
                conversionParentRow(), convBuyChildRow(), convSellChildRow());

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getMonthlySummary().getBuyCount()).isEqualTo(1);
        assertThat(report.getMonthlySummary().getSellCount()).isEqualTo(1);
        assertThat(report.getMonthlySummary().getTotalCount()).isEqualTo(2);
    }

    // ============================ B14–B17: RBAC + cross-tenant ============================

    @Test
    @DisplayName("B14/FR-17: PENZTAR → AccessDeniedException VV-AUTH-006 + pontosan egy ACCESS_DENIED audit")
    void b14_penztarDeniedWithAudit() {
        authenticate("PENZTAR");

        assertThatThrownBy(() -> service.getReport(null, FROM, TO))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageStartingWith("VV-AUTH-006");

        ArgumentCaptor<String> changes = ArgumentCaptor.forClass(String.class);
        verify(auditLogService, times(1)).logInNewTransaction(
                eq("ACCESS_DENIED"), eq("TRANSACTION_LEVY_REPORT"), any(),
                any(), any(), any(), any(), changes.capture());
        assertThat(changes.getValue())
                .contains("\"KAT\":\"AUTH\"")
                .contains("\"VV-AUTH-006\"");
        verify(transactionRepository, never())
                .findTransactionLevySourceRows(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("B15/FR-17: IRODAVEZETO a riportot lekérdezheti (a B14 jó fele)")
    void b15_irodavezetoAllowed() {
        authenticate("IRODAVEZETO");
        stubRates(seedRate());
        stubRows(buyRow(D1, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).hasSize(1);
    }

    @Test
    @DisplayName("B16/FR-19: idegen tenant branchId → BusinessException VV-TENANT-001 NOT_FOUND, létezés nem szivárog")
    void b16_foreignBranchNotFoundWithoutLeakage() {
        authenticate("FOERTEKTAR");
        when(branchRepository.findByIdAndCompanyId(FOREIGN_BRANCH_ID, COMPANY_ID))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getReport(FOREIGN_BRANCH_ID, FROM, TO))
                .isInstanceOf(BusinessException.class)
                .satisfies(ex -> {
                    BusinessException bex = (BusinessException) ex;
                    assertThat(bex.getErrorCode()).isEqualTo("VV-TENANT-001");
                    assertThat(bex.getHttpStatus()).isEqualTo(HttpStatus.NOT_FOUND);
                    assertThat(bex.getMessage()).doesNotContain(FOREIGN_BRANCH_ID.toString());
                });

        verify(transactionRepository, never())
                .findTransactionLevySourceRows(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("B17/FR-19: saját tenant branchId → feloldódik és szűri a lekérdezést (a B16 jó fele)")
    void b17_ownBranchResolvesAndFilters() {
        authenticate("FOERTEKTAR");
        when(branchRepository.findByIdAndCompanyId(BRANCH_ID_001, COMPANY_ID))
                .thenReturn(Optional.of(mock(Branch.class)));
        stubRates(seedRate());
        stubRows(buyRow(D1, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(BRANCH_ID_001, FROM, TO);

        assertThat(report.getRows()).hasSize(1);
        verify(transactionRepository).findTransactionLevySourceRows(
                eq(COMPANY_ID), eq(BRANCH_ID_001), eq(FROM), eq(TO), isNull());
    }

    // ============================ B18–B19: D7 fail-closed ============================

    @Test
    @DisplayName("B18/D7: üres ráta-history → ValidationException a tranzakció dátumával, nincs kód-default")
    void b18_emptyRateHistoryFailsClosed() {
        authenticate("FOERTEKTAR");
        stubRates();
        stubRows(buyRow(D1, "3000000", "C1"));

        assertThatThrownBy(() -> service.getReport(null, FROM, TO))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining(D1.toString());
    }

    @Test
    @DisplayName("B19/D7: a legkorábbi effective_from is a tranzakció UTÁN van → ValidationException")
    void b19_allRatesLaterThanTransactionFailClosed() {
        authenticate("FOERTEKTAR");
        stubRates(rateRow(LocalDate.of(2026, 9, 1), "0.450", "20000.00", true));
        stubRows(buyRow(D1, "3000000", "C1"));

        assertThatThrownBy(() -> service.getReport(null, FROM, TO))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining(D1.toString());
    }

    // ============================ B20–B21: NFR-4 + validáció ============================

    @Test
    @DisplayName("B20/NFR-4: pontosan egy forrás-query és egy ráta-history lekérdezés (nincs N+1)")
    void b21_singleQueryPerRequest() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(
                buyRow(D1, "3000000", "C1"),
                row(D2, BRANCH_ID_002, "002", "Meldek", TransactionType.SELL,
                        "5000000", null, true, "C2", TransactionStatus.COMPLETED));

        service.getReport(null, FROM, TO);

        verify(transactionRepository, times(1))
                .findTransactionLevySourceRows(eq(COMPANY_ID), isNull(), eq(FROM), eq(TO), isNull());
        verify(rateHistoryRepository, times(1))
                .findByCompanyIdOrderByEffectiveFromDesc(COMPANY_ID);
    }

    @Test
    @DisplayName("B21: from > to → ValidationException, repository nem hívódik")
    void b21_reversedRangeRejected() {
        authenticate("FOERTEKTAR");

        assertThatThrownBy(() -> service.getReport(null, TO, FROM))
                .isInstanceOf(ValidationException.class);

        verify(transactionRepository, never())
                .findTransactionLevySourceRows(any(), any(), any(), any(), any());
    }

    // ============================ B22: több ráta-sor ============================

    @Test
    @DisplayName("B22: két ráta-sor → dátum szerinti feloldás, appliedRates ASC derived küszöbbel")
    void b22_multiRateResolutionByDate() {
        authenticate("FOERTEKTAR");
        stubRates(
                rateRow(LocalDate.of(2026, 8, 15), "0.300", "15000.00", true),
                seedRate());
        stubRows(
                buyRow(D1, "3000000", "C1"),
                buyRow(LocalDate.of(2026, 8, 20), "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(
                null, LocalDate.of(2026, 8, 1), LocalDate.of(2026, 8, 31));

        // 08-03: seed ráta → 13 500 + 13 500; 08-20: 0.3% → 9 000 + 9 000
        TransactionLevyReportDto.Row row0803 = report.getRows().stream()
                .filter(r -> D1.equals(r.getDate())).findFirst().orElseThrow();
        TransactionLevyReportDto.Row row0820 = report.getRows().stream()
                .filter(r -> LocalDate.of(2026, 8, 20).equals(r.getDate())).findFirst().orElseThrow();
        assertThat(row0803.getBuy().getNormalBaseLevy()).isEqualByComparingTo("13500");
        assertThat(row0803.getBuy().getNormalSupplementLevy()).isEqualByComparingTo("13500");
        assertThat(row0820.getBuy().getNormalBaseLevy()).isEqualByComparingTo("9000");
        assertThat(row0820.getBuy().getNormalSupplementLevy()).isEqualByComparingTo("9000");

        assertThat(report.getAppliedRates()).hasSize(2);
        assertThat(report.getAppliedRates().get(0).getEffectiveFrom()).isEqualTo(LocalDate.of(2013, 1, 1));
        assertThat(report.getAppliedRates().get(0).getThresholdHuf()).isEqualByComparingTo("4444445");
        assertThat(report.getAppliedRates().get(1).getEffectiveFrom()).isEqualTo(LocalDate.of(2026, 8, 15));
        assertThat(report.getAppliedRates().get(1).getThresholdHuf()).isEqualByComparingTo("5000000");
    }

    // ============================ B23–B26: D15 62 napos ablak ============================

    @Test
    @DisplayName("B23/D15: a pontosan 62 napos ablak (DAYS.between = 61) elfogadott")
    void b23_exactly62DayWindowAccepted() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows();

        TransactionLevyReportDto report = service.getReport(
                null, LocalDate.of(2026, 8, 1), LocalDate.of(2026, 10, 1));

        assertThat(report).isNotNull();
        assertThat(report.getRows()).isEmpty();
    }

    @Test
    @DisplayName("B24/D15: 63 nap → ValidationException a 62 napos limitről, repository nem hívódik")
    void b24_63DayWindowRejected() {
        authenticate("FOERTEKTAR");

        assertThatThrownBy(() -> service.getReport(
                null, LocalDate.of(2026, 8, 1), LocalDate.of(2026, 10, 2)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("62 nap");

        verify(transactionRepository, never())
                .findTransactionLevySourceRows(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("B25/D15+D8: fordított ÉS túl hosszú intervallum → EGY ValidationException mindkét szabállyal")
    void b25_reversedAndOverlongBatchedIntoOneException() {
        authenticate("FOERTEKTAR");

        assertThatThrownBy(() -> service.getReport(
                null, LocalDate.of(2026, 10, 2), LocalDate.of(2026, 8, 1)))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("záró dátum")
                .hasMessageContaining("62 nap");
    }

    @Test
    @DisplayName("B26/D15 vs RBAC: PENZTAR + 5 éves tartomány → AccessDeniedException, NEM ValidationException")
    void b26_authorizationDecidedBeforeRangeValidation() {
        authenticate("PENZTAR");

        assertThatThrownBy(() -> service.getReport(
                null, LocalDate.of(2021, 1, 1), LocalDate.of(2026, 8, 31)))
                .isInstanceOf(AccessDeniedException.class)
                .hasMessageStartingWith("VV-AUTH-006");

        verify(transactionRepository, never())
                .findTransactionLevySourceRows(any(), any(), any(), any(), any());
    }

    // ============================ B36–B40: FK-100 FR-3 — üres hónap appliedRates ============================

    /** FK-100 FR-6: aktív REGION dictionary-bejegyzés mockja. */
    private static Dictionary regionEntry(String code, boolean active) {
        return Dictionary.builder()
                .category("REGION")
                .code(code)
                .name(code)
                .isActive(active)
                .build();
    }

    @Test
    @DisplayName("B36/FR-3: 0 forrás-sor + 2013-as ráta → appliedRates=[2013], küszöb-badge adat, totals 0")
    void b36_emptyMonthPopulatesCoveringRate() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows();

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).isEmpty();
        assertThat(report.getTotals().getLevyTotal()).isEqualByComparingTo("0");
        assertThat(report.getAppliedRates())
                .as("B36/FR-3: üres hónapra is megjelenik az időszakra hatályos ráta")
                .hasSize(1);
        assertThat(report.getAppliedRates().get(0).getEffectiveFrom()).isEqualTo(LocalDate.of(2013, 1, 1));
        assertThat(report.getAppliedRates().get(0).getThresholdHuf()).isEqualByComparingTo("4444445");
    }

    @Test
    @DisplayName("B37/FR-3 él: 0 forrás-sor + NINCS ráta → üres appliedRates, NEM D7 fail-closed 400")
    void b37_emptyMonthWithoutRatesIsEmptyNotFailClosed() {
        authenticate("FOERTEKTAR");
        stubRates();
        stubRows();

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).isEmpty();
        assertThat(report.getAppliedRates()).isEmpty();
    }

    @Test
    @DisplayName("B38/FR-3: két lefedő ráta (2013 + 2026-08-15) → appliedRates ASC, mindkét derived küszöbbel")
    void b38_emptyMonthPopulatesBothCoveringRatesAscending() {
        authenticate("FOERTEKTAR");
        // DESC fixture (a repository DESC-ben adja): az újabb ráta előbb.
        stubRates(rateRow(LocalDate.of(2026, 8, 15), "0.300", "15000.00", true), seedRate());
        stubRows();

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getAppliedRates())
                .extracting(r -> r.getEffectiveFrom())
                .containsExactly(LocalDate.of(2013, 1, 1), LocalDate.of(2026, 8, 15));
        assertThat(report.getAppliedRates().get(0).getThresholdHuf()).isEqualByComparingTo("4444445");
        assertThat(report.getAppliedRates().get(1).getThresholdHuf()).isEqualByComparingTo("5000000");
    }

    @Test
    @DisplayName("B39/FR-3 él: a 'to'-nál későbbi ráta (2026-09-15) NEM kerül appliedRates-be")
    void b39_futureOnlyRateExcludedFromEmptyMonth() {
        authenticate("FOERTEKTAR");
        stubRates(rateRow(LocalDate.of(2026, 9, 15), "0.300", "15000.00", true), seedRate());
        stubRows();

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getAppliedRates())
                .as("B39: csak a 2013-as ráta fed le; a 09-15-ös az időszak után lép hatályba")
                .hasSize(1);
        assertThat(report.getAppliedRates().get(0).getEffectiveFrom()).isEqualTo(LocalDate.of(2013, 1, 1));
    }

    @Test
    @DisplayName("B40/FR-3 regresszió: nem üres forrás → appliedRates továbbra is CSAK fold-alapú")
    void b40_nonEmptySourceKeepsFoldOnlyPopulation() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        // B7 lejátszása: egy önálló BUY sor.
        stubRows(buyRow(D1, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO);

        assertThat(report.getRows()).hasSize(1);
        assertThat(report.getAppliedRates())
                .as("B40: nem üres forrásnál a fold recordAppliedRate az egyetlen forrás")
                .hasSize(1);
        assertThat(report.getAppliedRates().get(0).getEffectiveFrom()).isEqualTo(LocalDate.of(2013, 1, 1));
    }

    // ============================ B41–B46: FK-100 FR-6 — region-szűrő ============================

    @Test
    @DisplayName("B41/FR-6: region null → finder region=null-lal hívódik, az eredmény a mai")
    void b41_nullRegionPassesNullToFinder() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(buyRow(D1, "3000000", "C1"));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO, null);

        assertThat(report.getRows()).hasSize(1);
        verify(transactionRepository, times(1)).findTransactionLevySourceRows(
                eq(COMPANY_ID), isNull(), eq(FROM), eq(TO), isNull());
    }

    @Test
    @DisplayName("B42/FR-6: region SZEGED (dictionary aktív) → finder SZEGED-del hívódik")
    void b42_validRegionPassesThroughToFinder() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(buyRow(D1, "3000000", "C1"));
        when(dictionaryRepository.findByCategoryAndCode("REGION", "SZEGED"))
                .thenReturn(Optional.of(regionEntry("SZEGED", true)));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO, "SZEGED");

        assertThat(report.getRows()).hasSize(1);
        verify(transactionRepository, times(1)).findTransactionLevySourceRows(
                eq(COMPANY_ID), isNull(), eq(FROM), eq(TO), eq("SZEGED"));
    }

    @Test
    @DisplayName("B43/FR-6: ismeretlen region-kód (üres dictionary) → ValidationException, finder NEM fut")
    void b43_unknownRegionRejectedBeforeSourceQuery() {
        authenticate("FOERTEKTAR");
        when(dictionaryRepository.findByCategoryAndCode("REGION", "ISMERETLEN"))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getReport(null, FROM, TO, "ISMERETLEN"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("ISMERETLEN");

        verify(transactionRepository, never())
                .findTransactionLevySourceRows(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("B44/FR-6: ismert, de inaktív REGION bejegyzés → ValidationException")
    void b44_inactiveRegionRejected() {
        authenticate("FOERTEKTAR");
        when(dictionaryRepository.findByCategoryAndCode("REGION", "SZEGED"))
                .thenReturn(Optional.of(regionEntry("SZEGED", false)));

        assertThatThrownBy(() -> service.getReport(null, FROM, TO, "SZEGED"))
                .isInstanceOf(ValidationException.class);

        verify(transactionRepository, never())
                .findTransactionLevySourceRows(any(), any(), any(), any(), any());
    }

    @Test
    @DisplayName("B45/FR-6: '  SZEGED  ' → trimmelve: dictionary ÉS finder is 'SZEGED'-del hívódik")
    void b45_regionIsTrimmedForValidationAndFinder() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(buyRow(D1, "3000000", "C1"));
        when(dictionaryRepository.findByCategoryAndCode("REGION", "SZEGED"))
                .thenReturn(Optional.of(regionEntry("SZEGED", true)));

        service.getReport(null, FROM, TO, "  SZEGED  ");

        verify(dictionaryRepository).findByCategoryAndCode("REGION", "SZEGED");
        verify(transactionRepository, times(1)).findTransactionLevySourceRows(
                eq(COMPANY_ID), isNull(), eq(FROM), eq(TO), eq("SZEGED"));
    }

    @Test
    @DisplayName("B45b/FR-6: whitespace-only region '   ' → nincs szűrő: finder region=null (no-filter)")
    void b45b_blankRegionMeansNoFilter() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows(buyRow(D1, "3000000", "C1"));

        service.getReport(null, FROM, TO, "   ");

        verify(dictionaryRepository, never()).findByCategoryAndCode(any(), any());
        verify(transactionRepository, times(1)).findTransactionLevySourceRows(
                eq(COMPANY_ID), isNull(), eq(FROM), eq(TO), isNull());
    }

    @Test
    @DisplayName("B46/FR-6+FR-3: region valid + 0 sor + seedRate → appliedRates töltött (badge-adat van)")
    void b46_regionFilterWithEmptyMonthStillPopulatesRates() {
        authenticate("FOERTEKTAR");
        stubRates(seedRate());
        stubRows();
        when(dictionaryRepository.findByCategoryAndCode("REGION", "SZEGED"))
                .thenReturn(Optional.of(regionEntry("SZEGED", true)));

        TransactionLevyReportDto report = service.getReport(null, FROM, TO, "SZEGED");

        assertThat(report.getRows()).isEmpty();
        assertThat(report.getAppliedRates())
                .as("B46: region-szűrt üres hónapnál is van küszöb-badge adat")
                .hasSize(1);
        assertThat(report.getAppliedRates().get(0).getEffectiveFrom()).isEqualTo(LocalDate.of(2013, 1, 1));
        assertThat(report.getAppliedRates().get(0).getThresholdHuf()).isEqualByComparingTo("4444445");
    }
}
