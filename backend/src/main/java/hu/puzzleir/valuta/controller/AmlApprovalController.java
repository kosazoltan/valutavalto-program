package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.aml.AmlCheckResult;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.WorkerRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AmlApprovalService;
import hu.puzzleir.valuta.service.AmlService;
import hu.puzzleir.valuta.service.SupervisorPinService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;

/**
 * AML felsővezetői jóváhagyás — POS-oldali engedélyező-ellenőrzés.
 *
 * <p>Amikor egy AML-küszöböt átlépő tranzakciónál (FATF 1/a, ≥5M magas-kockázat, éves limit, BIGCTRL
 * 4+ besorolás) felsővezetői jóváhagyás kell, a PÉNZTÁROS (CASHIER) sessionjéből kell egy supervisor/
 * manager/admin engedélyt kérni. Az {@code AmlController} osztály-szintű {@code @PreAuthorize}-a
 * SUPERVISOR+-t követel, a {@code SupervisorPinController.verify} szintén — egyik sem hívható egy
 * pénztáros sessionjéből. Ez a controller {@code isAuthenticated()} szinten elérhető, és a beküldött
 * engedélyezőt validálja:</p>
 * <ol>
 *   <li>4-szem-elv: az engedélyező NEM lehet a bejelentkezett (rögzítő) pénztáros;</li>
 *   <li>jogosultság: az engedélyező az aktuális céghez tartozó SUPERVISOR/MANAGER/ADMIN
 *       ({@link AmlApprovalService#isValidSeniorApprover});</li>
 *   <li>jelenlét-bizonyíték: az engedélyező supervisor-PIN-je helyes
 *       ({@link SupervisorPinService#verifyPin} — lockout + audit).</li>
 * </ol>
 *
 * <p>Siker esetén a kliens a kapott {@code approverWorkerId}-t a tranzakció-request DTO-ba teszi; a
 * tranzakció-flow ({@code TransactionService} → {@code AmlApprovalService.recordSeniorApproval}) a
 * rögzítéskor MÉGEGYSZER validál (szerepkör + cég + 4-szem-elv), így ez az endpoint nem megkerülhető
 * biztonsági kapu, hanem korai (jó UX-ű) ellenőrzés + a PIN-jelenlét bizonyítása.</p>
 */
@RestController
@RequestMapping("/api/v1/aml-approval")
@RequiredArgsConstructor
@Slf4j
public class AmlApprovalController {

    private final AmlApprovalService amlApprovalService;
    private final SupervisorPinService supervisorPinService;
    private final WorkerRepository workerRepository;
    private final AmlService amlService;

