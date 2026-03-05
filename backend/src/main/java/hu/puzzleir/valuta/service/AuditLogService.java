package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.AuditLog;
import hu.puzzleir.valuta.repository.AuditLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

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
}
