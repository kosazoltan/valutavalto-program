package hu.puzzleir.valuta.config;

import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class DariusPvCodeInitializerTest {

    private final IntegrationTransportProperties properties = new IntegrationTransportProperties();

    @Test
    void parsesEnvListIntoPvCodesTrimmingWhitespaceAndSkippingEmptyEntries() {
        properties.getDarius().setPvCodesEnv(" COMPANY_A = PV-CODE-A , COMPANY_B=PV-CODE-B ,, ");

        new DariusPvCodeInitializer(properties).init();

        assertThat(properties.getDarius().getPvCodes())
                .containsExactlyInAnyOrderEntriesOf(Map.of(
                        "COMPANY_A", "PV-CODE-A",
                        "COMPANY_B", "PV-CODE-B"));
    }

    @Test
    void ignoresMalformedEntriesAndBlankKeysOrValues() {
        properties.getDarius().setPvCodesEnv("COMPANY_A=,=PV-CODE-A,malformed,COMPANY_B=PV-CODE-B");

        new DariusPvCodeInitializer(properties).init();

        assertThat(properties.getDarius().getPvCodes())
                .containsExactlyInAnyOrderEntriesOf(Map.of("COMPANY_B", "PV-CODE-B"));
    }

    @Test
    void explicitPropertyMapEntriesTakePrecedenceOverEnvList() {
        properties.getDarius().getPvCodes().put("COMPANY_A", "PV-CODE-EXPLICIT");
        properties.getDarius().setPvCodesEnv("COMPANY_A=PV-CODE-ENV");

        new DariusPvCodeInitializer(properties).init();

        assertThat(properties.getDarius().getPvCodes())
                .containsExactlyInAnyOrderEntriesOf(Map.of("COMPANY_A", "PV-CODE-EXPLICIT"));
    }

    @Test
    void nullOrBlankEnvLeavesMapEmpty() {
        properties.getDarius().setPvCodesEnv("  ");

        new DariusPvCodeInitializer(properties).init();

        assertThat(properties.getDarius().getPvCodes()).isEmpty();
    }
}
