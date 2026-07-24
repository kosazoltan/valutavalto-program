package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.ClosingControlDto;
import hu.puzzleir.valuta.dto.ClosingMarkType;
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

    @Mock
    private AuditLogService auditLogService;

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
        assertEquals(1, row.getRequiredCount());
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
        assertEquals(1, result.getCompletedCount());
        assertEquals("NONE", result.getAlertLevel());
        assertFalse(result.getMissingRecord());
    }

    @Test
    @DisplayName("markClosingDone creates daily record and makes cashier branch OK")
    void markClosingDone_createsDailyRecord() {
        LocalDate date = LocalDate.now();
        UUID branchId = UUID.randomUUID();
        Branch branch = branch(branchId, "BR01", "Pénztár 01");
        ClosingControl saved = ClosingControl.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .branchId(branchId)
                .controlDate(date)
                .dailyClosingDone(false)
                .eveningClosingDone(false)
                .navClosingDone(false)
                .alertLevel("WARNING")
                .build();

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(companyId, branchId, date))
                .thenReturn(Optional.empty());
        when(closingControlRepository.save(org.mockito.ArgumentMatchers.any(ClosingControl.class)))
                .thenAnswer(invocation -> {
                    ClosingControl control = invocation.getArgument(0);
                    if (control.getId() == null) {
                        control.setId(saved.getId());
                    }
                    return control;
                });

        ClosingControlDto result = service.markClosingDone(companyId, branchId, date, ClosingMarkType.DAILY);

        assertTrue(result.getDailyClosingDone());
        assertFalse(result.getEveningClosingDone());
        assertEquals("NONE", result.getAlertLevel());
        assertEquals(1, result.getCompletedCount());
        verify(auditLogService).log(org.mockito.ArgumentMatchers.eq("CLOSING_RECEIVED_DAILY"),
                org.mockito.ArgumentMatchers.eq("ClosingControl"),
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.eq(branchId.toString()),
                org.mockito.ArgumentMatchers.eq("Pénztár 01"),
                org.mockito.ArgumentMatchers.any(),
                org.mockito.ArgumentMatchers.isNull(),
                org.mockito.ArgumentMatchers.isNull());
    }

    @Test
    @DisplayName("FK-062: vault branch is OK with DAILY flag alone (evening flag ignored)")
    void getBranchStatus_vaultDailyAloneIsOk() {
        LocalDate date = LocalDate.now();
        UUID branchId = UUID.randomUUID();
        Branch branch = branch(branchId, "EV01", "Értéktár 01");
        branch.setIsVault(true);
        ClosingControl control = ClosingControl.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .branchId(branchId)
                .controlDate(date)
                .dailyClosingDone(true)
                .eveningClosingDone(false)
                .navClosingDone(true)
                .alertLevel("NONE")
                .build();

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(companyId, branchId, date))
                .thenReturn(Optional.of(control));

        ClosingControlDto result = service.getBranchStatus(branchId, date);

        assertEquals("NONE", result.getAlertLevel());
        assertEquals(1, result.getCompletedCount());
        assertEquals(1, result.getRequiredCount());
        assertFalse(result.getMissingRecord());
    }

    @Test
    @DisplayName("FK-062: vault branch without DAILY flag stays missing (WARNING)")
    void getBranchStatus_vaultWithoutDailyIsMissing() {
        LocalDate date = LocalDate.now();
        UUID branchId = UUID.randomUUID();
        Branch branch = branch(branchId, "EV02", "Értéktár 02");
        branch.setIsVault(true);
        ClosingControl control = ClosingControl.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .branchId(branchId)
                .controlDate(date)
                .dailyClosingDone(false)
                .eveningClosingDone(true)
                .navClosingDone(false)
                .alertLevel("WARNING")
                .build();

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(companyId, branchId, date))
                .thenReturn(Optional.of(control));

        ClosingControlDto result = service.getBranchStatus(branchId, date);

        assertEquals("WARNING", result.getAlertLevel());
        assertEquals(0, result.getCompletedCount());
        assertEquals(1, result.getRequiredCount());
    }

    @Test
    @DisplayName("FK-062 regression: cashier branch with only EVENING flag stays missing")
    void getBranchStatus_cashierEveningOnlyIsMissing() {
        LocalDate date = LocalDate.now();
        UUID branchId = UUID.randomUUID();
        Branch branch = branch(branchId, "BP02", "Budapest 02");
        ClosingControl control = ClosingControl.builder()
                .id(UUID.randomUUID())
                .companyId(companyId)
                .branchId(branchId)
                .controlDate(date)
                .dailyClosingDone(false)
                .eveningClosingDone(true)
                .navClosingDone(false)
                .alertLevel("WARNING")
                .build();

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(companyId, branchId, date))
                .thenReturn(Optional.of(control));

        ClosingControlDto result = service.getBranchStatus(branchId, date);

        assertEquals("WARNING", result.getAlertLevel());
        assertEquals(0, result.getCompletedCount());
    }

    @Test
    @DisplayName("FK-062: markClosingDone DAILY on vault branch resolves alertLevel to NONE")
    void markClosingDone_vaultDailyResolvesAlert() {
        LocalDate date = LocalDate.now();
        UUID branchId = UUID.randomUUID();
        Branch branch = branch(branchId, "EV03", "Értéktár 03");
        branch.setIsVault(true);

        when(branchRepository.findById(branchId)).thenReturn(Optional.of(branch));
        when(closingControlRepository.findByCompanyIdAndBranchIdAndControlDate(companyId, branchId, date))
                .thenReturn(Optional.empty());
        when(closingControlRepository.save(org.mockito.ArgumentMatchers.any(ClosingControl.class)))
                .thenAnswer(invocation -> {
                    ClosingControl control = invocation.getArgument(0);
                    if (control.getId() == null) {
                        control.setId(UUID.randomUUID());
                    }
                    return control;
                });

        ClosingControlDto result = service.markClosingDone(companyId, branchId, date, ClosingMarkType.DAILY);

        assertTrue(result.getDailyClosingDone());
        assertFalse(result.getEveningClosingDone());
        assertEquals("NONE", result.getAlertLevel());
        assertEquals(1, result.getCompletedCount());
    }

    private Branch branch(UUID id, String code, String name) {
        return Branch.builder()
                .id(id)
                .code(code)
                .name(name)
                .city("Budapest")
                .company(Company.builder().id(companyId).name("Best Change").build())
                .isActive(true)
                .isVault(false)
                .build();
    }
}
