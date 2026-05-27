package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.PoliceRequest;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.PoliceRequestRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageRequest;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * PoliceRequestService multi-tenant (IDOR) regressziós tesztek (architect-mode audit, 2026-05-27, V270).
 *
 * Korábban a getRequest/getRequestHistory/processRequest findById/findAll-lal, company-szűrés nélkül
 * futott → bármely MANAGER/ADMIN más cég rendőrségi adatkérését olvashatta/léptethette (cross-tenant leak).
 */
@ExtendWith(MockitoExtension.class)
class PoliceRequestServiceTenantTest {

    @Mock private PoliceRequestRepository policeRequestRepository;
    @Mock private CustomerRepository customerRepository;
    @Mock private TransactionRepository transactionRepository;
    @Mock private WorkerRepository workerRepository;
    @InjectMocks private PoliceRequestService service;

    private static final UUID MY_COMPANY = UUID.randomUUID();

    @Test
    @DisplayName("getRequest — company-scoped lekérdezést használ (cross-tenant → 404)")
    void getRequest_scopedByCompany() {
        UUID id = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            // A más cég rekordja a scope-olt query-re üres → 404.
            when(policeRequestRepository.findByIdAndCompanyId(id, MY_COMPANY)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.getRequest(id))
                    .isInstanceOf(ResourceNotFoundException.class);

            verify(policeRequestRepository).findByIdAndCompanyId(id, MY_COMPANY);
            verify(policeRequestRepository, never()).findById(any());
        }
    }

    @Test
    @DisplayName("processRequest — company-scoped lekérdezést használ (cross-tenant → 404)")
    void processRequest_scopedByCompany() {
        UUID id = UUID.randomUUID();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            when(policeRequestRepository.findByIdAndCompanyId(id, MY_COMPANY)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.processRequest(id))
                    .isInstanceOf(ResourceNotFoundException.class);

            verify(policeRequestRepository).findByIdAndCompanyId(id, MY_COMPANY);
            verify(policeRequestRepository, never()).findById(any());
        }
    }

    @Test
    @DisplayName("getRequestHistory — a hívó cégére szűrő query-t használ (nem findAll)")
    void getRequestHistory_scopedByCompany() {
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            when(policeRequestRepository.findByCompanyIdOrderByCreatedAtDesc(eq(MY_COMPANY), any()))
                    .thenReturn(org.springframework.data.domain.Page.empty());

            service.getRequestHistory(PageRequest.of(0, 20));

            verify(policeRequestRepository).findByCompanyIdOrderByCreatedAtDesc(eq(MY_COMPANY), any());
            verify(policeRequestRepository, never()).findAllByOrderByCreatedAtDesc(any());
        }
    }

    @Test
    @DisplayName("getRequest — saját cég rekordja visszaadható")
    void getRequest_sameTenant_ok() {
        UUID id = UUID.randomUUID();
        PoliceRequest own = PoliceRequest.builder()
                .id(id).companyId(MY_COMPANY).requestNumber("RK-001").requestedBy("Rendőr").build();
        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(MY_COMPANY);
            when(policeRequestRepository.findByIdAndCompanyId(id, MY_COMPANY)).thenReturn(Optional.of(own));

            assertThatCode(() -> service.getRequest(id)).doesNotThrowAnyException();
        }
    }
}
