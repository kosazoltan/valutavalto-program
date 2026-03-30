package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.representative.CreateRepresentativeDto;
import hu.puzzleir.valuta.dto.representative.RepresentativeDto;
import hu.puzzleir.valuta.entity.AuthorizationLog;
import hu.puzzleir.valuta.entity.AuthorizedRepresentative;
import hu.puzzleir.valuta.service.AuthorizedRepresentativeService;
import hu.puzzleir.valuta.service.CustomerService;
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
 * Meghatalmazott képviselő controller.
 * Frontend-kompatibilis DTO-s API.
 */
@RestController
@RequestMapping("/api/v1/authorized-representatives")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('CASHIER', 'SUPERVISOR', 'MANAGER', 'ADMIN')")
public class AuthorizedRepresentativeController {

    private final AuthorizedRepresentativeService service;
    private final CustomerService customerService;

    /**
     * Meghatalmazottak listázása ügyfél szerint.
     * GET /api/v1/authorized-representatives/customer/{customerId}
     */
    @GetMapping("/customer/{customerId}")
    public ResponseEntity<List<RepresentativeDto>> findByCustomer(@PathVariable Long customerId) {
        List<AuthorizedRepresentative> reps = service.findAll(customerId);
        String customerName = getCustomerName(customerId);
        return ResponseEntity.ok(reps.stream().map(r -> toDto(r, customerName)).collect(Collectors.toList()));
    }

    /**
     * Meghatalmazottak listázása (összes, vagy customerId szűréssel).
     * GET /api/v1/authorized-representatives?customerId=123
     */
    @GetMapping
    public ResponseEntity<List<RepresentativeDto>> findAll(
            @RequestParam(required = false) Long customerId) {
        List<AuthorizedRepresentative> reps = service.findAll(customerId);
        return ResponseEntity.ok(reps.stream().map(r -> toDto(r, null)).collect(Collectors.toList()));
    }

