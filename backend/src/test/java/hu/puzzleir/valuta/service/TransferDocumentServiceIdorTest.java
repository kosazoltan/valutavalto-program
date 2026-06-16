package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.TransferDocument;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.TransferDocumentRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.when;

/**
 * TransferDocumentService courier/receiver multi-tenant IDOR guard tesztek
 * (audit 2026-06-15, FINDING #19): a user-vezérelt courierId/receiverId a hívó cégéhez kötött.
 */
@ExtendWith(MockitoExtension.class)
class TransferDocumentServiceIdorTest {

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID FOREIGN_COMPANY_ID = UUID.randomUUID();
    private static final Long DOC_ID = 100L;
    private static final Long COURIER_ID = 7L;

    @Mock private TransferDocumentRepository transferDocumentRepository;
    @Mock private WorkerRepository workerRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @InjectMocks private TransferDocumentService service;

    private MockedStatic<SecurityUtils> securityUtilsMock;
    private Company ownCompany;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
        ownCompany = Company.builder().id(COMPANY_ID).build();
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) securityUtilsMock.close();
    }

    private TransferDocument pendingDoc() {
        return TransferDocument.builder()
                .id(DOC_ID).documentNumber("SZ-20260615-0001")
                .company(ownCompany)              // a bizonylat a hívó cégéhez tartozik (findAndValidate OK)
                .status(TransferDocument.Status.PENDING)
                .courierPinHash(null)             // nincs PIN → a PIN-ág kihagyva
                .build();
    }

    @Test
    @DisplayName("courierPickup: idegen cég dolgozója futárként → ResourceNotFoundException (404)")
    void courierPickup_foreignCourier_throws() {
        when(transferDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(pendingDoc()));
        Worker foreignCourier = Worker.builder().id(COURIER_ID)
                .company(Company.builder().id(FOREIGN_COMPANY_ID).build()).build();
        when(workerRepository.findById(COURIER_ID)).thenReturn(Optional.of(foreignCourier));

        assertThatThrownBy(() -> service.courierPickup(DOC_ID, COURIER_ID, null))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("Értékszállító nem található");
    }

    @Test
    @DisplayName("courierPickup: saját cég futára → PICKED_UP")
    void courierPickup_ownCourier_succeeds() {
        TransferDocument doc = pendingDoc();
        when(transferDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(doc));
        Worker ownCourier = Worker.builder().id(COURIER_ID).company(ownCompany).build();
        when(workerRepository.findById(COURIER_ID)).thenReturn(Optional.of(ownCourier));
        when(transferDocumentRepository.save(any(TransferDocument.class))).thenAnswer(inv -> inv.getArgument(0));

        TransferDocument result = service.courierPickup(DOC_ID, COURIER_ID, null);

        assertThat(result.getStatus()).isEqualTo(TransferDocument.Status.PICKED_UP);
        assertThat(result.getCourier()).isSameAs(ownCourier);
    }
}
