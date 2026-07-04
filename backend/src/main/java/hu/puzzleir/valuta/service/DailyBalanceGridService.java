package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.DailyBalanceGridRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * FK-047: Napi ellenőrző lista grid — a {@code daily_balance} tábla (FK-046 által töltött)
 * pénztári adatainak valutánkénti összesítése a kért scope-ra (teljes cég / terület / pénztár).
 *
 * <p>Read-only riport-service. Multi-tenant izoláció: a branch-halmaz MINDIG a hívó cégének
 * irodáiból áll ({@code companyId}-szűrt lekérdezések); idegen cég irodája → 404
 * (id-enumeráció ellen, a requireOwnBranch mintája szerint).</p>
 */
@Service
@RequiredArgsConstructor
public class DailyBalanceGridService {

    private final DailyBalanceRepository dailyBalanceRepository;
    private final BranchRepository branchRepository;

    /**
     * Valutánkénti összesített napi mérleg a kért scope-ra.
     *
     * @param companyId        a hívó cége (SecurityUtils-ból, a controller adja)
     * @param date             a mérleg napja
     * @param branchId         opcionális pénztár-szűrő (null = terület vagy teljes cég)
     * @param vaultTerritoryId opcionális terület-szűrő (csak ha branchId null)
     */
    @Transactional(readOnly = true)
    public List<DailyBalanceGridRowDto> getGrid(
            UUID companyId, LocalDate date, UUID branchId, Integer vaultTerritoryId) {

        List<UUID> branchIds = resolveBranchScope(companyId, branchId, vaultTerritoryId);
        if (branchIds.isEmpty()) {
            return List.of();
        }

        List<DailyBalance> balances = dailyBalanceRepository.findByBranchIdsAndDate(companyId, branchIds, date);

        // Valutánkénti aggregálás — több pénztár (cég/terület nézet) soronként összeadódik.
        Map<String, DailyBalanceGridRowDto> byCurrency = new LinkedHashMap<>();
        for (DailyBalance db : balances) {
            DailyBalanceGridRowDto row = byCurrency.computeIfAbsent(db.getCurrencyCode(),
                    code -> DailyBalanceGridRowDto.builder()
                            .currencyCode(code)
                            .openingBalance(BigDecimal.ZERO)
                            .purchases(BigDecimal.ZERO)
                            .sales(BigDecimal.ZERO)
                            .transfersIn(BigDecimal.ZERO)
                            .transfersOut(BigDecimal.ZERO)
                            .closingBalance(BigDecimal.ZERO)
                            .actualStock(null) // null marad, amíg nincs legalább egy rögzített SZÁMZÁR
                            .surplus(BigDecimal.ZERO)
                            .shortage(BigDecimal.ZERO)
                            .build());
            row.setOpeningBalance(row.getOpeningBalance().add(nz(db.getOpeningBalance())));
            row.setPurchases(row.getPurchases().add(nz(db.getPurchases())));
            row.setSales(row.getSales().add(nz(db.getSales())));
            row.setTransfersIn(row.getTransfersIn().add(nz(db.getTransfersIn())));
            row.setTransfersOut(row.getTransfersOut().add(nz(db.getTransfersOut())));
            row.setClosingBalance(row.getClosingBalance().add(nz(db.getClosingBalance())));
            // SZÁMZÁR: null = nincs leszámolás — összesítésben csak a rögzített értékek adódnak,
            // és ha EGYIK pénztárnak sincs, a mező null marad (a grid „–"-t mutat, FR-8).
            if (db.getActualStock() != null) {
                row.setActualStock(nz(row.getActualStock()).add(db.getActualStock()));
            }
            row.setSurplus(row.getSurplus().add(nz(db.getSurplus())));
            row.setShortage(row.getShortage().add(nz(db.getShortage())));
        }

        List<DailyBalanceGridRowDto> result = new ArrayList<>(byCurrency.values());
        result.sort(Comparator.comparing(DailyBalanceGridRowDto::getCurrencyCode));
        return result;
    }

    /**
     * A branch-halmaz feloldása a hívó cégére szűrve (multi-tenant izoláció, §1).
     * Pénztár-nézet: a kért iroda tulajdonosát validáljuk (idegen cég → 404).
     */
    private List<UUID> resolveBranchScope(UUID companyId, UUID branchId, Integer vaultTerritoryId) {
        if (branchId != null) {
            if (!branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
                throw new ResourceNotFoundException("Iroda nem található: " + branchId);
            }
            return List.of(branchId);
        }
        List<Branch> companyBranches = branchRepository.findByCompanyId(companyId);
        return companyBranches.stream()
                .filter(b -> vaultTerritoryId == null
                        || vaultTerritoryId.equals(b.getVaultTerritoryId()))
                .map(Branch::getId)
                .toList();
    }

    private static BigDecimal nz(BigDecimal v) {
        return v == null ? BigDecimal.ZERO : v;
    }
}
