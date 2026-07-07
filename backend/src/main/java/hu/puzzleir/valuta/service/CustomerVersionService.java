package hu.puzzleir.valuta.service;

import tools.jackson.databind.ObjectMapper;
import hu.puzzleir.valuta.dto.customer.CustomerDto;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.CustomerVersion;
import hu.puzzleir.valuta.entity.DataChangeSource;
import hu.puzzleir.valuta.mapper.CustomerMapper;
import hu.puzzleir.valuta.repository.CustomerVersionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * FS-3 (D1): ügyfél-törzsadat verziózás — teljes CustomerDto-snapshot jsonb-ben.
 * A verzió-sorok immutabilisek; a szerializációs hiba tranzakció-rollback
 * (fail-closed: verzió nélkül nincs törzsadat-módosítás).
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CustomerVersionService {

    private final CustomerVersionRepository customerVersionRepository;
    private final CustomerMapper customerMapper;
    private final ObjectMapper objectMapper;

    public DataChangeSource currentChangeSource() {
        return SecurityUtils.isComplianceSide()
                ? DataChangeSource.COMPLIANCE : DataChangeSource.CASHIER;
    }

    /** Változott-e a törzsadat az utolsó verzióhoz képest (normalizált összevetés). */
    @Transactional(readOnly = true)
    public boolean hasDataChanged(Customer customer) {
        Optional<CustomerVersion> latest =
                customerVersionRepository.findTopByCustomerIdOrderByVersionNoDesc(customer.getId());
        if (latest.isEmpty()) {
            return true; // legacy/első érintés → baseline verzió jár neki
        }
        String current = normalizedSnapshot(customerMapper.toDto(customer));
        CustomerDto previous = objectMapper.readValue(latest.get().getSnapshot(), CustomerDto.class);
        return !normalizedSnapshot(previous).equals(current);
    }

    @Transactional(rollbackFor = Exception.class)
    public CustomerVersion recordVersion(Customer customer, DataChangeSource source) {
        long nextNo = customerVersionRepository
                .findTopByCustomerIdOrderByVersionNoDesc(customer.getId())
                .map(v -> v.getVersionNo() + 1)
                .orElse(1L);
        CustomerVersion version = CustomerVersion.builder()
                .customerId(customer.getId())
                .companyId(customer.getCompany().getId())
                .versionNo(nextNo)
                .snapshot(objectMapper.writeValueAsString(customerMapper.toDto(customer)))
                .changeSource(source)
                .changedBy(SecurityUtils.getCurrentWorkerCode())
                .changedAt(LocalDateTime.now())
                .build();
        CustomerVersion saved = customerVersionRepository.save(version);
        log.info("[CUSTOMER-VERSION] Ügyfél #{} v{} rögzítve ({})",
                customer.getId(), nextNo, source);
        return saved;
    }

    @Transactional(readOnly = true)
    public List<CustomerVersion> listVersions(Long customerId, UUID companyId) {
        return customerVersionRepository
                .findByCustomerIdAndCompanyIdOrderByVersionNoDesc(customerId, companyId);
    }

    @Transactional(readOnly = true)
    public Optional<CustomerVersion> getVersion(Long customerId, Long versionNo, UUID companyId) {
        return customerVersionRepository
                .findByCustomerIdAndVersionNoAndCompanyId(customerId, versionNo, companyId);
    }

    /**
     * Volatilis/workflow mezők nullázása az összevetéshez (contract):
     * updatedAt (@LastModifiedDate flush-bump), createdAt, lastTransactionDate,
     * transactionCount (aggregátumok), eddActive (órafüggő számított),
     * reviewStatus/reviewedBy/reviewedAt (a review önmagában nem adatváltozás).
     */
    private String normalizedSnapshot(CustomerDto dto) {
        dto.setUpdatedAt(null);
        dto.setCreatedAt(null);
        dto.setLastTransactionDate(null);
        dto.setTransactionCount(null);
        dto.setEddActive(null);
        dto.setReviewStatus(null);
        dto.setReviewedBy(null);
        dto.setReviewedAt(null);
        return objectMapper.writeValueAsString(dto);
    }
}
