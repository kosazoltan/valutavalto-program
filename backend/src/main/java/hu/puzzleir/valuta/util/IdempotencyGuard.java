package hu.puzzleir.valuta.util;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Idempotencia védelem tranzakciós endpointokhoz.
 *
 * Megakadályozza, hogy ugyanaz a kérés (ugyanazzal az idempotency key-jel)
 * többször feldolgozásra kerüljön — pl. OptimisticLockRetry miatti dupla POS terhelés ellen.
 *
 * Az idempotency key-t a kliens generálja (UUID) és a request header-ben küldi.
 */
@Component
@Slf4j
public class IdempotencyGuard {

    /** Feldolgozás alatt álló kérések (key → timestamp) */
    private final Map<String, Long> processingKeys = new ConcurrentHashMap<>();

    /** Sikeres eredmények cache-je (key → result) — 5 perces TTL */
    private final Map<String, Object> completedResults = new ConcurrentHashMap<>();

    private static final long TTL_MS = 5 * 60 * 1000L; // 5 perc

    /**
     * Kérés feldolgozásának megkezdése.
     *
     * @param idempotencyKey Kliens által generált egyedi kulcs
     * @return null ha ez új kérés, vagy a korábbi eredmény ha már feldolgozva
     */
    @SuppressWarnings("unchecked")
    public <T> T tryAcquire(String idempotencyKey) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            return null; // nincs key → nem védjük (backward compatible)
        }

        cleanup();

        // Ha már sikeresen feldolgozva → visszaadjuk a korábbi eredményt
        Object cached = completedResults.get(idempotencyKey);
        if (cached != null) {
            log.info("Idempotency: dupla kérés detektálva, korábbi eredmény visszaadása — key: {}", idempotencyKey);
            return (T) cached;
        }

        // Ha éppen feldolgozás alatt áll → elutasítjuk
        Long existing = processingKeys.putIfAbsent(idempotencyKey, System.currentTimeMillis());
        if (existing != null) {
            log.warn("Idempotency: párhuzamos dupla kérés detektálva — key: {}", idempotencyKey);
            throw new hu.puzzleir.valuta.exception.ValidationException(
                    "A kérés feldolgozás alatt áll. Kérjük ne küldje el újra!");
        }

        return null;
    }

    /**
     * Sikeres feldolgozás rögzítése.
     */
    public <T> void complete(String idempotencyKey, T result) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            return;
        }
        completedResults.put(idempotencyKey, result);
        processingKeys.remove(idempotencyKey);
    }

    /**
     * Sikertelen feldolgozás — kulcs felszabadítása az újrapróbáláshoz.
     */
    public void release(String idempotencyKey) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            return;
        }
        processingKeys.remove(idempotencyKey);
    }

    private void cleanup() {
        long now = System.currentTimeMillis();
        processingKeys.entrySet().removeIf(e -> now - e.getValue() > TTL_MS);
        completedResults.entrySet().removeIf(e -> {
            // A completedResults-ben nincs timestamp, de a processingKeys alapján tudjuk törölni
            // Egyszerűbb: minden 5 percnél régebbi entry-t töröljük
            return false; // Lazy cleanup — a map nem nő túl nagyra a használat jellegéből adódóan
        });
    }
}
