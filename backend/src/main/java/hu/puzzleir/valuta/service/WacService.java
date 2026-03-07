package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.entity.Company;
import com.puzzleir.backend.exception.ValidationException;
import com.puzzleir.backend.repository.BranchRepository;
import com.puzzleir.backend.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.ProfitLog;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.ProfitLogRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;

/**
 * WAC (Weighted Average Cost) szolgáltatás.
 * Valutakészlet nyilvántartás súlyozott átlagár módszerrel.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class WacService {

    private final CurrencyStockRepository currencyStockRepository;
    private final ProfitLogRepository profitLogRepository;
    private final CompanyRepository companyRepository;
    private final BranchRepository branchRepository;

    /**
     * WAC frissítés amikor valuta érkezik (bank→értéktár, értéktár→pénztár, ügyfél→pénztár).
     */
    @Transactional
    public void receiveStock(String entityType, String entityId, String currencyCode,
                             BigDecimal quantity, BigDecimal costPerUnit) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new IllegalStateException("Company nem található: " + companyId));

        CurrencyStock stock = currencyStockRepository
                .findForUpdate(companyId, entityType, entityId, currencyCode)
                .orElseGet(() -> CurrencyStock.builder()
                        .company(company)
                        .entityType(entityType)
                        .entityId(entityId)
                        .currencyCode(currencyCode)
                        .quantity(BigDecimal.ZERO)
                        .weightedAvgCost(BigDecimal.ZERO)
                        .build());

        stock.receiveStock(quantity, costPerUnit);
        currencyStockRepository.save(stock);

        log.info("WAC receiveStock: {}/{} {} +{} @ {} → WAC={}",
                entityType, entityId, currencyCode, quantity, costPerUnit, stock.getWeightedAvgCost());
    }

    /**
     * WAC-ból kiadás (nem változtatja a WAC-ot, csak csökkenti a mennyiséget).
     * @return a kiadott tételek WAC-ja (ez lesz az átvevő bekerülési ára)
     */
    @Transactional
    public BigDecimal issueStock(String entityType, String entityId, String currencyCode,
                                 BigDecimal quantity) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        CurrencyStock stock = currencyStockRepository
                .findForUpdate(companyId, entityType, entityId, currencyCode)
                .orElseThrow(() -> new IllegalStateException(
                        "Készlet nem található: " + entityType + "/" + entityId + "/" + currencyCode));

        // C-4: Negatív készlet védelem
        if (stock.getQuantity().compareTo(quantity) < 0) {
            throw new ValidationException("Nincs elegendő készlet: " + currencyCode
                    + " (kért: " + quantity + ", elérhető: " + stock.getQuantity() + ")");
        }

        BigDecimal wacAtIssue = stock.issueStock(quantity);
        currencyStockRepository.save(stock);

        log.info("WAC issueStock: {}/{} {} -{} WAC={}",
                entityType, entityId, currencyCode, quantity, wacAtIssue);

        return wacAtIssue;
    }

    /**
     * Profit rögzítés ügyféltranzakciónál.
     * @return realizált profit összeg
     */
    @Transactional
    public BigDecimal recordProfit(UUID branchId, Long transactionId, String currencyCode,
                                   BigDecimal quantity, BigDecimal customerPrice, String txType) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Company company = companyRepository.findById(companyId)
                .orElseThrow(() -> new IllegalStateException("Company nem található: " + companyId));

        // Aktuális WAC lekérdezése a pénztár készletéből
        CurrencyStock stock = currencyStockRepository
                .findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
                        companyId, "CASHIER", branchId.toString(), currencyCode)
                .orElse(null);

        BigDecimal acquisitionCost = (stock != null) ? stock.getWeightedAvgCost() : BigDecimal.ZERO;

        // Profit = (ügyfélár - WAC) × mennyiség
        BigDecimal realizedProfit = customerPrice.subtract(acquisitionCost)
                .multiply(quantity)
                .setScale(2, RoundingMode.HALF_UP);

        ProfitLog profitLog = ProfitLog.builder()
                .company(company)
                .transactionId(transactionId)
                .branchId(branchId)
                .currencyCode(currencyCode)
                .quantity(quantity)
                .acquisitionCost(acquisitionCost)
                .salePrice(customerPrice)
                .realizedProfit(realizedProfit)
                .transactionType(txType)
                .createdAt(LocalDateTime.now())
                .build();

        profitLogRepository.save(profitLog);

        log.info("WAC profit: branch={} tx={} {} {} acq={} sale={} profit={}",
                branchId, transactionId, currencyCode, txType,
                acquisitionCost, customerPrice, realizedProfit);

        return realizedProfit;
    }

    /**
     * Profit összesítés branch-re (pénztárra).
     */
    @Transactional(readOnly = true)
    public ProfitSummary getBranchProfitSummary(UUID branchId, LocalDate from, LocalDate to) {
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.atTime(LocalTime.MAX);

        List<ProfitLog> logs = profitLogRepository.findByBranchIdAndCreatedAtBetween(branchId, fromDt, toDt);
        BigDecimal totalProfit = profitLogRepository.sumProfitByBranch(branchId, fromDt, toDt);

        return buildSummary(logs, totalProfit);
    }

    /**
     * Profit összesítés területre (vault territory-ra).
     */
    @Transactional(readOnly = true)
    public ProfitSummary getTerritoryProfitSummary(Integer territoryId, LocalDate from, LocalDate to) {
        // Területhez tartozó branch-ök keresése
        List<Branch> branches = branchRepository.findByVaultTerritoryId(territoryId);
        List<UUID> branchIds = branches.stream().map(Branch::getId).toList();

        if (branchIds.isEmpty()) {
            return ProfitSummary.empty();
        }

        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.atTime(LocalTime.MAX);

        BigDecimal totalProfit = profitLogRepository.sumProfitByBranches(branchIds, fromDt, toDt);

        // Összegyűjtjük az összes log-ot a területhez
        List<ProfitLog> allLogs = new ArrayList<>();
        for (UUID bid : branchIds) {
            allLogs.addAll(profitLogRepository.findByBranchIdAndCreatedAtBetween(bid, fromDt, toDt));
        }

        return buildSummary(allLogs, totalProfit);
    }

    /**
     * Cég szintű profit összesítés.
     */
    @Transactional(readOnly = true)
    public ProfitSummary getCompanyProfitSummary(UUID companyId, LocalDate from, LocalDate to) {
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.atTime(LocalTime.MAX);

        List<ProfitLog> logs = profitLogRepository.findByCompanyIdAndCreatedAtBetween(companyId, fromDt, toDt);
        BigDecimal totalProfit = profitLogRepository.sumProfitByCompany(companyId, fromDt, toDt);

        return buildSummary(logs, totalProfit);
    }

    // ============ BELSŐ ============

    private ProfitSummary buildSummary(List<ProfitLog> logs, BigDecimal totalProfit) {
        Map<String, BigDecimal> profitByCurrency = new LinkedHashMap<>();
        int sellCount = 0;
        int buyCount = 0;

        for (ProfitLog log : logs) {
            profitByCurrency.merge(log.getCurrencyCode(), log.getRealizedProfit(), BigDecimal::add);
            if ("SELL".equals(log.getTransactionType())) {
                sellCount++;
            } else if ("BUY".equals(log.getTransactionType())) {
                buyCount++;
            }
        }

        return ProfitSummary.builder()
                .totalProfit(totalProfit)
                .transactionCount(logs.size())
                .sellCount(sellCount)
                .buyCount(buyCount)
                .profitByCurrency(profitByCurrency)
                .build();
    }

    // ============ DTO ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class ProfitSummary {
        private BigDecimal totalProfit;
        private int transactionCount;
        private int sellCount;
        private int buyCount;
        private Map<String, BigDecimal> profitByCurrency;

        public static ProfitSummary empty() {
            return ProfitSummary.builder()
                    .totalProfit(BigDecimal.ZERO)
                    .transactionCount(0)
                    .sellCount(0)
                    .buyCount(0)
                    .profitByCurrency(Collections.emptyMap())
                    .build();
        }
    }
}
