package hu.puzzleir.valuta.config;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import javax.sql.DataSource;

/**
 * Neon DB másodlagos (BACKUP) DataSource konfiguráció.
 * Csak akkor aktív, ha app.neon-sync.enabled=true.
 *
 * <p>FONTOS: ez a bean önmagában visszaléptetné a Spring Boot primary DataSource auto-configját
 * (lásd a 2026-06-15 incidenst). Ezért az elsődleges, LOKÁLIS datasource-ot a
 * {@link PrimaryDataSourceConfig} EXPLICITTÉ és {@code @Primary}-vá teszi — így ez a bean
 * egyértelműen MÁSODLAGOS marad, és a neon-sync bekapcsolása NEM téríti el a primaryt.
 */
@Configuration
@ConditionalOnProperty(name = "app.neon-sync.enabled", havingValue = "true")
@Slf4j
public class NeonDataSourceConfig {

    @Value("${NEON_DATABASE_URL:}")
    private String neonUrl;

    @Value("${NEON_DATABASE_USERNAME:}")
    private String neonUsername;

    @Value("${NEON_DATABASE_PASSWORD:}")
    private String neonPassword;

    @Bean(name = "neonDataSource")
    public DataSource neonDataSource() {
        log.info("Neon DataSource konfigurálás: {}", maskUrl(neonUrl));
        DriverManagerDataSource ds = new DriverManagerDataSource();
        ds.setDriverClassName("org.postgresql.Driver");

        if (neonUrl.startsWith("postgresql://") || neonUrl.startsWith("postgres://")) {
            String jdbcUrl = convertToJdbcUrl(neonUrl);
            ds.setUrl(jdbcUrl);
            // Apply credentials parsed from the libpq URI
            if (parsedUsername != null && !parsedUsername.isEmpty()) {
                ds.setUsername(parsedUsername);
            }
            if (parsedPassword != null && !parsedPassword.isEmpty()) {
                ds.setPassword(parsedPassword);
            }
        } else if (neonUrl.startsWith("jdbc:")) {
            ds.setUrl(neonUrl);
            ds.setUsername(neonUsername);
            ds.setPassword(neonPassword);
        } else {
            ds.setUrl("jdbc:postgresql://" + neonUrl);
            ds.setUsername(neonUsername);
            ds.setPassword(neonPassword);
        }
        return ds;
    }

    @Bean(name = "neonJdbcTemplate")
    public JdbcTemplate neonJdbcTemplate() {
        return new JdbcTemplate(neonDataSource());
    }

    /**
     * Convert libpq URI to JDBC URL and extract credentials.
     * postgresql://user:pass@host:port/db?params → jdbc:postgresql://host:port/db?params
     * User/pass are set on the DataSource, NOT embedded in the JDBC URL.
     */
    private String convertToJdbcUrl(String url) {
        String withoutScheme = url.replaceFirst("^postgres(ql)?://", "");
        String hostAndDb;
        if (withoutScheme.contains("@")) {
            int atIdx = withoutScheme.indexOf('@');
            String userInfo = withoutScheme.substring(0, atIdx);
            hostAndDb = withoutScheme.substring(atIdx + 1);
            // Parse user:pass from URI and store for DataSource config
            if (userInfo.contains(":")) {
                int colonIdx = userInfo.indexOf(':');
                this.parsedUsername = userInfo.substring(0, colonIdx);
                this.parsedPassword = userInfo.substring(colonIdx + 1);
            } else {
                this.parsedUsername = userInfo;
            }
        } else {
            hostAndDb = withoutScheme;
        }
        return "jdbc:postgresql://" + hostAndDb;
    }

    /** Credentials parsed from the libpq URI, applied in neonDataSource(). */
    private String parsedUsername;
    private String parsedPassword;

    private String maskUrl(String url) {
        if (url == null || url.isEmpty()) {
            return "(empty)";
        }
        return url.replaceAll(":[^/@]+@", ":***@");
    }
}
