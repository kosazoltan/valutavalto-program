package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.TestApplication;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Dictionary;
import hu.puzzleir.valuta.entity.ShipmentHandlingFee;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestItem;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * FKH-036 WU-5 — a két új mozgás-lekérdezés JPQL-validálása ÉS az üzleti-dátum
 * dimenzió (B2) igazolása valódi EntityManager ellen (pitfall 4: az ad-hoc
 * {@code JOIN Currency c ON c.id = i.currencyId} szintaxis csak itt parse-olódik).
 *
 * <p>A tenant-seed a {@code CameraReviewTransactionLinkRepositoryTest.seedTenant}
 * bevált mintáját követi (Dictionary-alapú Branch-kényszerek).</p>
 */
@SpringBootTest(
        classes = TestApplication.class,
        properties = {
                "app.encryption.key=test-only-local-encryption-key-32chars",
                "app.encryption.salt=00112233445566778899aabbccddeeff"
        })
@ActiveProfiles("test")
@Transactional
class ShipmentMovementFkh036RepositoryTest {

    @Autowired private ShipmentRequestRepository shipmentRequestRepository;
    @Autowired private ShipmentHandlingFeeRepository feeRepository;
    @Autowired private CurrencyRepository currencyRepository;
    @Autowired private BranchRepository branchRepository;
    @Autowired private CompanyRepository companyRepository;
    @Autowired private DictionaryRepository dictionaryRepository;

    private record Tenant(Company company, Branch branch, Branch otherBranch) {}

