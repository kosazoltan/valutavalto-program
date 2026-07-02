package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.report.DailyBalanceGridRowDto;
import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.DailyBalance;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.DailyBalanceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-047: a Napi ellenőrző lista grid-service egység-tesztjei — valutánkénti aggregálás,
 * multi-tenant izoláció (idegen iroda → 404), SZÁMZÁR null-kezelés, scope-szűrés.
 */
@ExtendWith(MockitoExtension.class)
class DailyBalanceGridServiceTest {

    private static final UUID COMPANY = UUID.randomUUID();
    private static final UUID BRANCH_A = UUID.randomUUID();
    private static final UUID BRANCH_B = UUID.randomUUID();
    private static final LocalDate DATE = LocalDate.of(2026, 7, 1);

    @Mock
    private DailyBalanceRepository dailyBalanceRepository;

    @Mock
    private BranchRepository branchRepository;

    @InjectMocks
    private DailyBalanceGridService service;

    private static DailyBalance db(UUID branchId, String currency, String opening, String purchases,
                                   String sales, String tIn, String tOut, String closing,
                                   String actualStock, String surplus, String shortage) {
        return DailyBalance.builder()
                .branchId(branchId)
                .balanceDate(DATE)
                .currencyCode(currency)
                .openingBalance(new BigDecimal(opening))
                .purchases(new BigDecimal(purchases))
                .sales(new BigDecimal(sales))
                .transfersIn(new BigDecimal(tIn))
                .transfersOut(new BigDecimal(tOut))
                .closingBalance(new BigDecimal(closing))
                .actualStock(actualStock == null ? null : new BigDecimal(actualStock))
                .surplus(new BigDecimal(surplus))
                .shortage(new BigDecimal(shortage))
                .build();
    }

    private static Branch branch(UUID id, Integer territoryId) {
        Branch b = new Branch();
        b.setId(id);
        b.setVaultTerritoryId(territoryId);
        return b;
    }

    // ----- Pénztár-nézet -----

    @Test
    @DisplayName("pénztár-nézet: a kért iroda sorai valutánként, aggregálás nélkül")
    void branchView_returnsRowsForBranch() {
        when(branchRepository.existsByIdAndCompanyId(BRANCH_A, COMPANY)).thenReturn(true);
        when(dailyBalanceRepository.findByBranchIdsAndDate(List.of(BRANCH_A), DATE)).thenReturn(List.of(
                db(BRANCH_A, "EUR", "100", "50", "30", "10", "5", "125", "125", "0", "0"),
                db(BRANCH_A, "USD", "200", "0", "0", "0", "0", "200", null, "2", "0")));

        List<DailyBalanceGridRowDto> rows = service.getGrid(COMPANY, DATE, BRANCH_A, null);

        assertEquals(2, rows.size());
        DailyBalanceGridRowDto eur = rows.get(0);
        assertEquals("EUR", eur.getCurrencyCode());
        assertEquals(new BigDecimal("100"), eur.getOpeningBalance());
        assertEquals(new BigDecimal("50"), eur.getPurchases());
        assertEquals(new BigDecimal("125"), eur.getActualStock());
        DailyBalanceGridRowDto usd = rows.get(1);
        assertNull(usd.getActualStock()); // FR-8: nincs SZÁMZÁR → null (a grid „–"-t mutat)
        assertEquals(new BigDecimal("2"), usd.getSurplus()); // FR-6: TH-tranzakcióból
    }

    @Test
    @DisplayName("multi-tenant izoláció (§1): idegen cég irodája → 404, DB-lekérdezés nélkül")
    void branchView_crossTenant_notFound() {
        when(branchRepository.existsByIdAndCompanyId(BRANCH_A, COMPANY)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class,
                () -> service.getGrid(COMPANY, DATE, BRANCH_A, null));
        verify(dailyBalanceRepository, never()).findByBranchIdsAndDate(any(), any());
    }

    // ----- Cég/terület-nézet: aggregálás -----

