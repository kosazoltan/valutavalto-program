package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.AmlApprovalGrant;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.TransactionAmlApproval;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.AmlApprovalGrantRepository;
import hu.puzzleir.valuta.repository.TransactionAmlApprovalRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * AML felsővezetői jóváhagyás (Pmt. 14/A. § (4), MNB 14/2025 V.2.6) rögzítő szolgáltatás unit teszt.
 */
@ExtendWith(MockitoExtension.class)
class AmlApprovalServiceTest {

    @Mock private WorkerRepository workerRepository;
    @Mock private TransactionAmlApprovalRepository approvalRepository;
    @Mock private AmlApprovalGrantRepository grantRepository;
    @InjectMocks private AmlApprovalService service;

    private final UUID companyId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        UsernamePasswordAuthenticationToken auth =
                new UsernamePasswordAuthenticationToken("W1", null, List.of());
        auth.setDetails(new WorkerAuthenticationDetails(1L, companyId, UUID.randomUUID(), "CASHIER"));
        SecurityContextHolder.getContext().setAuthentication(auth);
    }

    @AfterEach
    void clear() {
        SecurityContextHolder.clearContext();
    }

    private Worker worker(Long id, String name, WorkerRole role, UUID cId) {
        Company c = Company.builder().id(cId).code("EBC").build();
        Worker w = new Worker();
        w.setId(id);
        w.setName(name);
        w.setRole(role);
        w.setCompany(c);
        return w;
    }

    @Test
    @DisplayName("érvényes felsővezető (MANAGER) engedélyező → rögzít az engedélyező NEVÉVEL")
    void recordSeniorApproval_validSupervisor_recordsWithName() {
        when(workerRepository.findById(99L)).thenReturn(Optional.of(
                worker(99L, "Kósa Zoltán", WorkerRole.MANAGER, companyId)));
        when(approvalRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));
        // Codex P1: van felhasználható grant (a PIN-ellenorzes letrehozta) → atomikus decrement sikeres.
        when(grantRepository.findConsumableIds(any(), any(), any(), any(), any())).thenReturn(List.of(1L));
        when(grantRepository.decrementIfAvailable(1L)).thenReturn(1);

        TransactionAmlApproval rec = service.recordSeniorApproval(99L,
                "FATF 1/a (ellenintézkedés)", new BigDecimal("6000000"), "Teszt Ügyfél", "V00001", "session-1");

        assertThat(rec.getApprovedByName()).isEqualTo("Kósa Zoltán");
        assertThat(rec.getApprovedByWorkerId()).isEqualTo(99L);
        assertThat(rec.getApprovalReason()).contains("1/a");
        assertThat(rec.getCompanyId()).isEqualTo(companyId);
        verify(approvalRepository).save(any());
        // A grant atomikusan elhasznalodott (uses_remaining--).
        verify(grantRepository).decrementIfAvailable(1L);
    }

    @Test
    @DisplayName("érvényes engedélyező DE nincs PIN-grant → elutasít (Codex P1: nincs forge PIN nélkül)")
    void recordSeniorApproval_noGrant_rejected() {
        when(workerRepository.findById(99L)).thenReturn(Optional.of(
                worker(99L, "Kósa Zoltán", WorkerRole.MANAGER, companyId)));
        // Nincs felhasználható grant → a PIN-ellenorzes nem tortent meg → tilos rogziteni.
        when(grantRepository.findConsumableIds(any(), any(), any(), any(), any())).thenReturn(List.of());

        assertThatThrownBy(() -> service.recordSeniorApproval(99L, "AML", BigDecimal.TEN, "X", null, "session-1"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("PIN-ellenőrzés nélkül");
        verify(approvalRepository, never()).save(any());
    }

    @Test
    @DisplayName("pénztáros (CASHIER) engedélyező → elutasít, NEM rögzít")
    void recordSeniorApproval_cashier_rejected() {
        when(workerRepository.findById(50L)).thenReturn(Optional.of(
                worker(50L, "Pénztáros Béla", WorkerRole.CASHIER, companyId)));

        assertThatThrownBy(() -> service.recordSeniorApproval(50L, "AML", BigDecimal.TEN, "X", null, "session-1"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem jogosult");
        verify(approvalRepository, never()).save(any());
    }

    @Test
    @DisplayName("más cég engedélyezője → elutasít (multi-tenant)")
    void recordSeniorApproval_crossTenant_rejected() {
        when(workerRepository.findById(77L)).thenReturn(Optional.of(
                worker(77L, "Más Cég Vezető", WorkerRole.MANAGER, UUID.randomUUID())));

        assertThatThrownBy(() -> service.recordSeniorApproval(77L, "AML", BigDecimal.TEN, "X", null, "session-1"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nem ehhez a céghez");
        verify(approvalRepository, never()).save(any());
    }

    @Test
    @DisplayName("self-approval (engedélyező = a bejelentkezett pénztáros) → elutasít (4-szem-elv)")
    void recordSeniorApproval_selfApproval_rejected() {
        // setUp: a bejelentkezett worker id-ja 1L → 1L engedélyező = self-approval.
        assertThatThrownBy(() -> service.recordSeniorApproval(1L, "AML", BigDecimal.TEN, "X", null, "session-1"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("4-szem-elv");
        verify(approvalRepository, never()).save(any());
    }

    @Test
    @DisplayName("hiányzó engedélyező (null) → elutasít")
    void recordSeniorApproval_nullApprover_rejected() {
        assertThatThrownBy(() -> service.recordSeniorApproval(null, "AML", BigDecimal.TEN, "X", null, "session-1"))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("nincs megadva");
    }

    @Test
    @DisplayName("issueApprovalGrant: EGY grant, SERVER-FIX uses=1 — egy PIN egy nyugtát fed (Codex P1)")
    void issueApprovalGrant_savesOneGrantWithServerFixedUses() {
        service.issueApprovalGrant(99L, "session-xyz");

        ArgumentCaptor<AmlApprovalGrant> captor = ArgumentCaptor.forClass(AmlApprovalGrant.class);
        verify(grantRepository, times(1)).save(captor.capture());
        AmlApprovalGrant saved = captor.getValue();
        assertThat(saved.getApproverWorkerId()).isEqualTo(99L);
        assertThat(saved.getCompanyId()).isEqualTo(companyId);
        assertThat(saved.getSessionId()).isEqualTo("session-xyz"); // receipt-scoping (Codex P1)
        // GRANT_USES_PER_PIN=1: egy nyugta (single/multi-line/konverzió) az approvalRecorded flag miatt
        // legfeljebb egy jóváhagyást rögzít → egy PIN egy felhasználást fedez, nem amplifikálható.
        assertThat(saved.getUsesRemaining()).isEqualTo(1);
    }

    @Test
    @DisplayName("isValidSeniorApprover: supervisor=true, pénztáros=false, null=false")
    void isValidSeniorApprover() {
        when(workerRepository.findById(99L)).thenReturn(Optional.of(
                worker(99L, "Vezető", WorkerRole.SUPERVISOR, companyId)));
        when(workerRepository.findById(50L)).thenReturn(Optional.of(
                worker(50L, "Pénztáros", WorkerRole.CASHIER, companyId)));

        assertThat(service.isValidSeniorApprover(99L)).isTrue();
        assertThat(service.isValidSeniorApprover(50L)).isFalse();
        assertThat(service.isValidSeniorApprover(null)).isFalse();
    }
}
