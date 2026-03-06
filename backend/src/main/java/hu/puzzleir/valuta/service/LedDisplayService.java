package hu.puzzleir.valuta.service;

import com.puzzleir.backend.entity.Branch;
import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.repository.BranchRepository;
import hu.puzzleir.valuta.dto.led.*;
import hu.puzzleir.valuta.entity.LedDisplay;
import hu.puzzleir.valuta.entity.LedDisplayConfig;
import hu.puzzleir.valuta.entity.LedDisplayConnectionType;
import hu.puzzleir.valuta.entity.LedDisplayType;
import hu.puzzleir.valuta.repository.LedDisplayConfigRepository;
import hu.puzzleir.valuta.repository.LedDisplayRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * LED kijelző service.
 * Árfolyam tábla + futó szöveg + konfiguráció kezelés.
 * A fizikai LED vezérlés (RS-232 / USB / Network) későbbi fejlesztés.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LedDisplayService {

    private final LedDisplayRepository ledDisplayRepository;
    private final LedDisplayConfigRepository ledDisplayConfigRepository;
    private final BranchRepository branchRepository;

    /**
     * Árfolyam tábla frissítése LED kijelzőre.
     */
    @Transactional
    public LedDisplayDto updateRateBoard(UUID branchId) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        LedDisplay display = ledDisplayRepository.findByBranchIdAndDisplayType(
                        branchId, LedDisplayType.RATE_BOARD)
                .orElse(LedDisplay.builder()
                        .branch(branch)
                        .displayType(LedDisplayType.RATE_BOARD)
                        .build());

        // Placeholder — az árfolyamokat JSON formátumba generáljuk
        display.setContent("{\"type\":\"RATE_BOARD\",\"message\":\"Árfolyam tábla frissítve\",\"timestamp\":\""
                + LocalDateTime.now() + "\"}");
        display.setLastUpdated(LocalDateTime.now());

        display = ledDisplayRepository.save(display);
        log.info("LED árfolyam tábla frissítve: branch={}", branch.getCode());
        return toDto(display);
    }

    /**
     * Futó szöveg beállítása.
     */
    @Transactional
    public LedDisplayDto updateScrollingText(UUID branchId, String text) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        LedDisplay display = ledDisplayRepository.findByBranchIdAndDisplayType(
                        branchId, LedDisplayType.SCROLLING_TEXT)
                .orElse(LedDisplay.builder()
                        .branch(branch)
                        .displayType(LedDisplayType.SCROLLING_TEXT)
                        .build());

        display.setContent("{\"type\":\"SCROLLING_TEXT\",\"text\":\""
                + text.replace("\"", "\\\"") + "\",\"timestamp\":\""
                + LocalDateTime.now() + "\"}");
        display.setLastUpdated(LocalDateTime.now());

        display = ledDisplayRepository.save(display);
        log.info("LED futó szöveg frissítve: branch={}, text={}", branch.getCode(), text);
        return toDto(display);
    }

    /**
     * LED kijelző státusz lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<LedDisplayDto> getStatus(UUID branchId) {
        return ledDisplayRepository.findByBranchId(branchId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ CONFIG MANAGEMENT ============

    /**
     * LED kijelző konfiguráció lekérdezése egy irodához.
     */
    @Transactional(readOnly = true)
    public LedDisplayConfigDto getDisplayConfig(UUID branchId) {
        LedDisplayConfig config = ledDisplayConfigRepository.findByBranchId(branchId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "LED kijelző konfiguráció nem található: branchId=" + branchId));
        return toConfigDto(config);
    }

    /**
     * LED kijelző konfiguráció mentése / frissítése.
     */
    @Transactional
    public LedDisplayConfigDto saveDisplayConfig(SaveLedDisplayConfigRequest request) {
        Branch branch = branchRepository.findById(request.getBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + request.getBranchId()));

        LedDisplayConfig config = ledDisplayConfigRepository.findByBranchId(request.getBranchId())
                .orElse(LedDisplayConfig.builder().branch(branch).build());

        if (request.getDisplayType() != null) {
            config.setDisplayType(LedDisplayConnectionType.valueOf(request.getDisplayType()));
        }
        if (request.getConnectionString() != null) {
            config.setConnectionString(request.getConnectionString());
        }
        if (request.getIsActive() != null) {
            config.setIsActive(request.getIsActive());
        }
        if (request.getRefreshIntervalSeconds() != null) {
            config.setRefreshIntervalSeconds(request.getRefreshIntervalSeconds());
        }
        if (request.getDisplayedCurrencies() != null) {
            config.setDisplayedCurrencies(request.getDisplayedCurrencies());
        }
        config.setLastUpdatedAt(LocalDateTime.now());

        config = ledDisplayConfigRepository.save(config);
        log.info("LED kijelző konfiguráció mentve: branch={}", branch.getCode());
        return toConfigDto(config);
    }

    /**
     * LED kijelző aktuális tartalom (mock árfolyamok).
     */
    @Transactional(readOnly = true)
    public List<LedDisplayLineDto> getDisplayContent(UUID branchId) {
        // Placeholder: mock árfolyamok — production-ben az ExchangeRateService-ből jönnének
        List<LedDisplayLineDto> lines = new ArrayList<>();
        lines.add(LedDisplayLineDto.builder()
                .currencyCode("EUR").buyRate(new BigDecimal("395.50")).sellRate(new BigDecimal("399.50")).unit(1).build());
        lines.add(LedDisplayLineDto.builder()
                .currencyCode("USD").buyRate(new BigDecimal("365.00")).sellRate(new BigDecimal("369.00")).unit(1).build());
        lines.add(LedDisplayLineDto.builder()
                .currencyCode("GBP").buyRate(new BigDecimal("460.00")).sellRate(new BigDecimal("466.00")).unit(1).build());
        lines.add(LedDisplayLineDto.builder()
                .currencyCode("CHF").buyRate(new BigDecimal("415.00")).sellRate(new BigDecimal("420.00")).unit(1).build());
        log.debug("LED kijelző tartalom lekérdezve: branch={}", branchId);
        return lines;
    }

    // ============ HELPERS ============

    private LedDisplayDto toDto(LedDisplay d) {
        return LedDisplayDto.builder()
                .id(d.getId().toString())
                .branchId(d.getBranch().getId().toString())
                .displayType(d.getDisplayType().name())
                .content(d.getContent())
                .lastUpdated(d.getLastUpdated() != null ? d.getLastUpdated().toString() : null)
                .build();
    }

    private LedDisplayConfigDto toConfigDto(LedDisplayConfig c) {
        return LedDisplayConfigDto.builder()
                .id(c.getId())
                .branchId(c.getBranch().getId())
                .displayType(c.getDisplayType().name())
                .connectionString(c.getConnectionString())
                .isActive(c.getIsActive())
                .refreshIntervalSeconds(c.getRefreshIntervalSeconds())
                .displayedCurrencies(c.getDisplayedCurrencies())
                .lastUpdatedAt(c.getLastUpdatedAt())
                .build();
    }
}
