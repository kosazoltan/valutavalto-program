package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.circular.*;
import hu.puzzleir.valuta.entity.CircularType;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.CircularService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Körlevél controller.
 *
 * Legacy: ERTEKTAR — korlev.dll
 */
@RestController
@RequestMapping("/api/v1/circulars")
@RequiredArgsConstructor
public class CircularController {

    private final CircularService circularService;

    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CircularDto>> findAll() {
        return ResponseEntity.ok(circularService.findAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CircularDto> findById(@PathVariable Long id) {
        return ResponseEntity.ok(circularService.findById(id));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CircularDto> create(
            @Valid @RequestBody CreateCircularDto dto,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(circularService.create(dto, workerId));
    }

    @PostMapping("/{id}/acknowledge")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CircularDto> acknowledge(@PathVariable Long id) {
        return ResponseEntity.ok(circularService.acknowledge(id));
    }

    @GetMapping("/unacknowledged")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CircularDto>> findUnacknowledged() {
        return ResponseEntity.ok(circularService.findUnacknowledged());
    }

    // ============ ÚJ ENDPOINTOK — Típusok + Célcsoport ============

    @GetMapping("/types")
    @Operation(summary = "Összes elérhető körlevél típus listázása")
    public ResponseEntity<List<Map<String, Object>>> listTypes() {
        return ResponseEntity.ok(circularService.listTypes());
    }

    @GetMapping("/by-type/{type}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevelek szűrése típus szerint")
    public ResponseEntity<List<CircularDto>> findByType(@PathVariable CircularType type) {
        return ResponseEntity.ok(circularService.findByType(type));
    }

    @GetMapping("/relevant")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "Az aktuális irodához releváns nem nyugtázott körlevelek")
    public ResponseEntity<List<CircularDto>> findRelevant() {
        return ResponseEntity.ok(circularService.findRelevantForCurrentBranch());
    }

    @PostMapping("/typed")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevél létrehozása típussal és célcsoporttal")
    public ResponseEntity<CircularDto> createTyped(
            @Valid @RequestBody TypedCircularRequest request,
            Authentication auth) {
        Long workerId = getWorkerId(auth);

        CreateCircularDto dto = new CreateCircularDto();
        dto.setTitle(request.title());
        dto.setContent(request.content());
        dto.setUrgent(request.urgent());

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(circularService.createTyped(
                        dto, workerId,
                        request.circularType(),
                        request.target(),
                        request.priority(),
                        request.targetBranchId(),
                        request.targetCompanyId(),
                        request.registrationNumber()));
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevél keresés iktatószám alapján")
    public ResponseEntity<List<CircularDto>> search(@RequestParam String q) {
        return ResponseEntity.ok(circularService.searchByRegistrationNumber(q));
    }

    // --- Request DTO ---
    record TypedCircularRequest(
        String title,
        String content,
        Boolean urgent,
        CircularType circularType,
        CircularType.CircularTarget target,
        CircularType.CircularPriority priority,
        UUID targetBranchId,
        Integer targetCompanyId,
        String registrationNumber
    ) {}

    // ============ HELPERS ============

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new hu.puzzleir.valuta.exception.ValidationException("Hitelesítés szükséges!");
    }
}
