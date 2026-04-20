package hu.puzzleir.valuta.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Publikus (no-auth) worker info a penztar klienshez,
 * a login-elotti dolgozo-listahoz a kivalasztott penztar regioja szerint.
 *
 * Csak code + name (semmi erzekeny adat - no email, phone, TAJ, adoazonosito).
 * Region = region identifier (pl. SZEGED, DEBRECEN).
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PublicWorkerDto {
    /** Penztaros kod (pl. W007570, BORSI) */
    private String code;

    /** Penztaros neve */
    private String name;

    /** Region - BEKESCSABA, DEBRECEN, NYIREGYHAZA, KECSKEMET, SZEGED, KAPOSVAR, PECS, SZEKSZARD, IRODA */
    private String region;
}
