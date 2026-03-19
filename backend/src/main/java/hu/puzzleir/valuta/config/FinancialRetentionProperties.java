package hu.puzzleir.valuta.config;

import jakarta.validation.constraints.AssertFalse;
import jakarta.validation.constraints.Min;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;
import org.springframework.validation.annotation.Validated;

/**
 * Explicit retention policy for financial transaction data.
 *
 * The archive is append-only and hard delete must stay disabled.
 */
@Configuration
@ConfigurationProperties(prefix = "retention.financial-transactions")
@Validated
@Getter
@Setter
public class FinancialRetentionProperties {

    @Min(value = 8, message = "Financial transaction retention must be at least 8 years")
    private int years = 8;

    @AssertFalse(message = "Hard delete must remain disabled for financial transaction retention")
    private boolean hardDeleteEnabled = false;
}
