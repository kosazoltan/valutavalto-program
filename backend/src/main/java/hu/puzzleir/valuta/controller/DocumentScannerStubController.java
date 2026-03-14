package hu.puzzleir.valuta.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Dokumentum szkenner API stub — TWAIN szkenner Electron integráció.
 *
 * Legacy: A Delphi rendszerben TWAIN driver-en keresztül szkennerből
 * olvasták be az ügyfél dokumentumokat (személyi, útlevél).
 *
 * Modern megoldás:
 * 1. Electron IPC → node-twain (TWAIN bridge) → szkenner
 * 2. Alternatíva: Web TWAIN (Dynamic Web TWAIN SDK)
 * 3. Fallback: fájl feltöltés (drag & drop)
 *
 * A backend a beolvasott képet tárolja és OCR-rel feldolgozza.
 *
 * ÁLLAPOT: STUB — a szkenner integráció az Electron kliens oldalon
 * történik, a backend csak a feltöltött képet fogadja.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/document-scanner")
@Tag(name = "Dokumentum Szkenner (STUB)", description = "TWAIN szkenner integráció — Electron kliens oldalon")
@Slf4j
public class DocumentScannerStubController {

    @PostMapping("/scan")
    @Operation(summary = "[STUB] Dokumentum szkennelés indítása")
    public ResponseEntity<Map<String, Object>> startScan() {
        log.warn("Szkenner STUB hívás: /scan — Electron kliens oldalon kezelendő");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "A szkennelés az Electron kliens oldalon történik (TWAIN IPC bridge). " +
                        "Használja a /upload endpointot a beolvasott kép feltöltéséhez.",
                "legacyModule", "TWAIN DLL",
                "modernApproach", "Electron IPC → node-twain → TWAIN driver"
        ));
    }

    @PostMapping("/upload")
    @Operation(summary = "Beolvasott dokumentum kép feltöltése")
    public ResponseEntity<Map<String, Object>> uploadScannedDocument(
            @RequestParam(required = false) Long customerId,
            @RequestParam(required = false) String documentType) {
        log.warn("Szkenner STUB hívás: /upload — backend fájlmentés még nincs implementálva");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "A backend oldali dokumentum feltöltés még nincs kész. " +
                        "A beolvasás és tárolás jelenleg az Electron kliens oldalon történik.",
                "customerId", customerId != null ? customerId : 0L,
                "documentType", documentType != null ? documentType : "UNKNOWN"
        ));
    }

    @GetMapping("/devices")
    @Operation(summary = "Elérhető szkennerek listázása")
    public ResponseEntity<Map<String, Object>> listDevices() {
        return ResponseEntity.ok(Map.of(
                "devices", java.util.Collections.emptyList(),
                "message", "Szkenner felsorolás az Electron kliens oldalon történik. " +
                        "A backend nem lát TWAIN eszközöket."
        ));
    }
}
