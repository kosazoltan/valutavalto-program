package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.DocumentSide;
import hu.puzzleir.valuta.entity.DocumentViewGrant;
import hu.puzzleir.valuta.entity.ScannedDocument;
import hu.puzzleir.valuta.entity.ScannedDocumentImage;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.entity.WorkerRole;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.DocumentViewGrantRepository;
import hu.puzzleir.valuta.repository.ScannedDocumentImageRepository;
import hu.puzzleir.valuta.repository.ScannedDocumentRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;
import org.springframework.security.access.AccessDeniedException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.contains;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FS-5 SLICE 2 — DocumentViewGrantService tesztek (RED→GREEN).
 *
 * <p>7 kötelező eset a terv T2.1 szerint:</p>
 * <ol>
 *   <li>issueViewGrant happy: supervisor + jó PIN → save(usesRemaining=1, documentId kötve).</li>
 *   <li>issueViewGrant hibás PIN → ValidationException, save SOHA.</li>
 *   <li>issueViewGrant nem-supervisor → ValidationException, PIN-ellenőrzés SEM fut.</li>
 *   <li>serveFullImage aktív granttel → bájt kimegy, decrement + audit hívva.</li>
 *   <li>serveFullImage grant nélkül → AccessDeniedException.</li>
 *   <li>serveFullImage kimerült granttel (decrement=0) → AccessDeniedException.</li>
 *   <li>cross-tenant dokumentum → ResourceNotFoundException (parent-assert dob, grant-lookup nem fut).</li>
 * </ol>
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class DocumentViewGrantServiceTest {

    @org.mockito.InjectMocks
    private DocumentViewGrantService service;

    @org.mockito.Mock private DocumentViewGrantRepository grantRepository;
    @org.mockito.Mock private ScannedDocumentRepository scannedDocumentRepository;
    @org.mockito.Mock private ScannedDocumentImageRepository imageRepository;
    @org.mockito.Mock private CustomerRepository customerRepository;
    @org.mockito.Mock private TransactionRepository transactionRepository;
    @org.mockito.Mock private WorkerRepository workerRepository;
    @org.mockito.Mock private SupervisorPinService supervisorPinService;
    @org.mockito.Mock private AuditLogService auditLogService;

    private static final UUID COMPANY_ID = UUID.randomUUID();
    private static final UUID DOC_ID = UUID.randomUUID();
    private static final Long REQUESTER_ID = 10L;
    private static final Long APPROVER_ID = 20L;
    private static final String PIN = "1234";

    // ---- Fixtures ----

    private Company company() {
        return Company.builder().id(COMPANY_ID).code("TEST").name("Test").build();
    }

    private ScannedDocument ownDoc() {
        return ScannedDocument.builder()
                .id(DOC_ID)
                .customerId(1L)
                .isDeleted(false)
                .build();
    }

    private ScannedDocument crossTenantDoc() {
        return ScannedDocument.builder()
                .id(DOC_ID)
                .customerId(999L)
                .isDeleted(false)
                .build();
    }

    private Worker approver(WorkerRole role) {
        return Worker.builder()
                .id(APPROVER_ID)
                .company(company())
                .role(role)
                .build();
    }

    private ScannedDocumentImage image() {
        return ScannedDocumentImage.builder()
                .scannedDocumentId(DOC_ID)
                .side(DocumentSide.FRONT)
                .mimeType("image/jpeg")
                .fileData(new byte[]{1, 2, 3})
                .build();
    }

    // ================================================================
    // issueViewGrant — 7 eset
    // ================================================================

    @Test
    @DisplayName("1. issueViewGrant happy: supervisor + jó PIN → save(usesRemaining=1, documentId kötve)")
    void issueViewGrant_happy_savesSingleUseGrant() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(REQUESTER_ID);

            when(scannedDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(ownDoc()));
            when(customerRepository.existsByIdAndCompany_Id(1L, COMPANY_ID)).thenReturn(true);
            when(workerRepository.findByIdAndCompanyId(APPROVER_ID, COMPANY_ID)).thenReturn(Optional.of(approver(WorkerRole.SUPERVISOR)));
            when(supervisorPinService.verifyPin(APPROVER_ID, PIN, null, null)).thenReturn(true);

            service.issueViewGrant(DOC_ID, APPROVER_ID, PIN, null, null);

            ArgumentCaptor<DocumentViewGrant> captor = ArgumentCaptor.forClass(DocumentViewGrant.class);
            verify(grantRepository).save(captor.capture());
            DocumentViewGrant saved = captor.getValue();
            assertThat(saved.getUsesRemaining()).isEqualTo(1);
            assertThat(saved.getDocumentId()).isEqualTo(DOC_ID);
            assertThat(saved.getRequesterWorkerId()).isEqualTo(REQUESTER_ID);
            assertThat(saved.getApproverWorkerId()).isEqualTo(APPROVER_ID);
            assertThat(saved.getCompanyId()).isEqualTo(COMPANY_ID);
            assertThat(saved.getExpiresAt()).isAfter(LocalDateTime.now().plusMinutes(8));
            assertThat(saved.getExpiresAt()).isBefore(LocalDateTime.now().plusMinutes(12));
        }
    }

    @Test
    @DisplayName("2. issueViewGrant hibás PIN → ValidationException, save SOHA")
    void issueViewGrant_badPin_throwsAndNeverSaves() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(REQUESTER_ID);

            when(scannedDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(ownDoc()));
            when(customerRepository.existsByIdAndCompany_Id(1L, COMPANY_ID)).thenReturn(true);
            when(workerRepository.findByIdAndCompanyId(APPROVER_ID, COMPANY_ID)).thenReturn(Optional.of(approver(WorkerRole.SUPERVISOR)));
            when(supervisorPinService.verifyPin(APPROVER_ID, PIN, null, null)).thenReturn(false);

            assertThatThrownBy(() -> service.issueViewGrant(DOC_ID, APPROVER_ID, PIN, null, null))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("PIN");

            verify(grantRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("3. issueViewGrant nem-supervisor → ValidationException, PIN-ellenőrzés SEM fut")
    void issueViewGrant_nonSupervisor_throwsWithoutPinCheck() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            when(scannedDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(ownDoc()));
            when(customerRepository.existsByIdAndCompany_Id(1L, COMPANY_ID)).thenReturn(true);
            when(workerRepository.findByIdAndCompanyId(APPROVER_ID, COMPANY_ID)).thenReturn(Optional.of(approver(WorkerRole.CASHIER)));

            assertThatThrownBy(() -> service.issueViewGrant(DOC_ID, APPROVER_ID, PIN, null, null))
                    .isInstanceOf(ValidationException.class);

            verify(supervisorPinService, never()).verifyPin(anyLong(), anyString(), any(), any());
            verify(grantRepository, never()).save(any());
        }
    }

    @Test
    @DisplayName("3b. issueViewGrant cross-tenant approver → SAME 'nem jogosult' error, PIN soha, save soha (enumeration-disclosure fix)")
    void issueViewGrant_crossTenantApprover_uniformErrorNoPinNoSave() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);

            when(scannedDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(ownDoc()));
            when(customerRepository.existsByIdAndCompany_Id(1L, COMPANY_ID)).thenReturn(true);
            // A más céghez tartozó (vagy nem létező) approver — findByIdAndCompanyId üres.
            when(workerRepository.findByIdAndCompanyId(APPROVER_ID, COMPANY_ID))
                    .thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.issueViewGrant(DOC_ID, APPROVER_ID, PIN, null, null))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("nem jogosult");

            verify(supervisorPinService, never()).verifyPin(anyLong(), anyString(), any(), any());
            verify(grantRepository, never()).save(any());
        }
    }

    // ================================================================
    // serveFullImage — 7 eset
    // ================================================================

    @Test
    @DisplayName("4. serveFullImage aktív granttel → bájt kimegy, decrement + audit hívva")
    void serveFullImage_withGrant_servesBytesAndAudits() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(REQUESTER_ID);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W001");

            when(scannedDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(ownDoc()));
            when(customerRepository.existsByIdAndCompany_Id(1L, COMPANY_ID)).thenReturn(true);
            DocumentViewGrant grant = DocumentViewGrant.builder()
                    .id(1L).companyId(COMPANY_ID).requesterWorkerId(REQUESTER_ID)
                    .approverWorkerId(APPROVER_ID).documentId(DOC_ID)
                    .usesRemaining(1).createdAt(LocalDateTime.now().minusMinutes(1))
                    .expiresAt(LocalDateTime.now().plusMinutes(9)).build();
            when(grantRepository.findActiveForDocument(eq(COMPANY_ID), eq(REQUESTER_ID), eq(DOC_ID), any()))
                    .thenReturn(List.of(grant));
            when(grantRepository.decrementIfAvailable(eq(1L), eq(COMPANY_ID), eq(REQUESTER_ID))).thenReturn(1);
            when(imageRepository.findByScannedDocumentIdAndSide(DOC_ID, DocumentSide.FRONT))
                    .thenReturn(Optional.of(image()));

            DocumentScannerService.ImagePayload result = service.serveFullImage(DOC_ID, DocumentSide.FRONT);

            assertThat(result.data()).isEqualTo(new byte[]{1, 2, 3});
            assertThat(result.mimeType()).isEqualTo("image/jpeg");
            verify(grantRepository).decrementIfAvailable(eq(1L), eq(COMPANY_ID), eq(REQUESTER_ID));

            ArgumentCaptor<String> actionCaptor = ArgumentCaptor.forClass(String.class);
            verify(auditLogService).log(actionCaptor.capture(), any(), any(), any(), any(),
                    any(), any(), any(), any(), any());
            assertThat(actionCaptor.getValue()).isEqualTo("DOCUMENT_FULLRES_VIEW");
        }
    }

    @Test
    @DisplayName("5. serveFullImage grant nélkül → AccessDeniedException, bájt nem megy ki")
    void serveFullImage_noGrant_throwsAccessDenied() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(REQUESTER_ID);

            when(scannedDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(ownDoc()));
            when(customerRepository.existsByIdAndCompany_Id(1L, COMPANY_ID)).thenReturn(true);
            when(grantRepository.findActiveForDocument(any(), any(), any(), any()))
                    .thenReturn(List.of());

            assertThatThrownBy(() -> service.serveFullImage(DOC_ID, DocumentSide.FRONT))
                    .isInstanceOf(AccessDeniedException.class);

            verify(grantRepository, never()).decrementIfAvailable(any(), any(), any());
            verify(auditLogService, never()).log(anyString(), anyString(), anyString(),
                    anyString(), anyString(), any(), any(), anyString(), any(), any());
        }
    }

    @Test
    @DisplayName("6. serveFullImage kimerült granttel (decrement=0) → AccessDeniedException")
    void serveFullImage_exhaustedGrant_throwsAccessDenied() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(REQUESTER_ID);

            when(scannedDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(ownDoc()));
            when(customerRepository.existsByIdAndCompany_Id(1L, COMPANY_ID)).thenReturn(true);
            DocumentViewGrant grant = DocumentViewGrant.builder()
                    .id(1L).usesRemaining(0).build();
            when(grantRepository.findActiveForDocument(any(), any(), any(), any()))
                    .thenReturn(List.of(grant));
            when(grantRepository.decrementIfAvailable(eq(1L), any(), any())).thenReturn(0);

            assertThatThrownBy(() -> service.serveFullImage(DOC_ID, DocumentSide.FRONT))
                    .isInstanceOf(AccessDeniedException.class);

            verify(auditLogService, never()).log(anyString(), anyString(), anyString(),
                    anyString(), anyString(), any(), any(), anyString(), any(), any());
        }
    }

    @Test
    @DisplayName("7. cross-tenant dokumentum → ResourceNotFoundException (grant-lookup nem fut)")
    void serveFullImage_crossTenantDoc_throwsResourceNotFound() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(REQUESTER_ID);

            when(scannedDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(crossTenantDoc()));
            when(customerRepository.existsByIdAndCompany_Id(999L, COMPANY_ID)).thenReturn(false);

            assertThatThrownBy(() -> service.serveFullImage(DOC_ID, DocumentSide.FRONT))
                    .isInstanceOf(ResourceNotFoundException.class);

            verify(grantRepository, never()).findActiveForDocument(any(), any(), any(), any());
            verify(grantRepository, never()).decrementIfAvailable(any(), any(), any());
        }
    }

    @Test
    @DisplayName("8. serveFullImage cross-tenant grant (decrement=0 a tenant-predikátum miatt) → AccessDeniedException, bájt nem megy ki")
    void serveFullImage_crossTenantGrant_decrementReturnsZero_throwsAccessDenied() {
        try (MockedStatic<SecurityUtils> su = Mockito.mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
            su.when(SecurityUtils::getCurrentWorkerId).thenReturn(REQUESTER_ID);
            su.when(SecurityUtils::getCurrentWorkerCode).thenReturn("W001");

            when(scannedDocumentRepository.findById(DOC_ID)).thenReturn(Optional.of(ownDoc()));
            when(customerRepository.existsByIdAndCompany_Id(1L, COMPANY_ID)).thenReturn(true);
            // A grant idegen tenantból érkezik (a findActiveForDocument már szűrte volna,
            // de defense-in-depth: maga a mutáció UPDATE is hordozza a predikátumot).
            UUID otherCompany = UUID.randomUUID();
            Long otherRequester = 999L;
            DocumentViewGrant foreignGrant = DocumentViewGrant.builder()
                    .id(42L).companyId(otherCompany).requesterWorkerId(otherRequester)
                    .approverWorkerId(APPROVER_ID).documentId(DOC_ID)
                    .usesRemaining(1).createdAt(LocalDateTime.now().minusMinutes(1))
                    .expiresAt(LocalDateTime.now().plusMinutes(9)).build();
            when(grantRepository.findActiveForDocument(any(), any(), any(), any()))
                    .thenReturn(List.of(foreignGrant));
            // A tenant-predikátum miatt a mutáció nem talál sort → 0 sor érintett.
            when(grantRepository.decrementIfAvailable(eq(42L), eq(COMPANY_ID), eq(REQUESTER_ID)))
                    .thenReturn(0);

            assertThatThrownBy(() -> service.serveFullImage(DOC_ID, DocumentSide.FRONT))
                    .isInstanceOf(AccessDeniedException.class);

            verify(grantRepository).decrementIfAvailable(eq(42L), eq(COMPANY_ID), eq(REQUESTER_ID));
            verify(auditLogService, never()).log(anyString(), anyString(), anyString(),
                    anyString(), anyString(), any(), any(), anyString(), any(), any());
        }
    }
}
