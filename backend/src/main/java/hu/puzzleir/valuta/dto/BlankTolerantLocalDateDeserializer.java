package hu.puzzleir.valuta.dto;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;

import java.io.IOException;
import java.time.LocalDate;

/**
 * FK-025: üres string ("") → null LocalDate mezőkre, hogy a Jackson ne dobjon
 * deszerializálási hibát (HttpMessageNotReadableException → kontextus nélküli 400).
 * Üres érték után a Bean Validation ad érthető hibaüzenetet (@NotNull mezőn), vagy
 * átengedi (opcionális mezőn). ISO-8601 formátum (pl. "2020-01-15").
 *
 * Eredetileg az UpdateBranchDto beágyazott osztálya volt (commit 4cf0ebc6f) — a
 * CreateBranchDto TBD#1 javításával közös használatra top-level osztályba került.
 */
public class BlankTolerantLocalDateDeserializer extends JsonDeserializer<LocalDate> {
    @Override
    public LocalDate deserialize(JsonParser p, DeserializationContext ctx) throws IOException {
        String value = p.getText();
        if (value == null || value.isBlank()) {
            return null;
        }
        return LocalDate.parse(value.trim());
    }
}
