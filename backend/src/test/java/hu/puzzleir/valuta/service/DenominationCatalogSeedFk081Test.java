package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Branch;
import hu.puzzleir.valuta.entity.Company;
import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Denomination;
import hu.puzzleir.valuta.entity.DenominationAllowed;
import hu.puzzleir.valuta.entity.DenominationType;
import hu.puzzleir.valuta.repository.BranchRepository;
import hu.puzzleir.valuta.repository.CompanyRepository;
import hu.puzzleir.valuta.repository.CurrencyRepository;
import hu.puzzleir.valuta.repository.DenominationAllowedRepository;
import hu.puzzleir.valuta.repository.DenominationCountRepository;
import hu.puzzleir.valuta.repository.DenominationRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockedStatic;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * FK-081: új cég (a V376/V379 migrációk UTÁN létrehozott tenant) üres
 * `denomination_allowed` katalógussal indul — ezt a fiók-inicializálás pótolja.
 *
 * <p><b>A hibalánc, amit ez zár be</b> (FK-080 round-2 ACCEPTED-RISK):
 * a katalógust eddig KIZÁRÓLAG migráció töltötte (V376 deviza-seed, V379 HUF-seed),
 * és az `INSERT ... SELECT` a futása pillanatában létező cégekre töltött. Egy később
 * felvett cég katalógusa üres marad → {@code initializeBranchDenominations} 0 címletsort
 * hoz létre → a záró-varázsló (VV-VALID-006) és a mentés-gát (VV-VALID-007) MINDEN
 * kombinációt elutasít, a HUF-ot is. Az FK-080 előtt a HUF-zárás még átment (a HUF ki
 * volt véve a validáció alól); az FK-080 (V379) óta az NFR-6 garanciát ADAT biztosítja,
 * ezért a robbanási sugár a törvényes HUF-zárásra is kiterjedt.
 *
 * <p><b>Miért itt a javítás:</b> a repóban NINCS alkalmazás-szintű tenant-cég létrehozás
 * ({@code CompanyAdminService} csak `updateCompany`-t tud; az `OwnCompany` az `own_company`
 * táblát kezeli, ami más). Az FK-081 ticket „company-creation seed” javaslata ezért nem
 * valósítható meg úgy, ahogy le van írva — a ticket elfogadási kritériuma viszont
 * pontosan ez: „újonnan létrehozott cég + új iroda esetén az initializeBranchDenominations
 * a teljes törvényes katalógust létrehozza”. A seed ezért a fiók-inicializálás elejére kerül.
 */
@ExtendWith(MockitoExtension.class)
class DenominationCatalogSeedFk081Test {

    @Mock private DenominationRepository denominationRepository;
    @Mock private DenominationCountRepository denominationCountRepository;
    @Mock private CurrencyRepository currencyRepository;
    @Mock private CompanyRepository companyRepository;
    @Mock private BranchRepository branchRepository;
    @Mock private DenominationAllowedRepository denominationAllowedRepository;
    @InjectMocks private DenominationService denominationService;

    private static final UUID NEW_COMPANY_ID = UUID.randomUUID();
    private static final UUID OTHER_COMPANY_ID = UUID.randomUUID();
    private static final UUID BRANCH_ID = UUID.randomUUID();

    private static DenominationAllowed catalogRow(String code, String faceValue, DenominationType type) {
        Currency currency = new Currency();
        currency.setId((long) (code.hashCode() & 0x7fffffff));
        currency.setCode(code);
        currency.setActive(true);
        return DenominationAllowed.builder()
                .currency(currency)
                .faceValue(new BigDecimal(faceValue))
                .denominationType(type)
                .active(true)
                .build();
    }

    private void arrangeCompanyAndBranch() {
        Company company = new Company();
        company.setId(NEW_COMPANY_ID);
        Branch branch = new Branch();
        branch.setId(BRANCH_ID);
        branch.setName("Új cég új irodája");
        when(companyRepository.findById(NEW_COMPANY_ID)).thenReturn(Optional.of(company));
        when(branchRepository.findById(BRANCH_ID)).thenReturn(Optional.of(branch));
    }

    @Test
    @DisplayName("FK-081: ÜRES katalógusú új cégnél a fiók-init előbb seed-eli a katalógust, majd abból hoz létre címletsorokat")
    void emptyCatalogIsSeededBeforeBranchInitialisation() {
        arrangeCompanyAndBranch();

        // 1. hívás: üres katalógus (a migrációk után létrehozott cég).
        // 2. hívás (a seed után): a teljes törvényes katalógus.
        List<DenominationAllowed> seeded = List.of(
                catalogRow("HUF", "20000", DenominationType.BANKNOTE),
                catalogRow("HUF", "200", DenominationType.COIN),
                catalogRow("EUR", "2", DenominationType.COIN));
        when(denominationAllowedRepository.findActiveByCompanyId(NEW_COMPANY_ID))
                .thenReturn(List.of())
                .thenReturn(seeded);
        when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(NEW_COMPANY_ID);

            denominationService.initializeBranchDenominations(BRANCH_ID);
        }

