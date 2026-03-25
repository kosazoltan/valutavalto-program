package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.nav.NavSendResult;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterEventDto;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterReceiptRequest;
import hu.puzzleir.valuta.dto.cashregister.CashRegisterStornoRequest;
import hu.puzzleir.valuta.entity.CashRegisterEvent;
import hu.puzzleir.valuta.entity.CashRegisterEventType;
import hu.puzzleir.valuta.repository.CashRegisterEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Pénztárgép szolgáltatás.
 * NAV online pénztárgép integráció — egyelőre mock/log implementáció.
 * A tényleges hardware kommunikáció abstract.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CashRegisterService {

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
        String comPort = resolveNavComPort();
        boolean qrSent = navIntegrationService.sendQrCode("CASH_REGISTER_OPEN|branchId=" + branchId, comPort);

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.OPEN)
                .eventTimestamp(LocalDateTime.now())
            .rawResponse(buildResponse(qrSent ? "OK" : "ERROR",
                qrSent ? "Pénztárgép napi nyitás sikeres" : "Pénztárgép napi nyitás sikertelen",
                "comPort", comPort,
                "bridge", "NAV"))
                .build();

        event = cashRegisterEventRepository.save(event);
        log.info("Pénztárgép napi nyitás: branch={}", branch.getCode());
        return toDto(event);
    }

    /**
     * Napi zárás — Z jelentés, CLOSE esemény.
     */
    @Transactional(rollbackFor = Exception.class)
    public CashRegisterEventDto closeDay(UUID branchId) {
        Branch branch = findBranch(branchId);
        String comPort = resolveNavComPort();
        boolean qrSent = navIntegrationService.sendQrCode("CASH_REGISTER_CLOSE|branchId=" + branchId, comPort);

        CashRegisterEvent event = CashRegisterEvent.builder()
                .branch(branch)
                .eventType(CashRegisterEventType.CLOSE)
                .eventTimestamp(LocalDateTime.now())
            .rawResponse(buildResponse(qrSent ? "OK" : "ERROR",
                qrSent ? "Z jelentés nyomtatva, pénztárgép napi zárás sikeres" : "Z jelentés küldés sikertelen",
                "comPort", comPort,
                "bridge", "NAV"))
                .build();

        event = cashRegisterEventRepository.save(event);
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
        String navReceipt = (navResult != null && navResult.getReceiptNumber() != null && !navResult.getReceiptNumber().isBlank())
            ? navResult.getReceiptNumber()
            : request.getReceiptNumber();

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

        // Eredeti bizonylat esemény keresése
        CashRegisterEvent originalEvent = cashRegisterEventRepository.findById(request.getOriginalReceiptId())
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Eredeti bizonylat esemény nem található: " + request.getOriginalReceiptId()));

        String comPort = resolveNavComPort();
        String originalReceipt = originalEvent.getReceiptNumber() != null ? originalEvent.getReceiptNumber() : "UNKNOWN";
        NavSendResult navResult = invokeNavSend(buildSyntheticTransactionId("STORNO-" + originalReceipt), comPort);
        boolean navSuccess = navResult != null && navResult.isSuccess();
        String navStornoReceipt = (navResult != null && navResult.getReceiptNumber() != null && !navResult.getReceiptNumber().isBlank())
            ? navResult.getReceiptNumber()
            : "S-" + originalReceipt;

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
        return branchRepository.findById(branchId)
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

    private String buildResponse(String status, String message, String key1, String value1, String key2, String value2) {
        return String.format(
                "{\"status\":\"%s\",\"message\":\"%s\",\"%s\":\"%s\",\"%s\":\"%s\"}",
                escapeJson(status),
                escapeJson(message),
                escapeJson(key1),
                escapeJson(value1),
                escapeJson(key2),
                escapeJson(value2));
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
