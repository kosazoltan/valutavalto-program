package hu.puzzleir.valuta.dto.report;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * FKH-030: a Pénzforgalom riport válasza — a lekérdezett tartomány és a bizonylat-sorok.
 *
 * <p>A tartomány visszaadása szándékos: a nyomtatott lap fejlécében meg kell jelennie,
 * melyik időszakra vonatkozik a kimutatás (FR-10).</p>
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CashFlowReportDto {

    /** A lekérdezett tartomány kezdete (ISO). */
    private String from;

    /** A lekérdezett tartomány vége (ISO), inkluzív. */
    private String to;

    /** FR-3/FR-4: bizonylatonkénti sorok, dátum szerint rendezve. */
    private List<CashFlowReportRowDto> rows;
}
