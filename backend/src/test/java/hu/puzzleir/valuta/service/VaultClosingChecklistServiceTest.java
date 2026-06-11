package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.vaultchecklist.CompleteChecklistRequest;
import hu.puzzleir.valuta.dto.vaultchecklist.UpdateChecklistItemsRequest;
import hu.puzzleir.valuta.dto.vaultchecklist.VaultClosingChecklistDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.VaultClosingChecklist;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.VaultClosingChecklistRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.*;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * VaultClosingChecklistService unit tesztek.
 *
 * <p>Lefedett esetek:</p>
 * <ol>
 *   <li>getOrCreate idempotens — meglévő rekordra visszaadja, nem hoz létre újat</li>
 *   <li>getOrCreate új rekordot hoz létre, ha nem létezik</li>
 *   <li>Cross-tenant kísérlet 404 ResourceNotFoundException-t dob</li>
 *   <li>complete() auditor_name kényszer — üres név ValidationException-t dob</li>
 *   <li>complete() auditor_role kényszer — üres beosztás ValidationException-t dob</li>
 *   <li>complete() sikeres esetben audit-log hívódik</li>
 * </ol>
 */
@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
class VaultClosingChecklistServiceTest {

    @InjectMocks
    private VaultClosingChecklistService service;

    @Mock
    private VaultClosingChecklistRepository checklistRepository;

    @Mock
    private BranchRepository branchRepository;

    @Mock
    private AuditLogService auditLogService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();
    private static final UUID OTHER_COMPANY_ID = UUID.randomUUID();
    private static final LocalDate DATE = LocalDate.of(2026, 6, 11);

    @BeforeEach
    void setUpSecurityContext() {
        WorkerAuthenticationDetails details =
                new WorkerAuthenticationDetails(42L, COMPANY_ID, BRANCH_ID, "CASHIER");
        TestingAuthenticationToken auth =
                new TestingAuthenticationToken("test", "pass", "ROLE_CASHIER");
        auth.setDetails(details);
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    // ===== segédmetódusok =====

    private Branch branchOwnedByCurrentCompany() {
        Company company = new Company();
        company.setId(COMPANY_ID);
        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setName("EBC Iroda 1");
        branch.setCompany(company);
        return branch;
    }

    private Branch branchOwnedByOtherCompany() {
        Company company = new Company();
        company.setId(OTHER_COMPANY_ID);
        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setName("Más cég pénztára");
        branch.setCompany(company);
        return branch;
    }

    private VaultClosingChecklist existingChecklist(Branch branch) {
        return VaultClosingChecklist.builder()
                .id(UUID.randomUUID())
                .companyId(COMPANY_ID)
                .branch(branch)
                .closingDate(DATE)
                .item1(true)
                .item2(false)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();
    }

    // ===== 1. getOrCreate idempotens =====

    @Test
    @DisplayName("getOrCreate — meglévő rekord esetén NEM hoz létre újat (idempotencia)")
    void getOrCreate_existingRecord_returnsExistingWithoutSave() {
        Branch branch = branchOwnedByCurrentCompany();
        VaultClosingChecklist existing = existingChecklist(branch);

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(checklistRepository.findByCompanyIdAndBranch_IdAndClosingDate(COMPANY_ID, BRANCH_ID, DATE))
                .thenReturn(Optional.of(existing));

        VaultClosingChecklistDto result = service.getOrCreate(BRANCH_ID, DATE);

        assertThat(result).isNotNull();
        assertThat(result.getBranchId()).isEqualTo(BRANCH_ID);
        assertThat(result.isItem1()).isTrue();
        assertThat(result.isItem2()).isFalse();

        // save() NEM hívódik meg idempotens esetben
        verify(checklistRepository, never()).save(any());
    }

    // ===== 2. getOrCreate új rekord =====

    @Test
    @DisplayName("getOrCreate — nem létező rekord esetén létrehozza és elmenti")
    void getOrCreate_noExistingRecord_createsAndSaves() {
        Branch branch = branchOwnedByCurrentCompany();
        VaultClosingChecklist newRecord = existingChecklist(branch);

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(checklistRepository.findByCompanyIdAndBranch_IdAndClosingDate(COMPANY_ID, BRANCH_ID, DATE))
                .thenReturn(Optional.empty());
        when(checklistRepository.save(any(VaultClosingChecklist.class))).thenReturn(newRecord);

        VaultClosingChecklistDto result = service.getOrCreate(BRANCH_ID, DATE);

        assertThat(result).isNotNull();
        verify(checklistRepository, times(1)).save(any(VaultClosingChecklist.class));
    }

    // ===== 3. Cross-tenant guard =====

    @Test
    @DisplayName("getOrCreate — más cég branch-ére 404 ResourceNotFoundException")
    void getOrCreate_crossTenantBranch_throws404() {
        Branch crossTenantBranch = branchOwnedByOtherCompany();
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(crossTenantBranch));

        assertThatThrownBy(() -> service.getOrCreate(BRANCH_ID, DATE))
                .isInstanceOf(ResourceNotFoundException.class);

        // Checklist repository NEM kerül megkeresésre
        verify(checklistRepository, never()).findByCompanyIdAndBranch_IdAndClosingDate(any(), any(), any());
    }

