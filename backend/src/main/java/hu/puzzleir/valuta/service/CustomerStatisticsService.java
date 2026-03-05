package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.customer.CustomerRankingDto;
import hu.puzzleir.valuta.dto.customer.CustomerStatsDto;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.puzzleir.backend.exception.ResourceNotFoundException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Ügyfél statisztika szolgáltatás.
 */
@Service
@RequiredArgsConstructor
@Slf4j
public class CustomerStatisticsService {

    private final CustomerRepository customerRepository;
    private final TransactionRepository transactionRepository;

    /**
     * Ügyfél statisztikái
     */
    @Transactional(readOnly = true)
    public CustomerStatsDto getCustomerStats(Long customerId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található: " + customerId));

        if (!customer.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Ügyfél nem található: " + customerId);
        }

        // Tranzakciók lekérése a customer_name/customer_document_number alapján
        List<Transaction> transactions = transactionRepository.findAll().stream()
                .filter(t -> t.getCompany().getId().equals(companyId))
                .filter(t -> TransactionStatus.COMPLETED.equals(t.getStatus()))
                .filter(t -> {
                    String docNum = customer.getDocumentNumber();
                    return docNum != null && docNum.equals(t.getCustomerDocumentNumber());
                })
                .toList();

        if (transactions.isEmpty()) {
            return CustomerStatsDto.builder()
                    .customerId(customerId)
                    .customerName(customer.getName())
                    .totalTransactions(0)
                    .totalVolumeHuf(BigDecimal.ZERO)
                    .averageAmount(BigDecimal.ZERO)
                    .build();
        }

        BigDecimal totalVolume = transactions.stream()
                .map(Transaction::getHufAmount)
                .filter(Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal avgAmount = totalVolume.divide(
                new BigDecimal(transactions.size()), 2, RoundingMode.HALF_UP);

        LocalDate firstVisit = transactions.stream()
                .map(Transaction::getTransactionDate)
                .filter(Objects::nonNull)
                .min(LocalDate::compareTo)
                .orElse(null);

        LocalDate lastVisit = transactions.stream()
                .map(Transaction::getTransactionDate)
                .filter(Objects::nonNull)
                .max(LocalDate::compareTo)
                .orElse(null);

        // Preferált valuta: a legtöbb tranzakcióban használt
        String preferredCurrency = transactions.stream()
                .filter(t -> t.getCurrency() != null)
                .collect(Collectors.groupingBy(t -> t.getCurrency().getCode(), Collectors.counting()))
                .entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElse(null);

        return CustomerStatsDto.builder()
                .customerId(customerId)
                .customerName(customer.getName())
                .totalTransactions(transactions.size())
                .totalVolumeHuf(totalVolume)
                .averageAmount(avgAmount)
                .firstVisit(firstVisit)
                .lastVisit(lastVisit)
                .preferredCurrency(preferredCurrency)
                .build();
    }

    /**
     * Top ügyfelek listája (adott iroda, időszak, limit)
     */
    @Transactional(readOnly = true)
    public List<CustomerRankingDto> getTopCustomers(UUID branchId, LocalDate from, LocalDate to, int limit) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<Transaction> transactions = transactionRepository.findAll().stream()
                .filter(t -> t.getCompany().getId().equals(companyId))
                .filter(t -> TransactionStatus.COMPLETED.equals(t.getStatus()))
                .filter(t -> branchId == null || (t.getBranch() != null && t.getBranch().getId().equals(branchId)))
                .filter(t -> from == null || !t.getTransactionDate().isBefore(from))
                .filter(t -> to == null || !t.getTransactionDate().isAfter(to))
                .filter(t -> t.getCustomerDocumentNumber() != null && !t.getCustomerDocumentNumber().isBlank())
                .toList();

        // Csoportosítás ügyfél okmányszám alapján
        Map<String, List<Transaction>> byCustomer = transactions.stream()
                .collect(Collectors.groupingBy(Transaction::getCustomerDocumentNumber));

        List<CustomerRankingDto> rankings = byCustomer.entrySet().stream()
                .map(entry -> {
                    List<Transaction> txs = entry.getValue();
                    BigDecimal total = txs.stream()
                            .map(Transaction::getHufAmount)
                            .filter(Objects::nonNull)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);

                    String name = txs.stream()
                            .map(Transaction::getCustomerName)
                            .filter(Objects::nonNull)
                            .findFirst()
                            .orElse(entry.getKey());

                    // Próbáljuk megtalálni a Customer entity-t
                    Long custId = customerRepository.findByDocumentNumberContainingIgnoreCase(entry.getKey())
                            .stream().findFirst().map(Customer::getId).orElse(null);

                    return CustomerRankingDto.builder()
                            .customerId(custId)
                            .customerName(name)
                            .transactionCount(txs.size())
                            .totalVolumeHuf(total)
                            .build();
                })
                .sorted((a, b) -> b.getTotalVolumeHuf().compareTo(a.getTotalVolumeHuf()))
                .limit(limit)
                .toList();

        // Rank beállítás
        List<CustomerRankingDto> result = new ArrayList<>();
        for (int i = 0; i < rankings.size(); i++) {
            CustomerRankingDto r = rankings.get(i);
            r.setRank(i + 1);
            result.add(r);
        }

        return result;
    }
}
