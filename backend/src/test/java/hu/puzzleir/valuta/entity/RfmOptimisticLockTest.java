package hu.puzzleir.valuta.entity;

import jakarta.persistence.Version;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Field;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * RFM optimista zárolás (@Version) leképezés-teszt (VV-ELVI v2 7.3).
 *
 * <p>Az árfolyam-szerkesztő (RFM) entitásoknak {@code @Version} mezővel kell
 * rendelkezniük, hogy két felhasználó egyidejű szerkesztése esetén a második
 * mentés OptimisticLockException-t kapjon (lost update védelem) a néma
 * felülírás helyett. A locking szemantikát a Hibernate garantálja, ha a
 * {@code @Version} leképezés jelen van; ez a teszt azt a leképezést védi a
 * véletlen eltávolítástól. A DB-szintű {@code version} oszlop meglétét a
 * V245 Flyway migration assertálja éles PostgreSQL-en.
 */
class RfmOptimisticLockTest {

    private static Optional<Field> findVersionField(Class<?> type) {
        for (Field f : type.getDeclaredFields()) {
            if (f.isAnnotationPresent(Version.class)) {
                return Optional.of(f);
            }
        }
        return Optional.empty();
    }

    private void assertHasLongVersion(Class<?> entity) {
        Optional<Field> version = findVersionField(entity);
        assertTrue(version.isPresent(),
                entity.getSimpleName() + " entitásnak kell egy @Version mezőt tartalmaznia (optimista zárolás)");
        Class<?> t = version.get().getType();
        assertTrue(t == Long.class || t == long.class,
                entity.getSimpleName() + " @Version mezője Long/long típusú kell legyen, de: " + t.getName());
    }

    @Test
    @DisplayName("RateTemplate-nek van @Version Long mezője")
    void rateTemplateHasVersion() {
        assertHasLongVersion(RateTemplate.class);
    }

    @Test
    @DisplayName("ExchangeRateMaster-nek van @Version Long mezője")
    void exchangeRateMasterHasVersion() {
        assertHasLongVersion(ExchangeRateMaster.class);
    }

    @Test
    @DisplayName("RatePublication-nek van @Version Long mezője")
    void ratePublicationHasVersion() {
        assertHasLongVersion(RatePublication.class);
    }

    @Test
    @DisplayName("Mindhárom RFM entitásnak pontosan egy @Version mezője van")
    void exactlyOneVersionFieldEach() {
        for (Class<?> entity : new Class<?>[]{RateTemplate.class, ExchangeRateMaster.class, RatePublication.class}) {
            long count = java.util.Arrays.stream(entity.getDeclaredFields())
                    .filter(f -> f.isAnnotationPresent(Version.class))
                    .count();
            assertEquals(1L, count,
                    entity.getSimpleName() + " pontosan 1 @Version mezőt tartalmazhat, de: " + count);
        }
    }
}
