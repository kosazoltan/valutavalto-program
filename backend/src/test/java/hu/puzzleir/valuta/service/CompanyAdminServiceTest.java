package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.admin.CompanyUpdateDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DataChangeSource;
import hu.puzzleir.valuta.entity.ReviewStatus;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.SyncLogRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CompanyAdminServiceTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();

    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private SyncLogRepository syncLogRepository;
    @Mock private CompanyVersionService companyVersionService;
    @InjectMocks private CompanyAdminService service;

    private Company company() {
        return Company.builder()
                .id(COMPANY_ID)
                .code("BEST")
                .name("Régi név")
                .taxNumber("12345678-2-42")
                .registrationNumber("01-10-123456")
                .reviewStatus(ReviewStatus.REVIEWED)
                .build();
    }

    @Test
    void updateCompany_changedData_autoReviewedAndRecordsComplianceVersion() {
        Company company = company();
        CompanyUpdateDto dto = CompanyUpdateDto.builder().name("Új név").build();
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(companyVersionService.hasDataChanged(company)).thenReturn(true);
        when(companyRepository.save(company)).thenReturn(company);

        try (MockedStatic<SecurityUtils> sec = mockStatic(SecurityUtils.class)) {
            sec.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W1");
            sec.when(SecurityUtils::isComplianceSide).thenReturn(true);

            Company result = service.updateCompany(COMPANY_ID, dto);

            assertThat(result.getName()).isEqualTo("Új név");
            assertThat(result.getReviewStatus()).isEqualTo(ReviewStatus.REVIEWED);
            assertThat(result.getReviewedBy()).isEqualTo("W1");
            assertThat(result.getReviewedAt()).isNotNull();
            verify(companyVersionService).recordVersion(result, DataChangeSource.COMPLIANCE);
        }
    }

    @Test
    void updateCompany_noDataChange_doesNotRecordVersion() {
        Company company = company();
        CompanyUpdateDto dto = CompanyUpdateDto.builder().name("Régi név").build();
        when(companyRepository.findById(COMPANY_ID)).thenReturn(Optional.of(company));
        when(companyVersionService.hasDataChanged(company)).thenReturn(false);
        when(companyRepository.save(company)).thenReturn(company);

        Company result = service.updateCompany(COMPANY_ID, dto);

        assertThat(result.getReviewStatus()).isEqualTo(ReviewStatus.REVIEWED);
        verify(companyVersionService, never()).recordVersion(any(), any());
    }
}
