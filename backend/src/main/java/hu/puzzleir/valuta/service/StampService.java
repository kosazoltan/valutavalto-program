package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.stamp.*;
import hu.puzzleir.valuta.entity.StampAssignment;
import hu.puzzleir.valuta.entity.StampBatch;
import hu.puzzleir.valuta.repository.StampAssignmentRepository;
import hu.puzzleir.valuta.repository.StampBatchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Matrica pénztár — készlet kezelés, hozzárendelés.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class StampService {

    private final StampBatchRepository batchRepository;
    private final StampAssignmentRepository assignmentRepository;
    private final AuditLogService auditLogService;

    /**
     * Matrica készlet lekérdezés.
     */
    @Transactional(readOnly = true)
    public List<StampBatchDto> getInventory() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<StampBatch> batches = batchRepository.findByCompanyId(companyId);
        return batches.stream()
                .map(b -> StampBatchDto.from(b, assignmentRepository.countByBatchId(b.getId())))
                .collect(Collectors.toList());
    }

    /**
     * Új matrica batch felvétele.
     */
    @Transactional(rollbackFor = Exception.class)
    public StampBatchDto receiveBatch(CreateStampBatchRequest request) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        if (request.getSerialEnd() < request.getSerialStart()) {
            throw new ValidationException("A záró sorszám nem lehet kisebb a kezdőnél!");
        }

        StampBatch batch = StampBatch.builder()
                .companyId(companyId)
                .branchId(request.getBranchId())
                .serialPrefix(request.getSerialPrefix())
                .serialStart(request.getSerialStart())
                .serialEnd(request.getSerialEnd())
                .receivedAt(LocalDateTime.now())
                .receivedBy(SecurityUtils.getCurrentWorkerCode())
                .note(request.getNote())
                .build();

        batch = batchRepository.save(batch);

        String userId = String.valueOf(SecurityUtils.getCurrentWorkerId());
        auditLogService.log(
                "STAMP_BATCH_RECEIVE",
                "STAMP_BATCH",
                batch.getId().toString(),
                userId,
                SecurityUtils.getCurrentWorkerCode(),
                null, null,
                String.format("prefix=%s, range=%d-%d",
                        request.getSerialPrefix(), request.getSerialStart(), request.getSerialEnd()),
                null, null
        );

        log.info("[Stamp] Új batch: {} {}-{}", request.getSerialPrefix(),
                request.getSerialStart(), request.getSerialEnd());

        return StampBatchDto.from(batch, 0);
    }

    /**
     * Matrica hozzárendelés tranzakcióhoz.
     */
    @Transactional(rollbackFor = Exception.class)
    public StampAssignmentDto assignStamp(AssignStampRequest request) {
        // Ellenőrzés: nincs-e már hozzárendelve
        if (assignmentRepository.existsBySerialNumber(request.getSerialNumber())) {
            throw new ValidationException("Ez a matrica sorszám már hozzá van rendelve: " + request.getSerialNumber());
        }

        // Batch keresés a sorszám alapján
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<StampBatch> batches = batchRepository.findByCompanyId(companyId);

        StampBatch matchingBatch = batches.stream()
                .filter(b -> {
                    String prefix = b.getSerialPrefix();
                    if (!request.getSerialNumber().startsWith(prefix + "-")) return false;
                    try {
                        int num = Integer.parseInt(request.getSerialNumber().substring(prefix.length() + 1));
                        return num >= b.getSerialStart() && num <= b.getSerialEnd();
                    } catch (NumberFormatException e) {
                        return false;
                    }
                })
                .findFirst()
                .orElseThrow(() -> new ValidationException(
                        "Nem található matrica batch ehhez a sorszámhoz: " + request.getSerialNumber()));

        StampAssignment assignment = StampAssignment.builder()
                .stampBatch(matchingBatch)
                .serialNumber(request.getSerialNumber())
                .transactionId(request.getTransactionId())
                .assignedAt(LocalDateTime.now())
                .assignedBy(SecurityUtils.getCurrentWorkerCode())
                .build();

        assignment = assignmentRepository.save(assignment);

        log.info("[Stamp] Hozzárendelés: {} → tx={}", request.getSerialNumber(), request.getTransactionId());
        return StampAssignmentDto.from(assignment);
    }

    /**
     * Felhasznált matricák listája.
     */
    @Transactional(readOnly = true)
    public List<StampAssignmentDto> getUsedStamps() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return assignmentRepository.findUsedByCompanyId(companyId).stream()
                .map(StampAssignmentDto::from)
                .collect(Collectors.toList());
    }
}
