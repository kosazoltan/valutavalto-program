package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.levy.TransactionLevyRateCreateRequest;
import hu.puzzleir.valuta.dto.levy.TransactionLevyRateDto;
import hu.puzzleir.valuta.service.TransactionLevyRateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * FK-099 — append-only illeték-ráta history végpontok.
 *
 * <p>FR-1: CSAK GET és POST létezik — PUT/PATCH/DELETE szándékosan nincs
 * (a TransactionLevyControllerSecurityTest reflexióval pineli). D10:
 * osztály-szintű {@code @PreAuthorize("isAuthenticated()")} — a szerep-döntés
 * a service-ben történik, hogy a megtagadás ACCESS_DENIED audit-sort kapjon
 * (FR-18).</p>
 */
@RestController
@RequestMapping("/api/v1/transaction-levy-rates")
@PreAuthorize("isAuthenticated()")
@RequiredArgsConstructor
public class TransactionLevyRateController {

    private final TransactionLevyRateService rateService;

    @GetMapping
    public List<TransactionLevyRateDto> list() {
        return rateService.list();
    }

    @PostMapping
    public ResponseEntity<TransactionLevyRateDto> create(
            @Valid @RequestBody TransactionLevyRateCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(rateService.create(request));
    }
}
