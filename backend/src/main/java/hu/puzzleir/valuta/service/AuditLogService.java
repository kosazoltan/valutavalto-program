package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.audit.AuditLogEntryDto;
import hu.puzzleir.valuta.dto.audit.AuditSearchCriteria;
import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;

    /** Resolve current company ID from security context (nullable for system/background tasks). */
    private UUID resolveCompanyId() {
        try {
            return SecurityUtils.getCurrentCompanyId();
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Egyszerűsített audit log — action + message + entityId (String).
     * SecurityContext-ből tölti ki a user/branch adatokat.
     */
    @Transactional(rollbackFor = Exception.class)
    public void log(String action, String message, String entityId) {
        log(action, "SYSTEM", entityId,
            null, null, null, null, message, null, null);
    }

    /**
     * Egyszerűsített audit log — action + message + entityId (Long).
     */
    @Transactional(rollbackFor = Exception.class)
    public void log(String action, String message, Long entityId) {
        log(action, "SYSTEM", entityId != null ? entityId.toString() : null,
            null, null, null, null, message, null, null);
    }

    @Transactional(rollbackFor = Exception.class)
    public void log(String action, String entityType, String entityId,
                    String userId, String userName, String branchId, String branchName,
                    String changes, String ipAddress, String userAgent) {
        AuditLog entry = AuditLog.builder()
                .companyId(resolveCompanyId())
                .action(action)
                .entityType(entityType)
                .entityId(entityId)
                .userId(userId)
                .userName(userName)
                .branchId(branchId)
                .branchName(branchName)
                .changes(changes)
                .ipAddress(ipAddress)
                .userAgent(userAgent)
                .build();
        auditLogRepository.save(entry);
    }

    /**
     * Bővített audit log — oldValue/newValue JSON + reason mező.
     */
    @Transactional(rollbackFor = Exception.class)
    public void logWithDetails(String action, String entityType, String entityId,
                               String userId, String userName, String branchId, String branchName,
                               String oldValue, String newValue, String reason,
                               String ipAddress) {
        AuditLog entry = AuditLog.builder()
                .companyId(resolveCompanyId())
                .action(action)
                .entityType(entityType)
                .entityId(entityId)
                .userId(userId)
                .userName(userName)
                .branchId(branchId)
                .branchName(branchName)
                .oldValue(oldValue)
                .newValue(newValue)
                .reason(reason)
                .ipAddress(ipAddress)
                .build();
        auditLogRepository.save(entry);
    }

    /**
     * Ellenőrzi, hogy adott action + entityId kombinációra létezik-e audit log bejegyzés.
     * Év-nyitó idempotencia-ellenőrzéshez.
     */
    @Transactional(readOnly = true)
    public boolean existsByActionAndReference(String action, String reference) {
        UUID companyId = resolveCompanyId();
        if (companyId == null) {
            return auditLogRepository.existsByActionAndEntityId(action, reference);
        }
        return auditLogRepository.existsByCompanyIdAndActionAndEntityId(companyId, action, reference);
    }

    public List<AuditLog> getByEntity(String entityId) {
        UUID companyId = resolveCompanyId();
        return auditLogRepository.findByCompanyIdAndEntityIdOrderByCreatedAtDesc(companyId, entityId);
    }

    public Page<AuditLog> getByWorker(String workerId, LocalDateTime from, LocalDateTime to, Pageable pageable) {
        UUID companyId = resolveCompanyId();
        return auditLogRepository.findByWorker(companyId, workerId, from, to, pageable);
    }

    public Page<AuditLog> getByBranch(String branchId, LocalDateTime from, LocalDateTime to, Pageable pageable) {
        UUID companyId = resolveCompanyId();
        return auditLogRepository.findByBranch(companyId, branchId, from, to, pageable);
    }

    public Page<AuditLog> getByAction(String action, LocalDateTime from, LocalDateTime to, Pageable pageable) {
        UUID companyId = resolveCompanyId();
        return auditLogRepository.findByAction(companyId, action, from, to, pageable);
    }

    public Page<AuditLog> getSystemLogs(LocalDateTime from, LocalDateTime to, Pageable pageable) {
        UUID companyId = resolveCompanyId();
        return auditLogRepository.findByDateRange(companyId, from, to, pageable);
    }

    // POS and NAV logs use the same table with different entityType filters
    public Page<AuditLog> getPosLogs(LocalDateTime from, LocalDateTime to, Pageable pageable) {
        UUID companyId = resolveCompanyId();
        return auditLogRepository.findByDateRange(companyId, from, to, pageable);
    }

    public Page<AuditLog> getNavLogs(LocalDateTime from, LocalDateTime to, Pageable pageable) {
        UUID companyId = resolveCompanyId();
        return auditLogRepository.findByDateRange(companyId, from, to, pageable);
    }

    /**
     * Logok exportálása CSV formátumban.
     */
    @Transactional(readOnly = true)
    public byte[] exportLogsCsv(LocalDateTime from, LocalDateTime to) {
        UUID companyId = resolveCompanyId();
        List<AuditLog> logs = auditLogRepository.findAllByDateRange(companyId, from, to);
        StringBuilder csv = new StringBuilder();
        csv.append("id,action,entityType,entityId,userId,userName,branchId,branchName,changes,ipAddress,userAgent,createdAt\n");

        DateTimeFormatter dtf = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
        for (AuditLog log : logs) {
            csv.append(escapeCsv(log.getId() != null ? log.getId().toString() : "")).append(',');
            csv.append(escapeCsv(log.getAction())).append(',');
            csv.append(escapeCsv(log.getEntityType())).append(',');
            csv.append(escapeCsv(log.getEntityId())).append(',');
            csv.append(escapeCsv(log.getUserId())).append(',');
            csv.append(escapeCsv(log.getUserName())).append(',');
            csv.append(escapeCsv(log.getBranchId())).append(',');
            csv.append(escapeCsv(log.getBranchName())).append(',');
            csv.append(escapeCsv(log.getChanges())).append(',');
            csv.append(escapeCsv(log.getIpAddress())).append(',');
            csv.append(escapeCsv(log.getUserAgent())).append(',');
            csv.append(log.getCreatedAt() != null ? log.getCreatedAt().format(dtf) : "");
            csv.append('\n');
        }

        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }

    private String escapeCsv(String value) {
        if (value == null) return "";
        if (value.contains(",") || value.contains("\"") || value.contains("\n")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }

    // ====================================================================
    // Batch 6B — Bővített audit trail metódusok
    // ====================================================================

    /**
     * Általános művelet naplózása.
     */
    @Transactional(rollbackFor = Exception.class)
    public void logAction(String entityType, UUID entityId, String action, String details, Long workerId) {
        log.debug("Audit logAction: {} {} {} workerId={}", action, entityType, entityId, workerId);
        AuditLog entry = AuditLog.builder()
                .action(action)
                .entityType(entityType)
                .entityId(entityId != null ? entityId.toString() : null)
                .userId(workerId != null ? workerId.toString() : null)
                .changes(details)
                .build();
        auditLogRepository.save(entry);
    }

    /**
     * Tranzakció esemény naplózása (létrehozás/módosítás/stornó).
     */
    @Transactional(rollbackFor = Exception.class)
    public void logTransactionEvent(UUID transactionId, String event) {
        log.debug("Audit logTransactionEvent: {} {}", transactionId, event);
        AuditLog entry = AuditLog.builder()
                .action(event)
                .entityType("TRANSACTION")
                .entityId(transactionId != null ? transactionId.toString() : null)
                .changes("Tranzakció esemény: " + event)
                .build();
        auditLogRepository.save(entry);
    }

    /**
     * Árfolyam változás naplózása.
     */
    @Transactional(rollbackFor = Exception.class)
    public void logRateChange(String currency, BigDecimal oldRate, BigDecimal newRate, Long workerId) {
        log.debug("Audit logRateChange: {} {} -> {} workerId={}", currency, oldRate, newRate, workerId);
        AuditLog entry = AuditLog.builder()
                .action("RATE_CHANGE")
                .entityType("EXCHANGE_RATE")
                .entityId(currency)
                .userId(workerId != null ? workerId.toString() : null)
                .oldValue(oldRate != null ? oldRate.toPlainString() : null)
                .newValue(newRate != null ? newRate.toPlainString() : null)
                .changes(String.format("Árfolyam módosítás: %s %s -> %s", currency, oldRate, newRate))
                .build();
        auditLogRepository.save(entry);
    }

    /**
     * Biztonsági esemény naplózása.
     */
    @Transactional(rollbackFor = Exception.class)
    public void logSecurityEvent(String eventType, String details, String ipAddress) {
        log.debug("Audit logSecurityEvent: {} ip={}", eventType, ipAddress);
        AuditLog entry = AuditLog.builder()
                .action(eventType)
                .entityType("SECURITY")
                .changes(details)
                .ipAddress(ipAddress)
                .build();
        auditLogRepository.save(entry);
    }

    /**
     * Entitás audit trail lekérdezése (entityType + entityId alapján).
     */
    @Transactional(readOnly = true)
    public List<AuditLogEntryDto> getAuditTrail(String entityType, String entityId) {
        UUID companyId = resolveCompanyId();
        List<AuditLog> logs = auditLogRepository.findByCompanyIdAndEntityTypeAndEntityIdOrderByCreatedAtDesc(companyId, entityType, entityId);
        return logs.stream().map(this::toDto).toList();
    }

    /**
     * Összetett keresés az audit logban.
     */
    @Transactional(readOnly = true)
    public Page<AuditLogEntryDto> searchAuditLog(AuditSearchCriteria criteria, Pageable pageable) {
        UUID companyId = resolveCompanyId();
        return auditLogRepository.searchAuditLog(
                companyId,
                criteria.getDateFrom(),
                criteria.getDateTo(),
                criteria.getWorkerId(),
                criteria.getEntityType(),
                criteria.getAction(),
                criteria.getKeyword(),
                pageable
        ).map(this::toDto);
    }

    /**
     * Worker szerinti keresés DTO-val.
     */
    @Transactional(readOnly = true)
    public Page<AuditLogEntryDto> getByWorkerDto(String workerId, LocalDateTime from, LocalDateTime to, Pageable pageable) {
        UUID companyId = resolveCompanyId();
        return auditLogRepository.findByWorker(companyId, workerId, from, to, pageable).map(this::toDto);
    }

    /**
     * Bővített CSV export — oldValue/newValue/reason mezőkkel.
     */
    @Transactional(readOnly = true)
    public byte[] exportFullCsv(LocalDateTime from, LocalDateTime to) {
        UUID companyId = resolveCompanyId();
        List<AuditLog> logs = auditLogRepository.findAllByDateRange(companyId, from, to);
        StringBuilder csv = new StringBuilder();
        csv.append("id,action,entityType,entityId,userId,userName,branchId,branchName,changes,oldValue,newValue,reason,ipAddress,createdAt\n");

        DateTimeFormatter dtf = DateTimeFormatter.ISO_LOCAL_DATE_TIME;
        for (AuditLog l : logs) {
            csv.append(escapeCsv(l.getId() != null ? l.getId().toString() : "")).append(',');
            csv.append(escapeCsv(l.getAction())).append(',');
            csv.append(escapeCsv(l.getEntityType())).append(',');
            csv.append(escapeCsv(l.getEntityId())).append(',');
            csv.append(escapeCsv(l.getUserId())).append(',');
            csv.append(escapeCsv(l.getUserName())).append(',');
            csv.append(escapeCsv(l.getBranchId())).append(',');
            csv.append(escapeCsv(l.getBranchName())).append(',');
            csv.append(escapeCsv(l.getChanges())).append(',');
            csv.append(escapeCsv(l.getOldValue())).append(',');
            csv.append(escapeCsv(l.getNewValue())).append(',');
            csv.append(escapeCsv(l.getReason())).append(',');
            csv.append(escapeCsv(l.getIpAddress())).append(',');
            csv.append(l.getCreatedAt() != null ? l.getCreatedAt().format(dtf) : "");
            csv.append('\n');
        }

        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }

    // --- Mapper ---
    private AuditLogEntryDto toDto(AuditLog log) {
        return AuditLogEntryDto.builder()
                .id(log.getId())
                .action(log.getAction())
                .entityType(log.getEntityType())
                .entityId(log.getEntityId())
                .userId(log.getUserId())
                .userName(log.getUserName())
                .branchId(log.getBranchId())
                .branchName(log.getBranchName())
                .changes(log.getChanges())
                .oldValue(log.getOldValue())
                .newValue(log.getNewValue())
                .reason(log.getReason())
                .ipAddress(log.getIpAddress())
                .userAgent(log.getUserAgent())
                .createdAt(log.getCreatedAt())
                .build();
    }
}
