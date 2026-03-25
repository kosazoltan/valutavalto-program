package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Transaction;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/**
 * Tranzakcio export szolgaltatas.
 * Kifele exportalhato tranzakcio listak eloallitasa.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TransactionExportService {

    private final TransactionReportService transactionReportService;

    /**
     * Egyszeru napi export adatelokeszites.
     */
    public List<Transaction> getDailyExportData() {
        return transactionReportService.getDailyTransactions();
    }

    /**
     * Idoszakos export adatelokeszites (a teljes branch adathalmazra tipusfilter nelkul).
     */
    public List<Transaction> getPeriodExportData(LocalDate date) {
        // Jelenlegi Phase-1 scopeban napi export kompatibilitasi wrapper.
        // Tovabbi formatum-specifikus export (CSV/XLSX/PDF) kulon export servicekben van.
        return transactionReportService.getDailyTransactions();
    }
}
