package hu.puzzleir.valuta.errorlog;

import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface ErrorLogRepository extends JpaRepository<ErrorLog, String> {
    Optional<ErrorLog> findByFingerprint(String fingerprint);
}
