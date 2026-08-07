package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.FeeDiscount;
import hu.puzzleir.valuta.service.DiscountThresholdService;
import hu.puzzleir.valuta.util.HungarianRounding;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Kedvezmény threshold REST API.
 *
 * Legacy: BIGARFVALT / KISARFVALT — automatikus kedvezmény/felár
 * a tranzakció összeg alapján.
 *
 * <p>FK-076 (2026-08-07): a `/resolve` és `/apply` a pénztári tranzakció-folyamat
 * díjszámító lépései (a `CashierTransactionPage` minden összeg-változáskor hívja).
 * A vezetői osztály-kör ezeket 403-mal dobta a pénztárosnak. Mindkettő mellékhatás
 * nélküli olvasó számítás, ezért a {@link AmlController#TRANSACTION_FLOW_ROLES} kört
 * kapják. Az `/active` (teljes kedvezmény-törzs listázása) vezetői körben marad.</p>
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping({"/api/v1/discount-threshold", "/api/discount-threshold"})
@RequiredArgsConstructor
@Tag(name = "Kedvezmény küszöb", description = "Automatikus kedvezmény/felár nagy/kis összeg alapján")
public class DiscountThresholdController {

    private final DiscountThresholdService thresholdService;

    @GetMapping("/resolve")
    @PreAuthorize(AmlController.TRANSACTION_FLOW_ROLES)
    @Operation(summary = "Kedvezmény/felár meghatározása összeg alapján")
    public ResponseEntity<Map<String, Object>> resolve(@RequestParam BigDecimal hufAmount) {
        Optional<FeeDiscount> discount = thresholdService.resolveDiscount(hufAmount);

        if (discount.isPresent()) {
            FeeDiscount d = discount.get();
            return ResponseEntity.ok(Map.of(
                    "hasDiscount", true,
                    "code", d.getCode(),
                    "name", d.getName(),
                    "type", d.getDiscountType() != null ? d.getDiscountType() : "",
                    "value", d.getDiscountValue() != null ? d.getDiscountValue() : BigDecimal.ZERO
            ));
        }

        return ResponseEntity.ok(Map.of("hasDiscount", false));
    }

    @GetMapping("/apply")
    @PreAuthorize(AmlController.TRANSACTION_FLOW_ROLES)
    @Operation(summary = "Kedvezmény alkalmazása a kezelési díjra")
    public ResponseEntity<Map<String, Object>> apply(
            @RequestParam BigDecimal hufAmount,
            @RequestParam BigDecimal originalFee) {

        Optional<FeeDiscount> discount = thresholdService.resolveDiscount(hufAmount);

        if (discount.isPresent()) {
            BigDecimal adjustedFee = HungarianRounding.roundToFive(
                    thresholdService.applyDiscount(originalFee, discount.get()));
            return ResponseEntity.ok(Map.of(
                    "originalFee", originalFee,
                    "adjustedFee", adjustedFee,
                    "discountCode", discount.get().getCode(),
                    "discountName", discount.get().getName()
            ));
        }

        return ResponseEntity.ok(Map.of(
                "originalFee", originalFee,
                "adjustedFee", HungarianRounding.roundToFive(originalFee),
                "discountCode", "",
                "discountName", "Nincs automatikus kedvezmény"
        ));
    }

    @GetMapping("/active")
    @Operation(summary = "Összes aktív kedvezmény listázása")
    public ResponseEntity<List<FeeDiscount>> listActive() {
        return ResponseEntity.ok(thresholdService.listActiveDiscounts());
    }
}
