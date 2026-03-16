package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.stocksnapshot.StockSnapshotDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.StockSnapshotExcelService;
import hu.puzzleir.valuta.service.StockSnapshotService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/stock-snapshot")
@RequiredArgsConstructor
@Slf4j
public class StockSnapshotController {

    private final StockSnapshotService snapshotService;
    private final StockSnapshotExcelService excelService;

    @GetMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<StockSnapshotDto> getSnapshot() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        StockSnapshotDto snapshot = snapshotService.getFullSnapshot(companyId);
        return ResponseEntity.ok(snapshot);
    }

    @GetMapping("/excel")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<byte[]> downloadExcel() throws IOException {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        StockSnapshotDto snapshot = snapshotService.getFullSnapshot(companyId);
        byte[] xlsx = excelService.generateFullWorkbook(snapshot);

        String filename = "keszlet-export-" + LocalDate.now() + ".xlsx";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .contentLength(xlsx.length)
                .body(xlsx);
    }
}
