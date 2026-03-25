package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.entity.Receipt;
import hu.puzzleir.valuta.repository.ReceiptRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ReceiptService {

    private final ReceiptRepository repo;

    public List<Receipt> list(UUID transactionId) {
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        if (transactionId != null) {
            return repo.findByCompanyIdAndTransactionId(companyId, transactionId);
        }
        return repo.findAllByCompanyId(companyId);
    }

    public Receipt getById(UUID id) {
        return repo.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Bizonylat nem található: " + id));
    }

    @Transactional(rollbackFor = Exception.class)
    public Receipt print(UUID id) {
        Receipt receipt = getById(id);
        receipt.setIsPrinted(true);
        receipt.setPrintedAt(LocalDateTime.now());
        return repo.save(receipt);
    }
}
