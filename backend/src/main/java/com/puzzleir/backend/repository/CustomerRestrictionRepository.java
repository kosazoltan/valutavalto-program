package com.puzzleir.backend.repository;

import com.puzzleir.backend.entity.CustomerRestriction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CustomerRestrictionRepository extends JpaRepository<CustomerRestriction, UUID> {

    List<CustomerRestriction> findByCustomerIdAndActiveTrue(Long customerId);

    List<CustomerRestriction> findByCustomerId(Long customerId);
}
