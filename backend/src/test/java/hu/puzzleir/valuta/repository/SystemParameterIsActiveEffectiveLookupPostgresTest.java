package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.SystemParameter;
import hu.puzzleir.valuta.service.SystemParameterService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Az effektív (olvasási) system_parameter lookup is_active-szűrésének SQL-szintű bizonyítéka
 * valós PostgreSQL-en — a mock-alapú {@code SystemParameterServiceTest} a service-szerződést
 * pineli, ez a JPQL tényleges viselkedését.
 *
 * <p>Kulcs-eset a NULL-tolerancia: az {@code is_active} oszlopnak nincs NOT NULL kikötése
 * (V3_5/V74), ezért a régi, {@code is_active} nélkül beszúrt sor NULL-t tartalmazhat —
 * annak TOVÁBBRA IS érvényes találatnak kell lennie, különben a szűrés bevezetése némán
 * kiejtene élő paramétereket.
 */
@Testcontainers
@Import({ SystemParameterService.class, hu.puzzleir.valuta.service.AuditLogService.class })
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class SystemParameterIsActiveEffectiveLookupPostgresTest {

    private static final UUID COMPANY_A = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private SystemParameterRepository repository;
    @Autowired private SystemParameterService service;
    @Autowired private JdbcTemplate jdbcTemplate;

    private String uniqueKey(String suffix) {
        return "TEST_IS_ACTIVE_" + suffix + "_" + UUID.randomUUID().toString().substring(0, 8);
    }

    private void insertRow(String key, String value, UUID companyId, Boolean isActive) {
        jdbcTemplate.update("""
                INSERT INTO system_parameter
                       (id, parameter_key, company_id, parameter_value, parameter_type, category, is_active)
                VALUES (?, ?, ?, ?, 'STRING', 'CLOSING', ?)
                """, UUID.randomUUID(), key, companyId, value, isActive);
    }

    @Test
    @DisplayName("aktív globális sor → effektív találat")
    void activeGlobalRowIsFound() {
        String key = uniqueKey("ACTIVE_GLOBAL");
        insertRow(key, "5", null, Boolean.TRUE);

        assertThat(repository.findEffectiveGlobalByParameterKey(key))
                .map(SystemParameter::getParameterValue)
                .contains("5");
    }

    @Test
    @DisplayName("inaktivált globális sor → NINCS effektív találat (a szűrés SQL-ben él)")
    void inactiveGlobalRowIsFilteredOut() {
        String key = uniqueKey("INACTIVE_GLOBAL");
        insertRow(key, "5000", null, Boolean.FALSE);

        assertThat(repository.findEffectiveGlobalByParameterKey(key)).isEmpty();
        // a szűretlen (admin/írási) út továbbra is megtalálja ugyanazt a sort:
        assertThat(repository.findByParameterKeyAndCompanyIdIsNull(key)).isPresent();
        // és a service publikus effektív olvasása is üres → a hívó fallback-ága dönt:
        assertThat(service.findEffectiveValue(key)).isEmpty();
    }

    @Test
    @DisplayName("is_active NULL (régi, kitöltetlen sor) → TOVÁBBRA IS effektív találat")
    void nullIsActiveRowStaysEffective() {
        String key = uniqueKey("NULL_ACTIVE");
        insertRow(key, "1000000", null, null);

        assertThat(jdbcTemplate.queryForObject(
                "SELECT is_active FROM system_parameter WHERE parameter_key = ?", Boolean.class, key))
                .isNull();
        assertThat(repository.findEffectiveGlobalByParameterKey(key))
                .map(SystemParameter::getParameterValue)
                .contains("1000000");
        assertThat(service.findEffectiveValue(key)).contains("1000000");
    }

    @Test
    @DisplayName("audit — a create() ténylegesen INSERT-el egy audit_log sort (security-standards §3)")
    void createWritesRealAuditLogRow() {
        String key = uniqueKey("AUDIT_CREATE");

        SystemParameter created = service.create(key, "42", "STRING", "CLOSING", "audit-teszt", Boolean.FALSE);

        Map<String, Object> row = jdbcTemplate.queryForMap("""
                SELECT action, entity_type, entity_id, old_value, new_value, entry_hash
                  FROM audit_log
                 WHERE entity_type = 'SystemParameter' AND entity_id = ?
                """, created.getId().toString());

        assertThat(row.get("action")).isEqualTo("CREATE");
        assertThat(row.get("old_value")).isNull();
        assertThat((String) row.get("new_value"))
                .contains("\"parameterKey\":\"" + key + "\"")
                .contains("\"parameterValue\":\"42\"")
                .contains("\"isActive\":false");
        // hash-lánc (tamper-evidence) is kitöltődik, nem csak a mezők:
        assertThat((String) row.get("entry_hash")).isNotBlank();
    }

    @Test
    @DisplayName("audit — a toggleActive() UPDATE sort ír a DB-ből olvasott VALÓDI előző is_active-val")
    void toggleActiveWritesAuditLogRowWithRealBeforeState() {
        String key = uniqueKey("AUDIT_TOGGLE");
        SystemParameter created = service.create(key, "1", "STRING", "CLOSING", null, Boolean.TRUE);

        service.toggleActive(created.getId());

        Map<String, Object> row = jdbcTemplate.queryForMap("""
                SELECT action, old_value, new_value, reason
                  FROM audit_log
                 WHERE entity_type = 'SystemParameter' AND entity_id = ? AND action = 'UPDATE'
                """, created.getId().toString());

        assertThat((String) row.get("old_value")).contains("\"isActive\":true");
        assertThat((String) row.get("new_value")).contains("\"isActive\":false");
        assertThat((String) row.get("reason")).contains("true").contains("false");
    }

    @Test
    @DisplayName("toggleActive — valós NULL is_active soron: nincs NPE, explicit false lesz, az audit a null-t rögzíti")
    void toggleActiveOnRealNullIsActiveRow() {
        String key = uniqueKey("TOGGLE_NULL");
        insertRow(key, "1", null, null);
        SystemParameter row = repository.findByParameterKeyAndCompanyIdIsNull(key).orElseThrow();
        assertThat(row.getIsActive()).as("a DB-ből valóban null jön vissza").isNull();

        service.toggleActive(row.getId());

        assertThat(jdbcTemplate.queryForObject(
                "SELECT is_active FROM system_parameter WHERE parameter_key = ?", Boolean.class, key))
                .isFalse();
        Map<String, Object> auditRow = jdbcTemplate.queryForMap("""
                SELECT old_value, new_value FROM audit_log
                 WHERE entity_type = 'SystemParameter' AND entity_id = ? AND action = 'UPDATE'
                """, row.getId().toString());
        assertThat((String) auditRow.get("old_value")).contains("\"isActive\":null");
        assertThat((String) auditRow.get("new_value")).contains("\"isActive\":false");
    }

    @Test
    @DisplayName("audit — titok-értékű kulcs értéke NEM kerül be az audit_log sorba")
    void secretValuedParameterIsMaskedInAuditLog() {
        String key = uniqueKey("MNB_API_TOKEN");

        SystemParameter created = service.create(key, "sup3r-titkos-token", "STRING", "INTEGRATION", null, null);

        String newValue = jdbcTemplate.queryForObject("""
                SELECT new_value FROM audit_log
                 WHERE entity_type = 'SystemParameter' AND entity_id = ?
                """, String.class, created.getId().toString());

        assertThat(newValue).doesNotContain("sup3r-titkos-token").contains(key);
    }

    @Test
    @DisplayName("inaktivált cég-override → a cég-lekérdezés üres, a globális sor marad az effektív")
    void inactiveCompanyOverrideFallsBackToGlobalRow() {
        String key = uniqueKey("COMPANY_OVERRIDE");
        insertRow(key, "999", COMPANY_A, Boolean.FALSE);
        insertRow(key, "1000000", null, Boolean.TRUE);

        Optional<SystemParameter> scoped = repository.findEffectiveByParameterKeyAndCompanyId(key, COMPANY_A);
        assertThat(scoped).isEmpty();
        assertThat(repository.findEffectiveGlobalByParameterKey(key))
                .map(SystemParameter::getParameterValue)
                .contains("1000000");
        // getCompanyValue SOHA nem esik vissza globálisra → az inaktív cég-sor defaultot ad:
        assertThat(service.getCompanyValue(key, COMPANY_A, "def")).isEqualTo("def");
    }
}
