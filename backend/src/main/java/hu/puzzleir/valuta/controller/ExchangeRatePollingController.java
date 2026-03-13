package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.polling.ApplyMarginsDto;
import hu.puzzleir.valuta.dto.polling.ExchangeRateSourceDto;
import hu.puzzleir.valuta.dto.polling.PollingStatusDto;
import hu.puzzleir.valuta.dto.polling.UpdateExchangeRateSourceDto;
import hu.puzzleir.valuta.entity.ExchangeRateSource;
import hu.puzzleir.valuta.repository.ExchangeRateSourceRepository;
import hu.puzzleir.valuta.service.ExchangeRatePollingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Árfolyam polling controller — /api/v1/rates/polling
 *
 * Manuális polling trigger, állapot lekérdezés, ECB árfolyamok,
 * margin alkalmazás, és árfolyam források kezelése.
 */
@RestController
@RequestMapping("/api/v1/rates/polling")
@RequiredArgsConstructor
@Slf4j
public class ExchangeRatePollingController {

    private final ExchangeRatePollingService pollingService;
    private final ExchangeRateSourceRepository sourceRepository;

    /**
     * Manuális polling trigger.
     *
     * POST /api/v1/rates/polling/trigger
     *
     * Csak SUPERVISOR, MANAGER, ADMIN
     */
    @PostMapping("/trigger")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, String>> triggerPoll() {
        log.info("Manuális MNB polling trigger kérés");
        pollingService.triggerManualPoll();
        return ResponseEntity.ok(Map.of("message", "MNB árfolyam polling elindítva"));
    }

    /**
     * Utolsó polling állapota (mikor volt, hiba volt-e).
     *
     * GET /api/v1/rates/polling/status
     */
    @GetMapping("/status") // Publikus monitoring endpoint — szándékosan nem auth-védett
    public ResponseEntity<PollingStatusDto> getPollingStatus() {
        Map<String, Object> status = pollingService.getPollingStatus();
        PollingStatusDto dto = PollingStatusDto.builder()
            .lastPollTime(status.get("lastPollTime") != null
                ? (LocalDateTime) status.get("lastPollTime") : null)
            .lastPollSuccess(status.get("lastPollSuccess") != null
                && (boolean) status.get("lastPollSuccess"))
            .lastPollError(status.get("lastPollError") != null
                ? (String) status.get("lastPollError") : null)
            .lastPollUpdatedCount(status.get("lastPollUpdatedCount") != null
                ? (int) status.get("lastPollUpdatedCount") : 0)
            .lastPollSource(status.get("lastPollSource") != null
                ? (String) status.get("lastPollSource") : "NONE")
            .build();
        return ResponseEntity.ok(dto);
    }

    /**
     * ECB árfolyamok lekérdezése.
     *
     * GET /api/v1/rates/polling/ecb
     */
    @GetMapping("/ecb")
    public ResponseEntity<Map<String, BigDecimal>> getEcbRates() {
        Map<String, BigDecimal> rates = pollingService.fetchEcbRatesOnly();
        return ResponseEntity.ok(rates);
    }

    /**
     * Margin alkalmazás (params: currencyId, spread).
     *
     * POST /api/v1/rates/polling/apply-margins
     *
     * Csak SUPERVISOR, MANAGER, ADMIN
     */
    @PostMapping("/apply-margins")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Map<String, String>> applyMargins(@Valid @RequestBody ApplyMarginsDto dto) {
        log.info("Margin alkalmazás kérés: currencyId={}, spread={}", dto.getCurrencyId(), dto.getSpread());
        pollingService.applyMargins(dto.getCurrencyId(), dto.getSpread());
        return ResponseEntity.ok(Map.of("message", "Margin sikeresen alkalmazva"));
    }

    /**
     * Árfolyam források listája.
     *
     * GET /api/v1/rates/polling/sources
     */
    @GetMapping("/sources")
    public ResponseEntity<List<ExchangeRateSourceDto>> getSources() {
        List<ExchangeRateSourceDto> sources = sourceRepository.findAll().stream()
            .map(this::toDto)
            .collect(Collectors.toList());
        return ResponseEntity.ok(sources);
    }

    /**
     * Forrás frissítés (interval, active).
     *
     * PUT /api/v1/rates/polling/sources/{id}
     *
     * Csak SUPERVISOR, MANAGER, ADMIN
     */
    @PutMapping("/sources/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ExchangeRateSourceDto> updateSource(
            @PathVariable Long id,
            @Valid @RequestBody UpdateExchangeRateSourceDto dto) {

        ExchangeRateSource source = sourceRepository.findById(id)
            .orElseThrow(() -> new ResourceNotFoundException(
                "Árfolyam forrás nem található: " + id));

        if (dto.getPollIntervalMinutes() != null) {
            source.setPollingIntervalMinutes(dto.getPollIntervalMinutes());
        }
        if (dto.getActive() != null) {
            source.setActive(dto.getActive());
        }

        ExchangeRateSource saved = sourceRepository.save(source);
        log.info("Árfolyam forrás frissítve: id={}, name={}", saved.getId(), saved.getSourceName());

        return ResponseEntity.ok(toDto(saved));
    }

    // ============ MAPPER ============

    private ExchangeRateSourceDto toDto(ExchangeRateSource entity) {
        return ExchangeRateSourceDto.builder()
            .id(entity.getId())
            .name(entity.getSourceName())
            .url(entity.getSourceUrl())
            .pollIntervalMinutes(entity.getPollingIntervalMinutes())
            .active(entity.getActive())
            .lastSuccessAt(entity.getLastSuccessAt())
            .lastErrorAt(entity.getLastErrorAt())
            .lastError(entity.getLastError())
            .successCount(entity.getSuccessCount())
            .errorCount(entity.getErrorCount())
            .build();
    }
}
