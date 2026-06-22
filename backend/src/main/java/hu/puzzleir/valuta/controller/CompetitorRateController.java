package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.competitor.CompetitorRateEntryDto;
import hu.puzzleir.valuta.dto.competitor.CompetitorTodayRateDto;
import hu.puzzleir.valuta.dto.competitor.CompetitorWatchBootstrapDto;
import hu.puzzleir.valuta.service.CompetitorRateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * FK-041/II — versenytárs-árfolyam BEVITEL végpontjai az „árfolyam néző" szerepkörnek (dedikált,
 * a területén lévő versenyhelyek árfolyamainak rögzítésére). A főértéktáros/ügyvezető/admin is elérheti.
 *
 * <p>Auth: az árfolyam néző aktív szerepköre {@code arfolyam_nezo} → a JwtAuthenticationFilter
 * {@code ROLE_ARFOLYAM_NEZO} authority-t képez belőle.</p>
 */
@RestController
@RequestMapping("/api/v1/competitor-rates")
@RequiredArgsConstructor
public class CompetitorRateController {

    private static final String WATCHER_ROLES =
            "hasAnyRole('ARFOLYAM_NEZO', 'FOERTEKTAR', 'UGYVEZETO', 'ADMIN')";

    private final CompetitorRateService competitorRateService;

    /** A beíró oldal bootstrapja: a hívó régiójának versenyhelyei + a figyelt valutakosár. */
    @PreAuthorize(WATCHER_ROLES)
    @GetMapping("/bootstrap")
    public ResponseEntity<CompetitorWatchBootstrapDto> getBootstrap() {
        return ResponseEntity.ok(competitorRateService.getBootstrap());
    }

    /** Egy versenyhely MAI bevitt versenytárs-árfolyamai (előtöltéshez). */
    @PreAuthorize(WATCHER_ROLES)
    @GetMapping("/today")
    public ResponseEntity<List<CompetitorTodayRateDto>> getTodayRates(@RequestParam UUID competitorId) {
        return ResponseEntity.ok(competitorRateService.getTodayRates(competitorId));
    }

    /** Versenytárs-árfolyam beküldés (upsert versenyhely + valuta + ma szerint). */
    @PreAuthorize(WATCHER_ROLES)
    @PostMapping
    public ResponseEntity<Void> submit(@Valid @RequestBody CompetitorRateEntryDto dto) {
        competitorRateService.submit(dto);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}
