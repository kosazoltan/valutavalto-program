package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeCreateRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeCreateResponseDto;
import hu.puzzleir.valuta.dto.shipment.ShipmentHandlingFeeDto;
import hu.puzzleir.valuta.dto.shipment.ShipmentVatSupplyCreateRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentVatSupplyCreateResponseDto;
import hu.puzzleir.valuta.dto.shipment.ShipmentVatSupplyDto;
import hu.puzzleir.valuta.dto.shipment.ShipmentDeliverRequest;
import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.exception.ErrorResponse;
import hu.puzzleir.valuta.service.ShipmentHandlingFeeService;
import hu.puzzleir.valuta.service.ShipmentService;
import hu.puzzleir.valuta.service.ShipmentVatSupplyService;
import hu.puzzleir.valuta.util.IdempotencyGuard;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Szállítmánykérés controller.
 * Fiókok közötti valuta szállítmány igénylés (Átadás-átvétel pénztáraknak) kezelése.
 *
 * <p><b>P0 fix (2026-05-28, Bali Henriett visszajelzés):</b> az olvasó végpontok a magyar
 * szerepkör-nevezéktanra (ERTEKTAR, FOERTEKTAR, PENZTAR, UGYVEZETO) is engedélyezettek
 * — értéktáros felhasználók addig 403-at kaptak, ami a frontenden hibás 500-ként
 * jelent meg ("Request failed with status code 500"). Az írás-szigorúság (approve)
 * marad SUPERVISOR/MANAGER/ADMIN szinten, kiegészítve FŐÉRTÉKTÁR/ÜGYVEZETŐ-vel.</p>
 */
@RestController
@RequestMapping("/api/v1/shipments")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', "
        + "'PENZTAR', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
public class ShipmentController {

    private final ShipmentService shipmentService;
    private final ShipmentHandlingFeeService shipmentHandlingFeeService;
    private final ShipmentVatSupplyService shipmentVatSupplyService;
    private final IdempotencyGuard idempotencyGuard;

    private static final String DEPRECATION_SUNSET = "Thu, 31 Dec 2026 23:59:59 GMT";

    /**
     * Szállítmánykérések listázása (lapozott, opcionális státusz- és branch-szűrő).
     * GET /api/v1/shipments?status=DRAFT&branchId=...&page=0&size=20
     *
     * <p>F2 (2026-06-01): a {@code branchId} natív, DB-szintű szűrő (fromBranchId VAGY toBranchId)
     * — megszünteti a kliens-oldali "összes letöltése + filter" mintát.
     */
    @GetMapping
    public ResponseEntity<Page<ShipmentRequestResponseDto>> findAll(
            @RequestParam(required = false) ShipmentRequestStatus status,
            @RequestParam(required = false) UUID branchId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(shipmentService.findAllResponse(status, branchId, PageRequest.of(page, size)));
    }

