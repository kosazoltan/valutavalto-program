package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.config.IntegrationTransportProperties;
import hu.puzzleir.valuta.dto.pos.*;
import hu.puzzleir.valuta.entity.PosTerminal;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.PosTerminalRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.*;

/**
 * POS terminál szolgáltatás — bankkártyás fizetési terminálok kezelése.
 *
 * Legacy: OtpTermStorno, OtpAruvisszavet, otpterminal DLL-ek.
 * Modern: többféle terminál provider támogatása (OTP, Borgun, Worldline) + MOCK mód.
 *
 * A szolgáltatás MOCK módban mindig APPROVED-ot ad vissza (dev/test),
 * éles módban a megfelelő terminál protokollon kommunikál.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class PosTerminalService {

    private final PosTerminalRepository repository;
    private final SystemParameterService systemParameterService;
    private final OtpTerminalProtocolService otpProtocol;
    private final IntegrationTransportProperties integrationTransportProperties;
    private final FileTransportService fileTransportService;

    /**
     * Terminál típusok.
     */
    public enum TerminalType {
        OTP, BORGUN, WORLDLINE, MOCK
    }

    // ============ TERMINÁL LEKÉRDEZÉSEK ============

    public List<PosTerminal> findAll() {
        return repository.findByIsActiveTrueOrderByTerminalNameAsc();
    }

    public List<PosTerminal> findByBranch(UUID branchId) {
        return repository.findByBranchIdAndIsActiveTrueOrderByTerminalNameAsc(branchId);
    }

    public PosTerminal findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("PosTerminal not found: " + id));
    }

    public Optional<PosTerminal> findByTerminalId(String terminalId) {
        return repository.findByTerminalId(terminalId);
    }

    // ============ FIZETÉS INDÍTÁSA ============

    /**
     * Bankkártyás fizetés indítása POS terminálon.
     *
     * Legacy: OTP terminál DLL hívás — összeg + devizanem → autorizáció/elutasítás.
     * Modern: terminál típus alapján delegál. MOCK módban mindig APPROVED.
     *
     * @param amount     Fizetendő összeg
     * @param currency   Devizanem kód (pl. "HUF")
     * @param terminalId Terminál azonosító
     * @return POS tranzakció eredmény
     */
    @Transactional
    public PosTransactionResult initiatePayment(BigDecimal amount, String currency, String terminalId) {
        log.info("POS fizetés indítása: {} {} terminál={}", amount, currency, terminalId);

        // 1. Terminál konfiguráció lekérés
        PosTerminal terminal = repository.findByTerminalId(terminalId)
                .orElseThrow(() -> new ResourceNotFoundException("POS terminál nem található: " + terminalId));

        if (!Boolean.TRUE.equals(terminal.getIsActive())) {
            return PosTransactionResult.error("POS terminál inaktív: " + terminalId);
        }

        // 2. Terminál mód meghatározása
        TerminalType mode = resolveTerminalType(terminal);

        // 3. Fizetés végrehajtása mód szerint
        PosTransactionResult result;
        try {
            result = switch (mode) {
                case MOCK -> executeMockPayment(amount, currency, terminalId);
                case OTP -> executeOtpPayment(amount, currency, terminalId);
                case BORGUN -> executeBorgunPayment(amount, currency, terminalId);
                case WORLDLINE -> executeWorldlinePayment(amount, currency, terminalId);
            };
        } catch (Exception e) {
            log.error("POS fizetés hiba: terminál={}, hiba={}", terminalId, e.getMessage(), e);
            result = PosTransactionResult.error("Terminál kommunikációs hiba: " + e.getMessage());
        }

        // 4. Utolsó tranzakció időpont frissítése
        if (result.approved()) {
            terminal.setLastTransactionAt(LocalDateTime.now());
            repository.save(terminal);
        }

        log.info("POS fizetés eredmény: {} {} terminál={} → {}",
                amount, currency, terminalId, result.status());

        return result;
    }

    // ============ SZTORNÓ ============

    /**
     * Bankkártyás fizetés sztornója (visszavonása).
     *
     * Legacy: OtpTermStorno / OtpAruvisszavet DLL.
     *
     * @param originalTransactionRef Eredeti tranzakció referencia szám
     * @param terminalId             Terminál azonosító
     * @return POS tranzakció eredmény
     */
    @Transactional
    public PosTransactionResult initiateReversal(String originalTransactionRef, String terminalId) {
        log.info("POS sztornó indítása: eredeti ref={}, terminál={}", originalTransactionRef, terminalId);

        PosTerminal terminal = repository.findByTerminalId(terminalId)
                .orElseThrow(() -> new ResourceNotFoundException("POS terminál nem található: " + terminalId));

        if (!Boolean.TRUE.equals(terminal.getIsActive())) {
            return PosTransactionResult.error("POS terminál inaktív: " + terminalId);
        }

        TerminalType mode = resolveTerminalType(terminal);

        PosTransactionResult result;
        try {
            result = switch (mode) {
                case MOCK -> executeMockReversal(originalTransactionRef, terminalId);
                case OTP -> executeOtpReversal(originalTransactionRef, terminalId);
                case BORGUN -> executeBorgunReversal(originalTransactionRef, terminalId);
                case WORLDLINE -> executeWorldlineReversal(originalTransactionRef, terminalId);
            };
        } catch (Exception e) {
            log.error("POS sztornó hiba: terminál={}, hiba={}", terminalId, e.getMessage(), e);
            result = PosTransactionResult.error("Terminál kommunikációs hiba: " + e.getMessage());
        }

        if (result.approved()) {
            terminal.setLastTransactionAt(LocalDateTime.now());
            repository.save(terminal);
        }

        log.info("POS sztornó eredmény: ref={} terminál={} → {}", originalTransactionRef, terminalId, result.status());
        return result;
    }

    // ============ NAPI ZÁRÁS ============

    /**
     * POS terminál napi zárás.
     *
     * Legacy: otpterminal DLL — napzáráskor összesítés és egyeztetés a bankkal.
     *
     * @param terminalId Terminál azonosító
     * @return Napi zárás eredmény
     */
    @Transactional
    public PosClosingResult dailyClose(String terminalId) {
        log.info("POS napi zárás indítása: terminál={}", terminalId);

        PosTerminal terminal = repository.findByTerminalId(terminalId)
                .orElseThrow(() -> new ResourceNotFoundException("POS terminál nem található: " + terminalId));

        if (!Boolean.TRUE.equals(terminal.getIsActive())) {
            return PosClosingResult.failure("POS terminál inaktív: " + terminalId);
        }

        TerminalType mode = resolveTerminalType(terminal);

        PosClosingResult result;
        try {
            result = switch (mode) {
                case MOCK -> executeMockDailyClose(terminalId);
                case OTP -> executeOtpDailyClose(terminalId);
                case BORGUN -> executeBorgunDailyClose(terminalId);
                case WORLDLINE -> executeWorldlineDailyClose(terminalId);
            };
        } catch (Exception e) {
            log.error("POS napi zárás hiba: terminál={}, hiba={}", terminalId, e.getMessage(), e);
            result = PosClosingResult.failure("Terminál kommunikációs hiba: " + e.getMessage());
        }

        log.info("POS napi zárás eredmény: terminál={} → sikeres={}, tranzakciók={}",
                terminalId, result.success(), result.transactionCount());
        return result;
    }

    // ============ TERMINÁL STÁTUSZ ============

    /**
     * Terminál státusz lekérdezés.
     *
     * @param terminalId Terminál azonosító
     * @return Terminál státusz
     */
    public TerminalStatus getStatus(String terminalId) {
        Optional<PosTerminal> optTerminal = repository.findByTerminalId(terminalId);
        if (optTerminal.isEmpty()) {
            return TerminalStatus.inactive(terminalId);
        }

        PosTerminal terminal = optTerminal.get();
        if (!Boolean.TRUE.equals(terminal.getIsActive())) {
            return TerminalStatus.inactive(terminalId);
        }

        TerminalType mode = resolveTerminalType(terminal);
        if (mode == TerminalType.MOCK) {
            return TerminalStatus.online(terminalId, terminal.getTerminalName(),
                    terminal.getTerminalType(), terminal.getLastTransactionAt());
        }

        if (mode == TerminalType.OTP) {
            boolean reachable = otpProtocol.checkConnection(resolveOtpHost(terminal), resolveOtpPort(terminal));
            if (reachable) {
            return TerminalStatus.online(terminalId, terminal.getTerminalName(),
                terminal.getTerminalType(), terminal.getLastTransactionAt());
            }
            return TerminalStatus.offline(terminalId, terminal.getTerminalName(), terminal.getTerminalType(),
                "OTP terminál nem elérhető");
        }

        boolean reachable = emitBridgeHeartbeat(mode, terminal);
        if (reachable) {
            return TerminalStatus.online(terminalId, terminal.getTerminalName(),
                terminal.getTerminalType(), terminal.getLastTransactionAt());
        }
        return TerminalStatus.offline(terminalId, terminal.getTerminalName(), terminal.getTerminalType(),
            mode.name() + " bridge heartbeat sikertelen");
    }

    // ============ LEGACY KOMPATIBILITÁS ============

    /**
     * Legacy processTransaction metódus — backward compatibility.
     */
    @Transactional
    public Map<String, Object> processTransaction(String terminalId, BigDecimal amount, String currency) {
        PosTransactionResult posResult = initiatePayment(amount, currency, terminalId);

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("terminalId", terminalId);
        result.put("amount", amount);
        result.put("currency", currency);
        result.put("status", posResult.approved() ? "PROCESSED" : "FAILED");
        result.put("authorizationCode", posResult.authorizationCode());
        result.put("referenceNumber", posResult.referenceNumber());
        result.put("processedAt", LocalDateTime.now());
        if (posResult.errorMessage() != null) {
            result.put("errorMessage", posResult.errorMessage());
        }
        return result;
    }

    // ============ HELPER METÓDUSOK ============

    /**
     * Terminál típus meghatározása: először a terminál saját beállítását nézzük,
     * majd a globális rendszerparamétert.
     */
    private TerminalType resolveTerminalType(PosTerminal terminal) {
        // Terminál saját típusa
        String type = terminal.getTerminalType();
        if (type != null && !type.isBlank() && !"MOCK".equalsIgnoreCase(type)) {
            try {
                return TerminalType.valueOf(type.toUpperCase());
            } catch (IllegalArgumentException e) {
                log.warn("Ismeretlen terminál típus: {} — fallback MOCK módra", type);
            }
        }

        // Globális rendszerparaméter
        try {
            String globalMode = systemParameterService.getValue("pos.terminal.mode");
            if (globalMode != null && !globalMode.isBlank()) {
                return TerminalType.valueOf(globalMode.toUpperCase());
            }
        } catch (Exception e) {
            log.debug("pos.terminal.mode paraméter nem elérhető — MOCK mód");
        }

        return TerminalType.MOCK;
    }

    // ============ MOCK IMPLEMENTÁCIÓ (dev/test) ============

    private PosTransactionResult executeMockPayment(BigDecimal amount, String currency, String terminalId) {
        String authCode = "MOCK-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        String refNumber = "REF-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        log.debug("MOCK POS fizetés: {} {} → APPROVED (auth={}, ref={})", amount, currency, authCode, refNumber);
        return PosTransactionResult.approved(authCode, refNumber);
    }

    private PosTransactionResult executeMockReversal(String originalRef, String terminalId) {
        String authCode = "MOCK-S-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        String refNumber = "REF-S-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        log.debug("MOCK POS sztornó: eredeti ref={} → APPROVED (auth={}, ref={})", originalRef, authCode, refNumber);
        return PosTransactionResult.approved(authCode, refNumber);
    }

    private PosClosingResult executeMockDailyClose(String terminalId) {
        log.debug("MOCK POS napi zárás: terminál={} → SUCCESS", terminalId);
        return PosClosingResult.success(0, BigDecimal.ZERO);
    }

    // ============ OTP IMPLEMENTÁCIÓ ============

    /**
     * OTP terminál kártyás fizetés.
     * Legacy: OTPFUNCTYPE=0 → Vasarlas() — TCP/IP kommunikáció a POS terminállal.
     */
    private PosTransactionResult executeOtpPayment(BigDecimal amount, String currency, String terminalId) {
        PosTerminal terminal = repository.findByTerminalId(terminalId).orElse(null);
        if (terminal == null) {
            return PosTransactionResult.error("OTP terminál nem található: " + terminalId);
        }

        String host = resolveOtpHost(terminal);
        int port = resolveOtpPort(terminal);
        String receiptNumber = terminalId + "-" + System.currentTimeMillis();

        log.info("OTP terminál fizetés: {} {} → {}:{}", amount, currency, host, port);
        return otpProtocol.executePayment(host, port, amount, receiptNumber);
    }

    /**
     * OTP terminál sztornó.
     * Legacy: OTPFUNCTYPE=100 → Storno() — utolsó bizonylat érvénytelenítése.
     */
    private PosTransactionResult executeOtpReversal(String originalRef, String terminalId) {
        PosTerminal terminal = repository.findByTerminalId(terminalId).orElse(null);
        if (terminal == null) {
            return PosTransactionResult.error("OTP terminál nem található: " + terminalId);
        }

        String host = resolveOtpHost(terminal);
        int port = resolveOtpPort(terminal);

        log.info("OTP terminál sztornó: ref={} → {}:{}", originalRef, host, port);
        return otpProtocol.executeStorno(host, port, originalRef);
    }

    /**
     * OTP terminál napi zárás.
     * Legacy: OTPFUNCTYPE=60 → TerminalZaras()
     */
    private PosClosingResult executeOtpDailyClose(String terminalId) {
        PosTerminal terminal = repository.findByTerminalId(terminalId).orElse(null);
        if (terminal == null) {
            return PosClosingResult.failure("OTP terminál nem található: " + terminalId);
        }

        String host = resolveOtpHost(terminal);
        int port = resolveOtpPort(terminal);

        log.info("OTP terminál napi zárás: terminál={} → {}:{}", terminalId, host, port);
        return otpProtocol.dailyClose(host, port);
    }

    /**
     * OTP terminál host IP cím meghatározása.
     * Legacy: HARDWARE.POSHOST
     */
    private String resolveOtpHost(PosTerminal terminal) {
        // Először a terminál saját konfigjából
        if (terminal.getIpAddress() != null && !terminal.getIpAddress().isBlank()) {
            return terminal.getIpAddress();
        }
        // Fallback: rendszerparaméter
        try {
            return systemParameterService.getValue("pos.otp.host");
        } catch (Exception e) {
            return "127.0.0.1";
        }
    }

    /**
     * OTP terminál port meghatározása.
     * Legacy: HARDWARE.POSPORT
     */
    private int resolveOtpPort(PosTerminal terminal) {
        if (terminal.getPort() != null && terminal.getPort() > 0) {
            return terminal.getPort();
        }
        try {
            return Integer.parseInt(systemParameterService.getValue("pos.otp.port"));
        } catch (Exception e) {
            return 5000; // default OTP port
        }
    }

    // ============ BORGUN IMPLEMENTÁCIÓ (TODO: éles driver) ============

    private PosTransactionResult executeBorgunPayment(BigDecimal amount, String currency, String terminalId) {
        return executeProviderBridgePayment(TerminalType.BORGUN, amount, currency, terminalId);
    }

    private PosTransactionResult executeBorgunReversal(String originalRef, String terminalId) {
        return executeProviderBridgeReversal(TerminalType.BORGUN, originalRef, terminalId);
    }

    private PosClosingResult executeBorgunDailyClose(String terminalId) {
        return executeProviderBridgeDailyClose(TerminalType.BORGUN, terminalId);
    }

    // ============ WORLDLINE IMPLEMENTÁCIÓ (TODO: éles driver) ============

    private PosTransactionResult executeWorldlinePayment(BigDecimal amount, String currency, String terminalId) {
        return executeProviderBridgePayment(TerminalType.WORLDLINE, amount, currency, terminalId);
    }

    private PosTransactionResult executeWorldlineReversal(String originalRef, String terminalId) {
        return executeProviderBridgeReversal(TerminalType.WORLDLINE, originalRef, terminalId);
    }

    private PosClosingResult executeWorldlineDailyClose(String terminalId) {
        return executeProviderBridgeDailyClose(TerminalType.WORLDLINE, terminalId);
    }

    private PosTransactionResult executeProviderBridgePayment(TerminalType provider,
                                                              BigDecimal amount,
                                                              String currency,
                                                              String terminalId) {
        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("action", "PAYMENT");
            payload.put("provider", provider.name());
            payload.put("terminalId", terminalId);
            payload.put("amount", amount);
            payload.put("currency", currency);
            payload.put("requestedAt", LocalDateTime.now().toString());

            Path artifact = fileTransportService.writeJson(resolvePosDir(provider), "pos_payment_" + sanitizeTerminalId(terminalId), payload);
            String authCode = provider.name().substring(0, 3) + "-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
            String ref = "BRIDGE-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
            log.info("{} payment bridge artifact: terminalId={}, file={}", provider, terminalId, artifact);
            return PosTransactionResult.approved(authCode, ref);
        } catch (Exception e) {
            log.error("{} payment bridge hiba: terminalId={}", provider, terminalId, e);
            return PosTransactionResult.error(provider + " bridge payment hiba: " + e.getMessage());
        }
    }

    private PosTransactionResult executeProviderBridgeReversal(TerminalType provider,
                                                               String originalRef,
                                                               String terminalId) {
        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("action", "REVERSAL");
            payload.put("provider", provider.name());
            payload.put("terminalId", terminalId);
            payload.put("originalRef", originalRef);
            payload.put("requestedAt", LocalDateTime.now().toString());

            Path artifact = fileTransportService.writeJson(resolvePosDir(provider), "pos_reversal_" + sanitizeTerminalId(terminalId), payload);
            String authCode = provider.name().substring(0, 3) + "-S-" + UUID.randomUUID().toString().substring(0, 4).toUpperCase();
            String ref = "BRIDGE-S-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
            log.info("{} reversal bridge artifact: terminalId={}, file={}", provider, terminalId, artifact);
            return PosTransactionResult.approved(authCode, ref);
        } catch (Exception e) {
            log.error("{} reversal bridge hiba: terminalId={}", provider, terminalId, e);
            return PosTransactionResult.error(provider + " bridge reversal hiba: " + e.getMessage());
        }
    }

    private PosClosingResult executeProviderBridgeDailyClose(TerminalType provider, String terminalId) {
        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("action", "DAILY_CLOSE");
            payload.put("provider", provider.name());
            payload.put("terminalId", terminalId);
            payload.put("requestedAt", LocalDateTime.now().toString());

            Path artifact = fileTransportService.writeJson(resolvePosDir(provider), "pos_daily_close_" + sanitizeTerminalId(terminalId), payload);
            log.info("{} daily-close bridge artifact: terminalId={}, file={}", provider, terminalId, artifact);
            return PosClosingResult.success(0, BigDecimal.ZERO);
        } catch (Exception e) {
            log.error("{} daily-close bridge hiba: terminalId={}", provider, terminalId, e);
            return PosClosingResult.failure(provider + " bridge daily close hiba: " + e.getMessage());
        }
    }

    private boolean emitBridgeHeartbeat(TerminalType provider, PosTerminal terminal) {
        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.put("action", "HEARTBEAT");
            payload.put("provider", provider.name());
            payload.put("terminalId", terminal.getTerminalId());
            payload.put("terminalName", terminal.getTerminalName());
            payload.put("requestedAt", LocalDateTime.now().toString());

            Path artifact = fileTransportService.writeJson(
                    resolvePosDir(provider),
                    "pos_heartbeat_" + sanitizeTerminalId(terminal.getTerminalId()),
                    payload);
            log.debug("{} heartbeat artifact létrehozva: terminalId={}, file={}", provider, terminal.getTerminalId(), artifact);
            return true;
        } catch (Exception e) {
            log.warn("{} heartbeat bridge sikertelen: terminalId={}, error={}",
                    provider, terminal.getTerminalId(), e.getMessage());
            return false;
        }
    }

    private String resolvePosDir(TerminalType provider) {
        String safeSyncDir = fileTransportService.sanitizePathSegment(
                integrationTransportProperties.getSync().getDir(), "sync.dir");
        return Paths.get(safeSyncDir, "pos-integration", provider.name().toLowerCase(Locale.ROOT)).toString();
    }

    private String sanitizeTerminalId(String terminalId) {
        String fallback = (terminalId == null || terminalId.isBlank()) ? "unknown" : terminalId.trim();
        return fileTransportService.sanitizePathSegment(fallback.replaceAll("[^A-Za-z0-9._-]", "_"), "terminalId");
    }
}
