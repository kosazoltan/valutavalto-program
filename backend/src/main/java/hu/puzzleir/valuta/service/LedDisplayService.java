package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.led.*;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.ExchangeRate;
import hu.puzzleir.valuta.entity.LedDisplay;
import hu.puzzleir.valuta.entity.LedDisplayConfig;
import hu.puzzleir.valuta.entity.LedDisplayConnectionType;
import hu.puzzleir.valuta.entity.LedDisplayType;
import hu.puzzleir.valuta.entity.LedSerialDisplayType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ExchangeRateRepository;
import hu.puzzleir.valuta.repository.LedDisplayConfigRepository;
import hu.puzzleir.valuta.repository.LedDisplayRepository;
import hu.puzzleir.valuta.service.led.LedProtocolEncoder;
import hu.puzzleir.valuta.service.led.LedSerialPortDriver;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * LED kijelző service.
 *
 * Árfolyam tábla + futó szöveg + konfiguráció kezelés + soros port vezérlés.
 * V38 alapfunkciók + V98 bővítés: RS-232 soros port protokoll (jSerialComm).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class LedDisplayService {

    private final LedDisplayRepository ledDisplayRepository;
    private final LedDisplayConfigRepository ledDisplayConfigRepository;
    private final BranchRepository branchRepository;
    private final ExchangeRateRepository exchangeRateRepository;
    private final LedProtocolEncoder encoder;
    private final LedSerialPortDriver serialDriver;

    /** Valós idejű státusz cache (branch-enkénti) */
    private final ConcurrentHashMap<UUID, LedDisplayStatusDto> statusMap = new ConcurrentHashMap<>();

    // ============ DISPLAY CONTROL (V38) ============

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
     * LED kijelző státusz lekérdezése (logikai, nem fizikai).
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
     * LED kijelző konfiguráció mentése / frissítése (legacy V38 signature).
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

    // ============ SERIAL COM PORT VEZÉRLÉS (V98) ============

    /**
     * LED kijelző frissítése egy irodán (soros port protokoll).
     * Betölti a konfigurációt, lekéri az árfolyamokat, kódolja és elküldi COM-on.
     */
    @Transactional(readOnly = true)
    public void refreshDisplay(UUID branchId) {
        LedDisplayConfig config = ledDisplayConfigRepository.findByBranchId(branchId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "LED konfiguráció nem található: branchId=" + branchId));

        if (!Boolean.TRUE.equals(config.getIsActive())) {
            log.debug("LED konfiguráció inaktív, kihagyva: branchId={}", branchId);
            return;
        }

        try {
            Map<String, BigDecimal[]> rates = getRatesForBranch(branchId, config.getCurrencyArray());
            byte[][] packets = encoder.encodeMultiDisplay(config, rates);
            String[] ports = config.getComPortArray();

            boolean allOk = true;
            for (int i = 0; i < ports.length && i < packets.length; i++) {
                boolean ok = serialDriver.send(ports[i], packets[i]);
                if (!ok) {
                    allOk = false;
                    log.warn("LED küldés sikertelen: branchId={}, port={}", branchId, ports[i]);
                }
            }

            LedDisplayStatusDto status = LedDisplayStatusDto.builder()
                    .branchId(branchId)
                    .branchName(config.getBranch() != null ? config.getBranch().getName() : branchId.toString())
                    .connected(allOk)
                    .lastRefresh(LocalDateTime.now())
                    .lastError(allOk ? null : "Küldési hiba egy vagy több porton")
                    .build();
            statusMap.put(branchId, status);

            log.info("LED frissítve: branchId={}, portok={}, OK={}", branchId, ports.length, allOk);

        } catch (Exception e) {
            log.error("LED frissítési hiba: branchId={}", branchId, e);
            LedDisplayStatusDto errStatus = LedDisplayStatusDto.builder()
                    .branchId(branchId)
                    .branchName(branchId.toString())
                    .connected(false)
                    .lastRefresh(LocalDateTime.now())
                    .lastError(e.getMessage())
                    .build();
            statusMap.put(branchId, errStatus);
        }
    }

    /**
     * Összes aktív LED kijelző frissítése — 60 másodpercenként fut.
     */
    @Scheduled(fixedRate = 60_000)
    public void refreshAllActive() {
        List<LedDisplayConfig> activeConfigs = ledDisplayConfigRepository.findByIsActiveTrue();
        log.info("LED automatikus frissítés: {} aktív konfiguráció", activeConfigs.size());
        for (LedDisplayConfig config : activeConfigs) {
            if (config.getBranch() != null) {
                try {
                    refreshDisplay(config.getBranch().getId());
                } catch (Exception e) {
                    log.error("LED auto-frissítési hiba: branchId={}",
                            config.getBranch().getId(), e);
                }
            }
        }
    }

    /**
     * Konfiguráció lekérdezése (V98 API).
     */
    @Transactional(readOnly = true)
    public LedDisplayConfigDto getConfig(UUID branchId) {
        return getDisplayConfig(branchId);
    }

    /**
     * Konfiguráció frissítése (V98 API — DTO alapú).
     */
    @Transactional
    public LedDisplayConfigDto updateConfig(UUID branchId, LedDisplayConfigDto dto) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        LedDisplayConfig config = ledDisplayConfigRepository.findByBranchId(branchId)
                .orElse(LedDisplayConfig.builder().branch(branch).build());

        // V38 mezők
        if (dto.getDisplayType() != null) {
            config.setDisplayType(LedDisplayConnectionType.valueOf(dto.getDisplayType()));
        }
        if (dto.getConnectionString() != null) {
            config.setConnectionString(dto.getConnectionString());
        }
        if (dto.getIsActive() != null) {
            config.setIsActive(dto.getIsActive());
        }
        if (dto.getRefreshIntervalSeconds() != null) {
            config.setRefreshIntervalSeconds(dto.getRefreshIntervalSeconds());
        }
        if (dto.getDisplayedCurrencies() != null) {
            config.setDisplayedCurrencies(dto.getDisplayedCurrencies());
        }

        // V98 soros port mezők
        if (dto.getSerialDisplayType() != null) {
            config.setSerialDisplayType(LedSerialDisplayType.valueOf(dto.getSerialDisplayType()));
        }
        if (dto.getComPorts() != null) {
            config.setComPorts(dto.getComPorts());
        }
        if (dto.getCurrencies() != null) {
            config.setCurrencies(dto.getCurrencies());
        }
        config.setShowBankCard(dto.isShowBankCard());
        config.setSpeedCommand(dto.isSpeedCommand());
        config.setSpeed(dto.getSpeed());
        if (dto.getEndMarkers() != null) {
            config.setEndMarkers(dto.getEndMarkers());
        }
        if (dto.getDecimalSeparator() != '\0') {
            config.setDecimalSeparator(dto.getDecimalSeparator());
        }
        if (dto.getCustomText() != null) {
            config.setCustomText(dto.getCustomText());
        }
        if (dto.getDisplayIds() != null) {
            config.setDisplayIds(dto.getDisplayIds());
        }
        config.setLastUpdatedAt(LocalDateTime.now());

        config = ledDisplayConfigRepository.save(config);
        log.info("LED konfiguráció frissítve: branchId={}", branchId);
        return toConfigDto(config);
    }

    /**
     * Egyéni szöveg küldése soros porton.
     */
    @Transactional(readOnly = true)
    public void sendCustomText(UUID branchId, String text) {
        LedDisplayConfig config = ledDisplayConfigRepository.findByBranchId(branchId)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "LED konfiguráció nem található: branchId=" + branchId));

        byte[] packet = encoder.encodeText(config, text);
        for (String port : config.getComPortArray()) {
            boolean ok = serialDriver.send(port, packet);
            log.info("LED egyéni szöveg küldés: branchId={}, port={}, OK={}", branchId, port, ok);
        }
    }

    /**
     * Egy iroda fizikai LED státuszának lekérdezése.
     */
    public LedDisplayStatusDto getSerialStatus(UUID branchId) {
        return statusMap.getOrDefault(branchId,
                LedDisplayStatusDto.builder()
                        .branchId(branchId)
                        .branchName(branchId.toString())
                        .connected(false)
                        .lastError("Nincs státusz adat — még nem volt frissítés")
                        .build());
    }

    /**
     * Összes iroda fizikai LED státuszának lekérdezése.
     */
    public List<LedDisplayStatusDto> getAllStatuses() {
        return new ArrayList<>(statusMap.values());
    }

    // ============ HELPERS ============

    /**
     * Árfolyamok összegyűjtése egy branchhoz, valutakód → [vétel, eladás] formátumban.
     * ExchangeRateRepository.findAllActiveRates() alapján — companyId-t a branch-ből vonjuk le.
     */
    private Map<String, BigDecimal[]> getRatesForBranch(UUID branchId, String[] currencies) {
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));

        UUID companyId = branch.getCompany() != null ? branch.getCompany().getId() : null;
        if (companyId == null) {
            log.warn("Branch company hiányzik: branchId={}", branchId);
            return Map.of();
        }

        List<ExchangeRate> allRates = exchangeRateRepository.findAllActiveRates(companyId, branchId);

        // Valutánként a legfrissebb árfolyam (findAllActiveRates már rendezve van)
        Map<String, BigDecimal[]> result = new LinkedHashMap<>();
        for (ExchangeRate rate : allRates) {
            String code = rate.getCurrency().getCode();
            result.putIfAbsent(code, new BigDecimal[]{
                rate.getBaseBuyRate(),
                rate.getBaseSellRate()
            });
        }

        // Ha kért valuták listája van, szűrjük arra
        if (currencies != null && currencies.length > 0) {
            Map<String, BigDecimal[]> filtered = new LinkedHashMap<>();
            for (String cur : currencies) {
                if (result.containsKey(cur)) {
                    filtered.put(cur, result.get(cur));
                }
            }
            return filtered;
        }
        return result;
    }

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
                .branchId(c.getBranch() != null ? c.getBranch().getId() : null)
                .displayType(c.getDisplayType() != null ? c.getDisplayType().name() : null)
                .connectionString(c.getConnectionString())
                .isActive(c.getIsActive())
                .refreshIntervalSeconds(c.getRefreshIntervalSeconds())
                .displayedCurrencies(c.getDisplayedCurrencies())
                .lastUpdatedAt(c.getLastUpdatedAt())
                // V98 soros port mezők
                .serialDisplayType(c.getSerialDisplayType() != null ? c.getSerialDisplayType().name() : null)
                .comPorts(c.getComPorts())
                .currencies(c.getCurrencies())
                .showBankCard(c.isShowBankCard())
                .speedCommand(c.isSpeedCommand())
                .speed(c.getSpeed())
                .endMarkers(c.getEndMarkers())
                .decimalSeparator(c.getDecimalSeparator())
                .customText(c.getCustomText())
                .displayIds(c.getDisplayIds())
                .updatedAt(c.getUpdatedAt())
                .build();
    }
}
