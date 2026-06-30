package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.shipment.ShipmentRequestResponseDto;
import hu.puzzleir.valuta.entity.ShipmentRequest;
import hu.puzzleir.valuta.entity.ShipmentRequestStatus;
import hu.puzzleir.valuta.service.ShipmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

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

    /**
     * Szállítmánykérés lekérése ID alapján.
     * GET /api/v1/shipments/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<ShipmentRequestResponseDto> findById(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.findByIdResponse(id));
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
    public ResponseEntity<ShipmentRequestResponseDto> submit(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.submitResponse(id));
    }

    /**
     * Szállítmánykérés jóváhagyása.
     * POST /api/v1/shipments/{id}/approve
     */
    @PostMapping("/{id}/approve")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<ShipmentRequestResponseDto> approve(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.approveResponse(id));
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
    public ResponseEntity<ShipmentRequestResponseDto> deliver(@PathVariable UUID id) {
        return ResponseEntity.ok(shipmentService.deliverResponse(id));
    }

    /**
     * Szállítmánykérés visszavonása.
     * POST /api/v1/shipments/{id}/cancel
     */
    @PostMapping("/{id}/cancel")
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
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN', 'FOERTEKTAR', 'UGYVEZETO')")
    public ResponseEntity<ShipmentRequestResponseDto> reject(
            @PathVariable UUID id,
            @RequestParam(required = false) String reason) {
        return ResponseEntity.ok(shipmentService.rejectResponse(id, reason));
    }
}
