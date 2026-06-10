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
import static org.mockito.ArgumentMatchers.isNull;
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

    // EXCMD b5b (FR-BSZUR-02 "csak ügyfeles" + FR-BSZUR-05 10M Ft AML-jelölő):
    // a list() a synthesized ÉS a real Receipt-eket is dúsítja customerName + hufAmount
    // @Transient mezőkkel a kapcsolt Transaction-ből.

    @Test
    @DisplayName("EXCMD b5b: synthesized Receipt customerName + hufAmount dúsítás a tx-ből")
    void list_synthesizedReceiptEnrichedWithCustomerAndHuf() {
        when(receiptRepository.findByCompanyIdAndIssueDateRange(eq(COMPANY_ID), any(), any()))
                .thenReturn(Collections.emptyList());

        Transaction tx = makeTransaction(601L, "V017000040", TransactionType.BUY);
        tx.setCustomerName("Kovács János");
        tx.setHufAmount(new BigDecimal("12000000.00")); // 12 M Ft → 10M+ küszöb felett

        when(transactionRepository.findReceiptListByCompanyIdAndDateRange(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class)))
                .thenReturn(List.of(tx));

        List<Receipt> receipts = receiptService.list(null);

        assertThat(receipts).hasSize(1);
        assertThat(receipts.get(0).getCustomerName()).isEqualTo("Kovács János");
        assertThat(receipts.get(0).getHufAmount()).isEqualByComparingTo("12000000.00");
    }

    @Test
    @DisplayName("EXCMD b5b: real (materializált) Receipt dúsítása EGY batch findAllById query-vel (N+1-mentes)")
    void list_realReceiptsEnrichedViaBatchQuery() {
        // Két materializált real receipt (synthesized UUID id-vel), tx nélkül a Receipt táblában
        Receipt real1 = Receipt.builder()
                .id(new UUID(0L, 701L)).companyId(COMPANY_ID)
                .receiptNumber("V017000050").receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29)).isPrinted(true).build();
        Receipt real2 = Receipt.builder()
                .id(new UUID(0L, 702L)).companyId(COMPANY_ID)
                .receiptNumber("E017000051").receiptType("SELL")
                .issueDate(LocalDate.of(2026, 4, 29)).isPrinted(true).build();

        Transaction tx1 = makeTransaction(701L, "V017000050", TransactionType.BUY);
        tx1.setCustomerName("Nagy Anna");
        tx1.setHufAmount(new BigDecimal("500000.00")); // küszöb alatt
        Transaction tx2 = makeTransaction(702L, "E017000051", TransactionType.SELL);
        tx2.setCustomerName("Szabó Péter");
        tx2.setHufAmount(new BigDecimal("10000000.00")); // pontosan a küszöbön → 10M+

        when(receiptRepository.findByCompanyIdAndIssueDateRange(eq(COMPANY_ID), any(), any()))
                .thenReturn(List.of(real1, real2));
        // a materializáltakat a synthesized-detektálás kihagyja → nincs synthesized
        when(transactionRepository.findReceiptListByCompanyIdAndDateRange(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class)))
                .thenReturn(List.of(tx1, tx2));
        // N+1 ELKERÜLÉS + multi-tenant + OSIV-safe: EGYETLEN cég-szűrt batch query a két txId-ra
        when(transactionRepository.findAllByIdInAndCompanyId(any(), eq(COMPANY_ID)))
                .thenReturn(List.of(tx1, tx2));

        List<Receipt> receipts = receiptService.list(null);

        assertThat(receipts).hasSize(2);
        assertThat(receipts).extracting(Receipt::getCustomerName)
                .containsExactlyInAnyOrder("Nagy Anna", "Szabó Péter");
        // EGYETLEN batch hívás (NEM per-receipt) — N+1-mentesség bizonyítása
        Mockito.verify(transactionRepository, Mockito.times(1))
                .findAllByIdInAndCompanyId(any(), eq(COMPANY_ID));
    }

    @Test
    @DisplayName("Codex P1+P2 (multi-tenant): a dúsítás cég-szűrt query-t hív — cross-company tx NEM szivárog")
    void list_realReceiptEnrich_crossTenant_notLeaked() {
        // Materializált real receipt a saját cégnél, a dekódolt tx-id egy MÁS céghez tartozó
        // tranzakcióra mutatna. A dúsítás cég-szűrt query-t (findAllByIdInAndCompanyId) hív az
        // AKTUÁLIS companyId-vel — egy másik cég tranzakciója a DB-ben kiszűrődik, ezért a query
        // ÜRES eredményt ad → a customerName/hufAmount null marad (nincs leak), és nem is kell a
        // detached tx.getCompany()-t dereferálni (OSIV-off safe).
        Receipt real = Receipt.builder()
                .id(new UUID(0L, 703L)).companyId(COMPANY_ID)
                .receiptNumber("V017000060").receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29)).isPrinted(true).build();

        when(receiptRepository.findByCompanyIdAndIssueDateRange(eq(COMPANY_ID), any(), any())).thenReturn(List.of(real));
        when(transactionRepository.findReceiptListByCompanyIdAndDateRange(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class)))
                .thenReturn(List.of());
        // A cég-szűrt query az AKTUÁLIS céggel hívva ÜRES (a cross-company tx kiszűrődik a DB-ben).
        when(transactionRepository.findAllByIdInAndCompanyId(any(), eq(COMPANY_ID)))
                .thenReturn(List.of());

        List<Receipt> receipts = receiptService.list(null);

        assertThat(receipts).hasSize(1);
        assertThat(receipts.get(0).getCustomerName()).isNull();
        assertThat(receipts.get(0).getHufAmount()).isNull();
        // Bizonyítjuk, hogy a dúsítás a SAJÁT cég id-jával kérdez (nem támadó-vezérelt értékkel).
        Mockito.verify(transactionRepository).findAllByIdInAndCompanyId(any(), eq(COMPANY_ID));
    }

    @Test
    @DisplayName("Codex/Copilot P2: a transactionId-szűrt ág IS dúsít (customerName + hufAmount)")
    void list_filteredByTransactionId_isEnriched() {
        // GET /api/v1/receipts?transactionId=... — a korai-return szűrt ágnak is dúsítania kell,
        // különben a materializált receipt customerName/hufAmount-ja null marad (—/nincs 10M badge).
        UUID txFilter = new UUID(0L, 710L); // synthesizedUuid → decode 710
        Receipt real = Receipt.builder()
                .id(txFilter).companyId(COMPANY_ID)
                .receiptNumber("V017000070").receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29)).isPrinted(true).build();
        Transaction tx = makeTransaction(710L, "V017000070", TransactionType.BUY);
        tx.setCustomerName("Kovács Béla");
        tx.setHufAmount(new BigDecimal("12000000.00")); // 10M felett → AML-jelölő is

        when(receiptRepository.findByCompanyIdAndTransactionId(COMPANY_ID, txFilter))
                .thenReturn(List.of(real));
        when(transactionRepository.findAllByIdInAndCompanyId(any(), eq(COMPANY_ID)))
                .thenReturn(List.of(tx));

        List<Receipt> receipts = receiptService.list(txFilter);

        assertThat(receipts).hasSize(1);
        assertThat(receipts.get(0).getCustomerName()).isEqualTo("Kovács Béla");
        assertThat(receipts.get(0).getHufAmount()).isEqualByComparingTo("12000000.00");
    }

    @Test
    @DisplayName("Codex P2: a from/to MINDKÉT query-be bekerül — real ÉS synthesized is DB-szinten szűrt")
    void list_dateRange_filtersRealAndSynthesizedAtDbLevel() {
        LocalDate from = LocalDate.of(2026, 4, 1);
        LocalDate to = LocalDate.of(2026, 4, 30);
        when(receiptRepository.findByCompanyIdAndIssueDateRange(eq(COMPANY_ID), eq(from), eq(to)))
                .thenReturn(Collections.emptyList());
        when(transactionRepository.findReceiptListByCompanyIdAndDateRange(
                eq(COMPANY_ID), eq(from), eq(to), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class)))
                .thenReturn(Collections.emptyList());

        receiptService.list(null, from, to);

        // A dátum-szűrés a DB-ben fut MINDKÉT forrásra (nem csak a synthesized ágon) — a real
        // receipt-ek sem kerülnek be a tartományon kívülről (Codex P2 szerződés).
        Mockito.verify(receiptRepository).findByCompanyIdAndIssueDateRange(eq(COMPANY_ID), eq(from), eq(to));
        Mockito.verify(transactionRepository)
                .findReceiptListByCompanyIdAndDateRange(eq(COMPANY_ID), eq(from), eq(to),
                        any(), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class));
    }

    @Test
    @DisplayName("Codex P2 (FR-BSZUR-03): ügyfél-szűrők a synthesized DB-query-be kerülnek (%lower% LIKE)")
    void list_customerFilters_pushedToSynthesizedQuery() {
        when(receiptRepository.findByCompanyIdAndIssueDateRange(eq(COMPANY_ID), any(), any()))
                .thenReturn(Collections.emptyList());
        when(transactionRepository.findReceiptListByCompanyIdAndDateRange(
                eq(COMPANY_ID), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class)))
                .thenReturn(Collections.emptyList());

        receiptService.list(null, null, null,
                java.util.Map.of("customerName", "Kovács", "customerNationality", "Magyar"));

        // A name+nationality %lower% LIKE-ként megy a synthesized query-be (a 500-as csonkolás ELŐTT,
        // DB-szinten — Codex P2); a többi customer-param null (nincs szűrés). A mező-SORREND is rögzítve.
        Mockito.verify(transactionRepository).findReceiptListByCompanyIdAndDateRange(
                eq(COMPANY_ID), isNull(), isNull(),
                eq("%kovács%"),       // custName
                isNull(),             // custMotherName
                isNull(),             // custBirthPlace
                isNull(),             // custBirthDate
                eq("%magyar%"),       // custNationality
                isNull(),             // custAddress
                isNull(),             // custDocType
                isNull(),             // custDocNumber
                isNull(),             // custActorName (FR-BSZUR-04)
                any(Pageable.class));
    }

    @Test
    @DisplayName("Codex P2 (FR-BSZUR-03): a materializált real receipt-eket IS szűri az ügyfél-adatlap szűrő")
    void list_customerFilters_filtersMaterializedReceipts() {
        Receipt match = Receipt.builder()
                .id(new UUID(0L, 730L)).companyId(COMPANY_ID)
                .receiptNumber("V017000090").receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29)).isPrinted(true).build();
        Receipt noMatch = Receipt.builder()
                .id(new UUID(0L, 731L)).companyId(COMPANY_ID)
                .receiptNumber("V017000091").receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29)).isPrinted(true).build();
        Transaction txMatch = makeTransaction(730L, "V017000090", TransactionType.BUY);
        txMatch.setCustomerName("Kovács János");
        Transaction txNoMatch = makeTransaction(731L, "V017000091", TransactionType.BUY);
        txNoMatch.setCustomerName("Szabó Péter");

        when(receiptRepository.findByCompanyIdAndIssueDateRange(eq(COMPANY_ID), any(), any()))
                .thenReturn(new java.util.ArrayList<>(List.of(match, noMatch)));
        when(transactionRepository.findReceiptListByCompanyIdAndDateRange(
                eq(COMPANY_ID), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class)))
                .thenReturn(List.of()); // nincs synthesized (mindkettő materializált)
        when(transactionRepository.findAllByIdInAndCompanyId(any(), eq(COMPANY_ID)))
                .thenReturn(List.of(txMatch, txNoMatch));

        List<Receipt> receipts = receiptService.list(null, null, null, java.util.Map.of("customerName", "kovács"));

        // Csak a "Kovács János" marad — a "Szabó Péter" real receipt szerver-oldalon kiesik (Java-szűrés).
        assertThat(receipts).extracting(Receipt::getReceiptNumber).containsExactly("V017000090");
    }

    @Test
    @DisplayName("Codex P2: transactionId + from/to — a tranzakció-ág is szűr a dátumtartományra")
    void list_filteredByTransactionId_honorsDateRange() {
        UUID txFilter = new UUID(0L, 720L);
        Receipt inRange = Receipt.builder()
                .id(txFilter).companyId(COMPANY_ID)
                .receiptNumber("V017000080").receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 15)).isPrinted(true).build();
        Receipt outRange = Receipt.builder()
                .id(new UUID(0L, 721L)).companyId(COMPANY_ID)
                .receiptNumber("V017000081").receiptType("BUY")
                .issueDate(LocalDate.of(2026, 3, 1)).isPrinted(true).build(); // tartományon KÍVÜL

        when(receiptRepository.findByCompanyIdAndTransactionId(COMPANY_ID, txFilter))
                .thenReturn(List.of(inRange, outRange));
        when(transactionRepository.findAllByIdInAndCompanyId(any(), eq(COMPANY_ID)))
                .thenReturn(List.of());

        List<Receipt> receipts = receiptService.list(txFilter, LocalDate.of(2026, 4, 1), LocalDate.of(2026, 4, 30));

        // Csak az áprilisi marad — a tartományon kívüli (márciusi) kiesik a transactionId-ágon is.
        assertThat(receipts).extracting(Receipt::getReceiptNumber).containsExactly("V017000080");
    }

    @Test
    @DisplayName("Codex P2 (FR-BSZUR-03): transactionId + customer-szűrő — a tx-ág is szűr ügyfél-adatlapra")
    void list_filteredByTransactionId_honorsCustomerFilters() {
        UUID txFilter = new UUID(0L, 740L);
        Receipt real = Receipt.builder()
                .id(txFilter).companyId(COMPANY_ID)
                .receiptNumber("V017000100").receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29)).isPrinted(true).build();
        Transaction tx = makeTransaction(740L, "V017000100", TransactionType.BUY);
        tx.setCustomerName("Szabó Péter");

        when(receiptRepository.findByCompanyIdAndTransactionId(COMPANY_ID, txFilter))
                .thenReturn(List.of(real));
        when(transactionRepository.findAllByIdInAndCompanyId(any(), eq(COMPANY_ID)))
                .thenReturn(List.of(tx));

        // customerName "kovács" — a "Szabó Péter" NEM egyezik → a tx-ág is kiszűri (üres).
        List<Receipt> receipts = receiptService.list(txFilter, null, null,
                java.util.Map.of("customerName", "kovács"));
        assertThat(receipts).isEmpty();
    }

    @Test
    @DisplayName("list() synthesize Receipt-et ad vissza, ha a Receipt tabla URES")
    void list_synthesizesFromTransactionsWhenReceiptTableEmpty() {
        when(receiptRepository.findByCompanyIdAndIssueDateRange(eq(COMPANY_ID), any(), any()))
                .thenReturn(Collections.emptyList());

        Transaction tx1 = makeTransaction(101L, "V017000001", TransactionType.BUY);
        Transaction tx2 = makeTransaction(102L, "E017000001", TransactionType.SELL);

        when(transactionRepository.findReceiptListByCompanyIdAndDateRange(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class)))
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

        when(receiptRepository.findByCompanyIdAndIssueDateRange(eq(COMPANY_ID), any(), any()))
                .thenReturn(List.of(realForTx1));
        when(transactionRepository.findReceiptListByCompanyIdAndDateRange(eq(COMPANY_ID), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(), any(Pageable.class)))
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
    @DisplayName("v2.3.53 Codex P1 SECURITY: print() null-companyId real Receipt-et ELUTASIT (NEM bypass)")
    void print_nullCompanyIdRealReceiptRejected() {
        UUID realUuid = UUID.randomUUID();
        // Orphan Receipt — company_id == null (data corruption / legacy seed)
        Receipt orphanReceipt = Receipt.builder()
                .id(realUuid)
                .companyId(null)
                .receiptNumber("V???000003")
                .receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29))
                .isPrinted(false)
                .build();

        when(receiptRepository.findById(realUuid)).thenReturn(Optional.of(orphanReceipt));

        assertThatThrownBy(() -> receiptService.print(realUuid))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessageContaining("nem található");

        // CRITICAL: orphan receipt NOT modified (NEM hivtuk save())
        Mockito.verify(receiptRepository, Mockito.never()).save(any(Receipt.class));
    }

    @Test
    @DisplayName("v2.3.53 Codex P2 SECURITY: getById() null-companyId real Receipt-et ELUTASIT")
    void getById_nullCompanyIdRealReceiptRejected() {
        UUID realUuid = UUID.randomUUID();
        Receipt orphanReceipt = Receipt.builder()
                .id(realUuid)
                .companyId(null)
                .receiptNumber("V???000004")
                .receiptType("BUY")
                .issueDate(LocalDate.of(2026, 4, 29))
                .isPrinted(false)
                .build();

        when(receiptRepository.findById(realUuid)).thenReturn(Optional.of(orphanReceipt));

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
