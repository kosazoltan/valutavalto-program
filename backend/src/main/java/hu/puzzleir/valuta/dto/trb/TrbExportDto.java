package hu.puzzleir.valuta.dto.trb;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.List;

/**
 * Teljes TRB export egy cégre, egy napra.
 *
 * Legacy: unit5.pas MAKEIMPORT → WIMPORT → txt + Excel
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TrbExportDto {
    private String companyCode;
    private String companyName;
    private LocalDate reportDate;
    private LocalDate valueDate;
    /** Irodánkénti részletes jelentések */
    private List<TrbBranchReportDto> branchReports;
    /** Céges szintű bankforgalom összesítő */
    private List<TrbBankFlowLineDto> bankFlowLines;
}
