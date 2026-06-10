package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.nav.NavSendResult;
import hu.puzzleir.valuta.service.NavIntegrationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * NAV pénztárgép integráció controller.
 * Alacsony szintű bridge endpointok. Az üzleti pénztárgép parancsok elsődleges, auditált útja:
 * {@code /api/v1/cash-register/command}.
 */
@RestController
@RequestMapping("/api/v1/nav-integration")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
public class NavIntegrationController {

    private final NavIntegrationService navIntegrationService;

    /**
     * Tranzakció küldése a NAV pénztárgépnek.
     * POST /api/v1/nav-integration/send-transaction
     */
    @PostMapping("/send-transaction")
    public ResponseEntity<NavSendResult> sendTransaction(
            @RequestParam Long transactionId,
            @RequestParam String comPort) {
        return ResponseEntity.ok(navIntegrationService.sendTransaction(transactionId, comPort));
    }

    /**
     * Nyugtaszám fogadása a NAV pénztárgéptől.
     * GET /api/v1/nav-integration/receive-receipt-number
     */
    @GetMapping("/receive-receipt-number")
    public ResponseEntity<String> receiveReceiptNumber(@RequestParam String comPort) {
        return ResponseEntity.ok(navIntegrationService.receiveReceiptNumber(comPort));
    }

    /**
     * QR kód küldése a NAV pénztárgépnek.
     * POST /api/v1/nav-integration/send-qr-code
     */
    @PostMapping("/send-qr-code")
    public ResponseEntity<Boolean> sendQrCode(
            @RequestParam String qrCode,
            @RequestParam String comPort) {
        return ResponseEntity.ok(navIntegrationService.sendQrCode(qrCode, comPort));
    }
}
