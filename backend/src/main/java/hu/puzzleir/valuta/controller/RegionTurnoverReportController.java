package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.report.RegionTurnoverReportDto;
import hu.puzzleir.valuta.service.RegionTurnoverReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * G23 (EXCMD b8-forgalom FR-13..15): körzet-szintű havi forgalmi/trend riport.
 *
 * <p>Csak vezetői / körzeti / főértéktáros / admin szerepkör érheti el
 * (a többi forgalmi riporttal konzisztens). Multi-tenant a service-ben.</p>
 */
@RestController
@RequestMapping("/api/v1/reports/region-turnover")
@RequiredArgsConstructor
public class RegionTurnoverReportController {

    private final RegionTurnoverReportService service;

    /**
     * Körzet-szintű havi forgalmi riport.
     *
     * @param yearMonth a hónap "YYYY-MM" formátumban
     * @return régiónkénti forgalmi sorok + trend% az előző hónaphoz képest
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('MANAGER','TREASURY_MANAGER','MAIN_TREASURY','ADMIN',"
            + "'REGIONAL_MANAGER','SUPERVISOR','CASHIER_SUPERVISOR')")
    public ResponseEntity<RegionTurnoverReportDto> getRegionTurnover(
            @RequestParam String yearMonth) {
        return ResponseEntity.ok(service.getRegionTurnover(yearMonth));
    }
}