    /**
     * Pre-check: kell-e a tervezett tranzakcióhoz AML felsővezetői jóváhagyás?
     * Body: { amountHuf, customerId?, customerName?, documentNumber?, currencyCode?, customerNationality? }.
     *
     * <p>A pénztáros (CASHIER) ezzel a rögzítés ELŐTT (online) megtudja, kell-e engedélyt kérni — az
     * {@code AmlController.check} SUPERVISOR+-gated, ezt nem hívhatja. A backend két AML-kapuját futtatja:
     * a basicResult-ot ({@link AmlService#checkTransaction} — FATF / éves göngyölési limit ≥3.6M, ami
     * flag-független és nem-supervisornál ténylegesen blokkol) és a threshold-kaput
     * ({@link AmlService#checkAllThresholds} — BIGCTRL 4+ / 8 napos gördülő). A determináció így a
     * tranzakció-flow-éval konzisztens; a végső, hiteles döntés a tranzakció-POST szerver-oldalán dől el.</p>
     */
    @PostMapping("/check-required")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> checkApprovalRequired(@RequestBody Map<String, Object> body) {
        BigDecimal amountHuf = toBigDecimal(body.get("amountHuf"));
        if (amountHuf == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "amountHuf kötelező"));
        }
        String customerId = asStr(body.get("customerId"));
        String customerName = asStr(body.get("customerName"));
        String documentNumber = asStr(body.get("documentNumber"));
        String currencyCode = asStr(body.get("currencyCode"));
        String customerNationality = asStr(body.get("customerNationality"));

        boolean required = false;
        String reason = null;

        // 1) Basic kapu (FATF + éves göngyölés). Read-only; ha bármi okból kivételt dobna (pl. szankciós
        //    hard-reject), a pre-check NEM blokkol — a tényleges tranzakció-POST úgyis kiváltja a rejectet.
        try {
            AmlService.AmlBasicCheckResult basic = amlService.checkTransaction(
                    amountHuf, customerId, customerName, documentNumber, currencyCode, customerNationality);
            if (basic.isRequiresApproval()) {
                required = true;
                reason = basic.getApprovalReason();
            }
        } catch (RuntimeException e) {
            log.warn("[AML-APPROVAL] check-required basic-kapu hiba (nem blokkoló): {}", e.toString());
        }

        // 2) Threshold kapu (BIGCTRL 4+ / 8 napos gördülő) — csak ha van ügyfél-azonosító.
        if (!required && customerId != null && !customerId.isBlank()) {
            AmlCheckResult threshold = amlService.checkAllThresholds(customerId, amountHuf, currencyCode);
            if (threshold.isRequiresManagerApproval()) {
                required = true;
                reason = threshold.getManagerApprovalReason();
            }
        }

        Map<String, Object> resp = new HashMap<>();
        resp.put("requiresApproval", required);
        resp.put("reason", reason != null ? reason : "");
        return ResponseEntity.ok(resp);
    }

    private static String asStr(Object o) {
        return o instanceof String s && !s.isBlank() ? s : null;
    }

    private static BigDecimal toBigDecimal(Object o) {
        if (o instanceof Number n) {
            return BigDecimal.valueOf(n.doubleValue());
        }
        if (o instanceof String s && !s.isBlank()) {
            try {
                return new BigDecimal(s.trim());
            } catch (NumberFormatException e) {
                return null;
            }
        }
        return null;
    }

    /**
     * Engedélyező ellenőrzése PIN-nel. Body: { approverWorkerId, pin }.
     * Bárki authentikált pénztáros hívhatja (a saját tranzakciójához kér jóváhagyást).
     */
    @PostMapping("/verify-approver")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> verifyApprover(
            @RequestBody Map<String, Object> body,
            HttpServletRequest request) {

        Object idObj = body.get("approverWorkerId");
        Long approverWorkerId = idObj instanceof Number n ? n.longValue()
                : idObj instanceof String s && !s.isBlank() ? Long.parseLong(s.trim())
                : null;
        String pin = body.get("pin") instanceof String p ? p : null;

        if (approverWorkerId == null || pin == null || pin.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("ok", false, "error", "approverWorkerId + pin kötelező"));
        }

        // 1) 4-szem-elv: az engedélyező nem lehet a rögzítő pénztáros.
        Long currentWorkerId = SecurityUtils.getCurrentWorkerId();
        if (currentWorkerId != null && currentWorkerId.equals(approverWorkerId)) {
            return ResponseEntity.badRequest().body(Map.of("ok", false,
                    "error", "Az engedélyező nem lehet a tranzakciót rögzítő dolgozó (4-szem-elv)."));
        }

        // 2) Jogosultság: az aktuális céghez tartozó SUPERVISOR/MANAGER/ADMIN.
        if (!amlApprovalService.isValidSeniorApprover(approverWorkerId)) {
            return ResponseEntity.badRequest().body(Map.of("ok", false,
                    "error", "A kiválasztott dolgozó nem jogosult AML jóváhagyásra (supervisor/manager/admin szükséges)."));
        }

        // 3) PIN-jelenlét bizonyítása (lockout + audit a SupervisorPinService-ben).
        String ip = extractClientIp(request);
        String ua = request.getHeader("User-Agent");
        boolean pinOk;
        try {
            pinOk = supervisorPinService.verifyPin(approverWorkerId, pin, ip, ua);
        } catch (ValidationException e) {
            // Lockout ("túl sok hibás próbálkozás") vagy "nincs PIN beállítva" — egységes 401, a modal
            // a válasz "error" mezőjét jeleníti meg. (Nem dobjuk tovább, hogy a kliens egyértelmű
            // hibaüzenetet kapjon a generikus globális handler helyett.)
            return ResponseEntity.status(401).body(Map.of("ok", false, "error", e.getMessage()));
        }
        if (!pinOk) {
            return ResponseEntity.status(401).body(Map.of("ok", false, "error", "Hibás PIN"));
        }

        String approverName = workerRepository.findById(approverWorkerId)
                .map(Worker::getName)
                .orElse("#" + approverWorkerId);
        log.info("[AML-APPROVAL] Engedélyező verifikálva — approver #{} a rögzítő #{} tranzakciójához",
                approverWorkerId, currentWorkerId);
        return ResponseEntity.ok(Map.of(
                "ok", true,
                "approverWorkerId", approverWorkerId,
                "approverName", approverName));
    }

    private String extractClientIp(HttpServletRequest req) {
        String fwd = req.getHeader("X-Forwarded-For");
        if (fwd != null && !fwd.isBlank()) {
            return fwd.split(",")[0].trim();
        }
        return req.getRemoteAddr();
    }
}
