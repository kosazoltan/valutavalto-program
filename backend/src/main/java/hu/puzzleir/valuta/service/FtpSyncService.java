package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.dto.ftpsync.FtpSyncLogDto;
import hu.puzzleir.valuta.dto.ftpsync.FtpSyncResultDto;
import hu.puzzleir.valuta.entity.FtpSyncLog;
import hu.puzzleir.valuta.repository.FtpSyncLogRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * FTP szinkronizáció szolgáltatás.
 * BRIDGE a régi FTP alapú (port 21100) és az új REST API alapú szinkronizáció között.
 * A régi FTP hívásokat menedzselt storage artifact formátumba fordítja.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class FtpSyncService {

    private final FtpSyncLogRepository ftpSyncLogRepository;
    private final BranchRepository branchRepository;
         private final ExchangeRateRepository exchangeRateRepository;
         private final TransactionRepository transactionRepository;
         private final IntegrationTransportProperties integrationTransportProperties;
         private final FileTransportService fileTransportService;

    /**
     * Árfolyam fájl letöltése (FTP DOWNLOAD).
     */
    @Transactional(rollbackFor = Exception.class)
    public FtpSyncResultDto syncRateFile(UUID branchId) {
        Branch branch = findBranch(branchId);
        LocalDate date = LocalDate.now();
        LocalDateTime startedAt = LocalDateTime.now();

        FtpSyncLog syncLog = FtpSyncLog.builder()
                .branch(branch)
                .direction(FtpSyncLog.FtpSyncDirection.DOWNLOAD)
                .status(FtpSyncLog.FtpSyncStatus.FAILED)
                .startedAt(startedAt)
                .build();
        syncLog = ftpSyncLogRepository.save(syncLog);

        try {
            List<ExchangeRate> rates = exchangeRateRepository.findAllActiveRates(branch.getCompany().getId(), branchId);
            String safeSyncDir = fileTransportService.sanitizePathSegment(
                    integrationTransportProperties.getSync().getDir(), "sync.dir");
            String safeBranchCode = fileTransportService.sanitizePathSegment(branch.getCode(), "branchCode");

            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("branchId", branchId);
            payload.put("branchCode", safeBranchCode);
            payload.put("date", date.toString());
            payload.put("type", "RATES_DOWNLOAD");
            payload.put("count", rates.size());
                        payload.put("items", rates.stream().map(r -> {
                                Map<String, Object> row = new LinkedHashMap<>();
                                row.put("currency", r.getCurrency() != null ? r.getCurrency().getCode() : null);
                                row.put("buyRate", r.getBaseBuyRate());
                                row.put("sellRate", r.getBaseSellRate());
                                row.put("validDate", r.getValidDate());
                                row.put("validTime", r.getValidTime());
                                return row;
                        }).toList());

            Path artifact = fileTransportService.writeJson(
                    Paths.get(safeSyncDir, safeBranchCode, "ftp-rates").toString(),
                    "rates_" + safeBranchCode + "_" + date.format(DateTimeFormatter.BASIC_ISO_DATE),
                    payload
            );

            long fileSize = Files.size(artifact);
            syncLog.setStatus(FtpSyncLog.FtpSyncStatus.SUCCESS);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setFileName(artifact.getFileName().toString());
            syncLog.setFileSizeBytes(fileSize);
            syncLog.setErrorMessage(null);
            syncLog = ftpSyncLogRepository.save(syncLog);

            log.info("FTP rates bridge artifact elkészült: branch={}, file={}, rates={}",
                    branch.getCode(), artifact, rates.size());

            return FtpSyncResultDto.builder()
                    .success(true)
                    .message("Árfolyam artifact sikeresen elkészült")
                    .fileName(syncLog.getFileName())
                    .fileSizeBytes(fileSize)
                    .syncLog(toDto(syncLog))
                    .build();
        } catch (Exception e) {
            syncLog.setStatus(FtpSyncLog.FtpSyncStatus.FAILED);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setErrorMessage(e.getMessage());
            syncLog = ftpSyncLogRepository.save(syncLog);
            log.error("FTP rates bridge sikertelen: branch={}", branch.getCode(), e);

            return FtpSyncResultDto.builder()
                    .success(false)
                    .message("Árfolyam artifact készítése sikertelen: " + e.getMessage())
                    .fileName(syncLog.getFileName())
                    .fileSizeBytes(syncLog.getFileSizeBytes())
                    .syncLog(toDto(syncLog))
                    .build();
        }
    }

    /**
     * Napi jelentés feltöltése (FTP UPLOAD).
     */
    @Transactional(rollbackFor = Exception.class)
    public FtpSyncResultDto uploadDailyReport(UUID branchId, LocalDate date) {
        Branch branch = findBranch(branchId);
        LocalDate effectiveDate = date != null ? date : LocalDate.now();
        FtpSyncLog syncLog = FtpSyncLog.builder()
                .branch(branch)
                .direction(FtpSyncLog.FtpSyncDirection.UPLOAD)
                .status(FtpSyncLog.FtpSyncStatus.FAILED)
                .startedAt(LocalDateTime.now())
                .build();
        syncLog = ftpSyncLogRepository.save(syncLog);

        try {
            List<Transaction> dailyTransactions = transactionRepository.findActiveByBranchAndDate(branchId, effectiveDate);
            String safeSyncDir = fileTransportService.sanitizePathSegment(
                    integrationTransportProperties.getSync().getDir(), "sync.dir");
            String safeBranchCode = fileTransportService.sanitizePathSegment(branch.getCode(), "branchCode");

            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("branchId", branchId);
            payload.put("branchCode", safeBranchCode);
            payload.put("reportDate", effectiveDate.toString());
            payload.put("transactionCount", dailyTransactions.size());
            payload.put("generatedAt", LocalDateTime.now().toString());

            Path artifact = fileTransportService.writeJson(
                    Paths.get(safeSyncDir, safeBranchCode, "ftp-daily-reports").toString(),
                    "daily_" + safeBranchCode + "_" + effectiveDate.format(DateTimeFormatter.BASIC_ISO_DATE),
                    payload
            );

            long fileSize = Files.size(artifact);
            syncLog.setStatus(FtpSyncLog.FtpSyncStatus.SUCCESS);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setFileName(artifact.getFileName().toString());
            syncLog.setFileSizeBytes(fileSize);
            syncLog.setErrorMessage(null);
            syncLog = ftpSyncLogRepository.save(syncLog);

            log.info("FTP daily report bridge artifact elkészült: branch={}, file={}, txCount={}",
                    branch.getCode(), artifact, dailyTransactions.size());

            return FtpSyncResultDto.builder()
                    .success(true)
                    .message("Napi riport artifact sikeresen elkészült")
                    .fileName(syncLog.getFileName())
                    .fileSizeBytes(fileSize)
                    .syncLog(toDto(syncLog))
                    .build();
        } catch (Exception e) {
            syncLog.setStatus(FtpSyncLog.FtpSyncStatus.FAILED);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setErrorMessage(e.getMessage());
            syncLog = ftpSyncLogRepository.save(syncLog);
            log.error("FTP daily report bridge sikertelen: branch={}", branch.getCode(), e);

            return FtpSyncResultDto.builder()
                    .success(false)
                    .message("Napi riport artifact készítése sikertelen: " + e.getMessage())
                    .fileName(syncLog.getFileName())
                    .fileSizeBytes(syncLog.getFileSizeBytes())
                    .syncLog(toDto(syncLog))
                    .build();
        }
    }

    /**
     * Tranzakció batch feltöltése (FTP UPLOAD).
     */
    @Transactional(rollbackFor = Exception.class)
    public FtpSyncResultDto uploadTransactionBatch(UUID branchId) {
        Branch branch = findBranch(branchId);
        LocalDateTime startedAt = LocalDateTime.now();
        FtpSyncLog syncLog = FtpSyncLog.builder()
                .branch(branch)
                .direction(FtpSyncLog.FtpSyncDirection.UPLOAD)
                .status(FtpSyncLog.FtpSyncStatus.FAILED)
                .startedAt(startedAt)
                .build();
        syncLog = ftpSyncLogRepository.save(syncLog);

        try {
            List<Transaction> transactions = transactionRepository.findActiveByBranchAndDate(branchId, LocalDate.now());
            String safeSyncDir = fileTransportService.sanitizePathSegment(
                    integrationTransportProperties.getSync().getDir(), "sync.dir");
            String safeBranchCode = fileTransportService.sanitizePathSegment(branch.getCode(), "branchCode");

            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("branchId", branchId);
            payload.put("branchCode", safeBranchCode);
            payload.put("generatedAt", LocalDateTime.now().toString());
            payload.put("count", transactions.size());
                        payload.put("items", transactions.stream().map(tx -> {
                                Map<String, Object> row = new LinkedHashMap<>();
                                row.put("id", tx.getId());
                                row.put("receiptNumber", tx.getReceiptNumber());
                                row.put("transactionType", tx.getTransactionType() != null ? tx.getTransactionType().name() : null);
                                row.put("transactionDate", tx.getTransactionDate());
                                row.put("transactionTime", tx.getTransactionTime());
                                row.put("currencyCode", tx.getCurrency() != null ? tx.getCurrency().getCode() : null);
                                row.put("currencyAmount", tx.getCurrencyAmount());
                                row.put("hufAmount", tx.getHufAmount());
                                row.put("status", tx.getStatus() != null ? tx.getStatus().name() : null);
                                return row;
                        }).toList());

            Path artifact = fileTransportService.writeJson(
                    Paths.get(safeSyncDir, safeBranchCode, "ftp-transactions").toString(),
                    "transactions_" + safeBranchCode + "_" + startedAt.format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")),
                    payload
            );

            long fileSize = Files.size(artifact);
            syncLog.setStatus(FtpSyncLog.FtpSyncStatus.SUCCESS);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setFileName(artifact.getFileName().toString());
            syncLog.setFileSizeBytes(fileSize);
            syncLog.setErrorMessage(null);
            syncLog = ftpSyncLogRepository.save(syncLog);

            log.info("FTP tranzakció bridge artifact elkészült: branch={}, file={}, txCount={}",
                    branch.getCode(), artifact, transactions.size());

            return FtpSyncResultDto.builder()
                    .success(true)
                    .message("Tranzakció batch artifact sikeresen elkészült")
                    .fileName(syncLog.getFileName())
                    .fileSizeBytes(fileSize)
                    .syncLog(toDto(syncLog))
                    .build();
        } catch (Exception e) {
            syncLog.setStatus(FtpSyncLog.FtpSyncStatus.FAILED);
            syncLog.setCompletedAt(LocalDateTime.now());
            syncLog.setErrorMessage(e.getMessage());
            syncLog = ftpSyncLogRepository.save(syncLog);
            log.error("FTP tranzakció bridge sikertelen: branch={}", branch.getCode(), e);

            return FtpSyncResultDto.builder()
                    .success(false)
                    .message("Tranzakció batch artifact készítése sikertelen: " + e.getMessage())
                    .fileName(syncLog.getFileName())
                    .fileSizeBytes(syncLog.getFileSizeBytes())
                    .syncLog(toDto(syncLog))
                    .build();
        }
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
