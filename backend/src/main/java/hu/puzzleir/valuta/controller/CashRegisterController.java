package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.cashregister.CashRegisterEventDto;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterCommandRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterReceiptRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterStornoRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterDeviceDto;
import hu.puzzleir.valuta.dto.cashregister.RegisterCashRegisterDeviceRequest;
import hu.puzzleir.valuta.service.BranchService;
import hu.puzzleir.valuta.service.CashRegisterService;
import hu.puzzleir.valuta.service.CashRegisterDeviceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Pénztárgép controller.
 * NAV online pénztárgép integráció endpointok.
 */
@RestController
@RequestMapping("/api/v1/cash-register")
@RequiredArgsConstructor
public class CashRegisterController {

    private final CashRegisterService cashRegisterService;
    private final CashRegisterDeviceService cashRegisterDeviceService;
    private final BranchService branchService;

    @PostMapping("/open")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> openDay(@RequestParam UUID branchId) {
        branchService.findById(branchId); // IDOR védelem: cég ellenőrzés
        return eventResponse(cashRegisterService.openDay(branchId));
    }

    @PostMapping("/close")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> closeDay(@RequestParam UUID branchId) {
        branchService.findById(branchId); // IDOR védelem: cég ellenőrzés
        return eventResponse(cashRegisterService.closeDay(branchId));
    }

    @PostMapping("/receipt")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CashRegisterEventDto> printReceipt(
            @Valid @RequestBody CashRegisterReceiptRequest request) {
        branchService.findById(request.getBranchId()); // IDOR védelem: cég ellenőrzés
        return eventResponse(cashRegisterService.printReceipt(request));
    }

    @PostMapping("/storno")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> printStorno(
            @Valid @RequestBody CashRegisterStornoRequest request) {
        branchService.findById(request.getBranchId()); // IDOR védelem: cég ellenőrzés
        return eventResponse(cashRegisterService.printStorno(request));
    }

    @GetMapping("/x-report/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> getXReport(@PathVariable UUID branchId) {
        branchService.findById(branchId); // IDOR védelem: cég ellenőrzés
        return eventResponse(cashRegisterService.getXReport(branchId));
    }

    @GetMapping("/z-report/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> generateZReport(
            @PathVariable UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        branchService.findById(branchId);
        return eventResponse(cashRegisterService.generateZReport(branchId, date));
    }

    @PostMapping("/command")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CashRegisterEventDto> executeCommand(
            @Valid @RequestBody CashRegisterCommandRequest request) {
        branchService.findById(request.getBranchId());
        return eventResponse(cashRegisterService.executeCommand(request));
    }

    @GetMapping("/receipt-gaps/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<java.util.List<String>> validateReceiptGaps(
            @PathVariable UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        branchService.findById(branchId);
        return ResponseEntity.ok(cashRegisterService.validateReceiptSequenceContinuity(branchId, date));
    }

    @GetMapping("/events/{branchId}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CashRegisterEventDto>> getDailyEvents(
            @PathVariable UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        branchService.findById(branchId); // IDOR védelem: cég ellenőrzés
        LocalDate effectiveDate = date != null ? date : LocalDate.now();
        return ResponseEntity.ok(cashRegisterService.getDailyEvents(branchId, effectiveDate));
    }
// ============ PENZTAR-ESZKOZ REGISZTRACIO (V100) ============

    /**
     * Penztar-client Electron eszkoz online regisztracioja a SetupWizard-bol.
     * Idempotens: a (companyId, code) parra uniqueness - ugyanaz a penztar ismetelten hivhato frissitesi celbol.
     *
     * Security: barmely authentikalt worker regisztralhat UJ eszkozt (self-registration,
     * hogy a SetupWizard barmely role-u credentials-szel tudja hasznalni). A device-hijacking
     * vedelmet (letezo rekord MAS fingerprint-tel) a CashRegisterDeviceService ellenorzi
     * (409 Conflict). Update eseten (letezo rekord ugyanazzal a fingerprint-tel) az elemi
     * authentikacio elegendo, mert a companyId-t a JWT token adja.
     */
    @PostMapping("/register")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CashRegisterDeviceDto> registerDevice(
            @Valid @RequestBody RegisterCashRegisterDeviceRequest request) {
        return ResponseEntity.ok(cashRegisterDeviceService.register(request));
    }

    /**
     * Heartbeat: last_seen_at frissitese. SyncEngine hivja periodikusan online modban.
     */
    @PostMapping("/device/{deviceId}/heartbeat")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<CashRegisterDeviceDto> recordDeviceHeartbeat(@PathVariable UUID deviceId) {
        return ResponseEntity.ok(cashRegisterDeviceService.heartbeat(deviceId));
    }

    /**
     * A bejelentkezett ceg osszes aktiv penztar-eszkozenek listaja.
     */
    @GetMapping("/devices")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<CashRegisterDeviceDto>> listCashRegisterDevices() {
        return ResponseEntity.ok(cashRegisterDeviceService.listForCurrentCompany());
    }

    private ResponseEntity<CashRegisterEventDto> eventResponse(CashRegisterEventDto event) {
        HttpStatus status = hasErrorStatus(event) ? HttpStatus.BAD_GATEWAY : HttpStatus.OK;
        return ResponseEntity.status(status).body(event);
    }

    private boolean hasErrorStatus(CashRegisterEventDto event) {
        return event != null
                && event.getRawResponse() != null
                && event.getRawResponse().contains("\"status\":\"ERROR\"");
    }
}
