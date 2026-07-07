package hu.puzzleir.valuta.service;

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
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * FS-5: Okmány full-res megtekintés engedélyezési kapu (törvényi mag).
 *
 * <p>Két metódus:</p>
 * <ol>
 *   <li>{@link #issueViewGrant} — a supervisor/manager/admin PIN-ellenőrzése után
 *       kiállít egy SINGLE-USE grantet (usesRemaining=1, 10 perc lejárat), a konkrét
 *       dokumentumhoz kötve. Tenant-assert ELŐBB, mint a PIN-ellenőrzés.</li>
 *   <li>{@link #serveFullImage} — FAIL-CLOSED kapu: csak érvényes, fel nem használt,
 *       EHHEZ a dokumentumhoz kötött grant esetén szolgálja ki a full-res bájtokat.
 *       A grant atomikus feltételes UPDATE-tel fogy el; audit MÉG a bájtok előtt,
 *       ugyanabban a tranzakcióban.</li>
 * </ol>
 *
 * <p>Biztonsági invariánsok: tenant-assert (parent customer/transaction a hívó cégéé)
 * a PIN- és grant-lookup ELŐTT (cross-tenant → 404, nem 403). PII sosem app-logban —
 * csak id-k. A grant documentId-kötött: egy wrong-document próbálkozás NEM éget el
 * grantot (a documentId-scoped lookup előbb szűr).</p>
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class DocumentViewGrantService {

    /** Engedélyezésre jogosult szerepek — az FS-2 SENIOR_APPROVER_ROLES tükrözése. */
    private static final Set<WorkerRole> APPROVER_ROLES =
            EnumSet.of(WorkerRole.SUPERVISOR, WorkerRole.MANAGER, WorkerRole.ADMIN);
    /** Rövid lejárat: a megtekintés azonnali; nem offline-sync eset (vö. AML 7 nap). */
    private static final int GRANT_VALIDITY_MINUTES = 10;

    private final DocumentViewGrantRepository grantRepository;
    private final ScannedDocumentRepository scannedDocumentRepository;
    private final ScannedDocumentImageRepository imageRepository;
    private final CustomerRepository customerRepository;
    private final TransactionRepository transactionRepository;
    private final WorkerRepository workerRepository;
    private final SupervisorPinService supervisorPinService;
    private final AuditLogService auditLogService;

    @Transactional
    public void issueViewGrant(UUID documentId, Long approverWorkerId, String pin,
            String clientIp, String userAgent) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        ScannedDocument doc = requireDocumentInCurrentCompany(documentId);
        Worker approver = workerRepository.findByIdAndCompanyId(approverWorkerId, companyId)
                .filter(w -> w.getRole() != null && APPROVER_ROLES.contains(w.getRole()))
                .orElseThrow(() -> new ValidationException(
                        "Az engedélyező nem jogosult okmány-nagyítás engedélyezésére (supervisor/manager/admin szükséges)."));
        if (!supervisorPinService.verifyPin(approverWorkerId, pin, clientIp, userAgent)) {
            throw new ValidationException("Hibás PIN");
        }
        LocalDateTime now = LocalDateTime.now();
        grantRepository.save(DocumentViewGrant.builder()
                .companyId(companyId)
                .requesterWorkerId(SecurityUtils.getCurrentWorkerId())
                .approverWorkerId(approverWorkerId)
                .documentId(doc.getId())
                .createdAt(now)
                .expiresAt(now.plusMinutes(GRANT_VALIDITY_MINUTES))
                .usesRemaining(1)
                .build());
        // PII nem app-logba: csak id-k.
        log.info("[DOC-VIEW] Nagyítás-grant kiállítva — doc={}, approver #{}, requester #{}",
                doc.getId(), approverWorkerId, SecurityUtils.getCurrentWorkerId());
    }

    @Transactional
    public DocumentScannerService.ImagePayload serveFullImage(UUID documentId, DocumentSide side) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long requesterWorkerId = SecurityUtils.getCurrentWorkerId();
        ScannedDocument doc = requireDocumentInCurrentCompany(documentId);
        // FAIL-CLOSED kapu: érvényes, fel nem használt, EHHEZ a dokumentumhoz kötött grant kell.
        List<DocumentViewGrant> grants = grantRepository.findActiveForDocument(
                companyId, requesterWorkerId, doc.getId(), LocalDateTime.now());
        DocumentViewGrant consumed = grants.stream()
                .filter(g -> grantRepository.decrementIfAvailable(
                        g.getId(), companyId, requesterWorkerId) == 1)
                .findFirst()
                .orElseThrow(() -> new org.springframework.security.access.AccessDeniedException(
                        "Az okmány nagyításához engedélyezés szükséges."));
        ScannedDocumentImage img = imageRepository.findByScannedDocumentIdAndSide(doc.getId(), side)
                .orElseThrow(() -> new ResourceNotFoundException("Okmánykép nem található"));
        // Audit MÉG a kiszolgálás előtt, ugyanabban a tranzakcióban (törvényi nyom).
        auditLogService.log("DOCUMENT_FULLRES_VIEW", "ScannedDocument", doc.getId().toString(),
                String.valueOf(requesterWorkerId), SecurityUtils.getCurrentWorkerCode(),
                null, null,
                "side=" + side + "; grantId=" + consumed.getId()
                        + "; approverWorkerId=" + consumed.getApproverWorkerId(),
                null, null);
        log.info("[DOC-VIEW] Full-res kiszolgálva — doc={}, side={}, worker #{}",
                doc.getId(), side, requesterWorkerId);
        return new DocumentScannerService.ImagePayload(img.getMimeType(), img.getFileData());
    }

    /** Tenant-gát: a dokumentum szülője (customer/transaction) a hívó cégéé — a meglévő minta. */
    private ScannedDocument requireDocumentInCurrentCompany(UUID documentId) {
        ScannedDocument doc = scannedDocumentRepository.findById(documentId)
                .filter(d -> !Boolean.TRUE.equals(d.getIsDeleted()))
                .orElseThrow(() -> new ResourceNotFoundException("Dokumentum nem található: " + documentId));
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        boolean viaCustomer = doc.getCustomerId() != null
                && customerRepository.existsByIdAndCompany_Id(doc.getCustomerId(), companyId);
        boolean viaTransaction = doc.getTransactionId() != null
                && transactionRepository.findByIdAndCompanyId(doc.getTransactionId(), companyId).isPresent();
        if (!viaCustomer && !viaTransaction) {
            throw new ResourceNotFoundException("Dokumentum nem található: " + documentId);
        }
        return doc;
    }
}
