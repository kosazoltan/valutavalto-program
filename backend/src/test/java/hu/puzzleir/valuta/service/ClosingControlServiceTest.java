package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ClosingControlDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingControl;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ClosingControlRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.when;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.never;

@ExtendWith(MockitoExtension.class)
class ClosingControlServiceTest {

    @Mock
    private ClosingControlRepository closingControlRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private NotificationService notificationService;

    @InjectMocks
    private ClosingControlService service;

    private UUID companyId;

    @BeforeEach
    void setUpAuthContext() {
        companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("WORKER001", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(99L, companyId, branchId, "MANAGER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clearAuthContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    @DisplayName("checkAllBranches returns missing active branches as critical rows for past dates")
    void checkAllBranches_returnsMissingActiveBranches() {
        LocalDate date = LocalDate.now().minusDays(1);
        UUID branchId = UUID.randomUUID();
        Branch branch = branch(branchId, "BP01", "Budapest 01");

        when(closingControlRepository.findByCompanyIdAndControlDate(companyId, date)).thenReturn(List.of());
        // FK-014: a Zárás beérkezés a banki/speciális partnereket (VAULT_COUNTERPARTY) kizáró
        // repo-metódust hívja — a napi zárást NEM végző partnerek nem jelenhetnek meg.
        when(branchRepository.findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId)).thenReturn(List.of(branch));

        List<ClosingControlDto> result = service.checkAllBranches(date);

        verify(branchRepository).findByCompanyIdAndIsActiveTrueExcludingCounterparties(companyId);
        verify(branchRepository, never()).findByCompanyIdAndIsActiveTrue(companyId);
        assertEquals(1, result.size());
        ClosingControlDto row = result.get(0);
        assertNull(row.getId());
        assertEquals(branchId, row.getBranchId());
        assertEquals("BP01", row.getBranchCode());
        assertEquals("Budapest 01", row.getBranchName());
        assertFalse(row.getDailyClosingDone());
        assertFalse(row.getEveningClosingDone());
        assertFalse(row.getNavClosingDone());
        assertEquals(0, row.getCompletedCount());
        assertEquals(3, row.getRequiredCount());
        assertTrue(row.getMissingRecord());
        assertEquals("CRITICAL", row.getAlertLevel());
    }

    @Test
    @DisplayName("getBranchStatus enriches existing control with branch identity")
    void getBranchStatus_enrichesExistingControl() {
        LocalDate date = LocalDate.now();
        UUID branchId = UUID.randomUUID();
        Branch branch = branch(branchId, "PEC1", "Pécs Diana");
        ClosingControl control = ClosingControl.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .branchId(branchId)
                .controlDate(date)
                .dailyClosingDone(true)
                .eveningClosingDone(true)
                .navClosingDone(true)
                .alertLevel("NONE")
                .build();

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(companyId, branchId, date))
                .thenReturn(Optional.of(control));

        ClosingControlDto result = service.getBranchStatus(branchId, date);

        assertEquals(control.getId(), result.getId());
        assertEquals("PEC1", result.getBranchCode());
        assertEquals("Pécs Diana", result.getBranchName());
        assertEquals(3, result.getCompletedCount());
        assertEquals("NONE", result.getAlertLevel());
        assertFalse(result.getMissingRecord());
    }

    private Branch branch(UUID id, String code, String name) {
        return Branch.builder()
                .id(id)
                .code(code)
                .name(name)
                .city("Budapest")
                .company(Company.builder().id(companyId).name("Best Change").build())
                .isActive(true)
                .build();
    }
}
