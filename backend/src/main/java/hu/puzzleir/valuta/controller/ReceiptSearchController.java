package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.receipt.*;
import hu.puzzleir.valuta.service.ReceiptSearchService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.data.domain.Page;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * Bizonylat keresÄąâ€ controller.
 */
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
@RestController
@RequestMapping("/api/v1/receipts-search")
@RequiredArgsConstructor
public class ReceiptSearchController {

    private final ReceiptSearchService receiptSearchService;

    /**
     * GET /api/v1/receipts/search
     * Bizonylat keresÄ‚Â©s.
     */
    @GetMapping("/search")
    public ResponseEntity<Page<ReceiptSearchResultDto>> search(
            @RequestParam(required = false) String number,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateTo,
            @RequestParam(required = false) String type,
            @RequestParam(required = false) BigDecimal minAmount,
            @RequestParam(required = false) BigDecimal maxAmount,
            @RequestParam(required = false) String customer,
            Pageable pageable) {

        ReceiptSearchCriteria criteria = new ReceiptSearchCriteria(
                number, dateFrom, dateTo, type, minAmount, maxAmount, customer);

        return ResponseEntity.ok(receiptSearchService.search(criteria, pageable));
    }

    /**
     * GET /api/v1/receipts/{id}
     * Bizonylat rÄ‚Â©szletek.
     */
    
}
