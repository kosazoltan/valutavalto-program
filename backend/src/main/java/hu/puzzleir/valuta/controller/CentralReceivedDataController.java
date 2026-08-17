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
// olvashatnák a company-wide turnover/branch riportokat.
//
// Authority-források (JwtAuthenticationFilter):
// - Legacy WorkerRole (CASHIER/SUPERVISOR/MANAGER/ADMIN) → ROLE_<UPPER> authority
// - Active canonical role → ROLE_<NORMALIZED> authority (normalizeOperationalRoleForAuthority)
//   Pl. activeRole "REGIONAL_MGR" → ROLE_TERULETI_VEZETO, "CHIEF_VAULT" → ROLE_FOERTEKTAR
//
// A CentralModuleManifest a frontend menüt szűri canonical role kódokkal (foertektar,
// ugyvezeto, belso_ellenor, teruleti_vezeto a "received-data" modulhoz), de a backend
// @PreAuthorize közvetlenül a Spring Security authority-kből dolgozik.
// Ezért a guard mindkét csatornát lefedi: legacy SUPERVISOR/MANAGER/ADMIN (CASHIER-t kizárja)
// + 4 canonical received-data role (Copilot P1 #577 follow-up — canonical-only worker,
// pl. CASHIER legacy + foertektar canonical, ne kapjon hamis 403-at).
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO', 'BELSO_ELLENOR', 'TERULETI_VEZETO')")
public class CentralReceivedDataController {

    private final CentralReceivedDataService centralReceivedDataService;

    @GetMapping("/status")
    public ResponseEntity<CentralReceivedDataOverviewDto> getStatus(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        // FK-088 FR-3: a képernyő referencia-dátuma az intervallum VÉGE (endDate). Az új
        // paraméter ADDITÍV: a régi kliensek `date` paraméterét továbbra is elfogadjuk
        // (prioritás: endDate > date > ma). A service-aláírás nem változik.
        LocalDate reportDate = endDate != null ? endDate : (date != null ? date : LocalDate.now());
        log.info("GET /api/v1/central/received-data/status endDate={}, date={}, resolved={}",
                endDate, date, reportDate);
        return ResponseEntity.ok(centralReceivedDataService.getOverview(reportDate));
    }
}
