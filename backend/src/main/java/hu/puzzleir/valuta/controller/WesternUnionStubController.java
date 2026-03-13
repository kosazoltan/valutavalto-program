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
 * Western Union API stub â€” placeholder a WU integrĂˇciĂł szĂˇmĂˇra.
 *
 * Legacy: WUNION DLL â€” Western Union pĂ©nzĂˇtutalĂˇs kezelĂ©s.
 * A partner mĂˇr NEM aktĂ­v, de a kĂłd-struktĂşra fennmarad
 * arra az esetre, ha Ăşjra aktivĂˇlnĂˇk vagy mĂˇs ĂˇtutalĂˇsi
 * partnert integrĂˇlnak (MoneyGram, Ria, stb.).
 *
 * ĂLLAPOT: STUB â€” nincs Ă©lĹ‘ integrĂˇciĂł, minden endpoint
 * HTTP 501 Not Implemented vĂˇlaszt ad.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/western-union-stub")
@Tag(name = "Western Union (STUB)", description = "Western Union integrĂˇciĂł â€” jelenleg inaktĂ­v")
@Slf4j
public class WesternUnionStubController {

    @PostMapping("/send")
    @Operation(summary = "[STUB] PĂ©nzkĂĽldĂ©s indĂ­tĂˇsa")
    public ResponseEntity<Map<String, Object>> sendMoney(@Valid @RequestBody Map<String, Object> request) {
        log.warn("Western Union STUB hĂ­vĂˇs: /send â€” partner inaktĂ­v");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "Western Union integrĂˇciĂł jelenleg inaktĂ­v. Partner megszĹ±ntette az egyĂĽttmĹ±kĂ¶dĂ©st.",
                "legacyModule", "WUNION.DLL"
        ));
    }

    @PostMapping("/receive")
    @Operation(summary = "[STUB] PĂ©nz ĂˇtvĂ©tel")
    public ResponseEntity<Map<String, Object>> receiveMoney(@Valid @RequestBody Map<String, Object> request) {
        log.warn("Western Union STUB hĂ­vĂˇs: /receive â€” partner inaktĂ­v");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "Western Union integrĂˇciĂł jelenleg inaktĂ­v."
        ));
    }

    @GetMapping("/status/{mtcn}")
    @Operation(summary = "[STUB] TranzakciĂł stĂˇtusz lekĂ©rdezĂ©s")
    public ResponseEntity<Map<String, Object>> getStatus(@PathVariable String mtcn) {
        log.warn("Western Union STUB hĂ­vĂˇs: /status/{} â€” partner inaktĂ­v", mtcn);
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "mtcn", mtcn,
                "message", "Western Union integrĂˇciĂł jelenleg inaktĂ­v."
        ));
    }

    @GetMapping("/rates")
    @Operation(summary = "[STUB] WU Ăˇrfolyamok lekĂ©rdezĂ©se")
    public ResponseEntity<Map<String, Object>> getRates() {
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "Western Union Ăˇrfolyam szolgĂˇltatĂˇs nem elĂ©rhetĹ‘."
        ));
    }
}
