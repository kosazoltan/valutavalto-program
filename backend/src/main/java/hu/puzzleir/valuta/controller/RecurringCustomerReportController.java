package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.report.RecurringCustomerDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.RecurringCustomerReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Időszakos (visszatérő) ügyfél monitoring REST endpoint — legacy ugyfelcontrol/idoszakos parity.
 *
 * <p>v2.5.74 Sprint P3.3: AML frequent-customer detection. Csak compliance/vezetői
 * szerepkör érheti el (fokozott ügyfél-átvilágítás Pmt. 16. § alapján).</p>
 */
@RestController
@RequestMapping("/api/v1/reports/recurring-customers")
@RequiredArgsConstructor
@Tag(name = "Visszatérő ügyfél monitoring", description = "AML frequent-customer detection (Pmt. 16. §)")
public class RecurringCustomerReportController {

    private final RecurringCustomerReportService service;

    /**
     * Visszatérő ügyfelek riport — azon ügyfelek, akik az időszakban ≥ minTransactions
     * alkalommal tranzaktáltak. Multi-tenant: a jelenlegi cégre szűrve.
     *
     * @param from            időszak kezdete (YYYY-MM-DD)
     * @param to              időszak vége (YYYY-MM-DD, inclusive)
     * @param minTransactions küszöb (default 3, min 2)
     */
    @GetMapping
    @PreAuthorize("hasAnyRole('COMPLIANCE_OFFICER','BELSO_ELLENOR','AUDITOR',"
            + "'MANAGER','TREASURY_MANAGER','MAIN_TREASURY','REGIONAL_MANAGER','ADMIN')")
    @Operation(summary = "Visszatérő ügyfelek (≥ N tranzakció) az időszakban — AML monitoring")
    public ResponseEntity<List<RecurringCustomerDto>> generate(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false, defaultValue = "3") int minTransactions
    ) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        return ResponseEntity.ok(service.generate(companyId, from, to, minTransactions));
    }
}
