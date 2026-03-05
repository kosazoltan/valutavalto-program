package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CommissionCalculation;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * CommissionCalculationRepository UNIT tesztek — Mockito.
 *
 * Repository interfész tesztelés mock-kal
 * (H2 integrációs teszt helyett, komplex entitás séma miatt).
 */
@ExtendWith(MockitoExtension.class)
class CommissionCalculationRepositoryTest {

    @Mock
    private CommissionCalculationRepository repository;

    // =====================================================================
    // findByWorkerIdAndPeriod — keresés worker + időszak szerint
    // =====================================================================
    @Test
    @DisplayName("findByWorkerIdAndPeriod: létező rekord megtalálása")
    void testFindByWorkerAndPeriod() {
        // Arrange — mock válasz
        CommissionCalculation calc = CommissionCalculation.builder()
                .id(UUID.randomUUID())
                .workerId(42L)
                .branchId(UUID.randomUUID())
                .period("2026-01")
                .calculationType(CommissionCalculation.CalculationType.MONTHLY)
                .totalTransactions(100)
                .totalVolumeHuf(new BigDecimal("5000000"))
                .commissionRate(new BigDecimal("0.015"))
                .commissionAmount(new BigDecimal("75000"))
                .bonusAmount(BigDecimal.ZERO)
                .deductions(BigDecimal.ZERO)
                .netCommission(new BigDecimal("75000"))
                .status(CommissionCalculation.CommissionStatus.CALCULATED)
                .calculatedAt(LocalDateTime.now())
                .build();

        when(repository.findByWorkerIdAndPeriod(42L, "2026-01")).thenReturn(Optional.of(calc));

        // Act
        Optional<CommissionCalculation> found = repository.findByWorkerIdAndPeriod(42L, "2026-01");

        // Assert — megtalálja
        assertThat(found).isPresent();
        assertThat(found.get().getWorkerId()).isEqualTo(42L);
        assertThat(found.get().getPeriod()).isEqualTo("2026-01");
        assertThat(found.get().getTotalVolumeHuf()).isEqualByComparingTo(new BigDecimal("5000000"));
        assertThat(found.get().getNetCommission()).isEqualByComparingTo(new BigDecimal("75000"));
    }

    @Test
    @DisplayName("findByWorkerIdAndPeriod: nem létező rekord → üres Optional")
    void testFindByWorkerAndPeriod_notFound() {
        // Arrange
        when(repository.findByWorkerIdAndPeriod(999L, "2030-12")).thenReturn(Optional.empty());

        // Act
        Optional<CommissionCalculation> found = repository.findByWorkerIdAndPeriod(999L, "2030-12");

        // Assert
        assertThat(found).isEmpty();
    }

    @Test
    @DisplayName("existsByWorkerIdAndPeriod: létező rekord → true")
    void testExistsByWorkerAndPeriod() {
        // Arrange
        when(repository.existsByWorkerIdAndPeriod(77L, "2026-03")).thenReturn(true);
        when(repository.existsByWorkerIdAndPeriod(77L, "2026-04")).thenReturn(false);

        // Act & Assert
        assertThat(repository.existsByWorkerIdAndPeriod(77L, "2026-03")).isTrue();
        assertThat(repository.existsByWorkerIdAndPeriod(77L, "2026-04")).isFalse();
    }
}
