package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Receipt;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionStatus;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.ReceiptRepository;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.MockedStatic;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;

/**
 * v2.3.48 (B7 audit fix): ReceiptService synthesize-from-Transaction tesztek.
 *
 * Cel:
 * 1. Ha a Receipt tabla ures, a list() synthesize Receipt-eket a Transaction-bol
 * 2. A synthesized UUID encoding/decoding mukodik (most-sig-bits=0, least=tx.id)
 * 3. getById() synthesized UUID-ra is mukodik (decode + multi-tenant verify)
 * 4. print() synthesized UUID eseten lazily materialize a Receipt rekordot
 * 5. Multi-tenant: cross-company synthesized lookup elutasitva
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("ReceiptService B7 audit fix — synthesize Receipt from Transaction")
class ReceiptServiceB7Test {

    @Mock private ReceiptRepository receiptRepository;
    @Mock private TransactionRepository transactionRepository;

    @InjectMocks private ReceiptService receiptService;

    private static final UUID COMPANY_ID = UUID.fromString("a72280a4-f950-482d-bcbf-6b98f0925b43");
    private static final UUID OTHER_COMPANY_ID = UUID.fromString("11111111-1111-1111-1111-111111111111");

    private MockedStatic<SecurityUtils> securityUtilsMock;

    @BeforeEach
    void setUp() {
        securityUtilsMock = Mockito.mockStatic(SecurityUtils.class);
        securityUtilsMock.when(SecurityUtils::getCurrentCompanyId).thenReturn(COMPANY_ID);
    }

    private Transaction makeTransaction(long id, String receiptNumber, TransactionType type) {
        Company c = new Company();
        c.setId(COMPANY_ID);
        Branch b = new Branch();
        b.setId(UUID.randomUUID());
        Transaction t = new Transaction();
        t.setId(id);
        t.setCompany(c);
        t.setBranch(b);
        t.setReceiptNumber(receiptNumber);
        t.setTransactionType(type);
        t.setTransactionDate(LocalDate.of(2026, 4, 29));
        t.setTransactionTime(LocalTime.of(10, 30));
        t.setStatus(TransactionStatus.COMPLETED);
        t.setCurrencyAmount(new BigDecimal("100.00"));
        t.setExchangeRate(new BigDecimal("400.0000"));
        t.setHufAmount(new BigDecimal("40000.00"));
        return t;
    }

    @Test
    @DisplayName("list() synthesize Receipt-et ad vissza, ha a Receipt tabla URES")
    void list_synthesizesFromTransactionsWhenReceiptTableEmpty() {
        when(receiptRepository.findAllByCompanyId(COMPANY_ID))
                .thenReturn(Collections.emptyList());

        Transaction tx1 = makeTransaction(101L, "V017000001", TransactionType.BUY);
        Transaction tx2 = makeTransaction(102L, "E017000001", TransactionType.SELL);

        when(transactionRepository.findReceiptListByCompanyId(eq(COMPANY_ID), any(Pageable.class)))
                .thenReturn(List.of(tx1, tx2));

        List<Receipt> receipts = receiptService.list(null);

        assertThat(receipts).hasSize(2);
        assertThat(receipts).extracting(Receipt::getReceiptNumber)
                .containsExactly("V017000001", "E017000001");
        assertThat(receipts).extracting(Receipt::getReceiptType)
                .containsExactly("BUY", "SELL");
        // Synthesized UUID: most-sig-bits = 0
        assertThat(receipts.get(0).getId().getMostSignificantBits()).isZero();
        assertThat(receipts.get(0).getId().getLeastSignificantBits()).isEqualTo(101L);
    }

    @Test
    @DisplayName("list() merge real Receipt + synthesized — duplikaltakat KIHAGY")
    void list_mergesRealAndSynthesizedSkipsMaterialized() {
        Transaction tx1 = makeTransaction(201L, "V017000010", TransactionType.BUY);
        Transaction tx2 = makeTransaction(202L, "V017000011", TransactionType.BUY);

        // tx1-hez mar van real Receipt (synthesized UUID-val), tx2-hez nincs
        Receipt realForTx1 = Receipt.builder()
                .id(new UUID(0L, 201L))  // synthesized UUID
                .companyId(COMPANY_ID)
                .receiptNumber("V017000010")
                .receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29))
                .isPrinted(true)
                .build();

        when(receiptRepository.findAllByCompanyId(COMPANY_ID))
                .thenReturn(List.of(realForTx1));
        when(transactionRepository.findReceiptListByCompanyId(eq(COMPANY_ID), any(Pageable.class)))
                .thenReturn(List.of(tx1, tx2));

        List<Receipt> receipts = receiptService.list(null);

        // 1 real (tx1 mar materializaalt) + 1 synthesized (tx2)
        assertThat(receipts).hasSize(2);
        // Real receipt: isPrinted=true (megerositve)
        assertThat(receipts.get(0).getIsPrinted()).isTrue();
        assertThat(receipts.get(0).getReceiptNumber()).isEqualTo("V017000010");
        // Synthesized: isPrinted=false
        assertThat(receipts.get(1).getIsPrinted()).isFalse();
        assertThat(receipts.get(1).getReceiptNumber()).isEqualTo("V017000011");
    }

    @Test
    @DisplayName("getById() synthesized UUID-t feloldja a Transaction tablabol")
    void getById_synthesizedUuidResolvesFromTransaction() {
        UUID synthesizedUuid = new UUID(0L, 301L);
        Transaction tx = makeTransaction(301L, "V017000020", TransactionType.BUY);

        when(receiptRepository.findById(synthesizedUuid)).thenReturn(Optional.empty());
        when(transactionRepository.findById(301L)).thenReturn(Optional.of(tx));

        Receipt r = receiptService.getById(synthesizedUuid);

        assertThat(r.getId()).isEqualTo(synthesizedUuid);
        assertThat(r.getReceiptNumber()).isEqualTo("V017000020");
        assertThat(r.getReceiptType()).isEqualTo("BUY");
    }

    @Test
    @DisplayName("getById() cross-company synthesized UUID-t ELUTASIT (multi-tenant)")
    void getById_crossCompanySynthesizedUuidRejected() {
        UUID synthesizedUuid = new UUID(0L, 401L);
        Company otherCompany = new Company();
        otherCompany.setId(OTHER_COMPANY_ID);
        Transaction txOtherCompany = makeTransaction(401L, "V999000001", TransactionType.BUY);
        txOtherCompany.setCompany(otherCompany);

        when(receiptRepository.findById(synthesizedUuid)).thenReturn(Optional.empty());
        when(transactionRepository.findById(401L)).thenReturn(Optional.of(txOtherCompany));

        assertThatThrownBy(() -> receiptService.getById(synthesizedUuid))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("nem található");
    }

    @Test
    @DisplayName("print() synthesized UUID eseten lazily materialize a Receipt rekordot")
    void print_synthesizedUuidLazilyMaterializesReceipt() {
        UUID synthesizedUuid = new UUID(0L, 501L);
        Transaction tx = makeTransaction(501L, "V017000030", TransactionType.BUY);

        when(receiptRepository.findById(synthesizedUuid)).thenReturn(Optional.empty());
        when(transactionRepository.findById(501L)).thenReturn(Optional.of(tx));
        when(receiptRepository.save(any(Receipt.class))).thenAnswer(inv -> inv.getArgument(0));

        Receipt printed = receiptService.print(synthesizedUuid);

        assertThat(printed.getIsPrinted()).isTrue();
        assertThat(printed.getPrintedAt()).isNotNull();
        assertThat(printed.getReceiptNumber()).isEqualTo("V017000030");
        assertThat(printed.getReceiptType()).isEqualTo("BUY");
    }

    @Test
    @DisplayName("print() real Receipt eseten csak isPrinted update")
    void print_realReceiptOnlyUpdatesIsPrinted() {
        UUID realUuid = UUID.randomUUID();
        Receipt existing = Receipt.builder()
                .id(realUuid)
                .companyId(COMPANY_ID)
                .receiptNumber("V017000099")
                .receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29))
                .isPrinted(false)
                .build();

        when(receiptRepository.findById(realUuid)).thenReturn(Optional.of(existing));
        when(receiptRepository.save(any(Receipt.class))).thenAnswer(inv -> inv.getArgument(0));

        Receipt printed = receiptService.print(realUuid);

        assertThat(printed.getIsPrinted()).isTrue();
        assertThat(printed.getPrintedAt()).isNotNull();
        assertThat(printed.getId()).isEqualTo(realUuid);
    }

    @Test
    @DisplayName("v2.3.50 P1 SECURITY: print() cross-company real Receipt-et ELUTASIT")
    void print_crossCompanyRealReceiptRejected() {
        UUID realUuid = UUID.randomUUID();
        // A receipt belongs to OTHER_COMPANY_ID, but current user is COMPANY_ID
        Receipt otherCompanyReceipt = Receipt.builder()
                .id(realUuid)
                .companyId(OTHER_COMPANY_ID)
                .receiptNumber("V999000001")
                .receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29))
                .isPrinted(false)
                .build();

        when(receiptRepository.findById(realUuid)).thenReturn(Optional.of(otherCompanyReceipt));

        assertThatThrownBy(() -> receiptService.print(realUuid))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("nem található");

        // CRITICAL: verify the cross-company receipt was NEM modositva (NEM hivtuk save())
        Mockito.verify(receiptRepository, Mockito.never()).save(any(Receipt.class));
    }

    @Test
    @DisplayName("v2.3.50 P1 SECURITY: getById() cross-company real Receipt-et ELUTASIT")
    void getById_crossCompanyRealReceiptRejected() {
        UUID realUuid = UUID.randomUUID();
        Receipt otherCompanyReceipt = Receipt.builder()
                .id(realUuid)
                .companyId(OTHER_COMPANY_ID)
                .receiptNumber("V999000002")
                .receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29))
                .isPrinted(false)
                .build();

        when(receiptRepository.findById(realUuid)).thenReturn(Optional.of(otherCompanyReceipt));

        assertThatThrownBy(() -> receiptService.getById(realUuid))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("nem található");
    }

    @Test
    @DisplayName("Synthesized UUID encoding: tx.id -> UUID(0, txId), decode visszahozza")
    void synthesizedUuidEncodingRoundTrip() {
        long txId = 12345L;
        UUID encoded = new UUID(0L, txId);

        assertThat(encoded.getMostSignificantBits()).isZero();
        assertThat(encoded.getLeastSignificantBits()).isEqualTo(txId);
    }

    @AfterEach
    void tearDown() {
        if (securityUtilsMock != null) {
            securityUtilsMock.close();
        }
    }
}
