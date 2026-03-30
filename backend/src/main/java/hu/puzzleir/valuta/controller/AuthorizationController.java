package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.authorization.AuthorizationDto;
import hu.puzzleir.valuta.dto.authorization.CreateAuthorizationDto;
import hu.puzzleir.valuta.entity.Authorization;
import hu.puzzleir.valuta.service.AuthorizationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Authorization controller — meghatalmazás jogosultságok kezelése.
 * CRUD + verify/suspend/revoke workflow.
 */
@RestController
@RequestMapping("/api/v1/authorized-representatives")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
public class AuthorizationController {

    private final AuthorizationService authorizationService;

    /**
     * Meghatalmazott jogosultságainak listázása.
     * GET /api/v1/authorized-representatives/{representativeId}/authorizations
     */
    @GetMapping("/{representativeId}/authorizations")
    public ResponseEntity<List<AuthorizationDto>> findByRepresentative(@PathVariable UUID representativeId) {
        return ResponseEntity.ok(
            authorizationService.findByRepresentativeId(representativeId).stream()
                .map(this::toDto)
                .collect(Collectors.toList())
        );
    }

    /**
     * Új jogosultság létrehozása.
     * POST /api/v1/authorized-representatives/{representativeId}/authorizations
     */
    @PostMapping("/{representativeId}/authorizations")
    public ResponseEntity<AuthorizationDto> create(
            @PathVariable UUID representativeId,
            @Valid @RequestBody CreateAuthorizationDto dto,
            @RequestParam(required = false) Long workerId) {
        Authorization auth = toEntity(dto, representativeId);
        Authorization saved = authorizationService.create(auth);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved));
    }

    /**
     * Jogosultság jóváhagyása (PENDING → ACTIVE).
     * POST /api/v1/authorized-representatives/authorizations/{authorizationId}/verify
     */
    @PostMapping("/authorizations/{authorizationId}/verify")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<AuthorizationDto> verify(
            @PathVariable UUID authorizationId,
            @RequestParam Long workerId,
            @RequestParam(required = false) String notes) {
        return ResponseEntity.ok(toDto(authorizationService.verify(authorizationId, workerId, notes)));
    }

    /**
     * Jogosultság felfüggesztése (ACTIVE → SUSPENDED).
     * POST /api/v1/authorized-representatives/authorizations/{authorizationId}/suspend
     */
    @PostMapping("/authorizations/{authorizationId}/suspend")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<AuthorizationDto> suspend(
            @PathVariable UUID authorizationId,
            @RequestParam Long workerId,
            @RequestParam String reason) {
        return ResponseEntity.ok(toDto(authorizationService.suspend(authorizationId, workerId, reason)));
    }

    /**
     * Jogosultság visszavonása (→ REVOKED, végleges).
     * POST /api/v1/authorized-representatives/authorizations/{authorizationId}/revoke
     */
    @PostMapping("/authorizations/{authorizationId}/revoke")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<AuthorizationDto> revoke(
            @PathVariable UUID authorizationId,
            @RequestParam Long workerId,
            @RequestParam String reason) {
        return ResponseEntity.ok(toDto(authorizationService.revoke(authorizationId, workerId, reason)));
    }

    // --- Mapping ---

    private AuthorizationDto toDto(Authorization entity) {
        return AuthorizationDto.builder()
                .id(entity.getId())
                .representativeId(entity.getRepresentativeId())
                .operationDid(entity.getOperationDid())
                .authorizationTypeDid(entity.getAuthorizationTypeDid())
                .statusDid(entity.getStatusDid())
                .startDate(entity.getStartDate())
                .expiryDate(entity.getExpiryDate())
                .singleTransactionLimit(entity.getSingleTransactionLimit())
                .maxAmount(entity.getMaxAmount())
                .maxTransactionCount(entity.getMaxTransactionCount())
                .usedTransactionCount(entity.getUsedTransactionCount())
                .usedAmount(entity.getUsedAmount())
                .notes(entity.getNotes())
                .statusReason(entity.getStatusReason())
                .verifiedAt(entity.getVerifiedAt())
                .createdAt(entity.getCreatedAt())
                .build();
    }

    private Authorization toEntity(CreateAuthorizationDto dto, UUID representativeId) {
        return Authorization.builder()
                .representativeId(representativeId)
                .operationDid(dto.getOperationDid())
                .authorizationTypeDid(dto.getAuthorizationTypeDid())
                .startDate(dto.getStartDate())
                .expiryDate(dto.getExpiryDate())
                .singleTransactionLimit(dto.getSingleTransactionLimit())
                .maxAmount(dto.getMaxAmount())
                .maxTransactionCount(dto.getMaxTransactionCount())
                .notes(dto.getNotes())
                .build();
    }
}
