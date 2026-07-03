package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.CashBalance;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.CurrencyStock;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class InventoryStockAccessor {

    private static final String ENTITY_TYPE_VAULT = "VAULT";

    private final CashBalanceRepository cashBalanceRepository;
    private final CurrencyStockRepository currencyStockRepository;

    public BigDecimal getBalance(Branch branch, Currency currency) {
        if (isVaultContext(branch)) {
            CurrencyStock stock = findVaultStock(branch, currency);
            return stock.getQuantity();
        }
        return findCashBalance(branch, currency).getCurrentBalance();
    }

    public void adjust(Branch branch, Currency currency, BigDecimal delta) {
        BigDecimal normalizedDelta = delta.setScale(4, RoundingMode.HALF_UP);
        if (isVaultContext(branch)) {
            adjustVaultStock(branch, currency, normalizedDelta);
            return;
        }
        CashBalance balance = findCashBalance(branch, currency);
        balance.updateBalance(normalizedDelta.abs(), normalizedDelta.signum() >= 0);
        cashBalanceRepository.save(balance);
    }

    public boolean isVaultContext(Branch branch) {
        return branch != null && Boolean.TRUE.equals(branch.getIsVault());
    }

    private CashBalance findCashBalance(Branch branch, Currency currency) {
        return cashBalanceRepository.findByBranchIdAndCurrencyId(branch.getId(), currency.getId())
                .orElseThrow(() -> new ValidationException(
                        "Nincs kassza egyenleg ehhez a valutához: " + currency.getCode()));
    }

    private CurrencyStock findVaultStock(Branch branch, Currency currency) {
        UUID companyId = requireCompanyId(branch);
        return currencyStockRepository
                .findForUpdate(companyId, ENTITY_TYPE_VAULT, vaultEntityId(branch), currency.getCode())
                .orElseThrow(() -> new ValidationException("Nincs elegendő készlet! Egyenleg: 0.0000, kért: 0.0000"));
    }

    private void adjustVaultStock(Branch branch, Currency currency, BigDecimal delta) {
        UUID companyId = requireCompanyId(branch);
        String entityId = vaultEntityId(branch);
        CurrencyStock stock = currencyStockRepository
                .findForUpdate(companyId, ENTITY_TYPE_VAULT, entityId, currency.getCode())
                .orElse(null);

        if (stock == null) {
            if (delta.signum() < 0) {
                throw insufficientVaultStock(currency, BigDecimal.ZERO, delta.abs());
            }
            stock = CurrencyStock.builder()
                    .company(branch.getCompany())
                    .entityType(ENTITY_TYPE_VAULT)
                    .entityId(entityId)
                    .currencyCode(currency.getCode())
                    .quantity(BigDecimal.ZERO)
                    .weightedAvgCost(BigDecimal.ZERO)
                    .build();
            applyVaultDelta(stock, currency, delta);
            try {
                currencyStockRepository.saveAndFlush(stock);
            } catch (DataIntegrityViolationException race) {
                CurrencyStock locked = currencyStockRepository
                        .findForUpdate(companyId, ENTITY_TYPE_VAULT, entityId, currency.getCode())
                        .orElseThrow(() -> race);
                applyVaultDelta(locked, currency, delta);
                currencyStockRepository.save(locked);
            }
            return;
        }

        applyVaultDelta(stock, currency, delta);
        currencyStockRepository.save(stock);
    }

    private void applyVaultDelta(CurrencyStock stock, Currency currency, BigDecimal delta) {
        BigDecimal nextQuantity = stock.getQuantity().add(delta);
        if (nextQuantity.signum() < 0) {
            throw insufficientVaultStock(currency, stock.getQuantity(), delta.abs());
        }
        stock.setQuantity(nextQuantity);
        stock.setLastUpdated(LocalDateTime.now());
    }

    private String vaultEntityId(Branch branch) {
        Integer territoryId = branch.getVaultTerritoryId();
        if (territoryId == null) {
            throw new ValidationException(String.format(
                    "Az értéktári fiók (%s) vault_territory_id mezője nincs kitöltve — a "
                            + "készletkönyvelés nem végezhető el (törzsadat-rendezés szükséges).",
                    branch.getCode()));
        }
        return territoryId.toString();
    }

    private UUID requireCompanyId(Branch branch) {
        if (branch == null || branch.getCompany() == null || branch.getCompany().getId() == null) {
            throw new ValidationException("Hiányzó cégazonosító — a készletkönyvelés nem végezhető el.");
        }
        return branch.getCompany().getId();
    }

    private ValidationException insufficientVaultStock(Currency currency, BigDecimal available, BigDecimal requested) {
        return new ValidationException("Nincs elegendő készlet! Egyenleg: "
                + available.setScale(4, RoundingMode.HALF_UP)
                + ", kért: " + requested.setScale(4, RoundingMode.HALF_UP)
                + " (" + currency.getCode() + ")");
    }
}
