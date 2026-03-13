package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.dto.receipt.*;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionLine;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import jakarta.persistence.criteria.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Bizonylat kereső — keresés és részletek.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class ReceiptSearchService {

    private final TransactionRepository transactionRepository;
    private final EntityManager entityManager;

    /**
     * Bizonylat keresés több kritérium alapján.
     */
    @Transactional(readOnly = true)
    public Page<ReceiptSearchResultDto> search(ReceiptSearchCriteria criteria, Pageable pageable) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        CriteriaBuilder cb = entityManager.getCriteriaBuilder();
        CriteriaQuery<Transaction> cq = cb.createQuery(Transaction.class);
        Root<Transaction> root = cq.from(Transaction.class);
        root.fetch("worker", JoinType.LEFT);
        root.fetch("currency", JoinType.LEFT);

        List<Predicate> predicates = buildPredicates(cb, root, criteria, companyId);
        cq.where(predicates.toArray(new Predicate[0]));
        cq.orderBy(cb.desc(root.get("transactionDate")), cb.desc(root.get("transactionTime")));

        // Count query
        CriteriaQuery<Long> countQuery = cb.createQuery(Long.class);
        Root<Transaction> countRoot = countQuery.from(Transaction.class);
        List<Predicate> countPredicates = buildPredicates(cb, countRoot, criteria, companyId);
        countQuery.select(cb.count(countRoot));
        countQuery.where(countPredicates.toArray(new Predicate[0]));
        Long total = entityManager.createQuery(countQuery).getSingleResult();

        // Paged result
        TypedQuery<Transaction> typedQuery = entityManager.createQuery(cq);
        typedQuery.setFirstResult((int) pageable.getOffset());
        typedQuery.setMaxResults(pageable.getPageSize());

        List<ReceiptSearchResultDto> results = typedQuery.getResultList().stream()
                .map(this::toSearchResult)
                .collect(Collectors.toList());

        return new PageImpl<>(results, pageable, total);
    }

    /**
     * Bizonylat részletek (fejléc + tételsorok).
     */
    @Transactional(readOnly = true)
    public ReceiptDetailDto getDetail(Long transactionId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Tranzakció nem található: " + transactionId));

        if (!tx.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Tranzakció nem található: " + transactionId);
        }

        List<ReceiptLineDto> lines = tx.getLines().stream()
                .map(line -> ReceiptLineDto.builder()
                        .lineNumber(line.getLineNumber())
                        .currencyCode(line.getCurrency() != null ? line.getCurrency().getCode() : "")
                        .appliedRate(line.getAppliedRate())
                        .banknoteCount(line.getBanknoteCount())
                        .hufValue(line.getHufValue())
                        .lineDiscount(line.getLineDiscount())
                        .build())
                .collect(Collectors.toList());

        return ReceiptDetailDto.builder()
                .id(tx.getId())
                .receiptNumber(tx.getReceiptNumber())
                .transactionDate(tx.getTransactionDate())
                .transactionTime(tx.getTransactionTime())
                .transactionType(tx.getTransactionType().name())
                .transactionTypeDisplay(tx.getTransactionType().getDisplayName())
                .status(tx.getStatus().name())
                .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : "")
                .currencyAmount(tx.getCurrencyAmount())
                .hufAmount(tx.getHufAmount())
                .exchangeRate(tx.getExchangeRate())
                .handlingFee(tx.getHandlingFee())
                .customerName(tx.getCustomerName())
                .customerAddress(tx.getCustomerAddress())
                .customerDocumentNumber(tx.getCustomerDocumentNumber())
                .cashierName(tx.getWorker() != null ? tx.getWorker().getName() : "")
                .branchCode(tx.getBranch() != null ? tx.getBranch().getCode() : "")
                .lines(lines)
                .build();
    }

    private List<Predicate> buildPredicates(CriteriaBuilder cb, Root<Transaction> root,
                                            ReceiptSearchCriteria criteria, UUID companyId) {
        List<Predicate> predicates = new ArrayList<>();

        // Multi-tenant!
        predicates.add(cb.equal(root.get("company").get("id"), companyId));

        if (criteria.getNumber() != null && !criteria.getNumber().isBlank()) {
            predicates.add(cb.like(
                    cb.lower(root.get("receiptNumber")),
                    "%" + criteria.getNumber().toLowerCase() + "%"));
        }

        if (criteria.getDateFrom() != null) {
            predicates.add(cb.greaterThanOrEqualTo(root.get("transactionDate"), criteria.getDateFrom()));
        }
        if (criteria.getDateTo() != null) {
            predicates.add(cb.lessThanOrEqualTo(root.get("transactionDate"), criteria.getDateTo()));
        }

        if (criteria.getType() != null && !criteria.getType().isBlank()) {
            predicates.add(cb.equal(root.get("transactionType").as(String.class), criteria.getType()));
        }

        if (criteria.getMinAmount() != null) {
            predicates.add(cb.greaterThanOrEqualTo(root.get("hufAmount"), criteria.getMinAmount()));
        }
        if (criteria.getMaxAmount() != null) {
            predicates.add(cb.lessThanOrEqualTo(root.get("hufAmount"), criteria.getMaxAmount()));
        }

        if (criteria.getCustomer() != null && !criteria.getCustomer().isBlank()) {
            predicates.add(cb.like(
                    cb.lower(root.get("customerName")),
                    "%" + criteria.getCustomer().toLowerCase() + "%"));
        }

        return predicates;
    }

    private ReceiptSearchResultDto toSearchResult(Transaction tx) {
        return ReceiptSearchResultDto.builder()
                .id(tx.getId())
                .receiptNumber(tx.getReceiptNumber())
                .transactionDate(tx.getTransactionDate())
                .transactionTime(tx.getTransactionTime())
                .transactionType(tx.getTransactionType().name())
                .transactionTypeDisplay(tx.getTransactionType().getDisplayName())
                .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : "")
                .currencyAmount(tx.getCurrencyAmount())
                .hufAmount(tx.getHufAmount())
                .exchangeRate(tx.getExchangeRate())
                .customerName(tx.getCustomerName())
                .cashierName(tx.getWorker() != null ? tx.getWorker().getName() : "")
                .status(tx.getStatus().name())
                .build();
    }
}
