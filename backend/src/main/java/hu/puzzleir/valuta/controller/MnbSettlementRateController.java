package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.mnbsettlement.MnbQueryRateDto;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateDto;
import hu.puzzleir.valuta.dto.mnbsettlement.MnbSettlementRateUpdateRequest;
import hu.puzzleir.valuta.service.MnbSettlementRateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/mnb-settlement-rates")
@RequiredArgsConstructor
public class MnbSettlementRateController {

    private final MnbSettlementRateService service;

    @GetMapping
    @PreAuthorize("hasAnyRole('FOERTEKTAR','BELSO_ELLENOR','UGYVEZETO')")
    public ResponseEntity<List<MnbSettlementRateDto>> list() {
        return ResponseEntity.ok(service.list());
    }

    /** FOERTEKTAR-only enforcement a service-guardban történik, mert ACCESS_DENIED audit kell a 403-hoz. */
    @GetMapping("/mnb-query")
    @PreAuthorize("hasAnyRole('FOERTEKTAR','BELSO_ELLENOR','UGYVEZETO')")
    public ResponseEntity<List<MnbQueryRateDto>> mnbQuery() {
        return ResponseEntity.ok(service.mnbQuery());
    }

    /** FOERTEKTAR-only enforcement a service-guardban történik, mert ACCESS_DENIED audit kell a 403-hoz. */
    @PutMapping
    @PreAuthorize("hasAnyRole('FOERTEKTAR','BELSO_ELLENOR','UGYVEZETO')")
    public ResponseEntity<List<MnbSettlementRateDto>> update(
            @Valid @RequestBody MnbSettlementRateUpdateRequest request) {
        return ResponseEntity.ok(service.update(request, false));
    }

    /** FOERTEKTAR-only enforcement a service-guardban történik, mert ACCESS_DENIED audit kell a 403-hoz. */
    @PutMapping("/publish")
    @PreAuthorize("hasAnyRole('FOERTEKTAR','BELSO_ELLENOR','UGYVEZETO')")
    public ResponseEntity<List<MnbSettlementRateDto>> publish(
            @Valid @RequestBody MnbSettlementRateUpdateRequest request) {
        return ResponseEntity.ok(service.update(request, true));
    }
}
