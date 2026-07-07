package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.currency.CurrencyDenominationImageDto;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.entity.DocumentSide;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.service.CurrencyDenominationImageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

/**
 * FS-9 S1: valuta-címletkép endpointok.
 * Írás: Valutakezelés-adminok (CurrencyController-precedens); olvasás: minden bejelentkezett
 * (a pénztár sync-fetch is ezt hívja). A cég-scope a service-ben, a SecurityContextből.
 */
@RestController
@RequestMapping("/api/v1/currency-denomination-images")
@RequiredArgsConstructor
public class CurrencyDenominationImageController {

    private final CurrencyDenominationImageService service;

    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<CurrencyDenominationImageDto> upload(
            @RequestParam("currencyId") Long currencyId,
            @RequestParam("faceValue") BigDecimal faceValue,
            @RequestParam("denominationType") String denominationType,
            @RequestParam("side") String side,
            @RequestParam("file") MultipartFile file) throws BindException {
        return ResponseEntity.ok(service.upload(
                currencyId,
                faceValue,
                parseDenominationType(denominationType),
                parseSide(side),
                file));
    }

    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<CurrencyDenominationImageDto>> list(
            @RequestParam(value = "currencyId", required = false) Long currencyId) {
        return ResponseEntity.ok(service.list(currencyId));
    }

    @GetMapping("/{id}/image")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<byte[]> getImage(@PathVariable UUID id) {
        CurrencyDenominationImageService.ImagePayload payload = service.getImage(id);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(payload.mimeType()))
                .body(payload.data());
    }

    @GetMapping("/{id}/thumbnail")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<byte[]> getThumbnail(@PathVariable UUID id) {
        CurrencyDenominationImageService.ImagePayload payload = service.getThumbnail(id);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(payload.mimeType()))
                .body(payload.data());
    }

    @PutMapping("/{id}/active")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<CurrencyDenominationImageDto> setActive(
            @PathVariable UUID id,
            @RequestBody Map<String, Object> body) {
        if (!(body.get("active") instanceof Boolean active)) {
            throw new ValidationException("Az 'active' mező kötelező (boolean)");
        }
        return ResponseEntity.ok(service.setActive(id, active));
    }

    private static DocumentSide parseSide(String side) throws BindException {
        try {
            return DocumentSide.valueOf(side.toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException | NullPointerException e) {
            throw validationBindException("side", side, "Érvénytelen oldal: " + side);
        }
    }

    private static DenominationType parseDenominationType(String type) throws BindException {
        try {
            return DenominationType.valueOf(type.toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException | NullPointerException e) {
            throw validationBindException("denominationType", type, "Érvénytelen címlet-típus: " + type);
        }
    }

    private static BindException validationBindException(String field, String rejectedValue, String message) {
        String objectName = "currencyDenominationImageUpload";
        BindException ex = new BindException(new Object(), objectName);
        ex.addError(new FieldError(objectName, field, rejectedValue, false, null, null, message));
        return ex;
    }
}
