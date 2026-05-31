package hu.puzzleir.valuta.entity;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * RateTemplate JSON-szerializáció — multi-tenant LazyInit fix (audit 2026-05-31, P1).
 *
 * A {@code company} lazy {@code @ManyToOne} + {@code @JsonIgnore}; a controller GET/approve/revoke
 * endpointjai az ENTITÁST adják vissza, így OSIV=false mellett a Company-proxy szerializálása
 * {@code LazyInitializationException} 500-at dobott. A fix: a company-t a JSON kihagyja, és a
 * companyId flat mezőként jelenik meg (a RateWorkgroup mintája).
 */
class RateTemplateSerializationTest {

    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Test
    @DisplayName("RateTemplate szerializáció: NINCS 'company' objektum (nincs lazy-proxy hozzáférés), companyId flat mezőként")
    void serializesCompanyIdFlatAndIgnoresCompany() throws Exception {
        UUID companyId = UUID.randomUUID();
        RateTemplate template = RateTemplate.builder()
                .id(UUID.randomUUID())
                .company(Company.builder().id(companyId).code("BEST").name("Best Change").build())
                .workgroupId(UUID.randomUUID())
                .currencyId(1L)
                .baseBuyRate(new BigDecimal("395.0000"))
                .baseSellRate(new BigDecimal("398.0000"))
                .status(RateTemplate.RateTemplateStatus.APPROVED)
                .build();

        JsonNode json = objectMapper.readTree(objectMapper.writeValueAsString(template));

        // @JsonIgnore: a company asszociáció NEM szerializálódik → a Jackson sosem nyúl a lazy proxyhoz.
        assertThat(json.has("company")).isFalse();
        // A flat companyId getter a már ismert FK-ból ad értéket, lazy-betöltés nélkül.
        assertThat(json.has("companyId")).isTrue();
        assertThat(json.get("companyId").asText()).isEqualTo(companyId.toString());
    }

    @Test
    @DisplayName("getCompanyId() null-biztos: ha nincs company, null-t ad (nem NPE)")
    void getCompanyIdNullSafeWhenNoCompany() {
        RateTemplate template = RateTemplate.builder()
                .id(UUID.randomUUID())
                .workgroupId(UUID.randomUUID())
                .currencyId(1L)
                .build();

        assertThat(template.getCompanyId()).isNull();
    }
}
