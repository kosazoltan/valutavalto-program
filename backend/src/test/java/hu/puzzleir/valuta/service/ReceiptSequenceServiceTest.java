package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.ReceiptSequence;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.ReceiptSequenceRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ReceiptSequenceServiceTest {

    @Mock
    private ReceiptSequenceRepository receiptSequenceRepository;
    @Mock
    private BranchRepository branchRepository;
    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private ReceiptSequenceService service;

    @Test
    void generateReceiptNumberUsesCompanyScopedBranchLookupWhenAuthenticated() {
        UUID companyId = UUID.randomUUID();
        UUID branchId = UUID.randomUUID();
        Company company = Company.builder().id(companyId).build();
        Branch branch = Branch.builder()
                .id(branchId)
                .code("BR105")
                .company(company)
                .build();
        ReceiptSequence sequence = ReceiptSequence.builder()
                .branchId(branchId)
                .lastSellReceipt(100000L)
                .build();

        try (MockedStatic<SecurityUtils> security = mockStatic(SecurityUtils.class)) {
            security.when(SecurityUtils::getCurrentCompanyIdOrNull).thenReturn(companyId);
            when(branchRepository.findByIdAndCompanyId(branchId, companyId)).thenReturn(Optional.of(branch));
            when(receiptSequenceRepository.findByBranchIdForUpdate(branchId)).thenReturn(Optional.of(sequence));
            when(receiptSequenceRepository.save(sequence)).thenReturn(sequence);

            String receiptNumber = service.generateReceiptNumber(branchId, TransactionType.SELL);

            assertThat(receiptNumber).isEqualTo("E105100001");
            verify(branchRepository).findByIdAndCompanyId(branchId, companyId);
            verify(branchRepository, never()).findById(branchId);
        }
    }
}
