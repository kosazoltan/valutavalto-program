package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.transfer.*;
import hu.puzzleir.valuta.entity.Transfer;
import hu.puzzleir.valuta.security.WorkerAuthenticationDetails;
import hu.puzzleir.valuta.service.TransferService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transfers")
@RequiredArgsConstructor
public class TransferController {

    private final TransferService transferService;

    @PostMapping
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDto> create(@Valid @RequestBody CreateTransferDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.status(HttpStatus.CREATED).body(transferService.create(dto, workerId));
    }

    @PostMapping("/{id}/receive")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDto> receive(@PathVariable Long id, @Valid @RequestBody ReceiveTransferDto dto, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(transferService.receive(id, dto, workerId));
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize("hasAnyRole('SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDto> reject(@PathVariable Long id, @RequestParam String reason, Authentication auth) {
        Long workerId = getWorkerId(auth);
        return ResponseEntity.ok(transferService.reject(id, reason, workerId));
    }

    /**
     * PENDING átadás visszavonása — a végpont MEGMARAD (kliens-kompatibilitás), de belül a
     * BIZTONSÁGOS sztornó-útvonalra irányít.
     *
     * <p>A korábbi {@code TransferService.cancel} csak státuszt váltott: a create-kor lekönyvelt
     * összeg NEM került vissza a küldő fiók kasszájába, bizonylat és audit-nyom sem keletkezett.
     * Mostantól a hívás a {@link TransferService#storno} diszpécserre megy, amely PENDING-nél
     * automatikusan a {@code stornoPending} ágra fut (visszapótlás + {@code -SZ} bizonylat +
     * {@code STORNO} audit + HUF naplósorszám). Ezért lett az indoklás KÖTELEZŐ.
     *
     * <p>A válasz alakja szándékosan változatlan (204 No Content) — a szűkített hatókör miatt a
     * kliens-oldali szerződésből csak a request body bővül. Szerepkör-annotáció változatlan.
     */
    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Void> cancel(@PathVariable Long id, @Valid @RequestBody StornoRequestDto dto) {
        transferService.storno(id, dto.getReason());
        return ResponseEntity.noContent().build();
    }

    /**
     * Átadás-átvétel bizonylat SZTORNÓZÁSA indoklással (FR-12..16). Külön a {@code /cancel}-től
     * (ami a PENDING-törlés): a sztornó megtartja a rekordot, megjelöli, és {@code <eredeti>-SZ}
     * sorszámú sztornó bizonylatot tesz lehetővé. Jogosultság = a rögzítési joggal azonos.
     */
    @PostMapping("/{id}/storno")
    @PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
    public ResponseEntity<TransferDto> storno(@PathVariable Long id, @Valid @RequestBody StornoRequestDto dto) {
        return ResponseEntity.ok(transferService.storno(id, dto.getReason()));
    }

    /** Sztornó bizonylat előnézet-adatai (FR-15): eredeti adatok + indoklás + {@code <eredeti>-SZ} sorszám. */
    @GetMapping("/{id}/storno-preview")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<TransferDto> stornoPreview(@PathVariable Long id) {
        return ResponseEntity.ok(transferService.getStornoPreview(id));
    }

    @GetMapping("/{id}")
    public ResponseEntity<TransferDto> getById(@PathVariable Long id) {
        return ResponseEntity.ok(transferService.getById(id));
    }

    @GetMapping("/number/{transferNumber}")
    public ResponseEntity<TransferDto> getByTransferNumber(@PathVariable String transferNumber) {
        return ResponseEntity.ok(transferService.getByTransferNumber(transferNumber));
    }

    @GetMapping("/pending")
    public ResponseEntity<List<TransferDto>> getPending() {
        return ResponseEntity.ok(transferService.getPending());
    }

    @GetMapping("/outgoing")
    public ResponseEntity<List<TransferDto>> getOutgoing(Authentication auth) {
        UUID branchId = getBranchId(auth);
        return ResponseEntity.ok(transferService.getOutgoing(branchId));
    }

    @GetMapping("/incoming")
    public ResponseEntity<List<TransferDto>> getIncoming(Authentication auth) {
        UUID branchId = getBranchId(auth);
        return ResponseEntity.ok(transferService.getIncoming(branchId));
    }

    @GetMapping
    public ResponseEntity<Page<TransferDto>> search(
            @RequestParam(required = false) UUID branchId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) Transfer.TransferStatus status,
            @RequestParam(required = false) Transfer.TransferType type,
            // FKH-037 FR-1 (TBD-3): bizonylat dátum+idő szerinti legfrissebb-elől alapértelmezés;
            // JPQL ORDER BY szándékosan NINCS (Pageable-lel ütközne).
            @PageableDefault(sort = {"transferDate", "transferTime", "createdAt"}, direction = Sort.Direction.DESC)
            Pageable pageable) {
        return ResponseEntity.ok(transferService.search(branchId, startDate, endDate, status, type, pageable));
    }

    @GetMapping("/pending/count")
    public ResponseEntity<Long> countPending(Authentication auth) {
        UUID branchId = getBranchId(auth);
        return ResponseEntity.ok(transferService.countPending(branchId));
    }

    private Long getWorkerId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getWorkerId();
        }
        throw new hu.puzzleir.valuta.exception.ValidationException("Hitelesítés szükséges!");
    }

    private UUID getBranchId(Authentication auth) {
        if (auth != null && auth.getDetails() instanceof WorkerAuthenticationDetails details) {
            return details.getBranchId();
        }
        throw new hu.puzzleir.valuta.exception.ValidationException("Hitelesítés szükséges!");
    }
}
