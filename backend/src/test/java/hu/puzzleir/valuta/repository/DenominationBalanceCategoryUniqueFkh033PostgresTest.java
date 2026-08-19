package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationBalance;
import hu.puzzleir.valuta.entity.DenominationCategory;
import org.junit.jupiter.api.DisplayName;
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
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * FKH-033: kategoria-tudatos {@code denomination_balance} upsert — perzisztencia-szintu
 * regressziovedelem valos PostgreSQL-en.
 *
 * <p>A PR #1588 code-review BLOCK-verdiktje: a V75-os
 * {@code (cash_desk_id, denomination_id)} egyedi kulcs miatt az ELSO
 * {@code HANDLING_FEE} cimlet-mentes {@code DataIntegrityViolationException}-t dobott,
 * ha ugyanarra a cimletre mar allt {@code EVENING} sor — vagyis a torvenyileg kotelezo
 * napi zaras varazsloja 500-zal osszeomlott. A javitas: V378 kategoria-tudatos kulcs +
 * kategoria-tudatos lookup a szervizekben.</p>
 */
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
class DenominationBalanceCategoryUniqueFkh033PostgresTest {

    private static final LocalDate BUSINESS_DATE = LocalDate.of(2026, 8, 10);

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private DenominationBalanceRepository balanceRepository;
    @Autowired private DenominationRepository denominationRepository;
    @Autowired private JdbcTemplate jdbcTemplate;
    @Autowired private TransactionTemplate transactionTemplate;

