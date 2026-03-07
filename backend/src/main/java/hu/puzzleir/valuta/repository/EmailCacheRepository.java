package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EmailCache;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface EmailCacheRepository extends JpaRepository<EmailCache, UUID> {

    List<EmailCache> findByEmailAccountIdOrderByReceivedAtDesc(UUID emailAccountId);

    Optional<EmailCache> findByEmailAccountIdAndGmailMessageId(UUID emailAccountId, String gmailMessageId);

    void deleteByEmailAccountId(UUID emailAccountId);

    List<EmailCache> findByEmailAccountIdAndLabelIdsContainingOrderByReceivedAtDesc(UUID emailAccountId, String label);

    List<EmailCache> findByEmailAccountIdOrderByReceivedAtDesc(UUID emailAccountId, Pageable pageable);

    void deleteByReceivedAtBefore(LocalDateTime cutoff);
}
