package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.EmailAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface EmailAccountRepository extends JpaRepository<EmailAccount, UUID> {

    List<EmailAccount> findByBranchId(UUID branchId);

    List<EmailAccount> findByVaultTerritoryId(Integer vaultTerritoryId);

    List<EmailAccount> findByWorkerId(Long workerId);

    List<EmailAccount> findByOwnCompanyId(UUID ownCompanyId);

    List<EmailAccount> findByBranchIdAndIsActiveTrue(UUID branchId);
}
