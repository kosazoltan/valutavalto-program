package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.sanction.SanctionScreeningRequest;
import hu.puzzleir.valuta.dto.sanction.SanctionScreeningResult;
import hu.puzzleir.valuta.dto.sanction.SanctionStatusResponse;
import hu.puzzleir.valuta.entity.SanctionEntry;
import hu.puzzleir.valuta.repository.SanctionEntryRepository;
import hu.puzzleir.valuta.service.SanctionScreeningService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.security.Principal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/**
 * Szankciós szűrés controller.
 *
 * POST /api/v1/sanctions/screen  — ügyfél szűrés (minden pénztáros)
 * GET  /api/v1/sanctions/list    — lista lekérés (admin)
 * POST /api/v1/sanctions/import  — XML import (admin)
 * GET  /api/v1/sanctions/status  — utolsó frissítés dátuma
 */
@RestController
@RequestMapping("/api/v1/sanctions")
@RequiredArgsConstructor
public class SanctionScreeningController {

    private final SanctionScreeningService screeningService;
    private final SanctionEntryRepository sanctionEntryRepository;

    /**
     * Ügyfél szűrés — tranzakció előtt KÖTELEZŐ.
     */
    @PostMapping("/screen")
    public ResponseEntity<SanctionScreeningResult> screenCustomer(
            @Valid @RequestBody SanctionScreeningRequest request,
            Principal principal
    ) {
        String workerId = principal != null ? principal.getName() : "unknown";
        SanctionScreeningResult result = screeningService.screenCustomer(
                request.getName(),
                request.getDocumentNumber(),
                request.getDateOfBirth(),
                workerId,
                workerId,
                null // branchCode a SecurityContext-ből jön majd
        );
        return ResponseEntity.ok(result);
    }

    /**
     * Szankciós lista lekérés — admin.
     */
    @GetMapping("/list")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<SanctionEntry>> listEntries(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size
    ) {
        return ResponseEntity.ok(
                sanctionEntryRepository.findAll(PageRequest.of(page, size)).getContent()
        );
    }

    /**
     * ENSZ XML szankciós lista import — admin.
     */
    @PostMapping(value = "/import", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, Object>> importList(
            @RequestParam("file") MultipartFile file
    ) {
        try {
            int count = screeningService.importSanctionList(file.getInputStream());
            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                    "imported", count,
                    "message", count + " bejegyzés sikeresen importálva"
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "error", "Import hiba: " + e.getMessage()
            ));
        }
    }

    /**
     * Szankciós lista státusz — utolsó frissítés + aktív bejegyzések száma.
     */
    @GetMapping("/status")
    public ResponseEntity<SanctionStatusResponse> getStatus() {
        LocalDate lastUpdate = screeningService.getLastUpdateDate();
        long activeCount = screeningService.getActiveCount();

        return ResponseEntity.ok(SanctionStatusResponse.builder()
                .lastUpdateDate(lastUpdate)
                .activeEntryCount(activeCount)
                .build());
    }
}
