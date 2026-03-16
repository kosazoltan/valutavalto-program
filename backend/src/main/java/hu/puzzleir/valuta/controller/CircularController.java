package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.circular.*;
import hu.puzzleir.valuta.entity.CircularType;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.CircularService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Körlevél controller.
 *
 * Legacy: ERTEKTAR — korlev.dll
 */
@RestController
@RequestMapping("/api/v1/circulars")
@RequiredArgsConstructor
public class CircularController {

    private final CircularService circularService;

    @GetMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CircularDto>> findAll() {
        return ResponseEntity.ok(circularService.findAll());
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CircularDto> findById(@PathVariable Long id) {
        return ResponseEntity.ok(circularService.findById(id));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CircularDto> create(
            @Valid @RequestBody CreateCircularDto dto,
            Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(circularService.create(dto, workerId));
    }

    @PostMapping("/{id}/acknowledge")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<CircularDto> acknowledge(@PathVariable Long id) {
        return ResponseEntity.ok(circularService.acknowledge(id));
    }

    @GetMapping("/unacknowledged")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<CircularDto>> findUnacknowledged() {
        return ResponseEntity.ok(circularService.findUnacknowledged());
    }

    // ============ ÚJ ENDPOINTOK — Típusok + Célcsoport ============

    @GetMapping("/types")
    @Operation(summary = "Összes elérhető körlevél típus listázása")
    public ResponseEntity<List<Map<String, Object>>> listTypes() {
        return ResponseEntity.ok(circularService.listTypes());
    }

    @GetMapping("/by-type/{type}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevelek szűrése típus szerint")
    public ResponseEntity<List<CircularDto>> findByType(@PathVariable CircularType type) {
        return ResponseEntity.ok(circularService.findByType(type));
    }

    @GetMapping("/relevant")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "Az aktuális irodához releváns nem nyugtázott körlevelek")
    public ResponseEntity<List<CircularDto>> findRelevant() {
        return ResponseEntity.ok(circularService.findRelevantForCurrentBranch());
    }

    @PostMapping("/typed")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevél létrehozása típussal és célcsoporttal")
    public ResponseEntity<CircularDto> createTyped(
            @Valid @RequestBody TypedCircularRequest request,
            Authentication auth) {
        Long workerId = getWorkerId(auth);

        CreateCircularDto dto = new CreateCircularDto();
        dto.setTitle(request.title());
        dto.setContent(request.content());
        dto.setUrgent(request.urgent());

        return ResponseEntity.status(HttpStatus.CREATED)
                .body(circularService.createTyped(
                        dto, workerId,
                        request.circularType(),
                        request.target(),
                        request.priority(),
                        request.targetBranchId(),
                        request.targetCompanyId(),
                        request.registrationNumber()));
    }

    @GetMapping("/search")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevél keresés iktatószám alapján")
    public ResponseEntity<List<CircularDto>> search(@RequestParam String q) {
        return ResponseEntity.ok(circularService.searchByRegistrationNumber(q));
    }

    // ============ V88: PER-WORKER NYUGTÁZÁS ============

    @PostMapping("/{id}/acknowledge-worker")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevél nyugtázása az aktuális dolgozóval (per-worker)")
    public ResponseEntity<CircularDto> acknowledgeByWorker(@PathVariable Long id) {
        return ResponseEntity.ok(circularService.acknowledgeByWorker(id));
    }

    @GetMapping("/my-unacknowledged")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "Saját nem nyugtázott körlevelek listázása")
    public ResponseEntity<List<CircularDto>> findMyUnacknowledged() {
        return ResponseEntity.ok(circularService.findUnacknowledgedForCurrentWorker());
    }

    @GetMapping("/{id}/acknowledgment-status")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevél nyugtázási státusza (hányan nyugtázták)")
    public ResponseEntity<Map<String, Object>> getAcknowledgmentStatus(@PathVariable Long id) {
        return ResponseEntity.ok(circularService.getAcknowledgmentStatus(id));
    }

    // ============ V88: KATEGÓRIÁK ============

    @GetMapping("/by-category/{category}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevelek kategória szerint (GENERAL, VIP, ZALOG)")
    public ResponseEntity<List<CircularDto>> findByCategory(@PathVariable String category) {
        return ResponseEntity.ok(circularService.findByCategory(category));
    }

    @GetMapping("/active")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "Aktív (nem archivált) körlevelek listázása")
    public ResponseEntity<List<CircularDto>> findActive() {
        return ResponseEntity.ok(circularService.findActiveForCompany());
    }

    // ============ V88: ARCHIVÁLÁS ============

    @PostMapping("/{id}/archive")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Körlevél archiválása")
    public ResponseEntity<CircularDto> archive(@PathVariable Long id) {
        return ResponseEntity.ok(circularService.archive(id));
    }

    @GetMapping("/archived")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Archivált körlevelek listázása")
    public ResponseEntity<List<CircularDto>> findArchived() {
        return ResponseEntity.ok(circularService.findArchived());
    }

    @GetMapping("/archived/{year}")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Archívum év szerint (legacy: LASTYEAR)")
    public ResponseEntity<List<CircularDto>> findByArchiveYear(@PathVariable Integer year) {
        return ResponseEntity.ok(circularService.findByArchiveYear(year));
    }

    // ============ V88: FÁJL FELTÖLTÉS/LETÖLTÉS ============

    @PostMapping("/{id}/attachment")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    @Operation(summary = "Csatolmány feltöltése körlevélhez (ODT/DOCX/PDF)")
    public ResponseEntity<CircularDto> uploadAttachment(
            @PathVariable Long id,
            @RequestParam("file") MultipartFile file) throws IOException {
        return ResponseEntity.ok(circularService.uploadAttachment(id, file));
    }

    @GetMapping("/{id}/attachment")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    @Operation(summary = "Csatolmány letöltése")
    public ResponseEntity<Resource> downloadAttachment(@PathVariable Long id) throws IOException {
        Path path = circularService.getAttachmentPath(id);
        Resource resource = new UrlResource(path.toUri());

        String filename = path.getFileName().toString();
        String contentType = "application/octet-stream";
        if (filename.endsWith(".odt")) contentType = "application/vnd.oasis.opendocument.text";
        else if (filename.endsWith(".docx")) contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
        else if (filename.endsWith(".pdf")) contentType = "application/pdf";

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .body(resource);
    }

    // --- Request DTO ---
    record TypedCircularRequest(
        String title,
        String content,
        Boolean urgent,
        CircularType circularType,
        CircularType.CircularTarget target,
        CircularType.CircularPriority priority,
        UUID targetBranchId,
        Integer targetCompanyId,
        String registrationNumber
    ) {}

    // ============ HELPERS ============

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new hu.puzzleir.valuta.exception.ValidationException("Hitelesítés szükséges!");
    }
}
