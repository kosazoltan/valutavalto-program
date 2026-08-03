package hu.puzzleir.valuta.exception;

import hu.puzzleir.valuta.errorlog.ErrorMailerService;
import hu.puzzleir.valuta.errorlog.ErrorReportRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import jakarta.persistence.EntityNotFoundException;
import jakarta.persistence.OptimisticLockException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * Globális kivételkezelő — egységes hibaválasz formátum minden endpoint-ra.
 */
@RestControllerAdvice(basePackages = "hu.puzzleir.valuta")
@Slf4j
public class GlobalExceptionHandler {

    @Autowired(required = false)
    private ErrorMailerService errorMailerService;

    // --- 404 Not Found ---
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<ErrorResponse> handleNoResource(NoResourceFoundException ex) {
        log.debug("No resource found: {}", ex.getMessage());
        return buildResponse(HttpStatus.NOT_FOUND, "NOT_FOUND", ex.getMessage());
    }

    @ExceptionHandler({ResourceNotFoundException.class, NotFoundException.class})
    public ResponseEntity<ErrorResponse> handleResourceNotFound(ResourceNotFoundException ex) {
        log.warn("Resource not found: {}", ex.getMessage());
        return buildResponse(HttpStatus.NOT_FOUND, "NOT_FOUND", ex.getMessage());
    }

    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleEntityNotFound(EntityNotFoundException ex) {
        log.warn("Entity not found: {}", ex.getMessage());
        return buildResponse(HttpStatus.NOT_FOUND, "NOT_FOUND", ex.getMessage());
    }

    // --- 403 Forbidden ---
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ErrorResponse> handleAccessDenied(AccessDeniedException ex) {
        log.warn("Access denied: {}", ex.getMessage());
        if (ex.getMessage() != null && ex.getMessage().startsWith("VV-AUTH-001")) {
            return buildResponse(HttpStatus.FORBIDDEN, "VV-AUTH-001", "Nincs jogosultsága a művelet végrehajtásához");
        }
        return buildResponse(HttpStatus.FORBIDDEN, "ACCESS_DENIED", "Nincs jogosultsága a művelet végrehajtásához");
    }

    // --- 401 Unauthorized (authentication) ---
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ErrorResponse> handleAuthentication(AuthenticationException ex) {
        log.warn("Authentication failed: {}", ex.getMessage());
        return buildResponse(HttpStatus.UNAUTHORIZED, "UNAUTHORIZED", ex.getMessage());
    }

