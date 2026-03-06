package hu.puzzleir.valuta.controller;

import hu.puzzleir.valuta.dto.ratemanagement.RatePublishRequestDto;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.RateDiscountRepository;
import hu.puzzleir.valuta.service.RateTemplateApprovalService;
import hu.puzzleir.valuta.service.RateTemplateService;
import hu.puzzleir.valuta.service.RatePublishService;
import hu.puzzleir.valuta.service.RateWorkgroupService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/rate-management")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
public class RateManagementController {

    private final RateTemplateService templateService;
    private final RateWorkgroupService workgroupService;
    private final RateTemplateApprovalService approvalService;
    private final RatePublishService publishService;
    private final RateDiscountRepository discountRepository;

    // ============ TEMPLATES ============

    @GetMapping("/templates")
    public ResponseEntity<List<RateTemplate>> getTemplates(
            @RequestParam(required = false) UUID workgroupId) {
        if (workgroupId != null) {
            return ResponseEntity.ok(templateService.getTemplatesByWorkgroup(workgroupId));
        }
        return ResponseEntity.ok(templateService.getTemplatesByStatus(RateTemplate.RateTemplateStatus.DRAFT));
    }

    @GetMapping("/templates/{id}")
    public ResponseEntity<RateTemplate> getTemplate(@PathVariable UUID id) {
        return ResponseEntity.ok(templateService.getTemplate(id));
    }

    @PostMapping("/templates")
    public ResponseEntity<RateTemplate> createTemplate(@Valid @RequestBody RateTemplate template) {
        return ResponseEntity.status(HttpStatus.CREATED).body(templateService.createTemplate(template));
    }

    @PutMapping("/templates/{id}")
    public ResponseEntity<RateTemplate> updateTemplate(
            @PathVariable UUID id, @Valid @RequestBody RateTemplate template) {
        return ResponseEntity.ok(templateService.updateTemplate(id, template));
    }

    @DeleteMapping("/templates/{id}")
    public ResponseEntity<Void> deleteTemplate(@PathVariable UUID id) {
        templateService.deleteTemplate(id);
        return ResponseEntity.noContent().build();
    }

    // ============ WORKFLOW ============

    @PostMapping("/templates/{id}/approve")
    public ResponseEntity<RateTemplate> approveTemplate(@PathVariable UUID id) {
        return ResponseEntity.ok(approvalService.approve(id));
    }

    @PostMapping("/templates/{id}/publish")
    public ResponseEntity<RatePublication> publishTemplate(@PathVariable UUID id) {
        return ResponseEntity.ok(publishService.publish(
                templateService.getTemplate(id).getWorkgroupId(),
                List.of(id), null));
    }

    @PostMapping("/templates/{id}/revoke")
    public ResponseEntity<RateTemplate> revokeTemplate(@PathVariable UUID id) {
        return ResponseEntity.ok(approvalService.revoke(id));
    }

    @PostMapping("/publish")
    public ResponseEntity<RatePublication> publishBatch(@RequestBody RatePublishRequestDto dto) {
        return ResponseEntity.ok(publishService.publish(dto.getWorkgroupId(), dto.getTemplateIds(), dto.getNotes()));
    }

    // ============ WORKGROUPS ============

    @GetMapping("/workgroups")
    public ResponseEntity<List<RateWorkgroup>> getWorkgroups() {
        return ResponseEntity.ok(workgroupService.getAll());
    }

    @PostMapping("/workgroups")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RateWorkgroup> createWorkgroup(@Valid @RequestBody RateWorkgroup workgroup) {
        return ResponseEntity.status(HttpStatus.CREATED).body(workgroupService.create(workgroup));
    }

    @PutMapping("/workgroups/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RateWorkgroup> updateWorkgroup(
            @PathVariable UUID id, @Valid @RequestBody RateWorkgroup workgroup) {
        return ResponseEntity.ok(workgroupService.update(id, workgroup));
    }

    // ============ DISCOUNTS ============

    @GetMapping("/discounts/{workgroupId}")
    public ResponseEntity<List<RateDiscount>> getDiscounts(@PathVariable UUID workgroupId) {
        return ResponseEntity.ok(discountRepository.findByWorkgroupIdOrderByLevel(workgroupId));
    }

    @PostMapping("/discounts")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RateDiscount> createDiscount(@Valid @RequestBody RateDiscount discount) {
        return ResponseEntity.status(HttpStatus.CREATED).body(discountRepository.save(discount));
    }

    @PutMapping("/discounts/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RateDiscount> updateDiscount(
            @PathVariable UUID id, @Valid @RequestBody RateDiscount discount) {
        discount.setId(id);
        return ResponseEntity.ok(discountRepository.save(discount));
    }

    // ============ PUBLICATIONS ============

    @GetMapping("/publications")
    public ResponseEntity<List<RatePublication>> getPublications(
            @RequestParam(required = false) UUID workgroupId) {
        return ResponseEntity.ok(publishService.getPublicationHistory(workgroupId));
    }
}
