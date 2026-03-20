package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Kamera export szolgáltatás — 4-eyes jóváhagyással, manifest generálással,
 * chain-of-custody naplózással.
 *
 * Folyamat:
 * 1. Export kérelem (indoklás + időszak + opcionális bizonylatszám)
 * 2. Jóváhagyás (4-eyes: más személy, mint a kérelmező)
 * 3. Export végrehajtás (szegmensek + manifest + hash lista)
 * 4. Chain-of-custody naplózás minden lépésnél
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CameraExportService {

    private final CameraExportRequestRepository exportRepository;
    private final ChainOfCustodyRepository custodyRepository;
    private final CameraSegmentHashRepository hashRepository;
    private final CameraRecordingRepository recordingRepository;
    private final CameraEncryptionService encryptionService;
    private final AuditLogService auditLogService;

    @Value("${camera.export.baseDir:C:/valuta/camera-exports}")
    private String exportBaseDir;

    // === 1. KÉRELEM ===

    @Transactional
    public CameraExportRequest createExportRequest(UUID branchId, String cameraId,
                                                     LocalDateTime from, LocalDateTime to,
                                                     String reason, String referenceNumber) {
        if (reason == null || reason.isBlank()) {
            throw new ValidationException("Export indoklás kötelező!");
        }
        if (from.isAfter(to)) {
            throw new ValidationException("Kezdő dátum nem lehet később mint a záró dátum!");
        }

        String requestedBy = SecurityUtils.getCurrentWorkerCode();

        CameraExportRequest request = CameraExportRequest.builder()
            .branchId(branchId)
            .cameraId(cameraId)
            .periodFrom(from)
            .periodTo(to)
            .reason(reason)
            .referenceNumber(referenceNumber)
            .requestedBy(requestedBy)
            .build();

        CameraExportRequest saved = exportRepository.save(request);

        // Chain of Custody
        recordCustodyEvent(saved.getId(), branchId, cameraId,
            CustodyEventType.EXPORT_REQUESTED, requestedBy,
            String.format("Export kérelem: %s → %s, indok: %s", from, to, reason),
            from, to);

        auditLogService.log("CAMERA_EXPORT_REQUESTED",
            String.format("Export kérelem: branch=%s, camera=%s, %s → %s", branchId, cameraId, from, to),
            branchId.toString());

        log.info("Export kérelem létrehozva: id={}, branch={}, camera={}, {} → {}",
            saved.getId(), branchId, cameraId, from, to);

        return saved;
    }

    // === 2. JÓVÁHAGYÁS (4-eyes) ===

    @Transactional
    public CameraExportRequest approveExport(UUID requestId) {
        CameraExportRequest request = findRequest(requestId);

        if (request.getStatus() != CameraExportStatus.REQUESTED) {
            throw new ValidationException("Jóváhagyás csak REQUESTED státuszú kérelemre lehetséges!");
        }

        String approver = SecurityUtils.getCurrentWorkerCode();

        // 4-eyes: a jóváhagyó nem lehet ugyanaz, mint a kérelmező
        if (approver.equals(request.getRequestedBy())) {
            throw new ValidationException("4-eyes: a jóváhagyó nem lehet ugyanaz, mint a kérelmező!");
        }

        request.setStatus(CameraExportStatus.APPROVED);
        request.setApprovedBy(approver);
        request.setApprovedAt(LocalDateTime.now());
        exportRepository.save(request);

        recordCustodyEvent(requestId, request.getBranchId(), request.getCameraId(),
            CustodyEventType.EXPORT_APPROVED, approver,
            "Export jóváhagyva", request.getPeriodFrom(), request.getPeriodTo());

        log.info("Export jóváhagyva: id={}, approvedBy={}", requestId, approver);
        return request;
    }

    @Transactional
    public CameraExportRequest rejectExport(UUID requestId, String rejectionReason) {
        CameraExportRequest request = findRequest(requestId);

        if (request.getStatus() != CameraExportStatus.REQUESTED) {
            throw new ValidationException("Elutasítás csak REQUESTED státuszú kérelemre lehetséges!");
        }

        String rejector = SecurityUtils.getCurrentWorkerCode();
        request.setStatus(CameraExportStatus.REJECTED);
        request.setApprovedBy(rejector);
        request.setApprovedAt(LocalDateTime.now());
        request.setRejectionReason(rejectionReason);
        exportRepository.save(request);

        recordCustodyEvent(requestId, request.getBranchId(), request.getCameraId(),
            CustodyEventType.EXPORT_REJECTED, rejector,
            "Export elutasítva: " + rejectionReason, request.getPeriodFrom(), request.getPeriodTo());

        log.info("Export elutasítva: id={}, reason={}", requestId, rejectionReason);
        return request;
    }

    // === 3. EXPORT VÉGREHAJTÁS ===

    @Transactional
    public CameraExportRequest executeExport(UUID requestId) {
        CameraExportRequest request = findRequest(requestId);

        if (request.getStatus() != CameraExportStatus.APPROVED) {
            throw new ValidationException("Export végrehajtás csak APPROVED státuszú kérelemre lehetséges!");
        }

        request.setStatus(CameraExportStatus.EXPORTING);
        exportRepository.save(request);

        String executor = SecurityUtils.getCurrentWorkerCode();
        recordCustodyEvent(requestId, request.getBranchId(), request.getCameraId(),
            CustodyEventType.EXPORT_STARTED, executor,
            "Export indítva", request.getPeriodFrom(), request.getPeriodTo());

        try {
            // Export könyvtár
            String exportDirName = String.format("export_%s_%s",
                request.getId().toString().substring(0, 8),
                LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")));
            Path exportDir = Path.of(exportBaseDir, exportDirName);
            Files.createDirectories(exportDir);

            // Hash-ek lekérése az időszakra
            List<CameraSegmentHash> hashes = hashRepository
                .findByBranchIdAndCameraIdAndCreatedAtBetweenOrderBySequenceNumberAsc(
                    request.getBranchId(), request.getCameraId(),
                    request.getPeriodFrom(), request.getPeriodTo());

            // Szegmens fájlok másolása (visszafejtve, ha titkosított)
            long totalSize = 0;
            List<String> manifestLines = new ArrayList<>();
            manifestLines.add("# Camera Export Manifest");
            manifestLines.add("# Export ID: " + request.getId());
            manifestLines.add("# Branch: " + request.getBranchId());
            manifestLines.add("# Camera: " + request.getCameraId());
            manifestLines.add("# Period: " + request.getPeriodFrom() + " → " + request.getPeriodTo());
            manifestLines.add("# Requested by: " + request.getRequestedBy());
            manifestLines.add("# Approved by: " + request.getApprovedBy());
            manifestLines.add("# Reason: " + request.getReason());
            manifestLines.add("# Reference: " + (request.getReferenceNumber() != null ? request.getReferenceNumber() : "N/A"));
            manifestLines.add("# Generated: " + LocalDateTime.now());
            manifestLines.add("#");
            manifestLines.add("# sequence | file_hash | chain_hash | file_name | size_bytes");

            for (CameraSegmentHash hash : hashes) {
                Path sourceFile = Path.of(hash.getFilePath());
                if (Files.exists(sourceFile)) {
                    String targetFileName = String.format("segment_%05d_%s.mp4",
                        hash.getSequenceNumber(), hash.getFileHash().substring(0, 12));
                    Path targetFile = exportDir.resolve(targetFileName);

                    // Visszafejtés
                    if (encryptionService.isEncryptionEnabled()) {
                        encryptionService.decryptFile(sourceFile, targetFile);
                    } else {
                        Files.copy(sourceFile, targetFile);
                    }

                    long fileSize = Files.size(targetFile);
                    totalSize += fileSize;

                    manifestLines.add(String.format("%d | %s | %s | %s | %d",
                        hash.getSequenceNumber(), hash.getFileHash(), hash.getChainHash(),
                        targetFileName, fileSize));
                } else {
                    log.warn("Export: hiányzó szegmens fájl: {}", hash.getFilePath());
                    manifestLines.add(String.format("%d | %s | %s | MISSING | 0",
                        hash.getSequenceNumber(), hash.getFileHash(), hash.getChainHash()));
                }
            }

            // Manifest fájl írása
            Path manifestFile = exportDir.resolve("manifest.txt");
            Files.write(manifestFile, manifestLines, StandardCharsets.UTF_8);

            // Manifest hash
            String manifestHash = encryptionService.computeFileHash(manifestFile);

            // Hash lista fájl
            Path hashListFile = exportDir.resolve("hash_chain.txt");
            List<String> hashLines = hashes.stream()
                .map(h -> String.format("%d;%s;%s;%s", h.getSequenceNumber(), h.getFileHash(), h.getPreviousHash(), h.getChainHash()))
                .collect(Collectors.toList());
            Files.write(hashListFile, hashLines, StandardCharsets.UTF_8);

            // Request frissítés
            request.setStatus(CameraExportStatus.COMPLETED);
            request.setExportPath(exportDir.toString());
            request.setExportSizeBytes(totalSize);
            request.setManifestHash(manifestHash);
            request.setCompletedAt(LocalDateTime.now());
            exportRepository.save(request);

            recordCustodyEvent(requestId, request.getBranchId(), request.getCameraId(),
                CustodyEventType.EXPORT_COMPLETED, executor,
                String.format("Export kész: %d szegmens, %d byte, manifest hash: %s",
                    hashes.size(), totalSize, manifestHash),
                request.getPeriodFrom(), request.getPeriodTo());

            auditLogService.log("CAMERA_EXPORT_COMPLETED",
                String.format("Export kész: id=%s, %d szegmens, %d byte", requestId, hashes.size(), totalSize),
                request.getBranchId().toString());

            log.info("Export kész: id={}, dir={}, segments={}, size={}, manifestHash={}",
                requestId, exportDir, hashes.size(), totalSize, manifestHash);

        } catch (Exception e) {
            request.setStatus(CameraExportStatus.FAILED);
            request.setErrorMessage(e.getMessage());
            exportRepository.save(request);

            log.error("Export hiba: id={}, error={}", requestId, e.getMessage(), e);

            auditLogService.log("CAMERA_EXPORT_FAILED",
                String.format("Export hiba: id=%s — %s", requestId, e.getMessage()),
                request.getBranchId().toString());
        }

        return request;
    }

    // === 4. LEKÉRDEZÉSEK ===

    @Transactional(readOnly = true)
    public CameraExportRequest getRequest(UUID requestId) {
        return findRequest(requestId);
    }

    @Transactional(readOnly = true)
    public List<CameraExportRequest> getPendingRequests() {
        return exportRepository.findByStatusOrderByCreatedAtAsc(CameraExportStatus.REQUESTED);
    }

    @Transactional(readOnly = true)
    public List<CameraExportRequest> getRequestsByBranch(UUID branchId) {
        return exportRepository.findByBranchIdOrderByCreatedAtDesc(branchId);
    }

    @Transactional(readOnly = true)
    public List<ChainOfCustodyRecord> getCustodyHistory(UUID exportRequestId) {
        return custodyRepository.findByExportRequestIdOrderByEventTimestampAsc(exportRequestId);
    }

    // === HELPERS ===

    private CameraExportRequest findRequest(UUID requestId) {
        return exportRepository.findById(requestId)
            .orElseThrow(() -> new ResourceNotFoundException("Export kérelem nem található: " + requestId));
    }

    private void recordCustodyEvent(UUID exportRequestId, UUID branchId, String cameraId,
                                      CustodyEventType eventType, String actor,
                                      String details, LocalDateTime periodFrom, LocalDateTime periodTo) {
        ChainOfCustodyRecord record = ChainOfCustodyRecord.builder()
            .exportRequestId(exportRequestId)
            .branchId(branchId)
            .cameraId(cameraId)
            .eventType(eventType)
            .actor(actor)
            .eventTimestamp(LocalDateTime.now())
            .details(details)
            .periodFrom(periodFrom)
            .periodTo(periodTo)
            .build();

        custodyRepository.save(record);
    }
}
