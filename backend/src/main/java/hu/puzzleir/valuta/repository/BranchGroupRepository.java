package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.BranchGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface BranchGroupRepository extends JpaRepository<BranchGroup, UUID> {

    List<BranchGroup> findByIsActiveTrue();

    List<BranchGroup> findByParentGroupIdIsNull();

    @Query("SELECT DISTINCT bg FROM BranchGroup bg JOIN bg.branchIds bid WHERE bid IN :branchIds")
    List<BranchGroup> findByAnyBranchIdIn(@Param("branchIds") List<UUID> branchIds);

    @Query("SELECT DISTINCT bg FROM BranchGroup bg JOIN bg.branchIds bid WHERE bid IN :branchIds AND bg.isActive = true")
    List<BranchGroup> findActiveByAnyBranchIdIn(@Param("branchIds") List<UUID> branchIds);

    @Query("SELECT DISTINCT bg FROM BranchGroup bg JOIN bg.branchIds bid WHERE bid IN :branchIds AND bg.parentGroupId IS NULL")
    List<BranchGroup> findRootByAnyBranchIdIn(@Param("branchIds") List<UUID> branchIds);
}
