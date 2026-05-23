package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.entity.WuPartnerCompany;
import hu.puzzleir.valuta.service.WuPartnerCompanyService;
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
 * Western Union partner-cég törzs endpoint (legacy: GETWCEG.dll / WUCEGEK).
 */
@RestController
@RequestMapping("/api/v1/wu-partner-companies")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER','SUPERVISOR','MANAGER','ADMIN')")
public class WuPartnerCompanyController {

    private final WuPartnerCompanyService service;

    @GetMapping
    public ResponseEntity<List<Dto>> list(@RequestParam(name = "q", required = false) String q) {
        List<Dto> dtos = service.search(q).stream()
                .map(w -> new Dto(w.getId(), w.getName()))
                .toList();
        return ResponseEntity.ok(dtos);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('SUPERVISOR','MANAGER','ADMIN')")
    public ResponseEntity<Dto> create(@RequestBody CreateRequest request) {
        WuPartnerCompany created = service.create(request.getName());
        return ResponseEntity.ok(new Dto(created.getId(), created.getName()));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('SUPERVISOR','MANAGER','ADMIN')")
    public ResponseEntity<Void> deactivate(@PathVariable UUID id) {
        service.deactivate(id);
        return ResponseEntity.noContent().build();
    }

    @Value
    public static class Dto {
        UUID id;
        String name;
    }

    @Data
    public static class CreateRequest {
        @NotBlank
        private String name;
    }
}
