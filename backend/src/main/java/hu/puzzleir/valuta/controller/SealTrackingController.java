package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.seal.SealTrackingDto;
import hu.puzzleir.valuta.entity.SealTracking;
import hu.puzzleir.valuta.service.SealTrackingService;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/v1/seal-tracking")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@Validated
public class SealTrackingController {

    private final SealTrackingService sealTrackingService;

    private SealTrackingDto toDto(SealTracking entity) {
        return SealTrackingDto.builder()
                .id(entity.getId())
                .companyId(entity.getCompanyId())
                .transferType(entity.getTransferType())
                .transferId(entity.getTransferId())
                .sealNumber(entity.getSealNumber())
                .sealedAt(entity.getSealedAt())
                .sealedBy(entity.getSealedBy())
                .openedAt(entity.getOpenedAt())
                .openedBy(entity.getOpenedBy())
                .transitStatus(entity.getTransitStatus())
                .notes(entity.getNotes())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    @PostMapping("/seal")
    public ResponseEntity<SealTrackingDto> seal(
            @RequestParam @NotBlank String transferType,
            @RequestParam @NotNull Long transferId,
            @RequestParam @NotBlank String sealNumber) {
        return ResponseEntity.ok(toDto(sealTrackingService.seal(transferType, transferId, sealNumber)));
    }

    @PostMapping("/start-transit")
    public ResponseEntity<SealTrackingDto> startTransit(
            @RequestParam @NotBlank String transferType,
            @RequestParam @NotNull Long transferId) {
        return ResponseEntity.ok(toDto(sealTrackingService.startTransit(transferType, transferId)));
    }

    @PostMapping("/confirm-arrival")
    public ResponseEntity<SealTrackingDto> confirmArrival(
            @RequestParam @NotBlank String transferType,
            @RequestParam @NotNull Long transferId) {
        return ResponseEntity.ok(toDto(sealTrackingService.confirmArrival(transferType, transferId)));
    }

    @PostMapping("/open")
    public ResponseEntity<SealTrackingDto> openSeal(
            @RequestParam @NotBlank String transferType,
            @RequestParam @NotNull Long transferId) {
        return ResponseEntity.ok(toDto(sealTrackingService.openSeal(transferType, transferId)));
    }

    @GetMapping("/active")
    public ResponseEntity<List<SealTrackingDto>> getActive() {
        return ResponseEntity.ok(sealTrackingService.getActiveTransits().stream().map(this::toDto).toList());
    }

    @GetMapping("/by-seal/{sealNumber}")
    public ResponseEntity<SealTrackingDto> getBySealNumber(@PathVariable String sealNumber) {
        Optional<SealTracking> result = sealTrackingService.getBySealNumber(sealNumber);
        return result.map(entity -> ResponseEntity.ok(toDto(entity)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/by-transfer")
    public ResponseEntity<SealTrackingDto> getByTransfer(
            @RequestParam @NotBlank String transferType,
            @RequestParam @NotNull Long transferId) {
        Optional<SealTracking> result = sealTrackingService.getByTransfer(transferType, transferId);
        return result.map(entity -> ResponseEntity.ok(toDto(entity)))
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/validate")
    public ResponseEntity<Boolean> validateIntegrity(
            @RequestParam @NotBlank String transferType,
            @RequestParam @NotNull Long transferId,
            @RequestParam @NotBlank String expectedSealNumber) {
        boolean valid = sealTrackingService.validateSealIntegrity(transferType, transferId, expectedSealNumber);
        return ResponseEntity.ok(valid);
    }
}