    /**
     * Meghatalmazott lekérése ID alapján.
     * GET /api/v1/authorized-representatives/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<RepresentativeDto> findById(@PathVariable UUID id) {
        AuthorizedRepresentative rep = service.findById(id);
        String customerName = getCustomerName(rep.getCustomerId());
        return ResponseEntity.ok(toDto(rep, customerName));
    }

    /**
     * Új meghatalmazott regisztrációja ügyfélhez.
     * POST /api/v1/authorized-representatives/customer/{customerId}/register
     */
    @PostMapping("/customer/{customerId}/register")
    public ResponseEntity<RepresentativeDto> register(
            @PathVariable Long customerId,
            @Valid @RequestBody CreateRepresentativeDto dto,
            @RequestParam(required = false) String workerId) {
        AuthorizedRepresentative entity = toEntity(dto, customerId);
        AuthorizedRepresentative saved = service.create(entity);
        String customerName = getCustomerName(customerId);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved, customerName));
    }

    /**
     * Meghatalmazott létrehozása (legacy route).
     * POST /api/v1/authorized-representatives
     */
    @PostMapping
    public ResponseEntity<RepresentativeDto> create(
            @Valid @RequestBody CreateRepresentativeDto dto,
            @RequestParam Long customerId) {
        AuthorizedRepresentative entity = toEntity(dto, customerId);
        AuthorizedRepresentative saved = service.create(entity);
        return ResponseEntity.status(HttpStatus.CREATED).body(toDto(saved, null));
    }

    /**
     * Meghatalmazott frissítése.
     * PUT /api/v1/authorized-representatives/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<RepresentativeDto> update(
            @PathVariable UUID id,
            @Valid @RequestBody CreateRepresentativeDto dto) {
        AuthorizedRepresentative existing = service.findById(id);
        updateEntity(existing, dto);
        AuthorizedRepresentative saved = service.update(id, existing);
        return ResponseEntity.ok(toDto(saved, null));
    }

    /**
     * Meghatalmazott törlése.
     * DELETE /api/v1/authorized-representatives/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    /**
     * Tranzakció naplózása meghatalmazotthoz.
     * POST /api/v1/authorized-representatives/record-transaction
     */
    @PostMapping("/record-transaction")
    public ResponseEntity<AuthorizationLog> recordTransaction(
            @RequestParam UUID representativeId,
            @RequestParam(required = false) Long transactionId,
            @RequestParam String action) {
        return ResponseEntity.ok(service.recordTransaction(representativeId, transactionId, action));
    }

    // --- Mapping helpers ---

    private RepresentativeDto toDto(AuthorizedRepresentative entity, String customerName) {
        return RepresentativeDto.builder()
                .id(entity.getId())
                .customerId(entity.getCustomerId())
                .customerName(customerName)
                .firstName(entity.getFirstName())
                .lastName(entity.getLastName())
                .fullName(entity.getFullName())
                .birthDate(entity.getBirthDate())
                .birthPlace(entity.getBirthPlace())
                .nationalityDid(entity.getNationalityDid())
                .documentTypeDid(entity.getDocumentTypeDid() != null ? entity.getDocumentTypeDid() : entity.getRepresentativeDocumentType())
                .documentNumber(entity.getRepresentativeDocumentNumber())
                .documentValidFrom(entity.getDocumentValidFrom())
                .documentValidTo(entity.getDocumentValidTo())
                .address(entity.getAddress())
                .phone(entity.getPhone())
                .email(entity.getEmail())
                .representativeTypeDid(entity.getRepresentativeTypeDid())
                .relationshipDid(entity.getRelationshipDid())
                .isActive(entity.getIsActive())
                .registeredAt(entity.getCreatedAt())
                .build();
    }

    private AuthorizedRepresentative toEntity(CreateRepresentativeDto dto, Long customerId) {
        return AuthorizedRepresentative.builder()
                .customerId(customerId)
                .representativeName(dto.getName())
                .firstName(dto.getFirstName())
                .lastName(dto.getLastName())
                .birthDate(dto.getBirthDate())
                .birthPlace(dto.getBirthPlace())
                .nationalityDid(dto.getNationalityDid())
                .representativeDocumentNumber(dto.getDocumentNumber())
                .representativeDocumentType(dto.getDocumentType())
                .documentTypeDid(dto.getDocumentTypeDid())
                .documentValidFrom(dto.getDocumentValidFrom())
                .documentValidTo(dto.getDocumentValidTo())
                .address(dto.getAddress())
                .phone(dto.getPhone())
                .email(dto.getEmail())
                .representativeTypeDid(dto.getRepresentativeTypeDid())
                .relationshipDid(dto.getRelationshipDid())
                .authorizationStart(dto.getAuthorizationStart())
                .authorizationEnd(dto.getAuthorizationEnd())
                .isActive(true)
                .build();
    }

    private void updateEntity(AuthorizedRepresentative entity, CreateRepresentativeDto dto) {
        entity.setRepresentativeName(dto.getName());
        entity.setFirstName(dto.getFirstName());
        entity.setLastName(dto.getLastName());
        entity.setBirthDate(dto.getBirthDate());
        entity.setBirthPlace(dto.getBirthPlace());
        entity.setNationalityDid(dto.getNationalityDid());
        entity.setRepresentativeDocumentNumber(dto.getDocumentNumber());
        entity.setRepresentativeDocumentType(dto.getDocumentType());
        entity.setDocumentTypeDid(dto.getDocumentTypeDid());
        entity.setDocumentValidFrom(dto.getDocumentValidFrom());
        entity.setDocumentValidTo(dto.getDocumentValidTo());
        entity.setAddress(dto.getAddress());
        entity.setPhone(dto.getPhone());
        entity.setEmail(dto.getEmail());
        entity.setRepresentativeTypeDid(dto.getRepresentativeTypeDid());
        entity.setRelationshipDid(dto.getRelationshipDid());
        entity.setAuthorizationStart(dto.getAuthorizationStart());
        entity.setAuthorizationEnd(dto.getAuthorizationEnd());
    }

    private String getCustomerName(Long customerId) {
        if (customerId == null) return null;
        try {
            return customerService.findById(customerId).getName();
        } catch (Exception e) {
            return null;
        }
    }
}
