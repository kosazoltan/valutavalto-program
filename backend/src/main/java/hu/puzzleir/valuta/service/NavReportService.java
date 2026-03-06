package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.nav.NavReportDto;
import hu.puzzleir.valuta.dto.nav.NavReportableTransactionDto;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * NAV adatszolgáltatás szolgáltatás.
 *
 * 2M+ Ft tranzakciók jelentése az adóhatóság felé.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class NavReportService {

    private final TransactionRepository transactionRepository;

    /** NAV jelentési küszöb: 2.000.000 Ft */
    private static final BigDecimal NAV_THRESHOLD = new BigDecimal("2000000");

    /**
     * Napi NAV riport generálása.
     */
    public NavReportDto generateNavReport(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();

        List<Transaction> reportable = transactionRepository.findReportableTransactions(
            companyId, date, NAV_THRESHOLD);

        BigDecimal totalAmount = BigDecimal.ZERO;
        List<NavReportableTransactionDto> dtos = new java.util.ArrayList<>();

        for (Transaction tx : reportable) {
            totalAmount = totalAmount.add(tx.getHufAmount());
            dtos.add(toReportableDto(tx));
        }

        return NavReportDto.builder()
            .date(date)
            .reportableTransactionCount(reportable.size())
            .totalAmountHuf(totalAmount)
            .transactions(dtos)
            .build();
    }

    /**
     * CSV export a NAV-nak jelentendő tranzakciókról.
     */
    public byte[] exportNavCsv(LocalDate date) {
        NavReportDto report = generateNavReport(date);

        StringBuilder csv = new StringBuilder();
        csv.append("Bizonylat;Típus;Dátum;Idő;Valuta;Valuta összeg;Árfolyam;HUF összeg;");
        csv.append("Ügyfél kód;Ügyfél név;Cím;Okmányszám\n");

        for (NavReportableTransactionDto tx : report.getTransactions()) {
            csv.append(safe(tx.getReceiptNumber())).append(';');
            csv.append(safe(tx.getTransactionType())).append(';');
            csv.append(tx.getTransactionDate()).append(';');
            csv.append(tx.getTransactionTime()).append(';');
            csv.append(safe(tx.getCurrencyCode())).append(';');
            csv.append(tx.getCurrencyAmount()).append(';');
            csv.append(tx.getExchangeRate()).append(';');
            csv.append(tx.getHufAmount()).append(';');
            csv.append(safe(tx.getCustomerId())).append(';');
            csv.append(safe(tx.getCustomerName())).append(';');
            csv.append(safe(tx.getCustomerAddress())).append(';');
            csv.append(safe(tx.getCustomerDocumentNumber())).append('\n');
        }

        return csv.toString().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Jelenthető tranzakciók listája.
     */
    public List<NavReportableTransactionDto> getReportableTransactions(LocalDate date) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        List<Transaction> reportable = transactionRepository.findReportableTransactions(
            companyId, date, NAV_THRESHOLD);
        return reportable.stream().map(this::toReportableDto).toList();
    }

    // ============ HELPER ============

    private NavReportableTransactionDto toReportableDto(Transaction tx) {
        return NavReportableTransactionDto.builder()
            .transactionId(tx.getId())
            .receiptNumber(tx.getReceiptNumber())
            .transactionType(tx.getTransactionType().name())
            .transactionDate(tx.getTransactionDate())
            .transactionTime(tx.getTransactionTime())
            .currencyCode(tx.getCurrency() != null ? tx.getCurrency().getCode() : null)
            .currencyAmount(tx.getCurrencyAmount())
            .exchangeRate(tx.getExchangeRate())
            .hufAmount(tx.getHufAmount())
            .customerId(tx.getCustomerId())
            .customerName(tx.getCustomerName())
            .customerAddress(tx.getCustomerAddress())
            .customerDocumentNumber(tx.getCustomerDocumentNumber())
            .build();
    }

    private String safe(String value) {
        if (value == null) return "";
        // CSV-ben a pontosvesszőt és sortörést escapelni kell
        return value.replace(";", ",").replace("\n", " ").replace("\r", "");
    }
}
