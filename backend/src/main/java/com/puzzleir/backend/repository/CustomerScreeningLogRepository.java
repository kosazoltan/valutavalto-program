package com.puzzleir.backend.repository;

import com.puzzleir.backend.entity.CustomerScreeningLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CustomerScreeningLogRepository extends JpaRepository<CustomerScreeningLog, UUID> {

    List<CustomerScreeningLog> findByCustomerIdOrderByScreenedAtDesc(Long customerId);
}
