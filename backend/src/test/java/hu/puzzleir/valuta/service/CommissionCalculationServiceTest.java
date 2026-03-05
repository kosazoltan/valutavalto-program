package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.entity.CommissionCalculation;
import hu.puzzleir.valuta.entity.CommissionRule;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.repository.CommissionCalculationRepository;
import hu.puzzleir.valuta.repository.CommissionRuleRepository2;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
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
 */
@ExtendWith(MockitoExtension.class)
class CommissionCalculationServiceTest {

    @InjectMocks
    private CommissionCalculationService service;

    @Mock
    private CommissionCalculationRepository commissionCalcRepo;

    @Mock
    private CommissionRuleRepository2 commissionRuleRepo;

    @Mock
    private TransactionRepository transactionRepository;

    private static final Long WORKER_ID = 1L;
    private static final String YEAR_MONTH = "2026-01";
    private static final Integer COMPANY_ID = 42;

    /**
     * Segéd: aktív BUY tranzakció létrehozása adott HUF összeggel.
     */
    private Transaction createBuyTransaction(BigDecimal hufAmount) {
        return Transaction.builder()
                .transactionType(TransactionType.BUY)
                .hufAmount(hufAmount)
                .status(TransactionStatus.COMPLETED)
                .build();
    }

    /**
     * Segéd: aktív SELL tranzakció létrehozása adott HUF összeggel.
     */
    private Transaction createSellTransaction(BigDecimal hufAmount) {
        return Transaction.builder()
                .transactionType(TransactionType.SELL)
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
                .bonusPercent(bonusPercent)
                .build();
    }

    /**
     * Közös mock beállítás: SecurityUtils statikus metódus.
     */
    private MockedStatic<SecurityUtils> mockSecurityUtils() {
        MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class);
        secUtils.when(SecurityUtils::getCurrentBranchId).thenReturn(UUID.randomUUID());
        secUtils.when(SecurityUtils::getCurrentWorkerId).thenReturn(99L);
        return secUtils;
    }

    // =====================================================================
    // Tier 1: forgalom < 1M → 1%
    // =====================================================================
    @Test
    @DisplayName("Tier 1: forgalom < 1M HUF → 1% jutalék")
    void testCalculateMonthly_tier1() {
        try (MockedStatic<SecurityUtils> secUtils = mockSecurityUtils()) {
            // Arrange — 500K forgalom (BUY: 300K + SELL: 200K = 500K)
            List<Transaction> transactions = List.of(
                    createBuyTransaction(new BigDecimal("300000")),
                    createSellTransaction(new BigDecimal("200000"))
            );

            when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
            when(transactionRepository.findByWorkerAndDate(eq(WORKER_ID), any(LocalDate.class)))
                    .thenReturn(transactions);

            // Tier 1 szabály: 0 - 1M → 1%
            CommissionRule tier1 = createRule(
                    BigDecimal.ZERO, new BigDecimal("999999"),
                    new BigDecimal("1.0"), null, BigDecimal.ZERO
            );
            when(commissionRuleRepo.findActiveRules(eq(COMPANY_ID), any(LocalDate.class)))
                    .thenReturn(List.of(tier1));

            when(commissionCalcRepo.save(any(CommissionCalculation.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            // Act
            CommissionCalculation result = service.calculateMonthly(WORKER_ID, YEAR_MONTH, COMPANY_ID);

            // Assert — 500K * 1% = 5000 HUF
            assertThat(result).isNotNull();
            assertThat(result.getTotalVolumeHuf()).isEqualByComparingTo(new BigDecimal("500000"));
            BigDecimal expectedRate = new BigDecimal("1.0")
                    .divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);
            assertThat(result.getCommissionRate()).isEqualByComparingTo(expectedRate);
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
            // Arrange — 3M forgalom
            List<Transaction> transactions = List.of(
                    createBuyTransaction(new BigDecimal("2000000")),
                    createSellTransaction(new BigDecimal("1000000"))
            );

            when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
            when(transactionRepository.findByWorkerAndDate(eq(WORKER_ID), any(LocalDate.class)))
                    .thenReturn(transactions);

            // Tier 2 szabály: 1M - 5M → 1.5%
            CommissionRule tier2 = createRule(
                    new BigDecimal("1000000"), new BigDecimal("5000000"),
                    new BigDecimal("1.5"), null, BigDecimal.ZERO
            );
            when(commissionRuleRepo.findActiveRules(eq(COMPANY_ID), any(LocalDate.class)))
                    .thenReturn(List.of(tier2));

            when(commissionCalcRepo.save(any(CommissionCalculation.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            // Act
            CommissionCalculation result = service.calculateMonthly(WORKER_ID, YEAR_MONTH, COMPANY_ID);

            // Assert — 3M * 1.5% = 45,000 HUF
            assertThat(result.getTotalVolumeHuf()).isEqualByComparingTo(new BigDecimal("3000000"));
            BigDecimal expectedRate = new BigDecimal("1.5")
                    .divide(new BigDecimal("100"), 6, RoundingMode.HALF_UP);
            assertThat(result.getCommissionRate()).isEqualByComparingTo(expectedRate);
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
            // Arrange — 8M forgalom
            List<Transaction> transactions = List.of(
                    createBuyTransaction(new BigDecimal("5000000")),
                    createSellTransaction(new BigDecimal("3000000"))
            );

            when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
            when(transactionRepository.findByWorkerAndDate(eq(WORKER_ID), any(LocalDate.class)))
                    .thenReturn(transactions);

            // Tier 3 szabály: 5M+ → 2%
            CommissionRule tier3 = createRule(
                    new BigDecimal("5000000"), null,
                    new BigDecimal("2.0"), null, BigDecimal.ZERO
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
            // Arrange — 6M forgalom, bónusz küszöb: 5M, bónusz: 0.5%
            List<Transaction> transactions = List.of(
                    createBuyTransaction(new BigDecimal("4000000")),
                    createSellTransaction(new BigDecimal("2000000"))
            );

            when(commissionCalcRepo.existsByWorkerIdAndPeriod(WORKER_ID, YEAR_MONTH)).thenReturn(false);
            when(transactionRepository.findByWorkerAndDate(eq(WORKER_ID), any(LocalDate.class)))
                    .thenReturn(transactions);

            // Szabály: 5M+ → 2% + bónusz 0.5% ha forgalom >= 5M
            CommissionRule ruleWithBonus = createRule(
                    new BigDecimal("5000000"), null,
                    new BigDecimal("2.0"),
                    new BigDecimal("5000000"),  // bonusThreshold
                    new BigDecimal("0.5")       // bonusPercent
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
}
