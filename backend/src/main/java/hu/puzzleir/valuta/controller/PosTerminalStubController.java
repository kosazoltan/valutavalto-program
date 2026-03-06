package hu.puzzleir.valuta.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * OTP POS terminál API stub — placeholder a terminál integráció számára.
 *
 * Legacy: OTP terminál ISO 8583 protokoll — kártyás fizetés kezelés.
 * A legacy rendszerben soros porton (RS-232) kommunikált a terminállal.
 *
 * Modern megoldás: a POS terminálok ma TCP/IP-n vagy USB-n kommunikálnak,
 * és a terminál gyártó saját SDK-t biztosít (Ingenico, Verifone, PAX).
 *
 * ÁLLAPOT: STUB — nincs élő integráció, az Electron kliens a terminál
 * SDK-ján keresztül fog kommunikálni, a backend csak a tranzakciót rögzíti.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/pos-terminal")
@Tag(name = "POS Terminál (STUB)", description = "Bankkártyás fizetés terminál integráció — stub")
@Slf4j
public class PosTerminalStubController {

    @PostMapping("/authorize")
    @Operation(summary = "[STUB] Kártyás tranzakció engedélyeztetés")
    public ResponseEntity<Map<String, Object>> authorize(@RequestBody Map<String, Object> request) {
        log.warn("POS terminál STUB hívás: /authorize");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "POS terminál integráció előkészítés alatt. " +
                        "Az Electron kliens közvetlen terminál SDK-n keresztül fog kommunikálni.",
                "legacyModule", "OTP terminál ISO 8583",
                "modernApproach", "Electron IPC → terminál SDK (Ingenico/Verifone/PAX)"
        ));
    }

    @PostMapping("/void/{transactionId}")
    @Operation(summary = "[STUB] Kártyás tranzakció sztornózás")
    public ResponseEntity<Map<String, Object>> voidTransaction(@PathVariable String transactionId) {
        log.warn("POS terminál STUB hívás: /void/{}", transactionId);
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "transactionId", transactionId,
                "message", "POS terminál integráció előkészítés alatt."
        ));
    }

    @PostMapping("/settlement")
    @Operation(summary = "[STUB] Napi elszámolás (settlement)")
    public ResponseEntity<Map<String, Object>> settlement() {
        log.warn("POS terminál STUB hívás: /settlement");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "Napi POS settlement integráció előkészítés alatt."
        ));
    }

    @GetMapping("/status")
    @Operation(summary = "[STUB] Terminál állapot lekérdezés")
    public ResponseEntity<Map<String, Object>> getTerminalStatus() {
        return ResponseEntity.ok(Map.of(
                "connected", false,
                "terminalType", "STUB",
                "message", "Nincs csatlakoztatott POS terminál. " +
                        "Éles környezetben az Electron kliens kezeli a terminál kapcsolatot."
        ));
    }
}