    private Tenant seedTenant(String label) {
        String suffix = Long.toString(Math.abs(UUID.randomUUID().getLeastSignificantBits()), 36)
                .toUpperCase();
        LocalDateTime now = LocalDateTime.of(2026, 8, 17, 8, 0);
        Company company = companyRepository.save(Company.builder()
                .code(shortCode("FK36C", suffix))
                .name("FKH036 " + label + " " + suffix)
                .createdAt(now)
                .build());
        Dictionary branchType = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_TYPE").code(shortCode("BT", suffix))
                .name("FKH036 branch type").createdAt(now).build());
        Dictionary country = dictionaryRepository.save(Dictionary.builder()
                .category("COUNTRY").code(shortCode("CO", suffix))
                .name("Hungary").createdAt(now).build());
        Dictionary branchStatus = dictionaryRepository.save(Dictionary.builder()
                .category("BRANCH_STATUS").code(shortCode("BS", suffix))
                .name("Active").createdAt(now).build());
        Branch branch = branchRepository.save(branch(shortCode("B1", suffix), company,
                branchType, country, branchStatus, now));
        Branch otherBranch = branchRepository.save(branch(shortCode("B2", suffix), company,
                branchType, country, branchStatus, now));
        return new Tenant(company, branch, otherBranch);
    }

    private Branch branch(String code, Company company, Dictionary branchType,
                          Dictionary country, Dictionary branchStatus, LocalDateTime now) {
        return Branch.builder()
                .code(code)
                .company(company)
                .bankCode("FK36BANK")
                .branchType(branchType)
                .name("FKH036 branch " + code)
                .address("Teszt utca 1.")
                .city("Budapest")
                .zipCode("1000")
                .country(country)
                .branchStatus(branchStatus)
                .openingDate(LocalDate.of(2026, 1, 1))
                .createdAt(now)
                .build();
    }

    private Currency persistedCurrency(String code) {
        // A code oszlop VARCHAR(3) — pontosan 3 karakteres teszt-kódok.
        // A TestApplication nem kapcsolja be a JPA auditingot — created_at kézzel.
        return currencyRepository.save(Currency.builder()
                .code(code)
                .name(code + " test")
                .displayOrder(1)
                .createdAt(LocalDateTime.of(2026, 8, 17, 8, 0))
                .build());
    }

    private ShipmentRequest persistedRequest(Company company, Branch from, Branch to,
                                             String prefix, LocalDate requestDate,
                                             ShipmentRequestStatus status, Long currencyId) {
        ShipmentRequest request = ShipmentRequest.builder()
                .requestNumber(prefix + "-FKH036-"
                        + Math.abs(UUID.randomUUID().getLeastSignificantBits() % 100000))
                .companyId(company.getId())
                .serialPrefix(prefix)
                .serialNumber(1L)
                .fromBranchId(from.getId())
                .toBranchId(to.getId())
                .status(status)
                .requestDate(requestDate)
                .createdAt(requestDate.atTime(8, 0))
                .carrierName("FKH036 Test Carrier")
                .sealNumber("SEAL-FKH036-"
                        + Math.abs(UUID.randomUUID().getLeastSignificantBits() % 10000))
                .requestedById(1L)
                .build();
        ShipmentRequestItem item = ShipmentRequestItem.builder()
                .currencyId(currencyId)
                .requestedAmount(new BigDecimal("5000"))
                .appliedRate(new BigDecimal("400"))
                .hufValue(new BigDecimal("2000000"))
                .build();
        request.addItem(item);
        return shipmentRequestRepository.saveAndFlush(request);
    }

    private static String shortCode(String prefix, String suffix) {
        String normalized = (prefix + suffix).replaceAll("[^A-Z0-9]", "");
        return normalized.substring(0, Math.min(20, normalized.length()));
    }

    @Test
    @DisplayName("B2: éjfélt átlépő KK díj az üzleti dátumon (requestDate) számít, nem a createdAt szerint")
    void crossMidnight_feeAnchoredOnParentRequestDate() {
        Tenant tenant = seedTenant("Midnight");
        LocalDate d = LocalDate.of(2026, 8, 17);

        // KK kérés requestDate = D, státusz SUBMITTED.
        ShipmentRequest kkRequest = shipmentRequestRepository.save(ShipmentRequest.builder()
                .requestNumber("KK-FKH036-M1")
                .companyId(tenant.company().getId())
                .serialPrefix("KK")
                .serialNumber(1L)
                .fromBranchId(tenant.branch().getId())
                .toBranchId(tenant.branch().getId())
                .status(ShipmentRequestStatus.SUBMITTED)
                .requestDate(d)
                .createdAt(d.atTime(23, 50))
                .carrierName("FKH036 Test Carrier")
                .sealNumber("SEAL-FKH036-M1")
                .requestedById(1L)
                .build());
        // A díjsor audit-időbélyege D+1 00:30 — az éjfél-keresztezési eset.
        feeRepository.save(ShipmentHandlingFee.builder()
                .companyId(tenant.company().getId())
                .shipmentRequestId(kkRequest.getId())
                .sourceBranchId(tenant.branch().getId())
                .hufAmount(new BigDecimal("100000"))
                .calculatedFee(new BigDecimal("500"))
                .status(ShipmentRequestStatus.SUBMITTED)
                .createdAt(d.plusDays(1).atTime(0, 30))
                .build());

        // Az üzleti dátum nyer: D-re TRUE, D+1-re FALSE.
        assertThat(feeRepository.existsDailyMovementForSourceBranch(
                tenant.company().getId(), tenant.branch().getId(), d)).isTrue();
        assertThat(feeRepository.existsDailyMovementForSourceBranch(
                tenant.company().getId(), tenant.branch().getId(), d.plusDays(1))).isFalse();
    }

    @Test
    @DisplayName("findMovedCurrencyCodesForDate: FF/UF mozgás valutái, státusz-whitelisttel, cross-tenant kizárva")
    void movedCurrencies_parsedAndTenantScoped() {
        Tenant tenant = seedTenant("Move");
        Tenant otherTenant = seedTenant("Other");
        LocalDate d = LocalDate.of(2026, 8, 17);

        Currency eur = persistedCurrency("EUX");
        Currency usd = persistedCurrency("USX");
        Currency gbp = persistedCurrency("GBX");
        Currency xTenant = persistedCurrency("CHX");

        // FF kimenő EUR — számít (fromBranchId = kérő branch).
        persistedRequest(tenant.company(), tenant.branch(), tenant.otherBranch(),
                "FF", d, ShipmentRequestStatus.SUBMITTED, eur.getId());
        // UF bejövő USD — számít (toBranchId = kérő branch; mindkét irány mozgás).
        persistedRequest(tenant.company(), tenant.otherBranch(), tenant.branch(),
                "UF", d, ShipmentRequestStatus.DELIVERED, usd.getId());
        // DRAFT GBP — NEM számít (soha nem mozgott pénz).
        persistedRequest(tenant.company(), tenant.branch(), tenant.otherBranch(),
                "FF", d, ShipmentRequestStatus.DRAFT, gbp.getId());
        // CROSS-TENANT FF CHF — NEM szabad visszatérnie.
        persistedRequest(otherTenant.company(), otherTenant.branch(), otherTenant.otherBranch(),
                "FF", d, ShipmentRequestStatus.SUBMITTED, xTenant.getId());

        List<String> codes = shipmentRequestRepository.findMovedCurrencyCodesForDate(
                tenant.company().getId(), tenant.branch().getId(), d,
                ShipmentHandlingFeeRepository.KPI_COUNTED_STATUSES);

        assertThat(codes).containsExactlyInAnyOrder(eur.getCode(), usd.getCode());
    }

    @Test
    @DisplayName("findOutgoingPackageRowsForDate: FF sorok vetülete parse-ol és tenant-szűrt")
    void outgoingPackageRows_parsedAndTenantScoped() {
        Tenant tenant = seedTenant("Pack");
        LocalDate d = LocalDate.of(2026, 8, 17);
        Currency eur = persistedCurrency("EUX");

        ShipmentRequest ff = persistedRequest(tenant.company(), tenant.branch(), tenant.otherBranch(),
                "FF", d, ShipmentRequestStatus.APPROVED, eur.getId());
        ff.setSealNumber("PL-FKH036");
        shipmentRequestRepository.saveAndFlush(ff);

        List<Object[]> rows = shipmentRequestRepository.findOutgoingPackageRowsForDate(
                tenant.company().getId(), tenant.branch().getId(), d,
                ShipmentHandlingFeeRepository.KPI_COUNTED_STATUSES);

        assertThat(rows).hasSize(1);
        Object[] row = rows.get(0);
        assertThat(row[0]).isEqualTo(ff.getRequestNumber());
        assertThat(row[1]).isEqualTo(eur.getCode());
        assertThat((BigDecimal) row[2]).isEqualByComparingTo("5000");
        assertThat(row[3]).isEqualTo("PL-FKH036");
        assertThat(row[4]).isEqualTo(tenant.otherBranch().getName());

        // Cross-tenant: másik cég ugyanerre a dátumra üres.
        assertThat(shipmentRequestRepository.findOutgoingPackageRowsForDate(
                UUID.randomUUID(), tenant.branch().getId(), d,
                ShipmentHandlingFeeRepository.KPI_COUNTED_STATUSES)).isEmpty();
    }
}
