package hu.puzzleir.valuta.repository;

import hu.puzzleir.valuta.entity.License;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface LicenseRepository extends JpaRepository<License, UUID> {

    Optional<License> findByIsActiveTrue();

    Optional<License> findByLicenseKey(String licenseKey);

    Optional<License> findByCompanyIdAndIsActiveTrue(Integer companyId);
}
