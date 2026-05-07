package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.datacollection.*;
import hu.puzzleir.valuta.entity.DataCollection;
import hu.puzzleir.valuta.service.DataCollectionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

import org.springframework.lang.Nullable;

/**
 * Adatgyűjtő szerver controller.
 *
 * A központi szerver gyűjti össze az irodák napi adatait.
 */
@PreAuthorize("hasRole('ADMIN')")
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
        DataCollectionDto dto = toDto(result);
        return dataCollectionResponse(dto);
    }

    /**
     * Összes iroda adatgyűjtése.
     * POST /api/v1/data-collection/collect-all
     */
    @PostMapping("/collect-all")
    public ResponseEntity<List<DataCollectionDto>> collectAll(
            @Valid @RequestBody CollectAllRequestDto request) {
        List<DataCollection> results = dataCollectionService.collectAllBranches(request.getDate());
        List<DataCollectionDto> dtos = results.stream().map(this::toDto).collect(Collectors.toList());
        boolean allCompleted = dtos.stream().allMatch(this::isCompleted);
        return ResponseEntity.status(allCompleted ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE).body(dtos);
    }

    /**
     * Gyűjtés státusz lekérdezése.
     * GET /api/v1/data-collection/status
     * Ha branchId és date paraméterek hiányoznak, az összes iroda mai állapotát adja vissza összefoglalóként.
     */
    @GetMapping("/status")
    public ResponseEntity<?> getStatus(
            @RequestParam(required = false) @Nullable UUID branchId,
            @RequestParam(required = false) @Nullable LocalDate date) {
        if (branchId != null && date != null) {
            DataCollection dc = dataCollectionService.getCollectionStatus(branchId, date);
            return ResponseEntity.ok(toDto(dc));
        }
        // Summary: összes iroda utolsó gyűjtési állapota
        LocalDate resolvedDate = date != null ? date : LocalDate.now();
        List<DataCollectionDto> summary = dataCollectionService.getSummary(resolvedDate);
        return ResponseEntity.ok(summary);
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

    private ResponseEntity<DataCollectionDto> dataCollectionResponse(DataCollectionDto dto) {
        return ResponseEntity.status(isCompleted(dto) ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE).body(dto);
    }

    private boolean isCompleted(DataCollectionDto dto) {
        return dto != null && "COMPLETED".equalsIgnoreCase(dto.getStatus());
    }

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
