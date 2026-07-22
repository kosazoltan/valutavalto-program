package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@Testcontainers
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=none",
                "spring.flyway.enabled=true",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class DenominationBalanceSubmissionDatePostgresTest {

    private static final LocalDate DAY_T = LocalDate.of(2026, 7, 20);
    private static final LocalDate DAY_T_PLUS_ONE = DAY_T.plusDays(1);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private DenominationBalanceRepository repository;
    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    void sumDenominatedAmount_includesUnchangedRowsFromToday() {
        Seed seed = seedBalance(new BigDecimal("1000"), 100, new BigDecimal("100000"), DAY_T);

        transactionTemplate.executeWithoutResult(status -> {
            var balance = repository.findById(seed.balanceId()).orElseThrow();
            balance.setSubmissionDate(DAY_T_PLUS_ONE);
            repository.saveAndFlush(balance);
        });

        BigDecimal total = repository.sumDenominatedAmount(seed.branchId(), DAY_T_PLUS_ONE, "EVENING");

        assertThat(total).isEqualByComparingTo("100000");
        assertThat(repository.sumDenominatedAmount(seed.branchId(), DAY_T, "EVENING"))
                .isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(jdbcTemplate.queryForObject(
                "SELECT submission_date FROM denomination_balance WHERE id = ?",
                LocalDate.class,
                seed.balanceId())).isEqualTo(DAY_T_PLUS_ONE);
    }

    @Test
    void existsByBranchIdAndDateAndCategory_respectsCategoryAndSubmissionDate() {
        Seed seed = seedBalance(new BigDecimal("500"), 2, new BigDecimal("1000"), DAY_T_PLUS_ONE);
        jdbcTemplate.update(
                "UPDATE denomination_balance SET denomination_category = 'HANDLING_FEE' WHERE id = ?",
                seed.balanceId());

        assertThat(repository.existsByBranchIdAndDateAndCategory(
                seed.branchId(), DAY_T_PLUS_ONE, hu.puzzleir.valuta.entity.DenominationCategory.EVENING)).isFalse();

        jdbcTemplate.update(
                "UPDATE denomination_balance SET denomination_category = 'EVENING' WHERE id = ?",
                seed.balanceId());
        assertThat(repository.existsByBranchIdAndDateAndCategory(
                seed.branchId(), DAY_T_PLUS_ONE, hu.puzzleir.valuta.entity.DenominationCategory.EVENING)).isTrue();
        assertThat(repository.existsByBranchIdAndDateAndCategory(
                seed.branchId(), DAY_T, hu.puzzleir.valuta.entity.DenominationCategory.EVENING)).isFalse();
    }

    @Test
    void siblingDailyQueriesUseExactSubmissionDate() {
        Seed seed = seedBalance(new BigDecimal("200"), 3, new BigDecimal("600"), DAY_T_PLUS_ONE);

        assertThat(repository.sumDenominatedAmountByCategory(
                seed.branchId(), DAY_T_PLUS_ONE, hu.puzzleir.valuta.entity.DenominationCategory.EVENING))
                .isEqualByComparingTo("600");
        assertThat(repository.findByBranchIdAndDate(seed.branchId(), DAY_T_PLUS_ONE))
                .extracting(hu.puzzleir.valuta.entity.DenominationBalance::getId)
                .containsExactly(seed.balanceId());
        assertThat(repository.findByBranchIdAndDateAndCategory(
                seed.branchId(), DAY_T_PLUS_ONE, hu.puzzleir.valuta.entity.DenominationCategory.EVENING))
                .extracting(hu.puzzleir.valuta.entity.DenominationBalance::getId)
                .containsExactly(seed.balanceId());
    }

    @Test
    void sumActualStockByCurrency_usesExactSubmissionDate() {
        Seed seed = seedBalance(new BigDecimal("200"), 3, new BigDecimal("600"), DAY_T);
        jdbcTemplate.update(
                "UPDATE denomination_balance SET updated_at = ? WHERE id = ?",
                DAY_T_PLUS_ONE.atTime(9, 0),
                seed.balanceId());

        var rows = repository.sumActualStockByCurrency(
                seed.branchId(),
                DAY_T,
                hu.puzzleir.valuta.entity.DenominationCategory.EVENING);

        assertThat(rows).hasSize(1);
        assertThat(rows.get(0)[0]).isEqualTo("HUF");
        assertThat((BigDecimal) rows.get(0)[1]).isEqualByComparingTo("600");
    }

    @Test
    void mixedChangedAndUnchangedResubmissionsAreBothCounted() {
        Seed unchanged = seedBalance(new BigDecimal("1000"), 1, new BigDecimal("1000"), DAY_T);
        transactionTemplate.executeWithoutResult(status -> {
            var balance = repository.findById(unchanged.balanceId()).orElseThrow();
            balance.setSubmissionDate(DAY_T_PLUS_ONE);
            repository.saveAndFlush(balance);
        });

        Long denominationId = jdbcTemplate.queryForObject("""
                INSERT INTO denomination
                    (company_id, branch_id, currency_id, face_value, denomination_type, quantity, active)
                SELECT b.company_id, b.id, c.id, 200, 'BANKNOTE', 0, true
                  FROM branch b
                  JOIN currency c ON c.code = 'HUF'
                 WHERE b.id = ?
                RETURNING id
                """, Long.class, unchanged.branchId());
        jdbcTemplate.update("""
                INSERT INTO denomination_balance
                    (id, cash_desk_id, denomination_id, quantity, total_value, updated_at,
                     denomination_category, submission_date)
                VALUES (?, ?, ?, 3, 600, ?, 'EVENING', ?)
                """, UUID.randomUUID(), unchanged.branchId(), denominationId,
                DAY_T_PLUS_ONE.atTime(10, 0), DAY_T_PLUS_ONE);

        assertThat(repository.sumDenominatedAmount(unchanged.branchId(), DAY_T_PLUS_ONE, "EVENING"))
                .isEqualByComparingTo("1600");
    }

    @Test
    void saveWithoutSubmissionDateFailsNotNullContract() {
        Seed seed = seedBalance(new BigDecimal("100"), 1, new BigDecimal("100"), DAY_T);

        assertThatThrownBy(() -> transactionTemplate.executeWithoutResult(status -> {
            var balance = repository.findById(seed.balanceId()).orElseThrow();
            balance.setSubmissionDate(null);
            repository.saveAndFlush(balance);
        }))
                .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class)
                .hasMessageContaining("submission_date");
    }

    private Seed seedBalance(BigDecimal faceValue, int quantity, BigDecimal totalValue, LocalDate submissionDate) {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        UUID balanceId = UUID.randomUUID();
        String suffix = companyId.toString().substring(0, 8);
        jdbcTemplate.update(
                "INSERT INTO company (id, code, name, is_active, created_at) VALUES (?, ?, ?, true, NOW())",
                companyId, "F" + suffix, "FK-060 repository test company");
        jdbcTemplate.update(
                "INSERT INTO branch (id, code, company_id, name) VALUES (?, ?, ?, ?)",
                branchId, "B" + suffix, companyId, "FK-060 repository test branch");
        Long currencyId = jdbcTemplate.queryForObject("SELECT id FROM currency WHERE code = 'HUF'", Long.class);
        Long denominationId = jdbcTemplate.queryForObject("""
                INSERT INTO denomination
                    (company_id, branch_id, currency_id, face_value, denomination_type, quantity, active)
                VALUES (?, ?, ?, ?, 'BANKNOTE', 0, true)
                RETURNING id
                """, Long.class, companyId, branchId, currencyId, faceValue);
        jdbcTemplate.update("""
                INSERT INTO denomination_balance
                    (id, cash_desk_id, denomination_id, quantity, total_value, updated_at,
                     denomination_category, submission_date)
                VALUES (?, ?, ?, ?, ?, ?, 'EVENING', ?)
                """, balanceId, branchId, denominationId, quantity, totalValue,
                DAY_T.atTime(18, 0), submissionDate);
        return new Seed(branchId, balanceId);
    }

    private record Seed(UUID branchId, UUID balanceId) {
    }
}
