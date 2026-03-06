package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.dataimport.DataImportJobDto;
import hu.puzzleir.valuta.dto.dataimport.ImportRequestDto;
import hu.puzzleir.valuta.entity.DataImportJob;
import hu.puzzleir.valuta.service.DataImportService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

/**
 * Import felíró controller — fióki adatimport műveletek.
 *
 * Legacy: Import felíró DLL végpontjai.
 */
@RestController
@RequestMapping("/api/v1/data-import")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class DataImportController {

    private final DataImportService dataImportService;

    /**
     * Napi zárás import.
     * POST /api/v1/data-import/daily-closing
     */
    @PostMapping("/daily-closing")
    public ResponseEntity<DataImportJobDto> importDailyClosing(
            @Valid @RequestBody ImportRequestDto request) {
        DataImportJob job = dataImportService.importDailyClosing(
                request.getBranchId(), request.getDate());
        return ResponseEntity.ok(toDto(job));
    }

    /**
     * Készlet import.
     * POST /api/v1/data-import/inventory
     */
    @PostMapping("/inventory")
    public ResponseEntity<DataImportJobDto> importInventory(
            @Valid @RequestBody ImportRequestDto request) {
        DataImportJob job = dataImportService.importInventory(request.getBranchId());
        return ResponseEntity.ok(toDto(job));
    }

    /**
     * Tranzakció import.
     * POST /api/v1/data-import/transactions
     */
    @PostMapping("/transactions")
    public ResponseEntity<DataImportJobDto> importTransactions(
            @Valid @RequestBody ImportRequestDto request) {
        DataImportJob job = dataImportService.importTransactions(
                request.getBranchId(), request.getFromDate(), request.getToDate());
        return ResponseEntity.ok(toDto(job));
    }

    /**
     * Teljes import.
     * POST /api/v1/data-import/full
     */
    @PostMapping("/full")
    public ResponseEntity<DataImportJobDto> importFull(
            @Valid @RequestBody ImportRequestDto request) {
        DataImportJob job = dataImportService.importAll(request.getBranchId());
        return ResponseEntity.ok(toDto(job));
    }

    /**
     * Import történet.
     * GET /api/v1/data-import/history
     */
    @GetMapping("/history")
    public ResponseEntity<Page<DataImportJobDto>> getHistory(
            @RequestParam UUID branchId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Page<DataImportJob> jobs = dataImportService.getImportHistory(branchId, PageRequest.of(page, size));
        return ResponseEntity.ok(jobs.map(this::toDto));
    }

    /**
     * Sikertelen import újrapróbálás.
     * POST /api/v1/data-import/{id}/retry
     */
    @PostMapping("/{id}/retry")
    public ResponseEntity<DataImportJobDto> retry(@PathVariable UUID id) {
        DataImportJob job = dataImportService.retryFailed(id);
        return ResponseEntity.ok(toDto(job));
    }

    // ============ DTO KONVERZIÓ ============

    private DataImportJobDto toDto(DataImportJob job) {
        return DataImportJobDto.builder()
                .id(job.getId())
                .branchId(job.getBranch() != null ? job.getBranch().getId() : null)
                .importType(job.getImportType() != null ? job.getImportType().name() : null)
                .status(job.getStatus() != null ? job.getStatus().name() : null)
                .sourceType(job.getSourceType() != null ? job.getSourceType().name() : null)
                .sourceFile(job.getSourceFile())
                .totalRecords(job.getTotalRecords())
                .importedRecords(job.getImportedRecords())
                .failedRecords(job.getFailedRecords())
                .errorLog(job.getErrorLog())
                .startedAt(job.getStartedAt())
                .completedAt(job.getCompletedAt())
                .createdAt(job.getCreatedAt())
                .build();
    }
}
