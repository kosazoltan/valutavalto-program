package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.pos.PosAuthorizeRequest;
import hu.puzzleir.valuta.dto.pos.PosClosingResult;
import hu.puzzleir.valuta.dto.pos.PosTerminalRequest;
import hu.puzzleir.valuta.dto.pos.PosTransactionResult;
import hu.puzzleir.valuta.dto.pos.TerminalStatus;
import hu.puzzleir.valuta.service.PosTerminalService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * POS terminal compatibility endpoint (legacy STUB path kept for backward compatibility).
 *
 * NOTE: the old 501-only stub behavior is replaced with real POS bridge execution.
 */
@Validated
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/pos-terminal-stub")
@Tag(name = "POS Terminál (compat)", description = "Bankkártyás fizetés terminál integráció — kompatibilitási API")
@Slf4j
@RequiredArgsConstructor
public class PosTerminalStubController {

    private static final String ID_PATTERN = "^[A-Za-z0-9._-]{1,64}$";

    private final PosTerminalService posTerminalService;

    @PostMapping("/authorize")
    @Operation(summary = "Kártyás tranzakció engedélyeztetés (compat)")
    public ResponseEntity<Map<String, Object>> authorize(@Valid @RequestBody PosAuthorizeRequest request) {
        String currency = request.normalizedCurrency();

        PosTransactionResult result = posTerminalService.initiatePayment(request.amount(), currency, request.terminalId());
        return ResponseEntity.ok(toPaymentResponse("AUTHORIZE", request.terminalId(), request.amount(), currency, result));
    }

    @PostMapping("/void/{transactionId}")
    @Operation(summary = "Kártyás tranzakció sztornózás (compat)")
    public ResponseEntity<Map<String, Object>> voidTransaction(
            @PathVariable
            @NotBlank(message = "A transactionId kötelező")
            @Pattern(regexp = ID_PATTERN, message = "A transactionId formátuma érvénytelen")
            String transactionId,
            @Valid @ModelAttribute PosTerminalRequest request) {

        String safeTransactionId = validateIdentifier(transactionId, "transactionId");
        PosTransactionResult result = posTerminalService.initiateReversal(safeTransactionId, request.terminalId());

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("action", "VOID");
        payload.put("terminalId", request.terminalId());
        payload.put("transactionId", safeTransactionId);
        payload.put("approved", result.approved());
        payload.put("status", result.status().name());
        payload.put("authorizationCode", result.authorizationCode());
        payload.put("referenceNumber", result.referenceNumber());
        payload.put("errorMessage", result.errorMessage());
        return ResponseEntity.ok(payload);
    }

    @PostMapping("/settlement")
    @Operation(summary = "Napi elszámolás (settlement) (compat)")
    public ResponseEntity<Map<String, Object>> settlement(@Valid @ModelAttribute PosTerminalRequest request) {
        PosClosingResult result = posTerminalService.dailyClose(request.terminalId());

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("action", "SETTLEMENT");
        payload.put("terminalId", request.terminalId());
        payload.put("success", result.success());
        payload.put("transactionCount", result.transactionCount());
        payload.put("totalAmount", result.totalAmount());
        payload.put("errorMessage", result.errorMessage());
        return ResponseEntity.ok(payload);
    }

    @GetMapping("/status")
    @Operation(summary = "Terminál állapot lekérdezés (compat)")
    public ResponseEntity<Map<String, Object>> getTerminalStatus(@Valid @ModelAttribute PosTerminalRequest request) {
        TerminalStatus status = posTerminalService.getStatus(request.terminalId());

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("terminalId", status.terminalId());
        payload.put("connected", status.active() && status.reachable());
        payload.put("active", status.active());
        payload.put("reachable", status.reachable());
        payload.put("terminalName", status.terminalName());
        payload.put("terminalType", status.terminalType());
        payload.put("lastTransactionAt", status.lastTransactionAt());
        payload.put("message", status.statusMessage());
        return ResponseEntity.ok(payload);
    }

    private String validateIdentifier(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("A " + fieldName + " kötelező");
        }
        String normalized = value.trim();
        if (!normalized.matches(ID_PATTERN)) {
            throw new IllegalArgumentException("A " + fieldName + " formátuma érvénytelen");
        }
        return normalized;
    }

    private Map<String, Object> toPaymentResponse(String action,
                                                  String terminalId,
                                                  BigDecimal amount,
                                                  String currency,
                                                  PosTransactionResult result) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("action", action);
        payload.put("terminalId", terminalId);
        payload.put("amount", amount);
        payload.put("currency", currency);
        payload.put("approved", result.approved());
        payload.put("status", result.status().name());
        payload.put("authorizationCode", result.authorizationCode());
        payload.put("referenceNumber", result.referenceNumber());
        payload.put("errorMessage", result.errorMessage());
        return payload;
    }
}
