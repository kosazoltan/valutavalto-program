package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.support.TransactionTemplate;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@EnableJpaAuditing
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff",
                "spring.jpa.hibernate.ddl-auto=create-drop",
                "spring.flyway.enabled=false",
                "spring.jpa.database-platform=org.hibernate.dialect.PostgreSQLDialect"
        })
class ShipmentRequestListIsolationPostgresIT {

    @Container
    static final PostgreSQLContainer<?> POSTGRES = new PostgreSQLContainer<>("postgres:16-alpine");

    @DynamicPropertySource
    static void postgresProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.datasource.driver-class-name", POSTGRES::getDriverClassName);
    }

    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private TransactionTemplate transactionTemplate;

    @Test
    @DisplayName("Minden védett shipment lista kizárja az A-from/B-to korrupt tenant-sort valós PostgreSQL-en")
    void protectedListsExcludeMixedTenantDestinationRow() {
        Seed seed = transactionTemplate.execute(status -> seedMixedTenantRows());
        assertThat(seed).isNotNull();
        assertThat(shipmentRequestRepository.findById(seed.corruptShipmentId())).isPresent();
        PageRequest firstPage = PageRequest.of(0, 20);

        assertContainsOnlyValid(shipmentRequestRepository.findByStatusAndCompanyId(
                ShipmentRequestStatus.SUBMITTED, seed.companyAId(), firstPage).getContent(), seed.validShipmentId());
        assertContainsOnlyValid(shipmentRequestRepository.findAllOrderedByCompanyId(
                seed.companyAId(), firstPage).getContent(), seed.validShipmentId());
        assertContainsOnlyValid(shipmentRequestRepository.findByBranchAndCompanyId(
                seed.fromBranchAId(), ShipmentRequestStatus.SUBMITTED,
                seed.companyAId(), firstPage).getContent(), seed.validShipmentId());
        assertContainsOnlyValid(shipmentRequestRepository.findScopedByCompanyId(
                Set.of(seed.fromBranchAId()), null, ShipmentRequestStatus.SUBMITTED,
                seed.companyAId(), firstPage).getContent(), seed.validShipmentId());
        assertContainsOnlyValid(shipmentRequestRepository.findPendingForToBranch(
                seed.companyAId(), seed.toBranchAId(), Set.of(ShipmentRequestStatus.SUBMITTED)),
                seed.validShipmentId());

        // A korrupt sor toBranchId-ja önmagában egyezik, de az idegen cél-branch tenant-klauzulája kizárja.
        assertThat(shipmentRequestRepository.findPendingForToBranch(
                seed.companyAId(), seed.foreignToBranchId(), Set.of(ShipmentRequestStatus.SUBMITTED)))
                .isEmpty();
    }

    private void assertContainsOnlyValid(List<ShipmentRequest> rows, UUID validShipmentId) {
        assertThat(rows).extracting(ShipmentRequest::getId).containsExactly(validShipmentId);
    }

    private Seed seedMixedTenantRows() {
        LocalDateTime now = LocalDateTime.now();
        String suffix = UUID.randomUUID().toString().substring(0, 8).toUpperCase();

        Company companyA = companyRepository.save(Company.builder()
                .code("LA-" + suffix)
                .name("Shipment List Company A")
                .createdAt(now)
                .build());
        Company companyB = companyRepository.save(Company.builder()
                .code("LB-" + suffix)
                .name("Shipment List Company B")
                .createdAt(now)
                .build());

        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE")
                .code("LT-" + suffix)
                .name("Shipment list branch type")
                .createdAt(now)
                .build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY")
                .code("LC-" + suffix)
                .name("Hungary")
                .createdAt(now)
                .build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS")
                .code("LS-" + suffix)
                .name("Active")
                .createdAt(now)
                .build());

        Branch fromBranchA = branchRepository.save(branch(
                "LF-" + suffix, "Company A source", companyA, branchType, country, branchStatus, now));
        Branch toBranchA = branchRepository.save(branch(
                "LV-" + suffix, "Company A destination", companyA, branchType, country, branchStatus, now));
        Branch foreignToBranch = branchRepository.save(branch(
                "LX-" + suffix, "Company B destination", companyB, branchType, country, branchStatus, now));

        ShipmentRequest valid = shipmentRequestRepository.saveAndFlush(shipment(
                "LIST-VALID-" + suffix, companyA.getId(), fromBranchA.getId(), toBranchA.getId(), now));
        ShipmentRequest corrupt = shipmentRequestRepository.saveAndFlush(shipment(
                "LIST-MIXED-" + suffix, companyA.getId(), fromBranchA.getId(), foreignToBranch.getId(), now.minusMinutes(1)));

        return new Seed(companyA.getId(), fromBranchA.getId(), toBranchA.getId(),
                foreignToBranch.getId(), valid.getId(), corrupt.getId());
    }

    private Branch branch(
            String code,
            String name,
            Company company,
            Dictionary branchType,
            Dictionary country,
            Dictionary branchStatus,
            LocalDateTime createdAt) {
        return Branch.builder()
                .code(code)
                .company(company)
                .bankCode("LISTPG")
                .branchType(branchType)
                .name(name)
                .address("Isolation Street 1")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .isVault(false)
                .openingDate(LocalDate.now())
                .createdAt(createdAt)
                .build();
    }

    private ShipmentRequest shipment(
            String requestNumber,
            UUID companyId,
            UUID fromBranchId,
            UUID toBranchId,
            LocalDateTime createdAt) {
        return ShipmentRequest.builder()
                .requestNumber(requestNumber)
                .companyId(companyId)
                .serialPrefix("LI")
                .serialNumber(System.nanoTime())
                .fromBranchId(fromBranchId)
                .toBranchId(toBranchId)
                .transferType("BRANCH_TO_BRANCH")
                .requestedById(1L)
                .status(ShipmentRequestStatus.SUBMITTED)
                .requestDate(LocalDate.now())
                .carrierName("Isolation Carrier")
                .sealNumber("LIST-" + UUID.randomUUID().toString().substring(0, 8))
                .createdAt(createdAt)
                .build();
    }

    private record Seed(
            UUID companyAId,
            UUID fromBranchAId,
            UUID toBranchAId,
            UUID foreignToBranchId,
            UUID validShipmentId,
            UUID corruptShipmentId) {
    }
}
