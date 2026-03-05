package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.rateapproval.RateApprovalDto;
import hu.puzzleir.valuta.dto.rateapproval.RequestRateChangeDto;
import hu.puzzleir.valuta.entity.RateApproval;
import hu.puzzleir.valuta.entity.RateApprovalStatus;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.RateApprovalRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;

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
 */
@ExtendWith(MockitoExtension.class)
class RateApprovalServiceTest {

    @InjectMocks
    private RateApprovalService service;

    @Mock
    private RateApprovalRepository rateApprovalRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private WorkerRepository workerRepository;

    private final UUID BRANCH_ID = UUID.randomUUID();
    private final Long WORKER_ID = 1L;

    /**
     * Segéd: Branch mock létrehozás.
     */
    private Branch createMockBranch() {
        Branch branch = Branch.builder()
                .id(BRANCH_ID)
                .code("BP01")
                .name("Budapest Pénztár")
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

    // =====================================================================
    // Jóváhagyás: sikeres
    // =====================================================================
    @Test
    @DisplayName("Árfolyam jóváhagyás: PENDING → APPROVED sikeres")
    void testApprove_success() {
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

        when(rateApprovalRepository.findById(approvalId)).thenReturn(Optional.of(approval));
        when(workerRepository.findById(2L)).thenReturn(Optional.of(approver));
        when(rateApprovalRepository.save(any(RateApproval.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        // Act
        RateApprovalDto result = service.approveRateChange(approvalId, 2L);

        // Assert
        assertThat(result.getStatus()).isEqualTo("APPROVED");
        assertThat(result.getApprovedByName()).isEqualTo("Nagy Anna");
        assertThat(result.getApprovedAt()).isNotNull();
    }

    // =====================================================================
    // Jóváhagyás: nem PENDING → hiba
    // =====================================================================
    @Test
    @DisplayName("Jóváhagyás: már APPROVED státusz → ValidationException")
    void testApprove_notPending_throws() {
        // Arrange — már jóváhagyott kérelem
        UUID approvalId = UUID.randomUUID();
        RateApproval approval = RateApproval.builder()
                .id(approvalId)
                .status(RateApprovalStatus.APPROVED)
                .build();

        when(rateApprovalRepository.findById(approvalId)).thenReturn(Optional.of(approval));

        // Act & Assert
        assertThatThrownBy(() -> service.approveRateChange(approvalId, WORKER_ID))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("Csak PENDING státuszú");
    }

    // =====================================================================
    // Elutasítás: indoklással
    // =====================================================================
    @Test
    @DisplayName("Elutasítás: PENDING → REJECTED indoklással")
    void testReject_withReason() {
        // Arrange
        UUID approvalId = UUID.randomUUID();
        Branch branch = createMockBranch();
        RateApproval approval = RateApproval.builder()
                .id(approvalId)
                .branch(branch)
                .currencyCode("GBP")
                .status(RateApprovalStatus.PENDING)
                .build();

        when(rateApprovalRepository.findById(approvalId)).thenReturn(Optional.of(approval));
        when(rateApprovalRepository.save(any(RateApproval.class)))
                .thenAnswer(inv -> inv.getArgument(0));

        // Act
        RateApprovalDto result = service.rejectRateChange(approvalId, "Túl nagy eltérés a piaci árfolyamtól");

        // Assert
        assertThat(result.getStatus()).isEqualTo("REJECTED");
        assertThat(result.getReason()).isEqualTo("Túl nagy eltérés a piaci árfolyamtól");
    }
}
