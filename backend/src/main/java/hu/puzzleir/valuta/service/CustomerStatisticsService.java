package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.customer.CustomerRankingDto;
import hu.puzzleir.valuta.dto.customer.CustomerStatsDto;
import hu.puzzleir.valuta.entity.Customer;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.repository.CustomerRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.springframework.data.domain.Page;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;

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

        // Tranzakciók lekérése okmányszám alapján (multi-tenant szűréssel)
        String docNum = customer.getDocumentNumber();
        List<Transaction> transactions = (docNum != null)
                ? transactionRepository.findByCompanyIdAndCustomerDocumentNumber(companyId, docNum)
                : Collections.emptyList();

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
     * Ügyfél statisztikák dátum szűréssel.
     */
    @Transactional(readOnly = true)
    public CustomerStatsDto getCustomerStats(Long customerId, LocalDate from, LocalDate to) {
        if (from == null && to == null) {
            return getCustomerStats(customerId);
        }

        UUID companyId = SecurityUtils.getCurrentCompanyId();

        Customer customer = customerRepository.findById(customerId)
                .orElseThrow(() -> new ResourceNotFoundException("Ügyfél nem található: " + customerId));

        if (!customer.getCompany().getId().equals(companyId)) {
            throw new ResourceNotFoundException("Ügyfél nem található: " + customerId);
        }

        String docNum = customer.getDocumentNumber();
        List<Transaction> transactions = (docNum != null)
                ? transactionRepository.findByCompanyIdAndCustomerDocumentNumberAndDateRange(companyId, docNum, from, to)
                : Collections.emptyList();

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

        return CustomerStatsDto.builder()
                .customerId(customerId)
                .customerName(customer.getName())
                .totalTransactions(transactions.size())
                .totalVolumeHuf(totalVolume)
                .averageAmount(avgAmount)
                .build();
    }

    /**
     * Top ügyfelek listája (adott iroda, időszak, limit)
     */
    @Transactional(readOnly = true)
    public List<CustomerRankingDto> getTopCustomers(UUID branchId, LocalDate from, LocalDate to, int limit) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        // 2026-04-29 v2.3.26 (Codex P1 PR #290 follow-up):
        // Branch-scoped vs company-wide query split. A `branchId` null lehet, amikor
        // a controller `@RequestParam(required = false)`-szal company-wide-ot kér
        // (pl. /customers/top, /customers/frequent). A B17 hardening miatt a
        // `findWithFilters` most KÖTELEZI a branchId-t, ezért külön company-wide
        // metódust hívunk null esetén.
        Page<Transaction> page = (branchId == null)
                ? transactionRepository.findCompanyWideWithFilters(
                        companyId, from, to, null, org.springframework.data.domain.Pageable.unpaged())
                : transactionRepository.findWithFilters(
                        companyId, branchId, from, to, null, false, org.springframework.data.domain.Pageable.unpaged());

        List<Transaction> transactions = page.getContent().stream()
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
                    Long custId = customerRepository.findByCompanyIdAndDocumentNumberContainingIgnoreCase(companyId, entry.getKey())
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
