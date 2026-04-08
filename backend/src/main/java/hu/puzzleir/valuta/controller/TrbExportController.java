package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.trb.TrbExportDto;
import hu.puzzleir.valuta.service.TrbExportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDate;

/**
 * TRB Export controller — legacy Import felíró menüpont modern megfelelője.
 *
 * Legacy: unit5.pas MAKEIMPORT → WImport (TXT) + ExcelTablaKeszito (XLS)
 * A főértéktáros számára: napi összesítő fájl generálás cégenként.
 */
@RestController
@RequestMapping("/api/v1/trb-export")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
public class TrbExportController {

    private final TrbExportService trbExportService;

    /**
     * JSON előnézet — frontend táblázathoz.
     * GET /api/v1/trb-export/preview?date=2026-04-07
     */
    @GetMapping("/preview")
    public ResponseEntity<TrbExportDto> getPreview(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return ResponseEntity.ok(trbExportService.getPreview(date));
    }

    /**
     * TRB TXT fájl letöltés (legacy-kompatibilis formátum).
     * GET /api/v1/trb-export/txt?date=2026-04-07
     */
    @GetMapping("/txt")
    public ResponseEntity<byte[]> downloadTxt(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        byte[] txt = trbExportService.generateTxt(date);
        String filename = "trb-export-" + date + ".txt";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.TEXT_PLAIN)
                .contentLength(txt.length)
                .body(txt);
    }

    /**
     * TRB Excel letöltés (bankforgalom + ügyfélforgalom + pénztárállomány lapokkal).
     * GET /api/v1/trb-export/excel?date=2026-04-07
     */
    @GetMapping("/excel")
    public ResponseEntity<byte[]> downloadExcel(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) throws IOException {
        byte[] xlsx = trbExportService.generateExcel(date);
        String filename = "trb-export-" + date + ".xlsx";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .contentLength(xlsx.length)
                .body(xlsx);
    }
}
