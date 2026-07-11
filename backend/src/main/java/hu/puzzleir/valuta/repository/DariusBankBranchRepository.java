package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.DariusBankBranch;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DariusBankBranchRepository extends JpaRepository<DariusBankBranch, UUID> {

    List<DariusBankBranch> findByCompanyIdOrderByBankBranchCodeAsc(UUID companyId);

    List<DariusBankBranch> findByCompanyIdAndIsActiveTrueOrderByBankBranchCodeAsc(UUID companyId);

    Optional<DariusBankBranch> findByIdAndCompanyId(UUID id, UUID companyId);

    List<DariusBankBranch> findByCompanyIdAndIdIn(UUID companyId, Collection<UUID> ids);

    boolean existsByCompanyIdAndBankBranchCode(UUID companyId, String bankBranchCode);
}
