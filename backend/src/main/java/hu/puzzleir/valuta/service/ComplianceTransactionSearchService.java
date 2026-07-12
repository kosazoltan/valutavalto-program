package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionRowDto;
import hu.puzzleir.valuta.dto.compliance.ComplianceTransactionSearchCriteria;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.HandlingFeeOverrideType;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.Worker;
import hu.puzzleir.valuta.exception.BusinessException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * FS-11 S1: cégszintű compliance tranzakció-kereső service.
 * A company-scope kizárólag a SecurityContextből származik, requestből nem injektálható.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class ComplianceTransactionSearchService {

    static final int EXPORT_MAX_ROWS = 10_000;
    private static final List<Long> CURRENCY_SENTINEL = List.of(-1L);
    private static final List<String> RELATED_SENTINEL = List.of("-");

    private final TransactionRepository transactionRepository;

    public Page<ComplianceTransactionRowDto> search(ComplianceTransactionSearchCriteria criteria, Pageable pageable) {
        ComplianceTransactionSearchCriteria c = criteria == null ? new ComplianceTransactionSearchCriteria() : criteria;
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        Integer relatedMinCount = c.getRelatedMinCount();
        if (relatedMinCount != null && relatedMinCount <= 0) {
            throw new ValidationException("A minimum összefüggő tranzakciószámnak pozitívnak kell lennie!");
        }
        boolean relatedIdsEmpty = relatedMinCount == null;
        List<String> relatedCustomerIds = RELATED_SENTINEL;
        if (relatedMinCount != null) {
            relatedCustomerIds = transactionRepository.findRelatedCustomerIdsWithMinTransactionCount(
                    companyId, c.getStartDate(), c.getEndDate(), relatedMinCount);
            if (relatedCustomerIds.isEmpty()) {
                return Page.empty(pageable);
            }
        }
        boolean currencyIdsEmpty = c.getCurrencyIds() == null || c.getCurrencyIds().isEmpty();
        Page<Transaction> page = transactionRepository.searchComplianceTransactions(
                companyId, c.getBranchId(), c.getStartDate(), c.getEndDate(), c.getType(),
                c.getMinHufAmount(), c.getMaxHufAmount(), currencyIdsEmpty,
                currencyIdsEmpty ? CURRENCY_SENTINEL : c.getCurrencyIds(), c.getPaymentMethod(),
                c.isCustomRateOnly(), c.isKkDiscountOnly(), c.isOnBehalfOfOtherOnly(), c.isPepOnly(),
                normalize(c.getCustomerName()), c.getCustomerBirthDate(), normalize(c.getCustomerNationality()),
                normalize(c.getCustomerDocumentNumber()), c.isLegalEntityOnly(), normalize(c.getLegalEntityName()),
                normalize(c.getLegalEntityTaxNumber()), normalize(c.getLegalDeedNumber()), normalize(c.getLegalEntitySeat()),
                normalize(c.getBeneficialOwnerName()), normalize(c.getCustomerCountry()),
                normalize(c.getCustomerBirthName()), relatedIdsEmpty, relatedCustomerIds, pageable);
        return page.map(this::toRowDto);
    }

    /**
     * FS-11 S1 export-út: cap-ellenőrzés + teljes találati lista.
     * Fail-closed: csonkolt compliance-export helyett 422 COMPLIANCE_EXPORT_TOO_LARGE.
     */
    public List<ComplianceTransactionRowDto> searchForExport(ComplianceTransactionSearchCriteria criteria) {
        Page<ComplianceTransactionRowDto> page = search(criteria, PageRequest.of(0, EXPORT_MAX_ROWS));
        if (page.getTotalElements() > EXPORT_MAX_ROWS) {
            throw new BusinessException(
                    "Az export túl nagy (" + page.getTotalElements() + " sor, limit " + EXPORT_MAX_ROWS
                            + ") — szűkítsd a szűrőket",
                    "COMPLIANCE_EXPORT_TOO_LARGE");
        }
        return page.getContent();
    }

    private static String normalize(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private ComplianceTransactionRowDto toRowDto(Transaction transaction) {
        Currency currency = transaction.getCurrency();
        Worker worker = transaction.getWorker();
        return ComplianceTransactionRowDto.builder()
                .id(transaction.getId())
                .receiptNumber(transaction.getReceiptNumber())
                .transactionType(transaction.getTransactionType())
                .status(transaction.getStatus())
                .transactionDate(transaction.getTransactionDate())
                .transactionTime(transaction.getTransactionTime())
                .branchId(transaction.getBranch() != null ? transaction.getBranch().getId() : null)
                .branchName(transaction.getBranch() != null ? transaction.getBranch().getName() : null)
                .branchCode(transaction.getBranch() != null ? transaction.getBranch().getCode() : null)
                .currencyId(currency != null ? currency.getId() : null)
                .currencyCode(currency != null ? currency.getCode() : null)
                .currencyAmount(transaction.getCurrencyAmount())
                .exchangeRate(transaction.getExchangeRate())
                .hufAmount(transaction.getHufAmount())
                .paymentMethod(transaction.getPaymentMethod())
                .cashierCustomRate(transaction.getCashierCustomRate())
                .kkDiscount(isKkDiscount(transaction))
                .customerIsPep(transaction.getCustomerIsPep())
                .customerOnOwnBehalf(transaction.getCustomerOnOwnBehalf())
                .amlSuspicious(transaction.getAmlSuspicious())
                .customerId(transaction.getCustomerId())
                .customerName(transaction.getCustomerName())
                .customerBirthDate(transaction.getCustomerBirthDate())
                .customerNationality(transaction.getCustomerNationality())
                .customerDocumentNumber(transaction.getCustomerDocumentNumber())
                .isLegalEntityCustomer(transaction.getIsLegalEntityCustomer())
                .legalEntityName(transaction.getLegalEntityName())
                .legalEntityTaxNumber(transaction.getLegalEntityTaxNumber())
                .workerCode(worker != null ? worker.getCode() : null)
                .workerName(worker != null ? worker.getName() : null)
                .originalReceiptNumber(transaction.getOriginalTransaction() != null
                        ? transaction.getOriginalTransaction().getReceiptNumber()
                        : null)
                .build();
    }

    private static boolean isKkDiscount(Transaction transaction) {
        Integer discountTypeCode = transaction.getDiscountTypeCode();
        HandlingFeeOverrideType overrideType = transaction.getHandlingFeeOverrideType();
        return (discountTypeCode != null && discountTypeCode != 0)
                || (overrideType != null && overrideType != HandlingFeeOverrideType.NONE);
    }
}
