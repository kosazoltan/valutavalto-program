package hu.puzzleir.valuta.config;

import com.zaxxer.hikari.HikariDataSource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;

/**
 * Explicit, elsődleges (LOKÁLIS) {@code @Primary} DataSource.
 *
 * <p><b>Gyökér-ok (2026-06-15 prod incidens).</b> Amikor {@code app.neon-sync.enabled=true}, a
 * {@link NeonDataSourceConfig} egy másodlagos {@code DataSource} bean-t (neonDataSource) definiál.
 * Emiatt a Spring Boot {@code DataSourceAutoConfiguration} VISSZALÉP
 * ({@code @ConditionalOnMissingBean DataSource}), így NEM jön létre a {@code spring.datasource.url}
 * (= {@code DATABASE_URL}) alapú elsődleges Hikari-pool. Mivel ekkor a neonDataSource az EGYETLEN
 * {@code DataSource}, az lett a de-facto {@code @Primary} → az app, a Flyway és a JPA a Neont
 * szolgálta, a {@code DATABASE_URL=localhost}-ot figyelmen kívül hagyva ("minden a Neonra került").
 *
 * <p><b>Megoldás.</b> Ez a konfiguráció EXPLICITTÉ és {@code @Primary}-vá teszi a fő (DATABASE_URL
 * alapú) LOKÁLIS DataSource-ot, így a neonDataSource egyértelműen MÁSODLAGOS marad, és a neon-sync
 * bekapcsolása NEM téríti el a primaryt. A {@link NeonReplicationService} a {@code @Primary}
 * (lokális) {@code JdbcTemplate}-ből olvas és a {@code @Qualifier("neonDataSource")}-ba (Neon backup)
 * ír — azaz a backup-irány helyesen local→Neon.
 *
 * <p>A pool-beállítások a {@code spring.datasource.hikari.*} alól kötődnek (változatlan viselkedés a
 * korábbi auto-confighoz képest), beleértve a {@code data-source-properties.*} kulcsokat is.
 */
@Configuration
@Slf4j
public class PrimaryDataSourceConfig {

    @Bean
    @Primary
    @ConfigurationProperties("spring.datasource.hikari")
    public DataSource dataSource(
            @Value("${spring.datasource.url}") String url,
            @Value("${spring.datasource.username}") String username,
            @Value("${spring.datasource.password}") String password,
            @Value("${spring.datasource.driver-class-name:org.postgresql.Driver}") String driverClassName) {
        HikariDataSource ds = new HikariDataSource();
        ds.setJdbcUrl(url);
        ds.setUsername(username);
        ds.setPassword(password);
        ds.setDriverClassName(driverClassName);
        log.info("Elsődleges (PRIMARY) DataSource konfigurálva: {}", mask(url));
        return ds;
    }

    private static String mask(String url) {
        return url == null ? "(empty)" : url.replaceAll(":[^/@]+@", ":***@");
    }
}
