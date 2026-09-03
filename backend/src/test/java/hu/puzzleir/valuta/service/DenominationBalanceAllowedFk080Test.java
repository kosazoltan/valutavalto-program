package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.dto.denomination.DenominationQuantityUpdateRequestDto;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.DenominationCategory;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.exception.ResourceNotFoundException;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CashBalanceRepository;
import hu.puzzleir.valuta.repository.CashRegisterDeviceRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.CurrencyStockRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.repository.DenominationBalanceRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.repository.ShipmentHandlingFeeRepository;
import hu.puzzleir.valuta.repository.VatSupplyStockRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-080 FR-5: a címletezés MENTÉSI útja a `denomination_allowed` katalógus ellen validál.
 *
 * <p>A záró-varázsló auto-create ága (FR-3, VV-VALID-006) csak akkor véd, ha a
 * denomination-sor még nem létezik. A V320/V328 backfill viszont MINDEN aktív fiókra
 * beszúrta a teljes jegybanki katalógust, ezért a tiltott érme-sorok (RSD 10 érme,
 * HUF 1/2 forint) MÁR OTT VANNAK — rájuk az auto-create gát soha nem fut le.
 * Ez a gát (VV-VALID-007) zárja be azt a rést.
 *
 * <p>Két, szándékosan KÜLÖNBÖZŐ elutasítás — a különbségtétel maga is szerződés:
 * <ul>
 *   <li>cross-tenant vagy nem létező sor → 404 {@link ResourceNotFoundException},
 *       hogy más cég azonosítójának a LÉTEZÉSE se szivárogjon ki (IDOR);</li>
 *   <li>saját, de tiltott/inaktív sor → 400 {@link ValidationException} VV-VALID-007.</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
class DenominationBalanceAllowedFk080Test {

    @Mock private DenominationBalanceRepository balanceRepository;
    @Mock private DenominationRepository denominationRepository;
    @Mock private CashRegisterDeviceRepository cashRegisterDeviceRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private CashBalanceRepository cashBalanceRepository;
    @Mock private DenominationAllowedRepository denominationAllowedRepository;
    @Mock private ShipmentHandlingFeeRepository shipmentHandlingFeeRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private VatSupplyStockRepository vatSupplyStockRepository;
    @Mock private CurrencyStockRepository currencyStockRepository;

    private final UUID companyId = UUID.randomUUID();
    private final UUID otherCompanyId = UUID.randomUUID();
    private final UUID branchId = UUID.randomUUID();

    private DenominationBalanceService service() {
        return new DenominationBalanceService(
                balanceRepository, denominationRepository, cashRegisterDeviceRepository, branchRepository,
                cashBalanceRepository, denominationAllowedRepository,
                shipmentHandlingFeeRepository, currencyRepository, vatSupplyStockRepository,
                currencyStockRepository);
    }

    private Denomination row(long id, UUID owner, String code, long currencyId,
                             String faceValue, DenominationType type, boolean active) {
        return Denomination.builder()
                .id(id)
                .company(Company.builder().id(owner).build())
                .currency(Currency.builder().id(currencyId).code(code).build())
                .faceValue(new BigDecimal(faceValue))
                .denominationType(type)
                .active(active)
                .build();
    }

    private static DenominationAllowed allowed(String faceValue, DenominationType type) {
        return DenominationAllowed.builder()
                .faceValue(new BigDecimal(faceValue))
                .denominationType(type)
                .active(true)
                .build();
    }

