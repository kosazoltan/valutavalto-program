package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FK-098 FR-8 — the NEW vault-excluding branch query (handling-fee admin page data source).
 *
 * <p>H2 slice test (same template as CameraReviewTransactionLinkRepositoryTest): Flyway is
 * disabled in the test profile, therefore the test seeds its own master data.</p>
 *
 * <p>Coverage:</p>
 * <ul>
 *   <li>T-R1: the new method returns ONLY active, real cashier branches — vault,
 *       VAULT_COUNTERPARTY and inactive rows are excluded.</li>
 *   <li>T-R2: the OLD method is byte-identical — it still returns vaults (its 8 live
 *       consumers keep their semantics).</li>
 *   <li>T-R3: the new method stays company-scoped (a branch of another company is not
 *       returned). A defensive-null branchType row is impossible to seed
 *       (branch_type_did is NOT NULL) — hence the cross-tenant assertion instead.</li>
 * </ul>
 */
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
@ActiveProfiles("test")
@Transactional
class BranchRepositoryVaultExclusionFk098Test {

    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;

    @Test
    @DisplayName("FK-098 T-R1: FR-8 — az uj metodus pontosan az aktiv penztarat adja (vault, counterparty, inaktiv kizarva)")
    void newMethodReturnsOnlyActiveCashiers() {
        Fixture f = seed();

        List<Branch> result = branchRepository
                .findByCompanyIdAndIsActiveTrueExcludingCounterpartiesAndVaults(f.company1.getId());

        assertThat(result).extracting(Branch::getCode).containsExactly("FK098CASHIER");
    }

    @Test
    @DisplayName("FK-098 T-R2: FR-8 — a regi metodus ERINTETLEN: a vaultot tovabbra is visszahozza (8 fogyasztó szemantikaja)")
    void oldMethodStillReturnsVaults() {
        Fixture f = seed();

        List<Branch> result = branchRepository
                .findByCompanyIdAndIsActiveTrueExcludingCounterparties(f.company1.getId());

        assertThat(result).extracting(Branch::getCode).containsExactlyInAnyOrder("FK098CASHIER", "FK098VAULT");
    }

    @Test
    @DisplayName("FK-098 T-R3: FR-8 — az uj metodus ceg-szuru: masik cég fiókja nem jelenik meg")
    void newMethodIsCompanyScoped() {
        Fixture f = seed();

        List<Branch> result = branchRepository
                .findByCompanyIdAndIsActiveTrueExcludingCounterpartiesAndVaults(f.company1.getId());

        assertThat(result).extracting(Branch::getCode).doesNotContain("FK098OTHER");
    }

    // ============================ SEED ============================

    private record Fixture(Company company1, Company company2) {}

    private Fixture seed() {
        LocalDateTime now = LocalDateTime.of(2026, 8, 28, 8, 0);
        Company company1 = companyRepository.save(Company.builder()
                .code("FK098C1").name("FK-098 Company 1").createdAt(now).build());
        Company company2 = companyRepository.save(Company.builder()
                .code("FK098C2").name("FK-098 Company 2").createdAt(now).build());

        Dictionary penztar = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE").code("PENZTAR").name("Penztar").createdAt(now).build());
        Dictionary vaultCounterparty = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE").code("VAULT_COUNTERPARTY").name("Vault counterparty")
                .createdAt(now).build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY").code("HU").name("Hungary").createdAt(now).build());
        Dictionary activeStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS").code("ACTIVE").name("Active").createdAt(now).build());

        branchRepository.save(branch("FK098CASHIER", "FK-098 penztar", company1, penztar,
                country, activeStatus, false, true));
        branchRepository.save(branch("FK098VAULT", "FK-098 ertektar", company1, penztar,
                country, activeStatus, true, true));
        branchRepository.save(branch("FK098PARTNER", "FK-098 bankpartner", company1, vaultCounterparty,
                country, activeStatus, false, true));
        branchRepository.save(branch("FK098CLOSED", "FK-098 zarva", company1, penztar,
                country, activeStatus, false, false));
        branchRepository.save(branch("FK098OTHER", "FK-098 masik ceg", company2, penztar,
                country, activeStatus, false, true));
        branchRepository.flush();

        return new Fixture(company1, company2);
    }

    private Branch branch(String code, String name, Company company, Dictionary branchType,
                          Dictionary country, Dictionary branchStatus,
                          boolean isVault, boolean isActive) {
        return Branch.builder()
                .code(code)
                .name(name)
                .company(company)
                .bankCode(code)
                .branchType(branchType)
                .address("FK-098 teszt utca 1.")
                .city("Szeged")
                .zipCode("6720")
                .country(country)
                .branchStatus(branchStatus)
                .openingDate(LocalDate.of(2026, 1, 1))
                .isVault(isVault)
                .isActive(isActive)
                .createdAt(LocalDateTime.of(2026, 8, 28, 8, 0))
                .build();
    }
}
