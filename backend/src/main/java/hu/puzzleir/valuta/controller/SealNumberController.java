package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.SealNumber;
import hu.puzzleir.valuta.entity.SealNumber.SealType;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.SealNumberService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Plomba szám REST API.
 *
 * Legacy: GETPLOMB — plomba nyilvántartás és generálás.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping({"/api/v1/seal-numbers", "/api/seal-numbers"})
@RequiredArgsConstructor
@Tag(name = "Plomba szám", description = "Plomba szám generálás és nyilvántartás")
public class SealNumberController {

    private final SealNumberService sealNumberService;

    @GetMapping("/next")
    @Operation(summary = "Következő plomba szám lekérése (preview)")
    public ResponseEntity<Map<String, String>> getNext(
            @RequestParam String branchCode) {
        String next = sealNumberService.getNextSealNumber(branchCode);
        return ResponseEntity.ok(Map.of("sealNumber", next));
    }

    @PostMapping("/generate")
    @Operation(summary = "Plomba szám generálása és mentése")
    public ResponseEntity<SealNumber> generate(
            @Valid @RequestBody GenerateRequest request) {
        SealNumber seal = sealNumberService.generate(
                request.branchCode(),
                request.sealType() != null ? request.sealType() : SealType.CLOSE,
                request.sessionId(),
                request.note());
        return ResponseEntity.ok(seal);
    }

    @PostMapping("/{id}/use")
    @Operation(summary = "Plomba felhasználásának rögzítése")
    public ResponseEntity<SealNumber> markAsUsed(
            @PathVariable UUID id,
            @RequestParam(required = false) UUID sessionId) {
        SealNumber seal = sealNumberService.markAsUsed(id, sessionId);
        return ResponseEntity.ok(seal);
    }

    @GetMapping("/today")
    @Operation(summary = "Mai plomba számok listázása")
    public ResponseEntity<List<SealNumber>> listToday() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return ResponseEntity.ok(sealNumberService.listToday(branchId));
    }

    @GetMapping("/unused")
    @Operation(summary = "Felhasználatlan plomba számok")
    public ResponseEntity<List<SealNumber>> listUnused() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        return ResponseEntity.ok(sealNumberService.listUnused(branchId));
    }

    // --- Request DTO ---
    record GenerateRequest(
        String branchCode,
        SealType sealType,
        UUID sessionId,
        String note
    ) {}
}
