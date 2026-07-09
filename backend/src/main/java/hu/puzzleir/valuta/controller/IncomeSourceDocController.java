package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.document.IncomeProofEmailRequest;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.security.SecurityUtils;
import hu.puzzleir.valuta.service.AuditLogService;
import hu.puzzleir.valuta.service.IncomeSourceDocService;
import hu.puzzleir.valuta.service.SystemParameterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;

@RestController
@RequestMapping("/api/v1/income-source-docs")
@RequiredArgsConstructor
public class IncomeSourceDocController {

    private static final int MAX_RECIPIENTS = 20;
    private static final Pattern EMAIL_RX = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

    private final IncomeSourceDocService incomeSourceDocService;
    private final SystemParameterService systemParameterService;
    private final AuditLogService auditLogService;

    @GetMapping("/required")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> required(
            @RequestParam BigDecimal hufAmount,
            @RequestParam(required = false) String customerId,
            @RequestParam(required = false) String currencyCode) {
        if (hufAmount == null || hufAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ValidationException("hufAmount pozitív szám kell legyen!");
        }
        return ResponseEntity.ok(Map.of(
                "required", incomeSourceDocService.isRequired(customerId, hufAmount, currencyCode),
                "thresholdHuf", incomeSourceDocService.thresholdHuf()));
    }

    @PostMapping("/email")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<Map<String, Object>> email(@Valid @RequestBody IncomeProofEmailRequest req) {
        int sent = incomeSourceDocService.sendIncomeProofDocument(req);
        return ResponseEntity.ok(Map.of("sentTo", sent));
    }

    @GetMapping("/recipients")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getRecipients() {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        String raw = systemParameterService.getCompanyValue(
                IncomeSourceDocService.RECIPIENTS_PARAM_KEY, companyId, "");
        List<String> list = Arrays.stream(raw.split(","))
                .map(String::trim).filter(s -> !s.isEmpty()).toList();
        return ResponseEntity.ok(Map.of("recipients", list));
    }

    @PutMapping("/recipients")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> putRecipients(@RequestBody Map<String, Object> body) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Object raw = body.get("recipients");
        if (raw != null && !(raw instanceof List<?>)) {
            throw new ValidationException("A 'recipients' egy lista kell legyen!");
        }
        List<String> rawList = raw == null ? null : ((List<?>) raw).stream()
                .filter(el -> el instanceof String)
                .map(el -> (String) el)
                .toList();
        if (rawList == null) {
            throw new ValidationException("A 'recipients' mező megadása kötelező!");
        }
        List<String> list = rawList.stream().map(String::trim)
                .filter(s -> !s.isEmpty()).toList();
        if (list.size() > MAX_RECIPIENTS) {
            throw new ValidationException("Maximum " + MAX_RECIPIENTS + " címzett adható meg!");
        }
        for (String email : list) {
            if (!EMAIL_RX.matcher(email).matches()) {
                throw new ValidationException("Érvénytelen címzett email: " + email);
            }
        }
        systemParameterService.upsertCompanyValue(
                IncomeSourceDocService.RECIPIENTS_PARAM_KEY, companyId,
                String.join(",", list), "COMPLIANCE",
                "FS-7 jövedelemforrás-igazolás compliance címzettek");
        auditLogService.log("INCOME_PROOF_DOC_RECIPIENTS_UPDATED",
                "cég=" + companyId + ", címzettek=" + list.size(), (String) null);
        return ResponseEntity.ok(Map.of("recipients", list, "count", list.size()));
    }
}
