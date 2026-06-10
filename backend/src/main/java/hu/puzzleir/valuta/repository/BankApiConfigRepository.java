package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.BankApiConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface BankApiConfigRepository extends JpaRepository<BankApiConfig, UUID> {

    Optional<BankApiConfig> findByProviderName(String providerName);
}
