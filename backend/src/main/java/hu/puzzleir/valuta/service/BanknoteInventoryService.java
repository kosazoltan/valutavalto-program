package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.BanknoteInventory;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BanknoteInventoryRepository;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class BanknoteInventoryService {

    private final BanknoteInventoryRepository repository;
    private final BranchRepository branchRepository;

    /**
     * Multi-tenant IDOR-guard: a megadott branch a hívó cégéhez tartozik-e.
     *
     * <p>A {@link BanknoteInventory} entity csak {@code branchId}-t hordoz, a tenancy a
     * branch szülőjén (company) van. Minden branch-scope-os és by-inventoryId művelet a
     * betöltött rekord branchId-jén át validál a hívó cégére. Cross-tenant esetén
     * {@link ResourceNotFoundException} (a létezés sem szivárog ki).</p>
     *
     * <p>Az összes hívó user-context-ben fut (controller CASHIER+, illetve
     * {@code VaultStocktakeService.createSession}, amely előbb hívja a
     * {@code SecurityUtils.getCurrentCompanyId()}-t) — nincs @Scheduled/@Async/auth-mentes hívó.</p>
     */
    private void requireOwnBranch(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (branchId == null || !branchRepository.existsByIdAndCompanyId(branchId, companyId)) {
            throw new ResourceNotFoundException("Branch nem található: " + branchId);
        }
    }

    public List<BanknoteInventory> getByBranch(UUID branchId) {
        requireOwnBranch(branchId);
        return repository.findByBranchId(branchId);
    }

    public List<BanknoteInventory> getByBranchAndCurrency(UUID branchId, String currencyCode) {
        return repository.findByBranchIdAndCurrencyCode(branchId, currencyCode);
    }

    public List<BanknoteInventory> getLowStock(UUID branchId) {
        return repository.findLowStock(branchId);
    }

    public List<BanknoteInventory> getOverStock(UUID branchId) {
        return repository.findOverStock(branchId);
    }

    @Transactional
    public BanknoteInventory addStock(UUID branchId, Long currencyId, String currencyCode,
                                       BigDecimal faceValue, int quantity) {
        requireOwnBranch(branchId);
        BanknoteInventory inv = repository.findByBranchIdAndCurrencyIdAndFaceValue(branchId, currencyId, faceValue)
                .orElseGet(() -> BanknoteInventory.builder()
                        .branchId(branchId)
                        .currencyId(currencyId)
                        .currencyCode(currencyCode)
                        .faceValue(faceValue)
                        .quantity(0)
                        .build());

        inv.addQuantity(quantity);
        log.info("Added {} x {} {} to branch {}, new qty: {}", quantity, faceValue, currencyCode, branchId, inv.getQuantity());
        return repository.save(inv);
    }

    @Transactional
    public BanknoteInventory removeStock(UUID branchId, Long currencyId, BigDecimal faceValue, int quantity) {
        requireOwnBranch(branchId);
        BanknoteInventory inv = repository.findByBranchIdAndCurrencyIdAndFaceValue(branchId, currencyId, faceValue)
                .orElseThrow(() -> new IllegalStateException(
                        "No inventory for branch=" + branchId + " currency=" + currencyId + " faceValue=" + faceValue));

        inv.removeQuantity(quantity);
        log.info("Removed {} x {} from branch {}, remaining: {}", quantity, faceValue, branchId, inv.getQuantity());
        return repository.save(inv);
    }

    @Transactional
    public BanknoteInventory recordCount(Long inventoryId, int actualQuantity, String workerId) {
        BanknoteInventory inv = repository.findById(inventoryId)
                .orElseThrow(() -> new IllegalArgumentException("Inventory not found: " + inventoryId));
        requireOwnBranch(inv.getBranchId());

        // CodeQL java/tainted-arithmetic fix: Math.subtractExact() overflow/underflow eseten
        // ArithmeticException-t dob, igy a user-input (actualQuantity) nem koppintja silent
        // mode-ban az integer-tartomanyt.
        int currentQty = inv.getQuantity() != null ? inv.getQuantity() : 0;
        int diff = Math.subtractExact(actualQuantity, currentQty);
        if (diff != 0) {
            log.warn("Count discrepancy for inventory {}: expected={}, actual={}, diff={}",
                    inventoryId, inv.getQuantity(), actualQuantity, diff);
        }

        inv.setQuantity(actualQuantity);
        inv.setLastCountedAt(LocalDateTime.now());
        inv.setLastCountedBy(workerId);
        return repository.save(inv);
    }

    @Transactional
    public BanknoteInventory setThresholds(Long inventoryId, Integer minQuantity, Integer maxQuantity) {
        BanknoteInventory inv = repository.findById(inventoryId)
                .orElseThrow(() -> new IllegalArgumentException("Inventory not found: " + inventoryId));
        requireOwnBranch(inv.getBranchId());

        if (minQuantity != null && maxQuantity != null && minQuantity > maxQuantity) {
            throw new IllegalArgumentException("minQuantity cannot exceed maxQuantity");
        }

        inv.setMinQuantity(minQuantity);
        inv.setMaxQuantity(maxQuantity);
        return repository.save(inv);
    }
}
