package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.competition.CompetitionDto;
import hu.puzzleir.valuta.dto.competition.CompetitionEntryDto;
import hu.puzzleir.valuta.dto.competition.CreateCompetitionDto;
import hu.puzzleir.valuta.service.CompetitionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Pénztáros verseny REST végpontok.
 */
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/competitions")
@RequiredArgsConstructor
public class CompetitionController {

    private final CompetitionService competitionService;

    @GetMapping
    public ResponseEntity<List<CompetitionDto>> list() {
        return ResponseEntity.ok(competitionService.getAllCompetitions());
    }

    @PostMapping
    public ResponseEntity<CompetitionDto> create(@Valid @RequestBody CreateCompetitionDto dto) {
        return ResponseEntity.ok(competitionService.createCompetition(dto));
    }

    @PostMapping("/{id}/calculate")
    public ResponseEntity<List<CompetitionEntryDto>> calculate(@PathVariable UUID id) {
        return ResponseEntity.ok(competitionService.calculateScores(id));
    }

    @GetMapping("/{id}/leaderboard")
    public ResponseEntity<List<CompetitionEntryDto>> leaderboard(@PathVariable UUID id) {
        return ResponseEntity.ok(competitionService.getLeaderboard(id));
    }
}
