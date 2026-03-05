package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.PosTerminal;
import hu.puzzleir.valuta.repository.PosTerminalRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PosTerminalService {

    private final PosTerminalRepository repository;

    public List<PosTerminal> findAll() {
        return repository.findByIsActiveTrueOrderByTerminalNameAsc();
    }

    public PosTerminal findById(UUID id) {
        return repository.findById(id)
                .orElseThrow(() -> new RuntimeException("PosTerminal not found: " + id));
    }

    @Transactional
    public Map<String, Object> processTransaction(String terminalId, BigDecimal amount, String currency) {
        PosTerminal terminal = repository.findByTerminalId(terminalId)
                .orElseThrow(() -> new RuntimeException("POS terminál nem található: " + terminalId));

        if (!Boolean.TRUE.equals(terminal.getIsActive())) {
            throw new RuntimeException("POS terminál inaktív: " + terminalId);
        }

        // Update last transaction timestamp
        terminal.setLastTransactionAt(LocalDateTime.now());
        repository.save(terminal);

        // Process transaction result (simplified)
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("terminalId", terminalId);
        result.put("terminalName", terminal.getTerminalName());
        result.put("amount", amount);
        result.put("currency", currency);
        result.put("status", "PROCESSED");
        result.put("processedAt", LocalDateTime.now());
        result.put("transactionRef", UUID.randomUUID().toString().substring(0, 8).toUpperCase());
        return result;
    }
}
