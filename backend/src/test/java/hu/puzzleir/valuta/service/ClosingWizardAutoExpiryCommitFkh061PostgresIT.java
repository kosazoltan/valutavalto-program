package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingType;
import hu.puzzleir.valuta.entity.ClosingWizard;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.WizardStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.DictionaryRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;

/**
 * FKH-061 (PR #1740 review): the stale-wizard auto-expiry must COMMIT its transition.
 *
 * <p>SCOPE — read this before trusting the green. The Mockito sibling
 * ({@code ClosingWizardAutoExpiryFkh061Test}) runs on a raw {@code @InjectMocks} instance: no
 * persistence context, no bulk-update version bump, no commit. It proves only that
 * {@code ClosingWizardService} no longer dirties the loaded entity. This IT proves the other
 * half — the TRANSACTION SEMANTICS on real PostgreSQL: that a bulk {@code transitionIfStale}
 * followed by a managed-entity mutation loses the commit, while the bulk UPDATE alone commits
 * and bumps the version.</p>
 *
 * <p>What this IT does NOT do: it does not run {@code ClosingWizardService.autoExpireStaleWizards}
 * itself. That service has ~18 collaborators and {@code TestApplication} deliberately does not
 * component-scan services, so wiring it here is not viable. The harness below replicates the
 * service's exact sequence instead. Consequence, stated plainly: if someone re-introduces the
 * managed-entity mutation INSIDE the service, THIS test stays green and the Mockito sibling is
 * the one that catches it. The two tests are complementary; neither alone is sufficient.</p>
 *
 * <p>Defect shape observed in PRODUCTION (2026-09-11 03:30:00Z, first scheduler tick after the
 * V389 deploy): the tick logged {@code "1 varázsló lejáratva"} while {@code closing_wizard} held
 * ZERO {@code EXPIRED} rows, and three records failed with
 * {@code Unexpected row count (expected row count 1 but was 0) [update closing_wizard set ... where id=? and version=?]}.
 * {@code transitionIfStale} is a {@code @Modifying} bulk UPDATE that increments the DB
 * {@code version} column; the in-memory {@code setWizardStatus(EXPIRED)} then left the managed
 * entity dirty, so the commit-time flush issued an entity UPDATE with the PRE-bulk version,
 * threw, and rolled the whole tick back — including transitions that had already succeeded.</p>
 *
 * <p>EXECUTION CAVEAT (repo-wide, pre-existing): no {@code *PostgresIT} class is picked up by the
 * default {@code mvn test} run — Surefire's default includes cover {@code *Test} / {@code Test*} /
 * {@code *Tests} / {@code *TestCase} only, and {@code backend/pom.xml} configures no Failsafe
 * execution. Invoke explicitly:
 * {@code cd backend && ./mvnw -o test -Dtest=ClosingWizardAutoExpiryCommitFkh061PostgresIT}
 * (Docker required). Stated so nobody believes a green {@code mvn test} covered it.</p>
 */
