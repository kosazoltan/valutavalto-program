package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.RateApproval;
import hu.puzzleir.valuta.entity.RateApprovalStatus;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.RateApprovalRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Audit P0.2 fix (2026-05-17) cross-tenant izoláció verifikációja a RateApprovalService-en.
 *
 * Korábbi IDOR-finding (#631 audit): a {@code approveRateChange}, {@code rejectRateChange},
 * {@code getPendingApprovals}, {@code getApprovalHistory} metódusok nem ellenőrizték a
 * companyId-t — Company A cashier APPROVE-olhatott Company B árfolyam-változtatást, ill.
 * Company A user láthatta Company B PENDING approval-jait.
 *
 * Pattern: a {@code VaultStocktakeServiceTenantTest} mintáját követi.
 */
@ExtendWith(MockitoExtension.class)
class RateApprovalServiceTenantTest {

    private static final UUID COMPANY_A = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID COMPANY_B = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID APPROVAL_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");
    private static final UUID BRANCH_B_ID = UUID.fromString("44444444-4444-4444-4444-444444444444");

    @Mock private RateApprovalRepository rateApprovalRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private ExchangeRateService exchangeRateService;
    @Mock private CurrencyRepository currencyRepository;

    @InjectMocks private RateApprovalService rateApprovalService;

    @Test
    @DisplayName("approveRateChange — Company A user NEM approve-ol Company B approval-t")
    void approveRateChange_otherCompany_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            // A tenant-safe lookup empty-t ad vissza ha az ID másik cég branch-éhez tartozik
            when(rateApprovalRepository.findByIdAndBranch_Company_Id(APPROVAL_ID, COMPANY_A))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> rateApprovalService.approveRateChange(APPROVAL_ID, 1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Jóváhagyás");

            // Verify hogy a deprecated findById() NEM hívódott
            verify(rateApprovalRepository, never()).findById(APPROVAL_ID);
        }
    }

    @Test
    @DisplayName("rejectRateChange — Company A user NEM reject-el Company B approval-t")
    void rejectRateChange_otherCompany_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            when(rateApprovalRepository.findByIdAndBranch_Company_Id(APPROVAL_ID, COMPANY_A))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> rateApprovalService.rejectRateChange(APPROVAL_ID, "test"))
                    .isInstanceOf(ResourceNotFoundException.class);

            verify(rateApprovalRepository, never()).findById(APPROVAL_ID);
        }
    }

    @Test
    @DisplayName("getPendingApprovals — csak a saját cég approval-ait adja vissza")
    void getPendingApprovals_tenantFiltered() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            // A tenant-safe metódus üres listát ad vissza (Company A-nak nincs pending)
            when(rateApprovalRepository.findByStatusAndBranch_Company_IdOrderByRequestedAtDesc(
                    RateApprovalStatus.PENDING, COMPANY_A))
                    .thenReturn(java.util.Collections.emptyList());

            java.util.List<hu.puzzleir.valuta.dto.rateapproval.RateApprovalDto> result =
                    rateApprovalService.getPendingApprovals();

            assertThat(result).isEmpty();

            // Verify hogy a deprecated cross-tenant metódus NEM hívódott
            verify(rateApprovalRepository, never())
                    .findByStatusOrderByRequestedAtDesc(RateApprovalStatus.PENDING);
            // Verify hogy a tenant-safe variánst hívtuk
            verify(rateApprovalRepository).findByStatusAndBranch_Company_IdOrderByRequestedAtDesc(
                    RateApprovalStatus.PENDING, COMPANY_A);
        }
    }

    @Test
    @DisplayName("getApprovalHistory(null) — NEM findAll(), tenant-szűrt company history")
    void getApprovalHistory_nullBranchId_tenantFiltered() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            when(rateApprovalRepository.findByBranch_Company_IdOrderByRequestedAtDesc(COMPANY_A))
                    .thenReturn(java.util.Collections.emptyList());

            java.util.List<hu.puzzleir.valuta.dto.rateapproval.RateApprovalDto> result =
                    rateApprovalService.getApprovalHistory(null);

            assertThat(result).isEmpty();

            // KRITIKUS: a régi findAll() NEM hívódott — ez volt a total data leak
            verify(rateApprovalRepository, never()).findAll();
            verify(rateApprovalRepository, never()).findAll(org.mockito.ArgumentMatchers.any(org.springframework.data.domain.Sort.class));
            verify(rateApprovalRepository).findByBranch_Company_IdOrderByRequestedAtDesc(COMPANY_A);
        }
    }

    @Test
    @DisplayName("requestRateChange — Company A user NEM hozhat létre approval-t Company B branch-en")
    void requestRateChange_otherCompanyBranch_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);

            // Company B branch
            Company companyB = new Company();
            companyB.setId(COMPANY_B);
            Branch branchB = new Branch();
            branchB.setId(BRANCH_B_ID);
            branchB.setCode("B-OTHER");
            branchB.setCompany(companyB);

            when(branchRepository.findById(BRANCH_B_ID)).thenReturn(Optional.of(branchB));

            hu.puzzleir.valuta.dto.rateapproval.RequestRateChangeDto dto =
                    new hu.puzzleir.valuta.dto.rateapproval.RequestRateChangeDto();
            dto.setBranchId(BRANCH_B_ID);
            dto.setCurrencyCode("EUR");

            assertThatThrownBy(() -> rateApprovalService.requestRateChange(dto, 1L))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Iroda");

            // Verify hogy a save() NEM hívódott
            verify(rateApprovalRepository, never()).save(any(RateApproval.class));
        }
    }

}
