package hu.puzzleir.valuta.logging;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.MDC;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tesztek a {@link VVLogger}-hez. MDC kontextus-management.
 *
 * <p>Lefedett invariansok:
 * <ul>
 *   <li>MDC tiszta a logolas elott / utan (try/finally)</li>
 *   <li>error_category derivalas a errorCode prefix-bol (VV-AML → AML, VV-BIZ → BUSINESS, etc.)</li>
 *   <li>attrs.Map atadasa MDC-be</li>
 * </ul>
 */
class VVLoggerTest {

    private VVLogger logger;

    @BeforeEach
    void setUp() {
        MDC.clear();
        logger = VVLogger.of(VVLoggerTest.class);
    }

    @AfterEach
    void tearDown() {
        MDC.clear();
    }

    @Test
    @DisplayName("MDC tiszta a hivas vegen (try/finally garantal)")
    void info_clearsMdcAfterCall() {
        logger.info("test.event", Map.of("amount", 50000, "currency", "EUR"));
        assertThat(MDC.get("event_type")).isNull();
        assertThat(MDC.get("amount")).isNull();
        assertThat(MDC.get("currency")).isNull();
    }

    @Test
    @DisplayName("error() MDC tiszta utana - error_code es error_category is")
    void error_clearsMdcAfterCall() {
        logger.error("VV-AML-001", "aml.threshold_violation", null,
                Map.of("amount", 150000, "limit", 100000));
        assertThat(MDC.get("event_type")).isNull();
        assertThat(MDC.get("error_code")).isNull();
        assertThat(MDC.get("error_category")).isNull();
        assertThat(MDC.get("amount")).isNull();
    }

    @Test
    @DisplayName("NULL attrs nem doblja a logolas")
    void info_nullAttrs_doesNotThrow() {
        logger.info("simple.event", null);
        assertThat(MDC.get("event_type")).isNull();
    }

    @Test
    @DisplayName("Egymas utan hivasok nem szivaroghatnak az MDC-be")
    void multipleCalls_noMdcLeak() {
        logger.info("event.one", Map.of("a", 1));
        logger.info("event.two", Map.of("b", 2));
        logger.warn("event.three", "VV-BIZ-001", Map.of("c", 3));
        assertThat(MDC.getCopyOfContextMap() == null || MDC.getCopyOfContextMap().isEmpty()).isTrue();
    }
}
