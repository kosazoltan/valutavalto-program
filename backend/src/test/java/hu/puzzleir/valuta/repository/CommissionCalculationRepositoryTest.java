package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.CommissionCalculation;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * CommissionCalculationRepository INTEGRÁCIÓS teszt — @DataJpaTest + H2.
 *
 * Adatbázis lekérdezés tesztek: findByWorkerIdAndPeriod.
 */
@DataJpaTest
@ActiveProfiles("test")
class CommissionCalculationRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private CommissionCalculationRepository repository;

    // =====================================================================
    // findByWorkerIdAndPeriod — keresés worker + időszak szerint
    // =====================================================================
    @Test
    @DisplayName("findByWorkerIdAndPeriod: létező rekord megtalálása")
    void testFindByWorkerAndPeriod() {
        // Arrange — létrehozunk egy jutalék számítást
        CommissionCalculation calc = CommissionCalculation.builder()
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

        entityManager.persistAndFlush(calc);

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
        // Act — keresés nem létező worker-re
        Optional<CommissionCalculation> found = repository.findByWorkerIdAndPeriod(999L, "2030-12");

        // Assert
        assertThat(found).isEmpty();
    }

    @Test
    @DisplayName("existsByWorkerIdAndPeriod: létező rekord → true")
    void testExistsByWorkerAndPeriod() {
        // Arrange
        CommissionCalculation calc = CommissionCalculation.builder()
                .workerId(77L)
                .branchId(UUID.randomUUID())
                .period("2026-03")
                .calculationType(CommissionCalculation.CalculationType.MONTHLY)
                .totalTransactions(20)
                .totalVolumeHuf(new BigDecimal("1000000"))
                .commissionRate(new BigDecimal("0.01"))
                .commissionAmount(new BigDecimal("10000"))
                .bonusAmount(BigDecimal.ZERO)
                .deductions(BigDecimal.ZERO)
                .netCommission(new BigDecimal("10000"))
                .status(CommissionCalculation.CommissionStatus.CALCULATED)
                .calculatedAt(LocalDateTime.now())
                .build();

        entityManager.persistAndFlush(calc);

        // Act & Assert
        assertThat(repository.existsByWorkerIdAndPeriod(77L, "2026-03")).isTrue();
        assertThat(repository.existsByWorkerIdAndPeriod(77L, "2026-04")).isFalse();
    }
}
