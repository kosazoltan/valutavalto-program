package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * FK-038 regresszios teszt: a {@link BranchRepository#findPathToRoot(java.util.UUID)}
 * rekurziv CTE nem dobhat SQL-hibat, es a gyokertol a kiindulo branch-ig adja a path-ot.
 *
 * <p>Gyoker ok (javitva): a query zaro sora korabban
 * {@code SELECT * FROM branch WHERE id IN (SELECT id FROM branch_path) ORDER BY level DESC}
 * volt, ahol a level oszlop csak a branch_path CTE-ben letezik, NEM a branch tablaban —
 * PostgreSQL "column level does not exist" -> 500 a {@code GET /api/v1/branches/{id}/path}
 * vegponton (a kozponti kliens "Iroda szerkesztese" oldalan "Belso szerverhiba" banner).
 * A javitas a path-elemeket a CTE-vel JOIN-olja, igy az ORDER BY a bp.level CTE-oszlopra
 * hivatkozhat.</p>
 *
 * <p><b>Testcontainers PostgreSQL</b> kell: a query PostgreSQL-specifikus native rekurziv
 * CTE, amit H2-n nem lehet ervenyesen tesztelni (a {@code WorkerRepositoryPostgresLockIT}
 * ugyanezert hasznal valodi PostgreSQL-t). A teszt sajat parent -> child hierarchiat seed-el.</p>
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
@Transactional
class BranchPathRepositoryIT {

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
    private BranchRepository branchRepository;

    @Autowired
    private CompanyRepository companyRepository;

    @Autowired
    private DictionaryRepository dictionaryRepository;

    @Test
    @DisplayName("FK-038: findPathToRoot nem dob SQL-hibat es a gyokertol a branch-ig adja a path-ot")
    void findPathToRoot_runsWithoutSqlError_andReturnsRootToLeafOrder() {
        LocalDateTime now = LocalDateTime.now();
        String suffix = Long.toString(System.nanoTime());
        String shortSuffix = suffix.substring(Math.max(0, suffix.length() - 10));

        Company company = companyRepository.save(Company.builder()
                .code("TCP" + shortSuffix)
                .name("FK-038 Path Test Company")
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE").code("TCP-BT-" + suffix).name("Test branch type").createdAt(now).build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY").code("TCP-CO-" + suffix).name("Hungary").createdAt(now).build());
        Dictionary status = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS").code("TCP-ST-" + suffix).name("Active").createdAt(now).build());

        Branch root = branchRepository.save(Branch.builder()
                .code("TCP-ROOT-" + shortSuffix)
                .company(company).bankCode("TCBANK").branchType(branchType)
                .name("FK-038 Root").address("Root Street 1").city("Budapest").zipCode("1000")
                .country(country).branchStatus(status).openingDate(LocalDate.now()).createdAt(now)
                .build());
        Branch child = branchRepository.saveAndFlush(Branch.builder()
                .code("TCP-CHILD-" + shortSuffix)
                .company(company).bankCode("TCBANK").branchType(branchType)
                .name("FK-038 Child").address("Child Street 2").city("Szeged").zipCode("6700")
                .country(country).branchStatus(status).parentBranch(root)
                .openingDate(LocalDate.now()).createdAt(now)
                .build());

        // A regi (hibas) query "column level does not exist" SQLException-t dobott — ez most NEM dobhat.
        assertThatCode(() -> branchRepository.findPathToRoot(child.getId()))
                .as("a rekurziv path-query nem dobhat SQL-hibat (FK-038 regresszio)")
                .doesNotThrowAnyException();

        List<Branch> path = branchRepository.findPathToRoot(child.getId());
        assertThat(path)
                .as("a path a gyokertol a kiindulo branch-ig: [root, child]")
                .extracting(Branch::getId)
                .containsExactly(root.getId(), child.getId());
    }
}
