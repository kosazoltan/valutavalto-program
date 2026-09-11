package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ClosingWizard;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.WizardStatus;
import hu.puzzleir.valuta.repository.ClosingWizardRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FKH-061 follow-up — the wizard auto-expiry must NOT mutate the managed entity after the
 * conditional bulk UPDATE.
 *
 * <p>Production evidence (2026-09-11 03:30:00Z, the first scheduler tick after the V389 deploy):
 * the tick logged {@code "1 varázsló lejáratva"} yet {@code closing_wizard} contained ZERO
 * {@code EXPIRED} rows, and three records failed with
 * {@code Unexpected row count (expected row count 1 but was 0) [update closing_wizard set ... where id=? and version=?]}.
 * Cause: {@code transitionIfStale} is a {@code @Modifying} bulk UPDATE that bumps the DB
 * {@code version} column, while {@code wizard.setWizardStatus(EXPIRED)} left the still-managed
 * entity dirty. {@code SchedulerService} is class-level
 * {@code @Transactional(rollbackFor = Exception.class)}, so the flush at commit issued an entity
 * UPDATE with the pre-bulk version, threw, and rolled back the whole tick — including the bulk
 * UPDATE that had already succeeded. The defect was masked before V389, because the bulk UPDATE
 * itself died on the {@code wizard_status} CHECK constraint.
 *
 * <p>This test pins the contract at the unit level: after a successful transition the service
 * must leave the loaded entity's status UNTOUCHED (no dirty managed instance), while still
 * counting the expiry and writing the tenant-scoped audit entry.
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class ClosingWizardAutoExpiryFkh061Test {

    private static final UUID COMPANY_ID = UUID.fromString("aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee");
    private static final UUID BRANCH_ID = UUID.fromString("11111111-2222-3333-4444-555555555555");
    private static final UUID WIZARD_ID = UUID.fromString("99999999-8888-7777-6666-555555555555");

    @Mock
    private ClosingWizardRepository closingWizardRepository;
    @Mock
    private AuditLogService auditLogService;
    @Mock
    private SystemParameterService systemParameterService;

    @InjectMocks
    private ClosingWizardService service;

    @BeforeEach
    void stubExpireMinutes() {
        // resolveAutoExpireMinutes() calls getValue(...).trim(); an unstubbed mock returns null.
        // Stub it so the test exercises the expiry logic instead of a mock-wiring NPE.
        when(systemParameterService.getValue(anyString(), anyString())).thenReturn("120");
    }

    private static ClosingWizard staleWizard() {
        Company company = Company.builder().id(COMPANY_ID).build();
        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setCompany(company);

        ClosingWizard wizard = new ClosingWizard();
        wizard.setId(WIZARD_ID);
        wizard.setBranch(branch);
        wizard.setWizardStatus(WizardStatus.IN_PROGRESS);
        wizard.setClosingDate(LocalDate.of(2026, 9, 10));
        wizard.setStartedAt(LocalDateTime.now().minusHours(5));
        return wizard;
    }

    @Test
    @DisplayName("FKH-061: auto-expiry leaves the managed entity clean (no stale-version flush)")
    void autoExpiryDoesNotMutateManagedEntity() {
        ClosingWizard wizard = staleWizard();
        when(closingWizardRepository.findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), any(LocalDateTime.class)))
                .thenReturn(List.of(wizard));
        // The conditional bulk UPDATE succeeds (1 row) and bumps the DB version column.
        when(closingWizardRepository.transitionIfStale(
                eq(WIZARD_ID), eq(WizardStatus.IN_PROGRESS), eq(WizardStatus.EXPIRED),
                any(LocalDateTime.class)))
                .thenReturn(1);

        int expired = service.autoExpireStaleWizards();

        assertThat(expired).isEqualTo(1);

        // THE POINT: the loaded (managed) instance must stay IN_PROGRESS. Setting it to EXPIRED
        // here is what made the entity dirty in production and rolled the whole tick back.
        assertThat(wizard.getWizardStatus())
                .as("managed entity must not be mutated after the bulk UPDATE")
                .isEqualTo(WizardStatus.IN_PROGRESS);

        // The tenant-scoped audit entry is still written (company from the wizard's own row).
        verify(auditLogService).logForCompany(
                eq("CLOSING_WIZARD_AUTO_EXPIRED"), anyString(), eq(WIZARD_ID.toString()),
                eq(COMPANY_ID));
    }

    @Test
    @DisplayName("FKH-061: a concurrent state change (0 rows) is skipped without audit")
    void concurrentTransitionIsSkipped() {
        ClosingWizard wizard = staleWizard();
        when(closingWizardRepository.findByWizardStatusAndStartedAtBefore(
                eq(WizardStatus.IN_PROGRESS), any(LocalDateTime.class)))
                .thenReturn(List.of(wizard));
        when(closingWizardRepository.transitionIfStale(
                eq(WIZARD_ID), eq(WizardStatus.IN_PROGRESS), eq(WizardStatus.EXPIRED),
                any(LocalDateTime.class)))
                .thenReturn(0);

        int expired = service.autoExpireStaleWizards();

        assertThat(expired).isZero();
        assertThat(wizard.getWizardStatus()).isEqualTo(WizardStatus.IN_PROGRESS);
        verify(auditLogService, org.mockito.Mockito.never())
                .logForCompany(eq("CLOSING_WIZARD_AUTO_EXPIRED"), anyString(), anyString(), any(UUID.class));
    }
}