    /**
     * A BLOKKOLO eset: esti cimletezes utan kezelesi-dij cimletezes ugyanarra a cimletre.
     * A javitas elott ez {@code DataIntegrityViolationException}-t dobott.
     */
    @Test
    @DisplayName("FKH-033: EVENING utan HANDLING_FEE mentes ugyanarra a cimletre SIKERES, "
            + "es a ket sor kulon el")
    void handlingFeeSaveAfterEveningSucceeds() {
        Fixture fixture = seed();

        saveBalance(fixture, DenominationCategory.EVENING, 10, new BigDecimal("100000.00"));

        assertThatCode(() ->
                saveBalance(fixture, DenominationCategory.HANDLING_FEE, 3, new BigDecimal("30000.00")))
                .as("Az ELSO HANDLING_FEE mentes nem utkozhet az esti sorral")
                .doesNotThrowAnyException();

        assertThat(balanceRepository.findByCashDeskIdAndDenominationIdAndCategory(
                fixture.branchId(), fixture.denominationId(), DenominationCategory.EVENING))
                .get()
                .extracting(DenominationBalance::getTotalValue)
                .satisfies(value -> assertThat((BigDecimal) value).isEqualByComparingTo("100000.00"));

        assertThat(balanceRepository.findByCashDeskIdAndDenominationIdAndCategory(
                fixture.branchId(), fixture.denominationId(), DenominationCategory.HANDLING_FEE))
                .get()
                .extracting(DenominationBalance::getTotalValue)
                .satisfies(value -> assertThat((BigDecimal) value).isEqualByComparingTo("30000.00"));

        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM denomination_balance WHERE cash_desk_id = ?",
                Integer.class, fixture.branchId()))
                .as("Pontosan ket sor: egy kategoriankent")
                .isEqualTo(2);
    }

    /**
     * FKH-038 FR-1: a currency-scope READ kategóriára szűr. Ugyanarra a
     * (cashDeskId, denominationId) párra EVENING és HANDLING_FEE sor is létezik;
     * a lekérdezés kategóriánként csak a saját sort adja vissza.
     */
    @Test
    @DisplayName("FKH-038 FR-1: findByCashDeskIdAndCurrencyIdAndCategory nem keveri az EVENING "
            + "es HANDLING_FEE sorokat")
    void currencyScopedLoadFiltersByCategory() {
        Fixture fixture = seed();
        saveBalance(fixture, DenominationCategory.EVENING, 10, new BigDecimal("100000.00"));
        saveBalance(fixture, DenominationCategory.HANDLING_FEE, 3, new BigDecimal("30000.00"));

        Long currencyId = jdbcTemplate.queryForObject(
                "SELECT currency_id FROM denomination WHERE id = ?",
                Long.class, fixture.denominationId());

        var evening = balanceRepository.findByCashDeskIdAndCurrencyIdAndCategory(
                fixture.branchId(), currencyId, DenominationCategory.EVENING);
        var handlingFee = balanceRepository.findByCashDeskIdAndCurrencyIdAndCategory(
                fixture.branchId(), currencyId, DenominationCategory.HANDLING_FEE);

        assertThat(evening).hasSize(1);
        assertThat(evening.get(0).getQuantity()).isEqualTo(10);
        assertThat(evening.get(0).getDenominationCategory()).isEqualTo(DenominationCategory.EVENING);

        assertThat(handlingFee).hasSize(1);
        assertThat(handlingFee.get(0).getQuantity()).isEqualTo(3);
        assertThat(handlingFee.get(0).getDenominationCategory())
                .isEqualTo(DenominationCategory.HANDLING_FEE);
    }

    /**
     * A kategorian BELULI vedelem nem gyengulhet: ugyanaz a kategoria tovabbra is
     * UPDATE-et jelent, nem masodik sort.
     */
    @Test
    @DisplayName("FKH-033: azonos kategoria ismetelt mentese UPDATE marad (nem keletkezik masodik sor)")
    void sameCategoryResaveStaysUpsert() {
        Fixture fixture = seed();

        saveBalance(fixture, DenominationCategory.EVENING, 10, new BigDecimal("100000.00"));
        UUID firstId = balanceRepository.findByCashDeskIdAndDenominationIdAndCategory(
                        fixture.branchId(), fixture.denominationId(), DenominationCategory.EVENING)
                .orElseThrow()
                .getId();

        saveBalance(fixture, DenominationCategory.EVENING, 12, new BigDecimal("120000.00"));

        assertThat(jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM denomination_balance WHERE cash_desk_id = ?",
                Integer.class, fixture.branchId()))
                .as("Az azonos kategoria upsert, nem insert")
                .isEqualTo(1);
        DenominationBalance reloaded = balanceRepository.findById(firstId).orElseThrow();
        assertThat(reloaded.getQuantity()).isEqualTo(12);
        assertThat(reloaded.getTotalValue()).isEqualByComparingTo("120000.00");
    }

    /**
     * A DB-szintu vedelem tenyleg letezik: nyers INSERT-tel sem lehet ket azonos
     * (penztar, cimlet, kategoria) sort letrehozni.
     */
    @Test
    @DisplayName("FKH-033: a kategoria-tudatos egyedi kulcs DB-szinten is tiltja a duplikatumot")
    void databaseRejectsDuplicateWithinSameCategory() {
        Fixture fixture = seed();
        saveBalance(fixture, DenominationCategory.EVENING, 10, new BigDecimal("100000.00"));

        assertThatThrownBy(() -> jdbcTemplate.update("""
                INSERT INTO denomination_balance
                    (id, cash_desk_id, denomination_id, quantity, total_value, updated_at,
                     denomination_category, submission_date)
                VALUES (?, ?, ?, 1, 10000, NOW(), 'EVENING', ?)
                """, UUID.randomUUID(), fixture.branchId(), fixture.denominationId(), BUSINESS_DATE))
                .isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);
    }

    // ============================ FIXTURE ============================

    private void saveBalance(Fixture fixture, DenominationCategory category,
                             int quantity, BigDecimal totalValue) {
        transactionTemplate.executeWithoutResult(status -> {
            Denomination denomination = denominationRepository.findById(fixture.denominationId())
                    .orElseThrow();
            DenominationBalance balance = balanceRepository
                    .findByCashDeskIdAndDenominationIdAndCategory(
                            fixture.branchId(), fixture.denominationId(), category)
                    .orElseGet(() -> DenominationBalance.builder()
                            .cashDeskId(fixture.branchId())
                            .denomination(denomination)
                            .quantity(0)
                            .totalValue(BigDecimal.ZERO)
                            .denominationCategory(category)
                            .build());
            balance.setQuantity(quantity);
            balance.setTotalValue(totalValue);
            balance.setDenominationCategory(category);
            balance.setSubmissionDate(BUSINESS_DATE);
            balanceRepository.saveAndFlush(balance);
        });
    }

    private Fixture seed() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        String suffix = companyId.toString().substring(0, 8);
        jdbcTemplate.update(
                "INSERT INTO company (id, code, name, is_active, created_at) VALUES (?, ?, ?, true, NOW())",
                companyId, "F" + suffix, "FKH-033 test company");
        jdbcTemplate.update(
                "INSERT INTO branch (id, code, company_id, name) VALUES (?, ?, ?, ?)",
                branchId, "B" + suffix, companyId, "FKH-033 test branch");
        Long currencyId = jdbcTemplate.queryForObject(
                "SELECT id FROM currency WHERE code = 'HUF'", Long.class);
        Long denominationId = jdbcTemplate.queryForObject("""
                INSERT INTO denomination
                    (company_id, branch_id, currency_id, face_value, denomination_type, quantity, active)
                VALUES (?, ?, ?, 10000, 'BANKNOTE', 0, true)
                RETURNING id
                """, Long.class, companyId, branchId, currencyId);
        return new Fixture(branchId, denominationId);
    }

    private record Fixture(UUID branchId, Long denominationId) {
    }
}
