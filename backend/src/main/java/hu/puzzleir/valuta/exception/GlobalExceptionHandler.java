package hu.puzzleir.valuta.exception;

import hu.puzzleir.valuta.errorlog.ErrorMailerService;
import hu.puzzleir.valuta.errorlog.ErrorReportRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import jakarta.persistence.EntityNotFoundException;
import jakarta.persistence.OptimisticLockException;
import jakarta.servlet.http.HttpServletRequest;
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

    @ExceptionHandler(ResourceNotFoundException.class)
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

    // --- 400 Bad Request (bean validation) ---
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleMethodArgumentNotValid(MethodArgumentNotValidException ex) {
        Map<String, String> fieldErrors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach(error -> {
            String fieldName = ((FieldError) error).getField();
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

    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ErrorResponse> handleMissingRequestHeader(MissingRequestHeaderException ex) {
        log.warn("Missing request header: {}", ex.getHeaderName());
        return buildResponse(HttpStatus.BAD_REQUEST, "BAD_REQUEST", "Hianyzo fejléc: " + ex.getHeaderName());
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

    // --- 409 Conflict (Optimistic Lock) ---
    @ExceptionHandler(OptimisticLockException.class)
    public ResponseEntity<ErrorResponse> handleConflict(OptimisticLockException ex) {
        log.warn("Optimistic lock conflict: {}", ex.getMessage());
        return buildResponse(HttpStatus.CONFLICT, "CONFLICT",
                "Az adatot időközben módosította valaki más. Kérjük, frissítse és próbálja újra.");
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
        log.error("Unexpected internal error", ex);

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

        String rootCause = ex.getMessage();
        Throwable cause = ex.getCause();
        while (cause != null) {
            rootCause = cause.getClass().getSimpleName() + ": " + cause.getMessage();
            cause = cause.getCause();
        }
        String devMessage = ex.getClass().getSimpleName() + " — " + rootCause;
        return buildResponse(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", devMessage);
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
