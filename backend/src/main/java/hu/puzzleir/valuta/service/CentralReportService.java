package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.BranchStatus;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.BranchStatusRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Központi riport generálás — locserver.
 * Összesíti az összes iroda napi/heti/havi forgalmát, készletét és eltéréseit.
 * CSV formátumú kimenetet ad.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CentralReportService {

    private final BranchStatusRepository branchStatusRepository;
    private final BranchRepository branchRepository;

    /**
     * Multi-tenant szűrt BranchStatus lista.
     */
    private List<BranchStatus> getCompanyBranchStatuses() {
        java.util.UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<java.util.UUID> branchIds = branchRepository.findByCompanyId(companyId).stream()
                .map(Branch::getId)
                .toList();
        return branchStatusRepository.findByBranchIdIn(branchIds);
    }

    /**
     * Napi konszolidált riport generálás — CSV.
     */
    @Transactional(readOnly = true)
    public byte[] generateDailyConsolidation(LocalDate date) {
        List<BranchStatus> branches = getCompanyBranchStatuses();
        StringBuilder csv = new StringBuilder();
        csv.append("Fiók ID,Utolsó heartbeat,Online,Napi tranzakció szám,Napi forgalom (HUF),Nyitott riasztások\n");

        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
        for (BranchStatus bs : branches) {
            csv.append(bs.getBranchId()).append(',');
            csv.append(bs.getLastHeartbeat() != null ? bs.getLastHeartbeat().format(dtf) : "").append(',');
            csv.append(bs.getIsOnline() != null && bs.getIsOnline() ? "Igen" : "Nem").append(',');
            csv.append(bs.getDailyTransactionCount()).append(',');
            csv.append(bs.getDailyVolumeHuf() != null ? bs.getDailyVolumeHuf().toPlainString() : "0").append(',');
            csv.append(bs.getOpenAlerts());
            csv.append('\n');
        }

        log.info("Napi konszolidált riport generálva: {}, {} fiók", date, branches.size());
        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Heti riport generálás — CSV.
     */
    @Transactional(readOnly = true)
    public byte[] generateWeeklyReport(LocalDate weekStart) {
        List<BranchStatus> branches = getCompanyBranchStatuses();
        StringBuilder csv = new StringBuilder();
        csv.append("Heti riport kezdete: ").append(weekStart).append("\n");
        csv.append("Fiók ID,Napi tranzakció szám,Napi forgalom (HUF),Online státusz\n");

        for (BranchStatus bs : branches) {
            csv.append(bs.getBranchId()).append(',');
            csv.append(bs.getDailyTransactionCount()).append(',');
            csv.append(bs.getDailyVolumeHuf() != null ? bs.getDailyVolumeHuf().toPlainString() : "0").append(',');
            csv.append(bs.getIsOnline() != null && bs.getIsOnline() ? "Online" : "Offline");
            csv.append('\n');
        }

        log.info("Heti riport generálva: weekStart={}, {} fiók", weekStart, branches.size());
        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Havi riport generálás — CSV.
     */
    @Transactional(readOnly = true)
    public byte[] generateMonthlyReport(YearMonth month) {
        List<BranchStatus> branches = getCompanyBranchStatuses();
        StringBuilder csv = new StringBuilder();
        csv.append("Havi riport: ").append(month).append("\n");
        csv.append("Fiók ID,Napi tranzakció szám,Napi forgalom (HUF),Online státusz,Nyitott riasztások\n");

        BigDecimal totalVolume = BigDecimal.ZERO;
        int totalTransactions = 0;

        for (BranchStatus bs : branches) {
            csv.append(bs.getBranchId()).append(',');
            csv.append(bs.getDailyTransactionCount()).append(',');
            csv.append(bs.getDailyVolumeHuf() != null ? bs.getDailyVolumeHuf().toPlainString() : "0").append(',');
            csv.append(bs.getIsOnline() != null && bs.getIsOnline() ? "Online" : "Offline").append(',');
            csv.append(bs.getOpenAlerts());
            csv.append('\n');

            totalTransactions += bs.getDailyTransactionCount() != null ? bs.getDailyTransactionCount() : 0;
            if (bs.getDailyVolumeHuf() != null) {
                totalVolume = totalVolume.add(bs.getDailyVolumeHuf());
            }
        }

        csv.append("\nÖsszesítés:,,\n");
        csv.append("Összes tranzakció:,").append(totalTransactions).append('\n');
        csv.append("Összes forgalom (HUF):,").append(totalVolume.toPlainString()).append('\n');

        log.info("Havi riport generálva: month={}, {} fiók, összforgalom={}", month, branches.size(), totalVolume);
        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }
}