    /** FKH-018: a hitelesített célfiók még átvehető shipmentjei. */
    @GetMapping("/pending")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', "
            + "'PENZTAR', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<List<ShipmentRequestResponseDto>> pending() {
        return ResponseEntity.ok(shipmentService.findPendingForCurrentBranchResponse());
    }

    /**
     * Szállítmánykérés lekérése ID alapján.
     * GET /api/v1/shipments/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ShipmentRequestResponseDto> findById(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.findByIdResponse(id));
    }

    /**
     * FKH-018: a shipmenthez tartozó kezelési költség tétel lekérése (404, ha nincs).
     * GET /api/v1/shipments/{id}/handling-fee
     */
    @GetMapping("/{id}/handling-fee")
    public ResponseEntity<ShipmentHandlingFeeDto> getHandlingFee(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentHandlingFeeService.findByShipmentId(id));
    }

    /**
     * FKH-018: kezelési költség átvétel rögzítése — shipment (KK prefix, 1 HUF item)
     * és shipment_handling_fee sor egy tranzakcióban.
     * POST /api/v1/shipments/handling-fee
     */
    @PostMapping("/handling-fee")
    @PreAuthorize("hasAnyRole('ERTEKTAR', 'FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<ShipmentHandlingFeeCreateResponseDto> createHandlingFee(
            @Valid @RequestBody ShipmentHandlingFeeCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(shipmentHandlingFeeService.create(request));
    }

    /**
     * FKH-040: ÁFA átadás-átvétel tétel lekérése (404, ha nincs).
     * GET /api/v1/shipments/{id}/vat-supply
     */
    @GetMapping("/{id}/vat-supply")
    public ResponseEntity<ShipmentVatSupplyDto> getVatSupply(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentVatSupplyService.findByShipmentId(id));
    }

    /**
     * FKH-040: ÁFA átadás-átvétel rögzítése — shipment (AS prefix, 1 HUF item)
     * és shipment_vat_supply_item sor egy tranzakcióban. Nincs calculatedFee.
     * POST /api/v1/shipments/vat-supply
     */
    @PostMapping("/vat-supply")
    @PreAuthorize("hasAnyRole('ERTEKTAR', 'FOERTEKTAR', 'ADMIN')")
    public ResponseEntity<ShipmentVatSupplyCreateResponseDto> createVatSupply(
            @Valid @RequestBody ShipmentVatSupplyCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(shipmentVatSupplyService.create(request));
    }

    /**
     * Új szállítmánykérés létrehozása.
     * POST /api/v1/shipments
     */
    @PostMapping
    public ResponseEntity<ShipmentRequestResponseDto> create(@Valid @RequestBody ShipmentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(shipmentService.createResponse(request));
    }

    /**
     * Szállítmánykérés frissítése.
     * PUT /api/v1/shipments/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<ShipmentRequestResponseDto> update(
            @PathVariable UUID id,
            @Valid @RequestBody ShipmentRequest request) {
        return ResponseEntity.ok(shipmentService.updateResponse(id, request));
    }

    /**
     * Szállítmánykérés beküldése.
     * POST /api/v1/shipments/{id}/submit
     */
    @PostMapping("/{id}/submit")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', "
            + "'PENZTAR', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<ShipmentRequestResponseDto> submit(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.submitResponse(id));
    }

    /**
     * Szállítmánykérés jóváhagyása.
     * POST /api/v1/shipments/{id}/approve
     */
    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
    @Deprecated(since = "2.28.45", forRemoval = false)
    public ResponseEntity<ShipmentRequestResponseDto> approve(@PathVariable UUID id) {
        return deprecatedResponse(shipmentService.approveResponse(id));
    }

    /**
     * Szállítmánykérés leszállítása (átvevői visszaigazolás).
     * POST /api/v1/shipments/{id}/deliver
     *
     * <p>FR-4 defense-in-depth: a controller-szintű {@code @PreAuthorize} a szerepkör-réteget zárja
     * (csak készlet-kezelő szerepek), a service-szintű {@code assertReceiver} pedig a branch-réteget
     * (kizárólag az átvevő fiók). A kettő együtt adja a spec által kért kettős védelmet.</p>
     */
    @PostMapping("/{id}/deliver")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', "
            + "'PENZTAR', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "OK",
                    content = @Content(schema = @Schema(implementation = ShipmentRequestResponseDto.class))),
            @ApiResponse(responseCode = "409",
                    description = "Már kézbesített vagy azonos idempotenciakulccsal még feldolgozás alatt áll",
                    content = @Content(schema = @Schema(implementation = ErrorResponse.class)))
    })
    public ResponseEntity<ShipmentRequestResponseDto> deliver(
            @PathVariable UUID id,
            @RequestHeader(name = "Idempotency-Key", required = false) String idempotencyKey,
            @RequestHeader(name = "X-Idempotency-Key", required = false) String legacyIdempotencyKey,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    required = false,
                    description = "Régi Shipment figyelmeztetés tudatos megerősítése; hiánya kompatibilis.")
            @RequestBody(required = false) ShipmentDeliverRequest body) {
        String resolvedIdempotencyKey = resolveIdempotencyKey(idempotencyKey, legacyIdempotencyKey);
        boolean confirmedStale = body != null && Boolean.TRUE.equals(body.getConfirmedStale());
        String endpoint = "POST /api/v1/shipments/" + id + "/deliver";
        IdempotencyGuard.Acquired<ShipmentRequestResponseDto> acquired = idempotencyGuard.tryAcquire(
                resolvedIdempotencyKey, endpoint, id, ShipmentRequestResponseDto.class);
        if (acquired.cachedResult() != null) {
            return ResponseEntity.ok(acquired.cachedResult());
        }
        try {
            ShipmentRequestResponseDto result = shipmentService.deliverResponse(id, confirmedStale);
            idempotencyGuard.complete(acquired, result);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            idempotencyGuard.fail(acquired);
            throw e;
        }
    }

    /**
     * Szállítmánykérés visszavonása.
     * POST /api/v1/shipments/{id}/cancel
     */
    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN', "
            + "'PENZTAR', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<ShipmentRequestResponseDto> cancel(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.cancelResponse(id));
    }

    /**
     * Szállítmánykérés ELUTASÍTÁSA (reject) — külön a visszavonástól (cancel).
     * POST /api/v1/shipments/{id}/reject?reason=...
     *
     * <p>F3 (2026-06-01): a státuszt REJECTED-re állítja, és rögzíti a rejectionReason +
     * rejectedByWorkerId (a hitelesített user) audit-mezőket. Az elutasítás az approve
     * párja → azonos írás-jogosultság.
     */
    @PostMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'ERTEKTAR', 'FOERTEKTAR', 'UGYVEZETO')")
    @Deprecated(since = "2.28.45", forRemoval = false)
    public ResponseEntity<ShipmentRequestResponseDto> reject(
            @PathVariable UUID id,
            @RequestParam(required = false) String reason) {
        return deprecatedResponse(shipmentService.rejectResponse(id, reason));
    }

    private static <T> ResponseEntity<T> deprecatedResponse(T body) {
        return ResponseEntity.ok()
                .header("Deprecation", "true")
                .header("Sunset", DEPRECATION_SUNSET)
                .body(body);
    }

    private static String resolveIdempotencyKey(String key, String legacyKey) {
        return key != null && !key.isBlank() ? key : legacyKey;
    }
}
