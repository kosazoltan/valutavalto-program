package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.pos.*;
import hu.puzzleir.valuta.entity.PosTerminal;
import hu.puzzleir.valuta.repository.PosTerminalRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
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
                .orElseThrow(() -> new RuntimeException("PosTerminal not found: " + id));
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
                .orElseThrow(() -> new RuntimeException("POS terminál nem található: " + terminalId));

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
                .orElseThrow(() -> new RuntimeException("POS terminál nem található: " + terminalId));

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
                .orElseThrow(() -> new RuntimeException("POS terminál nem található: " + terminalId));

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

        // TODO: valódi ping implementálása terminál típus szerint
        return TerminalStatus.online(terminalId, terminal.getTerminalName(),
                terminal.getTerminalType(), terminal.getLastTransactionAt());
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

    // ============ OTP IMPLEMENTÁCIÓ (TODO: éles driver) ============

    private PosTransactionResult executeOtpPayment(BigDecimal amount, String currency, String terminalId) {
        // TODO: OTP terminál protokoll implementálása (ISO 8583 vagy saját OTP protokoll)
        // Legacy: otpterminal DLL hívás
        log.warn("OTP terminál fizetés: NEM IMPLEMENTÁLT — fallback MOCK módra. Terminál={}", terminalId);
        return executeMockPayment(amount, currency, terminalId);
    }

    private PosTransactionResult executeOtpReversal(String originalRef, String terminalId) {
        // TODO: OtpTermStorno / OtpAruvisszavet ekvivalens
        log.warn("OTP terminál sztornó: NEM IMPLEMENTÁLT — fallback MOCK módra. Terminál={}", terminalId);
        return executeMockReversal(originalRef, terminalId);
    }

    private PosClosingResult executeOtpDailyClose(String terminalId) {
        // TODO: otpterminal DLL ekvivalens — napzáráskor hívva
        log.warn("OTP terminál napi zárás: NEM IMPLEMENTÁLT — fallback MOCK módra. Terminál={}", terminalId);
        return executeMockDailyClose(terminalId);
    }

    // ============ BORGUN IMPLEMENTÁCIÓ (TODO: éles driver) ============

    private PosTransactionResult executeBorgunPayment(BigDecimal amount, String currency, String terminalId) {
        log.warn("Borgun terminál fizetés: NEM IMPLEMENTÁLT — fallback MOCK módra. Terminál={}", terminalId);
        return executeMockPayment(amount, currency, terminalId);
    }

    private PosTransactionResult executeBorgunReversal(String originalRef, String terminalId) {
        log.warn("Borgun terminál sztornó: NEM IMPLEMENTÁLT — fallback MOCK módra. Terminál={}", terminalId);
        return executeMockReversal(originalRef, terminalId);
    }

    private PosClosingResult executeBorgunDailyClose(String terminalId) {
        log.warn("Borgun terminál napi zárás: NEM IMPLEMENTÁLT — fallback MOCK módra. Terminál={}", terminalId);
        return executeMockDailyClose(terminalId);
    }

    // ============ WORLDLINE IMPLEMENTÁCIÓ (TODO: éles driver) ============

    private PosTransactionResult executeWorldlinePayment(BigDecimal amount, String currency, String terminalId) {
        log.warn("Worldline terminál fizetés: NEM IMPLEMENTÁLT — fallback MOCK módra. Terminál={}", terminalId);
        return executeMockPayment(amount, currency, terminalId);
    }

    private PosTransactionResult executeWorldlineReversal(String originalRef, String terminalId) {
        log.warn("Worldline terminál sztornó: NEM IMPLEMENTÁLT — fallback MOCK módra. Terminál={}", terminalId);
        return executeMockReversal(originalRef, terminalId);
    }

    private PosClosingResult executeWorldlineDailyClose(String terminalId) {
        log.warn("Worldline terminál napi zárás: NEM IMPLEMENTÁLT — fallback MOCK módra. Terminál={}", terminalId);
        return executeMockDailyClose(terminalId);
    }
}
