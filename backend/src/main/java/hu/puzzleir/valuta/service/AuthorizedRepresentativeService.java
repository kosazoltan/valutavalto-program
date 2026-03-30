package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.AuthorizationLog;
import hu.puzzleir.valuta.entity.AuthorizedRepresentative;
import hu.puzzleir.valuta.repository.AuthorizationLogRepository;
import hu.puzzleir.valuta.repository.AuthorizedRepresentativeRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Meghatalmazott képviselő szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Transactional
@Slf4j
public class AuthorizedRepresentativeService {

    private final AuthorizedRepresentativeRepository representativeRepository;
    private final AuthorizationLogRepository authorizationLogRepository;

    @Transactional(readOnly = true)
    public List<AuthorizedRepresentative> findAll(Long customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (customerId != null) {
            return representativeRepository.findByCompanyIdAndCustomerId(companyId, customerId);
        }
        return representativeRepository.findAllByCompanyId(companyId);
    }

    @Transactional(readOnly = true)
    public AuthorizedRepresentative findById(UUID id) {
        return representativeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Meghatalmazott nem található: " + id));
    }

    public AuthorizedRepresentative create(AuthorizedRepresentative representative) {
        representative.setCompanyId(SecurityUtils.getCurrentCompanyId());
        log.info("Új meghatalmazott létrehozása: {} (ügyfél: {})",
                representative.getRepresentativeName(), representative.getCustomerId());
        return representativeRepository.save(representative);
    }

    public AuthorizedRepresentative update(UUID id, AuthorizedRepresentative updated) {
        AuthorizedRepresentative existing = findById(id);
        // Alap mezők
        existing.setRepresentativeName(updated.getRepresentativeName());
        existing.setRepresentativeDocumentNumber(updated.getRepresentativeDocumentNumber());
        existing.setRepresentativeDocumentType(updated.getRepresentativeDocumentType());
        existing.setAuthorizationStart(updated.getAuthorizationStart());
        existing.setAuthorizationEnd(updated.getAuthorizationEnd());
        existing.setIsActive(updated.getIsActive());
        // V2 mezők
        existing.setFirstName(updated.getFirstName());
        existing.setLastName(updated.getLastName());
        existing.setBirthDate(updated.getBirthDate());
        existing.setBirthPlace(updated.getBirthPlace());
        existing.setNationalityDid(updated.getNationalityDid());
        existing.setAddress(updated.getAddress());
        existing.setPhone(updated.getPhone());
        existing.setEmail(updated.getEmail());
        existing.setDocumentTypeDid(updated.getDocumentTypeDid());
        existing.setDocumentValidFrom(updated.getDocumentValidFrom());
        existing.setDocumentValidTo(updated.getDocumentValidTo());
        existing.setRepresentativeTypeDid(updated.getRepresentativeTypeDid());
        existing.setRelationshipDid(updated.getRelationshipDid());
        log.info("Meghatalmazott frissítve: {}", id);
        return representativeRepository.save(existing);
    }

    public void delete(UUID id) {
        AuthorizedRepresentative existing = findById(id);
        log.info("Meghatalmazott törölve: {}", id);
        representativeRepository.delete(existing);
    }

    /**
     * Tranzakció naplózása meghatalmazotthoz.
     */
    public AuthorizationLog recordTransaction(UUID representativeId, Long transactionId, String action) {
        // Ellenőrizzük, hogy létezik-e a meghatalmazott
        findById(representativeId);

        AuthorizationLog logEntry = AuthorizationLog.builder()
                .representativeId(representativeId)
                .transactionId(transactionId)
                .action(action)
                .performedAt(LocalDateTime.now())
                .performedByWorkerId(SecurityUtils.getCurrentWorkerId())
                .build();

        log.info("Meghatalmazás napló: representative={}, action={}, transaction={}",
                representativeId, action, transactionId);
        return authorizationLogRepository.save(logEntry);
    }
}
