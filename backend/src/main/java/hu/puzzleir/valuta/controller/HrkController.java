package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.CreateHrkTransactionDto;
import hu.puzzleir.valuta.dto.HrkTransactionDto;
import hu.puzzleir.valuta.service.HrkService;
import hu.puzzleir.valuta.security.SecurityUtils;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/hrk")
@RequiredArgsConstructor
@Slf4j
@PreAuthorize("isAuthenticated()")
public class HrkController {

    private final HrkService hrkService;

    /**
     * POST /api/v1/hrk/handover — Pénztár → Bank átadás
     */
    @PostMapping("/handover")
    public ResponseEntity<HrkTransactionDto> handover(
            @RequestHeader(value = "X-Branch-Id") UUID branchId,
            @Valid @RequestBody CreateHrkTransactionDto dto) {
        log.info("POST /api/v1/hrk/handover - branch: {}", branchId);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        HrkTransactionDto result = hrkService.handover(companyId, branchId, workerId, dto);
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
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Long workerId = SecurityUtils.getCurrentWorkerId();
        HrkTransactionDto result = hrkService.receive(companyId, branchId, workerId, dto);
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
