package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.reservation.*;
import hu.puzzleir.valuta.entity.Reservation;
import hu.puzzleir.valuta.mapper.ReservationMapper;
import hu.puzzleir.valuta.service.ReservationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Foglaló (Reservation) controller.
 *
 * Legacy: FOGLALO.DLL — FoglaloBevetelezes, VisszaFizetoProcedura, FoglaloKivezetes
 *
 * Endpoints:
 * - POST /                    — új foglaló létrehozás
 * - POST /{id}/fulfill        — teljesítés (_visszatipus=1)
 * - POST /{id}/cancel-by-customer — ügyfél stornó (_visszatipus=2)
 * - POST /{id}/cancel-by-company  — EBC stornó (_visszatipus=3)
 * - GET  /active              — aktív foglalók
 * - GET  /expired             — lejárt foglalók
 * - GET  /reserved-stock      — foglalt készlet valutanemenként
 * - GET  /{id}                — részletek
 */
@RestController
@RequestMapping("/api/v1/reservations")
@RequiredArgsConstructor
public class ReservationController {

    private final ReservationService reservationService;
    private final ReservationMapper reservationMapper;

    /**
     * Új foglaló létrehozás.
     *
     * POST /api/v1/reservations
     * Legacy: FoglaloBevetelezes
     */
    @PostMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReservationDto> createReservation(
            @Valid @RequestBody CreateReservationDto dto) {
        Reservation reservation = reservationService.createReservation(
                dto.getCustomerId(),
                dto.getCurrencyCode(),
                dto.getAmount(),
                dto.getExchangeRate(),
                dto.getExpiresAt(),
                dto.getNotes());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(reservationMapper.toDto(reservation));
    }

    /**
     * Foglaló teljesítés.
     *
     * POST /api/v1/reservations/{id}/fulfill
     * Legacy: VisszaFizetoProcedura _visszatipus=1
     */
    @PostMapping("/{id}/fulfill")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReservationDto> fulfillReservation(
            @PathVariable Long id,
            @Valid @RequestBody(required = false) FulfillReservationDto dto) {
        Reservation reservation = reservationService.fulfillReservation(id);
        return ResponseEntity.ok(reservationMapper.toDto(reservation));
    }

    /**
     * Ügyfél stornó.
     *
     * POST /api/v1/reservations/{id}/cancel-by-customer
     * Legacy: VisszaFizetoProcedura _visszatipus=2
     */
    @PostMapping("/{id}/cancel-by-customer")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReservationDto> cancelByCustomer(
            @PathVariable Long id,
            @Valid @RequestBody(required = false) CancelReservationDto dto) {
        String reason = dto != null ? dto.getReason() : null;
        Reservation reservation = reservationService.cancelByCustomer(id, reason);
        return ResponseEntity.ok(reservationMapper.toDto(reservation));
    }

    /**
     * EBC stornó (supervisor jóváhagyás szükséges).
     *
     * POST /api/v1/reservations/{id}/cancel-by-company
     * Legacy: VisszaFizetoProcedura _visszatipus=3
     */
    @PostMapping("/{id}/cancel-by-company")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReservationDto> cancelByCompany(
            @PathVariable Long id,
            @Valid @RequestBody CancelReservationDto dto) {
        Reservation reservation = reservationService.cancelByCompany(
                id, dto.getReason(), dto.getSupervisorWorkerId());
        return ResponseEntity.ok(reservationMapper.toDto(reservation));
    }

    /**
     * Aktív foglalók listája.
     *
     * GET /api/v1/reservations/active?branchId=...
     */
    @GetMapping("/active")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<ReservationDto>> getActiveReservations(
            @RequestParam UUID branchId) {
        List<Reservation> reservations = reservationService.getActiveReservations(branchId);
        List<ReservationDto> dtos = reservations.stream()
                .map(reservationMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Lejárt, de nem lezárt foglalók.
     *
     * GET /api/v1/reservations/expired
     */
    @GetMapping("/expired")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<ReservationDto>> getExpiredReservations() {
        List<Reservation> reservations = reservationService.getExpiredReservations();
        List<ReservationDto> dtos = reservations.stream()
                .map(reservationMapper::toDto)
                .collect(Collectors.toList());
        return ResponseEntity.ok(dtos);
    }

    /**
     * Foglalt készlet valutanemenként (FOGLALOKESZLET).
     *
     * GET /api/v1/reservations/reserved-stock?branchId=...
     */
    @GetMapping("/reserved-stock")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<ReservedStockDto>> getReservedStock(
            @RequestParam UUID branchId) {
        List<ReservedStockDto> stock = reservationService.getReservedStock(branchId);
        return ResponseEntity.ok(stock);
    }

    /**
     * Foglaló részletek.
     *
     * GET /api/v1/reservations/{id}
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<ReservationDto> getReservation(@PathVariable Long id) {
        Reservation reservation = reservationService.getReservation(id);
        return ResponseEntity.ok(reservationMapper.toDto(reservation));
    }
}
