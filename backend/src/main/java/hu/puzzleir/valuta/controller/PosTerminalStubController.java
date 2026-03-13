package hu.puzzleir.valuta.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.Map;

/**
 * OTP POS terminĂˇl API stub â€” placeholder a terminĂˇl integrĂˇciĂł szĂˇmĂˇra.
 *
 * Legacy: OTP terminĂˇl ISO 8583 protokoll â€” kĂˇrtyĂˇs fizetĂ©s kezelĂ©s.
 * A legacy rendszerben soros porton (RS-232) kommunikĂˇlt a terminĂˇllal.
 *
 * Modern megoldĂˇs: a POS terminĂˇlok ma TCP/IP-n vagy USB-n kommunikĂˇlnak,
 * Ă©s a terminĂˇl gyĂˇrtĂł sajĂˇt SDK-t biztosĂ­t (Ingenico, Verifone, PAX).
 *
 * ĂLLAPOT: STUB â€” nincs Ă©lĹ‘ integrĂˇciĂł, az Electron kliens a terminĂˇl
 * SDK-jĂˇn keresztĂĽl fog kommunikĂˇlni, a backend csak a tranzakciĂłt rĂ¶gzĂ­ti.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/pos-terminal-stub")
@Tag(name = "POS TerminĂˇl (STUB)", description = "BankkĂˇrtyĂˇs fizetĂ©s terminĂˇl integrĂˇciĂł â€” stub")
@Slf4j
public class PosTerminalStubController {

    @PostMapping("/authorize")
    @Operation(summary = "[STUB] KĂˇrtyĂˇs tranzakciĂł engedĂ©lyeztetĂ©s")
    public ResponseEntity<Map<String, Object>> authorize(@Valid @RequestBody Map<String, Object> request) {
        log.warn("POS terminĂˇl STUB hĂ­vĂˇs: /authorize");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "POS terminĂˇl integrĂˇciĂł elĹ‘kĂ©szĂ­tĂ©s alatt. " +
                        "Az Electron kliens kĂ¶zvetlen terminĂˇl SDK-n keresztĂĽl fog kommunikĂˇlni.",
                "legacyModule", "OTP terminĂˇl ISO 8583",
                "modernApproach", "Electron IPC â†’ terminĂˇl SDK (Ingenico/Verifone/PAX)"
        ));
    }

    @PostMapping("/void/{transactionId}")
    @Operation(summary = "[STUB] KĂˇrtyĂˇs tranzakciĂł sztornĂłzĂˇs")
    public ResponseEntity<Map<String, Object>> voidTransaction(@PathVariable String transactionId) {
        log.warn("POS terminĂˇl STUB hĂ­vĂˇs: /void/{}", transactionId);
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "transactionId", transactionId,
                "message", "POS terminĂˇl integrĂˇciĂł elĹ‘kĂ©szĂ­tĂ©s alatt."
        ));
    }

    @PostMapping("/settlement")
    @Operation(summary = "[STUB] Napi elszĂˇmolĂˇs (settlement)")
    public ResponseEntity<Map<String, Object>> settlement() {
        log.warn("POS terminĂˇl STUB hĂ­vĂˇs: /settlement");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "Napi POS settlement integrĂˇciĂł elĹ‘kĂ©szĂ­tĂ©s alatt."
        ));
    }

    @GetMapping("/status")
    @Operation(summary = "[STUB] TerminĂˇl Ăˇllapot lekĂ©rdezĂ©s")
    public ResponseEntity<Map<String, Object>> getTerminalStatus() {
        return ResponseEntity.ok(Map.of(
                "connected", false,
                "terminalType", "STUB",
                "message", "Nincs csatlakoztatott POS terminĂˇl. " +
                        "Ă‰les kĂ¶rnyezetben az Electron kliens kezeli a terminĂˇl kapcsolatot."
        ));
    }
}