    @Test
    @DisplayName("FR-5a: tiltott ERME sorra (RSD 10) nem menthető darabszám → VV-VALID-007, nincs mentés")
    void forbiddenCoinRowRejectedWithVvValid007() {
        Denomination rsdCoin = row(41L, companyId, "RSD", 12L, "10", DenominationType.COIN, true);
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(denominationRepository.findById(41L)).thenReturn(Optional.of(rsdCoin));
        // A katalogus RSD 10-et BANKJEGY-kent engedelyezi (nem-EUR/HUF erme nem letezik),
        // ezert a COIN-kent tarolt sor tipus-eltéres miatt elutasitando.
        when(denominationAllowedRepository.findActiveAllowed(companyId, 12L, new BigDecimal("10")))
                .thenReturn(Optional.of(allowed("10", DenominationType.BANKNOTE)));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service().updateQuantity(branchId, 41L, 7))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-007")
                    .hasMessageContaining("RSD 10")
                    .hasMessageContaining("COIN");
        }

        verify(balanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FR-5b: bevont HUF 1 forintos sorra (nincs katalógus-sora) → VV-VALID-007")
    void withdrawnHufCoinRowRejected() {
        Denomination hufOne = row(7L, companyId, "HUF", 1L, "1", DenominationType.COIN, true);
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(denominationRepository.findById(7L)).thenReturn(Optional.of(hufOne));
        when(denominationAllowedRepository.findActiveAllowed(companyId, 1L, BigDecimal.ONE))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service().updateQuantity(branchId, 7L, 3))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-007")
                    .hasMessageContaining("HUF 1");
        }

        verify(balanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FR-5c: a V380 által INAKTIVÁLT sorra sem menthető darabszám → VV-VALID-007")
    void inactiveRowRejected() {
        // A katalogus szerint rendben lenne, de a sor maga inaktiv (V380 kapcsolta le).
        Denomination deactivated = row(9L, companyId, "HUF", 1L, "2", DenominationType.COIN, false);
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(denominationRepository.findById(9L)).thenReturn(Optional.of(deactivated));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service().updateQuantity(branchId, 9L, 1))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-007");
        }

        // Az inaktiv sor eseten a katalogus-lekerdezes MAR NEM is szukseges (rovidre zar).
        verify(denominationAllowedRepository, never()).findActiveAllowed(any(), any(), any());
        verify(balanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FR-5d IDOR: MÁS cég denomination-sora → 404 (nem 400) — az idegen id létezése sem szivárog ki")
    void crossTenantRowYields404NotValidationError() {
        Denomination foreign = row(100L, otherCompanyId, "EUR", 4L, "500", DenominationType.BANKNOTE, true);
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(denominationRepository.findById(100L)).thenReturn(Optional.of(foreign));

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service().updateQuantity(branchId, 100L, 1))
                    .isInstanceOf(ResourceNotFoundException.class)
                    .hasMessageContaining("Címlet nem található");
        }

        // A tenant-gat ELOBB fut, mint az uzleti gat: a katalogust meg meg sem kerdezzuk.
        verify(denominationAllowedRepository, never()).findActiveAllowed(any(), any(), any());
        verify(balanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FR-5e: engedélyezett sor (HUF 100 érme) változatlanul mentődik — a gát nem regresszió")
    void allowedRowStillSaves() {
        Denomination hufCoin = row(11L, companyId, "HUF", 1L, "100", DenominationType.COIN, true);
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        when(denominationRepository.findById(11L)).thenReturn(Optional.of(hufCoin));
        when(denominationAllowedRepository.findActiveAllowed(companyId, 1L, new BigDecimal("100")))
                .thenReturn(Optional.of(allowed("100", DenominationType.COIN)));
        when(balanceRepository.findByCashDeskIdAndDenominationIdAndCategory(
                branchId, 11L, DenominationCategory.EVENING))
                .thenReturn(Optional.empty());
        when(balanceRepository.save(any())).thenAnswer(inv -> {
            hu.puzzleir.valuta.entity.DenominationBalance saved = inv.getArgument(0);
            saved.setId(UUID.randomUUID());
            return saved;
        });

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatCode(() -> service().updateQuantity(branchId, 11L, 12))
                    .doesNotThrowAnyException();
        }

        verify(balanceRepository).save(any());
    }

    @Test
    @DisplayName("FR-5f: a gát a batchUpdate úton is fut — egyetlen tiltott tétel az egész köteget elutasítja")
    void gateAlsoAppliesToBatchUpdate() {
        Denomination rsdCoin = row(41L, companyId, "RSD", 12L, "10", DenominationType.COIN, true);
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        lenient().when(denominationRepository.findById(41L)).thenReturn(Optional.of(rsdCoin));
        lenient().when(denominationAllowedRepository.findActiveAllowed(companyId, 12L, new BigDecimal("10")))
                .thenReturn(Optional.of(allowed("10", DenominationType.BANKNOTE)));

        DenominationQuantityUpdateRequestDto update = new DenominationQuantityUpdateRequestDto();
        update.setDenominationId("41");
        update.setQuantity(5);

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service().batchUpdate(
                    branchId, List.of(update), DenominationCategory.HANDLING_FEE))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-007");
        }

        verify(balanceRepository, never()).save(any());
    }

    @Test
    @DisplayName("FR-5g (addendum A-4 + round-2 ITEM 2): a 2-arg batchUpdate(branchId, updates) belépési pont is gát alatt van — tiltott tételre VV-VALID-007, nincs mentés")
    void twoArgBatchUpdateOverloadAlsoRejectsForbiddenItem() {
        // A 2-argumentumos overload EVENING-kategorival delegal a 3-arg-ra, amely a
        // 4-arg updateQuantity-n keresztul futtatja a requireAllowedDenomination gatot.
        // A regi teszt CSAK a 3-arg overloadot jaratta nem-ures tiltott tetellel, igy
        // ez a publikus belepesi pont bizonyitatlan volt — addendum A-4 kotove tette.
        Denomination rsdCoin = row(42L, companyId, "RSD", 12L, "10", DenominationType.COIN, true);
        when(branchRepository.existsByIdAndCompanyId(branchId, companyId)).thenReturn(true);
        lenient().when(denominationRepository.findById(42L)).thenReturn(Optional.of(rsdCoin));
        lenient().when(denominationAllowedRepository.findActiveAllowed(companyId, 12L, new BigDecimal("10")))
                .thenReturn(Optional.of(allowed("10", DenominationType.BANKNOTE)));

        DenominationQuantityUpdateRequestDto update = new DenominationQuantityUpdateRequestDto();
        update.setDenominationId("42");
        update.setQuantity(9);

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(companyId);

            assertThatThrownBy(() -> service().batchUpdate(branchId, List.of(update)))
                    .isInstanceOf(ValidationException.class)
                    .hasMessageContaining("VV-VALID-007");
        }

        verify(balanceRepository, never()).save(any());
    }
}
