package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.InventoryMovement;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDate;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.catchThrowable;

/**
 * FK-039 regresszio: az {@link InventoryMovementRepository#search} a
 * {@code (:param IS NULL OR ...)} optional-filter idiomaval NON-NULL datum-parameter eseten
 * PostgreSQL-en "could not determine data type of parameter $N" PSQLException-t dobott
 * (PSQLException -> 500 a /inventory "Keszlet riportok" movement-log + daily-balance vegpontjain;
 * a getMovements es getDailyBalance is ezt a query-t hivja).
 *
 * <p>A hiba PG-specifikus (a prepared-statement extended protocol nem tudja a standalone
 * {@code $N IS NULL} operandus tipusat kikovetkeztetni), ezert a H2/mock unit teszt NEM fogja
 * meg — valos PostgreSQL (Testcontainers) kell. A fix a datum-parametereket
 * {@code CAST(:startDate AS DATE)} type-hint-tel latja el; utana a query lefut.</p>
 *
 * <p>Docker szukseges — lokalisan tipikusan nem fut, CI-ben igen (lasd WorkerRepositoryPostgresLockIT).</p>
 */
@Testcontainers
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class InventoryMovementRepositorySearchPostgresIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired
    private InventoryMovementRepository inventoryMovementRepository;

    @Test
    @DisplayName("FK-039: search NON-NULL datum-parameterrel nem dob PostgreSQL tipus-hibat")
    void searchWithNonNullDateParamsDoesNotThrowOnPostgres() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        LocalDate date = LocalDate.of(2026, 6, 22);

        // A getMovements / getDailyBalance PONTOSAN ezzel a parameterezessel hivja:
        // (companyId, branchId, startDate=date, endDate=date, status=null, type=null) + unpaged.
        // A fix elott ez "could not determine data type of parameter" PSQLException-nel bukott.
        Throwable thrown = catchThrowable(() -> inventoryMovementRepository.search(
                companyId, branchId, date, date, null, null, Pageable.unpaged()));

        assertThat(thrown)
                .as("A (:startDate IS NULL OR ...) idioma NON-NULL datummal sem dobhat "
                        + "'could not determine data type of parameter' hibat valos PostgreSQL-en")
                .isNull();
    }

    @Test
    @DisplayName("FK-039: search opcionalis (null) szurokkel is lefut es ures Page-et ad")
    void searchWithNullOptionalFiltersReturnsEmptyPage() {
        Page<InventoryMovement> page = inventoryMovementRepository.search(
                UUID.randomUUID(), null, null, null, null, null, Pageable.unpaged());

        assertThat(page).isNotNull();
        assertThat(page.getContent()).isEmpty();
    }
}
