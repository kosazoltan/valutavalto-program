package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.OrganizationalSystemParameter;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OrganizationalSystemParameterRepository extends JpaRepository<OrganizationalSystemParameter, UUID> {

    List<OrganizationalSystemParameter> findByOrganizationIdAndIsActiveTrueOrderByParameterKeyAsc(UUID organizationId);

    List<OrganizationalSystemParameter> findByIsActiveTrueOrderByOrganizationIdAscParameterKeyAsc();
}
