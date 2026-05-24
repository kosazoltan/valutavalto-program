package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CommissionCalculation;
import hu.puzzleir.valuta.entity.CommissionRule;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.CommissionCalculationRepository;
import hu.puzzleir.valuta.repository.CommissionRuleRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.*;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * CommissionCalculationService UNIT tesztek — Mockito.
 *
 * Teszteli a jutalékszámítás tier-besorolását, bónuszt és jóváhagyást.
 * A service havi range query-vel gyűjti a tranzakciókat.
 */
@ExtendWith(MockitoExtension.class)
class CommissionCalculationServiceTest {

    @InjectMocks
    private CommissionCalculationService service;

    @Mock
    private CommissionCalculationRepository commissionCalcRepo;

    @Mock
    private CommissionRuleRepository commissionRuleRepo;

    @Mock
    private TransactionRepository transactionRepository;

    @Mock
    private WorkerRepository workerRepository;

    private static final Long WORKER_ID = 1L;
    private static final String YEAR_MONTH = "2026-01";
    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    // #PP-18: a dolgozó SAJÁT fiókja — ennek kell a jutalék branchId-jébe kerülnie,
    // NEM a munkamenet (SecurityUtils) fiókjának.
    private static final UUID WORKER_BRANCH_ID = UUID.fromString("22222222-2222-2222-2222-222222222222");

    // 2026 január 1. (a mocks egyetlen napra adnak tranzakciót)
    private static final LocalDate JAN_1 = LocalDate.of(2026, 1, 1);

    /**
     * Segéd: aktív tranzakció létrehozása.
     */
    private Transaction createTransaction(TransactionType type, BigDecimal hufAmount) {
        return Transaction.builder()
                .transactionType(type)
                .hufAmount(hufAmount)
                .status(TransactionStatus.COMPLETED)
                .build();
    }

    /**
     * Segéd: CommissionRule létrehozása.
     */
    private CommissionRule createRule(BigDecimal minVolume, BigDecimal maxVolume,
                                      BigDecimal ratePercent, BigDecimal bonusThreshold,
                                      BigDecimal bonusPercent) {
        return CommissionRule.builder()
                .minVolumeHuf(minVolume)
                .maxVolumeHuf(maxVolume)
                .ratePercent(ratePercent)
                .bonusThreshold(bonusThreshold)
                .bonusPercent(bonusPercent != null ? bonusPercent : BigDecimal.ZERO)
                .build();
    }

    /**
     * Közös mock: havi range query eredménye.
     */
    private void mockTransactionsForMonth(List<Transaction> transactions) {
        when(transactionRepository.findByCompanyIdAndWorkerIdAndTransactionDateBetween(
                eq(COMPANY_ID), eq(WORKER_ID), any(LocalDate.class), any(LocalDate.class)))
                .thenReturn(transactions);
    }

