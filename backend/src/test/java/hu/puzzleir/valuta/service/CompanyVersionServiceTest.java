package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.CompanyVersion;
import hu.puzzleir.valuta.entity.DataChangeSource;
import hu.puzzleir.valuta.repository.CompanyVersionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CompanyVersionServiceTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Mock private CompanyVersionRepository companyVersionRepository;
    private CompanyVersionService service;

    @BeforeEach
    void setUp() {
        service = new CompanyVersionService(companyVersionRepository, new ObjectMapper());
    }

    private Company company() {
        return Company.builder()
                .id(COMPANY_ID)
                .code("BEST")
                .name("Best Change Zrt.")
                .taxNumber("12345678-2-42")
                .registrationNumber("01-10-123456")
                .address("Budapest")
                .phone("+361234567")
                .email("info@example.test")
                .isActive(true)
                .build();
    }

    @Test
    void recordVersion_firstVersion_isNo1_withSnapshotAndChangedBy() {
        when(companyVersionRepository.findTopByCompanyIdOrderByVersionNoDesc(COMPANY_ID))
                .thenReturn(Optional.empty());
        when(companyVersionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W007");

            CompanyVersion v = service.recordVersion(company(), DataChangeSource.COMPLIANCE);

            assertThat(v.getVersionNo()).isEqualTo(1L);
            assertThat(v.getCompanyId()).isEqualTo(COMPANY_ID);
            assertThat(v.getChangedBy()).isEqualTo("W007");
            assertThat(v.getSnapshot()).contains("\"name\":\"Best Change Zrt.\"")
                    .contains("\"taxNumber\":\"12345678-2-42\"");
        }
    }

    @Test
    void recordVersion_incrementsVersionNo() {
        when(companyVersionRepository.findTopByCompanyIdOrderByVersionNoDesc(COMPANY_ID))
                .thenReturn(Optional.of(CompanyVersion.builder().versionNo(5L).build()));
        when(companyVersionRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W007");

            CompanyVersion v = service.recordVersion(company(), DataChangeSource.COMPLIANCE);

            assertThat(v.getVersionNo()).isEqualTo(6L);
        }
    }

    @Test
    void hasDataChanged_emptyHistory_true() {
        when(companyVersionRepository.findTopByCompanyIdOrderByVersionNoDesc(COMPANY_ID))
                .thenReturn(Optional.empty());

        assertThat(service.hasDataChanged(company())).isTrue();
    }
}
