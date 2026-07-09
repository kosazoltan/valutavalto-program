package hu.puzzleir.valuta.service;

import hu.puzzleir.valuta.exception.BusinessException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class MnbRateQueryClientTest {

    private final MnbRateQueryClient client = new MnbRateQueryClient(5000);

    @Test
    @DisplayName("MNB XML parse: vesszős tizedes és unit=100 normalizálás, hibás Rate elemek kihagyása")
    void parseMnbXml_normalizesUnitAndSkipsInvalidRateElements() {
        String xml = """
                <MNBCurrentExchangeRates>
                  <Day date=\"2026-03-05\">
                    <Rate curr=\"EUR\" unit=\"1\">406,50</Rate>
                    <Rate curr=\"JPY\" unit=\"100\">250.30</Rate>
                    <Rate curr=\"BAD\" unit=\"1\">not-a-number</Rate>
                    <Rate unit=\"1\">123.45</Rate>
                    <Rate curr=\"EMPTY\" unit=\"1\"></Rate>
                  </Day>
                </MNBCurrentExchangeRates>
                """;

        Map<String, BigDecimal> rates = client.parseMnbXml(xml);

        assertThat(rates).containsOnlyKeys("EUR", "JPY");
        assertThat(rates.get("EUR")).isEqualByComparingTo("406.5000");
        assertThat(rates.get("JPY")).isEqualByComparingTo("2.5030");
    }

    @Test
    @DisplayName("MNB XML parse: XXE/DOCTYPE fail-closed BusinessExceptionnel")
    void parseMnbXml_rejectsDoctype() {
        String xml = """
                <!DOCTYPE foo [ <!ENTITY xxe SYSTEM \"file:///etc/passwd\"> ]>
                <MNBCurrentExchangeRates>
                  <Day date=\"2026-03-05\">
                    <Rate curr=\"EUR\" unit=\"1\">&xxe;</Rate>
                  </Day>
                </MNBCurrentExchangeRates>
                """;

        assertThatThrownBy(() -> client.parseMnbXml(xml))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("MNB XML");
    }
}
