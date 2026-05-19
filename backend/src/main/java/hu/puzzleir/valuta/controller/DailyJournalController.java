package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.service.DailyJournalService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Napkönyv (daily transaction journal) PDF REST endpoint — legacy NAPKONYV parity.
 *
 * <p>Sprint A P2.4 (v2.5.68).</p>
 */
@RestController
@RequestMapping("/api/v1/reports/daily-journal")
@RequiredArgsConstructor
@Slf4j
public class DailyJournalController {

    private final DailyJournalService service;

    /**
     * Napkönyv PDF letöltés.
     *
     * @param branchId iroda UUID
     * @param date     YYYY-MM-DD
     * @return PDF byte stream
     */
    @GetMapping(produces = MediaType.APPLICATION_PDF_VALUE)
    @PreAuthorize("hasAnyRole('CASHIER','SUPERVISOR','CASHIER_SUPERVISOR',"
            + "'MANAGER','TREASURY_MANAGER','MAIN_TREASURY','REGIONAL_MANAGER','ADMIN')")
    public ResponseEntity<byte[]> generate(
            @RequestParam UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) throws IOException {
        byte[] pdf = service.generatePdf(branchId, date);

        String filename = String.format("napkonyv-%s-%s.pdf", date, branchId.toString().substring(0, 8));

        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }
}
