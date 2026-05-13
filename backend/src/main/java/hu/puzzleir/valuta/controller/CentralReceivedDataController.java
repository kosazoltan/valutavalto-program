package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.central.CentralReceivedDataOverviewDto;
import hu.puzzleir.valuta.service.CentralReceivedDataService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/v1/central/received-data")
@RequiredArgsConstructor
@Slf4j
// Codex P1 #560 fix: NEM isAuthenticated(), mert akkor cashier szintű account-ok is
// olvashatnák a company-wide turnover/branch riportokat. A CentralModuleManifest-ben
// a "received-data" canonical role-jai: foertektar, ugyvezeto, belso_ellenor,
// teruleti_vezeto.
// Codex P1 #577 follow-up: a canonical role-ok JWT-ben ROLE_FOERTEKTAR /
// ROLE_UGYVEZETO / ROLE_BELSO_ELLENOR / ROLE_TERULETI_VEZETO authority-ként
// érkeznek (JwtAuthenticationFilter.normalizeOperationalRoleForAuthority).
// Ezért a guard BOTH legacy + canonical role-okat felismeri, hogy a canonical-only
// worker-ek (pl. CASHIER legacy + foertektar canonical) NE kapjanak hamis 403-at.
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'BELSO_ELLENOR', 'TERULETI_VEZETO')")
public class CentralReceivedDataController {

    private final CentralReceivedDataService centralReceivedDataService;

    @GetMapping("/status")
    public ResponseEntity<CentralReceivedDataOverviewDto> getStatus(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate reportDate = date != null ? date : LocalDate.now();
        log.info("GET /api/v1/central/received-data/status date={}", reportDate);
        return ResponseEntity.ok(centralReceivedDataService.getOverview(reportDate));
    }
}
