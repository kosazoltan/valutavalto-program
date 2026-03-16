package hu.puzzleir.valuta.dto.aml;

import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Napi AML export DTO — hatóságnak küldendő összesítő.
 *
 * 2017. évi LIII. tv. szerinti kötelező napi adatszolgáltatás.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AmlDailyExportDto {

    /** Export dátuma */
    private LocalDate exportDate;

    /** Cég azonosítója (multi-tenant) */
    private UUID companyId;

    /** Összes bejelentés az adott napon */
    private int totalReports;

    /** DRAFT státuszú bejelentések száma */
    private int draftCount;

    /** SUBMITTED státuszú bejelentések száma */
    private int submittedCount;

    /** ACKNOWLEDGED státuszú bejelentések száma */
    private int acknowledgedCount;

    /** FLAGGED státuszú bejelentések száma */
    private int flaggedCount;

    /** Az adott nap összes bejelentett összeg (HUF) */
    private BigDecimal totalAmountHuf;

    /** Bejelentések részletei */
    private List<AmlReportDto> reports;

    /** Export generálásának időpontja */
    private LocalDateTime generatedAt;
}
