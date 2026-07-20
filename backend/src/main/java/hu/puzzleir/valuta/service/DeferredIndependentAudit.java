package hu.puzzleir.valuta.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * Rollbackot is túlélő audit írásának futtatása a hívó tranzakció teljes lezárása után.
 *
 * <p>Az {@code afterCompletion} időzítés biztosítja, hogy a független audit tranzakció
 * csak a hívó tranzakció lockjainak elengedése után induljon. Aktív tranzakció-
 * szinkronizáció hiányában az írás azonnal, best-effort módon fut.</p>
 */
public final class DeferredIndependentAudit {

    private static final Logger log = LoggerFactory.getLogger(DeferredIndependentAudit.class);

    private DeferredIndependentAudit() {
    }

    public static void run(Runnable auditWrite, String description) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCompletion(int status) {
                    execute(auditWrite, description);
                }
            });
        } else {
            execute(auditWrite, description);
        }
    }

    private static void execute(Runnable auditWrite, String description) {
        try {
            auditWrite.run();
        } catch (Exception e) {
            log.error("Független audit írás sikertelen a tranzakció lezárása után: {}", description, e);
        }
    }
}
