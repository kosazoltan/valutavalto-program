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
    // Copilot PR #691 P1 finding: ha a Jackson enum-deserializaciot dob (pl.
    // VoiceAssistantMode wire-name nem letezo), az "Hiányzó vagy érvénytelen
    // request body" generikus szoveg helyett actionable feedback kell.
    // A cause-lancban benne van az InvalidFormatException, amibol kinyerheto
    // a megengedett enum-ertekek listaja.
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ErrorResponse> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        log.warn("Request body not readable: {}", ex.getMessage());

        // Mély-keresés: van-e InvalidFormatException a cause-láncban? (enum bind failure)
        Throwable cur = ex.getCause();
        while (cur != null) {
            if (cur instanceof com.fasterxml.jackson.databind.exc.InvalidFormatException ife) {
                Class<?> targetType = ife.getTargetType();
                if (targetType != null && targetType.isEnum()) {
                    String fieldName = ife.getPath().isEmpty()
                            ? "<unknown>"
                            : ife.getPath().get(ife.getPath().size() - 1).getFieldName();
                    String allowed = java.util.Arrays.stream(targetType.getEnumConstants())
                            .map(Object::toString)
                            .reduce((a, b) -> a + ", " + b)
                            .orElse("<none>");
                    String message = String.format(
                            "Érvénytelen érték a '%s' mezőben: '%s'. Megengedett értékek: %s.",
                            fieldName,
                            String.valueOf(ife.getValue()),
                            allowed.toLowerCase()
                    );
                    return buildResponse(HttpStatus.BAD_REQUEST, "INVALID_ENUM_VALUE", message);
                }
            }
            cur = cur.getCause();
        }

        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST",
                "Hiányzó vagy érvénytelen request body");
    }

    // --- 400 Bad Request (custom validation) ---
    @ExceptionHandler(ValidationException.class)
    public ResponseEntity<ErrorResponse> handleValidation(ValidationException ex) {
        log.warn("Validation error: {}", ex.getMessage());
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST", ex.getMessage());
    }

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