        // A seed lefutott a hívó cég azonosítójára...
        verify(denominationAllowedRepository).seedCatalogForCompany(NEW_COMPANY_ID);
        // ...MÉG a katalógus újraolvasása ELŐTT (különben megint üreset olvasnánk).
        var order = inOrder(denominationAllowedRepository);
        order.verify(denominationAllowedRepository).findActiveByCompanyId(NEW_COMPANY_ID);
        order.verify(denominationAllowedRepository).seedCatalogForCompany(NEW_COMPANY_ID);
        order.verify(denominationAllowedRepository).findActiveByCompanyId(NEW_COMPANY_ID);

        // És a fiók MEGKAPTA a címletsorokat — nem maradt 0 sorral.
        ArgumentCaptor<Denomination> saved = ArgumentCaptor.forClass(Denomination.class);
        verify(denominationRepository, org.mockito.Mockito.times(3)).save(saved.capture());
        assertThat(saved.getAllValues())
                .extracting(Denomination::getDenominationType)
                .containsExactlyInAnyOrder(
                        DenominationType.BANKNOTE, DenominationType.COIN, DenominationType.COIN);
    }

    @Test
    @DisplayName("FK-081: NEM üres katalógusnál nincs seed — a meglévő négy tenant útja változatlan")
    void existingCatalogIsNeverReseeded() {
        arrangeCompanyAndBranch();

        when(denominationAllowedRepository.findActiveByCompanyId(NEW_COMPANY_ID))
                .thenReturn(List.of(catalogRow("HUF", "5000", DenominationType.BANKNOTE)));
        when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(NEW_COMPANY_ID);

            denominationService.initializeBranchDenominations(BRANCH_ID);
        }

        // A négy stabil tenantra a seed SOHA nem fut le (idempotencia + nulla kockázat).
        verify(denominationAllowedRepository, never()).seedCatalogForCompany(any());
        verify(denominationAllowedRepository, org.mockito.Mockito.times(1))
                .findActiveByCompanyId(NEW_COMPANY_ID);
    }

    @Test
    @DisplayName("FK-081 multi-tenant: a seed KIZÁRÓLAG a hívó cég azonosítójára fut — idegen companyId-ra soha")
    void seedIsStrictlyScopedToTheCallingTenant() {
        arrangeCompanyAndBranch();

        when(denominationAllowedRepository.findActiveByCompanyId(NEW_COMPANY_ID))
                .thenReturn(List.of())
                .thenReturn(List.of(catalogRow("HUF", "1000", DenominationType.BANKNOTE)));
        when(denominationRepository.findByBranchIdAndCurrencyIdAndFaceValue(any(), any(), any()))
                .thenReturn(Optional.empty());

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(NEW_COMPANY_ID);

            denominationService.initializeBranchDenominations(BRANCH_ID);
        }

        verify(denominationAllowedRepository).seedCatalogForCompany(NEW_COMPANY_ID);
        verify(denominationAllowedRepository, never()).seedCatalogForCompany(eq(OTHER_COMPANY_ID));
        verify(denominationAllowedRepository, never()).findActiveByCompanyId(eq(OTHER_COMPANY_ID));
    }

    @Test
    @DisplayName("FK-081: ha a seed után is üres a katalógus (nincs mintaadat), a fiók-init NEM dob — 0 sor, de nincs branch-létrehozás-törés")
    void stillEmptyAfterSeedDoesNotBreakBranchCreation() {
        arrangeCompanyAndBranch();

        // Szélsőérték: teljesen üres DB (nincs honnan másolni) — a seed 0 sort ad.
        when(denominationAllowedRepository.findActiveByCompanyId(NEW_COMPANY_ID))
                .thenReturn(List.of())
                .thenReturn(List.of());

        try (MockedStatic<SecurityUtils> su = mockStatic(SecurityUtils.class)) {
            su.when(SecurityUtils::getCurrentCompanyId).thenReturn(NEW_COMPANY_ID);

            // A branch-létrehozás kiegészítő lépése nem bukhat el emiatt (REQUIRES_NEW).
            denominationService.initializeBranchDenominations(BRANCH_ID);
        }

        verify(denominationAllowedRepository).seedCatalogForCompany(NEW_COMPANY_ID);
        verify(denominationRepository, never()).save(any());
    }
}
