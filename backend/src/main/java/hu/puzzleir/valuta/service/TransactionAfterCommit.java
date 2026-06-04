package hu.puzzleir.valuta.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

/**
 * A6 (b8 FR-8): best-effort mellék-műveletek FUTTATÁSA a tranzakció COMMITJA UTÁN.
 *
 * <p>Ha aktív tranzakció-szinkronizáció van, a műveletet {@code afterCommit}-ra regisztrálja:
 * így a profit_log írás CSAK akkor fut le, ha a fő tranzakció (pl. eladás/sztornó) ténylegesen
 * commitált — nincs orphan-tétel rollback esetén. A művelet bármilyen hibája naplózódik, de NEM
 * propagál vissza (a fő tranzakció már lezárult, best-effort jelleg).</p>
 *
 * <p>Aktív szinkronizáció hiányában (pl. unit-teszt) a műveletet azonnal, best-effort módon futtatja.</p>
 */
public final class TransactionAfterCommit {

    private static final Logger log = LoggerFactory.getLogger(TransactionAfterCommit.class);

    private TransactionAfterCommit() {
    }

    public static void run(Runnable action, String description) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    execute(action, description);
                }
            });
        } else {
            execute(action, description);
        }
    }

    private static void execute(Runnable action, String description) {
        try {
            action.run();
        } catch (Exception e) {
            log.warn("afterCommit best-effort művelet sikertelen (a fő tranzakció érintetlen): {}", description, e);
        }
    }
}
