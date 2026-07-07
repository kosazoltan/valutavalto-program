package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.customer.CustomerDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.CustomerVersion;
import hu.puzzleir.valuta.entity.DataChangeSource;
import hu.puzzleir.valuta.mapper.CustomerMapper;
import hu.puzzleir.valuta.repository.CustomerVersionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CustomerVersionServiceTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Mock private CustomerVersionRepository customerVersionRepository;
    private ObjectMapper objectMapper;
    private CustomerVersionService service;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        service = new CustomerVersionService(
                customerVersionRepository, new CustomerMapper(), objectMapper);
    }

    private Customer customer() {
        return Customer.builder()
                .id(42L)
                .customerCode("C000042")
                .name("Teszt Elek")
                .documentNumber("AB123456")
                .company(Company.builder().id(COMPANY_ID).build())
                .build();
    }

    @Test
    void recordVersion_firstVersion_isNo1_withSnapshotAndTenant() {
        when(customerVersionRepository.findTopByCustomerIdOrderByVersionNoDesc(42L))
                .thenReturn(Optional.empty());
        when(customerVersionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W007");

            CustomerVersion v = service.recordVersion(customer(), DataChangeSource.CASHIER);

            assertThat(v.getVersionNo()).isEqualTo(1L);
            assertThat(v.getCompanyId()).isEqualTo(COMPANY_ID);
            assertThat(v.getChangedBy()).isEqualTo("W007");
            assertThat(v.getChangeSource()).isEqualTo(DataChangeSource.CASHIER);
            assertThat(v.getSnapshot()).contains("\"name\":\"Teszt Elek\"")
                    .contains("\"documentNumber\":\"AB123456\"");
        }
    }

    @Test
    void recordVersion_incrementsVersionNo() {
        when(customerVersionRepository.findTopByCustomerIdOrderByVersionNoDesc(42L))
                .thenReturn(Optional.of(CustomerVersion.builder().versionNo(3L).build()));
        when(customerVersionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W007");

            CustomerVersion v = service.recordVersion(customer(), DataChangeSource.COMPLIANCE);

            assertThat(v.getVersionNo()).isEqualTo(4L);
            assertThat(v.getChangeSource()).isEqualTo(DataChangeSource.COMPLIANCE);
        }
    }

    @Test
    void hasDataChanged_emptyHistory_true() {
        when(customerVersionRepository.findTopByCustomerIdOrderByVersionNoDesc(42L))
                .thenReturn(Optional.empty());

        assertThat(service.hasDataChanged(customer())).isTrue();
    }

    @Test
    void hasDataChanged_identicalData_false_evenIfVolatileFieldsDiffer() {
        Customer baseline = customer();
        CustomerDto dto = new CustomerMapper().toDto(baseline);
        dto.setUpdatedAt(LocalDateTime.of(2026, 7, 1, 10, 0));
        dto.setCreatedAt(LocalDateTime.of(2026, 6, 1, 9, 0));
        dto.setTransactionCount(99);
        dto.setReviewStatus(hu.puzzleir.valuta.entity.ReviewStatus.PENDING_REVIEW);
        dto.setReviewedBy("WOLD");
        dto.setReviewedAt(LocalDateTime.of(2026, 7, 1, 11, 0));

        when(customerVersionRepository.findTopByCustomerIdOrderByVersionNoDesc(42L))
                .thenReturn(Optional.of(CustomerVersion.builder()
                        .versionNo(1L)
                        .snapshot(objectMapper.writeValueAsString(dto))
                        .build()));

        assertThat(service.hasDataChanged(baseline)).isFalse();
    }

    @Test
    void hasDataChanged_nameDiffers_true() {
        Customer previous = customer();
        CustomerDto dto = new CustomerMapper().toDto(previous);
        when(customerVersionRepository.findTopByCustomerIdOrderByVersionNoDesc(42L))
                .thenReturn(Optional.of(CustomerVersion.builder()
                        .versionNo(1L)
                        .snapshot(objectMapper.writeValueAsString(dto))
                        .build()));

        Customer current = customer();
        current.setName("Más Név");

        assertThat(service.hasDataChanged(current)).isTrue();
    }

    @Test
    void currentChangeSource_complianceRoles_mapToCompliance() {
        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::isComplianceSide).thenReturn(true);
            assertThat(service.currentChangeSource()).isEqualTo(DataChangeSource.COMPLIANCE);

            sec.when(SecurityUtils::isComplianceSide).thenReturn(false);
            assertThat(service.currentChangeSource()).isEqualTo(DataChangeSource.CASHIER);
        }
    }
}
