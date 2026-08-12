package hu.puzzleir.valuta.migration;

import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-081: a `seedCatalogForCompany` natív INSERT bizonyítása VALÓS Postgres ellen.
 *
 * <p>A unit teszt ({@code DenominationCatalogSeedFk081Test}) a repository-t mockolja, ezért
 * a natív SQL helyességéről semmit nem mond: oszlopnév-elgépelés, rossz alkérdés vagy
 * sérült multi-tenant szűrés ott NEM bukna ki. Ez a teszt a tényleges séma és a tényleges
 * migrációs adat (V376 + V379) ellen fut.
 */
@SpringBootTest(
        classes = hu.puzzleir.valuta.TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=none",
                "spring.flyway.enabled=true",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
@Testcontainers
class DenominationCatalogSeedFk081PostgresTest {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void datasourceProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
    }

    @Autowired private DenominationAllowedRepository repository;
    @Autowired private JdbcTemplate jdbc;

    private UUID newCompanyId;

    @BeforeEach
    void insertBrandNewCompany() {
        // A migraciok UTAN letrehozott ceg — pontosan az FK-081 forgatokonyve.
        newCompanyId = UUID.randomUUID();
        jdbc.update("INSERT INTO company (id, name, code, is_active, created_at) "
                + "VALUES (?, ?, ?, true, NOW())", newCompanyId, "FK-081 New Tenant", "FK081N");
    }

    @Test
    @Transactional
    @DisplayName("FK-081: új cég katalógusa üresről a teljes törvényes listára töltődik — HUF-fal, 1/2 Ft nélkül")
    void seedFillsTheCatalogOfABrandNewCompanyFromExistingMasterData() {
        // ELŐTTE: a friss cegnek egyetlen katalogus-sora sincs.
        assertThat(repository.findActiveByCompanyId(newCompanyId))
                .as("Az FK-081 kiindulasa: a migraciok utan letrehozott ceg katalogusa URES")
                .isEmpty();

        Long referenceRows = jdbc.queryForObject(
                "SELECT count(*) FROM denomination_allowed da "
                        + "WHERE da.company_id = (SELECT company_id FROM denomination_allowed "
                        + "WHERE is_active = true GROUP BY company_id "
                        + "ORDER BY count(*) DESC, company_id ASC LIMIT 1)", Long.class);

        int seeded = repository.seedCatalogForCompany(newCompanyId);

        assertThat(seeded)
                .as("A seed a referencia-ceg TELJES aktiv katalogusat atmasolja")
                .isEqualTo(referenceRows.intValue());

        List<DenominationAllowed> catalog = repository.findActiveByCompanyId(newCompanyId);
        assertThat(catalog).hasSize(referenceRows.intValue());

        // A HUF benne van (V379) — enelkul az FK-080 ota a torvenyes HUF-zaras is elbukna.
        assertThat(catalog).anySatisfy(row ->
                assertThat(row.getCurrency().getCode()).isEqualTo("HUF"));

        Long hufRows = jdbc.queryForObject(
                "SELECT count(*) FROM denomination_allowed da JOIN currency c ON c.id = da.currency_id "
                        + "WHERE da.company_id = ? AND c.code = 'HUF'", Long.class, newCompanyId);
        assertThat(hufRows).as("12 torvenyes HUF cimlet (6 erme + 6 bankjegy)").isEqualTo(12L);

        // A bevont 1 es 2 forint SOHA nem kerulhet at.
        Long withdrawn = jdbc.queryForObject(
                "SELECT count(*) FROM denomination_allowed da JOIN currency c ON c.id = da.currency_id "
                        + "WHERE da.company_id = ? AND c.code = 'HUF' AND da.face_value IN (1, 2)",
                Long.class, newCompanyId);
        assertThat(withdrawn).as("HUF 1 es 2 forint (2008-ban bevonva) nem kerulhet a katalogusba").isZero();

        // Erme kizarolag HUF 200..5 es EUR 2/1 lehet.
        Long badCoins = jdbc.queryForObject(
                "SELECT count(*) FROM denomination_allowed da JOIN currency c ON c.id = da.currency_id "
                        + "WHERE da.company_id = ? AND da.denomination_type = 'COIN' "
                        + "AND c.code NOT IN ('HUF','EUR')", Long.class, newCompanyId);
        assertThat(badCoins).as("EUR-on es HUF-on kivul erme nem engedelyezett").isZero();
    }

    @Test
    @Transactional
    @DisplayName("FK-081 idempotencia: a seed második futása 0 sort ír be (uq_denomination_allowed nem sérül)")
    void secondSeedRunInsertsNothing() {
        int first = repository.seedCatalogForCompany(newCompanyId);
        assertThat(first).isPositive();

        int second = repository.seedCatalogForCompany(newCompanyId);

        assertThat(second).as("NFR-1: ismetelt futas 0 sort ir be").isZero();
        assertThat(repository.findActiveByCompanyId(newCompanyId)).hasSize(first);
    }

    @Test
    @Transactional
    @DisplayName("FK-081 multi-tenant: a seed CSAK a megadott céghez ír — más cégek sorszáma változatlan")
    void seedNeverTouchesOtherTenants() {
        Long otherRowsBefore = jdbc.queryForObject(
                "SELECT count(*) FROM denomination_allowed WHERE company_id <> ?", Long.class, newCompanyId);

        repository.seedCatalogForCompany(newCompanyId);

        Long otherRowsAfter = jdbc.queryForObject(
                "SELECT count(*) FROM denomination_allowed WHERE company_id <> ?", Long.class, newCompanyId);
        assertThat(otherRowsAfter)
                .as("A seed egyetlen masik ceg katalogusat sem modosithatja")
                .isEqualTo(otherRowsBefore);

        // A beirt sorok tulajdonosa kizarolag az uj ceg.
        Long wrongOwner = jdbc.queryForObject(
                "SELECT count(*) FROM denomination_allowed WHERE company_id = ? "
                        + "AND company_id <> ?", Long.class, newCompanyId, newCompanyId);
        assertThat(wrongOwner).isZero();
    }
}
