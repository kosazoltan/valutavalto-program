package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.TransferDocument;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.repository.TransferDocumentRepository;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

/**
 * Értékszállítási bizonylat szolgáltatás.
 * Workflow: PENDING → PICKED_UP → DELIVERED → CONFIRMED
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class TransferDocumentService {

    private final TransferDocumentRepository transferDocumentRepository;
    private final WorkerRepository workerRepository;
    private final CompanyRepository companyRepository;
    private final PasswordEncoder passwordEncoder;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyyMMdd");

    // ============ WORKFLOW ============

    /**
     * Bizonylat létrehozása → PENDING
     */
    @Transactional(rollbackFor = Exception.class)
    public TransferDocument createTransfer(Long senderId, String currencyCode, BigDecimal quantity,
                                           String sourceType, String sourceId,
                                           String destinationType, String destinationId,
                                           String courierPin, String notes) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new ResourceNotFoundException("Company nem található"));
        Worker sender = workerRepository.findById(senderId)
                .orElseThrow(() -> new ResourceNotFoundException("Átadó dolgozó nem található: " + senderId));

        String documentNumber = generateDocumentNumber();
        String pinHash = (courierPin != null && !courierPin.isBlank())
                ? passwordEncoder.encode(courierPin) : null;

        TransferDocument doc = TransferDocument.builder()
                .company(company)
                .documentNumber(documentNumber)
                .sender(sender)
                .sourceType(sourceType)
                .sourceId(sourceId)
                .destinationType(destinationType)
                .destinationId(destinationId)
                .currencyCode(currencyCode)
                .quantity(quantity)
                .status(TransferDocument.Status.PENDING)
                .createdAt(LocalDateTime.now())
                .courierPinHash(pinHash)
                .notes(notes)
                .build();

        TransferDocument saved = transferDocumentRepository.save(doc);
        log.info("TransferDocument létrehozva: {} - {} {} {} → {}",
                documentNumber, quantity, currencyCode, sourceType, destinationType);
        return saved;
    }

    /**
     * Értékszállító átveszi → PICKED_UP (PIN ellenőrzéssel)
     */
    @Transactional(rollbackFor = Exception.class)
    public TransferDocument courierPickup(Long docId, Long courierId, String courierPin) {
        TransferDocument doc = findAndValidate(docId, TransferDocument.Status.PENDING);
        Worker courier = workerRepository.findById(courierId)
                .orElseThrow(() -> new ResourceNotFoundException("Értékszállító nem található: " + courierId));

        // PIN ellenőrzés
        if (doc.getCourierPinHash() != null) {
            if (courierPin == null || !passwordEncoder.matches(courierPin, doc.getCourierPinHash())) {
                throw new ValidationException("Hibás értékszállítói PIN!");
            }
        }

        doc.setCourier(courier);
        doc.setStatus(TransferDocument.Status.PICKED_UP);
        doc.setPickedUpAt(LocalDateTime.now());

        TransferDocument saved = transferDocumentRepository.save(doc);
        log.info("TransferDocument PICKED_UP: {} courier={}",
                doc.getDocumentNumber(), courierId);
        return saved;
    }

    /**
     * Értékszállító átadja → DELIVERED
     */
    @Transactional(rollbackFor = Exception.class)
    public TransferDocument courierDeliver(Long docId) {
        TransferDocument doc = findAndValidate(docId, TransferDocument.Status.PICKED_UP);

        doc.setStatus(TransferDocument.Status.DELIVERED);
        doc.setDeliveredAt(LocalDateTime.now());

        TransferDocument saved = transferDocumentRepository.save(doc);
        log.info("TransferDocument DELIVERED: {}", doc.getDocumentNumber());
        return saved;
    }

    /**
     * Átvevő megerősíti → CONFIRMED
     */
    @Transactional(rollbackFor = Exception.class)
    public TransferDocument receiverConfirm(Long docId, Long receiverId) {
        TransferDocument doc = findAndValidate(docId, TransferDocument.Status.DELIVERED);
        Worker receiver = workerRepository.findById(receiverId)
                .orElseThrow(() -> new ResourceNotFoundException("Átvevő dolgozó nem található: " + receiverId));

        doc.setReceiver(receiver);
        doc.setStatus(TransferDocument.Status.CONFIRMED);
        doc.setConfirmedAt(LocalDateTime.now());

        TransferDocument saved = transferDocumentRepository.save(doc);
        log.info("TransferDocument CONFIRMED: {} receiver={}",
                doc.getDocumentNumber(), receiverId);
        return saved;
    }

    // ============ LEKÉRDEZÉSEK ============

    @Transactional(readOnly = true)
    public TransferDocument getById(Long id) {
        return transferDocumentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Bizonylat nem található: " + id));
    }

    @Transactional(readOnly = true)
    public List<TransferDocument> findFiltered(TransferDocument.Status status, Long courierId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return transferDocumentRepository.findFiltered(companyId, status, courierId);
    }

    // ============ BELSŐ ============

    private TransferDocument findAndValidate(Long docId, TransferDocument.Status expectedStatus) {
        TransferDocument doc = transferDocumentRepository.findById(docId)
                .orElseThrow(() -> new ResourceNotFoundException("Bizonylat nem található: " + docId));
        if (doc.getStatus() != expectedStatus) {
            throw new ValidationException(
                    "Érvénytelen státusz: " + doc.getStatus() + " (várt: " + expectedStatus + ")");
        }
        return doc;
    }

    private String generateDocumentNumber() {
        String dateStr = LocalDate.now().format(DATE_FMT);
        Long nextSeq = transferDocumentRepository.getNextTransferDocSequence();
        return String.format("SZ-%s-%04d", dateStr, nextSeq);
    }
}
