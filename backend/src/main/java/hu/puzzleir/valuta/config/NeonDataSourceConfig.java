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
 * Neon DB másodlagos DataSource konfiguráció.
 * Csak akkor aktív, ha app.neon-sync.enabled=true.
 * A fő DataSource-ot NEM érinti.
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
            // JDBC URL konverzió: postgresql://user:pass@host/db?params → jdbc:postgresql://host/db?params
            String jdbcUrl = convertToJdbcUrl(neonUrl);
            ds.setUrl(jdbcUrl);
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

    private String convertToJdbcUrl(String url) {
        // postgresql://user:pass@host:port/db?params
        String withoutScheme = url.replaceFirst("^postgres(ql)?://", "");
        String userInfo = "";
        String hostAndDb;
        if (withoutScheme.contains("@")) {
            int atIdx = withoutScheme.indexOf('@');
            userInfo = withoutScheme.substring(0, atIdx);
            hostAndDb = withoutScheme.substring(atIdx + 1);
        } else {
            hostAndDb = withoutScheme;
        }
        String jdbcUrl = "jdbc:postgresql://" + hostAndDb;

        // Ha van user:pass a URL-ben, a DriverManagerDataSource-ben is beállítjuk
        if (!userInfo.isEmpty() && userInfo.contains(":")) {
            // Nem kell külön — a JDBC driver a URL-ből is kiolvassa
        }
        return jdbcUrl;
    }

    private String maskUrl(String url) {
        if (url == null || url.isEmpty()) {
            return "(empty)";
        }
        return url.replaceAll(":[^/@]+@", ":***@");
    }
}
