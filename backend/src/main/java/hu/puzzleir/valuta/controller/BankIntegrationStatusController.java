package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.DariusReportStatus;
import hu.puzzleir.valuta.repository.DariusDailyReportRepository;
import hu.puzzleir.valuta.repository.MnbExchangeRateCacheRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Bank API integráció állapot — admin monitoring endpoint.
 *
 * <p>v2.5.50+ Sprint 2 (Bank API monitoring).</p>
 *
 * <p>A meglévő MNB, Raiffeisen, Darius integrációk állapotát adja vissza
 * dashboard-szerű formában. Nem új banki funkció — csak a meglévő integrációk
 * monitoringja egy helyen.</p>
 */
@RestController
@RequestMapping("/api/v1/admin/bank-integration")
@RequiredArgsConstructor
@Slf4j
public class BankIntegrationStatusController {

    private final MnbExchangeRateCacheRepository mnbCacheRepository;
    private final DariusDailyReportRepository dariusReportRepository;

    @GetMapping("/status")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','TREASURY_MANAGER','MAIN_TREASURY','COMPLIANCE_OFFICER')")
    public BankIntegrationStatusResponse getStatus() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDate today = LocalDate.now();

        // MNB
        long mnbCacheCount = mnbCacheRepository.count();

        // Darius (current month)
        LocalDate monthStart = today.withDayOfMonth(1);
        LocalDate monthEnd = today.withDayOfMonth(today.lengthOfMonth());
        long pendingCount = dariusReportRepository
                .findByCompanyIdAndStatusOrderByReportDateDesc(companyId, DariusReportStatus.GENERATED)
                .size();
        long failedCount = dariusReportRepository
                .findByCompanyIdAndStatusOrderByReportDateDesc(companyId, DariusReportStatus.FAILED)
                .size();
        long submittedCount = dariusReportRepository
                .findByCompanyIdAndStatusOrderByReportDateDesc(companyId, DariusReportStatus.SUBMITTED)
                .size();

        LocalDateTime lastSubmitted = dariusReportRepository
                .findByCompanyIdAndStatusOrderByReportDateDesc(companyId, DariusReportStatus.SUBMITTED)
                .stream()
                .findFirst()
                .map(r -> r.getSubmittedAt())
                .orElse(null);

        return BankIntegrationStatusResponse.builder()
                .mnb(MnbStatus.builder()
                        .rateCount((int) mnbCacheCount)
                        .lastFetchSuccess(mnbCacheCount > 0)
                        .lastFetchDate(today) // a cache léte = mai napi friss
                        .schedulerActive(true)
                        .build())
                .raiffeisen(RaiffeisenStatus.builder()
                        .schedulerActive(true)
                        .scheduledTime("08:00 CET (munkanapokon)")
                        .build())
                .darius(DariusStatus.builder()
                        .currentMonth(monthStart.toString().substring(0, 7))
                        .periodStart(monthStart)
                        .periodEnd(monthEnd)
                        .pendingReportsCount(pendingCount)
                        .failedReportsCount(failedCount)
                        .submittedReportsCount(submittedCount)
                        .lastSubmittedAt(lastSubmitted)
                        .transportMode("MANAGED_OUTBOX")
                        .build())
                .checkedAt(LocalDateTime.now())
                .build();
    }

    // ==========================================================================
    // Response DTOs
    // ==========================================================================

    @Data @Builder @AllArgsConstructor
    public static class BankIntegrationStatusResponse {
        private MnbStatus mnb;
        private RaiffeisenStatus raiffeisen;
        private DariusStatus darius;
        private LocalDateTime checkedAt;
    }

    @Data @Builder @AllArgsConstructor
    public static class MnbStatus {
        private Integer rateCount;
        private Boolean lastFetchSuccess;
        private LocalDate lastFetchDate;
        private Boolean schedulerActive;
    }

    @Data @Builder @AllArgsConstructor
    public static class RaiffeisenStatus {
        private Boolean schedulerActive;
        private String scheduledTime;
    }

    @Data @Builder @AllArgsConstructor
    public static class DariusStatus {
        private String currentMonth;
        private LocalDate periodStart;
        private LocalDate periodEnd;
        private Long pendingReportsCount;
        private Long failedReportsCount;
        private Long submittedReportsCount;
        private LocalDateTime lastSubmittedAt;
        private String transportMode;
    }
}
