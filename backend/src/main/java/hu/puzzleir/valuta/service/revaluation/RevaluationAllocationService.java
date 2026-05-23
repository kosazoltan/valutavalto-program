package hu.puzzleir.valuta.service.revaluation;

import hu.puzzleir.valuta.dto.revaluation.TerritoryReconciliationDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.entity.MnbExchangeRateCache;
import hu.puzzleir.valuta.entity.ProfitLog;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.ProfitLogRepository;
import hu.puzzleir.valuta.repository.TransferRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.MnbExchangeRateService;
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
 * Értéktári átértékelés lecsorgatása a pénztárakra + területi reconciliation.
 *
 * <p>A vault pufferkészlet (CurrencyStock entityType='VAULT', entityId=territoryId)
 * nem-realizált átértékelését (heldQty × (MNB − WAC)) valutánként a {@link RevaluationAllocator}
 * osztja le a terület pénztáraira a (lehívott mennyiség × pénztári átlag-árrés) súly szerint.</p>
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class RevaluationAllocationService {

    private static final String VAULT = "VAULT";

    private final BranchRepository branchRepository;
    private final CurrencyStockRepository currencyStockRepository;
    private final ProfitLogRepository profitLogRepository;
    private final TransferRepository transferRepository;
    private final MnbExchangeRateService mnbExchangeRateService;

    public TerritoryReconciliationDto reconcileTerritory(Integer territoryId, LocalDate from, LocalDate to) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        LocalDateTime fromDt = from.atStartOfDay();
        LocalDateTime toDt = to.atTime(LocalTime.MAX);

        // 1. Terület pénztárai (értéktár kizárva — az nem haszoncenter)
        List<Branch> cashiers = branchRepository.findByCompanyIdAndVaultTerritoryId(companyId, territoryId).stream()
                .filter(b -> !Boolean.TRUE.equals(b.getIsVault()))
                .toList();
        List<UUID> cashierIds = cashiers.stream().map(Branch::getId).toList();

        // 2. Értéktári pufferkészlet REVAL valutánként (heldQty × (MNB/unit − WAC))
        Map<String, MnbExchangeRateCache> mnbRates = mnbExchangeRateService.getRatesForDate(to);
        List<TerritoryReconciliationDto.CurrencyReval> revals = new ArrayList<>();
        Map<String, BigDecimal> revalByCurrency = new LinkedHashMap<>();
        for (CurrencyStock vs : currencyStockRepository.findByCompanyIdAndEntityType(companyId, VAULT)) {
            if (!String.valueOf(territoryId).equals(vs.getEntityId())) {
                continue;
            }
            String c = vs.getCurrencyCode();
            if ("HUF".equals(c)) {
                continue;
            }
            MnbExchangeRateCache mnb = mnbRates.get(c);
            if (mnb == null || vs.getQuantity() == null || vs.getQuantity().signum() == 0) {
                continue;
            }
            BigDecimal mnbPerUnit = mnb.getOfficialRate().divide(
                    BigDecimal.valueOf(mnb.getUnit() == null ? 1 : mnb.getUnit()), 6, RoundingMode.HALF_UP);
            BigDecimal wac = vs.getWeightedAvgCost() != null ? vs.getWeightedAvgCost() : BigDecimal.ZERO;
            // Egész forintra kerekítjük, hogy a kiosztott összeg (allokátor szintén egész Ft)
            // bit-pontosan egyezzen a megjelenített REVAL-lal — pénzügyi reconciliation.
            BigDecimal reval = vs.getQuantity().multiply(mnbPerUnit.subtract(wac)).setScale(0, RoundingMode.HALF_UP);
            revalByCurrency.merge(c, reval, BigDecimal::add);
            revals.add(TerritoryReconciliationDto.CurrencyReval.builder()
                    .currencyCode(c).vaultHeldQty(vs.getQuantity()).weightedAvgCost(wac)
                    .mnbRate(mnbPerUnit).revaluation(reval).build());
        }

        // 3. Hajtóerők pénztáranként-valutánként: realizált profit + forgalom (ProfitLog), lehívás (Transfer)
        // realizedProfit[branch][currency], quantity[branch][currency]
        Map<UUID, Map<String, BigDecimal>> realizedProfit = new HashMap<>();
        Map<UUID, Map<String, BigDecimal>> quantity = new HashMap<>();
        for (UUID bid : cashierIds) {
            for (ProfitLog pl : profitLogRepository.findByBranchIdAndCreatedAtBetween(bid, fromDt, toDt)) {
                realizedProfit.computeIfAbsent(bid, k -> new HashMap<>())
                        .merge(pl.getCurrencyCode(), nz(pl.getRealizedProfit()), BigDecimal::add);
                quantity.computeIfAbsent(bid, k -> new HashMap<>())
                        .merge(pl.getCurrencyCode(), nz(pl.getQuantity()), BigDecimal::add);
            }
        }
        // drawn[branch][currency]
        Map<UUID, Map<String, BigDecimal>> drawn = new HashMap<>();
        if (!cashierIds.isEmpty()) {
            for (Transfer t : transferRepository.findVaultDrawsToCashiers(cashierIds, from, to)) {
                String c = t.getCurrency() != null ? t.getCurrency().getCode() : null;
                if (c == null) {
                    continue;
                }
                drawn.computeIfAbsent(t.getToBranch().getId(), k -> new HashMap<>())
                        .merge(c, nz(t.getAmount()), BigDecimal::add);
            }
        }

        // 4. Allokáció valutánként → összegzés pénztáranként
        Map<UUID, BigDecimal> allocByBranch = new HashMap<>();
        for (Map.Entry<String, BigDecimal> e : revalByCurrency.entrySet()) {
            String c = e.getKey();
            List<RevaluationAllocator.CashierDriver> drivers = new ArrayList<>();
            for (UUID bid : cashierIds) {
                BigDecimal q = get(quantity, bid, c);
                BigDecimal prof = get(realizedProfit, bid, c);
                BigDecimal spread = q.signum() > 0 ? prof.divide(q, 6, RoundingMode.HALF_UP) : BigDecimal.ZERO;
                drivers.add(new RevaluationAllocator.CashierDriver(bid.toString(), get(drawn, bid, c), spread));
            }
            for (RevaluationAllocator.Allocation a : RevaluationAllocator.allocateCurrency(c, e.getValue(), drivers)) {
                allocByBranch.merge(UUID.fromString(a.cashierId()), a.allocatedReval(), BigDecimal::add);
            }
        }

        // 5. Pénztár-sorok + területi összesítés
        List<TerritoryReconciliationDto.CashierLine> lines = new ArrayList<>();
        BigDecimal sumRealized = BigDecimal.ZERO;
        BigDecimal sumAlloc = BigDecimal.ZERO;
        BigDecimal sumTotal = BigDecimal.ZERO;
        for (Branch b : cashiers) {
            BigDecimal realized = realizedProfit.getOrDefault(b.getId(), Map.of()).values()
                    .stream().reduce(BigDecimal.ZERO, BigDecimal::add).setScale(2, RoundingMode.HALF_UP);
            BigDecimal alloc = allocByBranch.getOrDefault(b.getId(), BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
            BigDecimal total = realized.add(alloc);
            sumRealized = sumRealized.add(realized);
            sumAlloc = sumAlloc.add(alloc);
            sumTotal = sumTotal.add(total);
            lines.add(TerritoryReconciliationDto.CashierLine.builder()
                    .branchId(b.getId().toString()).branchCode(b.getCode()).branchName(b.getName())
                    .realizedMargin(realized).allocatedRevaluation(alloc).totalProfit(total).build());
        }

        // A REVAL alap = Σ per-valuta (egész Ft); a kiosztott (sumAlloc) az allokátor által
        // pontosan ennyi. A területi totált a TÉNYLEGESEN kiosztott összegekből származtatjuk,
        // így territoryTotal === Σ(pénztár összhaszon) bit-pontosan.
        BigDecimal revalBasis = revalByCurrency.values().stream()
                .reduce(BigDecimal.ZERO, BigDecimal::add).setScale(2, RoundingMode.HALF_UP);
        BigDecimal territoryReval = sumAlloc;                      // == Σ kiosztott átértékelés
        BigDecimal territoryTotal = sumRealized.add(territoryReval); // == sumTotal
        // reconciliation: a kiosztás megőrizte-e az átértékelés alapot (Σalloc == Σreval per valuta)
        boolean ok = sumAlloc.compareTo(revalBasis) == 0
                && sumTotal.compareTo(territoryTotal) == 0;

        return TerritoryReconciliationDto.builder()
                .territoryId(territoryId).fromDate(from).toDate(to)
                .cashiers(lines).currencyRevaluations(revals)
                .territoryRealizedMargin(sumRealized)
                .territoryRevaluation(territoryReval)
                .territoryTotalProfit(territoryTotal)
                .reconciliationOk(ok)
                .build();
    }

    private static BigDecimal nz(BigDecimal b) {
        return b == null ? BigDecimal.ZERO : b;
    }

    private static BigDecimal get(Map<UUID, Map<String, BigDecimal>> m, UUID bid, String c) {
        return m.getOrDefault(bid, Map.of()).getOrDefault(c, BigDecimal.ZERO);
    }
}
