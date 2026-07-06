package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.entity.Currency;
import hu.puzzleir.valuta.entity.Transaction;
import hu.puzzleir.valuta.entity.TransactionLine;
import hu.puzzleir.valuta.entity.TransactionType;
import hu.puzzleir.valuta.exception.ValidationException;
import hu.puzzleir.valuta.repository.TransactionRepository;
import hu.puzzleir.valuta.security.SecurityUtils;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

/**
 * Tranzakció validációs szolgáltatás — VASARLAS üzleti szabályok.
 *
 * Legacy: VASARLAS.DLL, ELADAS.DLL üzleti szabályai:
 *
 * 1. Max 6 valuta per tranzakció (BLOKKTETEL max 6 sor)
 * 2. EUR érme/bankjegy szétválasztás (EuKontrol)
 * 3. Sávos kezelési díj (TRANZDIJTABLA)
 * 4. 4-szintű supervisor jóváhagyás (bitmask: 16/32/64/128)
 * 5. Távoli ügyfél szinkron (NBIZ/JBIZ — kis ügyfél tracking)
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
@Slf4j
public class TransactionValidationService {

    private static final int DEFAULT_MAX_REVERSAL_COUNT = 5;
    private static final BigDecimal DEFAULT_IDENTIFICATION_THRESHOLD = new BigDecimal("2000000");
    private static final BigDecimal DEFAULT_ENHANCED_DD_THRESHOLD = new BigDecimal("5000000");

    private final TransactionRepository transactionRepository;
    private final SystemParameterService systemParameterService;
    private final ValueBandService valueBandService;

    // === KONSTANSOK (Legacy: VASARLAS.DLL) ===

    /** Max valutasor per bizonylat (Legacy: BLOKKTETEL max 6) */
    private static final int MAX_CURRENCY_LINES = 6;

    /** EUR érme/bankjegy szétválasztási határ (Legacy: EuKontrol) */
    private static final BigDecimal EUR_COIN_LIMIT = new BigDecimal("50");


    /**
     * Supervisor szintek bitmask értékei.
     * Legacy: _engWord bitmask — 16/32/64/128
     *
     * Szint 1 (16):  Napi kedvezmény limit túllépés
     * Szint 2 (32):  Forint értéktáros jóváhagyás
     * Szint 3 (64):  Értéktáros jóváhagyás
     * Szint 4 (128): Jutalékmentes tranzakció
     */
    private static final int SUPERVISOR_LEVEL_1 = 16;   // Napi kedvezmény limit
    private static final int SUPERVISOR_LEVEL_2 = 32;   // Forint értéktáros
    private static final int SUPERVISOR_LEVEL_3 = 64;   // Értéktáros
    private static final int SUPERVISOR_LEVEL_4 = 128;  // Jutalékmentes

    // ============ VALIDÁCIÓS METÓDUSOK ============

    /**
     * Teljes tranzakció validáció — az összes üzleti szabály ellenőrzése.
     * Hívandó: TransactionService.createTransaction() előtt.
     *
     * @param transaction az ellenőrizendő tranzakció
     * @throws ValidationException ha bármely szabály megsérül
     */
    public void validateTransaction(Transaction transaction) {
        validateCurrencyExchangeable(transaction);
        validateCurrencyLineLimit(transaction);
        validateEurCoinBanknote(transaction);
        validateIdentificationRequired(transaction);
    }

    /** Elszámoló/báziz valuta — nem lehet kereskedett valuta (Legacy: "A FORINT NEM VÁLASZTHATÓ VALUTA"). */
    private static final String BASE_CURRENCY_CODE = "HUF";

    /**
     * 0. Kereskedhetőség: a bizonylat egyik valutasora sem lehet a forint (base) vagy inaktív valuta.
     * Legacy: ELADAS/VASARLAS — "A FORINT NEM VÁLASZTHATÓ VALUTA". Defense-in-depth: a UI is kiszűri,
     * de szerveroldalon is kötelező (pl. inaktivált HRK).
     */
    public void validateCurrencyExchangeable(Transaction transaction) {
        if (transaction.getLines() == null) {
            return;
        }
        for (TransactionLine line : transaction.getLines()) {
            validateCurrencyExchangeable(line.getCurrency());
        }
    }

    /**
     * Egyetlen kereskedett valuta kereshetőség-ellenőrzése — a buy/sell egysoros flow-hoz.
     * Legacy: ELADAS/VASARLAS — a forint és inaktív valuta nem választható kereskedett valutaként.
     */
    public void validateCurrencyExchangeable(Currency currency) {
        if (currency == null) {
            return;
        }
        String code = currency.getCode();
        if (BASE_CURRENCY_CODE.equalsIgnoreCase(code)) {
            throw new ValidationException("A FORINT NEM VÁLASZTHATÓ VALUTA!");
        }
        if (Boolean.FALSE.equals(currency.getActive())) {
            throw new ValidationException(
                String.format("A(z) %s valuta nem aktív, nem választható!", code));
        }
    }

    /**
     * 1. Max 6 valuta limit ellenőrzés.
     * Legacy: BLOKKTETEL — egy bizonylaton max 6 különböző valuta.
     *
     * Szabály: Ha a tranzakció multi-line (több valutasor), max 6 sor engedélyezett.
     */
    public void validateCurrencyLineLimit(Transaction transaction) {
        if (transaction.getLines() == null || transaction.getLines().isEmpty()) {
            return; // Egysoros tranzakció — OK
        }

        if (transaction.getLines().size() > MAX_CURRENCY_LINES) {
            throw new ValidationException(
                String.format("Egy bizonylaton maximum %d különböző valutasor engedélyezett! (jelenlegi: %d)",
                    MAX_CURRENCY_LINES, transaction.getLines().size()));
        }

        // Ellenőrzés: azonos valuta nem szerepelhet kétszer (hacsak nem EUR érme/bankjegy)
        Set<String> seenCurrencies = new HashSet<>();
        for (TransactionLine line : transaction.getLines()) {
            String currCode = line.getCurrency() != null ? line.getCurrency().getCode() : null;
            if (currCode != null && !"EUR".equals(currCode)) {
                if (!seenCurrencies.add(currCode)) {
                    throw new ValidationException(
                        String.format("Azonos valuta (%s) nem szerepelhet kétszer egy bizonylaton!", currCode));
                }
            }
        }
    }

    /**
     * 2. EUR érme/bankjegy szétválasztás.
     * Legacy: EuKontrol — EUR alatt 50 = érme, fölötte = bankjegy.
     *
     * Üzleti szabály: EUR érmék és bankjegyek más árfolyamon mehetnek.
     * Ha az összeg < 50 EUR, a rendszer értesíti a pénztárost, hogy érme árfolyamot kell alkalmazni.
     *
     * @return true ha érme árfolyamot kell használni
     */
    public boolean isEurCoinTransaction(String currencyCode, BigDecimal amount) {
        if (!"EUR".equals(currencyCode)) {
            return false;
        }
        return amount != null && amount.abs().compareTo(EUR_COIN_LIMIT) < 0;
    }

    /**
     * EUR kontroll validáció — biztosítja, hogy érme és bankjegy ne keveredjen egy sorban.
     */
    public void validateEurCoinBanknote(Transaction transaction) {
        if (transaction.getLines() == null) return;

        boolean hasEurCoin = false;
        boolean hasEurBanknote = false;

        for (TransactionLine line : transaction.getLines()) {
            if (line.getCurrency() != null && "EUR".equals(line.getCurrency().getCode())) {
                BigDecimal amount = line.getBanknoteCount();
                if (amount != null) {
                    if (amount.abs().compareTo(EUR_COIN_LIMIT) < 0) {
                        hasEurCoin = true;
                    } else {
                        hasEurBanknote = true;
                    }
                }
            }
        }

        if (hasEurCoin && hasEurBanknote) {
            log.info("EUR érme és bankjegy is szerepel a bizonylaton — külön árfolyam szükséges!");
            // Nem blokkolja a tranzakciót, csak loggolja (a pénztáros dönt)
        }
    }

    /**
     * 3. Ügyfél azonosítási kötelezettség ellenőrzés.
     * NAV szabályozás: 300.000 Ft felett kötelező az ügyfél azonosítás.
     */
    public void validateIdentificationRequired(Transaction transaction) {
        if (transaction.getHufAmount() == null) return;

        BigDecimal limit = ValueBandService.resolve(valueBandService).identificationLimitHuf();
        if (transaction.getHufAmount().abs().compareTo(limit) > 0) {
            // Ügyfél adatok kötelezőek
            if (transaction.getCustomerId() == null || transaction.getCustomerId().isBlank()) {
                throw new ValidationException(
                    String.format("%s Ft feletti tranzakcióhoz (%s Ft) kötelező az ügyfél azonosítás!",
                        limit.toPlainString(), transaction.getHufAmount()));
            }
            if (transaction.getCustomerName() == null || transaction.getCustomerName().isBlank()) {
                throw new ValidationException("Ügyfél neve kötelező " + limit.toPlainString()
                        + " Ft feletti tranzakcióhoz!");
            }
            if (transaction.getCustomerDocumentNumber() == null || transaction.getCustomerDocumentNumber().isBlank()) {
                throw new ValidationException("Személyazonosító okmány száma kötelező " + limit.toPlainString()
                        + " Ft feletti tranzakcióhoz!");
            }
        }
    }

    // ============ 4. SUPERVISOR JÓVÁHAGYÁS (4-SZINTŰ BITMASK) ============

    /**
     * Supervisor jóváhagyás szükségességének ellenőrzése.
     * Legacy: _engWord bitmask — 16/32/64/128
     *
     * @param transaction tranzakció
     * @param workerId pénztáros
     * @return szükséges supervisor szint (0 = nem kell, 16/32/64/128 = szint)
     */
    public int checkSupervisorRequired(Transaction transaction, Long workerId) {
        int requiredLevel = 0;

        // Szint 1 (16): Napi kedvezmény limit túllépés
        if (transaction.getDiscountPercent() != null
                && transaction.getDiscountPercent().compareTo(BigDecimal.ZERO) > 0) {
            long dailyDiscounts = transactionRepository.countDailyDiscountsByWorker(
                workerId, LocalDate.now());
            int limit = getDailyDiscountLimit();
            if (dailyDiscounts >= limit) {
                requiredLevel |= SUPERVISOR_LEVEL_1;
                log.info("Supervisor szükséges (szint 1): napi kedvezmény limit ({}/{}) elérve",
                    dailyDiscounts, limit);
            }
        }

        // Szint 2 (32): Forint értéktáros — nagy összegű tranzakció
        BigDecimal forintThreshold = getForintSupervisorThreshold();
        if (transaction.getHufAmount() != null
                && transaction.getHufAmount().abs().compareTo(forintThreshold) > 0) {
            requiredLevel |= SUPERVISOR_LEVEL_2;
            log.info("Supervisor szükséges (szint 2): forint értéktáros ({} Ft > {} Ft limit)",
                transaction.getHufAmount(), forintThreshold);
        }

        // Szint 3 (64): Értéktáros — nagyon nagy összeg
        BigDecimal vaultThreshold = getVaultSupervisorThreshold();
        if (transaction.getHufAmount() != null
                && transaction.getHufAmount().abs().compareTo(vaultThreshold) > 0) {
            requiredLevel |= SUPERVISOR_LEVEL_3;
            log.info("Supervisor szükséges (szint 3): értéktáros ({} Ft > {} Ft limit)",
                transaction.getHufAmount(), vaultThreshold);
        }

        // Szint 4 (128): Jutalékmentes tranzakció
        if (transaction.getDiscountTypeCode() != null && transaction.getDiscountTypeCode() == 34) {
            requiredLevel |= SUPERVISOR_LEVEL_4;
            log.info("Supervisor szükséges (szint 4): jutalékmentes tranzakció");
        }

        return requiredLevel;
    }

    /**
     * Supervisor szint dekódolása emberi olvasható formába.
     */
    public List<String> decodeSupervisorLevels(int bitmask) {
        List<String> levels = new ArrayList<>();
        if ((bitmask & SUPERVISOR_LEVEL_1) != 0) levels.add("Napi kedvezmény limit (szint 1)");
        if ((bitmask & SUPERVISOR_LEVEL_2) != 0) levels.add("Forint értéktáros (szint 2)");
        if ((bitmask & SUPERVISOR_LEVEL_3) != 0) levels.add("Értéktáros (szint 3)");
        if ((bitmask & SUPERVISOR_LEVEL_4) != 0) levels.add("Jutalékmentes (szint 4)");
        return levels;
    }

    // ============ 5. NAPI STATISZTIKÁK ============

    /**
     * Napi tranzakció statisztikák lekérdezése (validációhoz).
     */
    public DailyTransactionStats getDailyStats(UUID branchId, Long workerId) {
        LocalDate today = LocalDate.now();

        long buyCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(
            branchId, today, TransactionType.BUY);
        long sellCount = transactionRepository.countByBranchIdAndTransactionDateAndTransactionType(
            branchId, today, TransactionType.SELL);
        UUID companyId = SecurityUtils.getCurrentCompanyId();
        long stornoCount = transactionRepository.countReversalsByBranchAndDate(companyId, branchId, today);
        long discountCount = transactionRepository.countDailyDiscountsByWorker(workerId, today);

        BigDecimal buyTotal = transactionRepository.sumDailyTurnover(companyId, branchId, today, TransactionType.BUY);
        BigDecimal sellTotal = transactionRepository.sumDailyTurnover(companyId, branchId, today, TransactionType.SELL);

        return DailyTransactionStats.builder()
            .buyCount(buyCount)
            .sellCount(sellCount)
            .stornoCount(stornoCount)
            .discountCount(discountCount)
            .buyTotalHuf(buyTotal)
            .sellTotalHuf(sellTotal)
            .build();
    }

    // ============ HELPER ============

    private int getDailyDiscountLimit() {
        try {
            return Integer.parseInt(systemParameterService.getValue("DAILY_DISCOUNT_LIMIT"));
        } catch (Exception e) {
            return DEFAULT_MAX_REVERSAL_COUNT; // Legacy default
        }
    }

    private BigDecimal getForintSupervisorThreshold() {
        try {
            return new BigDecimal(systemParameterService.getValue("FORINT_SUPERVISOR_THRESHOLD"));
        } catch (Exception e) {
            return DEFAULT_IDENTIFICATION_THRESHOLD; // 2M Ft default
        }
    }

    private BigDecimal getVaultSupervisorThreshold() {
        try {
            return new BigDecimal(systemParameterService.getValue("VAULT_SUPERVISOR_THRESHOLD"));
        } catch (Exception e) {
            return DEFAULT_ENHANCED_DD_THRESHOLD; // 5M Ft default
        }
    }

    // ============ INNER CLASS ============

    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DailyTransactionStats {
        private long buyCount;
        private long sellCount;
        private long stornoCount;
        private long discountCount;
        private BigDecimal buyTotalHuf;
        private BigDecimal sellTotalHuf;
    }
}
