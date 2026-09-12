package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.turnover.TurnoverReportDto;
import hu.puzzleir.valuta.service.VaultTurnoverService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.UUID;

/**
 * FKH-066: the vault arm's read of a cash desk's actual daily turnover.
 *
 * <p>Deliberately a SEPARATE controller from {@link TurnoverController}: that one is restricted to
 * head-vault and executive roles and has no territory filtering, so widening it would have opened
 * every branch of the company to every vault manager. This endpoint adds ERTEKTAR access together
 * with the territory guard, leaving the existing turnover endpoints untouched.</p>
 *
 * <p>Method-level {@code @PreAuthorize} as required by the ArchUnit rule
 * {@code restControllersMustBeSecured}.</p>
 */
@RestController
@RequestMapping("/api/v1/turnover")
@RequiredArgsConstructor
@Validated
@Slf4j
public class VaultTurnoverController {

    private final VaultTurnoverService vaultTurnoverService;

    /**
     * GET /api/v1/turnover/vault-daily?branchId=&amp;date=
     *
     * <p>A branch outside the caller's territory (or company) yields 404, not 403 - consistent
     * with the movement-log convention, so the response never confirms that such a branch exists.</p>
     */
    @GetMapping("/vault-daily")
    @PreAuthorize("hasAnyRole('ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO', 'BELSO_ELLENOR', 'PENZUGYI_VEZETO')")
    public ResponseEntity<TurnoverReportDto> vaultDaily(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("GET /api/v1/turnover/vault-daily branchId={}, date={}", branchId, date);
        return ResponseEntity.ok(vaultTurnoverService.getVaultDailyTurnover(branchId, date));
    }
}
