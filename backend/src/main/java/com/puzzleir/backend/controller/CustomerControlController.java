package com.puzzleir.backend.controller;

import com.puzzleir.backend.dto.CreateRestrictionDto;
import com.puzzleir.backend.dto.CustomerRestrictionDto;
import com.puzzleir.backend.dto.CustomerScreeningLogDto;
import com.puzzleir.backend.service.CustomerControlService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/customer-control")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class CustomerControlController {

    private final CustomerControlService customerControlService;

    // TODO: workerId a JWT-ből
    private static final Long TEMP_WORKER_ID = 1L;

    /**
     * GET /api/v1/customer-control/{id}/restrictions — Ügyfél korlátozásai
     */
    @GetMapping("/{id}/restrictions")
    public ResponseEntity<List<CustomerRestrictionDto>> getRestrictions(@PathVariable Long id) {
        log.info("GET /api/v1/customer-control/{}/restrictions", id);
        List<CustomerRestrictionDto> restrictions = customerControlService.getAllRestrictions(id);
        return ResponseEntity.ok(restrictions);
    }

    /**
     * POST /api/v1/customer-control/{id}/restrict — Új korlátozás
     */
    @PostMapping("/{id}/restrict")
    public ResponseEntity<CustomerRestrictionDto> addRestriction(
            @PathVariable Long id,
            @Valid @RequestBody CreateRestrictionDto dto) {
        log.info("POST /api/v1/customer-control/{}/restrict - típus: {}", id, dto.getRestrictionType());
        CustomerRestrictionDto result = customerControlService.addRestriction(id, TEMP_WORKER_ID, dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(result);
    }

    /**
     * DELETE /api/v1/customer-control/restrictions/{id} — Korlátozás eltávolítása
     */
    @DeleteMapping("/restrictions/{id}")
    public ResponseEntity<Void> removeRestriction(@PathVariable UUID id) {
        log.info("DELETE /api/v1/customer-control/restrictions/{}", id);
        customerControlService.removeRestriction(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * GET /api/v1/customer-control/{id}/annual-total — Éves tranzakció összeg
     */
    @GetMapping("/{id}/annual-total")
    public ResponseEntity<BigDecimal> getAnnualTotal(
            @PathVariable Long id,
            @RequestParam(required = false) Integer year) {
        log.info("GET /api/v1/customer-control/{}/annual-total", id);
        int targetYear = year != null ? year : java.time.LocalDate.now().getYear();
        BigDecimal total = customerControlService.getAnnualTransactionTotal(id, targetYear);
        return ResponseEntity.ok(total);
    }

    /**
     * GET /api/v1/customer-control/{id}/screening-log — Szűrési napló
     */
    @GetMapping("/{id}/screening-log")
    public ResponseEntity<List<CustomerScreeningLogDto>> getScreeningLog(@PathVariable Long id) {
        log.info("GET /api/v1/customer-control/{}/screening-log", id);
        List<CustomerScreeningLogDto> logs = customerControlService.getScreeningHistory(id);
        return ResponseEntity.ok(logs);
    }
}
