package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Authorization;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.AuthorizationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Authorization service — meghatalmazás jogosultságok lifecycle kezelése.
 * PENDING → ACTIVE → (SUSPENDED ↔ ACTIVE) → REVOKED
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class AuthorizationService {

    private final AuthorizationRepository authorizationRepository;

    @Transactional(readOnly = true)
    public List<Authorization> findByRepresentativeId(UUID representativeId) {
        return authorizationRepository.findByRepresentativeId(representativeId);
    }

    @Transactional(readOnly = true)
    public Authorization findById(UUID id) {
        return authorizationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Jogosultság nem található: " + id));
    }

    public Authorization create(Authorization authorization) {
        log.info("Új jogosultság létrehozása: representative={}, operation={}",
                authorization.getRepresentativeId(), authorization.getOperationDid());
        return authorizationRepository.save(authorization);
    }

    /**
     * Jóváhagyás: PENDING → ACTIVE
     */
    public Authorization verify(UUID authorizationId, Long workerId, String notes) {
        Authorization auth = findById(authorizationId);
        if (!"PENDING".equals(auth.getStatusDid())) {
            throw new IllegalStateException("Csak PENDING státuszú jogosultság hagyható jóvá. Jelenlegi: " + auth.getStatusDid());
        }
        auth.setStatusDid("ACTIVE");
        auth.setVerifiedByWorkerId(workerId);
        auth.setVerifiedAt(LocalDateTime.now());
        if (notes != null) {
            auth.setNotes(notes);
        }
        log.info("Jogosultság jóváhagyva: id={}, worker={}", authorizationId, workerId);
        return authorizationRepository.save(auth);
    }

    /**
     * Felfüggesztés: ACTIVE → SUSPENDED
     */
    public Authorization suspend(UUID authorizationId, Long workerId, String reason) {
        Authorization auth = findById(authorizationId);
        if (!"ACTIVE".equals(auth.getStatusDid())) {
            throw new IllegalStateException("Csak ACTIVE státuszú jogosultság függeszthető fel. Jelenlegi: " + auth.getStatusDid());
        }
        auth.setStatusDid("SUSPENDED");
        auth.setStatusReason(reason);
        log.info("Jogosultság felfüggesztve: id={}, reason={}", authorizationId, reason);
        return authorizationRepository.save(auth);
    }

    /**
     * Visszavonás: bármelyik → REVOKED (végleges)
     */
    public Authorization revoke(UUID authorizationId, Long workerId, String reason) {
        Authorization auth = findById(authorizationId);
        if ("REVOKED".equals(auth.getStatusDid())) {
            throw new IllegalStateException("Jogosultság már visszavonva.");
        }
        auth.setStatusDid("REVOKED");
        auth.setStatusReason(reason);
        log.info("Jogosultság visszavonva: id={}, reason={}", authorizationId, reason);
        return authorizationRepository.save(auth);
    }
}