    /**
     * #PP-18: a dolgozó betöltése a SAJÁT fiókjával (WORKER_BRANCH_ID).
     */
    private void mockWorkerWithBranch() {
        Branch branch = Branch.builder().id(WORKER_BRANCH_ID).build();
        Company company = Company.builder().id(COMPANY_ID).build();
        Worker worker = Worker.builder().id(WORKER_ID).branch(branch).company(company).build();
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(worker));
    }

    /**
     * Közös SecurityUtils mock.
     */
    private MockedStatic<SecurityUtils> mockSecurityUtils() {
        MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class);
        secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(UUID.randomUUID());
        secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(99L);
        return secUtils;
    }

    // =====================================================================
    // Tier 1: forgalom < 1M → 1% (de service default 0.1% ha nincs tier match)
    // =====================================================================
    @Test
    @DisplayName("Tier 1: forgalom < 1M HUF → 1% jutalék")
    void testCalculateMonthly_tier1() {
        try (MockedStatic<SecurityUtils> secUtils = mockSecurityUtils()) {
            // Arrange — 500K forgalom (BUY: 300K + SELL: 200K = 500K), egyetlen nap
            List<Transaction> transactions = List.of(
                    createTransaction(TransactionType.BUY, new BigDecimal("300000")),
                    createTransaction(TransactionType.SELL, new BigDecimal("200000"))
            );

            when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
            mockTransactionsForMonth(transactions);
            mockWorkerWithBranch();

            // Tier 1 szabály: 0 - 1M → 1%
            CommissionRule tier1 = createRule(
                    BigDecimal.ZERO, new BigDecimal("999999"),
                    new BigDecimal("1.0"), null, null
            );
            when(commissionRuleRepo.findActiveRules(eq(COMPANY_ID), any(LocalDate.class)))
                    .thenReturn(List.of(tier1));

            when(commissionCalcRepo.save(any(CommissionCalculation.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            // Act
            CommissionCalculation result = service.calculateMonthly(WORKER_ID, YEAR_MONTH, COMPANY_ID);

            // Assert — 500K * 1% / 100 = 500K * 0.01 = 5000 HUF
            assertThat(result).isNotNull();
            assertThat(result.getTotalVolumeHuf()).isEqualByComparingTo(new BigDecimal("500000"));
            assertThat(result.getCommissionAmount()).isEqualByComparingTo(new BigDecimal("5000.00"));
            assertThat(result.getBonusAmount()).isEqualByComparingTo(BigDecimal.ZERO);
            assertThat(result.getStatus()).isEqualTo(CommissionCalculation.CommissionStatus.CALCULATED);
        }
    }

    // =====================================================================
    // Tier 2: forgalom 1M-5M → 1.5%
    // =====================================================================
    @Test
    @DisplayName("Tier 2: forgalom 1M-5M HUF → 1.5% jutalék")
    void testCalculateMonthly_tier2() {
        try (MockedStatic<SecurityUtils> secUtils = mockSecurityUtils()) {
            // Arrange — 3M forgalom egyetlen napon
            List<Transaction> transactions = List.of(
                    createTransaction(TransactionType.BUY, new BigDecimal("2000000")),
                    createTransaction(TransactionType.SELL, new BigDecimal("1000000"))
            );

            when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
            mockTransactionsForMonth(transactions);
            mockWorkerWithBranch();

            // Tier 2 szabály: 1M - 5M → 1.5%
            CommissionRule tier2 = createRule(
                    new BigDecimal("1000000"), new BigDecimal("5000000"),
                    new BigDecimal("1.5"), null, null
            );
            when(commissionRuleRepo.findActiveRules(eq(COMPANY_ID), any(LocalDate.class)))
                    .thenReturn(List.of(tier2));

            when(commissionCalcRepo.save(any(CommissionCalculation.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            // Act
            CommissionCalculation result = service.calculateMonthly(WORKER_ID, YEAR_MONTH, COMPANY_ID);

            // Assert — 3M * 1.5% = 45,000 HUF
            assertThat(result.getTotalVolumeHuf()).isEqualByComparingTo(new BigDecimal("3000000"));
            assertThat(result.getCommissionAmount()).isEqualByComparingTo(new BigDecimal("45000.00"));
        }
    }

    // =====================================================================
    // Tier 3: forgalom 5M+ → 2%
    // =====================================================================
    @Test
    @DisplayName("Tier 3: forgalom 5M+ HUF → 2% jutalék")
    void testCalculateMonthly_tier3() {
        try (MockedStatic<SecurityUtils> secUtils = mockSecurityUtils()) {
            // Arrange — 8M forgalom egyetlen napon
            List<Transaction> transactions = List.of(
                    createTransaction(TransactionType.BUY, new BigDecimal("5000000")),
                    createTransaction(TransactionType.SELL, new BigDecimal("3000000"))
            );

            when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
            mockTransactionsForMonth(transactions);
            mockWorkerWithBranch();

            // Tier 3 szabály: 5M+ → 2%
            CommissionRule tier3 = createRule(
                    new BigDecimal("5000000"), null,
                    new BigDecimal("2.0"), null, null
            );
            when(commissionRuleRepo.findActiveRules(eq(COMPANY_ID), any(LocalDate.class)))
                    .thenReturn(List.of(tier3));

            when(commissionCalcRepo.save(any(CommissionCalculation.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            // Act
            CommissionCalculation result = service.calculateMonthly(WORKER_ID, YEAR_MONTH, COMPANY_ID);

            // Assert — 8M * 2% = 160,000 HUF
            assertThat(result.getTotalVolumeHuf()).isEqualByComparingTo(new BigDecimal("8000000"));
            assertThat(result.getCommissionAmount()).isEqualByComparingTo(new BigDecimal("160000.00"));
        }
    }

    // =====================================================================
    // Bónusz: forgalom eléri a küszöböt → extra %
    // =====================================================================
    @Test
    @DisplayName("Bónusz: forgalom eléri a küszöböt → extra jutalék")
    void testCalculateMonthly_withBonus() {
        try (MockedStatic<SecurityUtils> secUtils = mockSecurityUtils()) {
            // Arrange — 6M forgalom egyetlen napon, bónusz küszöb: 5M
            List<Transaction> transactions = List.of(
                    createTransaction(TransactionType.BUY, new BigDecimal("4000000")),
                    createTransaction(TransactionType.SELL, new BigDecimal("2000000"))
            );

            when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
            mockTransactionsForMonth(transactions);
            mockWorkerWithBranch();

            // Szabály: 5M+ → 2% + bónusz 0.5% ha forgalom >= 5M
            CommissionRule ruleWithBonus = createRule(
                    new BigDecimal("5000000"), null,
                    new BigDecimal("2.0"),
                    new BigDecimal("5000000"),
                    new BigDecimal("0.5")
            );
            when(commissionRuleRepo.findActiveRules(eq(COMPANY_ID), any(LocalDate.class)))
                    .thenReturn(List.of(ruleWithBonus));

            when(commissionCalcRepo.save(any(CommissionCalculation.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            // Act
            CommissionCalculation result = service.calculateMonthly(WORKER_ID, YEAR_MONTH, COMPANY_ID);

            // Assert — 6M * 2% = 120K jutalék + 6M * 0.5% = 30K bónusz
            assertThat(result.getCommissionAmount()).isEqualByComparingTo(new BigDecimal("120000.00"));
            assertThat(result.getBonusAmount()).isEqualByComparingTo(new BigDecimal("30000.00"));
            // Nettó = jutalék + bónusz = 150K
            assertThat(result.getNetCommission()).isEqualByComparingTo(new BigDecimal("150000.00"));
        }
    }

    // =====================================================================
    // Jóváhagyás: sikeres
    // =====================================================================
    @Test
    @DisplayName("Jóváhagyás: CALCULATED → APPROVED sikeres")
    void testApproveCommission_success() {
        try (MockedStatic<SecurityUtils> secUtils = mockSecurityUtils()) {
            // Arrange
            UUID calcId = UUID.randomUUID();
            CommissionCalculation calc = CommissionCalculation.builder()
                    .id(calcId)
                    .status(CommissionCalculation.CommissionStatus.CALCULATED)
                    .build();

            when(commissionCalcRepo.findById(calcId)).thenReturn(Optional.of(calc));
            when(commissionCalcRepo.save(any(CommissionCalculation.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            // Act
            CommissionCalculation result = service.approveCommission(calcId);

            // Assert
            assertThat(result.getStatus()).isEqualTo(CommissionCalculation.CommissionStatus.APPROVED);
            assertThat(result.getApprovedBy()).isEqualTo(99L);
            assertThat(result.getApprovedAt()).isNotNull();
        }
    }

    // =====================================================================
    // Jóváhagyás: már jóváhagyott → hiba
    // =====================================================================
    @Test
    @DisplayName("Jóváhagyás: már APPROVED státuszú → ValidationException")
    void testApproveCommission_alreadyApproved_throws() {
        // Arrange
        UUID calcId = UUID.randomUUID();
        CommissionCalculation calc = CommissionCalculation.builder()
                .id(calcId)
                .status(CommissionCalculation.CommissionStatus.APPROVED)
                .build();

        when(commissionCalcRepo.findById(calcId)).thenReturn(Optional.of(calc));

        // Act & Assert
        assertThatThrownBy(() -> service.approveCommission(calcId))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Csak CALCULATED státuszú");
    }

    // =====================================================================
    // #PP-18: a jutalék a dolgozó SAJÁT fiókjához kerül (NEM a munkamenethez)
    // =====================================================================
    @Test
    @DisplayName("#PP-18: a branchId a dolgozó fiókja, nem a munkamenet fiókja")
    void testCalculateMonthly_branchIdFromWorkerNotSession() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            // A munkamenet fiókja SZÁNDÉKOSAN más, mint a dolgozó fiókja —
            // ha a service még a session-t használná, ez bukna. (getCurrentBranchId
            // hívás már nincs a calculateMonthly-ban, így a stub szándékosan elmarad.)
            when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
            mockTransactionsForMonth(List.of(
                    createTransaction(TransactionType.BUY, new BigDecimal("100000"))));
            mockWorkerWithBranch();
            when(commissionRuleRepo.findActiveRules(eq(COMPANY_ID), any(LocalDate.class)))
                    .thenReturn(Collections.emptyList());
            when(commissionCalcRepo.save(any(CommissionCalculation.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            CommissionCalculation result = service.calculateMonthly(WORKER_ID, YEAR_MONTH, COMPANY_ID);

            assertThat(result.getBranchId()).isEqualTo(WORKER_BRANCH_ID);
        }
    }

    @Test
    @DisplayName("#PP-18: ismeretlen dolgozó → ResourceNotFoundException")
    void testCalculateMonthly_unknownWorker_throws() {
        when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.calculateMonthly(WORKER_ID, YEAR_MONTH, COMPANY_ID))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Pénztáros nem található");
    }

    @Test
    @DisplayName("Copilot #830: más cég dolgozója → ResourceNotFoundException (multi-tenant guard)")
    void testCalculateMonthly_crossCompanyWorker_throws() {
        UUID otherCompany = UUID.fromString("99999999-9999-9999-9999-999999999999");
        Branch branch = Branch.builder().id(WORKER_BRANCH_ID).build();
        Worker foreignWorker = Worker.builder()
                .id(WORKER_ID).branch(branch)
                .company(Company.builder().id(otherCompany).build())
                .build();
        when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
        when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(foreignWorker));

        assertThatThrownBy(() -> service.calculateMonthly(WORKER_ID, YEAR_MONTH, COMPANY_ID))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
