package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.setup.SetupGoogleIdentifyRequestDto;
import hu.puzzleir.valuta.dto.setup.SetupGoogleIdentifyResponseDto;
import hu.puzzleir.valuta.service.SetupGoogleIdentificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/public/setup")
@RequiredArgsConstructor
@PreAuthorize("permitAll()")
public class SetupGoogleController {

    private final SetupGoogleIdentificationService setupGoogleIdentificationService;

    /**
     * First-run wizard Google OAuth auto-detection.
     *
     * <p>A requestben levo Google ID tokent a backend validalja, majd az emailt
     * a dolgozoi torzs / megosztott branch email alapjan azonosítja. Nyers email
     * alapjan nincs jogosultsag adva.</p>
     */
    @PostMapping("/google-identify")
    public ResponseEntity<SetupGoogleIdentifyResponseDto> identifyGoogleSetup(
            @Valid @RequestBody SetupGoogleIdentifyRequestDto request) {
        return ResponseEntity.ok(setupGoogleIdentificationService.identify(request));
    }
}
