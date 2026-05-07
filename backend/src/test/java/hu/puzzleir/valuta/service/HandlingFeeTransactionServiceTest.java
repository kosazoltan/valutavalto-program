package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeTransactionDto;
import hu.puzzleir.valuta.entity.HandlingFeeTransaction;
import hu.puzzleir.valuta.entity.PaymentMethod;
import hu.puzzleir.valuta.repository.HandlingFeeTransactionRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * HandlingFeeTransactionService UNIT tesztek — Mockito.
 *
 * Sávos kezelési díj számítás:
 * 0-50K = 0%, 50K-300K = 1.5%, 300K-1M = 1%, 1M+ = 0.5%
 */
@ExtendWith(MockitoExtension.class)
class HandlingFeeTransactionServiceTest {

    @InjectMocks
    private HandlingFeeTransactionService service;

    @Mock
    private HandlingFeeTransactionRepository repository;
    @Mock private LicenseService licenseService;

    // =====================================================================
    // Díjszámítás: 0-50K → 0%
    // =====================================================================
    @Test
    @DisplayName("Díjszámítás: 50K alatt → 0% (díjmentes)")
    void testCalculateFee_under50K() {
        // Arrange — 30,000 HUF tranzakció
        BigDecimal amount = new BigDecimal("30000");

        // Act — transactionId null → nem ment adatbázisba
        HandlingFeeTransactionDto result = service.calculateFee(null, amount);

        // Assert — 0 Ft díj
        assertThat(result).isNotNull();
        assertThat(result.getAmount()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(result.getFeeType()).isEqualTo("TIERED");
        verify(repository, never()).save(any());
    }

    @Test
    @DisplayName("Díjszámítás: pontosan 50K → 0% (határ érték, még díjmentes)")
    void testCalculateFee_exactly50K() {
        // Arrange
        BigDecimal amount = new BigDecimal("50000");

        // Act
        HandlingFeeTransactionDto result = service.calculateFee(null, amount);

        // Assert — pontosan 50K-nál még 0%
        assertThat(result.getAmount()).isEqualByComparingTo(BigDecimal.ZERO);
    }

    // =====================================================================
    // Díjszámítás: 50K-300K → 1.5%
    // =====================================================================
    @Test
    @DisplayName("Díjszámítás: 50K-300K → 1.5%")
    void testCalculateFee_50K_to_300K() {
        // Arrange — 200,000 HUF
        BigDecimal amount = new BigDecimal("200000");

        // Act
        HandlingFeeTransactionDto result = service.calculateFee(null, amount);

        // Assert — 200K * 1.5% = 3000 Ft
        assertThat(result.getAmount()).isEqualByComparingTo(new BigDecimal("3000"));
    }

    // =====================================================================
    // Díjszámítás: 300K-1M → 1%
    // =====================================================================
    @Test
    @DisplayName("Díjszámítás: 300K-1M → 1%")
    void testCalculateFee_300K_to_1M() {
        // Arrange — 500,000 HUF
        BigDecimal amount = new BigDecimal("500000");

        // Act
        HandlingFeeTransactionDto result = service.calculateFee(null, amount);

        // Assert — 500K * 1% = 5000 Ft
        assertThat(result.getAmount()).isEqualByComparingTo(new BigDecimal("5000"));
    }

    // =====================================================================
    // Díjszámítás: 1M+ → 0.5%
    // =====================================================================
    @Test
    @DisplayName("Díjszámítás: 1M felett → 0.5%")
    void testCalculateFee_over1M() {
        // Arrange — 2,000,000 HUF
        BigDecimal amount = new BigDecimal("2000000");

        // Act
        HandlingFeeTransactionDto result = service.calculateFee(null, amount);

        // Assert — 2M * 0.5% = 10,000 Ft
        assertThat(result.getAmount()).isEqualByComparingTo(new BigDecimal("10000"));
    }

    // =====================================================================
    // Kedvezmény alkalmazás: sikeres
    // =====================================================================
    @Test
    @DisplayName("Kedvezmény alkalmazás: 10% törzsvásárlói kedvezmény")
    void testApplyDiscount_success() {
        // Arrange
        UUID feeId = UUID.randomUUID();
        HandlingFeeTransaction hft = HandlingFeeTransaction.builder()
                .id(feeId)
                .transactionId(1L)
                .feeType(HandlingFeeTransaction.HandlingFeeTransactionType.TIERED)
                .amount(new BigDecimal("5000"))
                .netFee(new BigDecimal("5000"))
                .discountPercent(0)
                .workerCommissionShare(BigDecimal.ZERO)
                .build();

        when(repository.findById(feeId)).thenReturn(Optional.of(hft));
        when(repository.save(any(HandlingFeeTransaction.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        // Act — 10% kedvezmény
        HandlingFeeTransactionDto result = service.applyDiscount(feeId, 10, "Törzsvásárlói kedvezmény");

        // Assert — 5000 * 10% = 500 kedvezmény → nettó: 4500
        assertThat(result.getDiscountPercent()).isEqualTo(10);
        assertThat(result.getNetFee()).isEqualByComparingTo(new BigDecimal("4500"));
    }

    // =====================================================================
    // Kedvezmény alkalmazás: nem létező díj → hiba
    // =====================================================================
    @Test
    @DisplayName("Kedvezmény alkalmazás: nem létező díj → ResourceNotFoundException")
    void testApplyDiscount_overLimit_throws() {
        // Arrange — nem létező feeId
        UUID feeId = UUID.randomUUID();
        when(repository.findById(feeId)).thenReturn(Optional.empty());

        // Act & Assert
        assertThatThrownBy(() -> service.applyDiscount(feeId, 20, "Nagytételes"))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Kezelési díj nem található");
    }

    @Test
    @DisplayName("Riport: a kezelési díj tételek tartalmazzák a tranzakció fizetési módját")
    void testGetFeeReport_includesPaymentMethod() {
        // Arrange
        UUID branchId = UUID.randomUUID();
        HandlingFeeTransaction cashFee = HandlingFeeTransaction.builder()
                .id(UUID.randomUUID())
                .transactionId(10L)
                .feeType(HandlingFeeTransaction.HandlingFeeTransactionType.TIERED)
                .amount(new BigDecimal("1000"))
                .netFee(new BigDecimal("1000"))
                .discountPercent(0)
                .workerCommissionShare(BigDecimal.ZERO)
                .createdAt(LocalDateTime.of(2026, 5, 7, 9, 0))
                .build();
        HandlingFeeTransaction cardFee = HandlingFeeTransaction.builder()
                .id(UUID.randomUUID())
                .transactionId(11L)
                .feeType(HandlingFeeTransaction.HandlingFeeTransactionType.TIERED)
                .amount(new BigDecimal("2000"))
                .netFee(new BigDecimal("1800"))
                .discountPercent(10)
                .workerCommissionShare(BigDecimal.ZERO)
                .createdAt(LocalDateTime.of(2026, 5, 7, 10, 0))
                .build();

        when(repository.findByBranchAndPeriod(eq(branchId), any(), any()))
                .thenReturn(List.of(cashFee, cardFee));
        when(repository.findPaymentMethodsByBranchAndTransactionIds(eq(branchId), any()))
                .thenReturn(List.of(
                        paymentMethodProjection(10L, PaymentMethod.CASH),
                        paymentMethodProjection(11L, PaymentMethod.CARD)));

        // Act
        var report = service.getFeeReport(
                branchId,
                LocalDate.of(2026, 5, 1),
                LocalDate.of(2026, 5, 10));

        // Assert
        assertThat(report.getItems())
                .extracting(HandlingFeeTransactionDto::getPaymentMethod)
                .containsExactly("CASH", "CARD");
        verify(repository).findPaymentMethodsByBranchAndTransactionIds(eq(branchId), argThat(ids ->
                ids != null && ids.size() == 2 && ids.containsAll(List.of(10L, 11L))));
    }

    private static HandlingFeeTransactionRepository.TransactionPaymentMethodProjection paymentMethodProjection(
            Long transactionId,
            PaymentMethod paymentMethod) {
        return new HandlingFeeTransactionRepository.TransactionPaymentMethodProjection() {
            @Override
            public Long getTransactionId() {
                return transactionId;
            }

            @Override
            public PaymentMethod getPaymentMethod() {
                return paymentMethod;
            }
        };
    }
}




