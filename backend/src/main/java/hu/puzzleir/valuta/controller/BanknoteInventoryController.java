package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.inventory.BanknoteInventoryDto;
import hu.puzzleir.valuta.entity.BanknoteInventory;
import hu.puzzleir.valuta.service.BanknoteInventoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/banknote-inventory")
@RequiredArgsConstructor
public class BanknoteInventoryController {

    private final BanknoteInventoryService service;

    @GetMapping("/branch/{branchId}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<BanknoteInventoryDto>> getByBranch(@PathVariable UUID branchId,
                                                                    @RequestParam(required = false) String currencyCode) {
        List<BanknoteInventory> items = currencyCode != null
                ? service.getByBranchAndCurrency(branchId, currencyCode)
                : service.getByBranch(branchId);
        return ResponseEntity.ok(items.stream().map(this::toDto).toList());
    }

    @GetMapping("/branch/{branchId}/low-stock")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<BanknoteInventoryDto>> getLowStock(@PathVariable UUID branchId) {
        return ResponseEntity.ok(service.getLowStock(branchId).stream().map(this::toDto).toList());
    }

    @GetMapping("/branch/{branchId}/over-stock")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<BanknoteInventoryDto>> getOverStock(@PathVariable UUID branchId) {
        return ResponseEntity.ok(service.getOverStock(branchId).stream().map(this::toDto).toList());
    }

    @PostMapping("/branch/{branchId}/add")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<BanknoteInventoryDto> addStock(@PathVariable UUID branchId,
                                                          @RequestParam Long currencyId,
                                                          @RequestParam String currencyCode,
                                                          @RequestParam BigDecimal faceValue,
                                                          @RequestParam int quantity) {
        return ResponseEntity.ok(toDto(service.addStock(branchId, currencyId, currencyCode, faceValue, quantity)));
    }

    @PostMapping("/branch/{branchId}/remove")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<BanknoteInventoryDto> removeStock(@PathVariable UUID branchId,
                                                              @RequestParam Long currencyId,
                                                              @RequestParam BigDecimal faceValue,
                                                              @RequestParam int quantity) {
        return ResponseEntity.ok(toDto(service.removeStock(branchId, currencyId, faceValue, quantity)));
    }

    @PostMapping("/{inventoryId}/count")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<BanknoteInventoryDto> recordCount(@PathVariable Long inventoryId,
                                                              @RequestParam int actualQuantity,
                                                              @RequestParam String workerId) {
        return ResponseEntity.ok(toDto(service.recordCount(inventoryId, actualQuantity, workerId)));
    }

    @PutMapping("/{inventoryId}/thresholds")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<BanknoteInventoryDto> setThresholds(@PathVariable Long inventoryId,
                                                                @RequestParam(required = false) Integer minQuantity,
                                                                @RequestParam(required = false) Integer maxQuantity) {
        return ResponseEntity.ok(toDto(service.setThresholds(inventoryId, minQuantity, maxQuantity)));
    }

    private BanknoteInventoryDto toDto(BanknoteInventory inv) {
        return BanknoteInventoryDto.builder()
                .id(inv.getId())
                .branchId(inv.getBranchId())
                .currencyId(inv.getCurrencyId())
                .currencyCode(inv.getCurrencyCode())
                .faceValue(inv.getFaceValue())
                .quantity(inv.getQuantity())
                .totalValue(inv.getTotalValue())
                .minQuantity(inv.getMinQuantity())
                .maxQuantity(inv.getMaxQuantity())
                .availabilityDid(inv.getAvailabilityDid())
                .lowStock(inv.isLowStock())
                .overStock(inv.isOverStock())
                .lastCountedAt(inv.getLastCountedAt())
                .lastCountedBy(inv.getLastCountedBy())
                .build();
    }
}
