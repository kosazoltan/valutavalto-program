package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.ftpsync.FtpSyncLogDto;
import hu.puzzleir.valuta.dto.ftpsync.FtpSyncResultDto;
import hu.puzzleir.valuta.entity.FtpSyncLog;
import hu.puzzleir.valuta.repository.FtpSyncLogRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * FTP szinkronizáció szolgáltatás.
 * BRIDGE a régi FTP alapú (port 21100) és az új REST API alapú szinkronizáció között.
 * Egyelőre mock/log implementáció — a tényleges FTP kommunikáció később kerül be.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FtpSyncService {

    private final FtpSyncLogRepository ftpSyncLogRepository;
    private final BranchRepository branchRepository;

    /**
     * Árfolyam fájl letöltése (FTP DOWNLOAD).
     */
    @Transactional
    public FtpSyncResultDto syncRateFile(UUID branchId) {
        Branch branch = findBranch(branchId);
        String fileName = "rates_" + branch.getCode() + "_" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE) + ".dat";

        FtpSyncLog syncLog = FtpSyncLog.builder()
                .branch(branch)
                .direction(FtpSyncLog.FtpSyncDirection.DOWNLOAD)
                .fileName(fileName)
                .status(FtpSyncLog.FtpSyncStatus.SUCCESS)
                .startedAt(LocalDateTime.now())
                .completedAt(LocalDateTime.now())
                .fileSizeBytes(1024L)
                .build();

        syncLog = ftpSyncLogRepository.save(syncLog);
        log.info("FTP árfolyam fájl letöltve (mock): branch={}, file={}", branch.getCode(), fileName);

        return FtpSyncResultDto.builder()
                .success(true)
                .message("Árfolyam fájl sikeresen letöltve (mock)")
                .fileName(fileName)
                .fileSizeBytes(1024L)
                .syncLog(toDto(syncLog))
                .build();
    }

    /**
     * Napi jelentés feltöltése (FTP UPLOAD).
     */
    @Transactional
    public FtpSyncResultDto uploadDailyReport(UUID branchId, LocalDate date) {
        Branch branch = findBranch(branchId);
        LocalDate effectiveDate = date != null ? date : LocalDate.now();
        String fileName = "daily_" + branch.getCode() + "_" + effectiveDate.format(DateTimeFormatter.BASIC_ISO_DATE) + ".xml";

        FtpSyncLog syncLog = FtpSyncLog.builder()
                .branch(branch)
                .direction(FtpSyncLog.FtpSyncDirection.UPLOAD)
                .fileName(fileName)
                .status(FtpSyncLog.FtpSyncStatus.SUCCESS)
                .startedAt(LocalDateTime.now())
                .completedAt(LocalDateTime.now())
                .fileSizeBytes(2048L)
                .build();

        syncLog = ftpSyncLogRepository.save(syncLog);
        log.info("FTP napi jelentés feltöltve (mock): branch={}, file={}", branch.getCode(), fileName);

        return FtpSyncResultDto.builder()
                .success(true)
                .message("Napi jelentés sikeresen feltöltve (mock)")
                .fileName(fileName)
                .fileSizeBytes(2048L)
                .syncLog(toDto(syncLog))
                .build();
    }

    /**
     * Tranzakció batch feltöltése (FTP UPLOAD).
     */
    @Transactional
    public FtpSyncResultDto uploadTransactionBatch(UUID branchId) {
        Branch branch = findBranch(branchId);
        String fileName = "transactions_" + branch.getCode() + "_" + LocalDateTime.now().format(
                DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")) + ".csv";

        FtpSyncLog syncLog = FtpSyncLog.builder()
                .branch(branch)
                .direction(FtpSyncLog.FtpSyncDirection.UPLOAD)
                .fileName(fileName)
                .status(FtpSyncLog.FtpSyncStatus.SUCCESS)
                .startedAt(LocalDateTime.now())
                .completedAt(LocalDateTime.now())
                .fileSizeBytes(4096L)
                .build();

        syncLog = ftpSyncLogRepository.save(syncLog);
        log.info("FTP tranzakció batch feltöltve (mock): branch={}, file={}", branch.getCode(), fileName);

        return FtpSyncResultDto.builder()
                .success(true)
                .message("Tranzakció batch sikeresen feltöltve (mock)")
                .fileName(fileName)
                .fileSizeBytes(4096L)
                .syncLog(toDto(syncLog))
                .build();
    }

    /**
     * Szinkronizáció történet lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<FtpSyncLogDto> getSyncHistory(UUID branchId) {
        return ftpSyncLogRepository.findByBranchIdOrderByStartedAtDesc(branchId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ HELPERS ============

    private Branch findBranch(UUID branchId) {
        return branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
    }

    private FtpSyncLogDto toDto(FtpSyncLog s) {
        return FtpSyncLogDto.builder()
                .id(s.getId())
                .branchId(s.getBranch().getId())
                .direction(s.getDirection().name())
                .fileName(s.getFileName())
                .status(s.getStatus().name())
                .fileSizeBytes(s.getFileSizeBytes())
                .startedAt(s.getStartedAt())
                .completedAt(s.getCompletedAt())
                .errorMessage(s.getErrorMessage())
                .build();
    }
}