    // ===== 4. complete() auditor_name kényszer =====

    @Test
    @DisplayName("complete — üres auditorName ValidationException-t dob (FR-ZARUI-26)")
    void complete_emptyAuditorName_throwsValidationException() {
        Branch branch = branchOwnedByCurrentCompany();
        VaultClosingChecklist checklist = existingChecklist(branch);

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(checklistRepository.findByCompanyIdAndBranch_IdAndClosingDate(COMPANY_ID, BRANCH_ID, DATE))
                .thenReturn(Optional.of(checklist));

        CompleteChecklistRequest req = CompleteChecklistRequest.builder()
                .auditorName("   ")  // üres/blank
                .auditorRole("Vezető")
                .build();

        assertThatThrownBy(() -> service.complete(BRANCH_ID, DATE, req))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("kötelező");
    }

    // ===== 5. complete() auditor_role kényszer =====

    @Test
    @DisplayName("complete — üres auditorRole ValidationException-t dob (FR-ZARUI-26)")
    void complete_emptyAuditorRole_throwsValidationException() {
        Branch branch = branchOwnedByCurrentCompany();
        VaultClosingChecklist checklist = existingChecklist(branch);

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(checklistRepository.findByCompanyIdAndBranch_IdAndClosingDate(COMPANY_ID, BRANCH_ID, DATE))
                .thenReturn(Optional.of(checklist));

        CompleteChecklistRequest req = CompleteChecklistRequest.builder()
                .auditorName("Kovács Péter")
                .auditorRole("")  // üres
                .build();

        assertThatThrownBy(() -> service.complete(BRANCH_ID, DATE, req))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("kötelező");
    }

    // ===== 6. complete() audit-log hívás =====

    @Test
    @DisplayName("complete — sikeres véglegesítésnél auditLogService.log() hívódik")
    void complete_success_callsAuditLog() {
        Branch branch = branchOwnedByCurrentCompany();
        VaultClosingChecklist checklist = existingChecklist(branch);

        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
        when(checklistRepository.findByCompanyIdAndBranch_IdAndClosingDate(COMPANY_ID, BRANCH_ID, DATE))
                .thenReturn(Optional.of(checklist));
        when(checklistRepository.save(any(VaultClosingChecklist.class))).thenReturn(checklist);

        CompleteChecklistRequest req = CompleteChecklistRequest.builder()
                .auditorName("Kovács Péter")
                .auditorRole("Értéktáros vezető")
                .build();

        VaultClosingChecklistDto result = service.complete(BRANCH_ID, DATE, req);

        assertThat(result).isNotNull();
        // Audit log hívódott meg
        verify(auditLogService, times(1)).log(
                eq("VAULT_CLOSING_CHECKLIST_COMPLETE"),
                anyString(),
                anyString()
        );
        // completedAt és completedBy is beállítódott
        verify(checklistRepository, times(1)).save(argThat(c ->
                c.getCompletedAt() != null && c.getCompletedByWorkerId() != null));
    }
}
