package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.monitoring.BranchStatusResponse;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.BranchStatus;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.BranchStatusRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Fiók monitoring szolgáltatás — locserver központi szerver.
 * Heartbeat fogadás, online/offline fiókok lekérdezése, dashboard.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class BranchMonitoringService {

    private final BranchStatusRepository branchStatusRepository;
    private final BranchRepository branchRepository;

    /**
     * Heartbeat frissítés — fiók jelzi hogy él.
     */
    @Transactional(rollbackFor = Exception.class)
    public void updateHeartbeat(UUID branchId) {
        BranchStatus status = branchStatusRepository.findByBranchId(branchId)
                .orElseGet(() -> BranchStatus.builder()
                        .branchId(branchId)
                        .build());
        status.setLastHeartbeat(LocalDateTime.now());
        status.setIsOnline(true);
        branchStatusRepository.save(status);
        log.debug("Heartbeat frissítve: branchId={}", branchId);
    }

    /**
     * Online fiókok listája.
     */
    @Transactional(readOnly = true)
    public List<BranchStatusResponse> getOnlineBranches() {
        return branchStatusRepository.findByIsOnlineTrue()
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Offline fiókok listája — nem küldött heartbeat-et a megadott percen belül.
     */
    @Transactional(readOnly = true)
    public List<BranchStatusResponse> getOfflineBranches(int minutesThreshold) {
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(minutesThreshold);
        return branchStatusRepository.findOfflineBranches(threshold)
                .stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    /**
     * Összes fiók dashboard nézete — multi-tenant szűréssel.
     */
    @Transactional(readOnly = true)
    public Map<UUID, BranchStatusResponse> getBranchDashboard() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<UUID> companyBranchIds = branchRepository.findByCompanyId(companyId).stream()
                .map(Branch::getId)
                .collect(Collectors.toList());
        return branchStatusRepository.findByBranchIdIn(companyBranchIds)
                .stream()
                .collect(Collectors.toMap(
                        BranchStatus::getBranchId,
                        this::toResponse
                ));
    }

    private BranchStatusResponse toResponse(BranchStatus entity) {
        return BranchStatusResponse.builder()
                .id(entity.getId())
                .branchId(entity.getBranchId())
                .lastHeartbeat(entity.getLastHeartbeat())
                .lastSync(entity.getLastSync())
                .isOnline(entity.getIsOnline())
                .lastTransactionAt(entity.getLastTransactionAt())
                .dailyTransactionCount(entity.getDailyTransactionCount())
                .dailyVolumeHuf(entity.getDailyVolumeHuf())
                .openAlerts(entity.getOpenAlerts())
                .build();
    }
}
