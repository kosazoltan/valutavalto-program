package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.daybook.HufDaybookDto;
import hu.puzzleir.valuta.service.HufDaybookPdfService;
import hu.puzzleir.valuta.service.HufDaybookService;
import java.io.IOException;
import java.time.LocalDate;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/daybook")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
public class HufDaybookController {

    private final HufDaybookService hufDaybookService;
    private final HufDaybookPdfService hufDaybookPdfService;

    @GetMapping("/{branchId}/{date}")
    public ResponseEntity<HufDaybookDto> getDaybook(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(hufDaybookService.getDaybook(branchId, date));
    }

    @GetMapping("/{branchId}/{date}/pdf")
    public ResponseEntity<byte[]> getDaybookPdf(
            @PathVariable UUID branchId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) throws IOException {
        byte[] pdf = hufDaybookPdfService.generatePdf(branchId, date);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.inline()
                        .filename("huf-daybook-" + date + ".pdf")
                        .build()
                        .toString())
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }
}
