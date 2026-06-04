package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.ProfitLog;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.ProfitLogRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
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
    private final SystemParameterService systemParameterService;

    /**
     * A6 / b8 FR-8: a profit_log élesítését vezérlő flag. Default OFF — a realizált
     * profit-követés bekapcsolása ops-döntés, mert a WAC bekerülési ár a
     * MaterialReceiptService értéktár→pénztár átadásokból épül; éles bekapcsolás előtt
     * a nyitó-készlet bekerülési árának konzisztenciáját ops/compliance igazolja.
     */
    static final String WAC_PROFIT_TRACKING_PARAM = "WAC_PROFIT_TRACKING_ENABLED";
    private static final String WAC_PROFIT_TRACKING_DEFAULT = "false";

    /**
     * WAC frissítés amikor valuta érkezik (bank→értéktár, értéktár→pénztár, ügyfél→pénztár).
     */
    @Transactional(rollbackFor = Exception.class)
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
    @Transactional(rollbackFor = Exception.class)
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
    @Transactional(rollbackFor = Exception.class)
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
     * A6 / b8 FR-8: ELADÁS realizált profitjának rögzítése a profit_log-ba — flag-gated,
     * cold-start-safe, a tranzakciót sosem törő best-effort melléklet.
     *
     * <p>FONTOS: csak OLVAS a currency_stock-ból (a WAC bekerülési árat) és a profit_log-ba ÍR,
     * a currency_stock mennyiségét/WAC-ját NEM módosítja — így a havi zárás készletértékelését
     * ({@code MonthlyClosingService}) NEM befolyásolja, és nincs kettős-számolás a cash_balance-szal.</p>
     *
     * <p>Cold-start védelem: ha nincs WAC bekerülési ár (nincs készlet-sor, vagy WAC ≤ 0),
     * KIHAGYJA a rögzítést — különben a teljes eladási árat profitként könyvelné (túlbecslés).</p>
     *
     * <p>{@code discountPercent}: ha &gt; 0, az eladási ráta a kedvezménnyel csökkentve kerül a
     * profitba (effektív ráta = sellRate × (100 − pct) / 100). A kedvezmény a teljes deviza-
     * bevételre uniform %-ban hat, így ez egysoros és multi-line eladásnál is helyes.</p>
     *
     * <p>REQUIRES_NEW + a hívó oldali try-catch garantálja a "best-effort" jelleget: a profit-
     * rögzítés bármilyen hibája SAJÁT al-tranzakcióban marad, és NEM viszi rollback-re az eladást.</p>
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = Exception.class)
    public void recordSellProfitIfEnabled(UUID branchId, Long transactionId, String currencyCode,
                                          BigDecimal quantity, BigDecimal sellRate, BigDecimal discountPercent) {
        if (systemParameterService == null || !"true".equalsIgnoreCase(
                systemParameterService.getValue(WAC_PROFIT_TRACKING_PARAM, WAC_PROFIT_TRACKING_DEFAULT))) {
            return; // flag OFF (default) → no-op
        }
        if (branchId == null || transactionId == null || currencyCode == null
                || quantity == null || sellRate == null) {
            return;
        }
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        CurrencyStock stock = currencyStockRepository
                .findByCompanyIdAndEntityTypeAndEntityIdAndCurrencyCode(
                        companyId, "CASHIER", branchId.toString(), currencyCode)
                .orElse(null);
        if (stock == null || stock.getWeightedAvgCost() == null
                || stock.getWeightedAvgCost().compareTo(BigDecimal.ZERO) <= 0) {
            log.debug("WAC profit kihagyva (nincs bekerülési ár): branch={} {} qty={}",
                    branchId, currencyCode, quantity);
            return;
        }
        // Kedvezményes eladásnál a tényleges (diszkontált) eladási ráta a profit alapja,
        // különben a kedvezmény nélküli appliedRate túlbecsülné a realizált hasznot.
        BigDecimal effectiveSellRate = sellRate;
        if (discountPercent != null && discountPercent.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal factor = BigDecimal.valueOf(100).subtract(discountPercent)
                    .divide(BigDecimal.valueOf(100), 10, RoundingMode.HALF_UP);
            effectiveSellRate = sellRate.multiply(factor);
        }
        recordProfit(branchId, transactionId, currencyCode, quantity, effectiveSellRate, "SELL");
    }

    /**
     * A6 / b8 FR-8: sztornó / részleges visszatérítés profit-KOMPENZÁCIÓJA — flag-gated, best-effort.
     *
     * <p>Az eredeti ELADÁS profit-tételeit (ha vannak) negáló {@code REVERSAL} tételekkel ellensúlyozza,
     * a visszatérített mennyiség arányában ({@code reversedQty / originalQty}), így a {@code profit_log}
     * összegzése a sztornózott/visszatérített eladás hasznát NEM tartalmazza. Teljes sztornónál az arány 1,
     * részleges visszatérítésnél a visszatérített deviza aránya. Csak SELL-eredetit kompenzál
     * (a BUY nem realizál WAC-profitot).</p>
     */
    @Transactional(propagation = Propagation.REQUIRES_NEW, rollbackFor = Exception.class)
    public void recordReversalCompensationIfEnabled(Long originalTransactionId,
                                                    BigDecimal reversedQty, BigDecimal originalQty) {
        if (systemParameterService == null || !"true".equalsIgnoreCase(
                systemParameterService.getValue(WAC_PROFIT_TRACKING_PARAM, WAC_PROFIT_TRACKING_DEFAULT))) {
            return; // flag OFF (default) → no-op
        }
        if (originalTransactionId == null) {
            return;
        }
        BigDecimal ratio = BigDecimal.ONE;
        if (reversedQty != null && originalQty != null && originalQty.compareTo(BigDecimal.ZERO) > 0) {
            ratio = reversedQty.divide(originalQty, 10, RoundingMode.HALF_UP);
        }
        for (ProfitLog original : profitLogRepository.findByTransactionId(originalTransactionId)) {
            // Csak az eredeti SELL-profit kerül kompenzálásra; a korábbi REVERSAL-tételeket nem duplázzuk.
            if (!"SELL".equals(original.getTransactionType()) || original.getRealizedProfit() == null) {
                continue;
            }
            BigDecimal compensation = original.getRealizedProfit().multiply(ratio)
                    .negate().setScale(2, RoundingMode.HALF_UP);
            ProfitLog comp = ProfitLog.builder()
                    .company(original.getCompany())
                    .transactionId(originalTransactionId)
                    .branchId(original.getBranchId())
                    .currencyCode(original.getCurrencyCode())
                    .quantity(reversedQty != null ? reversedQty : original.getQuantity())
                    .acquisitionCost(original.getAcquisitionCost())
                    .salePrice(original.getSalePrice())
                    .realizedProfit(compensation)
                    .transactionType("REVERSAL")
                    .createdAt(LocalDateTime.now())
                    .build();
            profitLogRepository.save(comp);
            log.info("WAC profit kompenzáció: eredeti tx={} {} arány={} kompenzáció={}",
                    originalTransactionId, original.getCurrencyCode(), ratio, compensation);
        }
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
        // Multi-tenant-safe: company-scoped lookup
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Branch> branches = branchRepository.findByCompanyIdAndVaultTerritoryId(companyId, territoryId);
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
