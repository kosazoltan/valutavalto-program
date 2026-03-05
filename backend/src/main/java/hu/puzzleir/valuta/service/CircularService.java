package hu.puzzleir.valuta.service;

import com.puzzleir.backend.exception.ResourceNotFoundException;
import com.puzzleir.backend.exception.ValidationException;
import hu.puzzleir.valuta.dto.circular.*;
import hu.puzzleir.valuta.entity.*;
import hu.puzzleir.valuta.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Körlevél service — CRUD + acknowledge.
 *
 * Legacy: korlev.dll — központi utasítások a pénztáraknak.
 */
@Service
@RequiredArgsConstructor
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
                .build();
    }
}
