package hu.puzzleir.valuta.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Western Union API stub — placeholder a WU integráció számára.
 *
 * Legacy: WUNION DLL — Western Union pénzátutalás kezelés.
 * A partner már NEM aktív, de a kód-struktúra fennmarad
 * arra az esetre, ha újra aktiválnák vagy más átutalási
 * partnert integrálnak (MoneyGram, Ria, stb.).
 *
 * ÁLLAPOT: STUB — nincs élő integráció, minden endpoint
 * HTTP 501 Not Implemented választ ad.
 */
@RestController
@RequestMapping("/api/v1/western-union")
@Tag(name = "Western Union (STUB)", description = "Western Union integráció — jelenleg inaktív")
@Slf4j
public class WesternUnionStubController {

    @PostMapping("/send")
    @Operation(summary = "[STUB] Pénzküldés indítása")
    public ResponseEntity<Map<String, Object>> sendMoney(@RequestBody Map<String, Object> request) {
        log.warn("Western Union STUB hívás: /send — partner inaktív");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "Western Union integráció jelenleg inaktív. Partner megszűntette az együttműködést.",
                "legacyModule", "WUNION.DLL"
        ));
    }

    @PostMapping("/receive")
    @Operation(summary = "[STUB] Pénz átvétel")
    public ResponseEntity<Map<String, Object>> receiveMoney(@RequestBody Map<String, Object> request) {
        log.warn("Western Union STUB hívás: /receive — partner inaktív");
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "Western Union integráció jelenleg inaktív."
        ));
    }

    @GetMapping("/status/{mtcn}")
    @Operation(summary = "[STUB] Tranzakció státusz lekérdezés")
    public ResponseEntity<Map<String, Object>> getStatus(@PathVariable String mtcn) {
        log.warn("Western Union STUB hívás: /status/{} — partner inaktív", mtcn);
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "mtcn", mtcn,
                "message", "Western Union integráció jelenleg inaktív."
        ));
    }

    @GetMapping("/rates")
    @Operation(summary = "[STUB] WU árfolyamok lekérdezése")
    public ResponseEntity<Map<String, Object>> getRates() {
        return ResponseEntity.status(501).body(Map.of(
                "status", "NOT_IMPLEMENTED",
                "message", "Western Union árfolyam szolgáltatás nem elérhető."
        ));
    }
}
