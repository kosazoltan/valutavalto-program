package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.dto.circular.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Körlevél service — CRUD + acknowledge.
 *
 * Legacy: korlev.dll — központi utasítások a pénztáraknak.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CircularService {

    private final CircularRepository circularRepository;
    private final WorkerRepository workerRepository;

    /**
     * Összes körlevél listázása.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findAll() {
        return circularRepository.findAllOrderByCreatedAtDesc().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Egy körlevél lekérdezése.
     */
    @Transactional(readOnly = true)
    public CircularDto findById(Long id) {
        return toDto(findOrThrow(id));
    }

    /**
     * Körlevél létrehozása.
     */
    @Transactional
    public CircularDto create(CreateCircularDto dto, Long workerId) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        Circular circular = Circular.builder()
                .title(dto.getTitle())
                .content(dto.getContent())
                .createdBy(worker)
                .urgent(dto.getUrgent() != null ? dto.getUrgent() : false)
                .build();

        circular = circularRepository.save(circular);
        return toDto(circular);
    }

    /**
     * Körlevél tudomásul vétele.
     */
    @Transactional
    public CircularDto acknowledge(Long circularId) {
        Circular circular = findOrThrow(circularId);

        if (Boolean.TRUE.equals(circular.getAcknowledged())) {
            throw new ValidationException("A körlevél már tudomásul lett véve!");
        }

        circular.setAcknowledged(true);
        circular.setAcknowledgedAt(LocalDateTime.now());
        circular = circularRepository.save(circular);
        return toDto(circular);
    }

    /**
     * Még nem nyugtázott körlevelek.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findUnacknowledged() {
        return circularRepository.findUnacknowledged().stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Típus szerinti szűrés.
     * Legacy: KORLEV mappák szerinti szétválasztás
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findByType(CircularType type) {
        return circularRepository.findByType(type).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Irodához releváns körlevelek — szűri a célcsoportot.
     * Legacy: KorlevelOlvasas — a pénztáros bejelentkezéskor
     * kapta meg a rá vonatkozó körleveleket.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> findRelevantForCurrentBranch() {
        UUID branchId = SecurityUtils.getCurrentBranchId();
        // companyId-t a branch-ból lehetne de egyszerűsítve null-t küldünk
        return circularRepository.findRelevantForBranch(branchId, null).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Körlevél létrehozása típussal és célcsoporttal.
     *
     * Legacy: A szerver oldalon (KORLEV\SERVER\Unit1.pas) az értéktáras
     * készítette a körleveleket ODT/DOCX formátumban és FTP-n terjesztette.
     * Az új rendszerben REST API-n keresztül történik.
     */
    @Transactional
    public CircularDto createTyped(CreateCircularDto dto, Long workerId,
                                    CircularType type,
                                    CircularType.CircularTarget target,
                                    CircularType.CircularPriority priority,
                                    UUID targetBranchId,
                                    Integer targetCompanyId,
                                    String registrationNumber) {
        Worker worker = workerRepository.findById(workerId)
                .orElseThrow(() -> new ResourceNotFoundException("Dolgozó nem található: " + workerId));

        Circular circular = Circular.builder()
                .title(dto.getTitle())
                .content(dto.getContent())
                .createdBy(worker)
                .circularType(type)
                .target(target != null ? target : type.getDefaultTarget())
                .priority(priority != null ? priority : type.getDefaultPriority())
                .urgent(priority == CircularType.CircularPriority.URGENT
                        || (dto.getUrgent() != null && dto.getUrgent()))
                .targetBranchId(targetBranchId)
                .targetCompanyId(targetCompanyId)
                .registrationNumber(registrationNumber)
                .validFrom(LocalDate.now())
                .build();

        circular = circularRepository.save(circular);
        log.info("Körlevél létrehozva: id={}, type={}, target={}, priority={}, title={}",
                circular.getId(), type, target, priority, dto.getTitle());

        return toDto(circular);
    }

    /**
     * Iktatószám keresés.
     */
    @Transactional(readOnly = true)
    public List<CircularDto> searchByRegistrationNumber(String query) {
        return circularRepository.findByRegistrationNumberContainingIgnoreCase(query).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * Összes elérhető körlevél típus listázása.
     */
    public List<Map<String, Object>> listTypes() {
        return Arrays.stream(CircularType.values())
                .map(t -> {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("type", t.name());
                    m.put("description", t.getDescription());
                    m.put("defaultTarget", t.getDefaultTarget().name());
                    m.put("defaultPriority", t.getDefaultPriority().name());
                    return m;
                })
                .collect(Collectors.toList());
    }

    // ============ HELPERS ============

    private Circular findOrThrow(Long id) {
        return circularRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Körlevél nem található: " + id));
    }

    private CircularDto toDto(Circular c) {
        return CircularDto.builder()
                .id(c.getId())
                .title(c.getTitle())
                .content(c.getContent())
                .createdById(c.getCreatedBy().getId())
                .createdByName(c.getCreatedBy().getName())
                .urgent(c.getUrgent())
                .acknowledged(c.getAcknowledged())
                .acknowledgedAt(c.getAcknowledgedAt() != null ? c.getAcknowledgedAt().toString() : null)
                .createdAt(c.getCreatedAt() != null ? c.getCreatedAt().toString() : null)
                // Sprint 3 — típus rendszer
                .circularType(c.getCircularType() != null ? c.getCircularType().name() : null)
                .circularTypeDescription(c.getCircularType() != null ? c.getCircularType().getDescription() : null)
                .target(c.getTarget() != null ? c.getTarget().name() : null)
                .priority(c.getPriority() != null ? c.getPriority().name() : null)
                .registrationNumber(c.getRegistrationNumber())
                .attachmentFilename(c.getAttachmentFilename())
                .validFrom(c.getValidFrom() != null ? c.getValidFrom().toString() : null)
                .validTo(c.getValidTo() != null ? c.getValidTo().toString() : null)
                .build();
    }
}
