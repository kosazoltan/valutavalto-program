package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.BranchGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BranchGroupRepository extends JpaRepository<BranchGroup, UUID> {
    List<BranchGroup> findByIsActiveTrue();
    List<BranchGroup> findByParentGroupIdIsNull();
}
