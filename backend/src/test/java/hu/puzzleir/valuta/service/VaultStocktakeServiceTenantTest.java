package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.VaultStocktakeItem;
import hu.puzzleir.valuta.entity.VaultStocktakeSession;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.VaultStocktakeItemRepository;
import hu.puzzleir.valuta.repository.VaultStocktakeSessionRepository;
import hu.puzzleir.valuta.repository.VaultTerritoryRepository;
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

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * F1 fix-batch (Eszter audit) IDOR tenant-leak fix-verifikacio.
 *
 * Eszter P1 finding: a `VaultStocktakeService` ID-alapu fetch (findByIdWithItems)
 * NEM volt company-scoped — mas tenant session-jenek ID-javal olvashatok voltak az adatok.
 * A javitas: a repository uj `findByIdAndCompanyIdWithItems` metodus, a service ezt hasznalja.
 *
 * Ezek a tesztek bizonyitjak, hogy a tenant-szuro valoban mukodik: ha a service masik
 * company sessionet probal kerdezni, ResourceNotFoundException-t dob (NEM ValidationException,
 * mert akkor szivarogna info, hogy a session letezik).
 */
@ExtendWith(MockitoExtension.class)
class VaultStocktakeServiceTenantTest {

    private static final UUID COMPANY_A = UUID.fromString("11111111-1111-1111-1111-111111111111");
    private static final UUID COMPANY_B = UUID.fromString("22222222-2222-2222-2222-222222222222");
    private static final UUID SESSION_ID = UUID.fromString("33333333-3333-3333-3333-333333333333");

    @Mock
    private VaultStocktakeSessionRepository sessionRepo;
    @Mock
    private VaultStocktakeItemRepository itemRepo;
    @Mock
    private CompanyRepository companyRepo;
    @Mock
    private BranchRepository branchRepo;
    @Mock
    private VaultTerritoryRepository vaultTerritoryRepository;
    @Mock
    private BanknoteInventoryService banknoteInventoryService;
    @Mock
    private AuditLogService auditLogService;

    @InjectMocks
    private VaultStocktakeService service;

    private MockedStatic<SecurityUtils> securityUtilsMock;

    @BeforeEach
    void setUp() {
        securityUtilsMock = mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_A);
        securityUtilsMock.when(SecurityUtils::getCurrentWorkerCode).thenReturn("test-worker");
        securityUtilsMock.when(SecurityUtils::getCurrentRole).thenReturn("ADMIN");
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) securityUtilsMock.close();
    }

    @Test
    @DisplayName("getSession masik company sessionjen -> ResourceNotFoundException (IDOR vedett)")
    void getSession_otherCompanysSession_throwsResourceNotFound() {
        // ELVARAS: a company-scoped query NEM ad vissza session-t, ha a sessionId masik tenanthez tartozik.
        when(sessionRepo.findByIdAndCompanyIdWithItems(SESSION_ID, COMPANY_A)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.getSession(SESSION_ID))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining(SESSION_ID.toString());

        // ELVARAS: a deprecated tenant-fuggetlen findByIdWithItems-t NEM hivjuk
        verify(sessionRepo, never()).findByIdWithItems(SESSION_ID);
    }

    @Test
    @DisplayName("moveToReview masik company sessionjen -> ResourceNotFoundException")
    void moveToReview_otherCompanysSession_throwsResourceNotFound() {
        when(sessionRepo.findByIdAndCompanyIdWithItems(SESSION_ID, COMPANY_A)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.moveToReview(SESSION_ID))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(sessionRepo, never()).findByIdWithItems(SESSION_ID);
    }

    @Test
    @DisplayName("closeSession masik company sessionjen -> ResourceNotFoundException")
    void closeSession_otherCompanysSession_throwsResourceNotFound() {
        when(sessionRepo.findByIdAndCompanyIdWithItems(SESSION_ID, COMPANY_A)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.closeSession(SESSION_ID))
                .isInstanceOf(ResourceNotFoundException.class);

        verify(sessionRepo, never()).findByIdWithItems(SESSION_ID);
    }

    @Test
    @DisplayName("cancelSession masik company sessionjen -> ResourceNotFoundException")
    void cancelSession_otherCompanysSession_throwsResourceNotFound() {
        when(sessionRepo.findByIdAndCompanyId(SESSION_ID, COMPANY_A)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.cancelSession(SESSION_ID, "user request"))
                .isInstanceOf(ResourceNotFoundException.class);

        // a regi tenant-fuggetlen findById sem hivodhat
        verify(sessionRepo, never()).findById(SESSION_ID);
    }

    @Test
    @DisplayName("setItemActual masik company itemjen -> ResourceNotFoundException (item-on keresztuli IDOR)")
    void setItemActual_otherCompanysItem_throwsResourceNotFound() {
        UUID itemId = UUID.fromString("44444444-4444-4444-4444-444444444444");

        Company otherCompany = Company.builder().id(COMPANY_B).build();
        VaultStocktakeSession otherSession = VaultStocktakeSession.builder()
                .id(SESSION_ID).company(otherCompany).status(VaultStocktakeSession.Status.OPEN).build();
        VaultStocktakeItem item = VaultStocktakeItem.builder().id(itemId).session(otherSession).build();

        when(itemRepo.findById(itemId)).thenReturn(Optional.of(item));

        assertThatThrownBy(() -> service.setItemActual(itemId, 5, null))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining(itemId.toString());
    }
}
