package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * v2.2.2 hotfix: kozos cash-flow helper a VaultCollection/Distribution/Transfer service-ekhez.
 *
 * Probléma: a vault cash-flow workflow-k (Collection/Distribution/Transfer) eddig
 * csak a status-t tolak, de NEM frissitek a CurrencyStock + CashBalance rekordokat.
 * Emiatt:
 *  - VaultBankTransaction 500-at dob (vault HUF 0)
 *  - Tenyleges penzmozgas nem tortenik a DB-ben
 *
 * Ez a service egy helyre fogja a CurrencyStock (vault) + CashBalance (branch)
 * frissiteseket, a kulonbozo service-ekbol hasznalhato.
 *
 * entity_type konvencio:
 *   VAULT   -> entity_id = vault_territory.id::TEXT
 *   CASHIER -> entity_id = branch.id::TEXT (UUID string)
 */
@Service
@RequiredArgsConstructor
@Slf4j
@Transactional(rollbackFor = Exception.class)
public class VaultStockFlowService {

    private static final String ENTITY_TYPE_VAULT = "VAULT";
    private static final String ENTITY_TYPE_CASHIER = "CASHIER";
    private static final BigDecimal HUF_WAC = BigDecimal.ONE;

    private final CurrencyStockRepository currencyStockRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final BranchRepository branchRepository;
    private final CurrencyRepository currencyRepository;
    private final VaultTerritoryRepository vaultTerritoryRepository;
    private final CompanyRepository companyRepository;

    /**
     * Collection COMPLETED: penztar -> ertektar
     *  - source branch cash_balance csokken (vagy nem, ha a penztar mar oda adta fizikailag)
     *  - vault_territory currency_stock no
     *
     * A HUF WAC mindig 1.0, valuta WAC = jelenlegi kozarfolyam vagy 1.0 ha nincs info.
     */
    public void applyCollection(UUID companyId, String sourceBranchCode,
                                  String currencyCode, BigDecimal amount, BigDecimal wac) {
        VaultTerritory territory = getFirstActiveTerritory(companyId);
        String vaultEntityId = territory.getId().toString();

        // Source branch cash_balance csokkentes (ha nincs rekord, letrehozzuk -- nem romboljuk el)
        decrementBranchCashBalance(companyId, sourceBranchCode, currencyCode, amount);

        // Vault stock no
        CurrencyStock vaultStock = getOrCreateStock(companyId, ENTITY_TYPE_VAULT, vaultEntityId, currencyCode);
        BigDecimal effectiveWac = (wac == null || wac.signum() <= 0)
                ? ("HUF".equals(currencyCode) ? HUF_WAC : BigDecimal.ONE)
                : wac;
        vaultStock.receiveStock(amount, effectiveWac);
        currencyStockRepository.save(vaultStock);

        log.info("Collection COMPLETED: {} {} {} branch -> vault territory={}",
                amount, currencyCode, sourceBranchCode, vaultEntityId);
    }

    /**
     * Distribution COMPLETED: ertektar -> 1 vagy tobb penztar (lines)
     * Minden line-ra:
     *  - vault_territory currency_stock csokken
     *  - target branch cash_balance no
     */
    public void applyDistributionLine(UUID companyId, String targetBranchCode,
                                        String currencyCode, BigDecimal amount) {
        VaultTerritory territory = getFirstActiveTerritory(companyId);
        String vaultEntityId = territory.getId().toString();

        CurrencyStock vaultStock = getOrCreateStock(companyId, ENTITY_TYPE_VAULT, vaultEntityId, currencyCode);
        vaultStock.issueStock(amount);
        currencyStockRepository.save(vaultStock);

        incrementBranchCashBalance(companyId, targetBranchCode, currencyCode, amount);

        log.info("Distribution line COMPLETED: {} {} -> branch={} vault territory={}",
                amount, currencyCode, targetBranchCode, vaultEntityId);
    }

    /**
     * Transfer COMPLETED: branch -> branch
     *  - source branch cash_balance csokken
     *  - target branch cash_balance no
     */
    public void applyTransfer(UUID companyId, String sourceBranchCode,
                                String targetBranchCode, String currencyCode, BigDecimal amount) {
        decrementBranchCashBalance(companyId, sourceBranchCode, currencyCode, amount);
        incrementBranchCashBalance(companyId, targetBranchCode, currencyCode, amount);

        log.info("Transfer COMPLETED: {} {} {} -> {}", amount, currencyCode, sourceBranchCode, targetBranchCode);
    }

