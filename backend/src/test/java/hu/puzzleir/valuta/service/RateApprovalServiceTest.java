package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.rateapproval.RateApprovalDto;
import hu.puzzleir.valuta.dto.rateapproval.RequestRateChangeDto;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.RateApproval;
import hu.puzzleir.valuta.entity.RateApprovalStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.RateApprovalRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * RateApprovalService UNIT tesztek — Mockito.
 *
 * Árfolyam változtatás kérelem, jóváhagyás és elutasítás.
 *
 * Audit P0.2 fix (2026-05-17): a teszteket adaptáltuk a tenant-safe
 * service-implementációhoz — SecurityUtils.getCurrentCompanyId() mockStatic
 * + Branch.company mezőt kitöltjük, repo mockok a tenant-safe metódusokat
 * használják.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RateApprovalServiceTest {

    @InjectMocks
    private RateApprovalService service;

    @Mock
    private RateApprovalRepository rateApprovalRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private WorkerRepository workerRepository;

    @Mock
    private ExchangeRateService exchangeRateService;

    @Mock
    private CurrencyRepository currencyRepository;

    private static final UUID COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private final UUID BRANCH_ID = UUID.randomUUID();
    private final Long WORKER_ID = 1L;

    /**
     * Segéd: Branch mock létrehozás (a Company is be van állítva — audit P0.2).
     */
    private Branch createMockBranch() {
        Company company = new Company();
        company.setId(COMPANY_ID);
        company.setName("Test Cég");
        Branch branch = Branch.builder()
                .id(BRANCH_ID)
                .code("BP01")
                .name("Budapest Pénztár")
                .company(company)
                .build();
        return branch;
    }

    /**
     * Segéd: Worker mock létrehozás.
     */
    private Worker createMockWorker(Long id, String name) {
        return Worker.builder()
                .id(id)
                .name(name)
                .build();
    }

    // =====================================================================
    // Árfolyam változtatás kérelem: sikeres
    // =====================================================================
    @Test
    @DisplayName("Árfolyam változtatási kérelem: sikeres létrehozás")
    void testRequestRateChange_success() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // Arrange
            Branch branch = createMockBranch();
            Worker requester = createMockWorker(WORKER_ID, "Kiss Péter");

            RequestRateChangeDto dto = RequestRateChangeDto.builder()
                    .branchId(BRANCH_ID)
                    .currencyCode("EUR")
                    .newBuyRate(new BigDecimal("400.50"))
                    .newSellRate(new BigDecimal("405.00"))
                    .reason("Piaci trend változás")
                    .build();

            when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
            when(workerRepository.findById(WORKER_ID)).thenReturn(Optional.of(requester));
            when(rateApprovalRepository.save(any(RateApproval.class)))
                    .thenAnswer(inv -> {
                        RateApproval saved = inv.getArgument(0);
                        saved.setId(UUID.randomUUID());
                        return saved;
                    });

            // Act
            RateApprovalDto result = service.requestRateChange(dto, WORKER_ID);

            // Assert
            assertThat(result).isNotNull();
            assertThat(result.getCurrencyCode()).isEqualTo("EUR");
            assertThat(result.getNewBuyRate()).isEqualByComparingTo(new BigDecimal("400.50"));
            assertThat(result.getNewSellRate()).isEqualByComparingTo(new BigDecimal("405.00"));
            assertThat(result.getStatus()).isEqualTo("PENDING");
            assertThat(result.getBranchName()).isEqualTo("Budapest Pénztár");
        }
    }

    // =====================================================================
    // Jóváhagyás: sikeres
    // =====================================================================
    @Test
    @DisplayName("Árfolyam jóváhagyás: PENDING → APPROVED sikeres")
    void testApprove_success() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // Arrange
            UUID approvalId = UUID.randomUUID();
            Branch branch = createMockBranch();
            Worker approver = createMockWorker(2L, "Nagy Anna");

            RateApproval approval = RateApproval.builder()
                    .id(approvalId)
                    .branch(branch)
                    .currencyCode("USD")
                    .newBuyRate(new BigDecimal("380.00"))
                    .newSellRate(new BigDecimal("385.00"))
                    .status(RateApprovalStatus.PENDING)
                    .build();

            // Audit P0.2: tenant-safe lookup
            when(rateApprovalRepository.findByIdAndBranch_Company_Id(approvalId, COMPANY_ID))
                    .thenReturn(Optional.of(approval));
            when(workerRepository.findById(2L)).thenReturn(Optional.of(approver));
            when(rateApprovalRepository.save(any(RateApproval.class)))
                    .thenAnswer(inv -> inv.getArgument(0));
            Currency usd = new Currency();
            usd.setId(2L);
            usd.setCode("USD");
            when(currencyRepository.findByCode("USD")).thenReturn(Optional.of(usd));

            // Act
            RateApprovalDto result = service.approveRateChange(approvalId, 2L);

            // Assert
            assertThat(result.getStatus()).isEqualTo("APPROVED");
            assertThat(result.getApprovedByName()).isEqualTo("Nagy Anna");
            assertThat(result.getApprovedAt()).isNotNull();
        }
    }

    // =====================================================================
    // Jóváhagyás: nem PENDING → hiba
    // =====================================================================
    @Test
    @DisplayName("Jóváhagyás: már APPROVED státusz → ValidationException")
    void testApprove_notPending_throws() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // Arrange — már jóváhagyott kérelem
            UUID approvalId = UUID.randomUUID();
            Branch branch = createMockBranch();
            RateApproval approval = RateApproval.builder()
                    .id(approvalId)
                    .branch(branch)
                    .status(RateApprovalStatus.APPROVED)
                    .build();

            // Audit P0.2: tenant-safe lookup
            when(rateApprovalRepository.findByIdAndBranch_Company_Id(approvalId, COMPANY_ID))
                    .thenReturn(Optional.of(approval));

            // Act & Assert
            assertThatThrownBy(() -> service.approveRateChange(approvalId, WORKER_ID))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("Csak PENDING státuszú");
        }
    }

    // =====================================================================
    // Elutasítás: indoklással
    // =====================================================================
    @Test
    @DisplayName("Elutasítás: PENDING → REJECTED indoklással")
    void testReject_withReason() {
        try (MockedStatic<SecurityUtils> secUtils = mockStatic(SecurityUtils.class)) {
            secUtils.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            // Arrange
            UUID approvalId = UUID.randomUUID();
            Branch branch = createMockBranch();
            RateApproval approval = RateApproval.builder()
                    .id(approvalId)
                    .branch(branch)
                    .currencyCode("GBP")
                    .status(RateApprovalStatus.PENDING)
                    .build();

            // Audit P0.2: tenant-safe lookup
            when(rateApprovalRepository.findByIdAndBranch_Company_Id(approvalId, COMPANY_ID))
                    .thenReturn(Optional.of(approval));
            when(rateApprovalRepository.save(any(RateApproval.class)))
                    .thenAnswer(inv -> inv.getArgument(0));

            // Act
            RateApprovalDto result = service.rejectRateChange(approvalId, "Túl nagy eltérés a piaci árfolyamtól");

            // Assert
            assertThat(result.getStatus()).isEqualTo("REJECTED");
            assertThat(result.getReason()).contains("ELUTASÍTVA:");
            assertThat(result.getReason()).contains("Túl nagy eltérés a piaci árfolyamtól");
        }
    }
}