    @Test
    @DisplayName("teljes cég nézet: azonos valuta több pénztárból összeadódik")
    void companyView_aggregatesAcrossBranches() {
        when(branchRepository.findByCompanyId(COMPANY))
                .thenReturn(List.of(branch(BRANCH_A, 1), branch(BRANCH_B, 2)));
        when(dailyBalanceRepository.findByBranchIdsAndDate(List.of(BRANCH_A, BRANCH_B), DATE))
                .thenReturn(List.of(
                        db(BRANCH_A, "EUR", "100", "10", "5", "0", "0", "105", "105", "1", "0"),
                        db(BRANCH_B, "EUR", "200", "20", "10", "0", "0", "210", null, "0", "3")));

        List<DailyBalanceGridRowDto> rows = service.getGrid(COMPANY, DATE, null, null);

        assertEquals(1, rows.size());
        DailyBalanceGridRowDto eur = rows.get(0);
        assertEquals(new BigDecimal("300"), eur.getOpeningBalance());
        assertEquals(new BigDecimal("30"), eur.getPurchases());
        assertEquals(new BigDecimal("315"), eur.getClosingBalance());
        // SZÁMZÁR: csak a rögzített (BRANCH_A) érték — a null nem nulláz és nem dob NPE-t
        assertEquals(new BigDecimal("105"), eur.getActualStock());
        assertEquals(new BigDecimal("1"), eur.getSurplus());
        assertEquals(new BigDecimal("3"), eur.getShortage());
    }

    @Test
    @DisplayName("terület-nézet: csak az adott vault_territory pénztárai kerülnek a scope-ba")
    void territoryView_filtersBranchesByTerritory() {
        when(branchRepository.findByCompanyId(COMPANY))
                .thenReturn(List.of(branch(BRANCH_A, 1), branch(BRANCH_B, 2)));
        when(dailyBalanceRepository.findByBranchIdsAndDate(eq(List.of(BRANCH_A)), eq(DATE)))
                .thenReturn(List.of(db(BRANCH_A, "EUR", "100", "0", "0", "0", "0", "100", null, "0", "0")));

        List<DailyBalanceGridRowDto> rows = service.getGrid(COMPANY, DATE, null, 1);

        assertEquals(1, rows.size());
        verify(dailyBalanceRepository).findByBranchIdsAndDate(List.of(BRANCH_A), DATE);
    }

    @Test
    @DisplayName("üres scope (nincs illeszkedő pénztár): üres lista, DB-hívás nélkül")
    void emptyScope_returnsEmptyWithoutQuery() {
        when(branchRepository.findByCompanyId(COMPANY)).thenReturn(List.of(branch(BRANCH_A, 1)));

        List<DailyBalanceGridRowDto> rows = service.getGrid(COMPANY, DATE, null, 99);

        assertTrue(rows.isEmpty());
        verify(dailyBalanceRepository, never()).findByBranchIdsAndDate(any(), any());
    }

    @Test
    @DisplayName("FR-8: nincs daily_balance rekord az adott napra → üres lista (nem hiba)")
    void noData_returnsEmptyList() {
        when(branchRepository.existsByIdAndCompanyId(BRANCH_A, COMPANY)).thenReturn(true);
        when(dailyBalanceRepository.findByBranchIdsAndDate(List.of(BRANCH_A), DATE))
                .thenReturn(List.of());

        assertTrue(service.getGrid(COMPANY, DATE, BRANCH_A, null).isEmpty());
    }

    @Test
    @DisplayName("valuta-sorrend: a kimenet valutakód szerint rendezett (determinisztikus grid)")
    void rowsSortedByCurrencyCode() {
        when(branchRepository.existsByIdAndCompanyId(BRANCH_A, COMPANY)).thenReturn(true);
        when(dailyBalanceRepository.findByBranchIdsAndDate(List.of(BRANCH_A), DATE)).thenReturn(List.of(
                db(BRANCH_A, "USD", "1", "0", "0", "0", "0", "1", null, "0", "0"),
                db(BRANCH_A, "CHF", "1", "0", "0", "0", "0", "1", null, "0", "0"),
                db(BRANCH_A, "EUR", "1", "0", "0", "0", "0", "1", null, "0", "0")));

        List<DailyBalanceGridRowDto> rows = service.getGrid(COMPANY, DATE, BRANCH_A, null);

        assertEquals(List.of("CHF", "EUR", "USD"),
                rows.stream().map(DailyBalanceGridRowDto::getCurrencyCode).toList());
    }
}
