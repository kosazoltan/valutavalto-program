package hu.puzzleir.valuta.service.led;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * LED driver factory — a megfelelő driver példányt adja vissza típus alapján.
 *
 * Legacy: A Delphi rendszerben minden driver külön DLL volt (METRO.DLL, TRUELIGHT.DLL, stb.).
 * Az új rendszerben egyetlen factory kezeli az összes driver típust.
 *
 * Használat:
 * ```java
 * LedDriverProtocol driver = ledDriverFactory.getDriver(LedDriverType.METRO_S1);
 * driver.connect("COM3:9600");
 * driver.updateRateBoard(lines);
 * ```
 */
@Component
@Slf4j
public class LedDriverFactory {

    /** Aktív driver példányok cache-elése (branch-enként lehet más) */
    private final Map<String, LedDriverProtocol> activeDrivers = new ConcurrentHashMap<>();

    @Value("${led.driver.simulated-success-enabled:false}")
    private boolean simulatedSuccessEnabled;

    /**
     * Driver példány lekérése típus alapján.
     * Minden hívás ÚJ példányt ad (nem cache-elt).
     */
    public LedDriverProtocol createDriver(LedDriverType type) {
        log.info("LED driver létrehozás: {}", type);

        return switch (type) {
            // Soros port alapú driverek — jelenleg mind a GenericSerial-re mappolnak
            // Éles implementációnál minden gyártónak saját class kell
            case METRO_S1, METRO_S2, TRUELIGHT, TOPICA, SIGNTEC,
                LEDMAN, DELTA, GENERIC_SERIAL -> {
                    log.debug("Soros port driver: {} → GenericSerialLedDriver", type);
                yield new GenericSerialLedDriver(simulatedSuccessEnabled);
            }

            // Hálózati driverek — placeholder, élesben gyártó-specifikus protokoll
            case NOVASTAR, LINSN, COLORLIGHT, HUIDU, KYSTAR,
                 MAGNIMAGE, DBSTAR, XIXUN, ONBON -> {
                log.debug("Hálózati driver: {} → GenericSerialLedDriver placeholder, simulatedSuccessEnabled={}",
                        type, simulatedSuccessEnabled);
                yield new GenericSerialLedDriver(simulatedSuccessEnabled);
            }

            // Virtuális / web
            case VIRTUAL, WEB_DISPLAY -> {
                log.debug("Virtuális driver: {}", type);
                yield new GenericSerialLedDriver(simulatedSuccessEnabled);
            }
        };
    }

    /**
     * Driver lekérése vagy létrehozása egy adott branch-hez.
     */
    public LedDriverProtocol getOrCreate(String branchKey, LedDriverType type) {
        return activeDrivers.computeIfAbsent(branchKey, k -> {
            LedDriverProtocol driver = createDriver(type);
            log.info("Driver regisztrálva: branch={}, type={}", branchKey, type);
            return driver;
        });
    }

    /**
     * Branch driver leállítása.
     */
    public void shutdownDriver(String branchKey) {
        LedDriverProtocol driver = activeDrivers.remove(branchKey);
        if (driver != null) {
            driver.disconnect();
            log.info("Driver leállítva: branch={}", branchKey);
        }
    }

    /**
     * Összes aktív driver leállítása.
     */
    public void shutdownAll() {
        activeDrivers.forEach((key, driver) -> {
            driver.disconnect();
            log.info("Driver leállítva: {}", key);
        });
        activeDrivers.clear();
    }

    /**
     * Aktív driverek száma.
     */
    public int getActiveCount() {
        return activeDrivers.size();
    }
}
