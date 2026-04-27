package hu.puzzleir.valuta.dto.sync;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Sync inbound event request DTO.
 *
 * Audit-iter3 P1 (Spring Boot 4 / Jackson 3 migracio, 2026-04-27):
 * a `payload` mezo korabban Jackson 2 `com.fasterxml.jackson.databind.JsonNode`
 * volt, de Spring Boot 4 default Jackson 3 a JsonNode-ot nem tudja konstrualni
 * (no creators / abstract type). `Object`-re csereltuk, igy Jackson 3 a payload-ot
 * generikus Map/List/primitive deserializaciot csinal. A `objectMapper.writeValueAsString`
 * tovabbra is ugyanugy mukodik (Map-bol JSON string).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SyncInboundEventRequest {

    @NotBlank
    private String sourceNodeId;

    @NotBlank
    private String eventType;

    @NotNull
    private Object payload;
}