    // ============ HELPER METODUSOK ============

    private VaultTerritory getFirstActiveTerritory(UUID companyId) {
        List<VaultTerritory> territories = vaultTerritoryRepository.findByCompanyIdAndActiveTrue(companyId);
        if (territories.isEmpty()) {
            throw new ValidationException("Nincs aktiv ertektari terulet a ceghez (" + companyId + "). "
                    + "V156 seed migration elvileg letrehozza a 'Fo Ertektar'-t.");
        }
        return territories.get(0);
    }

    private CurrencyStock getOrCreateStock(UUID companyId, String entityType, String entityId, String currencyCode) {
        return currencyStockRepository.findForUpdate(companyId, entityType, entityId, currencyCode)
                .orElseGet(() -> {
                    CurrencyStock stock = CurrencyStock.builder()
                            .company(Company.builder().id(companyId).build())
                            .entityType(entityType)
                            .entityId(entityId)
                            .currencyCode(currencyCode)
                            .quantity(BigDecimal.ZERO)
                            .weightedAvgCost(BigDecimal.ZERO)
                            .lastUpdated(LocalDateTime.now())
                            .build();
                    return currencyStockRepository.save(stock);
                });
    }

    /**
     * Branch cash_balance csokkentese. Ha nincs rekord, nem romboljuk el a rendszert
     * (log.warn), csak skip -- a penztar az adott valutabol mar nem rendelkezik hivatalosan.
     */
    private void decrementBranchCashBalance(UUID companyId, String branchCode,
                                              String currencyCode, BigDecimal amount) {
        Optional<Branch> branchOpt = branchRepository.findByCompanyIdAndCode(companyId, branchCode);
        if (branchOpt.isEmpty()) {
            log.warn("decrementBranchCashBalance: branch nem talalhato ({}, {}), skip", branchCode, companyId);
            return;
        }
        Optional<Currency> currencyOpt = currencyRepository.findByCode(currencyCode);
        if (currencyOpt.isEmpty()) {
            log.warn("decrementBranchCashBalance: valuta nem talalhato ({}), skip", currencyCode);
            return;
        }
        UUID branchId = branchOpt.get().getId();
        Long currencyId = currencyOpt.get().getId();

        Optional<CashBalance> balanceOpt = cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, currencyId);
        if (balanceOpt.isEmpty()) {
            log.warn("decrementBranchCashBalance: cash_balance nem talalhato ({}, {}), skip", branchCode, currencyCode);
            return;
        }
        CashBalance balance = balanceOpt.get();
        if (balance.getCurrentBalance().compareTo(amount) < 0) {
            log.warn("decrementBranchCashBalance: elegtelen egyenleg ({} {} < {}), folytatva", 
                    currencyCode, balance.getCurrentBalance(), amount);
            // NEM throw-olunk: a penztar mar fizikailag elkuldte a penzt, csak nyilvantartasi
        }
        balance.subtractBalance(amount);
        balance.setLastTransactionAt(LocalDateTime.now());
        cashBalanceRepository.save(balance);
    }

    private void incrementBranchCashBalance(UUID companyId, String branchCode,
                                              String currencyCode, BigDecimal amount) {
        Optional<Branch> branchOpt = branchRepository.findByCompanyIdAndCode(companyId, branchCode);
        if (branchOpt.isEmpty()) {
            log.warn("incrementBranchCashBalance: branch nem talalhato ({}, {}), skip", branchCode, companyId);
            return;
        }
        Optional<Currency> currencyOpt = currencyRepository.findByCode(currencyCode);
        if (currencyOpt.isEmpty()) {
            log.warn("incrementBranchCashBalance: valuta nem talalhato ({}), skip", currencyCode);
            return;
        }
        UUID branchId = branchOpt.get().getId();
        Long currencyId = currencyOpt.get().getId();

        Company company = companyRepository.findById(companyId).orElseThrow();

        CashBalance balance = cashBalanceRepository.findByBranchIdAndCurrencyId(branchId, currencyId)
                .orElseGet(() -> CashBalance.builder()
                        .company(company)
                        .branch(branchOpt.get())
                        .currency(currencyOpt.get())
                        .currentBalance(BigDecimal.ZERO)
                        .openingBalance(BigDecimal.ZERO)
                        .build());
        balance.addBalance(amount);
        balance.setLastTransactionAt(LocalDateTime.now());
        cashBalanceRepository.save(balance);
    }
}