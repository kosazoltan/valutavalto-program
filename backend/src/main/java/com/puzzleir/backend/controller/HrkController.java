package com.puzzleir.backend.controller;

import com.puzzleir.backend.dto.CreateHrkTransactionDto;
import com.puzzleir.backend.dto.HrkTransactionDto;
import com.puzzleir.backend.service.HrkService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/hrk")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class HrkController {

    private final HrkService hrkService;

    // TODO: companyId és workerId a JWT-ből — egyelőre header-ből
    private static final UUID TEMP_COMPANY_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");
    private static final Long TEMP_WORKER_ID = 1L;

    /**
     * POST /api/v1/hrk/handover — Pénztár → Bank átadás
     */
    @PostMapping("/handover")
    public ResponseEntity<HrkTransactionDto> handover(
            @RequestHeader(value = "X-Branch-Id") UUID branchId,
            @Valid @RequestBody CreateHrkTransactionDto dto) {
        log.info("POST /api/v1/hrk/handover - branch: {}", branchId);
        HrkTransactionDto result = hrkService.handover(TEMP_COMPANY_ID, branchId, TEMP_WORKER_ID, dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    /**
     * POST /api/v1/hrk/receive — Bank → Pénztár átvétel
     */
    @PostMapping("/receive")
    public ResponseEntity<HrkTransactionDto> receive(
            @RequestHeader(value = "X-Branch-Id") UUID branchId,
            @Valid @RequestBody CreateHrkTransactionDto dto) {
        log.info("POST /api/v1/hrk/receive - branch: {}", branchId);
        HrkTransactionDto result = hrkService.receive(TEMP_COMPANY_ID, branchId, TEMP_WORKER_ID, dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    /**
     * GET /api/v1/hrk/journal — HRK napló
     */
    @GetMapping("/journal")
    public ResponseEntity<List<HrkTransactionDto>> getJournal(
            @RequestHeader(value = "X-Branch-Id") UUID branchId) {
        log.info("GET /api/v1/hrk/journal - branch: {}", branchId);
        List<HrkTransactionDto> journal = hrkService.getJournal(branchId);
        return ResponseEntity.ok(journal);
    }

    /**
     * POST /api/v1/hrk/close-daily — Napi HRK zárás összesítő
     */
    @PostMapping("/close-daily")
    public ResponseEntity<List<HrkTransactionDto>> closeDaily(
            @RequestHeader(value = "X-Branch-Id") UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        log.info("POST /api/v1/hrk/close-daily - branch: {}", branchId);
        LocalDate closingDate = date != null ? date : LocalDate.now();
        List<HrkTransactionDto> transactions = hrkService.getDailyTransactions(branchId, closingDate);
        return ResponseEntity.ok(transactions);
    }

    /**
     * DELETE /api/v1/hrk/{id} — HRK tranzakció törlése
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancel(@PathVariable UUID id) {
        log.info("DELETE /api/v1/hrk/{}", id);
        hrkService.cancel(id);
        return ResponseEntity.noContent().build();
    }
}
