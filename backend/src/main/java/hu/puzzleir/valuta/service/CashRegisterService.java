package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.nav.NavSendResult;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterCommandRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterCommandType;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterCurrencyCommandLine;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterEventDto;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterReceiptRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterStornoRequest;
import hu.puzzleir.valuta.entity.CashRegisterEvent;
import hu.puzzleir.valuta.entity.CashRegisterEventType;
import hu.puzzleir.valuta.repository.CashRegisterEventRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Pénztárgép szolgáltatás.
 * NAV online pénztárgép integráció.
 * A hardware bridge fail-closed: ha nincs éles driver vagy explicit szimuláció, ERROR event készül.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CashRegisterService {

    static final String NAV_AEE_NAMESPACE = "fiscat/AEE";
    static final String DAY_OPEN_COMMAND = NAV_AEE_NAMESPACE + "|OP";
    static final String DAY_CLOSE_COMMAND = NAV_AEE_NAMESPACE + "|DC|0|0";
    static final String CURRENCY_LIST_CLEAR_COMMAND = NAV_AEE_NAMESPACE + "|CCL";
    static final String CURRENCY_LIST_SET_COMMAND = NAV_AEE_NAMESPACE + "|CYS";

    private final CashRegisterEventRepository cashRegisterEventRepository;
    private final BranchRepository branchRepository;
    private final NavIntegrationService navIntegrationService;
    private final SystemParameterService systemParameterService;

    /**
     * Napi nyitás — OPEN esemény rögzítése.
     */
    @Transactional(rollbackFor = Exception.class)
    public CashRegisterEventDto openDay(UUID branchId) {
        Branch branch = findBranch(branchId);
        CashRegisterEvent event = sendExplicitQrCommand(
                branch,
                CashRegisterEventType.OPEN,
                DAY_OPEN_COMMAND,
                "Pénztárgép napi nyitás sikeres",
                "Pénztárgép napi nyitás sikertelen",
                "command", CashRegisterCommandType.DAY_OPEN.name());
        log.info("Pénztárgép napi nyitás: branch={}", branch.getCode());
        return toDto(event);
    }

    /**
     * Napi zárás — Z jelentés, CLOSE esemény.
     */
    @Transactional(rollbackFor = Exception.class)
    public CashRegisterEventDto closeDay(UUID branchId) {
        Branch branch = findBranch(branchId);
        CashRegisterEvent event = sendExplicitQrCommand(
                branch,
                CashRegisterEventType.CLOSE,
                DAY_CLOSE_COMMAND,
                "Z jelentés nyomtatva, pénztárgép napi zárás sikeres",
                "Z jelentés küldés sikertelen",
                "command", CashRegisterCommandType.DAY_CLOSE.name());
        log.info("Pénztárgép napi zárás (Z): branch={}", branch.getCode());
        return toDto(event);
    }

    /**
     * Bizonylat nyomtatása a pénztárgépen.
     */
    @Transactional(rollbackFor = Exception.class)
    public CashRegisterEventDto printReceipt(CashRegisterReceiptRequest request) {
        Branch branch = findBranch(request.getBranchId());
        String comPort = resolveNavComPort();
        NavSendResult navResult = invokeNavSend(buildSyntheticTransactionId(request.getReceiptNumber()), comPort);
        boolean navSuccess = navResult != null && navResult.isSuccess();
        String navReceipt = navSuccess
            ? firstNonBlank(navResult.getReceiptNumber(), request.getReceiptNumber())
            : null;

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.RECEIPT)
            .receiptNumber(navReceipt)
                .amount(request.getAmount())
                .currencyCode(request.getCurrencyCode())
                .amountHuf(request.getAmountHuf())
                .eventTimestamp(LocalDateTime.now())
            .rawResponse(buildResponse(navSuccess ? "OK" : "ERROR",
                navSuccess ? "Bizonylat sikeresen nyomtatva" : "Bizonylat NAV továbbítás sikertelen",
                "comPort", comPort,
                "requestedReceipt", request.getReceiptNumber()))
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép bizonylat: branch={}, receipt={}", branch.getCode(), request.getReceiptNumber());
        return toDto(event);
    }

    /**
     * Sztornó bizonylat nyomtatása.
     */
    @Transactional(rollbackFor = Exception.class)
    public CashRegisterEventDto printStorno(CashRegisterStornoRequest request) {
        Branch branch = findBranch(request.getBranchId());

        // Eredeti bizonylat esemény keresése + cross-branch védelem
        CashRegisterEvent originalEvent = cashRegisterEventRepository
                .findByIdAndBranchId(request.getOriginalReceiptId(), request.getBranchId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Eredeti bizonylat esemény nem található: " + request.getOriginalReceiptId()));

        String comPort = resolveNavComPort();
        String originalReceipt = originalEvent.getReceiptNumber() != null ? originalEvent.getReceiptNumber() : "UNKNOWN";
        NavSendResult navResult = invokeNavSend(buildSyntheticTransactionId("STORNO-" + originalReceipt), comPort);
        boolean navSuccess = navResult != null && navResult.isSuccess();
        String navStornoReceipt = navSuccess
            ? firstNonBlank(navResult.getReceiptNumber(), "S-" + originalReceipt)
            : null;

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.STORNO)
            .receiptNumber(navStornoReceipt)
                .amount(originalEvent.getAmount())
                .currencyCode(originalEvent.getCurrencyCode())
                .amountHuf(originalEvent.getAmountHuf())
                .eventTimestamp(LocalDateTime.now())
            .rawResponse(buildResponse(navSuccess ? "OK" : "ERROR",
                navSuccess ? "Sztornó bizonylat nyomtatva" : "Sztornó NAV továbbítás sikertelen",
                "comPort", comPort,
                "originalReceipt", originalReceipt))
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép sztornó: branch={}, original={}", branch.getCode(), request.getOriginalReceiptId());
        return toDto(event);
    }

    /**
     * X jelentés (köztes) lekérdezése.
     */
    @Transactional(rollbackFor = Exception.class)
    public CashRegisterEventDto getXReport(UUID branchId) {
        Branch branch = findBranch(branchId);
        String comPort = resolveNavComPort();
        boolean qrSent = navIntegrationService.sendQrCode("CASH_REGISTER_X_REPORT|branchId=" + branchId, comPort);

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.X_REPORT)
                .eventTimestamp(LocalDateTime.now())
            .rawResponse(buildResponse(qrSent ? "OK" : "ERROR",
                qrSent ? "X jelentés lekérdezve" : "X jelentés lekérdezés sikertelen",
                "comPort", comPort,
                "bridge", "NAV"))
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép X jelentés: branch={}", branch.getCode());
        return toDto(event);
    }

    /**
     * FR-EFM-02: explicit NAV pénztárgép parancsok auditált küldése.
     */
    @Transactional(rollbackFor = Exception.class)
    public CashRegisterEventDto executeCommand(CashRegisterCommandRequest request) {
        if (request == null || request.getCommandType() == null) {
            throw new IllegalArgumentException("Hiányzó pénztárgép parancs");
        }

        Branch branch = findBranch(request.getBranchId());
        String payload = buildExplicitCommandPayload(request);
        CashRegisterEvent event = sendExplicitQrCommand(
                branch,
                eventTypeFor(request.getCommandType()),
                payload,
                successMessageFor(request.getCommandType()),
                errorMessageFor(request.getCommandType()),
                "command", request.getCommandType().name());

        log.info("Explicit pénztárgép parancs: branch={}, command={}", branch.getCode(), request.getCommandType());
        return toDto(event);
    }

    /**
     * Z jelentés (napi zárás jelentés) generálása.
     * Összesíti az adott nap összes bizonylat eseményét.
     */
    @Transactional(rollbackFor = Exception.class)
    public CashRegisterEventDto generateZReport(UUID branchId, LocalDate date) {
        Branch branch = findBranch(branchId);
        LocalDate effectiveDate = date != null ? date : LocalDate.now();

        // Idempotencia: ha mar van Z_REPORT erre a napra, visszaadjuk
        LocalDateTime from = effectiveDate.atStartOfDay();
        LocalDateTime to = effectiveDate.atTime(LocalTime.MAX);
        List<CashRegisterEvent> dailyEvents = cashRegisterEventRepository
                .findByBranchIdAndEventTimestampBetweenOrderByEventTimestampDesc(branchId, from, to);

        // Check for existing Z_REPORT on this day
        var existingZReport = dailyEvents.stream()
                .filter(e -> e.getEventType() == CashRegisterEventType.Z_REPORT)
                .findFirst();
        if (existingZReport.isPresent()) {
            log.info("Z jelentés már létezik: branch={}, date={}", branch.getCode(), effectiveDate);
            return toDto(existingZReport.get());
        }

        long receiptCount = dailyEvents.stream()
                .filter(e -> e.getEventType() == CashRegisterEventType.RECEIPT)
                .count();
        long stornoCount = dailyEvents.stream()
                .filter(e -> e.getEventType() == CashRegisterEventType.STORNO)
                .count();

        String comPort = resolveNavComPort();
        boolean qrSent = navIntegrationService.sendQrCode(
                "CASH_REGISTER_Z_REPORT|branchId=" + branchId + "|date=" + effectiveDate, comPort);

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.Z_REPORT)
                .eventTimestamp(LocalDateTime.now())
                .rawResponse(buildResponse(qrSent ? "OK" : "ERROR",
                        String.format("Z jelentés: %d bizonylat, %d sztornó", receiptCount, stornoCount),
                        "comPort", comPort,
                        "date", effectiveDate.toString()))
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép Z jelentés: branch={}, date={}, receipts={}, stornos={}",
                branch.getCode(), effectiveDate, receiptCount, stornoCount);
        return toDto(event);
    }

    /**
     * Bizonylat sorszám folytonosság ellenőrzése.
     * Hézagmentes, folyamatos sorszámozást validál az adott irodában.
     */
    @Transactional(readOnly = true)
    public List<String> validateReceiptSequenceContinuity(UUID branchId, LocalDate date) {
        Branch branch = findBranch(branchId);
        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.atTime(LocalTime.MAX);

        List<CashRegisterEvent> receipts = cashRegisterEventRepository
                .findByBranchIdAndEventTimestampBetweenOrderByEventTimestampDesc(branchId, from, to)
                .stream()
                .filter(e -> e.getEventType() == CashRegisterEventType.RECEIPT)
                .sorted((a, b) -> a.getEventTimestamp().compareTo(b.getEventTimestamp()))
                .toList();

        List<String> gaps = new java.util.ArrayList<>();
        for (int i = 1; i < receipts.size(); i++) {
            String prev = receipts.get(i - 1).getReceiptNumber();
            String curr = receipts.get(i).getReceiptNumber();
            if (prev != null && curr != null) {
                try {
                    long prevNum = extractSequenceNumber(prev);
                    long currNum = extractSequenceNumber(curr);
                    if (currNum != prevNum + 1) {
                        gaps.add(String.format("Hézag: %s (%d) → %s (%d)", prev, prevNum, curr, currNum));
                    }
                } catch (NumberFormatException ignored) {
                    // Nem numerikus sorszám — skip
                }
            }
        }
        return gaps;
    }

    private long extractSequenceNumber(String receiptNumber) {
        // Bizonylat szám formátum: PREFIX-NNNN vagy NNNN
        String numPart = receiptNumber.replaceAll("[^0-9]", "");
        return Long.parseLong(numPart);
    }

    /**
     * Napi események lekérdezése.
     */
    @Transactional(readOnly = true)
    public List<CashRegisterEventDto> getDailyEvents(UUID branchId, LocalDate date) {
        LocalDateTime from = date.atStartOfDay();
        LocalDateTime to = date.atTime(LocalTime.MAX);

        return cashRegisterEventRepository
                .findByBranchIdAndEventTimestampBetweenOrderByEventTimestampDesc(branchId, from, to)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    // ============ HELPERS ============

    private Branch findBranch(UUID branchId) {
        UUID companyId = SecurityUtils.getCurrentCompanyIdOrNull();
        Optional<Branch> branch = companyId != null
                ? branchRepository.findByIdAndCompanyId(branchId, companyId)
                : branchRepository.findById(branchId);
        return branch
                .orElseThrow(() -> new ResourceNotFoundException("Iroda nem található: " + branchId));
    }

    private CashRegisterEventDto toDto(CashRegisterEvent e) {
        return CashRegisterEventDto.builder()
                .id(e.getId())
                .branchId(e.getBranch().getId())
                .eventType(e.getEventType().name())
                .receiptNumber(e.getReceiptNumber())
                .amount(e.getAmount())
                .currencyCode(e.getCurrencyCode())
                .amountHuf(e.getAmountHuf())
                .taxNumber(e.getTaxNumber())
                .cashRegisterId(e.getCashRegisterId())
                .eventTimestamp(e.getEventTimestamp())
                .rawResponse(e.getRawResponse())
                .build();
    }

    private CashRegisterEvent sendExplicitQrCommand(
            Branch branch,
            CashRegisterEventType eventType,
            String payload,
            String successMessage,
            String errorMessage,
            String... extraPairs) {
        String comPort = resolveNavComPort();
        boolean qrSent = navIntegrationService.sendQrCode(payload, comPort);
        String[] responsePairs = appendPairs(extraPairs,
                "comPort", comPort,
                "bridge", "NAV",
                "payload", payload);
        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(eventType)
                .eventTimestamp(LocalDateTime.now())
                .rawResponse(buildResponse(qrSent ? "OK" : "ERROR",
                        qrSent ? successMessage : errorMessage,
                        responsePairs))
                .build();
        return cashRegisterEventRepository.save(event);
    }

    private String buildExplicitCommandPayload(CashRegisterCommandRequest request) {
        return switch (request.getCommandType()) {
            case DAY_OPEN -> DAY_OPEN_COMMAND;
            case DAY_CLOSE -> DAY_CLOSE_COMMAND;
            case CURRENCY_LIST_CLEAR -> CURRENCY_LIST_CLEAR_COMMAND;
            case CURRENCY_LIST_SET -> buildCurrencyListSetPayload(request.getCurrencies());
        };
    }

    private String buildCurrencyListSetPayload(List<CashRegisterCurrencyCommandLine> currencies) {
        if (currencies == null || currencies.isEmpty()) {
            throw new IllegalArgumentException("CURRENCY_LIST_SET parancshoz legalább egy valuta szükséges");
        }

        StringBuilder payload = new StringBuilder(CURRENCY_LIST_SET_COMMAND);
        int generatedKeyIndex = 1;
        for (CashRegisterCurrencyCommandLine line : currencies) {
            if (line == null || line.getCurrencyCode() == null || line.getCurrencyCode().isBlank()) {
                throw new IllegalArgumentException("CURRENCY_LIST_SET valuta currencyCode mező kötelező");
            }
            String currencyCode = line.getCurrencyCode().trim().toUpperCase(Locale.ROOT);
            String key = resolveCashRegisterCurrencyKey(line, currencyCode, generatedKeyIndex);
            if (!isFixedCashRegisterCurrency(currencyCode) && (line.getCashRegisterKey() == null || line.getCashRegisterKey().isBlank())) {
                generatedKeyIndex++;
            }
            String displayName = sanitizeNavField(firstNonBlank(line.getDisplayName(), currencyCode), 40);
            String rate = formatNavRate(line.getRate());
            payload.append('|').append(key)
                    .append('|').append(displayName)
                    .append('|').append(rate)
                    .append('|').append(rate);
        }
        return payload.toString();
    }

    private String resolveCashRegisterCurrencyKey(
            CashRegisterCurrencyCommandLine line,
            String currencyCode,
            int generatedKeyIndex) {
        if (line.getCashRegisterKey() != null && !line.getCashRegisterKey().isBlank()) {
            return line.getCashRegisterKey().trim().toUpperCase(Locale.ROOT);
        }
        if ("HUF".equals(currencyCode)) {
            return "LOCA";
        }
        if ("EUR".equals(currencyCode)) {
            return "CY00";
        }
        return "CY" + String.format("%02d", generatedKeyIndex);
    }

    private boolean isFixedCashRegisterCurrency(String currencyCode) {
        return "HUF".equals(currencyCode) || "EUR".equals(currencyCode);
    }

    private String formatNavRate(BigDecimal rate) {
        BigDecimal effective = rate != null ? rate : BigDecimal.ONE;
        return effective.setScale(4, RoundingMode.DOWN).toPlainString();
    }

    private String sanitizeNavField(String value, int maxLength) {
        String cleaned = firstNonBlank(value, "")
                .replace('|', '/')
                .replaceAll("\\p{Cntrl}", "")
                .trim();
        return cleaned.length() <= maxLength ? cleaned : cleaned.substring(0, maxLength);
    }

    private CashRegisterEventType eventTypeFor(CashRegisterCommandType commandType) {
        return switch (commandType) {
            case DAY_OPEN -> CashRegisterEventType.OPEN;
            case DAY_CLOSE -> CashRegisterEventType.CLOSE;
            case CURRENCY_LIST_CLEAR -> CashRegisterEventType.CURRENCY_LIST_CLEAR;
            case CURRENCY_LIST_SET -> CashRegisterEventType.CURRENCY_LIST_SET;
        };
    }

    private String successMessageFor(CashRegisterCommandType commandType) {
        return switch (commandType) {
            case DAY_OPEN -> "Pénztárgép napi nyitás sikeres";
            case DAY_CLOSE -> "Z jelentés nyomtatva, pénztárgép napi zárás sikeres";
            case CURRENCY_LIST_CLEAR -> "Pénztárgép valuta-lista törlés sikeres";
            case CURRENCY_LIST_SET -> "Pénztárgép valuta-lista betöltés sikeres";
        };
    }

    private String errorMessageFor(CashRegisterCommandType commandType) {
        return switch (commandType) {
            case DAY_OPEN -> "Pénztárgép napi nyitás sikertelen";
            case DAY_CLOSE -> "Z jelentés küldés sikertelen";
            case CURRENCY_LIST_CLEAR -> "Pénztárgép valuta-lista törlés sikertelen";
            case CURRENCY_LIST_SET -> "Pénztárgép valuta-lista betöltés sikertelen";
        };
    }

    private NavSendResult invokeNavSend(long syntheticTransactionId, String comPort) {
        try {
            return navIntegrationService.sendTransaction(syntheticTransactionId, comPort);
        } catch (Exception e) {
            log.error("Pénztárgép NAV bridge hiba: tx={}, comPort={}", syntheticTransactionId, comPort, e);
            return NavSendResult.builder().success(false).error(e.getMessage()).build();
        }
    }

    private long buildSyntheticTransactionId(String seed) {
        if (seed == null || seed.isBlank()) {
            return Math.abs(UUID.randomUUID().getLeastSignificantBits());
        }
        return Integer.toUnsignedLong(seed.hashCode());
    }

    private String resolveNavComPort() {
        try {
            String configured = systemParameterService.getValue("nav.com-port");
            if (configured != null && !configured.isBlank()) {
                return configured.trim();
            }
        } catch (Exception ignored) {
            // Fallback used below.
        }
        return "COM1";
    }

    private String firstNonBlank(String preferred, String fallback) {
        return preferred != null && !preferred.isBlank() ? preferred : fallback;
    }

    private String buildResponse(String status, String message, String... pairs) {
        StringBuilder json = new StringBuilder();
        json.append("{\"status\":\"").append(escapeJson(status))
                .append("\",\"message\":\"").append(escapeJson(message)).append('"');
        for (int i = 0; pairs != null && i + 1 < pairs.length; i += 2) {
            json.append(",\"").append(escapeJson(pairs[i]))
                    .append("\":\"").append(escapeJson(pairs[i + 1])).append('"');
        }
        json.append('}');
        return json.toString();
    }

    private String[] appendPairs(String[] first, String... second) {
        String[] safeFirst = first != null ? first : new String[0];
        String[] result = new String[safeFirst.length + second.length];
        System.arraycopy(safeFirst, 0, result, 0, safeFirst.length);
        System.arraycopy(second, 0, result, safeFirst.length, second.length);
        return result;
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
