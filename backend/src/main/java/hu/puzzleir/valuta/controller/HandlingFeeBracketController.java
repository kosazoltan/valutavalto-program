package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.handlingfee.BracketSetDto;
import hu.puzzleir.valuta.dto.handlingfee.HandlingFeeBracketDto;
import hu.puzzleir.valuta.service.BranchHandlingFeeConfigService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * FK-096 — közös (cégszintű) kezelési díj sáv-készlet végpontok (D11).
 * A publish SOROS írási út (PESSIMISTIC_WRITE zár, FR-11/D8).
 */
@RestController
@RequestMapping("/api/v1/handling-fee-bracket")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('UGYVEZETO','FOERTEKTAR','ADMIN')")
public class HandlingFeeBracketController {

    private final BranchHandlingFeeConfigService service;

    @GetMapping
    public ResponseEntity<BracketSetDto> get() {
        return ResponseEntity.ok(service.getBrackets());
    }

    @PostMapping("/draft")
    public ResponseEntity<BracketSetDto> saveDraft(@RequestBody List<HandlingFeeBracketDto> rows) {
        return ResponseEntity.ok(service.saveBracketDraft(rows));
    }

    @PostMapping("/publish")
    public ResponseEntity<BracketSetDto> publish() {
        return ResponseEntity.ok(service.publishBrackets());
    }
}
