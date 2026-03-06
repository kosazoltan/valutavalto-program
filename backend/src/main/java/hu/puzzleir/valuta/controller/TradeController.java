package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.trade.ProposeTradeDto;
import hu.puzzleir.valuta.dto.trade.RejectTradeDto;
import hu.puzzleir.valuta.dto.trade.TradeDto;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.TradeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Trade controller — devizakereskedés irodák között.
 */
@RestController
@RequestMapping("/api/v1/trades")
@RequiredArgsConstructor
public class TradeController {

    private final TradeService service;

    @PostMapping("/propose")
    public ResponseEntity<TradeDto> propose(@Valid @RequestBody ProposeTradeDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.proposeTrade(dto));
    }

    @PostMapping("/{id}/accept")
    public ResponseEntity<TradeDto> accept(@PathVariable UUID id) {
        Long workerId = SecurityUtils.getCurrentWorkerId();
        return ResponseEntity.ok(service.acceptTrade(id, workerId));
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<TradeDto> reject(@PathVariable UUID id, @RequestBody(required = false) RejectTradeDto dto) {
        String reason = dto != null ? dto.getReason() : null;
        return ResponseEntity.ok(service.rejectTrade(id, reason));
    }

    @PostMapping("/{id}/complete")
    public ResponseEntity<TradeDto> complete(@PathVariable UUID id) {
        return ResponseEntity.ok(service.completeTrade(id));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<TradeDto> cancel(@PathVariable UUID id) {
        return ResponseEntity.ok(service.cancelTrade(id));
    }

    @GetMapping("/pending")
    public ResponseEntity<List<TradeDto>> pending(@RequestParam(required = false) UUID branchId) {
        return ResponseEntity.ok(service.getPendingTrades(branchId));
    }

    @GetMapping("/history")
    public ResponseEntity<Page<TradeDto>> history(
            @RequestParam(required = false) UUID branchId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            Pageable pageable) {
        return ResponseEntity.ok(service.getTradeHistory(branchId, from, to, pageable));
    }
}