    // --- 400 Bad Request (bean validation) ---
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleMethodArgumentNotValid(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = error instanceof FieldError fieldError ? fieldError.getField() : error.getObjectName();
            String errorMessage = error.getDefaultMessage();
            fieldErrors.put(fieldName, errorMessage);
        });

        log.warn("Validation errors: {}", fieldErrors);

        ErrorResponse response = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.BAD_REQUEST.value())
                .error("VALIDATION_FAILED")
                .message("Validációs hiba")
                .fieldErrors(fieldErrors)
                .build();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    // --- 400 Bad Request (type mismatch — invalid date, number, etc.) ---
    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<ErrorResponse> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
        String paramName = ex.getName();
        String requiredType = ex.getRequiredType() != null ? ex.getRequiredType().getSimpleName() : "unknown";
        String message = String.format("Érvénytelen paraméter '%s': '%s' nem konvertálható %s típusra",
                paramName, ex.getValue(), requiredType);
        log.warn("Type mismatch: param={}, value={}, type={}", paramName, ex.getValue(), requiredType);
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST", message);
    }

    @ExceptionHandler(BindException.class)
    public ResponseEntity<ErrorResponse> handleBindException(BindException ex) {
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = error instanceof FieldError fieldError ? fieldError.getField() : error.getObjectName();
            fieldErrors.put(fieldName, error.getDefaultMessage());
        });

        log.warn("Bind validation errors: {}", fieldErrors);

        ErrorResponse response = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(HttpStatus.BAD_REQUEST.value())
                .error("VALIDATION_FAILED")
                .message("Validációs hiba")
                .fieldErrors(fieldErrors)
                .build();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleConstraintViolation(ConstraintViolationException ex) {
        log.warn("Constraint validation error: {}", ex.getMessage());
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage());
    }

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ErrorResponse> handleMissingRequestHeader(MissingRequestHeaderException ex) {
        log.warn("Missing request header: {}", ex.getHeaderName());
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST", "Hianyzo fejléc: " + ex.getHeaderName());
    }

    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ErrorResponse> handleMissingRequestParam(MissingServletRequestParameterException ex) {
        log.warn("Missing request parameter: {}", ex.getParameterName());
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST",
                "Kötelező paraméter hiányzik: " + ex.getParameterName());
    }

    // --- 400 Bad Request (missing/unreadable body) ---
    // Copilot PR #691 P1 finding + Codex PR #692 P1 finding:
    // Ha a Jackson enum-deserializaciot dob (pl. VoiceAssistantMode wire-name
    // nem letezo), az "Hiányzó vagy érvénytelen request body" generikus szoveg
    // helyett actionable feedback kell.
    //
    // HARMAS DETEKCIO a cause-lancban:
    //  (a) InvalidFormatException - csak az enum bind generikus path-en
    //  (b) ValueInstantiationException - @JsonCreator factory (pl.
    //      VoiceAssistantMode.fromWireName) dobott IllegalArgumentException-t
    //  (c) MismatchedInputException + IllegalArgumentException root cause
    //
    // Az enum wire-name lista @JsonValue annotation methodbol jon (ha letezik),
    // egyebkent name().lowercase(Locale.ROOT). A Locale.ROOT fix a tor lokal-bugot.
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        log.warn("Request body not readable: {}", ex.getMessage());

        // FK-072 (FR-3): a záró-varázsló címletezés végpontján a Map<Integer,Integer>
        // kulcs bind-hibája (tipikusan tört névérték, pl. "0.5") ne kontextus nélküli
        // nyers 400 legyen, hanem egyértelmű magyar validációs hiba. Az egész, de
        // 1 alatti kulcsot a ClosingWizardService validálja ugyanezzel a kóddal.
        // (A kérés-URI a RequestContextHolder-ből jön, hogy a handler-szignatúra ne
        // változzon — a meglévő unit tesztek közvetlenül, egy argumentummal hívják.)
        if (isClosingDenominationRequest() && isIntegerMapKeyBindFailure(ex)) {
            return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST",
                    "VV-VALID-004: A címlet névértéke nem lehet 1-nél kisebb (tört címlet"
                            + " nem rögzíthető) — a címletezés névértékei csak egész számok lehetnek.");
        }

        Throwable cur = ex.getCause();
        while (cur != null) {
            // (a) Klasszikus InvalidFormatException — Jackson default enum bind failure
            if (cur instanceof tools.jackson.databind.exc.InvalidFormatException ife) {
                Class<?> targetType = ife.getTargetType();
                if (targetType != null && targetType.isEnum()) {
                    return buildEnumBindError(targetType, ife.getValue(), extractFieldName(ife.getPath()));
                }
            }
            // (b) ValueInstantiationException — @JsonCreator factory dobott IAE-t
            // (pl. VoiceAssistantMode.fromWireName("unknown") → IllegalArgumentException)
            if (cur instanceof tools.jackson.databind.exc.ValueInstantiationException vie) {
                Class<?> targetType = vie.getType() != null ? vie.getType().getRawClass() : null;
                if (targetType != null && targetType.isEnum()) {
                    Throwable rootCause = vie.getCause();
                    Object value = extractEnumValueFromCauseAndProcessor(rootCause, vie);
                    return buildEnumBindError(targetType, value, extractFieldName(vie.getPath()));
                }
            }
            // (c) MismatchedInputException — egyeb Jackson bind failure path-ek
            if (cur instanceof tools.jackson.databind.exc.MismatchedInputException mie) {
                Class<?> targetType = mie.getTargetType();
                if (targetType != null && targetType.isEnum()) {
                    Object value = extractEnumValueFromCauseAndProcessor(mie.getCause(), mie);
                    return buildEnumBindError(targetType, value, extractFieldName(mie.getPath()));
                }
            }
            cur = cur.getCause();
        }

        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST",
                "Hiányzó vagy érvénytelen request body");
    }

    /** FK-072: a záró-varázsló címletezés-beküldési végpontja-e az aktuális kérés. */
    private boolean isClosingDenominationRequest() {
        var attrs = org.springframework.web.context.request.RequestContextHolder.getRequestAttributes();
        if (!(attrs instanceof org.springframework.web.context.request.ServletRequestAttributes sra)) {
            return false;
        }
        String uri = sra.getRequest().getRequestURI();
        return uri != null && uri.contains("/closing-wizard/") && uri.endsWith("/denominations");
    }

    /**
     * FK-072: Integer Map-kulcs bind-hibája-e a kivétel (pl. "0.5" kulcs). A Jackson 3
     * a hibás kulcsot InvalidFormatException-nel (targetType=Integer) jelzi; fallbackként
     * a kivétel-lánc üzenetében a "Map key" markert is elfogadjuk.
     */
    private boolean isIntegerMapKeyBindFailure(Throwable ex) {
        Throwable cur = ex;
        while (cur != null) {
            if (cur instanceof tools.jackson.databind.exc.InvalidFormatException ife
                    && Integer.class.equals(ife.getTargetType())) {
                return true;
            }
            if (cur.getMessage() != null && cur.getMessage().contains("Map key")) {
                return true;
            }
            cur = cur.getCause();
        }
        return false;
    }

    /**
     * Visszaadja az enum wire-name-jeit. Elsobbsegben a @JsonValue method
     * (pl. VoiceAssistantMode.getWireName()), egyebkent name().toLowerCase(ROOT).
     */
    private String collectEnumValues(Class<?> enumType) {
        java.lang.reflect.Method jsonValueMethod = null;
        for (java.lang.reflect.Method m : enumType.getMethods()) {
            if (m.isAnnotationPresent(com.fasterxml.jackson.annotation.JsonValue.class) && m.getParameterCount() == 0) {
                jsonValueMethod = m;
                break;
            }
        }
        final java.lang.reflect.Method finalMethod = jsonValueMethod;
        return java.util.Arrays.stream(enumType.getEnumConstants())
                .map(c -> {
                    if (finalMethod != null) {
                        try { return String.valueOf(finalMethod.invoke(c)); }
                        catch (IllegalAccessException | java.lang.reflect.InvocationTargetException ignored) { /* fallthrough */ }
                    }
                    return ((Enum<?>) c).name().toLowerCase(java.util.Locale.ROOT);
                })
                .collect(java.util.stream.Collectors.joining(", "));
    }

    private ResponseEntity<ErrorResponse> buildEnumBindError(Class<?> enumType, Object value, String fieldName) {
        String allowed = collectEnumValues(enumType);
        String message = String.format(
                "Érvénytelen érték a '%s' mezőben: '%s'. Megengedett értékek: %s.",
                fieldName,
                String.valueOf(value),
                allowed
        );
        return buildResponse(HttpStatus.BAD_REQUEST, "INVALID_ENUM_VALUE", message);
    }

    private String extractFieldName(java.util.List<tools.jackson.core.JacksonException.Reference> path) {
        return (path == null || path.isEmpty())
                ? "<unknown>"
                : path.get(path.size() - 1).getPropertyName();
    }

    /**
     * Probal kinyerni a beadott wire-name-et kettos forrasbol:
     *  1. cause IllegalArgumentException message vegerol (": foobar")
     *  2. ha az nem mukodik, a Jackson parser current token text-jebol
     */
    private Object extractEnumValueFromCauseAndProcessor(Throwable rootCause,
                                                         tools.jackson.databind.DatabindException jme) {
        // (1) IAE message tail: "VoiceAssistantMode ismeretlen: foobar"
        if (rootCause != null) {
            String message = rootCause.getMessage();
            if (message != null) {
                int colon = message.lastIndexOf(':');
                if (colon >= 0 && colon < message.length() - 1) {
                    return message.substring(colon + 1).trim();
                }
            }
        }
        // (2) JsonParser current token text
        Object processor = jme.processor();
        if (processor instanceof tools.jackson.core.JsonParser parser) {
            try {
                String currentText = parser.getText();
                if (currentText != null && !currentText.isBlank()) return currentText;
            } catch (tools.jackson.core.JacksonException ignored) { /* fallthrough */ }
        }
        return rootCause != null ? rootCause.getMessage() : null;
    }

    // --- 400 Bad Request (custom validation) ---
    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidation(ValidationException ex) {
        log.warn("Validation error: {}", ex.getMessage());
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage());
    }

    // FK-054: deliberately no IllegalStateException handler here. CurrencyStock.issueStock()
    // keeps IllegalStateException as a last-resort internal invariant; service-layer stock
    // coverage pre-gates convert user-facing insufficient-stock denials to ValidationException.
    // Mapping every IllegalStateException to 400 would mask real server defects as client errors.

    // --- 400 Bad Request (IllegalArgument) ---
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ErrorResponse> handleBadRequest(IllegalArgumentException ex) {
        log.warn("Bad request: {}", ex.getMessage());
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage());
    }

    // --- 400 Bad Request (ArithmeticException — Math.addExact / subtractExact overflow) ---
    // Codex P2 fix #235 follow-up: a Math.addExact/subtractExact overflow ArithmeticException-t
    // dob, ami korabban catch-all 500-as hibakent ment ki. Ez user-input szelsoertekenel (pl.
    // BanknoteInventory.addQuantity Integer.MAX_VALUE - quantity-vel) tortenhet, igy a 400 BAD_REQUEST
    // a megfelelo HTTP statusz.
    @ExceptionHandler(ArithmeticException.class)
    public ResponseEntity<ErrorResponse> handleArithmetic(ArithmeticException ex) {
        log.warn("Arithmetic boundary error: {}", ex.getMessage());
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST",
                "Szamtani hiba: a megadott ertek a megengedett tartomanyon kivul esik (overflow/underflow).");
    }

    // --- 409 Conflict (Optimistic Lock) ---
    @ExceptionHandler(OptimisticLockException.class)
    public ResponseEntity<ErrorResponse> handleConflict(OptimisticLockException ex) {
        log.warn("Optimistic lock conflict: {}", ex.getMessage());
        return buildResponse(HttpStatus.CONFLICT, "CONFLICT",
                "Az adatot időközben módosította valaki más. Kérjük, frissítse és próbálja újra.");
    }

    // --- 409 Conflict (Spring optimista lock wrapper) ---
    // FK-065 (Codex HIGH): a Spring Data a jakarta OptimisticLockException-t
    // ObjectOptimisticLockingFailureException-be csomagolja (commit-kori flushnál is) —
    // kezeletlenül generikus 500 lenne 409 helyett.
    @ExceptionHandler(org.springframework.dao.OptimisticLockingFailureException.class)
    public ResponseEntity<ErrorResponse> handleSpringOptimisticConflict(
            org.springframework.dao.OptimisticLockingFailureException ex) {
        log.warn("Optimistic lock conflict (Spring wrapper): {}", ex.getMessage());
        return buildResponse(HttpStatus.CONFLICT, "CONFLICT",
                "Az adatot időközben módosította valaki más. Kérjük, frissítse és próbálja újra.");
    }

    // --- 409 Conflict (custom) ---
    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<ErrorResponse> handleConflictException(ConflictException ex) {
        log.warn("Conflict: {}", ex.getMessage());
        return buildResponse(HttpStatus.CONFLICT, "CONFLICT", ex.getMessage());
    }

    // --- 422 Business Exception ---
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ErrorResponse> handleBusinessException(BusinessException ex) {
        log.warn("Business error [{}]: {}", ex.getErrorCode(), ex.getMessage());
        return buildResponse(ex.getHttpStatus(), ex.getErrorCode(), ex.getMessage());
    }

    // --- 500 Internal Server Error (catch-all) ---
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleInternalError(Exception ex, HttpServletRequest request) {
        // GAP-002: catch HttpMessageNotReadableException ha a specifikus handler nem kapta el
        if (ex instanceof HttpMessageNotReadableException) {
            log.warn("Request body not readable (catch-all): {}", ex.getMessage());
            return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST",
                    "Hiányzó vagy érvénytelen request body");
        }
        log.error("Unexpected internal error [{}]: {}", ex.getClass().getName(), ex.getMessage(), ex);

        if (errorMailerService != null) {
            try {
                errorMailerService.sendErrorReport(ErrorReportRequest.builder()
                    .errorType("api_error")
                    .message(ex.getMessage())
                    .stack(stackTraceToString(ex))
                    .url(request.getRequestURI())
                    .requestMethod(request.getMethod())
                    .requestId(request.getHeader("X-Request-ID"))
                    .timestamp(Instant.now().toString())
                    .build());
            } catch (Exception reportEx) {
                log.warn("Failed to send error report", reportEx);
            }
        }

        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR",
                "Belső szerverhiba történt. Kérjük, próbálja újra később.");
    }

    private String stackTraceToString(Exception ex) {
        StringWriter sw = new StringWriter();
        ex.printStackTrace(new PrintWriter(sw));
        String full = sw.toString();
        return full.length() > 5000 ? full.substring(0, 5000) : full;
    }

    // --- Helper ---
    private ResponseEntity<ErrorResponse> buildResponse(HttpStatus status, String error, String message) {
        ErrorResponse response = ErrorResponse.builder()
                .timestamp(LocalDateTime.now())
                .status(status.value())
                .error(error)
                .message(message)
                .build();
        return ResponseEntity.status(status).body(response);
    }
}
