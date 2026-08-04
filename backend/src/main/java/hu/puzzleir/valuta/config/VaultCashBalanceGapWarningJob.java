package hu.puzzleir.valuta.config;

import hu.puzzleir.valuta.repository.CashBalanceRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * FKH-029 FR-3: az AKTÍV értéktári branch-ek hiányzó {@code cash_balance} sorainak
 * FIGYELMEZTETŐ monitorozása — a {@link TransferDedupStuckRecordWarningJob} mintájára.
 *
 * <p><b>Háttér:</b> a Batch3-B mirror-architektúra a vault-mozgásokat a {@code cash_balance}-on
 * könyveli, ezért minden aktív Értéktárnak léteznie kell a sorának minden aktív valutára
 * (V369 invariáns-fordulat, V371 hatókör-teljesítés). A 2026-08-04-i élő audit szerint a
 * hiány két és fél hónapig észrevétlen maradt: a BR075 Békéscsaba Értéktár 10 átadása
 * 2026-05-26 óta PENDING volt, mert a jóváhagyás {@code ValidationException}-be futott, és
 * semmi nem jelezte rendszerszinten a hiányt.</p>
 *
 * <p><b>Ez a job KIZÁRÓLAG riaszt</b> ({@code log.warn}), SEMMIT nem módosít és nem hoz létre.
 * A tényleges pótlást a V371 migráció (visszamenőleg), illetve a
 * {@code TransferService.resolveCashBalanceForUpdate} lazy get-or-create ága (runtime) végzi.
 * Ha nincs hiányzó sor, a job CSENDES — nem logol.</p>
 *
 * <p>Rendszerszintű (nincs request-scope JWT), ezért cégfüggetlen: a riasztás a cég kódját is
 * tartalmazza.</p>
 */
@Component
@Slf4j
public class VaultCashBalanceGapWarningJob {

    private final CashBalanceRepository cashBalanceRepository;

    public VaultCashBalanceGapWarningJob(CashBalanceRepository cashBalanceRepository) {
        this.cashBalanceRepository = cashBalanceRepository;
    }

    /** Alapértelmezés: 6 óránként (21 600 000 ms) — read-only, nem terheli a prodot. */
    @Scheduled(fixedDelayString = "${app.vault-cash-balance.gap-check-ms:21600000}")
    public void warnMissingVaultCashBalanceRows() {
        List<Object[]> gaps = cashBalanceRepository.findVaultBranchesWithMissingCashBalance();
        if (gaps == null || gaps.isEmpty()) {
            // Nincs hiány — szándékosan csendes (nem szemeteli a logot).
            return;
        }
        for (Object[] row : gaps) {
            String companyCode = row.length > 0 && row[0] != null ? row[0].toString() : "?";
            String branchCode = row.length > 1 && row[1] != null ? row[1].toString() : "?";
            String missingCurrencies = row.length > 2 && row[2] != null ? row[2].toString() : "?";
            String missingCount = row.length > 3 && row[3] != null ? row[3].toString() : "?";
            log.warn("FKH-029: HIÁNYZÓ értéktári cash_balance sor — cég: {}, branch: {}, "
                            + "{} valuta érintett: {}. Az átadás-jóváhagyás ezekre a valutákra "
                            + "hibára futhat. A V371 migráció a meglévő Értéktárakat pótolta; "
                            + "új hiány új Értéktárra vagy újonnan aktivált valutára utal.",
                    companyCode, branchCode, missingCount, missingCurrencies);
        }
    }
}
