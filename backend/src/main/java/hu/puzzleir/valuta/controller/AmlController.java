package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.aml.*;
import hu.puzzleir.valuta.service.AmlService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * AML (Pénzmosás elleni) controller.
 *
 * 2017. évi LIII. tv. — Pénzmosás és terrorizmus finanszírozása megelőzéséről.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/aml")
@RequiredArgsConstructor
public class AmlController {

    private final AmlService amlService;

    /**
     * Tranzakció AML ellenőrzés.
     * POST /api/v1/aml/check
     */
    @PostMapping("/check")
    public ResponseEntity<AmlCheckResult> checkTransaction(
            @Valid @RequestBody AmlTransactionCheckRequest request) {
        AmlCheckResult result = amlService.checkAllThresholds(
            request.getCustomerId(),
            request.getAmountHuf(),
            request.getCurrencyCode()
        );
        return ResponseEntity.ok(result);
    }

    /**
     * Ügyfél kockázati profil.
     * GET /api/v1/aml/customer-risk/{customerId}
     */
    @GetMapping("/customer-risk/{customerId}")
    public ResponseEntity<CustomerRiskProfileDto> getCustomerRiskProfile(
            @PathVariable String customerId) {
        return ResponseEntity.ok(amlService.getCustomerRiskProfile(customerId));
    }

    /**
     * AML bejelentés létrehozása.
     * POST /api/v1/aml/report
     */
    @PostMapping("/report")
    public ResponseEntity<AmlReportDto> submitReport(
            @Valid @RequestBody CreateAmlReportDto request) {
        return ResponseEntity.ok(amlService.submitReport(request));
    }

    /**
     * Függő bejelentések.
     * GET /api/v1/aml/pending
     */
    @GetMapping("/pending")
    public ResponseEntity<List<AmlReportDto>> getPendingReports() {
        return ResponseEntity.ok(amlService.getPendingReports());
    }

    /**
     * Lejárt határidejű (OVERDUE) bejelentések.
     * GET /api/v1/aml/overdue
     *
     * 2017. LIII. tv. 33.§ — 2 munkanapon belül be kell nyújtani.
     */
    @GetMapping("/overdue")
    public ResponseEntity<List<AmlReportDto>> getOverdueReports() {
        return ResponseEntity.ok(amlService.getOverdueReports());
    }

    /**
     * Napi AML összesítő.
     * GET /api/v1/aml/summary?date=
     */
    @GetMapping("/summary")
    public ResponseEntity<AmlDailySummaryDto> getDailySummary(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(amlService.getDailyAmlSummary(date));
    }

    /**
     * Teljes küszöb ellenőrzés (frontend hívja tranzakció rögzítéskor).
     * GET /api/v1/aml/check-all-thresholds?customerId=&hufAmount=&currencyCode=
     *
     * Legacy: BIGCTRL.DLL — 6 szintű kockázati besorolás + heti/negyedéves/éves göngyölés
     */
    @GetMapping("/check-all-thresholds")
    public ResponseEntity<AmlCheckResult> checkAllThresholds(
            @RequestParam String customerId,
            @RequestParam java.math.BigDecimal hufAmount,
            @RequestParam(required = false) String currencyCode) {
        AmlCheckResult result = amlService.checkAllThresholds(customerId, hufAmount, currencyCode);
        return ResponseEntity.ok(result);
    }

    /**
     * Sprint 6.2: 8 napos rolling window compliance audit.
     * GET /api/v1/aml/rolling-window-audit?thresholdHuf=4500000
     *
     * Pmt. (2017. LIII. tv.) szerinti hatosagi audit lista — azon ugyfelek,
     * akiknek a gongyolt 8 napos osszege eleri vagy meghaladja a kuszobot.
     */
    @GetMapping("/rolling-window-audit")
    public ResponseEntity<List<hu.puzzleir.valuta.dto.aml.RollingWindowAuditDto>> getRollingWindowAudit(
            @RequestParam(required = false) java.math.BigDecimal thresholdHuf) {
        return ResponseEntity.ok(amlService.getRollingWindowAudit(thresholdHuf));
    }

    /**
     * Structuring detektálás.
     * GET /api/v1/aml/structuring-check/{customerId}
     */
    @GetMapping("/structuring-check/{customerId}")
    public ResponseEntity<Map<String, Object>> checkStructuring(
            @PathVariable String customerId) {
        boolean isStructuring = amlService.isStructuring(customerId);
        return ResponseEntity.ok(Map.of(
            "customerId", customerId,
            "structuringDetected", isStructuring
        ));
    }
}
