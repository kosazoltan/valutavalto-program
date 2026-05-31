package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.CameraRecording;
import hu.puzzleir.valuta.entity.CameraSegmentHash;
import hu.puzzleir.valuta.logging.VVLogger;
import hu.puzzleir.valuta.repository.CameraRecordingRepository;
import hu.puzzleir.valuta.repository.CameraSegmentHashRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Kamera szegmens hash-lánc szolgáltatás.
 *
 * Forenzikus bizonyíték integritás:
 * Minden videó szegmenshez SHA-256 hash készül.
 * A hash-lánc az előző szegmens hash-ét is tartalmazza,
 * így bármely utólagos módosítás detektálható.
 *
 * Hash számítás: SHA-256(previousHash + segmentFileHash + metadata)
 *
 * Ez a lánc lehetővé teszi:
 * - utólagos módosítás detektálása
 * - hiányzó szegmens detektálása
 * - export során a lánc integritásának ellenőrzése
 * - hatósági bizonyítékérték fenntartása
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CameraHashChainService {

    private final CameraSegmentHashRepository hashRepository;
    private final CameraRecordingRepository recordingRepository;
    private final CameraEncryptionService encryptionService;
    private final AuditLogService auditLogService;

    /**
     * V234 belső log+audit (audit P3, 2026-05-31): strukturált error_code minden tamper/hiba
     * eseményhez, hogy a Loki/Grafana audit-keresés error_code='VV-TECH-005..007' szerint
     * lássa a kamera hash-lánc integritás-sérüléseit (forenzikus bizonyítékérték).
     */
    private static final VVLogger VV_LOG = VVLogger.of(CameraHashChainService.class);

    /** A lánc első elemének "előző hash" értéke */
    private static final String GENESIS_HASH = "0000000000000000000000000000000000000000000000000000000000000000";

    /**
     * Új szegmens hozzáadása a hash-lánchoz.
     *
     * @param recording A kamera felvétel entity
     * @param segmentFile A szegmens fájl elérési útja
     * @return A generált hash entity
     */
    @Transactional(rollbackFor = Exception.class)
    public CameraSegmentHash addToChain(CameraRecording recording, Path segmentFile) throws Exception {
        UUID branchId = recording.getBranchId();
        String cameraId = recording.getCameraId();

        // Előző hash lekérése
        String previousHash = getLastHash(branchId, cameraId);

        // Fájl hash
        String fileHash = encryptionService.computeFileHash(segmentFile);

        // Metadata string a hash-be
        String metadata = String.format("%s|%s|%s|%s|%d",
            recording.getId(),
            branchId,
            cameraId,
            recording.getStartTime() != null ? recording.getStartTime().toString() : "null",
            segmentFile.toFile().length());

        // Chain hash = SHA-256(previousHash + fileHash + metadata)
        String chainHash = computeChainHash(previousHash, fileHash, metadata);

        // Sequence number
        int sequenceNumber = hashRepository.countByBranchIdAndCameraId(branchId, cameraId) + 1;

        CameraSegmentHash segmentHash = CameraSegmentHash.builder()
            .recordingId(recording.getId())
            .branchId(branchId)
            .cameraId(cameraId)
            .sequenceNumber(sequenceNumber)
            .fileHash(fileHash)
            .previousHash(previousHash)
            .chainHash(chainHash)
            .filePath(segmentFile.toString())
            .fileSizeBytes(segmentFile.toFile().length())
            .createdAt(LocalDateTime.now())
            .build();

        CameraSegmentHash saved = hashRepository.save(segmentHash);

        log.debug("Hash-lánc bővítve: camera={}, seq={}, chainHash={}...{}",
            cameraId, sequenceNumber,
            chainHash.substring(0, 8), chainHash.substring(chainHash.length() - 8));

        return saved;
    }

    /**
     * Hash-lánc integritás ellenőrzése egy adott kamera teljes láncára.
     *
     * @return true ha a lánc ép, false ha sérült
     */
    @Transactional(readOnly = true)
    public boolean verifyChain(UUID branchId, String cameraId) {
        List<CameraSegmentHash> chain = hashRepository
            .findByBranchIdAndCameraIdOrderBySequenceNumberAsc(branchId, cameraId);

        if (chain.isEmpty()) {
            log.info("Üres hash-lánc: branch={}, camera={}", branchId, cameraId);
            return true;
        }

        String expectedPrevious = GENESIS_HASH;

        for (CameraSegmentHash entry : chain) {
            // Előző hash ellenőrzés
            if (!expectedPrevious.equals(entry.getPreviousHash())) {
                VV_LOG.error("VV-TECH-005", "camera.chain.integrity_failure", null,
                    java.util.Map.of(
                        "branchId", branchId,
                        "cameraId", cameraId,
                        "seq", entry.getSequenceNumber(),
                        "expectedPreviousHash", expectedPrevious,
                        "foundPreviousHash", entry.getPreviousHash()));

                auditLogService.log(
                    "CAMERA_CHAIN_INTEGRITY_FAILURE",
                    String.format("Hash-lánc sérült! camera=%s, seq=%d", cameraId, entry.getSequenceNumber()),
                    branchId.toString()
                );
                return false;
            }

            // Chain hash újraszámítás és ellenőrzés
            String recordingStartTime = recordingRepository.findById(entry.getRecordingId())
                .map(CameraRecording::getStartTime)
                .map(LocalDateTime::toString)
                .orElse("null");

            String metadata = String.format("%s|%s|%s|%s|%d",
                entry.getRecordingId(),
                entry.getBranchId(),
                entry.getCameraId(),
                recordingStartTime,
                entry.getFileSizeBytes());

            String recomputedChainHash;
            try {
                recomputedChainHash = computeChainHash(entry.getPreviousHash(), entry.getFileHash(), metadata);
            } catch (Exception e) {
                VV_LOG.error("VV-TECH-006", "camera.chain.verify_error", e,
                    java.util.Map.of("branchId", branchId, "cameraId", cameraId, "seq", entry.getSequenceNumber()));
                return false;
            }

            if (!recomputedChainHash.equals(entry.getChainHash())) {
                VV_LOG.error("VV-TECH-007", "camera.chain.hash_mismatch", null,
                    java.util.Map.of(
                        "branchId", branchId,
                        "cameraId", cameraId,
                        "seq", entry.getSequenceNumber(),
                        "storedChainHash", entry.getChainHash(),
                        "recomputedChainHash", recomputedChainHash));

                auditLogService.log(
                    "CAMERA_CHAIN_HASH_MISMATCH",
                    String.format("Chain hash mismatch! camera=%s, seq=%d", cameraId, entry.getSequenceNumber()),
                    branchId.toString()
                );
                return false;
            }

            expectedPrevious = entry.getChainHash();
        }

        log.info("Hash-lánc ép: branch={}, camera={}, {} szegmens", branchId, cameraId, chain.size());
        return true;
    }

    /**
     * Adott időszak hash-jeinek lekérése (exporthoz).
     */
    @Transactional(readOnly = true)
    public List<CameraSegmentHash> getHashesForPeriod(UUID branchId, String cameraId,
                                                       LocalDateTime from, LocalDateTime to) {
        return hashRepository.findByBranchIdAndCameraIdAndCreatedAtBetweenOrderBySequenceNumberAsc(
            branchId, cameraId, from, to);
    }

    // === PRIVÁT ===

    private String getLastHash(UUID branchId, String cameraId) {
        return hashRepository
            .findTopByBranchIdAndCameraIdOrderBySequenceNumberDesc(branchId, cameraId)
            .map(CameraSegmentHash::getChainHash)
            .orElse(GENESIS_HASH);
    }

    private String computeChainHash(String previousHash, String fileHash, String metadata) throws Exception {
        String combined = previousHash + "|" + fileHash + "|" + metadata;
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hash = digest.digest(combined.getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : hash) {
            hex.append(String.format("%02x", b));
        }
        return hex.toString();
    }
}
