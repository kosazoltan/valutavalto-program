package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ratemaker.LocalRateMakerBootstrapDto;
import hu.puzzleir.valuta.dto.ratemaker.LocalRatePackageDto;
import hu.puzzleir.valuta.dto.ratemaker.LocalRatePublishResponseDto;
import hu.puzzleir.valuta.dto.ratemaker.RateMakerSheetDto;
import hu.puzzleir.valuta.dto.ratemaker.RateMakerSheetUpdateRequest;
import hu.puzzleir.valuta.entity.RateMakerSheet;
import hu.puzzleir.valuta.service.RateCreationService;
import hu.puzzleir.valuta.service.RateMakerSheetService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/local-rate-maker")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('FOERTEKTAR', 'UGYVEZETO', 'ADMIN')")
public class LocalRateMakerController {

    private static final String ENDPOINT_PUBLISH = "POST /api/v1/local-rate-maker/packages/publish";

    private final RateCreationService rateCreationService;
    private final RateMakerSheetService rateMakerSheetService;
    private final IdempotencyGuard idempotencyGuard;

    @GetMapping("/bootstrap")
    public ResponseEntity<LocalRateMakerBootstrapDto> bootstrap() {
        return ResponseEntity.ok(rateCreationService.getLocalRateMakerBootstrap());
    }

    /**
     * A munkaív (rate-maker working sheet) szerver-oldali állapota — a vékony kliens ezt olvassa
     * be ALAPként megnyitáskor (más gépről indítva is). 204, ha még nincs munkaív a cégnek.
     */
    @GetMapping("/sheet")
    public ResponseEntity<RateMakerSheetDto> getSheet() {
        return rateMakerSheetService.getSheet()
                .map(s -> ResponseEntity.ok(toDto(s)))
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /**
     * A munkaív feltöltése (PUSH) — a vékony kliens (vagy a központi modul) felülírja a szerver
     * replikáját és növeli a verziót. A vékony kliens az igazságforrás aktív szerkesztéskor.
     */
    @PutMapping("/sheet")
    public ResponseEntity<RateMakerSheetDto> putSheet(@Valid @RequestBody RateMakerSheetUpdateRequest request) {
        RateMakerSheet saved = rateMakerSheetService.upsertSheet(
                request.sheetJson(), request.source(), request.deviceId(), request.baseVersion());
        return ResponseEntity.ok(toDto(saved));
    }

    private static RateMakerSheetDto toDto(RateMakerSheet s) {
        return new RateMakerSheetDto(
                s.getSheetJson(), s.getVersion(), s.getSource(),
                s.getDeviceId(), s.getUpdatedBy(), s.getUpdatedAt());
    }

    @PostMapping("/packages/publish")
    public ResponseEntity<LocalRatePublishResponseDto> publishPackage(
            @RequestHeader(name = "Idempotency-Key", required = false) String idempotencyKey,
            @RequestHeader(name = "X-Idempotency-Key", required = false) String legacyIdempotencyKey,
            @Valid @RequestBody LocalRatePackageDto packageDto) {

        String effectiveIdempotencyKey = idempotencyKey != null && !idempotencyKey.isBlank()
                ? idempotencyKey
                : legacyIdempotencyKey;

        IdempotencyGuard.Acquired<LocalRatePublishResponseDto> acquired =
                idempotencyGuard.tryAcquire(
                        effectiveIdempotencyKey,
                        ENDPOINT_PUBLISH,
                        packageDto,
                        LocalRatePublishResponseDto.class);

        if (acquired.cachedResult() != null) {
            return ResponseEntity.status(HttpStatus.CREATED).body(acquired.cachedResult());
        }

        try {
            LocalRatePublishResponseDto response = rateCreationService.publishLocalRatePackage(packageDto);
            idempotencyGuard.complete(acquired, response);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException e) {
            idempotencyGuard.fail(acquired);
            throw e;
        }
    }
}
