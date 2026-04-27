package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CircularSequenceRepository;
import hu.puzzleir.valuta.repository.ReceiptSequenceRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Collections;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;

/**
 * F1 fix-batch (Eszter audit) unit-tesztek a {@link YearOpeningService} explicit-companyId
 * overload-jahoz.
 *
 * Eszter P0 finding (audit-pipeline-eszter-tamas-3p0-3p1): a YearOpeningScheduler
 * AnonymousAuthenticationToken-bol nem tudott companyId-t adni a service-nek, ezert
 * az automata evnyitas januar 1-en bukni fogott. A javitas: explicit companyId parameter
 * overload, amit a scheduler hasznal.
 */
@ExtendWith(MockitoExtension.class)
class YearOpeningServiceTenantTest {

    private static final UUID COMPANY_A = UUID.fromString("11111111-1111-1111-1111-111111111111");

    @Mock
    private CircularSequenceRepository circularSequenceRepository;
    @Mock
    private ReceiptSequenceRepository receiptSequenceRepository;
    @Mock
    private BranchRepository branchRepository;
    @Mock
    private DailyClosingArchiveService dailyClosingArchiveService;
    @Mock
    private CircularService circularService;
    @Mock
    private AuditLogService auditLogService;

    @InjectMocks
    private YearOpeningService service;

    @Test
    @DisplayName("executeYearOpening(year, companyId, operator) explicit parameterekkel fut, nem hivja SecurityUtils-t")
    void executeYearOpening_explicitCompanyId_doesNotRequireSecurityContext() {
        int targetYear = LocalDate.now().getYear();
        when(branchRepository.findByCompanyId(COMPANY_A)).thenReturn(Collections.emptyList());
        when(circularSequenceRepository.findByCompanyId(COMPANY_A)).thenReturn(Collections.emptyList());
        when(circularService.archiveByYear(COMPANY_A, targetYear - 1)).thenReturn(0);
        when(auditLogService.existsByActionAndReference(anyString(), anyString())).thenReturn(false);

        // ELVARAS: SecurityContext nem letezik (scheduler kontextus), de a metodus mukodik.
        Map<String, Object> result = service.executeYearOpening(targetYear, COMPANY_A, "SYSTEM_SCHEDULER");

        assertThat(result).containsEntry("status", "SUCCESS");
        assertThat(result).containsEntry("operator", "SYSTEM_SCHEDULER");
        assertThat(result).containsEntry("targetYear", targetYear);
    }

    @Test
    @DisplayName("executeYearOpening idempotencia kulcsa <companyId>:<year> formatumu (NEM csak <year>)")
    void executeYearOpening_idempotencyKey_isCompanyScoped() {
        int targetYear = LocalDate.now().getYear();
        String expectedKey = COMPANY_A + ":" + targetYear;
        when(auditLogService.existsByActionAndReference("YEAR_OPENING", expectedKey)).thenReturn(true);

        // ELVARAS: ha a kulcs <companyId>:<year> formatumban mar van auditlog, IllegalStateException-t dobunk.
        assertThatThrownBy(() -> service.executeYearOpening(targetYear, COMPANY_A, "MANUAL"))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining(targetYear + "")
                .hasMessageContaining(COMPANY_A.toString());
    }

    @Test
    @DisplayName("executeYearOpening kulonbozo company-kre fuggetlen (NEM blokkol egy globalisan)")
    void executeYearOpening_oneCompanySkip_doesNotBlockOtherCompany() {
        int targetYear = LocalDate.now().getYear();
        UUID companyB = UUID.fromString("22222222-2222-2222-2222-222222222222");

        // CompanyA mar futott, CompanyB meg nem
        when(auditLogService.existsByActionAndReference("YEAR_OPENING", COMPANY_A + ":" + targetYear)).thenReturn(true);
        when(auditLogService.existsByActionAndReference("YEAR_OPENING", companyB + ":" + targetYear)).thenReturn(false);
        when(branchRepository.findByCompanyId(companyB)).thenReturn(Collections.emptyList());
        when(circularSequenceRepository.findByCompanyId(companyB)).thenReturn(Collections.emptyList());
        when(circularService.archiveByYear(companyB, targetYear - 1)).thenReturn(0);

        assertThatThrownBy(() -> service.executeYearOpening(targetYear, COMPANY_A, "SCHEDULER"))
                .isInstanceOf(IllegalStateException.class);

        Map<String, Object> resultB = service.executeYearOpening(targetYear, companyB, "SCHEDULER");
        assertThat(resultB).containsEntry("status", "SUCCESS");
    }

    @Test
    @DisplayName("executeYearOpening explicit companyId=null -> IllegalArgumentException")
    void executeYearOpening_nullCompanyId_throwsIllegalArgument() {
        assertThatThrownBy(() -> service.executeYearOpening(LocalDate.now().getYear(), null, "X"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("companyId nem lehet null");
    }
}
