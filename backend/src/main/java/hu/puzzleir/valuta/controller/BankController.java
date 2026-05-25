package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.Bank;
import hu.puzzleir.valuta.service.BankService;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/**
 * Bank-törzs endpoint (FK-005/C1) — a banki átadás-átvétel cél/forrás bankjai.
 *
 * <p>A lista TERÜLETI szűrésű (értéktárosnál a saját régió + cég-szintű bankok). Az
 * értéktáros (ERTEKTAR/FOERTEKTAR) is olvashatja; a felvétel/deaktiválás vezetői/admin jog.</p>
 */
@RestController
@RequestMapping("/api/v1/banks")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER','SUPERVISOR','MANAGER','ADMIN','FOERTEKTAR','UGYVEZETO','ERTEKTAR')")
public class BankController {

    private final BankService service;

    @GetMapping
    public ResponseEntity<List<Dto>> list(@RequestParam(name = "q", required = false) String q) {
        List<Dto> dtos = service.search(q).stream()
                .map(b -> new Dto(b.getId(), b.getName(), b.getRegionCode()))
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','FOERTEKTAR','UGYVEZETO')")
    public ResponseEntity<Dto> create(@RequestBody CreateRequest request) {
        Bank created = service.create(request.getName(), request.getRegionCode());
        return ResponseEntity.ok(new Dto(created.getId(), created.getName(), created.getRegionCode()));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('MANAGER','ADMIN','FOERTEKTAR','UGYVEZETO')")
    public ResponseEntity<Void> deactivate(@PathVariable UUID id) {
        service.deactivate(id);
        return ResponseEntity.noContent().build();
    }

    @Value
    public static class Dto {
        UUID id;
        String name;
        String regionCode;
    }

    @Data
    public static class CreateRequest {
        @NotBlank
        private String name;
        /** Opcionális területi kötés; üres = cég-szintű (minden területen választható). */
        private String regionCode;
    }
}
