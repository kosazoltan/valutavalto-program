package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.compliance.ComplianceQuestionDto;
import hu.puzzleir.valuta.dto.compliance.CreateComplianceQuestionDto;
import hu.puzzleir.valuta.dto.compliance.CreateQuestionAnswerDto;
import hu.puzzleir.valuta.dto.compliance.CustomerQuestionAnswerDto;
import hu.puzzleir.valuta.dto.compliance.UpdateComplianceQuestionDto;
import hu.puzzleir.valuta.service.ComplianceQuestionService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

/**
 * FS-10 S1: compliance-kérdés endpointok.
 * Írás: compliance/vezetői szerepek; pénztár-sync read + válasz POST: pénztári szerepek.
 * A cég-scope a service-ben, a SecurityContextből (request-ben SOHA nincs companyId).
 */
@RestController
@RequestMapping("/api/v1/compliance-questions")
@RequiredArgsConstructor
public class ComplianceQuestionController {

    private final ComplianceQuestionService service;
    private final IdempotencyGuard idempotencyGuard;
    private static final String ENDPOINT_ANSWER_PREFIX = "POST /api/v1/compliance-questions/";
    private static final String COMPLIANCE_MANAGE_ROLES =
            "hasAnyRole('COMPLIANCE','COMPLIANCE_OFFICER','MANAGER','ADMIN',"
            + "'BELSO_ELLENOR','BIZTONSAGI_VEZETO','UGYVEZETO')";
    private static final String COMPLIANCE_VIEW_ROLES =
            "hasAnyRole('COMPLIANCE','COMPLIANCE_OFFICER','SUPERVISOR','MANAGER','ADMIN',"
            + "'BELSO_ELLENOR','BIZTONSAGI_VEZETO','UGYVEZETO')";

    @PostMapping
    @PreAuthorize(COMPLIANCE_MANAGE_ROLES)
    @Operation(summary = "Compliance-kérdés létrehozása")
    public ResponseEntity<ComplianceQuestionDto> create(
            @Valid @RequestBody CreateComplianceQuestionDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(dto));
    }

    @PutMapping("/{id}")
    @PreAuthorize(COMPLIANCE_MANAGE_ROLES)
    @Operation(summary = "Compliance-kérdés módosítása")
    public ResponseEntity<ComplianceQuestionDto> update(
            @PathVariable UUID id,
            @RequestBody UpdateComplianceQuestionDto dto) {
        return ResponseEntity.ok(service.update(id, dto));
    }

    @PutMapping("/{id}/active")
    @PreAuthorize(COMPLIANCE_MANAGE_ROLES)
    @Operation(summary = "Compliance-kérdés aktiválása/inaktiválása (soft-disable)")
    public ResponseEntity<ComplianceQuestionDto> setActive(
            @PathVariable UUID id,
            @Valid @RequestBody SetActiveRequest body) {
        return ResponseEntity.ok(service.setActive(id, body.active()));
    }

    @GetMapping
    @PreAuthorize(COMPLIANCE_MANAGE_ROLES)
    @Operation(summary = "Összes compliance-kérdés (inaktív is) — compliance-nézet")
    public ResponseEntity<List<ComplianceQuestionDto>> list() {
        return ResponseEntity.ok(service.listForCurrentCompany());
    }

    @GetMapping("/active")
    @PreAuthorize("hasAnyRole('CASHIER','SUPERVISOR','MANAGER','ADMIN')")
    @Operation(summary = "Aktív kérdések — pénztár sync-fetch")
    public ResponseEntity<List<ComplianceQuestionDto>> listActive() {
        return ResponseEntity.ok(service.listActiveForCurrentCompany());
    }

    @PostMapping("/{id}/answers")
    @PreAuthorize("hasAnyRole('CASHIER','SUPERVISOR','MANAGER','ADMIN')")
    @Operation(summary = "Ügyfél-válasz rögzítése a pénztárból (idempotens)")
    public ResponseEntity<CustomerQuestionAnswerDto> submitAnswer(
            @PathVariable UUID id,
            @Valid @RequestBody CreateQuestionAnswerDto dto,
            HttpServletRequest request) {
        String idempotencyKey = resolveIdempotencyKey(request);
        String endpoint = ENDPOINT_ANSWER_PREFIX + id + "/answers";
        IdempotencyGuard.Acquired<CustomerQuestionAnswerDto> acquired =
                idempotencyGuard.tryAcquire(idempotencyKey, endpoint, dto, CustomerQuestionAnswerDto.class);
        if (acquired.cachedResult() != null) {
            return ResponseEntity.status(HttpStatus.CREATED).body(acquired.cachedResult());
        }
        try {
            CustomerQuestionAnswerDto result;
            try {
                result = service.submitAnswer(id, dto);
            } catch (DataIntegrityViolationException race) {
                // TD6 (CQA-UPSERT-RACE): két EGYIDEJŰ első válasz azonos (company, question,
                // customer, tx) upsert-kulcsra, de KÜLÖNBÖZŐ Idempotency-Key-jel → a vesztes
                // INSERT a V347 parciális unique indexen bukik, a tranzakciója visszagördül
                // (flush-hiba után a tx rollback-only, service-en belül nem javítható).
                // EGYSZERI retry ÚJ tranzakcióban: a re-read már megtalálja a győztes sort,
                // és a meglévő UPDATE-ág last-writer-wins-szel fejezi be az upsertet —
                // azonosan a szekvenciális kétszeri POST szemantikájával. Ha a retry is
                // elszáll (elvi lehetetlen: válasz-sort semmi nem töröl), a hiba propagál.
                result = service.submitAnswer(id, dto);
            }
            idempotencyGuard.complete(acquired, result);
            return ResponseEntity.status(HttpStatus.CREATED).body(result);
        } catch (Exception e) {
            idempotencyGuard.fail(acquired);
            throw e;
        }
    }

    @GetMapping("/{id}/answers")
    @PreAuthorize(COMPLIANCE_VIEW_ROLES)
    @Operation(summary = "A kérdésre érkezett válaszok — compliance-nézet")
    public ResponseEntity<List<CustomerQuestionAnswerDto>> getAnswers(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getAnswersForQuestion(id));
    }

    @GetMapping("/answers/by-customer/{customerId}")
    @PreAuthorize(COMPLIANCE_VIEW_ROLES)
    @Operation(summary = "Egy ügyfél összes válasza — compliance-nézet")
    public ResponseEntity<List<CustomerQuestionAnswerDto>> getAnswersForCustomer(
            @PathVariable Long customerId) {
        return ResponseEntity.ok(service.getAnswersForCustomer(customerId));
    }

    private String resolveIdempotencyKey(HttpServletRequest request) {
        String key = request.getHeader("Idempotency-Key");
        if (StringUtils.hasText(key)) {
            return key;
        }
        return request.getHeader("X-Idempotency-Key");
    }

    private record SetActiveRequest(@NotNull(message = "Az 'active' mező kötelező (boolean)") Boolean active) {
    }
}
