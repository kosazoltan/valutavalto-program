package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.datacollection.*;
import hu.puzzleir.valuta.entity.DataCollection;
import hu.puzzleir.valuta.service.DataCollectionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Adatgyűjtő szerver controller.
 *
 * A központi szerver gyűjti össze az irodák napi adatait.
 */
@RestController
@RequestMapping("/api/v1/data-collection")
@RequiredArgsConstructor
public class DataCollectionController {

    private final DataCollectionService dataCollectionService;

    /**
     * Egy iroda adatgyűjtése.
     * POST /api/v1/data-collection/collect
     */
    @PostMapping("/collect")
    public ResponseEntity<DataCollectionDto> collectBranch(
            @Valid @RequestBody CollectRequestDto request) {
        DataCollection result = dataCollectionService.collectBranchData(
            request.getBranchId(), request.getDate());
        return ResponseEntity.ok(toDto(result));
    }

    /**
     * Összes iroda adatgyűjtése.
     * POST /api/v1/data-collection/collect-all
     */
    @PostMapping("/collect-all")
    public ResponseEntity<List<DataCollectionDto>> collectAll(
            @Valid @RequestBody CollectAllRequestDto request) {
        List<DataCollection> results = dataCollectionService.collectAllBranches(request.getDate());
        return ResponseEntity.ok(
            results.stream().map(this::toDto).collect(Collectors.toList()));
    }

    /**
     * Gyűjtés státusz lekérdezése.
     * GET /api/v1/data-collection/status
     */
    @GetMapping("/status")
    public ResponseEntity<DataCollectionDto> getStatus(
            @RequestParam UUID branchId,
            @RequestParam LocalDate date) {
        DataCollection dc = dataCollectionService.getCollectionStatus(branchId, date);
        return ResponseEntity.ok(toDto(dc));
    }

    /**
     * Sikertelen gyűjtések újrapróbálása.
     * POST /api/v1/data-collection/retry
     */
    @PostMapping("/retry")
    public ResponseEntity<Map<String, Integer>> retryFailed() {
        int retried = dataCollectionService.retryFailedCollections();
        return ResponseEntity.ok(Map.of("retriedCount", retried));
    }

    // ============ DTO KONVERZIÓ ============

    private DataCollectionDto toDto(DataCollection dc) {
        return DataCollectionDto.builder()
            .id(dc.getId())
            .branchId(dc.getBranch() != null ? dc.getBranch().getId() : null)
            .collectionDate(dc.getCollectionDate())
            .status(dc.getStatus().name())
            .collectionType(dc.getCollectionType().name())
            .transactionCount(dc.getTransactionCount())
            .totalBuyHuf(dc.getTotalBuyHuf())
            .totalSellHuf(dc.getTotalSellHuf())
            .startedAt(dc.getStartedAt())
            .completedAt(dc.getCompletedAt())
            .errorMessage(dc.getErrorMessage())
            .createdAt(dc.getCreatedAt())
            .build();
    }
}
