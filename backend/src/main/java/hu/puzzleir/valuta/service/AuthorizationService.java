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
        // Domain validation
        if (authorization.getStartDate() != null && authorization.getExpiryDate() != null
                && authorization.getExpiryDate().isBefore(authorization.getStartDate())) {
            throw new IllegalArgumentException("expiryDate nem lehet korábbi mint startDate");
        }
        if (authorization.getSingleTransactionLimit() != null
                && authorization.getSingleTransactionLimit().signum() < 0) {
            throw new IllegalArgumentException("singleTransactionLimit nem lehet negatív");
        }
        if (authorization.getMaxAmount() != null && authorization.getMaxAmount().signum() < 0) {
            throw new IllegalArgumentException("maxAmount nem lehet negatív");
        }
        if (authorization.getMaxTransactionCount() != null && authorization.getMaxTransactionCount() < 0) {
            throw new IllegalArgumentException("maxTransactionCount nem lehet negatív");
        }
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
     * Újraaktíválás: SUSPENDED → ACTIVE
     */
    public Authorization resume(UUID authorizationId, Long workerId, String notes) {
        Authorization auth = findById(authorizationId);
        if (!"SUSPENDED".equals(auth.getStatusDid())) {
            throw new IllegalStateException("Csak SUSPENDED státuszú jogosultság aktiválható újra. Jelenlegi: " + auth.getStatusDid());
        }
        auth.setStatusDid("ACTIVE");
        auth.setStatusReason(null);
        if (notes != null) {
            auth.setNotes(notes);
        }
        log.info("Jogosultság újraaktíválva: id={}, worker={}", authorizationId, workerId);
        return authorizationRepository.save(auth);
    }

    /**
     * Visszavonás: bármelyik nem-REVOKED → REVOKED (végleges)
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
