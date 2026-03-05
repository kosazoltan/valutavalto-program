package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AuditLogService {

    private final AuditLogRepository auditLogRepository;

    @Transactional
    public void log(String action, String entityType, String entityId,
                    String userId, String userName, String branchId, String branchName,
                    String changes, String ipAddress, String userAgent) {
        AuditLog entry = AuditLog.builder()
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

    public Page<AuditLog> getSystemLogs(LocalDateTime from, LocalDateTime to, Pageable pageable) {
        return auditLogRepository.findByDateRange(from, to, pageable);
    }

    // POS and NAV logs use the same table with different entityType filters
    public Page<AuditLog> getPosLogs(LocalDateTime from, LocalDateTime to, Pageable pageable) {
        return auditLogRepository.findByDateRange(from, to, pageable);
    }

    public Page<AuditLog> getNavLogs(LocalDateTime from, LocalDateTime to, Pageable pageable) {
        return auditLogRepository.findByDateRange(from, to, pageable);
    }

    /**
     * Logok exportálása CSV formátumban.
     */
    @Transactional(readOnly = true)
    public byte[] exportLogsCsv(LocalDateTime from, LocalDateTime to) {
        List<AuditLog> logs = auditLogRepository.findAllByDateRange(from, to);
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
}