@Testcontainers
@EnableJpaAuditing
@Import({
        ClosingWizardAutoExpiryCommitFkh061PostgresIT.ExpiryHarness.class
})
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class ClosingWizardAutoExpiryCommitFkh061PostgresIT {

    private static final AtomicInteger SEQ = new AtomicInteger();

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private ExpiryHarness harness;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private ClosingWizardRepository closingWizardRepository;
    @Autowired private WorkerRepository workerRepository;
    @Autowired private JdbcTemplate jdbcTemplate;

    private Dictionary dictionary(String category, String code, String name, String nameHu) {
        return dictionaryRepository.findByCategoryAndCode(category, code)
                .orElseGet(() -> {
                    Dictionary d = new Dictionary();
                    d.setCategory(category);
                    d.setCode(code);
                    d.setName(name);
                    d.setNameHu(nameHu);
                    return dictionaryRepository.saveAndFlush(d);
                });
    }

    private Branch persistBranch() {
        int n = SEQ.incrementAndGet();
        Company company = new Company();
        company.setName("FKH061 IT company " + n);
        company.setCode("F61C" + n);
        company = companyRepository.saveAndFlush(company);

        // Branch has three NOT NULL dictionary FKs (branch_type_did, country_did,
        // branch_status_did). (category, code) is unique, so reuse rows across branches.
        Dictionary branchType = dictionary("BRANCH_TYPE", "PENZTAR", "Penztar", "Pénztár");
        Dictionary country = dictionary("COUNTRY", "HU", "Hungary", "Magyarország");
        Dictionary branchStatus = dictionary("BRANCH_STATUS", "ACTIVE", "Active", "Aktív");

        Branch branch = new Branch();
        branch.setCompany(company);
        branch.setCode("F61B" + n);
        branch.setName("FKH061 IT branch " + n);
        branch.setBranchType(branchType);
        branch.setCountry(country);
        branch.setBranchStatus(branchStatus);
        // Every NOT NULL column of `branch` (verified against the entity's @Column annotations).
        branch.setBankCode("F61BANK" + n);
        branch.setAddress("Teszt utca 1.");
        branch.setCity("Szeged");
        branch.setZipCode("6720");
        branch.setOpeningDate(LocalDate.of(2020, 1, 1));
        return branchRepository.saveAndFlush(branch);
    }

    private Worker persistWorker(Branch branch) {
        int n = SEQ.incrementAndGet();
        Worker worker = new Worker();
        worker.setCompany(branch.getCompany());
        worker.setBranch(branch);
        worker.setCode("F61W" + n);
        worker.setName("FKH061 IT worker " + n);
        worker.setRole(WorkerRole.CASHIER);
        return workerRepository.saveAndFlush(worker);
    }

    private UUID persistStaleWizard(Branch branch) {
        ClosingWizard wizard = ClosingWizard.builder()
                .branch(branch)
                .closingDate(LocalDate.of(2026, 9, 10))
                .closingType(ClosingType.DAILY)
                .currentStep(9)
                .totalSteps(9)
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .startedByWorker(persistWorker(branch))
                // Well beyond the 120-minute default threshold.
                .startedAt(LocalDateTime.now().minusHours(6))
                .build();
        return closingWizardRepository.saveAndFlush(wizard).getId();
    }

    @Test
    @DisplayName("FKH-061: auto-expiry COMMITS the EXPIRED transition (no stale-version rollback)")
    void autoExpiryCommitsTransition() {
        Branch branch = persistBranch();
        UUID wizardId = persistStaleWizard(branch);

        Long versionBefore = jdbcTemplate.queryForObject(
                "SELECT version FROM closing_wizard WHERE id = ?", Long.class, wizardId);
        String statusBefore = jdbcTemplate.queryForObject(
                "SELECT wizard_status FROM closing_wizard WHERE id = ?", String.class, wizardId);
        assertThat(statusBefore).isEqualTo("IN_PROGRESS");

        // Runs the scheduler path through a REAL transaction boundary: the commit happens when
        // this call returns. On the defective code the flush threw UnexpectedRollbackException /
        // ObjectOptimisticLockingFailureException here.
        assertThatCode(() -> harness.runExpiryInTransaction())
                .doesNotThrowAnyException();

        // THE POINT: the transition must be COMMITTED and visible outside the transaction.
        String statusAfter = jdbcTemplate.queryForObject(
                "SELECT wizard_status FROM closing_wizard WHERE id = ?", String.class, wizardId);
        assertThat(statusAfter)
                .as("the EXPIRED transition must survive the commit (prod: log said 1, DB had 0)")
                .isEqualTo("EXPIRED");

        Long versionAfter = jdbcTemplate.queryForObject(
                "SELECT version FROM closing_wizard WHERE id = ?", Long.class, wizardId);
        assertThat(versionAfter)
                .as("the bulk UPDATE increments the version column")
                .isGreaterThan(versionBefore);
    }

    @Test
    @DisplayName("FKH-061: a fresh wizard is left IN_PROGRESS and committed untouched")
    void freshWizardUntouched() {
        Branch branch = persistBranch();
        ClosingWizard fresh = ClosingWizard.builder()
                .branch(branch)
                .closingDate(LocalDate.of(2026, 9, 10))
                .closingType(ClosingType.DAILY)
                .currentStep(2)
                .totalSteps(9)
                .wizardStatus(WizardStatus.IN_PROGRESS)
                .startedByWorker(persistWorker(branch))
                .startedAt(LocalDateTime.now().minusMinutes(15))
                .build();
        UUID freshId = closingWizardRepository.saveAndFlush(fresh).getId();

        assertThatCode(() -> harness.runExpiryInTransaction()).doesNotThrowAnyException();

        String status = jdbcTemplate.queryForObject(
                "SELECT wizard_status FROM closing_wizard WHERE id = ?", String.class, freshId);
        assertThat(status).isEqualTo("IN_PROGRESS");
    }

    /**
     * Mirrors the production caller and the service loop at the transaction boundary.
     *
     * <p>{@code ClosingWizardService} has ~18 collaborators and is not a candidate for the
     * {@code TestApplication} context (which deliberately does not component-scan services), so
     * this harness reproduces the EXACT sequence the service performs inside
     * {@code SchedulerService}'s class-level {@code @Transactional(rollbackFor = Exception.class)}
     * boundary: load the stale wizards, run the conditional bulk UPDATE
     * ({@code transitionIfStale}, which bumps the DB {@code version}), and — in the defective
     * variant — additionally mutate the still-managed entity. The commit happens when the method
     * returns, which is where production died.</p>
     */
    @Component
    static class ExpiryHarness {
        private final ClosingWizardRepository repository;

        ExpiryHarness(ClosingWizardRepository repository) {
            this.repository = repository;
        }

        /** The FIXED sequence: bulk UPDATE only, managed entity untouched. */
        @Transactional(rollbackFor = Exception.class)
        public int runExpiryInTransaction() {
            return expire(false);
        }

        /** The DEFECTIVE sequence shipped before this PR: bulk UPDATE + in-memory mutation. */
        @Transactional(rollbackFor = Exception.class)
        public int runExpiryWithManagedMutation() {
            return expire(true);
        }

        private int expire(boolean mutateManagedEntity) {
            LocalDateTime cutoff = LocalDateTime.now().minusMinutes(120);
            List<ClosingWizard> stale =
                    repository.findByWizardStatusAndStartedAtBefore(WizardStatus.IN_PROGRESS, cutoff);
            int count = 0;
            for (ClosingWizard wizard : stale) {
                int updated = repository.transitionIfStale(
                        wizard.getId(), WizardStatus.IN_PROGRESS, WizardStatus.EXPIRED, cutoff);
                if (updated == 0) {
                    continue;
                }
                if (mutateManagedEntity) {
                    wizard.setWizardStatus(WizardStatus.EXPIRED);
                }
                count++;
            }
            return count;
        }
    }

    @Test
    @DisplayName("FKH-061: no wizard left IN_PROGRESS past the threshold after a tick")
    void noStaleWizardSurvivesATick() {
        Branch branch = persistBranch();
        persistStaleWizard(branch);
        persistStaleWizard(branch);

        assertThatCode(() -> harness.runExpiryInTransaction()).doesNotThrowAnyException();

        List<String> remaining = jdbcTemplate.queryForList(
                "SELECT wizard_status FROM closing_wizard WHERE branch_id = ? AND wizard_status = 'IN_PROGRESS'",
                String.class, branch.getId());
        assertThat(remaining)
                .as("every stale wizard of this branch must be committed as EXPIRED")
                .isEmpty();
    }

    @Test
    @DisplayName("FKH-061 RED proof: mutating the managed entity after the bulk UPDATE loses the commit")
    void managedMutationBreaksTheCommit() {
        Branch branch = persistBranch();
        UUID wizardId = persistStaleWizard(branch);

        // The defective sequence: the bulk UPDATE bumps the DB version, then the dirty managed
        // entity is flushed at commit with the PRE-bulk version.
        Throwable thrown = org.assertj.core.api.Assertions.catchThrowable(
                () -> harness.runExpiryWithManagedMutation());

        String status = jdbcTemplate.queryForObject(
                "SELECT wizard_status FROM closing_wizard WHERE id = ?", String.class, wizardId);

        // Either the commit blows up, or (worse) it silently rolls the transition back. Both are
        // the production symptom: the log claims an expiry that the DB never received.
        assertThat(thrown != null || !"EXPIRED".equals(status))
                .as("the defective sequence must NOT produce a committed EXPIRED row")
                .isTrue();
    }
}
