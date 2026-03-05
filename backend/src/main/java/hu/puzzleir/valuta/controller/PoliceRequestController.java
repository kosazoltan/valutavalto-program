package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.police.CreatePoliceRequestDto;
import hu.puzzleir.valuta.dto.police.PoliceRequestDto;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.PoliceRequestService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Rendőrségi adatkérés controller.
 *
 * Hatósági megkeresések nyilvántartása és feldolgozása.
 */
@RestController
@RequestMapping("/api/v1/police/requests")
@RequiredArgsConstructor
public class PoliceRequestController {

    private final PoliceRequestService policeRequestService;

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<PoliceRequestDto> createRequest(
            @Valid @RequestBody CreatePoliceRequestDto dto,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(policeRequestService.createRequest(dto, workerId));
    }

    @PostMapping("/{id}/process")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<PoliceRequestDto> processRequest(@PathVariable UUID id) {
        return ResponseEntity.ok(policeRequestService.processRequest(id));
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<Page<PoliceRequestDto>> getRequests(Pageable pageable) {
        return ResponseEntity.ok(policeRequestService.getRequestHistory(pageable));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<PoliceRequestDto> getRequest(@PathVariable UUID id) {
        return ResponseEntity.ok(policeRequestService.getRequest(id));
    }

    // ============ HELPERS ============

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new com.puzzleir.backend.exception.ValidationException("Hitelesítés szükséges!");
    }
}
